`timescale 1ns / 1ps

module bram_tb;

    // Testbench signals
    reg clk;
    reg [31:0] addr;
    wire [31:0] rdata;

    // Instantiate the bram module
    bram uut (
        .clk(clk),
        .addr(addr),
        .rdata(rdata)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period
    end

    // Test stimulus
    initial begin
        // Optionally preload mem with some values if firmware.hex is not present
        // Can be done by overriding $readmemh in the bram module for simulation purposes
        
        // Wait for global reset
        #20;

        // Test different address reads
        addr = 0;      #10; $display("rdata @ addr %h = %h", addr, rdata);
        addr = 4;      #10; $display("rdata @ addr %h = %h", addr, rdata);
        addr = 8;      #10; $display("rdata @ addr %h = %h", addr, rdata);
        addr = 1020;   #10; $display("rdata @ addr %h = %h", addr, rdata);
        addr = 4096;   #10; $display("rdata @ addr %h = %h", addr, rdata); // Out of range, should read default

        // Add additional test cases if needed

        #20;
        $finish;
    end

endmodule