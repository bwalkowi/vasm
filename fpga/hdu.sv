`define NOP_2 		INSTR2[0]
`define JXX_2 		INSTR2[1]
`define ADD_2 		INSTR2[2]
`define SUB_2 		INSTR2[3]
`define CMP_2 		INSTR2[4]
`define AND_2 		INSTR2[5]
`define OR_2 		INSTR2[6]
`define XOR_2		INSTR2[7]
`define NOT_2 		INSTR2[8]
`define NEG_2		INSTR2[9]
`define SHL_2		INSTR2[10]
`define SHR_2		INSTR2[11]
`define ST_2		INSTR2[12]
`define LD_2		INSTR2[13]
`define MOV_2		INSTR2[14]
`define HLT_2 		INSTR2[15]


`define NOP_3 		INSTR3[0]
`define JXX_3 		INSTR3[1]
`define ADD_3 		INSTR3[2]
`define SUB_3 		INSTR3[3]
`define CMP_3 		INSTR3[4]
`define AND_3 		INSTR3[5]
`define OR_3  		INSTR3[6]
`define XOR_3		INSTR3[7]
`define NOT_3 		INSTR3[8]
`define NEG_3		INSTR3[9]
`define SHL_3		INSTR3[10]
`define SHR_3		INSTR3[11]
`define ST_3		INSTR3[12]
`define LD_3		INSTR3[13]
`define MOV_3		INSTR3[14]
`define HLT_3 		INSTR3[15]


`define NOP_4 		INSTR4[0]
`define JXX_4 		INSTR4[1]
`define ADD_4 		INSTR4[2]
`define SUB_4 		INSTR4[3]
`define CMP_4 		INSTR4[4]
`define AND_4 		INSTR4[5]
`define OR_4 		INSTR4[6]
`define XOR_4		INSTR4[7]
`define NOT_4 		INSTR4[8]
`define NEG_4		INSTR4[9]
`define SHL_4		INSTR4[10]
`define SHR_4		INSTR4[11]
`define ST_4		INSTR4[12]
`define LD_4		INSTR4[13]
`define MOV_4		INSTR4[14]
`define HLT_4 		INSTR4[15]


module hdu(
   input logic [31:0] IR2,        // The instruction register for pipeline ID stage
   input logic [31:0] IR3,        // The decoded instruction for pipeline EX stage
   input logic [31:0] IR4,        // The decoded instruction for pipeline MEM stage

	input logic start,				// == 1 => master unit started processor
	output logic nop_2,       // bubble ID stage with nop operation

   output logic x2_z5_sel,      // selector for X in ID stage
   output logic y2_z5_sel,      // selector for Y in ID stage
   output logic md2_z5_sel,     // selector for MD in ID stage       

   output logic x3_z5_sel,      // selector for ALU operand 1 mux in EX stage
   output logic y3_z5_sel,      // selector for ALU operand 2 mux in EX stage
   output logic md3_z5_sel,     // selector for data_out mux in EX stage

	input logic ma_request,
	input logic ma_answer,
	output logic run_clk
);

	assign run_clk = ~(ma_request ^ ma_answer);

	// decode instructions from pipeline stages
	logic [31:0] INSTR2;
	decoder IR2dec(
		.opcode(IR2[31:27]), 
		.instr(INSTR2)
	);

	logic [31:0] INSTR3;
	decoder IR3dec(
		.opcode(IR3[31:27]), 
		.instr(INSTR3)
	);

	logic [31:0] INSTR4;
	decoder IR4dec(
		.opcode(IR4[31:27]), 
		.instr(INSTR4)
	);

	// alu_x == 1 => at x stage is instr whose result will be written to register
	logic alu_2, alu_3, alu_4;
	assign alu_2 = `ADD_2 | `SUB_2 | `AND_2 | `OR_2 | `XOR_2 | `NOT_2 | `NEG_2 | `SHL_2 | `SHR_2 | `MOV_2;
	assign alu_3 = `ADD_3 | `SUB_3 | `AND_3 | `OR_3 | `XOR_3 | `NOT_3 | `NEG_3 | `SHL_3 | `SHR_3 | `MOV_3;
	assign alu_4 = `ADD_4 | `SUB_4 | `AND_4 | `OR_4 | `XOR_4 | `NOT_4 | `NEG_4 | `SHL_4 | `SHR_4 | `MOV_4;

	// check if instruction depends on result of previous instructions
	logic rdst4_rs12, rdst4_rs22;
	assign rdst4_rs12 = (IR4[26:22] == IR2[21:17]) & ~((`LD_2 | `ST_2 | `LD_4 | `ST_4) & ~|IR2[21:17]);
	assign rdst4_rs22 = (IR4[26:22] == IR2[15:11]) & ~IR2[16];

	logic rdst4_rs13, rdst4_rs23;
	assign rdst4_rs13 = IR4[26:22] == IR3[21:17] & ~((`LD_3 | `ST_3 | `LD_4 | `ST_4) & ~|IR3[21:17]);
	assign rdst4_rs23 = (IR4[26:22] == IR3[15:11]) & ~IR3[16];

	// in case of ST where source register is specified in IR[26:22]
	logic rdst4_rs2, rdst4_rs3;
	assign rdst4_rs2 = (IR4[26:22] == IR2[26:22]) & |IR2[26:22];
	assign rdst4_rs3 = (IR4[26:22] == IR3[26:22]) & |IR3[26:22];

	logic wb_val;
	assign wb_val = alu_4 | `LD_4;

	// logic for ID stage selectors
	assign x2_z5_sel = rdst4_rs12 & (alu_2 | `ST_2 | `LD_2 | `CMP_2) & wb_val;
	assign y2_z5_sel = rdst4_rs22 & (alu_2 | `ST_2 | `LD_2 | `CMP_2) & wb_val;
	assign md2_z5_sel = rdst4_rs2 & `ST_2 & wb_val;

	// logic for EX stage selectors
	assign x3_z5_sel = rdst4_rs13 & (alu_3 | `ST_3 | `LD_3 | `CMP_3) & wb_val;
	assign y3_z5_sel = rdst4_rs23 & (alu_3 | `LD_3 | `ST_3 | `CMP_3) & wb_val;
	assign md3_z5_sel = rdst4_rs3 & `ST_3 & wb_val;

	// logic for bubbling stages with nop operation
	logic load_pc, hlt;
	assign load_pc = (`LD_2 & ~|IR2[26:22]) | (`LD_3 & ~|IR3[26:22]) | (`LD_4 & ~|IR4[26:22]);
	assign hlt = `HLT_2 | `HLT_3 | `HLT_4;
	assign nop_2 = start | hlt | load_pc;

endmodule
