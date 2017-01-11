`define ADD4 		INSTR4[2]
`define SUB4 		INSTR4[3]
`define AND4 		INSTR4[5]
`define OR4  		INSTR4[6]
`define XOR4		INSTR4[7]
`define NOT4 		INSTR4[8]
`define NEG4		INSTR4[9]
`define SHL4		INSTR4[10]
`define SHR4		INSTR4[11]
`define LD4			INSTR4[13]
`define MOV4		INSTR4[14]
`define HLT4		INSTR4[15]
`define LDUMP4		INSTR4[16]
`define SDUMP4		INSTR4[17]

module WB(
	input logic clk,				// clock 
	input logic clr, 				// clear

   input logic [31:0] IR4,      	// instruction register from pipeline EX stage
   input logic [15:0] Z4,       	// result from pipeline EX stage
	input logic [15:0] data_out,	// data read from memory if instr is LD

	output logic reg_write,			// == 1 => register write
	output logic [4:0] addr,		// address of register to write to
	output logic [15:0] Z5,			// content to wrtite to register pointed by addr

	output logic hlt,					// == 1 => stop executing instructions
	output logic load_pc				// == 1 => pc was loaded from memory
);

	logic [31:0] INSTR4;
   decoder op_decoder(
		.opcode(IR4[31:27]), 
		.instr(INSTR4)
	);

	logic load_reg;
	assign load_reg = `LD4 & |IR4[26:22];
	assign load_pc = `LD4 & ~|IR4[26:22];

	assign reg_write = `ADD4 | `SUB4 | `AND4 | `OR4 | `XOR4 |`NOT4 | `NEG4 | `SHL4 | `SHR4 | load_reg | `MOV4 |`LDUMP4 | `SDUMP4;
	assign addr = IR4[26:22];
	assign Z5 = `LD4 ? data_out : Z4;

	assign hlt = `HLT4;

endmodule
