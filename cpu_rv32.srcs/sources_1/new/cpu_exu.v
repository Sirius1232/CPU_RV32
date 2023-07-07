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
        input               clk,
        // input               rst_n,
        input       [4:0]   alu_ctrl,
        input       [31:0]  in1,
        input       [31:0]  in2,
        output  reg [31:0]  out
    );

    //*****************************************************
    //**                    main code
    //*****************************************************

    always @(posedge clk) begin
        case (alu_ctrl)
            /*基础运算*/
            `ALU_AND    : out <= in1 & in2;
            `ALU_OR     : out <= in1 | in2;
            `ALU_XOR    : out <= in1 ^ in2;
            `ALU_SLL    : out <= in1 << in2[4:0];
            `ALU_SRL    : out <= in1 >> in2[4:0];
            `ALU_SRA    : out <= in1 >>> in2[4:0];
            `ALU_ADD    : out <= in1 + in2;
            `ALU_SUB    : out <= in1 - in2;
            /*比较*/
            `ALU_EQ     : out <= in1 == in2;
            `ALU_NE     : out <= in1 != in2;
            `ALU_LT     : out <= {~in1[31],in1[30:0]} < {~in2[31],in2[30:0]};
            `ALU_GE     : out <= {~in1[31],in1[30:0]} >= {~in2[31],in2[30:0]};
            `ALU_LTU    : out <= in1 < in2;
            `ALU_GEU    : out <= in1 >= in2;
            default     : out <= 32'd0;
        endcase
    end


endmodule
