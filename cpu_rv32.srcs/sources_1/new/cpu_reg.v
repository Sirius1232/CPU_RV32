//****************************************************************************************//
// Encoding:            UTF-8
//----------------------------------------------------------------------------------------
// File Name:           cpu_reg.v
// Descriptions:        通用寄存器管理模块
//-----------------------------------------README-----------------------------------------
// 
// 
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module cpu_reg (
        input               clk,
        input               rst_n,
        input       [4:0]   rs1,
        input       [4:0]   rs2,
        input       [4:0]   jmp_rs,
        input       [4:0]   rd,
        input               wr_en,
        input       [31:0]  data_rd,
        output      [31:0]  data1,
        output      [31:0]  data2,
        output      [31:0]  jmp_data
    );

    integer i;
    reg     [31:0]      register[0:31];

    //*****************************************************
    //**                    main code
    //*****************************************************

    assign  data1 = register[rs1];
    assign  data2 = register[rs2];
    assign  jmp_data = register[jmp_rs];

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            for(i=0; i<32; i=i+1) begin
                register[i] <= 32'd0;
            end
        end
        else if(wr_en) begin
            if(rd==0)
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
