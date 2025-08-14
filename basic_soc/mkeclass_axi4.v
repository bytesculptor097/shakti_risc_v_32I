module mkeclass_axi4(
    input  wire clk,
    input  wire rst_n,

    // Instruction AXI4 master interface
    output wire imem_arvalid,
    output wire [31:0] imem_araddr,
    input  wire imem_arready,
    input  wire imem_rvalid,
    input  wire [1:0] imem_rresp,
    input  wire [31:0] imem_rdata,
    input  wire imem_rlast,
    input  wire [3:0] imem_rid,

    // Data AXI4 master interface
    output wire dmem_awvalid,
    output wire [31:0] dmem_awaddr,
    input  wire dmem_awready,
    output wire dmem_wvalid,
    output wire [31:0] dmem_wdata,
    input  wire dmem_wready,
    input  wire dmem_bvalid,
    input  wire [1:0] dmem_bresp,
    
    input  wire [3:0] dmem_bid,

    output wire dmem_arvalid,
    input  wire dmem_arready,
    input  wire dmem_rvalid,
    input  wire [1:0] dmem_rresp,
    input  wire [31:0] dmem_rdata,
    input  wire dmem_rlast,
    input  wire [3:0] dmem_rid,

    // Interrupt from PLIC/CLINT
    input wire sb_ext_interrupt_put,
    input wire EN_sb_ext_interrupt_put,
    output wire RDY_sb_ext_interrupt_put
);

    mkeclass cpu (
        .CLK(clk),
        .RST_N(~rst_n),

        .master_i_ARVALID(imem_arvalid),
        .master_i_ARADDR(imem_araddr),
        .master_i_ARREADY(imem_arready),
        .master_i_RVALID(imem_rvalid),
        .master_i_RRESP(imem_rresp),
        .master_i_RDATA(imem_rdata),
        .master_i_RLAST(imem_rlast),
        .master_i_RID(imem_rid),

        .master_d_AWVALID(dmem_awvalid),
        .master_d_AWADDR(dmem_awaddr),
        .master_d_AWREADY(dmem_awready),
        .master_d_WVALID(dmem_wvalid),
        .master_d_WDATA(dmem_wdata),
        .master_d_WREADY(dmem_wready),
        .master_d_BVALID(dmem_bvalid),
        .master_d_BRESP(dmem_bresp),
        .master_d_BID(dmem_bid),

        .master_d_ARVALID(dmem_arvalid),
        .master_d_ARREADY(dmem_arready),
        .master_d_RVALID(dmem_rvalid),
        .master_d_RRESP(dmem_rresp),
        .master_d_RDATA(dmem_rdata),
        .master_d_RLAST(dmem_rlast),
        .master_d_RID(dmem_rid),

        .sb_ext_interrupt_put(sb_ext_interrupt_put),
        .EN_sb_ext_interrupt_put(EN_sb_ext_interrupt_put),
        .RDY_sb_ext_interrupt_put(RDY_sb_ext_interrupt_put)
    );

endmodule

