`include "uart"
`default_nettype none
module axi_lite_to_apb3 #(
  parameter ADDR_WIDTH = 12,   // APB address (byte addr); word index = PADDR[5:2]
  parameter DATA_WIDTH = 32
)(
  input  wire                     ACLK,
  input  wire                     ARESETn,

  // AXI4-Lite slave
  input  wire [31:0]              S_AXI_AWADDR,
  input  wire                     S_AXI_AWVALID,
  output reg                      S_AXI_AWREADY,

  input  wire [DATA_WIDTH-1:0]    S_AXI_WDATA,
  input  wire [(DATA_WIDTH/8)-1:0]S_AXI_WSTRB,
  input  wire                     S_AXI_WVALID,
  output reg                      S_AXI_WREADY,

  output reg  [1:0]               S_AXI_BRESP,
  output reg                      S_AXI_BVALID,
  input  wire                     S_AXI_BREADY,

  input  wire [31:0]              S_AXI_ARADDR,
  input  wire                     S_AXI_ARVALID,
  output reg                      S_AXI_ARREADY,

  output reg  [DATA_WIDTH-1:0]    S_AXI_RDATA,
  output reg  [1:0]               S_AXI_RRESP,
  output reg                      S_AXI_RVALID,
  input  wire                     S_AXI_RREADY,

  // APB3 master
  output reg  [ADDR_WIDTH-1:0]    PADDR,
  output reg                      PSEL,
  output reg                      PENABLE,
  output reg                      PWRITE,
  output reg  [DATA_WIDTH-1:0]    PWDATA,
  input  wire [DATA_WIDTH-1:0]    PRDATA,
  input  wire                     PREADY,   // tie to 1 in simple slaves
  input  wire                     PSLVERR   // tie to 0 in simple slaves
);
  // Simple two FSMs: write channel and read channel. No outstanding overlap.
  typedef enum logic [1:0] {WIDLE, WSETUP, WENABLE, WRESP} wstate_e;
  typedef enum logic [1:0] {RIDLE, RSETUP, RENABLE, RRESP} rstate_e;

  wstate_e wstate;
  rstate_e rstate;

  // Latches
  reg [31:0] latched_awaddr, latched_wdata;
  reg        have_aw, have_w;

  // Write FSM
  always @(posedge ACLK or negedge ARESETn) begin
    if(!ARESETn) begin
      wstate        <= WIDLE;
      S_AXI_AWREADY <= 1'b0;
      S_AXI_WREADY  <= 1'b0;
      S_AXI_BVALID  <= 1'b0;
      S_AXI_BRESP   <= 2'b00;
      have_aw       <= 1'b0;
      have_w        <= 1'b0;
      PSEL          <= 1'b0;
      PENABLE       <= 1'b0;
      PWRITE        <= 1'b0;
      PADDR         <= {ADDR_WIDTH{1'b0}};
      PWDATA        <= {DATA_WIDTH{1'b0}};
    end else begin
      // defaults
      S_AXI_AWREADY <= (wstate==WIDLE && !have_aw);
      S_AXI_WREADY  <= (wstate==WIDLE && !have_w);

      case(wstate)
        WIDLE: begin
          // capture AW
          if (S_AXI_AWREADY && S_AXI_AWVALID) begin
            latched_awaddr <= S_AXI_AWADDR;
            have_aw        <= 1'b1;
          end
          // capture W
          if (S_AXI_WREADY && S_AXI_WVALID) begin
            latched_wdata <= S_AXI_WDATA;
            have_w        <= 1'b1;
          end
          if (have_aw && have_w) begin
            // drive APB setup
            PADDR   <= latched_awaddr[ADDR_WIDTH-1:0];
            PWDATA  <= latched_wdata;
            PWRITE  <= 1'b1;
            PSEL    <= 1'b1;
            PENABLE <= 1'b0;
            wstate  <= WSETUP;
          end
        end

        WSETUP: begin
          // APB enable phase
          PENABLE <= 1'b1;
          wstate  <= WENABLE;
        end

        WENABLE: begin
          if (PREADY) begin
            // complete APB write
            PSEL    <= 1'b0;
            PENABLE <= 1'b0;
            PWRITE  <= 1'b0;
            have_aw <= 1'b0;
            have_w  <= 1'b0;
            // respond on AXI
            S_AXI_BRESP  <= PSLVERR ? 2'b10 : 2'b00; // SLVERR or OKAY
            S_AXI_BVALID <= 1'b1;
            wstate       <= WRESP;
          end
        end

        WRESP: begin
          if (S_AXI_BVALID && S_AXI_BREADY) begin
            S_AXI_BVALID <= 1'b0;
            wstate       <= WIDLE;
          end
        end

        default: wstate <= WIDLE;
      endcase
    end
  end

  // Read FSM
  reg [31:0] latched_araddr;
  always @(posedge ACLK or negedge ARESETn) begin
    if(!ARESETn) begin
      rstate        <= RIDLE;
      S_AXI_ARREADY <= 1'b0;
      S_AXI_RVALID  <= 1'b0;
      S_AXI_RRESP   <= 2'b00;
    end else begin
      S_AXI_ARREADY <= (rstate==RIDLE);

      case(rstate)
        RIDLE: begin
          if (S_AXI_ARREADY && S_AXI_ARVALID) begin
            latched_araddr <= S_AXI_ARADDR;
            // APB read setup
            PADDR   <= S_AXI_ARADDR[ADDR_WIDTH-1:0];
            PWRITE  <= 1'b0;
            PSEL    <= 1'b1;
            PENABLE <= 1'b0;
            rstate  <= RSETUP;
          end
        end

        RSETUP: begin
          PENABLE <= 1'b1;
          rstate  <= RENABLE;
        end

        RENABLE: begin
          if (PREADY) begin
            PSEL         <= 1'b0;
            PENABLE      <= 1'b0;
            S_AXI_RDATA  <= PRDATA;
            S_AXI_RRESP  <= PSLVERR ? 2'b10 : 2'b00; // SLVERR or OKAY
            S_AXI_RVALID <= 1'b1;
            rstate       <= RRESP;
          end
        end

        RRESP: begin
          if (S_AXI_RVALID && S_AXI_RREADY) begin
            S_AXI_RVALID <= 1'b0;
            rstate       <= RIDLE;
          end
        end

        default: rstate <= RIDLE;
      endcase
    end
  end
endmodule
`default_nettype wire
