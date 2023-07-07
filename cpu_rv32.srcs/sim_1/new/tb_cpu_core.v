`timescale 1ns / 1ns

module tb_cpu_core();
    /*System Port*/
    reg                 sys_clk;
    reg                 sys_rst_n;
    reg                 start_flag;
    wire    [15:0]      lc;
    wire    [31:0]      instruction;
    reg     [31:0]      mem[0:1023];

    //----------------Module Instantiation----------------
    // cpu_core cpu_core_inst(
    //     .clk            (sys_clk),
    //     .rst_n          (sys_rst_n),
    //     .running        (running),
    //     .pc             (pc),
    //     .instruction    (instruction)
    // );
    cpu_rv32 cpu_rv32_inst(
        .clk            (sys_clk),
        .rst_n          (sys_rst_n),
        .start_flag     (start_flag),
        .lc             (lc),
        .instr_load     (instruction)
    );
    

    //----------------Test Conditions----------------
    initial begin
        $readmemb("E:/VSCodeProject/project_py/assembler/code.txt", mem);
    end
    assign  instruction = mem[lc[11:2]];

    initial begin
            sys_clk <= 1'b1;
            sys_rst_n <= 1'b0;
            start_flag <= 1'b0;
        #15
            sys_rst_n <= 1'b1;
        #85
            start_flag <= 1'b1;
        #20
            start_flag <= 1'b0;
        #880
            $stop;
    end

    always  #10 sys_clk=~sys_clk;   //clock period 20ns, 50MHz

    // always @(posedge sys_clk or negedge sys_rst_n) begin
    //     if(!sys_rst_n) begin
            
    //     end
    //     else begin
            
    //     end
    // end

endmodule