// SPDX-License-Identifier: MIT

// Fixed delay line for the composite path: q is d as it was N samples ago,
// the last tap of an N-stage shift register, kept in block RAM.
//
// The store is cleared by writing zeros for as long as reset is high, so a
// reset must last at least 2^clog2(N) + 2 clocks for q to match a shift
// register that is cleared at once. Short lines stay in registers.
// CLR_IN = 0 leaves out the zeroing of d, for a d that is itself zero from
// the first clock of reset on (a register with the same reset).

module cd_delay #(
	parameter W = 16,
	parameter N = 8,
	parameter CLR_IN = 1
)(
	input              clk,
	input              reset,
	input              ce,
	input      [W-1:0] d,
	output     [W-1:0] q
);

generate
	if (N < 4) begin : regs
		logic [W-1:0] sr [N];
		always_ff @(posedge clk) if (reset) begin
			for (int i = 0; i < N; i++) sr[i] <= '0;
		end else if (ce) begin
			sr[0] <= d;
			for (int i = 1; i < N; i++) sr[i] <= sr[i - 1];
		end
		assign q = sr[N-1];
	end else begin : ram
		localparam AW = $clog2(N);
		(* ramstyle = "M10K, no_rw_check" *) logic [W-1:0] mem[1 << AW];
		logic [AW-1:0] wp = '0;
		logic [W-1:0]  rd = '0;
		// The read is N - 1 behind the write, never the cell being written.
		wire  [AW-1:0] ra = wp - AW'(N - 1);
		wire           step = ce | reset;

		initial for (int k = 0; k < (1 << AW); k++) mem[k] = '0;

		always_ff @(posedge clk) if (step) begin
			mem[wp] <= (CLR_IN && reset) ? {W{1'b0}} : d;
			rd <= mem[ra];
			wp <= wp + 1'b1;
		end
		assign q = rd;
	end
endgenerate

endmodule
