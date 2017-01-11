`define NOP 		5'b00000
`define JXX 		5'b00001
`define ADD 		5'b00010
`define SUB 		5'b00011
`define CMP 		5'b00100
`define AND 		5'b00101
`define OR  		5'b00110
`define XOR			5'b00111
`define NOT 		5'b01000
`define NEG			5'b01001
`define SHL			5'b01010
`define SHR			5'b01011
`define ST			5'b01100
`define LD			5'b01101
`define MOV			5'b01110
`define HLT 		5'b01111
`define LDUMP 		5'b10000
`define SDUMP 		5'b10001
`define FREE 		5'b10010
`define SPAWN 		5'b10011


module decoder(
	input logic [4:0] opcode,
	output logic [31:0] instr
);

	assign instr = 1 << opcode;

endmodule
