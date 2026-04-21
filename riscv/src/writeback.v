`include "const.v"

`ifndef WRITEBACK_V
`define WRITEBACK_V

module WriteBack (
    input wire clk,
    input wire rst,
    input wire rdy,

    // Forward
    input wire rd_rdy,
    input wire is_vec,
    input wire [1:0]  type,
    input wire [5:0]  name,
    input wire [4:0]  rd,
    input wire [31:0] pc,
    input wire [31:0] imm,

    // SALU
    input wire [31:0] val,

    // IFetch
    input wire pc_rdy,
    output reg br_rdy,
    output reg [31:0] pc_out,

    // SReg
    input wire [31:0] st_data,
    output reg [4:0]  reg_rd,
    output reg [31:0] reg_out,

    // Memctrl
    input wire mem_rdy,
    input wire mem_st,
    input wire [31:0] ld_data,
    output reg [2:0]  mem_len,
    output reg [1:0]  mem_wr,
    output reg [31:0] mem_addr,
    output reg [31:0] mem_data
);

    reg [1:0] statu;
    reg [5:0] now_name;
    reg [4:0] now_rd;

    always @(posedge clk) begin
        if (rst) begin
            br_rdy <= 0;
            reg_rd <= 0;
            statu <= `IDLE;
        end else if (!rdy) begin

        end else begin
            case (statu)
                `IDLE: begin
                    if (rd_rdy) begin
                        case (type)
                            `REG: begin
                                if (name >= `LB && name <= `LHU) begin
                                    br_rdy <= 0;
                                    reg_rd <= 0;
                                    statu <= `LD;
                                    mem_wr <= `LD;
                                    now_name <= name;
                                    now_rd <= rd;
                                    mem_addr <= val;
                                    if (name == `LB || name == `LBU) mem_len <= 1;
                                    else if (name == `LH || name == `LHU) mem_len <= 2;
                                    else mem_len <= 4;
                                end else begin
                                    reg_rd <= rd;
                                    if (name == `JALR) begin
                                        br_rdy <= 1;
                                        pc_out <= val;
                                        reg_out <= pc + 4;
                                    end else begin
                                        br_rdy <= 0;
                                        reg_out <= val;
                                    end
                                end                                
                            end
                            `MEM: begin
                                br_rdy <= 0;
                                reg_rd <= 0;
                                if (name <= `SW && name >= `SB) begin
                                    statu <= `ST;
                                    mem_wr <= `ST;
                                    mem_addr <= val;
                                    now_name <= name;
                                    mem_data <= st_data;
                                    if (name == `SB) mem_len <= 1;
                                    else if (name == `SH) mem_len <= 2;
                                    else mem_len <= 4;
                                end
                            end
                            `BR: begin
                                br_rdy <= 1;
                                pc_out <= (val ? pc + imm : pc + 4);
                                reg_rd <= 0;
                                //statu <= `WBR;
                            end
                        endcase
                    end else begin
                        br_rdy <= 0;
                        reg_rd <= 0;
                    end
                end
                // `WBR: begin
                //     if (pc_rdy) begin
                //         br_rdy <= 0;
                //         wb_rdy <= 1;
                //         statu <= `IDLE;
                //     end
                // end
                `LD: begin
                    if (mem_st) begin
                        mem_wr <= 0;
                    end
                    if (mem_rdy) begin
                        reg_rd <= now_rd;
                        case (now_name)
                            `LW : reg_out <= ld_data;
                            `LH : reg_out <= {{17{ld_data[15]}}, ld_data[14:0]};
                            `LB : reg_out <= {{25{ld_data[7]}}, ld_data[6:0]};
                            `LHU: reg_out <= {16'b0, ld_data[15:0]};
                            `LBU: reg_out <= {24'b0, ld_data[7:0]};
                        endcase
                        statu <= `IDLE;
                    end
                end
                `ST: begin
                    if (mem_st) begin
                        mem_wr <= 0;
                    end
                    if (mem_rdy) begin
                        statu <= `IDLE;
                    end
                end
            endcase
        end
    end

endmodule

`endif