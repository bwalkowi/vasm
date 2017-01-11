module processor(
	input logic fast_clk,
	input logic clk,
	input logic clr,
	input logic exec,			// == 1 => start executing at START_ADDR
	output logic hlt,			// == 1 => stop execution

	input logic [4:0] addr,			// register address to read and display
	output logic [15:0] out,		// content of register at addr
	input logic [15:0] in,			// content to write to reg[0] at start

	input logic [15:0] START_ADDR,		// address of first instr to execute

   output logic [15:0] MEMORY_ADDR, 	// address for memory reads
	input logic [15:0] MEMORY_OUT,		// data read from local memory at MEMORY_ADDR

	output logic RUN,
	output logic proc_clk,

	output logic [15:0] MA_WHERE,		// tell dma where to dump memory
	output logic [15:0] MA_WHAT,		// tell dma what memory to dump or MA what memory free or process spawn
	output logic [15:0] MA_COUNT,		// tell dma how much memory to dump
	input logic [15:0] MA_ANSWER,		// MA answer
	output logic ma_request,
	input logic ma_answer
);

	always@(posedge exec, posedge hlt) begin
		if(exec == 1'b1) 
			RUN = 1;
		else 
			RUN = 0;
	end

	logic run_clk;
	assign proc_clk = RUN & clk & run_clk;


	logic [4:0] addr_0;
	logic [4:0] addr_1;
	logic [4:0] addr_2;
	logic [4:0] addr_3;
	logic [15:0] R0;
	logic [15:0] R1;
	logic [15:0] R2;
	logic [15:0] R3;
	logic reg_write;

	registers regs(
		.clk(proc_clk),
		.rw(reg_write),
		.addr_0(addr_0),
		.addr_1(addr_1),
		.addr_2(addr_2),
		.addr_3(addr_3),
		.R0(R0),
		.R1(R1),
		.R2(R2),
		.R3(R3),
		.addr(addr),
		.out(out),
		.start(exec),
		.in(in)
	);

	logic [15:0] PC1;
	logic [31:0] IR1;

	code_seg code(
		.clock(fast_clk),
		.address(PC1[7:0]),
		.q(IR1)
	);

	logic [15:0] PC2;
	logic [31:0] IR2;
	logic [15:0] Y3_MUX;

	logic nop_2;
	logic jmp_id, load_pc;

	IF stage_1(
		.clk(proc_clk),
		.clr(clr),
		.nop_2(nop_2),
		.PC1(PC1),
		.IR1(IR1),
		.IR2(IR2),
		.PC2(PC2),
		.start(exec),
		.START_ADDR(START_ADDR),
		.jmp(jmp_id),
		.Y3_MUX(Y3_MUX),
		.load_pc(load_pc),
		.Z5(R3)
	);

	logic C, Z, N, O;
	logic wb_x, wb_y, wb_md;

	logic [31:0] IR3;
	logic [31:0] INSTR3;
	logic [15:0] X3;
	logic [15:0] Y3;
	logic [15:0] MD3;

	ID stage_2(   
		.clk(proc_clk),
		.clr(clr),
		.IR2(IR2),
		.PC2(PC2),
		.Z5(R3),
		.C(C),
		.Z(Z),
		.N(N),
		.O(O),
		.IR3(IR3),
		.INSTR3(INSTR3),
		.X3(X3),
		.Y3_MUX(Y3_MUX),
		.Y3(Y3),
		.MD3(MD3),
		.jmp(jmp_id),
		.addr_0(addr_0),
		.RS0(R0),
		.addr_1(addr_1),
		.RS1(R1),
		.addr_2(addr_2),
		.RS2(R2),
		.wb_x(wb_x),
		.wb_y(wb_y),
		.wb_md(wb_md),
		.MA_WHERE(MA_WHERE),
		.MA_WHAT(MA_WHAT),
		.MA_COUNT(MA_COUNT),
		.MA_ANSWER(MA_ANSWER),
		.ma_request(ma_request)
	);

	logic [15:0] Z4;
	logic [15:0] data_in;
	logic [15:0] data_out;
   logic mem_write;

	data_seg data(
		.address_a(Z4[9:0]),
		.address_b(MEMORY_ADDR[9:0]),
		.clock(fast_clk),
		.data_a(data_in),
		.data_b(0),
		.wren_a(mem_write),
		.wren_b(0),
		.q_a(data_out),
		.q_b(MEMORY_OUT)
	);

	logic [31:0] IR4;
	logic x_z5_sel, y_z5_sel, md_z5_sel;

	EX stage_3(
		.clk(proc_clk),
		.clr(clr),
		.IR3(IR3),
		.INSTR3(INSTR3),
		.X3(X3),
		.Y3(Y3),
		.MD3(MD3),
		.C(C),
		.Z(Z),
		.N(N),
		.O(O),
		.IR4(IR4),
		.Z4(Z4),
		.data_in(data_in),
		.write(mem_write),
		.Z5(R3),
		.x_z5_sel(x_z5_sel),
		.y_z5_sel(y_z5_sel),
		.md_z5_sel(md_z5_sel)
	);

	// instantiate stage 4 of pipelining
	WB stage_4(
		.clk(proc_clk),
		.clr(clr),
		.IR4(IR4),
		.Z4(Z4),
		.data_out(data_out),
		.reg_write(reg_write),
		.addr(addr_3),
		.Z5(R3),
		.hlt(hlt),
		.load_pc(load_pc)
	);

	// instantiate hazard detection unit
	hdu hazard_detection(
		.IR2(IR2),
		.IR3(IR3),
		.IR4(IR4),
		.start(exec),
		.nop_2(nop_2),
		.x2_z5_sel(wb_x),
		.y2_z5_sel(wb_y),
		.md2_z5_sel(wb_md),
		.x3_z5_sel(x_z5_sel),
		.y3_z5_sel(y_z5_sel),
		.md3_z5_sel(md_z5_sel),
		.ma_request(ma_request),
		.ma_answer(ma_answer),
		.run_clk(run_clk)
	);

endmodule
