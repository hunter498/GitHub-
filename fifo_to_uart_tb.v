`timescale 1ns / 1ps
`define WR_CLK_PERIOD 8
`define RD_CLK_PERIOD 20
module fifo_to_uart_tb();
reg rxusrclk;
reg clk_50M;
reg resetdone;
reg [63:0] rx_data;
reg [7:0] data;
reg [7:0] rxcharisk;
reg fifo_rd_en;
wire [7:0] fifo_data_out;
wire [9:0] rd_data_count;
wire wr_rst_busy;
wire rd_rst_busy;
fifo_to_uart fifo_to_uart(
    .i_rxusrclk         (rxusrclk           ),
    .i_resetdone        (resetdone          ),
    .i_rx_data          (rx_data            ),
    .i_rxcharisk        (rxcharisk          ),

    .i_clk_50M          (clk_50M            ),
    .i_fifo_rd_en       (fifo_rd_en         ),
    .o_fifo_data_out    (fifo_data_out      ),
    .o_rd_data_count    (rd_data_count      ),
    .o_wr_rst_busy      (wr_rst_busy        ),
    .o_rd_rst_busy      (rd_rst_busy        )
);
initial rxusrclk = 0;
always#(`WR_CLK_PERIOD/2) rxusrclk = ~rxusrclk;
initial clk_50M = 0;
always#(`RD_CLK_PERIOD/2) clk_50M = ~clk_50M;

initial begin
    resetdone = 0;
    rx_data = 64'd0;
    rxcharisk = 8'hff;
    data = 0;
    fifo_rd_en = 0;
    #(`WR_CLK_PERIOD * 1000);
    resetdone = 1;
    #(`WR_CLK_PERIOD * 500);
    wr_data(29,01);

    #(`WR_CLK_PERIOD * 1);
    wr_data(30,02);

    #(`WR_CLK_PERIOD * 10);
    wr_data(31,03);

    fifo_rd_en = 1;
    #(`RD_CLK_PERIOD * 90);
    fifo_rd_en = 0;
end

task wr_data;
    input [15:0] wr_data_cnt;
    input [7:0] type;
    begin
        data = 0;
        rxcharisk = 8'd0;
        rx_data = {8'h7E,type,8'h5D,wr_data_cnt[15:8],8'h5D,wr_data_cnt[7:0],16'h5D_00};
        repeat((wr_data_cnt/4) - 1)
        begin
            #(`WR_CLK_PERIOD);
            rx_data = {8'h5D,data,8'h5D,data,8'h5D,data,8'h5D,data};
            data = data + 1;
        end
        #(`WR_CLK_PERIOD);
        if(((wr_data_cnt)%4) != 0 )
        begin
            case((wr_data_cnt)%4)
            1:rx_data = {8'h5D,8'hff,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
            2:rx_data = {8'h5D,8'hff,8'h5D,8'hff,8'h00,8'h00,8'h00,8'h00};
            3:rx_data = {8'h5D,8'hff,8'h5D,8'hff,8'h5D,8'hff,8'h00,8'h00};
            default:rx_data = {8'h5D,8'h00,8'h5D,8'h00,8'h5D,8'h00,8'h5D,8'h00};
            endcase
            #(`WR_CLK_PERIOD);
        end
        rxcharisk = 8'hff;
    end
endtask
endmodule

//增加一行注释