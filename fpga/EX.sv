`define NOP3 		INSTR3[0]
`define JXX3 		INSTR3[1]
`define ADD3 		INSTR3[2]
`define SUB3 		INSTR3[3]
`define CMP3 		INSTR3[4]
`define AND3 		INSTR3[5]
`define OR3 		INSTR3[6]
`define XOR3		INSTR3[7]
`define NOT3		INSTR3[8]
`define NEG3		INSTR3[9]
`define SHL3		INSTR3[10]
`define SHR3		INSTR3[11]
`define ST3 		INSTR3[12]
`define LD3			INSTR3[13]
`define MOV3		INSTR3[14]
`define LDUMP3		INSTR3[16]
`define SDUMP3		INSTR3[17]

module EX(
	input logic clk,				// clock 
	input logic clr, 				// clear

   input logic [31:0] IR3,        // instruction register from pipeline ID stage
	input logic [31:0] INSTR3,		 // decoded instruction from pipeline ID stage
   input logic [15:0] X3,         // first operand for the ALU.
   input logic [15:0] Y3,         // second operand for the ALU
   input logic [15:0] MD3,        // data to be stored from pipeline ID stage

   output logic C,		         // status bit - Carry - for pipeline ID stage
   output logic Z,		         // status bit - Zero - for pipeline ID stage
   output logic N,		         // status bit - Negative - for pipeline ID stage
   output logic O,		         // status bit - Overflow - for pipeline ID stage

   output logic [31:0] IR4,        // instruction register for pipeline MEM stage
   output logic [15:0] Z4,         // alu output for pipeline MEM stage

   output logic [15:0] data_in,    // data to be stored to pipeline MEM stage
	output logic write,				  // == 1 => write to local memory ; == 0 => read from memory

   input logic [15:0] Z5,  // result from pipeline WB stage

   input logic x_z5_sel,      // selector for ALU operand 1 mux
   input logic y_z5_sel,      // selector for ALU operand 2 mux
   input logic md_z5_sel      // selector for MD4 mux
);

	// logic for IR4 and INSTR4
	clk_wire #(32) ir(clk, clr, IR3, IR4);

	// logic for X, Y and ALU -> Z4
	logic [15:0] X_MUX;
	assign X_MUX = x_z5_sel ? Z5 : X3;
	logic [15:0] Y_MUX;
	assign Y_MUX = y_z5_sel ? Z5 : Y3;
   logic [16:0] ALU_OUT;

	alu ALU(X_MUX, Y_MUX, `ADD3, `SUB3, `CMP3, `AND3, `OR3, `XOR3, `NOT3, `NEG3, `SHL3, `SHR3, `LD3, `ST3, `MOV3, `LDUMP3, `SDUMP3, ALU_OUT);
	clk_wire #(16) alu_result(clk, clr, ALU_OUT[15:0], Z4);
	clk_wire #(16) memory_write(clk, clr, `ST3, write);

	// logic for data_in
	logic [15:0] data_in_mux;
	assign data_in_mux = md_z5_sel ? Z5 : MD3;
	clk_wire #(16) memory_data(clk, clr, data_in_mux, data_in);

   // logic for flags C, Z, N, O
   logic _c, _z, _n, _o;

	set_flags setf(
		.op1(X_MUX),
		.op2(Y_MUX),
		.result(ALU_OUT),
		.sub(`SUB3 | `CMP3),
		.add(`ADD3),
		.C(_c),
		.Z(_z),
		.N(_n),
		.O(_o)
	);

	logic fclk;
	assign fclk = clk & (`ADD3 | `SUB3 | `AND3 | `OR3 | `XOR3| `NOT3 | `NEG3 | `CMP3 | `SHL3 | `SHR3);
   clk_wire #(1) c_wire(fclk, clr, _c, C);
   clk_wire #(1) z_wire(fclk, clr, _z, Z);
   clk_wire #(1) n_wire(fclk, clr, _n, N);
   clk_wire #(1) o_wire(fclk, clr, _o, O);

endmodule
