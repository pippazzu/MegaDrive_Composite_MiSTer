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

**Audio & Video → Composite Filter** (JP and US regions) shows the console's composite video, as a
Model 1 board makes it, on a modelled NTSC TV:

* **Composite Filter**: Off / Budget TV (notch filter, softer colour) / Premium TV (comb filter,
  sharper colour).
* **Comp. Brightness**: Japan (the console's own black) / USA (a US set: the darkest shades crush to
  black) / More / Much More / Too Much.
* **Comp. Sharpness**: Off / Low / Medium / High (the TV's sharpness knob).

No frame buffer: the added delay is under a microsecond. Dithering blends and rainbows as on a real
console. On HDMI, checkerboard dither shows fine "teeth" that change colour from line to line; a real
console through a RetroTINK shows the same.

This core is for 15 kHz RGB CRTs and HDMI. The scandoubler, HQ2x, scanline effects and Y/C output are
removed, and so is Composite Blend (the composite path does that blending itself). For 31 kHz VGA or
S-video, use the main core.

How it is modelled and measured against real consoles: [docs/composite.md](docs/composite.md).

## Additional features

* Multitaps: 4-way, Team player, J-Cart
* SVP chip (Virtua Racing)
* Audio Filters for Model 1, Model 2, Minimal, No Filter.
* Option to choose between YM2612 and YM3438 (changes Ladder Effect behavior).
* FM chip for SMS carts.
* Composite video (see above).
* Border/Borderless modes.
* Support many popular mappers.
