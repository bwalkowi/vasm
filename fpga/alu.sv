module alu(	
   input logic[15:0] R1,   //alu input for operand 1
   input logic[15:0] R2,   //alu input for operand 2

	input logic ADD,  		//    -||-          -||-      -||-
   input logic SUB,  		//    -||-          -||-      -||-
   input logic CMP,  		//    -||-          -||-      -||-
	input logic AND,  		//    -||-          -||-      -||-
   input logic OR,   		//    -||-          -||-      -||-
   input logic XOR,  		//    -||-          -||-      -||-
   input logic NOT,  		//    -||-          -||-      -||-
	input logic NEG,  		//    -||-          -||-      -||-
	input logic SHL,  		//    -||-          -||-      -||-
	input logic SHR,  		//    -||-          -||-      -||-
	input logic ST,    		//    -||-          -||-      -||-
	input logic LD,   		//    -||-          -||-      -||-
	input logic MOV,			//    -||-          -||-      -||-
	input logic LDUMP,		//    -||-          -||-      -||-
	input logic SDUMP,		//    -||-          -||-      -||-

	output logic[16:0] result
);

	always @(*) begin
		case(1)
			(ADD | ST | LD): result <= R1 + R2;
			(SUB | CMP): result <= R1 - R2;
			AND: result <= {1'b0, R1 & R2};
			OR:  result <= {1'b0, R1 | R2};
			XOR: result <= {1'b0, R1 ^ R2};
			NOT: result[15:0] <= {1'b0, ~R2};
			NEG: result <= 0 - R2;
			SHL: result <= R1 << R2;
			SHR: {result[15:0], result[16]} <= R1 >> R2;
			(MOV | LDUMP | SDUMP): result <= R2;
			default: result <= 0;
		endcase
	end

endmodule
