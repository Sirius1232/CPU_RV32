//****************************************************************************************//
// Encoding:            UTF-8
//----------------------------------------------------------------------------------------
// File Name:           ram_instr.v
// Descriptions:        指令存储器模块
//-----------------------------------------README-----------------------------------------
// 实现对指令存储器的读写控制。
// 
// 指令存储器由2个数据位宽16bit、地址位宽14bit的BRAM组合而成。
// 
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module ram_instr (
        input               clk,
        input       [15:0]  addr,
        input               wr_en,
        input       [31:0]  wr_data,
        input               rd_en,
        output      [31:0]  rd_data
    );

    wire                enable;
    assign  enable = wr_en ^ rd_en;

    wire    [13:0]      addr_0, addr_1;
    assign  addr_0 = addr[15:2] + addr[1];
    assign  addr_1 = addr[15:2];

    reg                 rd_order;
    wire    [15:0]      rd_data_0, rd_data_1;
    assign  rd_data = rd_order ? {rd_data_0, rd_data_1} : {rd_data_1, rd_data_0};

    always @(posedge clk) begin
        if(enable)
            rd_order <= addr[1];
        else
            rd_order <= rd_order;
    end

    iram_16bit iram_16bit_inst_0 (
        .clka       (clk),
        .ena        (enable),
        .wea        (wr_en),  // ram 读写使能信号,高电平写入,低电平读出
        .addra      (addr_0),
        .dina       (wr_data[15:0]),
        .douta      (rd_data_0)
    );

    iram_16bit iram_16bit_inst_1 (
        .clka       (clk),
        .ena        (enable),
        .wea        (wr_en),  // ram 读写使能信号,高电平写入,低电平读出
        .addra      (addr_1),
        .dina       (wr_data[31:16]),
        .douta      (rd_data_1)
    );


endmodule
