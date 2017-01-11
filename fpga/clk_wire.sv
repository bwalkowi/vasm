module clk_wire #(parameter width = 1)(
	input logic clk, 
	input logic clr, 
	input logic [width-1:0] in, 
	output logic [width-1:0] out
);

	always @(negedge clr or posedge clk) begin
		out <= ~clr ? 0 : in;
	end

endmodule
