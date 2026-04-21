`include "const.v"

`ifndef REGFILE_V
`define REGFILE_V

module SRegfile (
    input wire clk,
    input wire rst,
    input wire rdy,

    // IQueue
    input wire issue_rdy,
    input wire [1:0] type,
    input wire [4:0] rd,
    input wire [4:0] pre_rs1,
    input wire [4:0] pre_rs2,
    input wire [4:0] rs1,
    input wire [4:0] rs2,
    output wire op1_rdy,
    output wire op2_rdy,
    output wire rd_rdy,

    // SALU
    output wire [31:0] op1,
    output wire [31:0] op2,

    // WB
    input wire [4:0]  commit_rd,
    input wire [31:0] commit_data
);

    reg        busy [31:0];
    reg [31:0] regs [31:0];

    assign now_set = issue_rdy && type == `REG;
    assign op1_busy = (busy[pre_rs1] && pre_rs1 != commit_rd) || (issue_rdy && pre_rs1 == rd);
    assign op2_busy = (busy[pre_rs2] && pre_rs2 != commit_rd) || (issue_rdy && pre_rs2 == rd);
    assign op1_rdy = !op1_busy;
    assign op2_rdy = !op2_busy;
    assign op1 = (commit_rd && rs1 == commit_rd) ? commit_data : regs[rs1];
    assign op2 = (commit_rd && rs2 == commit_rd) ? commit_data : regs[rs2];

    wire [31:0] reg5 = regs[5];
    wire [31:0] reg4 = regs[14];
    wire [31:0] reg2 = regs[12];
    wire [31:0] reg1 = regs[1];

    integer i;
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1) begin
                regs[i] <= 0;
                busy[i] <= 0;
            end
        end else if (!rdy) begin
        end else begin
            busy[0] <= 0;
            if (now_set) begin
                busy[rd] <= 1;
            end 
            if (commit_rd != 0) begin
                regs[commit_rd] <= commit_data;
                if (!(now_set && rd == commit_rd)) begin
                    busy[commit_rd] <= 0;
                end
            end
        end
    end
    
    always @(posedge clk) begin
    end

endmodule

`endif