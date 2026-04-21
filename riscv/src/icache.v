`include "const.v"

`ifndef ICACHE_V
`define ICACHE_V

module ICache (
    input wire clk,
    input wire rst,
    input wire rdy,

    // IFetch
    input  wire [31:0] pc,
    output wire hit,
    output wire [31:0] inst_out,

    // Memctrl
    input  wire inst_rdy, 
    input  wire [31:0] inst_in, // from memctrl to icache
    output reg  inst_miss, // from icache to memctrl
    output reg  [31:0] pc_out
);

    reg                   statu;
    reg                   valid [`CACHE_SIZE - 1:0];
    reg [           31:0] data  [`CACHE_SIZE - 1:0];
    reg [`TAG_SIZE - 1:0] tag   [`CACHE_SIZE - 1:0];

    wire [`INDEX_SIZE - 1:0] index  = pc[`INDEX_SIZE + 1 : 2];
    wire [  `TAG_SIZE - 1:0] tag_in = pc[31 : `INDEX_SIZE + 2];

    assign hit = valid[index] && (tag[index] == tag_in);
    assign inst_out = hit ? data[index] : inst_in;
    integer i;

    always @(posedge clk) begin
        if (rst) begin
            statu <= `IDLE;
            for (i = 0; i < `CACHE_SIZE; i = i + 1) begin
                valid[i] <= 0;
                data[i]  <= 0;
                tag[i]   <= 0;
            end
        end else if (!rdy) begin
        end else begin
            case (statu) 
                `IDLE : begin
                    if (!hit) begin
                        statu <= `IMEM;
                        inst_miss <= 1;
                        pc_out <= pc;
                    end
                end
                `IMEM : begin
                    if (inst_rdy) begin
                        statu <= `IDLE;
                        inst_miss <= 0;
                        valid[index] <= 1;
                        tag[index] <= tag_in;
                        data[index] <= inst_in;
                    end 
                end
            endcase
        end 
    end
    
endmodule

`endif