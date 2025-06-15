     module mkeclass_axi4 (
    input  wire clk,           // External clock (unused since we use internal)
    input  wire rst_n,         // Active-low reset (PIN_23)
    output wire uart_tx,       // UART TX output (PIN_14)
    output wire [3:0] dbg_led  // Debug LEDs (PINs 39,38,40,41)
);

    // ===== Internal 12 MHz Clock =====
    wire int_osc;
    SB_HFOSC #(.CLKHF_DIV("0b10")) u_SB_HFOSC (
        .CLKHFPU(1'b1),
        .CLKHFEN(1'b1),
        .CLKHF(int_osc)  // 12 MHz output
    );

    // ===== Reset Handling =====
    wire rst = ~rst_n;  // Convert to active-high reset
    reg [3:0] reset_sync;
    always @(posedge int_osc) reset_sync <= {reset_sync[2:0], rst};
    wire sync_rst = reset_sync[3];

    // ===== CPU Interfaces =====
    wire [31:0] imem_addr;
    wire        imem_arvalid;
    wire [31:0] dmem_addr, dmem_wdata;
    wire        dmem_awvalid, dmem_wvalid, dmem_arvalid;
    wire [31:0] rom_data;

    // ===== UART Bridge =====
    wire uart_active;
    axi4_uart_bridge uart_bridge (
        .clk         (int_osc),
        .rst         (sync_rst),
        .axi_awvalid (dmem_awvalid),
        .axi_awaddr  (dmem_addr),
        .axi_wvalid  (dmem_wvalid),
        .axi_wdata   (dmem_wdata),
        .uart_tx     (uart_tx),
        .uart_active (uart_active)
    );

    // ===== Instruction Memory =====
    bram instr_mem (
        .clk   (int_osc),
        .addr  (imem_addr[13:0]),  // 16KB memory (14-bit address)
        .rdata (rom_data)
    );

    // ===== Debug LEDs =====
    reg [23:0] led_counter;
    always @(posedge int_osc) begin
        if (sync_rst) led_counter <= 0;
        else led_counter <= led_counter + 1;
    end

    assign dbg_led = {
        dmem_awvalid,            // LED3: Write request
        (dmem_addr == 32'h90000000), // LED2: UART address match
        uart_active,             // LED1: UART transmission active
        led_counter[23]          // LED0: Slow blink (clock alive)
    };

    // ===== SHAKTI E-Class CPU =====
    mkeclass cpu (
        .CLK                   (int_osc),
        .RST_N                 (~sync_rst),  // Active-low reset

        // Instruction fetch
        .master_i_ARVALID      (imem_arvalid),
        .master_i_ARADDR       (imem_addr),
        .master_i_ARREADY      (1'b1),
        .master_i_RVALID       (1'b1),
        .master_i_RRESP        (2'b00),
        .master_i_RDATA        (rom_data),
        .master_i_RLAST        (1'b1),
        .master_i_RID          (4'd0),

        // Data write
        .master_d_AWVALID      (dmem_awvalid),
        .master_d_AWADDR       (dmem_addr),
        .master_d_AWREADY      (1'b1),
        .master_d_WVALID       (dmem_wvalid),
        .master_d_WDATA        (dmem_wdata),
        .master_d_WREADY       (1'b1),
        .master_d_BVALID       (1'b1),
        .master_d_BRESP        (2'b00),
        .master_d_BID          (4'd0),

        // Data read (minimal implementation)
        .master_d_ARVALID      (dmem_arvalid),
        .master_d_ARREADY      (1'b1),
        .master_d_RVALID       (1'b1),
        .master_d_RRESP        (2'b00),
        .master_d_RDATA        (32'h0),
        .master_d_RLAST        (1'b1),
        .master_d_RID          (4'd0),

        // No interrupts
        .sb_ext_interrupt_put      (1'b0),
        .EN_sb_ext_interrupt_put   (1'b0),
        .RDY_sb_ext_interrupt_put  ()
    );

endmodule   