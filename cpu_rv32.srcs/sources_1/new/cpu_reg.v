//****************************************************************************************//
// Encoding:            UTF-8
//----------------------------------------------------------------------------------------
// File Name:           cpu_reg.v
// Descriptions:        通用寄存器管理模块（写回模块）
//-----------------------------------------README-----------------------------------------
// 实现对通用寄存器的读写控制。
// 
// - 读：简单的组合逻辑电路，根据输入的寄存器地址引出相应的数据即可，不需要时序控制；
// - 写：每一个时钟周期完成一次写操作
// 
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module cpu_reg (
        input               clk,
        input               rst_n,
        input       [4:0]   rs1,
        output      [31:0]  data1,
        input       [4:0]   rs2,
        output      [31:0]  data2,
        input       [4:0]   jmp_rs,
        output      [31:0]  data_jmp_rs,
        input               wr_en,  // 写使能
        input       [4:0]   rd,  // 写寄存器地址
        input       [31:0]  data_rd  // 写数据
    );

    integer i;
    reg     [31:0]      register[0:31];

    //*****************************************************
    //**                    main code
    //*****************************************************

    assign  data1 = register[rs1];
    assign  data2 = register[rs2];
    assign  data_jmp_rs = register[jmp_rs];

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            for(i=0; i<32; i=i+1) begin
                register[i] <= 32'd0;
            end
        end
        else if(wr_en) begin
            if(rd==0)  // x0寄存器为硬件零
                register[0] <= 32'd0;
            else
                register[rd] <= data_rd;
        end
        else begin
            for(i=0; i<32; i=i+1) begin
                register[i] <= register[i];
            end
        end
    end


endmodule
