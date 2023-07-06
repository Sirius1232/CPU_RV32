//****************************************************************************************//
// Encoding:            UTF-8
//----------------------------------------------------------------------------------------
// File Name:           cpu_exu.v
// Descriptions:        执行模块
//-----------------------------------------README-----------------------------------------
// 
// 
//----------------------------------------------------------------------------------------
//****************************************************************************************//

`include "command.vh"

module cpu_exu (
        // input               clk,
        // input               rst_n,
        input       [4:0]   alu_ctrl,
        input       [31:0]  in1,
        input       [31:0]  in2,
        output      [31:0]  out
    );

    reg     [31:0]      alu_out;

    //*****************************************************
    //**                    main code
    //*****************************************************

    assign  out = alu_out;

    always @(*) begin
        case (alu_ctrl)
            /*基础运算*/
            `ALU_AND    : alu_out = in1 & in2;
            `ALU_OR     : alu_out = in1 | in2;
            `ALU_XOR    : alu_out = in1 ^ in2;
            `ALU_SLL    : alu_out = in1 << in2[4:0];
            `ALU_SRL    : alu_out = in1 >> in2[4:0];
            `ALU_SRA    : alu_out = in1 >>> in2[4:0];
            `ALU_ADD    : alu_out = in1 + in2;
            `ALU_SUB    : alu_out = in1 - in2;
            /*比较*/
            `ALU_EQ     : alu_out = in1 == in2;
            `ALU_NE     : alu_out = in1 != in2;
            `ALU_LT     : alu_out = {~in1[31],in1[30:0]} < {~in2[31],in2[30:0]};
            `ALU_GE     : alu_out = {~in1[31],in1[30:0]} >= {~in2[31],in2[30:0]};
            `ALU_LTU    : alu_out = in1 < in2;
            `ALU_GEU    : alu_out = in1 >= in2;
            default     : alu_out = 32'd0;
        endcase
    end


endmodule
