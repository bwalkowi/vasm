module registers(
	input logic clk,					// clock
	input logic rw,					// == 1 => write content of R3 to register at address addr_3

	input logic [4:0] addr_0,		// register address for R0
	input logic [4:0] addr_1,		// register address for R1
	input logic [4:0] addr_2,		// register address for R2
	input logic [4:0] addr_3,		// register address for R3
	output logic [15:0] R0,			// content of register at addr_0
	output logic [15:0] R1,			// content of register at addr_1
	output logic [15:0] R2,			// content of register at addr_2
	input logic [15:0] R3,			// content to write to register at addr_3

	input logic [4:0] addr,			// register address to read and display
	output logic [15:0] out,		// content of register at addr

	input logic start,				// == 1 => write content of in to 0 register
	input logic [15:0] in
);

	logic [15:0] reg_mem [31:0];

   always @(addr_0 or addr_1 or addr_2 or addr) begin 
		R0 <= reg_mem[addr_0];
		R1 <= reg_mem[addr_1];
		R2 <= reg_mem[addr_2];
		out <= reg_mem[addr];
	end
 
   always @(posedge clk) begin
		if(rw)
			reg_mem[addr_3] <= R3;
		if(start)
			reg_mem[0] <= in;
	end

endmodule
