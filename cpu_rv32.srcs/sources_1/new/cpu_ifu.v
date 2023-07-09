//****************************************************************************************//
// Encoding:            UTF-8
//----------------------------------------------------------------------------------------
// File Name:           cpu_ifu.v
// Descriptions:        取指模块
//-----------------------------------------README-----------------------------------------
// 
// 
//----------------------------------------------------------------------------------------
//****************************************************************************************//

`include "command.vh"

module cpu_ifu (
        input               clk,
        input               rst_n,
        input               running,  // 程序运行标志
        input               flush_flag,
        input               wait_exe,
        output  reg         jmp_pred,  // 跳转预测标志
        output  reg         jmp_reg_en,
        output      [4:0]   jmp_rs,
        input       [31:0]  jmp_data,
        input               wait_jmp,
        output  reg [15:0]  pc_now,  // 程序计数器
        output  reg [15:0]  pc,
        input       [31:0]  instruction
    );

    reg                 running_d;
    wire                pc_move;

    reg     [31:0]      jmp_imm;

    reg     [15:0]      pc_branch;
    reg     [15:0]      flush_pc[0:1];

    /*指令片段拆分*/
    wire    [6:0]       opcode;
    wire    [11:0]      imm_i;
    wire    [19:0]      imm_j;
    wire    [11:0]      imm_b;
    assign  opcode = instruction[6:0];
    assign  imm_i = instruction[31:20];
    assign  imm_j = {instruction[31],instruction[19:12],instruction[20],instruction[30:21]};
    assign  imm_b = {instruction[31], instruction[7], instruction[30:25], instruction[11:8]};

    assign  jmp_rs = instruction[19:15];

    //*****************************************************
    //**                    main code
    //*****************************************************
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            running_d <= 1'b0;
        else
            running_d <= running;
    end
    assign  pc_move = running_d & running;

    always @(*) begin
        if(~pc_move) begin  // 为了修复第一条指令无法取出的问题
            pc = 16'd0;
            pc_branch = 16'd0;
        end
        else if(flush_flag) begin
            pc = flush_pc[1];
            pc_branch = 16'd0;
        end
        else if(wait_exe) begin
            pc = pc_now;
            pc_branch = pc_now;
        end
        else if(wait_jmp) begin
            pc = pc_now;
            pc_branch = pc_now;
        end
        else if(jmp_pred) begin
            if(jmp_reg_en)
                pc = jmp_data + jmp_imm;
            else
                pc = pc_now + jmp_imm;
            pc_branch = pc_now + 16'd4;
        end
        else begin
            pc = pc_now + 16'd4;
            pc_branch = pc_now + 16'd4;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            pc_now <= 16'd0;
        else if(pc_move)
            pc_now <= pc;
        else
            pc_now <= pc_now;
    end


    /*分支预测机制*/
    always @(*) begin
        case (opcode)
            `JAL        : begin
                jmp_pred = 1'b1;
                jmp_reg_en = 1'b0;
                jmp_imm = {{11{imm_j[19]}}, imm_j, 1'b0};  // 末尾补0相当于左移一位
            end
            `JALR       : begin
                jmp_pred = 1'b1;
                jmp_reg_en = 1'b1;
                jmp_imm = {{20{imm_i[11]}}, imm_i};
            end
            `BRANCH     : begin
                jmp_pred = 1'b1;  //默认预测为跳
                jmp_reg_en = 1'b0;
                jmp_imm = {{19{imm_b[11]}}, imm_b, 1'b0};  // 末尾补0相当于左移一位
            end
            default     : begin
                jmp_pred = 1'b0;
                jmp_reg_en = 1'b0;
                jmp_imm = 32'd0;
            end
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            flush_pc[0] <= 16'd0;
            flush_pc[1] <= 16'd0;
        end
        else begin
            flush_pc[0] <= pc_branch;
            flush_pc[1] <= flush_pc[0];
        end
    end


endmodule
