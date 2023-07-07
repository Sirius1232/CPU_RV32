module cpu_core (
        input               clk,
        input               rst_n,
        input               running,
        output      [15:0]  pc_next,
        input       [31:0]  instruction,
        output      [4:0]   ram_ctrl,  // [4:2]:数据长度控制，即funct3；[1]:写；[0]:使用数据存储器
        output      [31:0]  addr_data,
        input       [31:0]  ram_dout,
        output      [31:0]  ram_din
    );

    wire    [15:0]      pc;
    wire    [4:0]       rs1, rs2, rd;
    wire    [1:0]       imm_en;
    wire    [31:0]      imm1, imm0;
    wire    [31:0]      data1, data2, data_rd;
    wire    [31:0]      in1, in2, out;
    wire    [4:0]       alu_ctrl;
    wire    [1:0]       jump_flag;  // 待修改
    wire                wr_en;
    wire    [2:0]       jmp_en;

    assign  addr_data = ram_ctrl[0] ? out : 32'hzzzz;
    assign  ram_din = data2;

    assign  data_rd = ram_ctrl[0] ? ram_dout : out;
    assign  in1 = jmp_en[1] ? pc : (imm_en[1] ? imm1 : data1);
    assign  in2 = imm_en[0] ? imm0 : data2;

    assign  jump_flag = {jmp_en[2], jmp_en[1]|jmp_en[0]&out[0]};

    cpu_ifu cpu_ifu_inst(
        .clk            (clk),
        .rst_n          (rst_n),
        .running        (running),
        .jump_flag      (jump_flag),
        .jump_rs        (data1),
        .jump_imm       (imm1),
        .pc             (pc),
        .pc_next        (pc_next)
    );

    cpu_idu cpu_idu_inst(
        .instruction    (instruction),
        .alu_ctrl       (alu_ctrl),
        .rs1            (rs1),
        .rs2            (rs2),
        .rd             (rd),
        .wr_en          (wr_en),
        .jmp_en         (jmp_en),
        .ram_ctrl       (ram_ctrl),
        .imm_en         (imm_en),
        .imm0           (imm0),
        .imm1           (imm1)
    );

    cpu_exu cpu_exu_inst(
        .alu_ctrl       (alu_ctrl),
        .in1            (in1),
        .in2            (in2),
        .out            (out)
    );

    cpu_reg cpu_reg_inst(
        .clk            (clk),
        .rst_n          (rst_n),
        .running        (running),
        .rs1            (rs1),
        .rs2            (rs2),
        .rd             (rd),
        .wr_en          (wr_en),
        .data_rd        (data_rd),
        .data1          (data1),
        .data2          (data2)
    );



endmodule
