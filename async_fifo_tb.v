`timescale 1ns/1ns
`include "async_fifo.v"

`define RCLK 18
`define WCLK 10

module async_fifo_tb;

logic [7:0] i_wdata_in;
logic i_wclk;
logic i_rclk;
logic i_rd;
logic i_wr;
logic i_wreset_n;
logic i_rreset_n;
logic o_rempty;
logic o_wfull;
logic [7:0] o_rdata_out;

Async_fifo DUT(
    .i_wdata_in(i_wdata_in),
    .i_wclk(i_wclk),
    .i_rclk(i_rclk),
    .i_rd(i_rd),
    .i_wr(i_wr),
    .i_wreset_n(i_wreset_n),
    .i_rreset_n(i_rreset_n),
    .o_rempty(o_rempty),
    .o_wfull(o_wfull),
    .o_rdata_out(o_rdata_out)
);

always #(`RCLK/2) i_rclk = ~i_rclk;

always #(`WCLK/2) i_wclk = ~i_wclk;

initial begin
    i_wdata_in <= 0;
    i_wclk <= 1;
    i_rclk <= 1;
    i_rd <= 0;
    i_wr <= 0;
    i_wreset_n <= 1;
    i_rreset_n <= 1;
end

integer i;

initial begin
    $dumpfile("async_fifo.vcd");
    $dumpvars(0, async_fifo_tb);

    #10;
    i_wreset_n = 1'b0;    //reset system
    i_rreset_n = 1'b0;

    #10;
    i_wreset_n = 1'b1;    //finish reset
    i_rreset_n = 1'b1;

    //write data:
    i_wr = 1'b1;
    i_rd = 1'b0;

    for(i = 0; i < 8; i = i + 1) begin
        i_wdata_in = i;
        #(`WCLK);
    end

    //read data:
    #(`WCLK);
    i_wr = 1'b0;
    #(`WCLK);
    i_rd = 1'b1;
    
    for(i = 0; i < 8; i = i + 1) begin
        #(`RCLK);
    end

    //write data:
    #6
    #(`WCLK);
    i_rd = 1'b0;
    #(`WCLK);
    i_wr = 1'b1;
    
    for(i = 8; i < 16; i = i + 1) begin
        i_wdata_in = i;
        #(`WCLK);
    end
    
    $display("test complete");
    $finish;
end

endmodule