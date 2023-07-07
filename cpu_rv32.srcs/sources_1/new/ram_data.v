module ram_data (
        input               clk,
        output      [4:0]   ram_ctrl,
        input       [31:0]  addr,
        input       [31:0]  wr_data,
        output  reg [31:0]  rd_data
    );

    wire                enable;
    wire                wr_en;
    assign  enable = ram_ctrl[0];
    assign  wr_en = ram_ctrl[1];

    reg     [31:0]      din;
    wire    [31:0]      dout;
    always @(*) begin
        case (ram_ctrl[3:2])
            2'b00 : begin
                din = {24'b0, wr_data[7:0]};
                rd_data = {{24{~ram_ctrl[4]&dout[7]}}, dout[7:0]};
            end
            2'b01 : begin
                din = {16'b0, wr_data[15:0]};
                rd_data = {{16{~ram_ctrl[4]&dout[15]}}, dout[15:0]};
            end
            2'b10 : begin
                din = wr_data;
                rd_data = dout;
            end
            default: begin
                din = 32'd0;
                rd_data = 32'd0;
            end
        endcase
    end

    dram dram_inst (
        .clka       (clk),
        .ena        (enable),
        .wea        (wr_en),
        .addra      (addr[7:0]),
        .dina       (din),
        .douta      (dout)
    );


endmodule
