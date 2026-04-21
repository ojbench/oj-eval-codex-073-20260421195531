`include "const.v"

`ifndef FORWARD_V
`define FORWARD_V

module Forward (
    input wire clk,
    input wire rst,
    input wire rdy,

    // IQueue
    input wire issue_rdy,
    input wire is_vec,
    input wire [1:0]  type,
    input wire [5:0]  name,
    input wire [4:0]  rd,
    input wire [31:0] pc,
    input wire [31:0] imm,
    output wire ins_rdy,

    // Memctrl
    input wire mem_rdy,

    // WB
    output reg rd_rdy,
    output reg is_vec_out,
    output reg [1:0]  type_out,
    output reg [5:0]  name_out,
    output reg [4:0]  rd_out,
    output reg [31:0] pc_out,
    output reg [31:0] imm_out
);

    wire bubble = issue_rdy && (name >= `LB && name <= `SW);
    reg bubbling;
    assign ins_rdy = !bubble && !bubbling;

    always @(posedge clk) begin
        if (rst) begin
            bubbling = 0;
        end else if (!rdy) begin
        end else begin
            rd_rdy <= issue_rdy;
            is_vec_out <= is_vec; 
            type_out <= type;
            name_out <= name;
            rd_out <= rd;
            pc_out <= pc;
            imm_out <= imm;
            if (bubbling) bubbling <= (!mem_rdy);
            else if (bubble) bubbling <= 1;
        end
    end

endmodule

`endif 