module prescaler #(parameter f = 28636360)(
	input logic clk_in,
	output logic clk_out
);

	logic [$clog2(f):0] cntr;

	always@(posedge clk_in) begin
		if(cntr < f)
			cntr <= cntr + 1;
		else begin
			cntr <= 0;
			clk_out <= ~clk_out;
		end
	end

endmodule
