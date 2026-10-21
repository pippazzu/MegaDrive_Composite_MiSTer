// Composite video front end: the VDP pins the CXA1145 encoder sees.
//
// The Nuked VDP runs on clk_md, two ticks per master clock, and its DAC,
// C-SYNC and SBCR pins can change on either tick. Each master clock is
// integrated here as the sum of its two ticks, so an edge on the second tick
// arrives as a half step instead of being lost, and handed to CLK_VIDEO, which
// runs at the master clock from the same PLL.
//
// Every sample also carries the subcarrier angle at its centre, counted from
// the peak of the SBCR fundamental: SBCR is MCLK/15, so a subcarrier cycle is
// exactly 30 ticks and 15 samples, and the angle is exact.

module md_cvbs_front (
	input            clk_md,
	input            clk_vid,

	input      [7:0] r,
	input      [7:0] g,
	input      [7:0] b,
	input            csync_n,     // C-SYNC pin, low in sync
	input            sbcr,        // SBCR pin, MCLK/15 in NTSC

	output reg [8:0] r2 = 9'd0,   // two-tick sums, CLK_VIDEO domain
	output reg [8:0] g2 = 9'd0,
	output reg [8:0] b2 = 9'd0,
	output reg [1:0] s2 = 2'd0,   // ticks C-SYNC was low
	output reg [5:0] ang = 6'd0   // carrier angle, 6 degree steps
);

// ------------------------------------------------------------ subcarrier lock

reg       sbcr_d = 1'b0;
reg [4:0] tick = 5'd0;            // tick within the subcarrier cycle
reg [4:0] hcnt = 5'd0, hlen = 5'd15;  // SBCR high time in ticks

wire       sb_rise = sbcr & ~sbcr_d;
wire [4:0] tick_n  = sb_rise ? 5'd0 : (tick == 5'd29) ? 5'd0 : tick + 5'd1;

always @(posedge clk_md) begin
	sbcr_d <= sbcr;
	tick   <= tick_n;
	if (sb_rise)     hcnt <= 5'd1;
	else if (sbcr)   hcnt <= hcnt + 5'd1;
	if (~sbcr & sbcr_d) hlen <= hcnt;
end

// ------------------------------------------------------------ tick pairs

reg  [7:0] r_a = 8'd0, g_a = 8'd0, b_a = 8'd0;
reg        s_a = 1'b0;
reg [34:0] pair = 35'd0;          // {r, g, b, sync, angle}

// The pair covers ticks 2k and 2k+1, centred 2k+1 ticks after the rising
// edge; the fundamental peaks hlen/2 ticks after it. Two steps per tick.
wire [6:0] ang_raw = {tick_n[4:1], 2'b10} - {2'b00, hlen};
wire [5:0] ang_n   = ang_raw[6] ? ang_raw[5:0] + 6'd60 : ang_raw[5:0];

always @(posedge clk_md) begin
	if (~tick_n[0]) begin
		{r_a, g_a, b_a, s_a} <= {r, g, b, ~csync_n};
	end else begin
		pair <= {{1'b0, r_a} + r, {1'b0, g_a} + g, {1'b0, b_a} + b,
		         {1'b0, s_a} + {1'b0, ~csync_n}, ang_n};
	end
end

// ------------------------------------------------------------ to CLK_VIDEO

// clk_vid is clk_md / 2 from the same PLL at any phase. A clk_vid toggle,
// registered twice on clk_md, marks one clk_md edge in two at a fixed place in
// the clk_vid cycle; the pair is copied there and stays steady for the two
// clk_md cycles until the next copy, so clk_vid takes each pair once. Only the
// first toggle register crosses domains, and nothing timed hangs off it.
reg vid_tog = 0;
always @(posedge clk_vid) vid_tog <= ~vid_tog;

reg        vid_tog_m = 1'b0, vid_tog_m2 = 1'b0;
reg [34:0] cvbs_xfer = 35'd0;
always @(posedge clk_md) begin
	vid_tog_m  <= vid_tog;
	vid_tog_m2 <= vid_tog_m;
	if (vid_tog_m != vid_tog_m2) cvbs_xfer <= pair;
end

always @(posedge clk_vid) {r2, g2, b2, s2, ang} <= cvbs_xfer;

endmodule
