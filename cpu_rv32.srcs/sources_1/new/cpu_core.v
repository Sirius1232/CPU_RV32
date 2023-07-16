//****************************************************************************************//
// Encoding:            UTF-8
//----------------------------------------------------------------------------------------
// File Name:           cpu_core.v
// Descriptions:        cpu核心模块
//-----------------------------------------README-----------------------------------------
// 实现了包含取指、译码、执行、访存、写回五级流水线的32位RISC-V处理器内核。
// 
// 该模块主要包括例化实现流水线的各级模块、数据传递，以及流水线冲刷和数据冲突问题的判断、处理。
// 
//----------------------------------------------------------------------------------------
//****************************************************************************************//

`include "command.vh"

module cpu_core (
        input               clk,
        input               rst_n,
        input               running,
        output      [15:0]  pc,
        input       [31:0]  pc_instr,
        output      [4:0]   ram_ctrl,  // [4:2]:数据长度控制，即funct3；[1]:写；[0]:使用数据存储器
        output      [31:0]  ram_addr,
        input       [31:0]  ram_dout,
        output  reg [31:0]  ram_din
    );

    reg     [31:0]      instruction;
    wire    [15:0]      pc_now;
    wire    [4:0]       stp1_rs1, stp1_rs2, stp1_rd;
    wire    [31:0]      stp1_data1, stp1_data2, stp3_data_rd;
    wire    [2:1]       stp1_rs_en;
    reg     [2:1]       stp2_rs_en;
    wire    [1:0]       imm_en;
    wire    [31:0]      imm1, imm0;
    wire    [31:0]      exu_in1, exu_in2, stp2_exu_out;
    wire    [4:0]       alu_ctrl;
    wire    [2:0]       jmp_ctrl;
    wire                jmp_pred;
    wire    [4:0]       jmp_rs;
    wire    [31:0]      jmp_data_rs;
    reg     [31:0]      jmp_data;
    wire                jmp_reg_en;
    reg                 branch_flag;
    wire                flush_flag;

    reg     [3:1]       load_flg_seq;
    reg                 wait_jmp;
    wire                wait_exe;

    wire                stp1_wr_en;
    wire    [4:0]       stp1_ram_ctrl;
    reg     [15:0]      stp1_pc_now;
    reg                 stp1_jmp_pred;
    wire    [31:0]      stp2_data2;
    reg                 stp2_jmp_pred;
    reg     [4:0]       stp2_rs2;
    reg                 stp2_wr_en, stp3_wr_en;
    reg     [4:0]       stp2_ram_ctrl;
    reg     [4:0]       stp3_ram_ctrl;
    reg     [4:0]       stp2_rd, stp3_rd;
    reg     [31:0]      stp3_out;

    /*数据在流水线间的传递*/
    /*idu的输出*/
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n || flush_flag) begin
            stp1_pc_now <= 16'd0;
            stp1_jmp_pred <= 1'b0;
        end
        else if(wait_exe) begin
            stp1_pc_now <= stp1_pc_now;
            stp1_jmp_pred <= stp1_jmp_pred;
        end
        else if(wait_jmp) begin
            stp1_pc_now <= 16'd0;
            stp1_jmp_pred <= 1'b0;
        end
        else begin
            stp1_pc_now <= pc_now;
            stp1_jmp_pred <= jmp_pred;
        end
    end
    /*exu的输出*/
    assign  ram_ctrl = stp2_ram_ctrl;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n || flush_flag || wait_exe) begin
            stp2_rs_en <= 2'b00;
            stp2_rs2 <= 5'd0;
            stp2_ram_ctrl <= 5'b00000;
            stp2_jmp_pred <= 1'b0;
            branch_flag <= 1'b0;
            stp2_rd <= 5'd0;
            stp2_wr_en <= 1'b0;
        end
        else begin
            stp2_rs_en <= stp1_rs_en;
            stp2_rs2 <= stp1_rs2;
            stp2_ram_ctrl <= stp1_ram_ctrl;
            stp2_jmp_pred <= stp1_jmp_pred;
            branch_flag <= jmp_ctrl[0];
            stp2_rd <= stp1_rd;
            stp2_wr_en <= stp1_wr_en;
        end
    end
    /*mau的输出*/
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            stp3_ram_ctrl <= 5'b00000;
            stp3_out <= 32'd0;
            stp3_rd <= 5'd0;
            stp3_wr_en <= 1'b0;
        end
        else begin
            stp3_ram_ctrl <= stp2_ram_ctrl;
            stp3_out <= stp2_exu_out;
            stp3_rd <= stp2_rd;
            stp3_wr_en <= stp2_wr_en;
        end
    end

    /*load指令记录*/
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n || flush_flag) begin
            load_flg_seq <= 3'b000;
        end
        else if(wait_exe) begin
            load_flg_seq[1] <= load_flg_seq[1];
            load_flg_seq[2] <= 1'b0;
            load_flg_seq[3] <= load_flg_seq[2];
        end
        else if(wait_jmp) begin
            load_flg_seq[1] <= 1'b0;
            load_flg_seq[2] <= load_flg_seq[1];
            load_flg_seq[3] <= load_flg_seq[2];
        end
        else begin
            if(instruction[6:0]==`LOAD)
                load_flg_seq[1] <= 1'b1;
            else
                load_flg_seq[1] <= 1'b0;
            load_flg_seq[2] <= load_flg_seq[1];
            load_flg_seq[3] <= load_flg_seq[2];
        end
    end

    /*流水线冲刷*/
    assign  flush_flag = branch_flag ? stp2_jmp_pred ^ stp2_exu_out[0] : 1'b0;


    /*取指*/
    /*译码+执行 控制 取指*/
    cpu_ifu cpu_ifu_inst(
        .clk            (clk),
        .rst_n          (rst_n),
        .running        (running),
        .flush_flag     (flush_flag),
        .wait_exe       (wait_exe),
        .wait_jmp       (wait_jmp),
        .jmp_pred       (jmp_pred),
        .jmp_reg_en     (jmp_reg_en),
        .jmp_rs         (jmp_rs),
        .jmp_data       (jmp_data),
        .pc_now         (pc_now),
        .pc             (pc),
        .instruction    (pc_instr)
    );
    always @(*) begin
        if(flush_flag)
            instruction = `NOP;
        else if(wait_exe)
            instruction = pc_instr;
        else if(wait_jmp)
            instruction = `NOP;
        else
            instruction = pc_instr;
    end
    /*取指模块的数据冲突问题*/
    always @(*) begin
        if(!jmp_reg_en || jmp_rs==5'd0)  // 非寄存器链接或链接到x0
            wait_jmp = 1'b0;
        else if(jmp_rs==stp1_rd && stp1_wr_en)
            wait_jmp = 1'b1;
        else if(jmp_rs==stp2_rd && stp2_wr_en && load_flg_seq[2])  // 虽然load指令必然会写入，但为了与F扩展一致，还是加上了`stp2_wr_en`
            wait_jmp = 1'b1;
        else
            wait_jmp = 1'b0;
    end
    always @(*) begin
        if(jmp_rs==5'd0)
            jmp_data = 32'd0;
        else if(jmp_rs==stp2_rd)
            jmp_data = stp2_exu_out;
        else if(jmp_rs==stp3_rd)
            jmp_data = stp3_data_rd;
        else
            jmp_data = jmp_data_rs;
    end


    /*stp0-译码-stp1*/
    cpu_idu cpu_idu_inst(
        .clk            (clk),
        .rst_n          (rst_n),
        .flush_flag     (flush_flag),
        .wait_exe       (wait_exe),
        .instruction    (instruction),
        .alu_ctrl       (alu_ctrl),
        .rs_en          (stp1_rs_en),
        .rs1            (stp1_rs1),
        .rs2            (stp1_rs2),
        .rd             (stp1_rd),
        .wr_en          (stp1_wr_en),
        .jmp_ctrl       (jmp_ctrl),
        .ram_ctrl       (stp1_ram_ctrl),
        .imm_en         (imm_en),
        .imm0           (imm0),
        .imm1           (imm1)
    );


    /*stp1-执行-stp2*/
    /*取指+译码 控制 执行*/
    /*执行模块的数据冲突问题*/
    reg                 wait_exe_1, wait_exe_2;
    assign  wait_exe = wait_exe_1 | wait_exe_2;
    always @(*) begin
        if(stp1_rs_en[1] && stp1_rs1!=5'd0 && stp1_rs1==stp2_rd && load_flg_seq[2] && stp2_wr_en)
            wait_exe_1 = 1'b1;
        else
            wait_exe_1 = 1'b0;
    end
    always @(*) begin
        if(stp1_rs_en[2] && stp1_rs2!=5'd0 && stp1_rs2==stp2_rd && load_flg_seq[2] && stp2_wr_en)
            wait_exe_2 = 1'b1;
        else
            wait_exe_2 = 1'b0;
    end
    reg     [31:0]      data1, data2;
    always @(*) begin
        if(stp1_rs_en[1] && stp1_rs1!=5'd0 && stp1_rs1==stp2_rd && stp2_wr_en)  // 执行的输出
            data1 = stp2_exu_out;
        else if(stp1_rs_en[1] && stp1_rs1!=5'd0 && stp1_rs1==stp3_rd && stp3_wr_en)  // 访存的输出
            data1 = stp3_data_rd;
        else
            data1 = stp1_data1;
    end
    always @(*) begin
        if(stp1_rs_en[2] && stp1_rs2!=5'd0 && stp1_rs2==stp2_rd && stp2_wr_en)  // 执行的输出
            data2 = stp2_exu_out;
        else if(stp1_rs_en[2] && stp1_rs2!=5'd0 && stp1_rs2==stp3_rd && stp3_wr_en)  // 访存的输出
            data2 = stp3_data_rd;
        else
            data2 = stp1_data2;
    end
    assign  exu_in1 = jmp_ctrl[1] ? stp1_pc_now : (imm_en[1] ? imm1 : data1);
    assign  exu_in2 = imm_en[0] ? imm0 : data2;
    cpu_exu cpu_exu_inst(
        .clk            (clk),
        .rst_n          (rst_n),
        .flush_flag     (flush_flag),
        .wait_exe       (wait_exe),
        .alu_ctrl       (alu_ctrl),
        .in1            (exu_in1),
        .in2            (exu_in2),
        .out            (stp2_exu_out)
    );


    /*stp2-访存-stp3*/
    /*译码+执行 控制 访存*/
    always @(*) begin
        if(stp2_rs_en[2] && stp2_rs2!=5'd0 && stp2_rs2==stp3_rd && stp3_wr_en)
            ram_din = stp3_data_rd;
        else
            ram_din = stp2_data2;
    end
    assign  ram_addr = stp2_ram_ctrl[0] ? stp2_exu_out : 32'hzzzz;
    assign  stp3_data_rd = stp3_ram_ctrl[0] ? ram_dout : stp3_out;


    /*stp3-写回*/
    /*译码+执行+访存 控制 写回*/
    cpu_reg cpu_reg_inst(
        .clk            (clk),
        .rst_n          (rst_n),
        .rs1            (stp1_rs1),
        .data1          (stp1_data1),
        .rs2            (stp1_rs2),
        .data2          (stp1_data2),
        .jmp_rs         (jmp_rs),
        .data_jmp_rs    (jmp_data_rs),
        .rs4            (stp2_rs2),
        .data4          (stp2_data2),
        .wr_en          (stp3_wr_en),
        .rd             (stp3_rd),
        .data_rd        (stp3_data_rd)
    );



endmodule
