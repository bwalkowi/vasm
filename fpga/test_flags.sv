`define JZ  	4'b0000		// jump if zero
`define JNZ 	4'b0001		// jump if not zero
`define JG  	4'b0010		// jump if greater than
`define JGE 	4'b0011		// jump if greater than or equal
`define JL  	4'b0100		// jump if less than
`define JLE 	4'b0101		// jump if less than or equal
`define JC  	4'b0110		// jump if carry
`define JNC 	4'b0111		// jump if not carry
`define JO  	4'b1000		// jump if overflow
`define JNO 	4'b1001		// jump if not overflow
`define JN  	4'b1010		// jump if negative
`define JNN 	4'b1011		// jump if not negative
`define JMP 	4'b1100		// always jump

module test_flags(
	input logic [3:0] cond,
	input logic C,
	input logic Z,
	input logic N,
	input logic O,
	output logic result
);

	always @(cond) begin
		case(cond)
			`JMP: result <= 1'b1;
			`JZ: result <= Z;
			`JNZ: result <= ~Z;
			`JG: result <= ~Z & ((~N & ~O) | (N & O));
			`JGE: result <= (~N & ~O) | (N & O);
			`JL: result <= (N & ~O) | (~N & O);
			`JLE: result <= Z | ((N & ~O) | (~N & O));
			`JC: result <= C;
			`JNC: result <= ~C;
			`JO: result <= O;
			`JNO: result <= ~O;
			`JN: result <= N;
			`JNN: result <= ~N;
		endcase
	end

endmodule
