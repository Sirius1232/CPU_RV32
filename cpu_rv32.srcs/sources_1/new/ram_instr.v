module ram_instr (
        input               clk,
        input       [13:0]  addr,
        input               wr_en,
        input       [31:0]  wr_data,
        input               rd_en,
        output      [31:0]  rd_data
    );

    wire                enable;
    assign  enable = wr_en ^ rd_en;

    iram iram_inst (
        .clka       (clk),
        .ena        (enable),
        .wea        (wr_en),  // ram 读写使能信号,高电平写入,低电平读出
        .addra      (addr),
        .dina       (wr_data),
        .douta      (rd_data)
    );


endmodule
