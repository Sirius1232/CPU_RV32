`include "command.vh"

module alu_fp (
        input       [4:0]   alu_ctrl,
        input       [31:0]  in1,
        input       [31:0]  in2,
        output  reg [31:0]  out
    );

    wire    [31:0]      fadd, fmul, fdiv, fsqrt;
    wire                feq, flt;

    //*****************************************************
    //**                    main code
    //*****************************************************

    always @(*) begin
        case (alu_ctrl)
            /*基础运算*/
            `ALU_FADD   : out <= fadd;
            `ALU_FSUB   : out <= fadd;
            `ALU_FMUL   : out <= fmul;
            `ALU_FDIV   : out <= fdiv;
            `ALU_FSQRT  : out <= fsqrt;
            `ALU_FMIN   : out <= flt ? in1 : in2;
            `ALU_FMAX   : out <= flt ? in2 : in1;
            `ALU_FSGNJ  : out <= {in2[31], in1[30:0]};
            `ALU_FSGNJN : out <= {~in2[31], in1[30:0]};
            `ALU_FSGNJX : out <= {in1[31]^in2[31], in1[30:0]};
            `ALU_FEQ    : out <= feq;
            `ALU_FLT    : out <= flt;
            `ALU_FLE    : out <= feq | flt;
            default     : out <= 32'd0;
        endcase
    end

    fp32_addsub fp32_addsub_inst (
        .s_axis_a_tvalid        (1'b1),
        .s_axis_a_tdata         (in1),
        .s_axis_b_tvalid        (1'b1),
        .s_axis_b_tdata         ({alu_ctrl[0]^in2[31], in2[30:0]}),
        .m_axis_result_tvalid   (),
        .m_axis_result_tdata    (fadd)
    );
    fp32_mul fp32_mul_inst (
        .s_axis_a_tvalid        (1'b1),
        .s_axis_a_tdata         (in1),
        .s_axis_b_tvalid        (1'b1),
        .s_axis_b_tdata         (in2),
        .m_axis_result_tvalid   (),
        .m_axis_result_tdata    (fmul)
    );
    fp32_div fp32_div_inst (
        .s_axis_a_tvalid        (1'b1),
        .s_axis_a_tdata         (in1),
        .s_axis_b_tvalid        (1'b1),
        .s_axis_b_tdata         (in2),
        .m_axis_result_tvalid   (),
        .m_axis_result_tdata    (fdiv)
    );
    fp32_sqrt fp32_sqrt_inst (
        .s_axis_a_tvalid        (1'b1),
        .s_axis_a_tdata         (in1),
        .m_axis_result_tvalid   (),
        .m_axis_result_tdata    (fsqrt)
    );

    fp32_cmp_eq fp32_cmp_eq_inst (
        .s_axis_a_tvalid        (1'b1),
        .s_axis_a_tdata         (in1),
        .s_axis_b_tvalid        (1'b1),
        .s_axis_b_tdata         (in2),
        .m_axis_result_tvalid   (),
        .m_axis_result_tdata    (feq)
    );
    fp32_cmp_lt fp32_cmp_lt_inst (
        .s_axis_a_tvalid        (1'b1),
        .s_axis_a_tdata         (in1),
        .s_axis_b_tvalid        (1'b1),
        .s_axis_b_tdata         (in2),
        .m_axis_result_tvalid   (),
        .m_axis_result_tdata    (flt)
    );


endmodule
