module axi4_uart_bridge (
    input  wire        clk,
    input  wire        rst,
    input  wire        axi_awvalid,
    input  wire [31:0] axi_awaddr,
    input  wire        axi_wvalid,
    input  wire [31:0] axi_wdata,
    output wire        uart_tx,
    output wire        uart_active
);

    reg [7:0] tx_data;
    reg       send;
    wire      tx_done;

    always @(posedge clk) begin
        if (rst) begin
            send <= 0;
        end else if (axi_awvalid && axi_wvalid && axi_awaddr == 32'h00000100) begin
            tx_data <= axi_wdata[7:0];
            send    <= 1;
        end else begin
            send <= 0;
        end
    end


    uart_tx_8n1 uart_tx_inst (
        .clk      (clk),
        .txbyte   (tx_data),
        .senddata (send),
        .txdone   (tx_done),
        .tx       (uart_tx)
    );
    assign uart_active = !tx_done;

endmodule
