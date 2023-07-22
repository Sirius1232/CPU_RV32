//****************************************************************************************//
// Encoding:            UTF-8
//----------------------------------------------------------------------------------------
// File Name:           ram_data.v
// Descriptions:        数据存储器模块（访存模块）
//-----------------------------------------README-----------------------------------------
// 实现对数据存储器的读写控制，以及数据长度控制。
// 
// 数据存储器由4个数据位宽8bit、地址位宽14bit的BRAM组合而成。
// 
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module ram_data (
        input               clk,
        input       [4:0]   ram_ctrl,  // [4:2]:数据长度控制，即funct3；[1]:写；[0]:使用数据存储器
        input       [31:0]  addr,
        input       [31:0]  wr_data,
        output  reg [31:0]  rd_data
    );


    wire    [13:0]      addr_0, addr_1, addr_2, addr_3;
    assign  addr_0 = addr[15:2] + (addr[1]|addr[0]);
    assign  addr_1 = addr[15:2] + addr[1];
    assign  addr_2 = addr[15:2] + (addr[1]&addr[0]);
    assign  addr_3 = addr[15:2];

    wire                enable;
    wire                wr_en;
    assign  enable = ram_ctrl[0];
    assign  wr_en = ram_ctrl[1];

    reg     [2:0]       mask_code;
    reg     [1:0]       rd_order;
    always @(posedge clk) begin
        mask_code <= ram_ctrl[4:2];
        rd_order  <= addr[1:0];
    end

    reg     [31:0]      din;
    reg     [7:0]       din_0, din_1, din_2, din_3;
    wire    [7:0]       dout_0, dout_1, dout_2, dout_3;
    reg     [31:0]      dout;
    /*写入*/
    always @(*) begin
        case (ram_ctrl[3:2])
            2'b00   : din = {24'b0, wr_data[7:0]};
            2'b01   : din = {16'b0, wr_data[15:0]};
            2'b10   : din = wr_data;
            default : din = 32'd0;
        endcase
    end
    always @(*) begin
        case (addr[1:0])
            2'b00   : {din_3, din_2, din_1, din_0} = din;
            2'b01   : {din_0, din_3, din_2, din_1} = din;
            2'b10   : {din_1, din_0, din_3, din_2} = din;
            2'b11   : {din_2, din_1, din_0, din_3} = din;
        endcase
    end
    /*读取*/
    always @(*) begin
        case (mask_code[1:0])
            2'b00   : rd_data = {{24{~mask_code[2]&dout[7]}}, dout[7:0]};
            2'b01   : rd_data = {{16{~mask_code[2]&dout[15]}}, dout[15:0]};
            2'b10   : rd_data = dout;
            default : rd_data = 32'd0;
        endcase
    end
    always @(*) begin
        case (rd_order)
            2'b00   : dout = {dout_3, dout_2, dout_1, dout_0};
            2'b01   : dout = {dout_0, dout_3, dout_2, dout_1};
            2'b10   : dout = {dout_1, dout_0, dout_3, dout_2};
            2'b11   : dout = {dout_2, dout_1, dout_0, dout_3};
        endcase
    end

    dram_8bit dram_8bit_inst_0 (
        .clka       (clk),
        .ena        (enable),
        .wea        (wr_en),
        .addra      (addr_0),
        .dina       (din_0),
        .douta      (dout_0)
    );
    dram_8bit dram_8bit_inst_1 (
        .clka       (clk),
        .ena        (enable),
        .wea        (wr_en),
        .addra      (addr_1),
        .dina       (din_1),
        .douta      (dout_1)
    );
    dram_8bit dram_8bit_inst_2 (
        .clka       (clk),
        .ena        (enable),
        .wea        (wr_en),
        .addra      (addr_2),
        .dina       (din_2),
        .douta      (dout_2)
    );
    dram_8bit dram_8bit_inst_3 (
        .clka       (clk),
        .ena        (enable),
        .wea        (wr_en),
        .addra      (addr_3),
        .dina       (din_3),
        .douta      (dout_3)
    );


endmodule
