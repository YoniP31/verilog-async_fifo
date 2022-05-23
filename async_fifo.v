module async_fifo(
    input [7:0] i_wdata_in,
    input i_wclk,
    input i_rclk,
    input i_rd,
    input i_wr,
    input i_wreset_n,
    input i_rreset_n,
    output wire o_rempty,
    output wire o_wfull,
    output reg [7:0] o_rdata_out
);

//8 * 8 memory
logic [7:0] fifo_ram[0:7];

logic [2:0] wgray, wbin, wq2_rgray, wq1_rgray;
logic [2:0] rgray, rbin, rq2_wgray, rq1_wgray;

//read and write addresses
logic [2:0] raddr, waddr;

//counters
logic [3:0] count;

//crossing the read pointer rgray clock domains
always @(posedge i_wclk or negedge i_wreset_n) begin
    if(!i_wreset_n) begin
        wq2_rgray <= 'b0; 
        wq1_rgray <= 'b0;
    end else begin
        wq2_rgray <= wq1_rgray;
        wq1_rgray <= rgray;
    end
end

//setting the write pointer and gray coding it
always @(posedge i_wclk or negedge i_wreset_n) begin
    if(!i_wreset_n) begin
        wbin <= 'b0;
        wgray <= 'b0;
    end else if(i_wr) begin
        wbin <= wbin + 1;
        wgray <= (wbin >> 1) ^ wbin;
    end
end

assign waddr = wbin[2:0];

//adding to count when writing
always @(posedge i_wclk or negedge i_wreset_n) begin
    if(!i_wreset_n)
        count <= 'b0;
    else if((i_wr) && (!i_rd)) begin
        if(count + 1 > 8)
            count <= count;
        else
            count <= count + 1;
    end
    else if((i_wr) && (i_rd))
        count <= count;
end

//subtracting from count when reading
always @(posedge i_rclk or negedge i_rreset_n) begin
    if(!i_rreset_n)
        count <= 'b0;
    else if((i_rd) && (!i_wr)) begin
        if((count - 1)  == -4'hf)
            count <= count;
        else
            count <= count - 1;
    end
    else if((i_rd) && (i_wr))
        count <= count;
end

//setting o_wfull and o_rempty
assign o_wfull = (count == 8);
assign o_rempty = (count == 0);

//write to FIFO
always_ff @ (posedge i_wclk) begin
    if((i_wr) && (!o_wfull))
        fifo_ram[waddr] <= i_wdata_in;
end

//crossing the write pointer wgray domains
always @(posedge i_rclk or negedge i_rreset_n) begin
    if(!i_rreset_n) begin
        rq2_wgray <= 'b0;
        rq1_wgray <= 'b0;
    end else begin
        rq2_wgray <= rq1_wgray;
        rq1_wgray <= wgray;
    end
end

//setting the read pointer and gray coding it
always @(posedge i_rclk or negedge i_rreset_n) begin
    if(!i_rreset_n) begin
        rbin <= 'b0;
        rgray <= 'b0;
    end else if(i_rd && !o_rempty) begin
        rbin <= rbin + 1;
        rgray <= (rbin >> 1) ^ rbin;
    end
end

assign raddr = rbin[2:0];

//read from FIFO
always_ff @ (posedge i_rclk) begin
    if((i_rd) && (!o_rempty))
        o_rdata_out <= fifo_ram[raddr];
end

endmodule