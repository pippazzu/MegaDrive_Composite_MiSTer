# Nuked-MD port for MiSTer, with composite video

![nukedmd_logo](rtl/nuked-md/nukedmd_logo.png)

[Original Nuked-MD repository](https://github.com/nukeykt/Nuked-MD-FPGA)

This fork adds the console's composite video: the picture a Model 1 Mega Drive sends through its AV
cable, decoded with Kitrinx's composite filters. See [Composite video](#composite-video).

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

Based on Kitrinx's NES core implementation, measured against two real Model 1 consoles (VA6 US, VA4
Japan) with an oscilloscope. Video chip pins from the Nuked netlist, Sony CXA1145 encoder from its
data sheet, Sega's board filters from the schematics, decoded with Kitrinx's composite filters. One
term, for fine coloured detail, is fitted to the measurements. Runs in step with the video signal,
adding under a microsecond of delay. Technical notes: [docs/composite.md](docs/composite.md).

Options, in **Audio & Video** (JP and US regions):

* **Composite Filter**: Off / Budget TV (notch filter, softer colour) / Premium TV (comb filter,
  sharper colour).
* **Comp. Brightness**: Japan (the console's own black) / USA (a US set: the darkest shades crush to
  black) / More / Much More / Too Much.
* **Comp. Sharpness**: Off / Low / Medium / High (the TV's sharpness knob).

This core is for 15 kHz RGB CRTs and HDMI. The scandoubler, HQ2x, scanline effects and Y/C output
are removed, and so is Composite Blend (the composite path does that blending itself). For 31 kHz
VGA or S-video, use the main core.

## Additional features

* Multitaps: 4-way, Team player, J-Cart
* SVP chip (Virtua Racing)
* Audio Filters for Model 1, Model 2, Minimal, No Filter.
* Option to choose between YM2612 and YM3438 (changes Ladder Effect behavior).
* FM chip for SMS carts.
* Composite video (see above).
* Border/Borderless modes.
* Support many popular mappers.
