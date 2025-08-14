`default_nettype none
module shakti_axi_uart #(
  parameter CLOCK_DIV_WIDTH = 20,
  parameter RX_FIFO_DEPTH   = 64
)(
  input  wire         aclk,
  input  wire         aresetn,

  // AXI4-Lite slave (Shakti peripheral bus)
  input  wire [31:0]  s_axi_awaddr,
  input  wire         s_axi_awvalid,
  output wire         s_axi_awready,
  input  wire [31:0]  s_axi_wdata,
  input  wire [3:0]   s_axi_wstrb,
  input  wire         s_axi_wvalid,
  output wire         s_axi_wready,
  output wire [1:0]   s_axi_bresp,
  output wire         s_axi_bvalid,
  input  wire         s_axi_bready,
  input  wire [31:0]  s_axi_araddr,
  input  wire         s_axi_arvalid,
  output wire         s_axi_arready,
  output wire [31:0]  s_axi_rdata,
  output wire [1:0]   s_axi_rresp,
  output wire         s_axi_rvalid,
  input  wire         s_axi_rready,

  // UART pins
  output wire         uart_txd,
  input  wire         uart_rxd
);

  // APB wires
  wire [11:0] PADDR;
  wire        PSEL, PENABLE, PWRITE;
  wire [31:0] PWDATA, PRDATA;
  wire        PREADY, PSLVERR;

  // Bridge
  axi_lite_to_apb3 #(
    .ADDR_WIDTH (12),
    .DATA_WIDTH (32)
  ) u_bridge (
    .ACLK         (aclk),
    .ARESETn      (aresetn),
    .S_AXI_AWADDR (s_axi_awaddr),
    .S_AXI_AWVALID(s_axi_awvalid),
    .S_AXI_AWREADY(s_axi_awready),
    .S_AXI_WDATA  (s_axi_wdata),
    .S_AXI_WSTRB  (s_axi_wstrb),
    .S_AXI_WVALID (s_axi_wvalid),
    .S_AXI_WREADY (s_axi_wready),
    .S_AXI_BRESP  (s_axi_bresp),
    .S_AXI_BVALID (s_axi_bvalid),
    .S_AXI_BREADY (s_axi_bready),
    .S_AXI_ARADDR (s_axi_araddr),
    .S_AXI_ARVALID(s_axi_arvalid),
    .S_AXI_ARREADY(s_axi_arready),
    .S_AXI_RDATA  (s_axi_rdata),
    .S_AXI_RRESP  (s_axi_rresp),
    .S_AXI_RVALID (s_axi_rvalid),
    .S_AXI_RREADY (s_axi_rready),

    .PADDR        (PADDR),
    .PSEL         (PSEL),
    .PENABLE      (PENABLE),
    .PWRITE       (PWRITE),
    .PWDATA       (PWDATA),
    .PRDATA       (PRDATA),
    .PREADY       (PREADY),
    .PSLVERR      (PSLVERR)
  );

  // Your APB3 UART
  apb3_uart #(
    .CLOCK_DIV_WIDTH (CLOCK_DIV_WIDTH),
    .RX_FIFO_DEPTH   (RX_FIFO_DEPTH)
  ) u_uart (
    .pclk     (aclk),
    .presetn  (aresetn),
    .psel     (PSEL),
    .penable  (PENABLE),
    .pwrite   (PWRITE),
    .paddr    (PADDR),
    .pwdata   (PWDATA),
    .prdata   (PRDATA),
    .pready   (PREADY),
    .pslverr  (PSLVERR),
    .txd      (uart_txd),
    .rxd      (uart_rxd)
  );

  // For the simple UART I gave earlier:
  //   pready  should be 1'b1 inside u_uart
  //   pslverr should be 1'b0 inside u_uart
  // If not already tied there, you can tie them here:
  // assign PREADY  = 1'b1;
  // assign PSLVERR = 1'b0;

endmodule
`default_nettype wire
