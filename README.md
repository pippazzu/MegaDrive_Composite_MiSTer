# Nuked-MD port for MiSTer

![nukedmd_logo](rtl/nuked-md/nukedmd_logo.png)

[Original Nuked-MD repository](https://github.com/nukeykt/Nuked-MD-FPGA)

## Installing
copy rbf to root of SD card. Put some ROMs (.BIN/.GEN/.MD/.SMS) into MegaDrive folder


## Hot Keys
* F1 - reset to JP(NTSC) region
* F2 - reset to US(NTSC) region
* F3 - reset to EU(PAL)  region


## Auto Region option (Megadrive/Genesis carts only)
There are 2 versions of region detection:

1) File name extension:

* BIN -> JP
* GEN -> US
* MD  -> EU

2) Header. It may not always work as not all ROMs follow the rule, especially in European region.
The header may include several regions - the correct one will be selected depending on priority option.


## Sega Master System

Core supports SMS carts with the same compatibility level as original MegaDrive hardware. Not all SMS carts are compatible with MD hardware.


## Composite video

**Audio & Video → Composite Filter** (JP and US regions) replaces the RGB picture with the console's
composite video, generated the way a Model 1 / Model 2 board makes it and shown through a modelled
NTSC television. Choose **Budget TV** (notch Y/C separation, narrow chroma) or **Premium TV**
(adaptive comb, wider chroma), then set **Comp. Brightness** (Japan has no 7.5 IRE setup, USA crushes
the darkest shades the way a US set does, the others lift the picture) and **Comp. Sharpness**.
The picture streams through with the beam: there is no frame buffer and the added delay is under a
microsecond.

What is modelled, in order:

1. **VDP pins.** The DAC level of each colour, C-SYNC and the SBCR subcarrier come straight from the
   Nuked YM7101 netlist, sampled at both edges of the 53.69 MHz master clock. SBCR is MCLK/15, so the
   subcarrier phase against every pixel edge is exact; that phase decides the colours of the rainbow
   on dithered patterns.
2. **Sony CXA1145 encoder** (data sheet typical values): RGB inputs clamped during the burst flag,
   Y = 0.299 R + 0.587 G + 0.114 B with white at 0.71 V and sync at 0.29 V, no setup pedestal,
   0.493 (B-Y) / 0.877 (R-Y) modulators, a 0.29 Vp-p burst at 180° from 0.5 µs after the C-SYNC
   rising edge for 2.75 µs, and a half-H killer. The subcarrier reaches X IN through 10 kΩ / 1 kΩ and
   100 pF, a 63.9° lag that is carried into the modulators.
3. **The board's Y/C networks**, from Sega's NTSC schematics (Model 1, and the Model 2 CXA1145M parts
   list) with the topology confirmed against the PAL-G maintenance manual:
   * luma: R27 1.2k into L3 100 µH ∥ C35 12 pF, then C34 180 pF and R29 1k at Y IN — the "delay line"
     is a low-pass with a trap near 3.75 MHz, which is why dithering blends on a Mega Drive;
   * chroma: R28 1.2k into L5 12 µH ∥ C37 180 pF ∥ R26 330 Ω, a broad band-pass around 3.4 MHz.

   Both are solved as exact zero-order-hold state-space systems at the master clock.
4. **The television**: Kitrinx's composite decoder from the NES core (MIT), run at 15 samples per
   subcarrier cycle. A real set's sync AGC is applied as a fixed contrast, since the board leaves white
   at 0.645 V and sync at 0.264 V. Two things a real set does differently from that decoder matter
   for the Mega Drive, and are modelled the way a set does them:
   * the VDP's horizontal sync is 5.83 µs, not 4.7, so the burst gate and black clamp are timed
     from the trailing edge of sync (as a set's burst gate pulse is), not from its leading edge,
     and chroma stays blanked until the back porch is over, so the long burst never shows;
   * a Mega Drive line is exactly 228 subcarrier cycles, not 227.5, so the Premium TV comb uses a
     set's fixed 227.5-cycle 1H delay: the previous line half a cycle along still carries inverted
     chroma, where a line-locked comb would cancel the burst and the colour.

   With a 4.7 µs sync and standard NTSC timing both behave exactly as the original.

Not modelled: the full-screen "rainbow banding" some Model 1 boards show, which comes from layout
crosstalk with no published measurements; PAL (the decoder is an NTSC set).

The Border and 320x224 Aspect options do not apply while composite is on. The scandoubler, HQ2x, scanline effects and MiSTer's Y/C output are not built into this core, which frees about 1,100 logic cells and 14 memory blocks; the picture leaves at the console's own line rate, which suits a PVM or other 15 kHz RGB display and the HDMI scaler, but a 31 kHz VGA monitor on the analog output gets no line doubling.

## Additional features

* Multitaps: 4-way, Team player, J-Cart
* SVP chip (Virtua Racing)
* Audio Filters for Model 1, Model 2, Minimal, No Filter.
* Option to choose between YM2612 and YM3438 (changes Ladder Effect behavior).
* FM chip for SMS carts.
* Composite video (see above).
* Border/Borderless modes.
* Support many popular mappers.
