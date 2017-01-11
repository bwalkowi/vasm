`define JXX2		INSTR2[1]
`define ST2			INSTR2[12]
`define LD2			INSTR2[13]
`define LDUMP2		INSTR2[16]
`define SDUMP2		INSTR2[17]
`define FREE2		INSTR2[18]
`define SPAWN2		INSTR2[19]


module ID(   
	input logic clk,				// clock 
	input logic clr, 				// clear

	input logic [31:0] IR2,		// instruction register from pipeline IF stage
	input logic [15:0] PC2,		// program counter from pipeline IF stage
	input logic [15:0] Z5,		// the result from pipeline WB stage

   input logic C,		         // status bit - Carry - from pipeline EX stage
   input logic Z,		         // status bit - Zero - from pipeline EX stage
   input logic N,		         // status bit - Negative - from pipeline EX stage
   input logic O,		         // status bit - Overflow - from pipeline EX stage

	output logic [31:0] IR3,   	// instruction register for pipeline EX stage
	output logic [31:0] INSTR3,	// decoded instruction for pipline EX stage
	output logic [15:0] X3,			// a source operand for pipeline EX stage
	output logic [15:0] Y3_MUX,
	output logic [15:0] Y3,			// a source operand for pipeline EX stage
	output logic [15:0] MD3,		// the operand to store in memory for pipeline EX stage
	output logic jmp,					// == 1 => positive evaluation condition for jump

	output logic [4:0] addr_0,	// address of source operand RS0
	input logic [15:0] RS0,		// a source operand from register file
	output logic [4:0] addr_1,	// address of source operand RS1
	input logic [15:0] RS1,		// a source operand from register file
	output logic [4:0] addr_2,	// address of source operand RS2
	input logic [15:0] RS2,		// a source operand from register file

   input logic wb_x,      // == 1 => rs1 forwarded from WB stage
   input logic wb_y,      // == 1 => rs2 forwarded from WB stage
   input logic wb_md,     // == 1 => md forwarded from WB stage

	output logic [15:0] MA_WHERE,		// tell dma where to dump memory
	output logic [15:0] MA_WHAT,		// tell dma what memory to dump or MA what memory free or process spawn
	output logic [15:0] MA_COUNT,		// tell dma how much memory to dump
	input logic [15:0] MA_ANSWER,		// MA answer
	output logic ma_request
);

	clk_wire #(32) ir(clk, clr, IR2, IR3);

	// logic for instruction decode and forwarding decoded form
	logic [31:0] INSTR2;
   decoder op_decoder(
		.opcode(IR2[31:27]), 
		.instr(INSTR2)
	);
	clk_wire #(32) instr(clk, clr, INSTR2, INSTR3);

	// logic for register data fetch
	assign addr_0 = (`LDUMP2 | `SDUMP2) ? IR2[10:6] : IR2[26:22];
	assign addr_1 = IR2[21:17];
   assign addr_2 = IR2[15:11];

	assign MA_WHERE = RS1;
	assign MA_WHAT = RS2;
	assign MA_COUNT = RS0;

	logic st_pc, st_or_ld_direct;
	assign st_pc = `ST2 & ~|IR2[26:22];
	assign st_or_ld_direct = (`ST2 | `LD2) & ~|IR2[21:17];

	// logic for X3
	logic [15:0] X_MUX;
	assign X_MUX = wb_x ? Z5 : (st_or_ld_direct ? 16'b0 : RS1);
	clk_wire #(16) x(clk, clr, X_MUX, X3);

	// logic for Y3
	assign Y3_MUX = wb_y ? Z5 : ((`LDUMP2 | `SDUMP2) ? MA_ANSWER : (IR2[16] ? IR2[15:0] : RS2));
	clk_wire #(16) y(clk, clr, Y3_MUX, Y3);

	// logic for MD3
	logic [15:0] MD_MUX;
	assign MD_MUX = wb_md ? Z5 : (st_pc ? PC2 + 1 : RS0);
	clk_wire #(16) md(clk, clr, MD_MUX, MD3);

	// logic for jmp
	logic cond;
	test_flags fcheck(
		.cond(IR2[26:23]),
		.C(C),
		.Z(Z),
		.N(N),
		.O(O),
		.result(cond)
	);
	assign jmp = cond & `JXX2;
	assign ma_request = `LDUMP2 | `SDUMP2 | `FREE2 | `SPAWN2;

endmodule
