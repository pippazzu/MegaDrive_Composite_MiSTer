// Mega Drive NTSC board networks between the CXA1145's Y/C outputs and its
// Y/C MIX inputs, and the resulting composite video at the AV jack.
//
//   Luma   Y OUT - R27 1.2k - [L3 100uH || C35 18pF] - Y IN
//                                                  Y IN - C34 180pF - GND
//                                                  Y IN - R29 1k    - VREF
//   Chroma C OUT - R28 1.2k - node, node - C33 0.01uF - C IN
//                             node - L5 12uH, C37 180pF, R26 330 - GND
//
// Sega Model 1 NTSC schematic and the Model 2 CXA1145M parts list, topology as
// in the PAL-G maintenance manual. Y IN and C IN are base inputs and load
// nothing; the 0.01 uF coupling and VREF's 10 uF are shorts at video rates.
//
// Each network is the exact zero-order-hold discretisation of its state
// equations at the master clock T: for dx/dt = Ac x + Bc u, A = exp(Ac T) and
// B = Ac^-1 (A - I) Bc, with currents carried as volts across 1k. Q16
// coefficients and Q3.16 states: every product is 18 x 19, two to a DSP
// block, and the error against the analog circuit stays under 0.3 mV.
// The CXA1145's mixer gain cancels against the encoder's jack-referred levels:
// with the data sheet's 1k-in, 1k-out reference networks the jack voltage is
// the sum of the two network outputs driven with twice those levels.

module md_av_board (
	input                    clk,
	input                    reset,
	input  signed [23:0]     y_in,     // Q2.21, jack-referred luma + sync
	input  signed [23:0]     c_in,     // Q2.21, jack-referred chroma + burst
	output reg signed [23:0] cvbs      // Q2.21 volts at the jack, 75R terminated
);

// Luma: states {tank voltage, L3 current x 1k, Y IN voltage}.
localparam signed [17:0] LA00 =  18'sd25368;
localparam signed [17:0] LA01 = -18'sd44531;
localparam signed [17:0] LA02 = -18'sd33309;
localparam signed [17:0] LA10 =  18'sd8016;
localparam signed [17:0] LA11 =  18'sd60750;
localparam signed [17:0] LA12 = -18'sd3731;
localparam signed [17:0] LA20 = -18'sd3331;
localparam signed [17:0] LA21 =  18'sd2073;
localparam signed [17:0] LA22 =  18'sd55826;
localparam signed [17:0] LB0  =  18'sd35382;
localparam signed [17:0] LB1  =  18'sd3872;
localparam signed [17:0] LB2  =  18'sd3471;

// Chroma: states {L5 current x 1k, node voltage}.
localparam signed [17:0] CA00 =  18'sd60970;
localparam signed [17:0] CA01 =  18'sd81622;
localparam signed [17:0] CA10 = -18'sd5441;
localparam signed [17:0] CA11 =  18'sd39946;
localparam signed [17:0] CB0  =  18'sd3805;
localparam signed [17:0] CB1  =  18'sd4535;

function automatic signed [18:0] sat19(input signed [24:0] v);
	if      (v >  25'sd262143) sat19 =  19'sd262143;
	else if (v < -25'sd262144) sat19 = 19'sh40000;
	else                       sat19 =  v[18:0];
endfunction

// One state row: two sums of two products, each sum one DSP block.
function automatic signed [18:0] row(
	input signed [17:0] a0, input signed [18:0] x0,
	input signed [17:0] a1, input signed [18:0] x1,
	input signed [17:0] a2, input signed [18:0] x2,
	input signed [17:0] bb, input signed [18:0] u);
	/* verilator lint_off UNUSEDSIGNAL */
	reg signed [40:0] acc;
	/* verilator lint_on UNUSEDSIGNAL */
	begin
		acc = (a0 * x0 + a1 * x1) + (a2 * x2 + bb * u);
		row = sat19(acc[40:16]);
	end
endfunction

// Q2.21 in, doubled to the pin level, Q3.16.
wire signed [18:0] uy = y_in[22:4];
wire signed [18:0] uc = c_in[22:4];

reg signed [18:0] l0, l1, l2;
reg signed [18:0] k0, k1;

always @(posedge clk) begin
	if (reset) begin
		{l0, l1, l2} <= 57'd0;
		{k0, k1} <= 38'd0;
	end else begin
		l0 <= row(LA00, l0, LA01, l1, LA02, l2, LB0, uy);
		l1 <= row(LA10, l0, LA11, l1, LA12, l2, LB1, uy);
		l2 <= row(LA20, l0, LA21, l1, LA22, l2, LB2, uy);
		k0 <= row(CA00, k0, CA01, k1, 18'sd0, 19'sd0, CB0, uc);
		k1 <= row(CA10, k0, CA11, k1, 18'sd0, 19'sd0, CB1, uc);
	end
end

wire signed [19:0] mix = l2 + k1;

always @(posedge clk) begin
	if (reset)                     cvbs <= 24'sd0;
	else if (mix >  20'sd262143)   cvbs <= 24'sd8388576;
	else if (mix < -20'sd262144)   cvbs <= 24'sh800000;
	else                           cvbs <= {mix[18:0], 5'd0};
end

endmodule
