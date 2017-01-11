module DE2_70_TOP(
	input logic iCLK_28,						//  28.63636 MHz

	input logic [3:0] iKEY,							//	Pushbutton[3:0]
	input logic [17:0] iSW,							//	Toggle Switch[17:0]

	output logic [6:0] oHEX0_D,						//	Seven Segment Digit 0
	output logic [6:0] oHEX1_D,						//	Seven Segment Digit 1
	output logic [6:0] oHEX2_D,						//	Seven Segment Digit 2
	output logic [6:0] oHEX3_D,						//	Seven Segment Digit 3
	output logic [6:0] oHEX4_D,						//	Seven Segment Digit 4
	output logic [6:0] oHEX5_D,						//	Seven Segment Digit 5
	output logic [6:0] oHEX6_D,						//	Seven Segment Digit 6
	output logic [6:0] oHEX7_D,						//	Seven Segment Digit 7

	output logic [8:0] oLEDG,							//	LED Green[8:0]
	output logic [17:0] oLEDR							//	LED Red[17:0]
);

	// clear
	logic clr;
	debouncer reset(
		.btn(iKEY[1]),
		.clk(iCLK_28),
		.btn_act(clr)
	);
	assign oLEDG[1] = clr;


	// clock
	logic manual_clk;
	debouncer btn_clk(
		.btn(iKEY[3]),
		.clk(iCLK_28),
		.btn_act(manual_clk)
	);

	logic auto_clk;
	prescaler pres(
		.clk_in(iCLK_28),
		.clk_out(auto_clk)
	);

	logic clk;
	assign clk = iSW[17] ? manual_clk & RUN : auto_clk & RUN;
	assign oLEDG[0] = clk;


	// exec, hlt, RUN
	logic exec, hlt, RUN;
	assign oLEDG[2] = exec;
	assign oLEDG[3] = hlt;
	assign oLEDG[4] = RUN;

	always@(posedge clk or negedge clr or posedge hlt) begin
		if(~clr) begin
			RUN <= 1;
			exec <= 1;
		end
		else if(hlt)
			RUN <= 0;
		else 
			exec <= 0;
	end


//	// hdu debug
//	logic [31:0] IR2;
//	logic [31:0] IR3;
//	logic [31:0] IR4;
//	
//	assign IR2 = 5;
//	assign IR3 = 4;
//	assign IR4 = 3;
//	
//	logic start, jmp_id, pc, ma_request, ma_answer;
//	assign {start, jmp_id, pc, ma_request, ma_answer} = iSW[4:0];
//
//	logic jmp_if, pause_1, pause_2, nop_2, nop_3, x2_z5_sel, y2_z5_sel, md2_z5_sel, x3_z5_sel, y3_z5_sel, md3_z5_sel, run_clk;
//	assign oLEDR[11:0] = {jmp_if, pause_1, pause_2, nop_2, nop_3, x2_z5_sel, y2_z5_sel, md2_z5_sel, x3_z5_sel, y3_z5_sel, md3_z5_sel, run_clk};
//
//	hdu my_hdu(IR2, IR3, IR4, start, jmp_id, jmp_if, pc, pause_1, pause_2, nop_2, nop_3, x2_z5_sel, y2_z5_sel, md2_z5_sel, x3_z5_sel, y3_z5_sel, md3_z5_sel, ma_request, ma_answer, run_clk);




	logic [15:0] MEMORY_ADDR;
	logic [15:0] MEMORY_OUT;

	logic proc_run, proc_clk;
	//assign oLEDG[8:6] = {hlt, proc_run, proc_clk};

	logic [15:0] START_ADDR;
	assign START_ADDR = 0;
	logic [15:0] in;
	assign in = 0;

	logic [4:0] addr;
	logic [15:0] out;
	
	assign {MEMORY_ADDR[9:0], addr} = iSW[14:0];

	logic [15:0] MA_WHERE;
	logic [15:0] MA_WHAT;
	logic [15:0] MA_COUNT;
	logic [15:0] MA_ANSWER;
	logic ma_request;
	logic ma_answer;

	processor proc(
		.fast_clk(iCLK_28),
		.clk(clk),
		.clr(clr),
		.exec(exec),
		.hlt(hlt),
		.addr(addr),
		.out(out),
		.in(in),
		.START_ADDR(START_ADDR),
		.MEMORY_ADDR(MEMORY_ADDR),
		.MEMORY_OUT(MEMORY_OUT),
		.RUN(proc_run),
		.proc_clk(proc_clk),
		.MA_WHERE(MA_WHERE),
		.MA_WHAT(MA_WHAT),
		.MA_COUNT(MA_COUNT),
		.MA_ANSWER(MA_ANSWER),
		.ma_request(ma_request),
		.ma_answer(ma_answer)
	);

	dek7seg decMEM_0(
		.data_in(MEMORY_OUT[3:0]),
		.data_out(oHEX0_D)
	);

	dek7seg decMEM_1(
		.data_in(MEMORY_OUT[7:4]),
		.data_out(oHEX1_D)
	);

	dek7seg decMEM_2(
		.data_in(MEMORY_OUT[11:8]),
		.data_out(oHEX2_D)
	);

	dek7seg decMEM_3(
		.data_in(MEMORY_OUT[15:12]),
		.data_out(oHEX3_D)
	);
	dek7seg decREG_1(
		.data_in(out[3:0]),
		.data_out(oHEX4_D)
	);

	dek7seg decREG_2(
		.data_in(out[7:4]),
		.data_out(oHEX5_D)
	);

	dek7seg decREG_3(
		.data_in(out[11:8]),
		.data_out(oHEX6_D)
	);

	dek7seg decREG_4(
		.data_in(out[15:12]),
		.data_out(oHEX7_D)
	);


endmodule
