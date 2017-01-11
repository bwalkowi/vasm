module set_flags(
   input logic[15:0] op1,     // instruction operand.
   input logic[15:0] op2,     // instruction operand.
   input logic[16:0] result,  // instruction result.

	input logic sub,				// == 1 => sub or cmp
	input logic add,				// == 1 => add

   output logic C,       		// carry condition bit.
   output logic Z,       		// zero condition bit.
   output logic N,       		// neagative condition bit.
   output logic O       		// overflow condition bit.
);

   assign C = result[16];
   assign Z = ~|result[15:0];
   assign N = result[15];

	logic tmp;
	assign tmp = (result[15] & ~op1[15] & ~(sub^op2[15])) | (~result[15] & op1[15] & (sub^op2[15]));
   assign O = (add | sub) ? tmp : 0;

endmodule
