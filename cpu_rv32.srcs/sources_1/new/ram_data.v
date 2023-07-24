//****************************************************************************************//
// Encoding:            UTF-8
//----------------------------------------------------------------------------------------
// File Name:           ram_data.v
// Descriptions:        数据存储器模块（访存模块）
//-----------------------------------------README-----------------------------------------
// 实现对数据存储器的读写控制，以及数据长度控制。
// 
// 数据存储器由8个数据位宽8bit、地址位宽13bit的BRAM组合而成。
// 
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module ram_data (
        input               clk,
        input       [4:0]   ram_ctrl,  // [4:2]:数据长度控制，即funct3；[1]:写；[0]:使用数据存储器
        input       [31:0]  addr,
        input       [63:0]  wr_data,
        output  reg [63:0]  rd_data
    );


    wire    [12:0]      addr_0, addr_1, addr_2, addr_3, addr_4, addr_5, addr_6, addr_7;
    assign  addr_0 = addr[15:3] + (addr[2]|addr[1]|addr[0]);
    assign  addr_1 = addr[15:3] + (addr[2]|addr[1]);
    assign  addr_2 = addr[15:3] + (addr[2]|(addr[1]&addr[0]));
    assign  addr_3 = addr[15:3] + addr[2];
    assign  addr_4 = addr[15:3] + (addr[2]&(addr[1]|addr[0]));
    assign  addr_5 = addr[15:3] + (addr[2]&addr[1]);
    assign  addr_6 = addr[15:3] + (addr[2]&addr[1]&addr[0]);
    assign  addr_7 = addr[15:3];

    wire                enable;
    reg     [7:0]       wr_en, wr_en_t;
    assign  enable = ram_ctrl[0];
    always @(*) begin
        case (ram_ctrl[3:1])
            3'b001  : wr_en_t = 8'b0000_0001;
            3'b011  : wr_en_t = 8'b0000_0011;
            3'b101  : wr_en_t = 8'b0000_1111;
            3'b111  : wr_en_t = 8'b1111_1111;
            default : wr_en_t = 8'b0000_0000;
        endcase
    end
    always @(*) begin
        case (addr[2:0])
            3'b000  : wr_en = wr_en_t;
            3'b001  : wr_en = {wr_en_t[6:0], wr_en_t[7]};
            3'b010  : wr_en = {wr_en_t[5:0], wr_en_t[7:6]};
            3'b011  : wr_en = {wr_en_t[4:0], wr_en_t[7:5]};
            3'b100  : wr_en = {wr_en_t[3:0], wr_en_t[7:4]};
            3'b101  : wr_en = {wr_en_t[2:0], wr_en_t[7:3]};
            3'b110  : wr_en = {wr_en_t[1:0], wr_en_t[7:2]};
            3'b111  : wr_en = {wr_en_t[0], wr_en_t[7:1]};
        endcase
    end

    reg     [2:0]       mask_code;
    reg     [2:0]       rd_order;
    always @(posedge clk) begin
        mask_code <= ram_ctrl[4:2];
        rd_order  <= addr[2:0];
    end

    reg     [63:0]      din;
    reg     [7:0]       din_0, din_1, din_2, din_3, din_4, din_5, din_6, din_7;
    wire    [7:0]       dout_0, dout_1, dout_2, dout_3, dout_4, dout_5, dout_6, dout_7;
    reg     [63:0]      dout;
    /*写入*/
    always @(*) begin
        case (ram_ctrl[3:2])
            2'b00   : din = {56'b0, wr_data[7:0]};
            2'b01   : din = {48'b0, wr_data[15:0]};
            2'b10   : din = {32'b0, wr_data[31:0]};
            2'b11   : din = wr_data;
        endcase
    end
    always @(*) begin
        case (addr[2:0])
            3'b000  : {din_7, din_6, din_5, din_4, din_3, din_2, din_1, din_0} = din;
            3'b001  : {din_0, din_7, din_6, din_5, din_4, din_3, din_2, din_1} = din;
            3'b010  : {din_1, din_0, din_7, din_6, din_5, din_4, din_3, din_2} = din;
            3'b011  : {din_2, din_1, din_0, din_7, din_6, din_5, din_4, din_3} = din;
            3'b100  : {din_3, din_2, din_1, din_0, din_7, din_6, din_5, din_4} = din;
            3'b101  : {din_4, din_3, din_2, din_1, din_0, din_7, din_6, din_5} = din;
            3'b110  : {din_5, din_4, din_3, din_2, din_1, din_0, din_7, din_6} = din;
            3'b111  : {din_6, din_5, din_4, din_3, din_2, din_1, din_0, din_7} = din;
        endcase
    end
    /*读取*/
    always @(*) begin
        case (mask_code[1:0])
            2'b00   : rd_data = {{56{~mask_code[2]&dout[7]}}, dout[7:0]};
            2'b01   : rd_data = {{48{~mask_code[2]&dout[15]}}, dout[15:0]};
            2'b10   : rd_data = {{32{~mask_code[2]&dout[31]}}, dout[31:0]};
            2'b11   : rd_data = dout;
        endcase
    end
    always @(*) begin
        case (rd_order)
            3'b000  : dout = {dout_7, dout_6, dout_5, dout_4, dout_3, dout_2, dout_1, dout_0};
            3'b001  : dout = {dout_0, dout_7, dout_6, dout_5, dout_4, dout_3, dout_2, dout_1};
            3'b010  : dout = {dout_1, dout_0, dout_7, dout_6, dout_5, dout_4, dout_3, dout_2};
            3'b011  : dout = {dout_2, dout_1, dout_0, dout_7, dout_6, dout_5, dout_4, dout_3};
            3'b100  : dout = {dout_3, dout_2, dout_1, dout_0, dout_7, dout_6, dout_5, dout_4};
            3'b101  : dout = {dout_4, dout_3, dout_2, dout_1, dout_0, dout_7, dout_6, dout_5};
            3'b110  : dout = {dout_5, dout_4, dout_3, dout_2, dout_1, dout_0, dout_7, dout_6};
            3'b111  : dout = {dout_6, dout_5, dout_4, dout_3, dout_2, dout_1, dout_0, dout_7};
        endcase
    end

    dram_8bit dram_8bit_inst_0 (
        .clka       (clk),
        .ena        (enable),
        .wea        (wr_en[0]),
        .addra      (addr_0),
        .dina       (din_0),
        .douta      (dout_0)
    );
    dram_8bit dram_8bit_inst_1 (
        .clka       (clk),
        .ena        (enable),
        .wea        (wr_en[1]),
        .addra      (addr_1),
        .dina       (din_1),
        .douta      (dout_1)
    );
    dram_8bit dram_8bit_inst_2 (
        .clka       (clk),
        .ena        (enable),
        .wea        (wr_en[2]),
        .addra      (addr_2),
        .dina       (din_2),
        .douta      (dout_2)
    );
    dram_8bit dram_8bit_inst_3 (
        .clka       (clk),
        .ena        (enable),
        .wea        (wr_en[3]),
        .addra      (addr_3),
        .dina       (din_3),
        .douta      (dout_3)
    );
    
    dram_8bit dram_8bit_inst_4 (
        .clka       (clk),
        .ena        (enable),
        .wea        (wr_en[4]),
        .addra      (addr_4),
        .dina       (din_4),
        .douta      (dout_4)
    );
    dram_8bit dram_8bit_inst_5 (
        .clka       (clk),
        .ena        (enable),
        .wea        (wr_en[5]),
        .addra      (addr_5),
        .dina       (din_5),
        .douta      (dout_5)
    );
    dram_8bit dram_8bit_inst_6 (
        .clka       (clk),
        .ena        (enable),
        .wea        (wr_en[6]),
        .addra      (addr_6),
        .dina       (din_6),
        .douta      (dout_6)
    );
    dram_8bit dram_8bit_inst_7 (
        .clka       (clk),
        .ena        (enable),
        .wea        (wr_en[7]),
        .addra      (addr_7),
        .dina       (din_7),
        .douta      (dout_7)
    );


endmodule
