`ifndef SALU_V
`define SALU_V   

module SALU (
    input wire clk,
    input wire rst,
    input wire rdy,

    // IQueue
    input wire issue_rdy,
    input wire is_vec,
    input wire is_imm, // use imm as operand (not rs2)
    input wire is_pc, // use pc as operand (not rs1)
    input wire [31:0] pc,
    input wire [31:0] imm,
    input wire [5:0]  name,

    // Reg
    input wire [31:0] op1, 

    // Reg and WB
    input wire [31:0] op2, // WB need op2 when sw

    // WB
    output reg [31:0] val
);

    wire [31:0] a = is_pc ? pc : op1;
    wire [31:0] b = is_imm ? imm : op2;

    always @(posedge clk) begin
        if (rst) begin
            val <= 0;
        end else if (!rdy) begin
        end else if (issue_rdy && !is_vec) begin
            case (name) 
                `SUB: val <= a - b;
                `SLL, `SLLI: val <= a << b[4:0];
                `SRL, `SRLI: val <= a >> b[4:0];
                `SRA, `SRAI: val <= $signed(a) >> b[4:0];
                `OR, `ORI: val <= a | b;
                `AND, `ANDI: val <= a & b;
                `XOR, `XORI: val <= a ^ b;
                `SLT, `SLTI, `BLT: val <= $signed(a) < $signed(b);
                `SLTU, `SLTIU, `BLTU: val <= a < b;
                `BEQ: val <= a == b;
                `BNE: val <= a != b;
                `BGE: val <= $signed(a) >= $signed(b);
                `BGEU: val <= a >= b;
                `LUI: val <= b;
                default: val <= a + b;
            endcase
        end
    end

endmodule

`endif