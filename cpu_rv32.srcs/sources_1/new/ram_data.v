//****************************************************************************************//
// Encoding:            UTF-8
//----------------------------------------------------------------------------------------
// File Name:           ram_data.v
// Descriptions:        数据存储器模块（访存模块）
//-----------------------------------------README-----------------------------------------
// 实现对数据存储器的读写控制，以及数据长度控制。
// 
// 数据存储器数据位宽32bit、地址位宽32bit。
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

    wire                enable;
    wire                wr_en;
    assign  enable = ram_ctrl[0];
    assign  wr_en = ram_ctrl[1];

    reg     [2:0]       mask_code;
    always @(posedge clk) begin
        mask_code <= ram_ctrl[4:2];
    end

    reg     [31:0]      din;
    wire    [31:0]      dout;
    /*写入*/
    always @(*) begin
        case (ram_ctrl[3:2])
            2'b00 : din = {24'b0, wr_data[7:0]};
            2'b01 : din = {16'b0, wr_data[15:0]};
            2'b10 : din = wr_data;
            default:din = 32'd0;
        endcase
    end
    /*读取*/
    always @(*) begin
        case (mask_code[1:0])
            2'b00 : rd_data = {{24{~mask_code[2]&dout[7]}}, dout[7:0]};
            2'b01 : rd_data = {{16{~mask_code[2]&dout[15]}}, dout[15:0]};
            2'b10 : rd_data = dout;
            default:rd_data = 32'd0;
        endcase
    end

    dram dram_inst (
        .clka       (clk),
        .ena        (enable),
        .wea        (wr_en),
        .addra      (addr[7:0]),
        .dina       (din),
        .douta      (dout)
    );


endmodule
