//****************************************************************************************//
// Encoding:            UTF-8
//----------------------------------------------------------------------------------------
// File Name:           cpu_rv32.v
// Descriptions:        cpu顶层模块
//-----------------------------------------README-----------------------------------------
// 包含核心模块cpu_core、指令存储器ram_instr、数据存储器ram_data，用于控制系统的空闲、程序下载、程序运行三个状态。
// 
// 指令存储器数据位宽32bit、地址位宽14bit；
// 数据存储器数据位宽32bit、地址位宽32bit
// 
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module cpu_rv32 (
        input               clk,
        input               rst_n,
        input               start_flag,  // 系统开始工作
        output  reg [15:0]  lc,  // 下载程序计数器
        input       [31:0]  instr_load
    );

    `define     STOP    7'b1111100

    wire    [15:0]      pc;
    wire    [31:0]      instruction;

    reg     [3:0]       state;
    //SM State Define
    localparam  IDLE = 4'd0;
    localparam  LOAD = 4'd1;
    localparam  RUN  = 4'd2;
    /*State Machine*/
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state <= IDLE;
        end
        else begin
            case (state)
                IDLE : begin
                    if(start_flag)
                        state <= LOAD;
                    else
                        state <= IDLE;
                end
                LOAD : begin
                    if(instr_load[6:0] == `STOP)
                        state <= RUN;
                    else
                        state <= LOAD;
                end
                RUN : begin
                    if(instruction[6:0] == `STOP)
                        state <= IDLE;
                    else
                        state <= RUN;
                end
                default : state <= IDLE;
            endcase
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            lc <= 16'd0;
        end
        else begin
            case (state)
                IDLE : lc <= 16'd0;
                LOAD : lc <= lc + 16'd4;
                RUN :  lc <= 16'd0;
                default : lc <= 16'd0;
            endcase
        end
    end

    wire                loading, running;
    assign  loading = (state==LOAD) ? 1'b1 : 1'b0;
    assign  running = (state==RUN ) ? 1'b1 : 1'b0;

    wire    [13:0]      addr_i;
    assign  addr_i = {14{loading}}&lc[13:0] | {14{running}}&pc[13:0];

    wire    [4:0]       ram_ctrl;
    wire    [63:0]      ram_dout, ram_din;
    wire    [31:0]      addr_d;

    cpu_core cpu_core_inst(
        .clk            (clk),
        .rst_n          (rst_n),
        .running        (running),
        .pc             (pc),
        .pc_instr       (instruction),
        .ram_ctrl       (ram_ctrl),
        .ram_addr       (addr_d),
        .ram_dout       (ram_dout),
        .ram_din        (ram_din)
    );

    ram_instr ram_instr_inst(
        .clk            (clk),
        .addr           (addr_i),
        .wr_en          (loading),
        .wr_data        (instr_load),
        .rd_en          (running),
        .rd_data        (instruction)
    );

    ram_data ram_data_inst(
        .clk            (clk),
        .ram_ctrl       (ram_ctrl),
        .addr           (addr_d),
        .wr_data        (ram_din),
        .rd_data        (ram_dout)
    );


endmodule
