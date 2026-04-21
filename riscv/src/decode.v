`include "const.v"

`ifndef DECODE_V
`define DECODE_V

module Decode (
    input wire [31:0] inst,
    output reg is_vec,
    output reg is_imm,
    output reg is_pc,
    output reg [1:0]  type,
    output reg [5:0]  name,
    output reg [4:0]  rd,
    output reg [4:0]  rs1,
    output reg [4:0]  rs2,
    output reg [31:0] imm
);
    wire [6:0]   opcode = inst[6:0];
    wire [3:0]   funct3 = inst[14:12];
    wire [31:25] funct7 = inst[31:25];
    
    always @(*) begin
        is_imm = 0;
        is_pc = 0;
        is_vec = 0;
        rd  = inst[11:7];
        rs1 = inst[19:15];
        rs2 = inst[24:20];
        case (opcode)
            7'b0110011: begin
                case (funct3)
                    3'b000: name = funct7 == 0 ? `ADD : `SUB;
                    3'b001: name = `SLL;
                    3'b010: name = `SLT;
                    3'b011: name = `SLTU;
                    3'b100: name = `XOR;
                    3'b101: name = funct7 == 0 ? `SRL : `SRA;
                    3'b110: name = `OR;
                    3'b111: name = `AND;
                endcase    
                type = `REG;
            end
            7'b0010011: begin
                case (funct3)
                    3'b000: name = `ADDI;
                    3'b001: name = `SLLI;
                    3'b010: name = `SLTI;
                    3'b011: name = `SLTIU;
                    3'b100: name = `XORI;
                    3'b101: name = funct7 == 0 ? `SRLI : `SRAI;
                    3'b110: name = `ORI;
                    3'b111: name = `ANDI;
                endcase
                case (name)
                    `SLLI, `SRLI, `SRAI: imm = inst[24:20];
                    `SLTIU: imm = inst[31:20];
                    default: imm = {{21{inst[31]}}, inst[30:20]};
                endcase
                rs2 = 0;
                type = `REG;
                is_imm = 1;
            end
            7'b0000011: begin
                case (funct3)
                    3'b000: name = `LB;
                    3'b001: name = `LH;
                    3'b010: name = `LW;
                    3'b100: name = `LBU;
                    3'b101: name = `LHU;
                endcase
                type = `REG;
                imm  = {{21{inst[31]}}, inst[30:20]};
                is_imm = 1;
                rs2 = 0;
            end
            7'b0100011: begin
                case (funct3)
                    3'b000: name = `SB;
                    3'b001: name = `SH;
                    3'b010: name = `SW;
                endcase
                type = `MEM;
                imm  = {{21{inst[31]}}, inst[30:25], inst[11:7]};
                is_imm = 1;
            end
            7'b1100011: begin
                case (funct3)
                    3'b000: name = `BEQ;
                    3'b001: name = `BNE;
                    3'b100: name = `BLT;
                    3'b101: name = `BGE;
                    3'b110: name = `BLTU;
                    3'b111: name = `BGEU;
                endcase
                type = `BR;
                imm  = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0}; 
            end
            7'b0110111: begin
                name = `LUI;
                type = `REG;
                imm  = {inst[31:12], 12'b0};
                is_imm = 1;
                rs1 = 0;
                rs2 = 0;
            end
            7'b0010111: begin
                name = `AUIPC;
                type = `REG;
                imm  = {inst[31:12], 12'b0};
                is_imm = 1;
                is_pc = 1;
                rs1 = 0;
                rs2 = 0;
            end
            7'b1101111: begin
                name = `JAL;
                type = `REG;
                imm  = 4;
                is_imm = 1;
                is_pc = 1;
                rs1 = 0;
                rs2 = 0;
            end
            7'b1100111: begin
                name = `JALR;
                type = `REG;
                imm  = {{21{inst[31]}}, inst[30:20]};
                is_imm = 1;
                rs2 = 0;
            end

        endcase
    end

endmodule

`endif