module cpu_core (
        input               clk,
        input               rst_n,
        input               running,
        output      [15:0]  pc,
        input       [31:0]  instruction,
        output  reg [4:0]   ex_ram_ctrl,  // [4:2]:数据长度控制，即funct3；[1]:写；[0]:使用数据存储器
        output      [31:0]  addr_data,
        input       [31:0]  ram_dout,
        output      [31:0]  ram_din
    );

    wire    [15:0]      pc_now;
    wire    [4:0]       rs1, rs2, rd;
    wire    [1:0]       imm_en;
    wire    [31:0]      imm1, imm0;
    wire    [31:0]      id_data1, id_data2, data_rd;
    wire    [31:0]      in1, in2, out;
    wire    [4:0]       alu_ctrl;
    wire    [1:0]       jump_flag;  // 待修改
    wire                wr_en;
    wire    [2:0]       jmp_en;
    wire    [4:0]       ram_ctrl;
    wire    [4:0]       jmp_rs;
    wire    [31:0]      jmp_data;


    /*取指*/
    /*译码+执行 控制 取指*/
    assign  jump_flag = {jmp_en[2], jmp_en[1]|jmp_en[0]&out[0]};
    cpu_ifu cpu_ifu_inst(
        .clk            (clk),
        .rst_n          (rst_n),
        .running        (running),
        .jmp_rs         (jmp_rs),
        .jmp_data       (jmp_data),
        .pc_now         (pc_now),
        .pc             (pc),
        .instruction    (instruction)
    );


    /*译码*/
    cpu_idu cpu_idu_inst(
        .clk            (clk),
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
    reg     [15:0]      pc_now_ex;
    always @(posedge clk) begin
        pc_now_ex <= pc_now;
    end


    /*执行*/
    /*取指+译码 控制 执行*/
    assign  in1 = jmp_en[1] ? pc_now_ex : (imm_en[1] ? imm1 : id_data1);
    assign  in2 = imm_en[0] ? imm0 : id_data2;
    cpu_exu cpu_exu_inst(
        .clk            (clk),
        .alu_ctrl       (alu_ctrl),
        .in1            (in1),
        .in2            (in2),
        .out            (out)
    );
    reg     [31:0]      ex_data2;
    always @(posedge clk) begin
        ex_data2 <= id_data2;
        ex_ram_ctrl <= ram_ctrl;
    end


    /*访存*/
    /*译码+执行 控制 访存*/
    assign  addr_data = ex_ram_ctrl[0] ? out : 32'hzzzz;
    assign  ram_din = ex_data2;
    reg     [15:0]      ma_ram_ctrl;
    reg     [31:0]      ma_out;
    always @(posedge clk) begin
        ma_ram_ctrl <= ex_ram_ctrl;
        ma_out <= out;
    end


    /*写回*/
    /*译码+执行+访存 控制 写回*/
    reg     [4:0]       ex_rd, ma_rd;
    reg                 ex_wr_en, ma_wr_en;
    always @(posedge clk) begin
        ex_rd <= rd;
        ma_rd <= ex_rd;
        ex_wr_en <= wr_en;
        ma_wr_en <= ex_wr_en;
    end
    assign  data_rd = ma_ram_ctrl[0] ? ram_dout : ma_out;
    cpu_reg cpu_reg_inst(
        .clk            (clk),
        .rst_n          (rst_n),
        .rs1            (rs1),
        .rs2            (rs2),
        .jmp_rs         (jmp_rs),
        .rd             (ma_rd),
        .wr_en          (ma_wr_en),
        .data_rd        (data_rd),
        .data1          (id_data1),
        .data2          (id_data2),
        .jmp_data       (jmp_data)
    );



endmodule
