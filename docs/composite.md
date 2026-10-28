# Composite video: technical notes

## What the console does, and how we know

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
5. **Composite filters**: Kitrinx's composite decoder from the NES core (MIT licence), run at 15
   samples per subcarrier cycle. The sync AGC is a fixed contrast, because the board leaves white at
   0.645 V and sync at 0.264 V. Where a real set differs from that decoder in a way that matters for
   the Mega Drive, the set's behaviour is used:
   * the burst gate and black clamp are timed from the trailing edge of the 5.83 µs sync, as a set's
     burst gate pulse is, and chroma stays blanked through the back porch;
   * the Premium TV comb uses a set's fixed 227.5-cycle delay; a comb comparing whole 228-cycle lines
     would cancel the burst;
   * the sync separator averages over one subcarrier cycle before slicing, so saturated colours are
     never taken for sync.

   With a 4.7 µs sync and standard NTSC timing, the decoder behaves exactly as the original.

Not implemented: interlaced sync, PAL.

In simulation (Icarus Verilog), the encoder and board filters match a floating-point model of the
circuit to within 0.1 mV. The whole Nuked console running a test card through the composite path
gives [composite_testcard.png](composite_testcard.png).

## Build

Quartus 17.0.2 Lite, seed 7. Logic 82%, DSP blocks 100/112, RAM blocks 79%. Worst setup slack is
+0.006 ns and hold slack +0.190 ns, so timing passes. Removing the scandoubler, HQ2x, scanline
effects and Y/C output frees about 1,100 logic cells and 14 memory blocks.
