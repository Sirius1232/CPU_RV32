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

module cpu_ifu (
        input               clk,
        input               rst_n,
        input               running,  // 程序运行标志
        input       [1:0]   jump_flag,  // [1]:寄存器链接；[0]:跳转标志
        input       [31:0]  jump_rs,
        input       [31:0]  jump_imm,
        output  reg [15:0]  pc_now,  // 程序计数器
        output  reg [15:0]  pc
    );

    reg                 running_d;
    wire                pc_move;

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
        if(~pc_move)  // 为了修复第一条指令无法取出的问题
            pc = 16'd0;
        else if(jump_flag[0]) begin
            if(jump_flag[1])
                pc = jump_rs + jump_imm;
            else
                pc = pc_now + jump_imm;
        end
        else
            pc = pc_now + 16'd4;
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            pc_now <= 16'd0;
        else if(pc_move)
            pc_now <= pc;
        else
            pc_now <= pc_now;
    end


endmodule
