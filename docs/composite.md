# Composite video: technical notes

## Model 1 composite output (CXA1145)

Sources: the Nuked YM7101 netlist (traced from the VDP die), the Sony CXA1145 data sheet, Sega's NTSC
schematics (Model 1, and the Model 2 CXA1145M parts list), the PAL-G maintenance manual. Measured with
a Hantek 6022BL oscilloscope at the AV jack, checked against a multimeter (±2%), on two Model 1s: a
VA6 (US) and a VA4 (Japan), with the project's test ROMs. Two consoles, not a survey.

1. **The VDP** outputs analog R, G and B from its DAC, a composite sync (C-SYNC) and the colour
   subcarrier (SBCR, master clock / 15), all from the netlist. A Mega Drive line is exactly 228
   subcarrier cycles, not NTSC's 227.5, so the carrier has the same phase on every line. The
   horizontal sync is 5.83 µs wide, not 4.7. Both were confirmed on the scope. The VDP's output for a
   1-pixel stripe matches an ideal stripe to 2%.
2. **The CXA1145 encoder** turns RGB into luma and chroma: Y = 0.299 R + 0.587 G + 0.114 B, white
   0.71 V, sync 0.29 V, no setup pedestal, 0.493 (B−Y) / 0.877 (R−Y) modulators, a 0.29 Vp-p burst at
   180°, and a half-H killer (data sheet). The subcarrier reaches it through 10 kΩ / 1 kΩ and 100 pF,
   a 63.9° lag (schematic). Measured: sync depth, white, grey, burst size, line length and sync width
   within 2–4%; the six colour-bar hues within 3° (VA4 against VA6: 2.4°).
3. **The board's filters** shape luma and chroma before they are mixed (schematics, topology from
   the PAL-G manual):
   * luma: R27 1.2k into L3 100 µH ∥ C35 12 pF, then C34 180 pF and R29 1k. A low-pass with a trap
     near 4.6 MHz, and why dithering blends. Some schematics give C35 as 18 pF; the PAL-G parts list
     gives 12 pF, and both real consoles pass about twice as much of a 3.4 MHz stripe as 18 pF would.
     With 12 pF the stripe response from 0.84 to 3.4 MHz matches within 4% (VA6) and 5% (VA4, 13% at
     2.7 MHz).
   * chroma: R28 1.2k into L5 12 µH ∥ C37 180 pF ∥ R26 330 Ω, a broad band-pass around 3.4 MHz.
4. **Fine coloured detail** reaches the luma at a strength that depends on its colour, which no
   document describes. Measured on the VA6 with 1- and 2-pixel stripes in red, green, blue, cyan,
   magenta and yellow, in both screen widths, repeated across a power cycle: a 1-pixel stripe
   (3.36 MHz) is 2.9× the circuit model in blue, 1.2× in red and 0.7× in green; at 2.7 / 1.7 MHz the
   blue figure is 1.9× / 1.1×. The colour mixes add up per channel within 10–25%.

The 228-cycle line means that on a checkerboard dither the colour beat flips from one line to the
next. A notch-filter TV shows this as fine "teeth"; a CRT seen from a normal distance blends it.

Not known: the full-screen rainbow banding some Model 1 boards show (layout crosstalk, never
measured).

## How it is implemented

1. **VDP pins**: the DAC levels, C-SYNC and SBCR come straight from the Nuked VDP, sampled at both
   edges of the 53.69 MHz master clock, so the subcarrier phase against every pixel edge is exact.
2. **Encoder**: the data sheet's typical values, inputs clamped during the burst flag, the burst from
   0.5 µs after the C-SYNC rising edge for 2.75 µs, the 63.9° lag carried into the modulators.
3. **Board filters**: both networks solved as exact zero-order-hold state-space systems at the master
   clock.
4. **Fine coloured detail** (item 4 above): the encoder adds −(21 (B−Y) + 9 (R−Y)), scaled and passed
   through four one-pole high-passes, to the luma. This halves the mismatch (0.034 → 0.015 Vp-p) and
   leaves flat colours and colour-bar edges unchanged. A fit to one console, not a circuit model.
5. **Composite filters**: Kitrinx's composite decoder from the NES core, run at 15 samples per
   subcarrier cycle, with the changes listed below. Its contrast input is fixed at what a set's
   sync AGC gives for this console's sync level. One output pixel every two samples: 26.85 MHz,
   1710 a line, four per H40 pixel and five per H32 pixel, so the scaler has 7.5 samples per
   subcarrier cycle to draw the decoded picture with (one in four left it 3.75).
6. **Gamma**: the decoded pixels come every two clocks, too fast for the gamma block inside
   `video_mixer`, which looks R, G and B up one after another and needs four clocks per pixel.
   The core uses the framework's `gamma_fast` instead, on both paths, which looks the three up at
   once from the same curve with the same one-pixel delay.

Not implemented: interlaced sync, PAL.

In simulation (Icarus Verilog), the encoder and board filters match a floating-point model of the
circuit to within 0.1 mV. The whole Nuked console running a test card through the composite path
gives [composite_testcard.png](composite_testcard.png).

## Changes to Kitrinx's composite decoder

The decoder is Kitrinx's from the NES core (MIT licence; the changes are MIT too), in
`rtl/composite/composite_decoder.sv`. It is the same file in the Mega Drive, Mega CD and 32X cores.

* **Burst gate and black clamp** are timed from the trailing edge of sync, as a set's burst gate
  pulse is, instead of from the leading edge. The Mega Drive's sync is 5.83 µs wide, so gates timed
  from the leading edge for a 4.7 µs sync would land inside it. With a 4.7 µs sync both still fall
  6.0 and 8.5 µs after the leading edge, as before.
* **Chroma is blanked** until the back porch is over (3.8 µs after sync ends), as a set blanks it
  through horizontal blanking, so the long burst is never shown.
* **Premium TV comb** uses a set's fixed 227.5-cycle delay instead of one line of the source. Mega
  Drive lines are 228 cycles, so a delay of one source line would meet chroma in phase and cancel
  the burst and the colour.
* **Sync separator** slices the signal averaged over one subcarrier cycle, as a set's does through
  its low-pass, instead of the raw signal. On a 32X, saturated colours swing the signal down to the
  sync tip (100% red against black: −0.297 V; sync tip: −0.30 V). The raw slicer counted those dips
  as line starts and tore the picture. The average's delay is taken back out, so all timing is as
  before; 0 of 84 pairs of full-strength colours now give a false line start.
* **Samples per cycle**: the core runs the decoder at 15 samples per subcarrier cycle (odd). The
  notch's half-cycle delay is then the mean of the two samples around it, and the comb's half-sample
  delay likewise.
* Not changing the picture: the sharpness filter's tap spacing is a parameter, two products are
  folded into one each (same results), and the comb's line store is a RAM inside the decoder rather
  than the core's dpram.

With a 4.7 µs sync and standard NTSC timing, the decoder gives the same picture as the original.

## Build

Quartus 17.0.2 Lite, seed 24 (best of 32). Logic 81%, DSP blocks 95/112, RAM blocks 437/553 (79%).
Worst setup slack is −0.041 ns, on three paths from `md_reset` to the write enable of the 68000 work
RAM, which only change at the start and end of a reset (the RAM clear); hold slack is +0.001 ns. The
untouched Nuked-MD core at its own seed misses by −0.119 ns. Removing the scandoubler, HQ2x, scanline
effects and Y/C output frees about 1,100 logic cells and 14 memory blocks.
