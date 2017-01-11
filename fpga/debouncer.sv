module debouncer #(parameter TIME = 2863630)(
	input logic btn,
	input logic clk,
	output logic btn_act 		// button active
);

	logic [$clog2(TIME):0] counter;
	assign btn_act = (counter < TIME) ? 1'b0 : 1'b1;

	always@(posedge clk, negedge btn) begin
		counter <= ~btn ? 0 : (counter < TIME ? counter + 1 : counter);
	end

endmodule
