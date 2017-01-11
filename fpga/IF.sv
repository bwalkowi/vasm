module IF(
	input logic clk,				// clock 
	input logic clr, 				// clear
	input logic nop_2,			// bubble ID stage with nop operation

	output logic [15:0] PC1,	// program counter; address pass to memory to fetch instruction to IR1
	input logic [31:0] IR1,		// instruction read from memory pointed to by address in PC1

	output logic [31:0] IR2,	// instruction pass to ID stage
	output logic [15:0] PC2,	// program counter pass to ID stage

	input logic start,					// == 1 => master unit started processor
	input logic [15:0] START_ADDR,	// address of first instruction to execute
	input logic jmp,						// == 1 => jump
	input logic [15:0] Y3_MUX,			// address pointing where to jump
	input logic load_pc,					// == 1 => pc was loaded from memory
	input logic [15:0] Z5				// address of loaded pc
);

	logic [31:0] NOP;
	assign NOP = 0;

	logic [15:0] PC1_INC;
	assign PC1_INC = PC1 + 1;

	logic [15:0] PC1_MUX;
	assign PC1_MUX = load_pc ? Z5 : (start ? START_ADDR : (jmp ? Y3_MUX : PC1_INC));
	clk_wire #(16) pc_if(clk, clr, PC1_MUX, PC1);

	logic [31:0] IR_MUX;
	assign IR_MUX = nop_2 ? NOP : IR1;
	clk_wire #(32) ir(clk, clr, IR_MUX, IR2);
	clk_wire #(16) pc_id(clk, clr, PC1_INC, PC2);

endmodule
