# Composite video: technical notes

The composite path follows the real signal chain: the VDP's pins, the board's encoder and filter
networks, then a TV. It works the same way as Kitrinx's NES core.

## What is modelled

1. **VDP pins.** The DAC level of each colour, C-SYNC and the SBCR subcarrier come straight from the
   Nuked YM7101 netlist, sampled at both edges of the 53.69 MHz master clock. SBCR is MCLK/15, so the
   subcarrier phase against every pixel edge is exact; that phase decides the rainbow colours on
   dithered patterns.
2. **Sony CXA1145 encoder** (data sheet typical values): RGB inputs clamped during the burst flag,
   Y = 0.299 R + 0.587 G + 0.114 B, white 0.71 V, sync 0.29 V, no setup pedestal, 0.493 (B−Y) /
   0.877 (R−Y) modulators, a 0.29 Vp-p burst at 180° from 0.5 µs after the C-SYNC rising edge for
   2.75 µs, and a half-H killer. The subcarrier reaches X IN through 10 kΩ / 1 kΩ and 100 pF, a
   63.9° lag carried into the modulators.

   One term is not from the data sheet. On a real Model 1 (VA6), how strongly fine coloured detail
   reaches the luma depends on the colour. A 1-pixel stripe (3.36 MHz) is 2.9× the plain model in
   blue, 1.2× in red and 0.7× in green; at 2.7 / 1.7 MHz the blue figure is 1.9× / 1.1×. The encoder
   adds −(21 (B−Y) + 9 (R−Y)), scaled and passed through four one-pole high-passes, to the luma.
   This halves the mismatch (0.034 → 0.015 Vp-p) and leaves flat colours and colour-bar edges
   unchanged. It is a fit to one console, not a circuit model.
3. **Board Y/C networks**, from Sega's NTSC schematics (Model 1, and the Model 2 CXA1145M parts list),
   with the topology confirmed against the PAL-G maintenance manual:
   * luma: R27 1.2k into L3 100 µH ∥ C35 12 pF, then C34 180 pF and R29 1k at Y IN. This "delay
     line" is a low-pass with a trap near 4.6 MHz, and it is why dithering blends. C35 is 12 pF as
     in the PAL-G parts list: two real NTSC Model 1s pass about twice as much of a 3.4 MHz stripe as
     the 18 pF of some schematics would.
   * chroma: R28 1.2k into L5 12 µH ∥ C37 180 pF ∥ R26 330 Ω, a broad band-pass around 3.4 MHz.

   Both networks are solved as exact zero-order-hold state-space systems at the master clock.
4. **TV**: Kitrinx's composite decoder from the NES core (MIT licence), run at 15 samples per
   subcarrier cycle. The sync AGC is a fixed contrast, because the board leaves white at 0.645 V and
   sync at 0.264 V. Where a real set differs from that decoder in a way that matters for the Mega
   Drive, the set's behaviour is modelled:
   * The VDP's horizontal sync is 5.83 µs, not 4.7, so the burst gate and black clamp are timed from
     the trailing edge of sync, as a set's burst gate pulse is. Chroma stays blanked through the back
     porch.
   * A Mega Drive line is exactly 228 subcarrier cycles, not 227.5, so the Premium TV comb uses a
     set's fixed 227.5-cycle delay. A comb that compared whole lines would cancel the burst.
   * The sync separator averages over one subcarrier cycle before slicing, so saturated colours are
     never taken for sync.

   With a 4.7 µs sync and standard NTSC timing, the decoder behaves exactly as the original.

The 228-cycle line also explains the dither "teeth" on HDMI. The colour carrier has the same phase
on every line, so on a checkerboard the colour beat flips from one line to the next. Any notch-filter
TV shows this; a CRT seen from a normal distance blends it.

**Not modelled:** the full-screen rainbow banding some Model 1 boards show (layout crosstalk, never
measured), interlaced sync, and PAL.

## Measured against real consoles

The measurements used a Hantek 6022BL oscilloscope at the AV jack (checked against a multimeter,
±2%) and test ROMs from the project. The consoles were two Model 1s, a VA6 (US) and a VA4 (Japan):

* Sync depth, white, grey, burst size, line length and sync width match within 2–4%.
* The six colour-bar hues match within 3° (VA4 against VA6: 2.4°).
* Stripe response from 0.84 to 3.4 MHz matches within 4% on the VA6, and within 5% on the VA4
  except 13% at 2.7 MHz.
* Coloured 1- and 2-pixel stripes were measured in red, green, blue, cyan, magenta and yellow, in
  both screen widths, and repeated across a power cycle. The colour mixes add up per channel within
  10–25%, which is why one fixed term (item 2 above) covers them.
* The Nuked VDP's own output for a 1-pixel stripe matches an ideal stripe to 2%. The real console's
  extra fine detail therefore comes from the board, not the chip.

These are two consoles, not a survey. In simulation (Icarus Verilog), the encoder and board filters
match a floating-point model of the circuit to within 0.1 mV. The whole Nuked console running a
test card through the composite path gives [composite_testcard.png](composite_testcard.png).

## Build

Quartus 17.0.2 Lite, seed 7. Logic 82%, DSP blocks 100/112, RAM blocks 79%. Worst setup slack is
+0.006 ns and hold slack +0.190 ns, so timing passes. Removing the scandoubler, HQ2x, scanline
effects and Y/C output frees about 1,100 logic cells and 14 memory blocks.
