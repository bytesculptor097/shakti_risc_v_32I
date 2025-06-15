module axi4_uart_bridge (
    input  wire        clk,
    input  wire        rst,

    // AXI4-Lite Write Interface
    input  wire        axi_awvalid,
    input  wire [31:0] axi_awaddr,
    input  wire        axi_wvalid,
    input  wire [31:0] axi_wdata,

    // UART Interface
    output wire        uart_tx,
    output wire        uart_active
);

    // ===== UART Control =====
    wire uart_addr_match = (axi_awaddr == 32'h90000000);
    wire uart_send = axi_awvalid && axi_wvalid && uart_addr_match;
    wire [7:0] uart_data = axi_wdata[7:0];

    // ===== Baud Rate Generator =====
    reg [10:0] baud_counter = 0;
    wire baud_tick = (baud_counter == 1250 - 1);  // 9600 baud @12MHz

    always @(posedge clk) begin
        if (rst) baud_counter <= 0;
        else if (baud_tick) baud_counter <= 0;
        else baud_counter <= baud_counter + 1;
    end

    // ===== UART Transmitter =====
    uart_tx_minimal u_uart_tx (
        .clk(clk),
        .baud_tick(baud_tick),
        .data(uart_data),
        .send(uart_send),
        .tx(uart_tx),
        .active(uart_active)
    );

endmodule

`default_nettype wire