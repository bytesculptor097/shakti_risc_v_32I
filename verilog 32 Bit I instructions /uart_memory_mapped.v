`default_nettype none
// -----------------------------------------------------------------------------
// APB3 memory-mapped UART
//   - Simple single-sample RX/TX (mid-bit sampling); good with accurate CLOCK_DIV
//   - One-byte TX buffer to avoid drops while a byte is in-flight
//   - RX FIFO depth parameterizable, default 64
// Address map (byte addresses):
//   0x00 R/W CLOCK_DIV        [CLOCK_DIV_WIDTH-1:0]
//   0x04 R/W FRAME            [3:0]=data_bits (5..8), [4]=two_stop, [5]=parity_en, [6]=parity_odd
//   0x08  W  TX DATA          [7:0]=tx_data
//   0x08  R  TX STATUS        bit[0]=tx_busy_or_buffered
//   0x0C  R  RX DATA/VALID    bit[31]=valid, [7:0]=data  (read pops when valid)
// -----------------------------------------------------------------------------
module apb3_uart #(
  parameter integer CLOCK_DIV_WIDTH = 20,
  parameter integer RX_FIFO_DEPTH   = 64,   // use power-of-two for best QoR
  parameter integer DATA_BITS_MAX   = 8,
  parameter integer CLOCK_DIV_INIT  = 0     // default divider after reset
)(
  input  wire                     pclk,
  input  wire                     presetn,

  // APB3
  input  wire                     psel,
  input  wire                     penable,
  input  wire                     pwrite,
  input  wire [11:0]              paddr,    // word aligned
  input  wire [31:0]              pwdata,
  output reg  [31:0]              prdata,
  output wire                     pready,
  output wire                     pslverr,

  // UART
  output wire                     txd,
  input  wire                     rxd
);

  // ------------------------------
  // APB3 defaults
  // ------------------------------
  assign pready  = 1'b1;
  assign pslverr = 1'b0;

  // Address decode (word index)
  localparam [3:0] ADDR_DIV   = 4'h0; // 0x00
  localparam [3:0] ADDR_FRAME = 4'h1; // 0x04
  localparam [3:0] ADDR_TX    = 4'h2; // 0x08
  localparam [3:0] ADDR_RX    = 4'h3; // 0x0C
  wire [3:0] addr_word = paddr[5:2];

  wire apb_wr = psel & penable &  pwrite;
  wire apb_rd = psel & penable & ~pwrite;

  // ------------------------------
  // Registers: CLOCK_DIV and FRAME
  // ------------------------------
  reg [CLOCK_DIV_WIDTH-1:0] clock_divider;
  // FRAME fields
  reg [3:0]  frm_data_bits; // 5..8
  reg        frm_two_stop;
  reg        frm_parity_en;
  reg        frm_parity_odd;

  // Reset values
  localparam [3:0]  RESET_DATABITS = 4'd8; // 8 data bits
  localparam        RESET_TWOSTOP  = 1'b0; // 1 stop
  localparam        RESET_PEN      = 1'b0; // parity disabled
  localparam        RESET_PODD     = 1'b0; // (don't care if disabled)

  always @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      clock_divider <= CLOCK_DIV_INIT[CLOCK_DIV_WIDTH-1:0];
      frm_data_bits <= RESET_DATABITS;
      frm_two_stop  <= RESET_TWOSTOP;
      frm_parity_en <= RESET_PEN;
      frm_parity_odd<= RESET_PODD;
    end else if (apb_wr) begin
      case (addr_word)
        ADDR_DIV: begin
          clock_divider <= pwdata[CLOCK_DIV_WIDTH-1:0];
        end
        ADDR_FRAME: begin
          frm_data_bits <= pwdata[3:0]; // expect 5..8
          frm_two_stop  <= pwdata[4];
          frm_parity_en <= pwdata[5];
          frm_parity_odd<= pwdata[6];
        end
        default: ;
      endcase
    end
  end

  // Clamp data bits into 5..8
  wire [3:0] data_bits = (frm_data_bits < 5) ? 4'd5 :
                         (frm_data_bits > 8) ? 4'd8 : frm_data_bits;

  // ------------------------------
  // TX engine with 1-byte buffer
  // ------------------------------
  reg        txd_q;
  assign txd = txd_q;

  typedef enum logic [2:0] {TX_IDLE, TX_START, TX_DATA, TX_PARITY, TX_STOP1, TX_STOP2} tx_state_e;
  reg [2:0]  tx_state;

  reg [CLOCK_DIV_WIDTH-1:0] tx_cnt;
  wire                      tx_tick = (tx_cnt == clock_divider);

  reg [7:0] tx_shift;
  reg [3:0] tx_bit_idx; // up to 8
  reg       tx_parity_bit;
  reg       tx_active; // in-flight byte

  // One-byte buffer to avoid losing writes
  reg       tx_buf_valid;
  reg [7:0] tx_buf_data;

  wire wr_tx_data = apb_wr && (addr_word == ADDR_TX);

  // TX busy/occupied: either sending or buffer contains data
  wire tx_busy = tx_active | tx_buf_valid;

  // Load into engine (priority: engine if idle; else buffer if empty)
  wire [7:0] tx_wr_byte = pwdata[7:0];
  wire       tx_can_start = ~tx_active; // engine idle

  // parity calc for 5..8 bits (LSBs of tx_wr_byte)
  function automatic parity_calc;
    input [7:0] d;
    input [3:0] nbits; // 5..8
    reg   [7:0] mask;
    begin
      mask = 8'hFF >> (8 - nbits);
      parity_calc = ^(d & mask); // even parity over used bits
    end
  endfunction

  // TX tick counter
  always @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      tx_cnt <= {CLOCK_DIV_WIDTH{1'b0}};
    end else if (tx_state != TX_IDLE) begin
      if (tx_tick) tx_cnt <= {CLOCK_DIV_WIDTH{1'b0}};
      else         tx_cnt <= tx_cnt + {{(CLOCK_DIV_WIDTH-1){1'b0}},1'b1};
    end else begin
      tx_cnt <= {CLOCK_DIV_WIDTH{1'b0}};
    end
  end

  // Manage buffer + start conditions
  always @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      tx_buf_valid <= 1'b0;
      tx_buf_data  <= 8'h00;
    end else begin
      // APB write to TX register
      if (wr_tx_data) begin
        if (tx_can_start) begin
          // load directly into engine below (no buffer)
          // nothing to store here
        end else if (!tx_buf_valid) begin
          tx_buf_valid <= 1'b1;
          tx_buf_data  <= tx_wr_byte;
        end
        // else: drop when buffer full (could add an overrun flag if needed)
      end

      // When engine finishes a byte and a buffer exists, engine will pull it;
      // we clear the buffer when it gets consumed (in TX_IDLE->TX_START transition).
      if (tx_state == TX_IDLE && tx_buf_valid && !tx_can_start) begin
        // no-op; tx_can_start is true in IDLE; handled below
      end

      if (tx_state == TX_START && tx_tick) begin
        // nothing to do here for buffer
      end

      // Clear buffer when it is moved into engine (see below)
      // (implemented in the state machine block to align with load timing)
    end
  end

  // TX state machine
  always @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      tx_state     <= TX_IDLE;
      txd_q        <= 1'b1; // idle high
      tx_active    <= 1'b0;
      tx_shift     <= 8'h00;
      tx_bit_idx   <= 4'd0;
      tx_parity_bit<= 1'b0;
    end else begin
      case (tx_state)
        TX_IDLE: begin
          txd_q     <= 1'b1;
          tx_active <= 1'b0;
          // Engine can start from APB write this cycle or buffered data
          if (wr_tx_data) begin
            // start with just-written data
            tx_shift      <= pwdata[7:0];
            tx_bit_idx    <= 4'd0;
            tx_parity_bit <= parity_calc(pwdata[7:0], data_bits) ^ (frm_parity_odd ? 1'b1 : 1'b0);
            tx_state      <= TX_START;
            tx_active     <= 1'b1;
          end else if (tx_buf_valid) begin
            // consume buffer
            tx_shift      <= tx_buf_data;
            tx_bit_idx    <= 4'd0;
            tx_parity_bit <= parity_calc(tx_buf_data, data_bits) ^ (frm_parity_odd ? 1'b1 : 1'b0);
            tx_state      <= TX_START;
            tx_active     <= 1'b1;
            tx_buf_valid  <= 1'b0; // buffer consumed
          end
        end

        TX_START: begin
          txd_q <= 1'b0; // start bit
          if (tx_tick) begin
            tx_state <= TX_DATA;
          end
        end

        TX_DATA: begin
          txd_q <= tx_shift[0];
          if (tx_tick) begin
            tx_shift   <= {1'b0, tx_shift[7:1]};
            tx_bit_idx <= tx_bit_idx + 4'd1;
            if (tx_bit_idx == (data_bits - 1)) begin
              if (frm_parity_en)
                tx_state <= TX_PARITY;
              else
                tx_state <= TX_STOP1;
            end
          end
        end

        TX_PARITY: begin
          txd_q <= tx_parity_bit; // already adjusted for odd/even
          if (tx_tick) begin
            tx_state <= TX_STOP1;
          end
        end

        TX_STOP1: begin
          txd_q <= 1'b1;
          if (tx_tick) begin
            if (frm_two_stop) tx_state <= TX_STOP2;
            else              tx_state <= TX_IDLE;
          end
        end

        TX_STOP2: begin
          txd_q <= 1'b1;
          if (tx_tick) begin
            tx_state <= TX_IDLE;
          end
        end

        default: tx_state <= TX_IDLE;
      endcase
    end
  end

  // ------------------------------
  // RX engine (mid-bit sampler) + FIFO
  // ------------------------------
  localparam integer RX_AW = (RX_FIFO_DEPTH <= 2)   ? 1 :
                             (RX_FIFO_DEPTH <= 4)   ? 2 :
                             (RX_FIFO_DEPTH <= 8)   ? 3 :
                             (RX_FIFO_DEPTH <= 16)  ? 4 :
                             (RX_FIFO_DEPTH <= 32)  ? 5 :
                             (RX_FIFO_DEPTH <= 64)  ? 6 :
                             (RX_FIFO_DEPTH <= 128) ? 7 :
                             (RX_FIFO_DEPTH <= 256) ? 8 : 9; // extend if needed

  reg [7:0]            rx_mem [0:RX_FIFO_DEPTH-1];
  reg [RX_AW-1:0]      rx_rptr, rx_wptr;
  reg [RX_AW:0]        rx_count;
  wire                  rx_empty = (rx_count == 0);
  wire                  rx_full  = (rx_count == RX_FIFO_DEPTH);

  // FIFO push/pop
  wire rx_pop  = apb_rd && (addr_word == ADDR_RX) && !rx_empty;
  reg  rx_push;
  reg [7:0] rx_push_data;

  always @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      rx_rptr  <= {RX_AW{1'b0}};
      rx_wptr  <= {RX_AW{1'b0}};
      rx_count <= {RX_AW+1{1'b0}};
    end else begin
      // POP
      if (rx_pop) begin
        rx_rptr  <= rx_rptr + {{(RX_AW-1){1'b0}},1'b1};
        rx_count <= rx_count - {{RX_AW{1'b0}},1'b1};
      end
      // PUSH
      if (rx_push && !rx_full) begin
        rx_mem[rx_wptr] <= rx_push_data;
        rx_wptr         <= rx_wptr + {{(RX_AW-1){1'b0}},1'b1};
        rx_count        <= rx_count + {{RX_AW{1'b0}},1'b1};
      end
    end
  end

  // RX sampler
  typedef enum logic [2:0] {RX_IDLE, RX_START, RX_DATA, RX_PARITY, RX_STOP} rx_state_e;
  reg [2:0]  rx_state;
  reg [CLOCK_DIV_WIDTH-1:0] rx_cnt;
  reg [3:0]  rx_bit_idx;
  reg [7:0]  rx_shift;
  reg        rx_parity_acc; // even parity accumulator over used bits
  reg        rxd_sync1, rxd_sync2;

  // simple 2FF sync
  always @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      rxd_sync1 <= 1'b1;
      rxd_sync2 <= 1'b1;
    end else begin
      rxd_sync1 <= rxd;
      rxd_sync2 <= rxd_sync1;
    end
  end

  wire rxd_i = rxd_sync2;

  // RX counters and state
  wire [CLOCK_DIV_WIDTH-1:0] half_div = clock_divider >> 1;

  always @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      rx_state      <= RX_IDLE;
      rx_cnt        <= {CLOCK_DIV_WIDTH{1'b0}};
      rx_bit_idx    <= 4'd0;
      rx_shift      <= 8'h00;
      rx_parity_acc <= 1'b0;
      rx_push       <= 1'b0;
      rx_push_data  <= 8'h00;
    end else begin
      rx_push <= 1'b0; // default

      case (rx_state)
        RX_IDLE: begin
          if (!rxd_i) begin // start-bit detect (falling edge)
            rx_cnt     <= half_div; // wait half to sample mid start bit
            rx_state   <= RX_START;
          end
        end

        RX_START: begin
          if (rx_cnt == 0) begin
            // sample start mid bit
            if (!rxd_i) begin
              // valid start, move to data
              rx_bit_idx    <= 4'd0;
              rx_parity_acc <= 1'b0;
              rx_cnt        <= clock_divider;
              rx_state      <= RX_DATA;
            end else begin
              // false start
              rx_state <= RX_IDLE;
            end
          end else begin
            rx_cnt <= rx_cnt - {{(CLOCK_DIV_WIDTH-1){1'b0}},1'b1};
          end
        end

        RX_DATA: begin
          if (rx_cnt == 0) begin
            // sample data bit
            rx_shift      <= {rxd_i, rx_shift[7:1]}; // LSB first
            rx_parity_acc <= rx_parity_acc ^ rxd_i;
            rx_bit_idx    <= rx_bit_idx + 4'd1;
            rx_cnt        <= clock_divider;
            if (rx_bit_idx == (data_bits - 1)) begin
              if (frm_parity_en) rx_state <= RX_PARITY;
              else                rx_state <= RX_STOP;
            end
          end else begin
            rx_cnt <= rx_cnt - {{(CLOCK_DIV_WIDTH-1){1'b0}},1'b1};
          end
        end

        RX_PARITY: begin
          if (rx_cnt == 0) begin
            // sample parity bit, ignore error reporting for simplicity
            // expected even parity = rx_parity_acc; odd flips it
            // parity_ok = (rxd_i == (rx_parity_acc ^ frm_parity_odd));
            rx_cnt   <= clock_divider;
            rx_state <= RX_STOP;
          end else begin
            rx_cnt <= rx_cnt - {{(CLOCK_DIV_WIDTH-1){1'b0}},1'b1};
          end
        end

        RX_STOP: begin
          if (rx_cnt == 0) begin
            // sample stop (should be 1). If not, still push data (simple design).
            // push only low data_bits
            if (!rx_full) begin
              rx_push_data <= rx_shift[7:0];
              rx_push      <= 1'b1;
            end
            rx_state <= RX_IDLE;
          end else begin
            rx_cnt <= rx_cnt - {{(CLOCK_DIV_WIDTH-1){1'b0}},1'b1};
          end
        end

        default: rx_state <= RX_IDLE;
      endcase
    end
  end

  // ------------------------------
  // APB read data mux
  // ------------------------------
  wire [7:0] rx_peek_data = rx_mem[rx_rptr];

  always @(*) begin
    prdata = 32'h0000_0000;
    case (addr_word)
      ADDR_DIV:   prdata[CLOCK_DIV_WIDTH-1:0] = clock_divider;
      ADDR_FRAME: begin
        prdata[3:0] = frm_data_bits;
        prdata[4]   = frm_two_stop;
        prdata[5]   = frm_parity_en;
        prdata[6]   = frm_parity_odd;
      end
      ADDR_TX: begin
        prdata[0] = tx_busy; // occupied/busy indicator
      end
      ADDR_RX: begin
        prdata[31]   = ~rx_empty;
        prdata[7:0]  = rx_empty ? 8'h00 : rx_peek_data; // non-blocking; pop occurs on handshake
      end
      default: prdata = 32'h0000_0000;
    endcase
  end

endmodule
`default_nettype wire

