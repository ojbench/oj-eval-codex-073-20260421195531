`include "./iqueue.v"
`include "./forward.v"
`include "./salu.v"
`include "./sregfile.v"
`include "./writeback.v"
`include "./memctrl.v"
`include "./icache.v"
`include "./ifetch.v"

// RISCV32I CPU top module
// port modification allowed for debugging purposes

module cpu(
  input  wire                 clk_in,			// system clock signal
  input  wire                 rst_in,			// reset signal
	input  wire					        rdy_in,			// ready signal, pause cpu when low

  input  wire [ 7:0]          mem_din,		// data input bus
  output wire [ 7:0]          mem_dout,		// data output bus
  output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
  output wire                 mem_wr,			// write/read signal (1 for write)
	
	input  wire                 io_buffer_full, // 1 if uart buffer is full
	
	output wire [31:0]			dbgreg_dout		// cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)

// Memctrl input
  wire ic_to_mem_inst_miss;
  wire [31:0] ic_to_mem_pc;
  wire [2:0] wb_to_mem_len;
  wire [1:0] wb_to_mem_wr;
  wire [31:0] wb_to_mem_addr;
  wire [31:0] wb_to_mem_data;

// ICache input
  wire [31:0] if_to_ic_pc;
  wire mem_to_ic_inst_rdy;
  wire [31:0] mem_to_ic_inst; 

// IFetch input
  wire ic_to_if_hit;
  wire [31:0] ic_to_if_inst; 
  wire iq_to_if_iq_full;
  wire wb_to_if_br_rdy;
  wire [31:0] wb_to_if_nex_pc;

// IQueue input
  wire if_to_iq_inst_rdy;
  wire [31:0] if_to_iq_inst;
  wire [31:0] if_to_iq_pc; 
  wire reg_to_iq_op1_rdy;
  wire reg_to_iq_op2_rdy;
  wire fw_to_iq_ins_rdy;
  
// Forward input  
  wire iq_issue_rdy; 
  wire iq_is_vec; 
  wire [1:0] iq_type; 
  wire [5:0] iq_name; 
  wire [4:0] iq_rd;
  wire [31:0] iq_pc;
  wire [31:0] iq_imm;
  wire mem_rdy;

// SALU input
  wire iq_is_imm;
  wire iq_is_pc;
  wire [31:0] reg_op1;
  wire [31:0] reg_op2;

// SReg input
  wire [4:0] iq_pre_rs1;
  wire [4:0] iq_pre_rs2; 
  wire [4:0] iq_rs1;
  wire [4:0] iq_rs2; 
  wire [4:0] wb_to_reg_commit_rd;
  wire [31:0] wb_to_reg_commit_data;

// Writeback input
  wire fw_to_wb_rd_rdy;
  wire fw_to_wb_is_vec;
  wire [1:0] fw_to_wb_type;
  wire [5:0] fw_to_wb_name;
  wire [4:0] fw_to_wb_rd;
  wire [31:0] fw_to_wb_pc;
  wire [31:0] fw_to_wb_imm; 
  wire [31:0] salu_to_wb_val;
  wire if_to_wb_pc_rdy;
  wire mem_to_wb_mem_st;
  wire [31:0] mem_to_wb_mem_out; 

  Memctrl memctrl(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    .data_in(mem_din),
    .io_buffer_full(io_buffer_full),
    .data_out(mem_dout),
    .data_addr(mem_a),
    .data_wr(mem_wr),
    .inst_miss(ic_to_mem_inst_miss),
    .pc(ic_to_mem_pc),
    .inst_rdy(mem_to_ic_inst_rdy),
    .inst_out(mem_to_ic_inst),
    .mem_len(wb_to_mem_len),
    .mem_wr(wb_to_mem_wr),
    .mem_addr(wb_to_mem_addr),
    .mem_data(wb_to_mem_data),
    .mem_rdy(mem_rdy),
    .mem_st(mem_to_wb_mem_st),
    .mem_out(mem_to_wb_mem_out)
  );

  ICache icache(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    .pc(if_to_ic_pc),
    .hit(ic_to_if_hit),
    .inst_out(ic_to_if_inst),
    .inst_rdy(mem_to_ic_inst_rdy),
    .inst_in(mem_to_ic_inst),
    .inst_miss(ic_to_mem_inst_miss),
    .pc_out(ic_to_mem_pc)
  );

  IFetch ifetch(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    .hit(ic_to_if_hit),
    .inst_in(ic_to_if_inst),
    .pc(if_to_ic_pc),
    .full(iq_to_if_iq_full),
    .inst_rdy(if_to_iq_inst_rdy),
    .inst_out(if_to_iq_inst),
    .pc_out(if_to_iq_pc),
    .br_rdy(wb_to_if_br_rdy),
    .nex_pc(wb_to_if_nex_pc),
    .pc_rdy(if_to_wb_pc_rdy)
  );
  
  IQueue iqueue(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    .inst_rdy(if_to_iq_inst_rdy),
    .inst(if_to_iq_inst),
    .pc_in(if_to_iq_pc),
    .full(iq_to_if_iq_full),
    .op1_rdy(reg_to_iq_op1_rdy),
    .op2_rdy(reg_to_iq_op2_rdy),
    .pre_rs1(iq_pre_rs1),
    .pre_rs2(iq_pre_rs2),
    .rs1(iq_rs1),
    .rs2(iq_rs2),
    .issue_rdy(iq_issue_rdy),
    .type(iq_type),
    .rd(iq_rd),
    .ins_rdy(fw_to_iq_ins_rdy),
    .is_vec(iq_is_vec),
    .name(iq_name),
    .pc_out(iq_pc),
    .imm(iq_imm),
    .is_imm(iq_is_imm),
    .is_pc(iq_is_pc)
  );

  Forward forward(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    .issue_rdy(iq_issue_rdy),
    .is_vec(iq_is_vec),
    .type(iq_type),
    .name(iq_name),
    .rd(iq_rd),
    .pc(iq_pc),
    .imm(iq_imm),
    .ins_rdy(fw_to_iq_ins_rdy),
    .mem_rdy(mem_rdy),
    .rd_rdy(fw_to_wb_rd_rdy),
    .is_vec_out(fw_to_wb_is_vec),
    .type_out(fw_to_wb_type),
    .name_out(fw_to_wb_name),
    .rd_out(fw_to_wb_rd),
    .pc_out(fw_to_wb_pc),
    .imm_out(fw_to_wb_imm)
  );

  SALU salu(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    .issue_rdy(iq_issue_rdy),
    .is_vec(iq_is_vec),
    .is_imm(iq_is_imm),
    .is_pc(iq_is_pc),
    .pc(iq_pc),
    .imm(iq_imm),
    .name(iq_name),
    .op1(reg_op1),
    .op2(reg_op2),
    .val(salu_to_wb_val)
  );

  SRegfile sregfile(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    .issue_rdy(iq_issue_rdy),
    .type(iq_type),
    .rd(iq_rd),
    .pre_rs1(iq_pre_rs1),
    .pre_rs2(iq_pre_rs2),
    .rs1(iq_rs1),
    .rs2(iq_rs2),
    .op1_rdy(reg_to_iq_op1_rdy),
    .op2_rdy(reg_to_iq_op2_rdy),
    .op1(reg_op1),
    .op2(reg_op2),
    .commit_rd(wb_to_reg_commit_rd),
    .commit_data(wb_to_reg_commit_data)
  );

  WriteBack writeback(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    .rd_rdy(fw_to_wb_rd_rdy),
    .is_vec(fw_to_wb_is_vec),
    .type(fw_to_wb_type),
    .name(fw_to_wb_name),
    .rd(fw_to_wb_rd),
    .pc(fw_to_wb_pc),
    .imm(fw_to_wb_imm),
    .val(salu_to_wb_val),
    .pc_rdy(if_to_wb_pc_rdy),
    .br_rdy(wb_to_if_br_rdy),
    .pc_out(wb_to_if_nex_pc),
    .st_data(reg_op2),
    .reg_rd(wb_to_reg_commit_rd),
    .reg_out(wb_to_reg_commit_data),
    .mem_rdy(mem_rdy),
    .mem_st(mem_to_wb_mem_st),
    .ld_data(mem_to_wb_mem_out),
    .mem_len(wb_to_mem_len),
    .mem_wr(wb_to_mem_wr),
    .mem_addr(wb_to_mem_addr),
    .mem_data(wb_to_mem_data)
  );

endmodule