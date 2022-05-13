## Notes for Fly Board - Gemini 1 and 2
### TFT Configuration 

https://github.com/Mellow-3D/klipper-docs/blob/master/docs/advanced/screen.md

### Notes for dts

```
fly@flygemini:/boot$ cat armbianEnv.txt 
verbosity=1
bootlogo=false
console=serial
overlay_prefix=sun50i-h5
overlays=usbhost2 usbhost3 FLY-TFT-V1
param_spidev_spi_bus=0
rootdev=UUID=e538b2aa-6c14-41dc-a04b-2e794cf3d04f
rootfstype=ext4
disp_mode=1920x1080p60
usbstoragequirks=0x2537:0x1066:u,0x2537:0x1068:u

```

```
fly@flygemini:/boot/dtb-5.10.85-sunxi64/allwinner$ dmesg | grep fb_ili9488
[    7.388346] fb_ili9488: module is from the staging directory, the quality is unknown, you have been warned.
[    7.390201] fb_ili9488 spi1.0: there is not valid maps for state default
[    7.390326] fb_ili9488 spi1.0: fbtft_property_value: width = 320
[    7.390336] fb_ili9488 spi1.0: fbtft_property_value: height = 480
[    7.390478] fb_ili9488 spi1.0: fbtft_property_value: regwidth = 8
[    7.390486] fb_ili9488 spi1.0: fbtft_property_value: buswidth = 8
[    7.390497] fb_ili9488 spi1.0: fbtft_property_value: debug = 0
[    7.390505] fb_ili9488 spi1.0: fbtft_property_value: rotate = 270
[    7.390515] fb_ili9488 spi1.0: fbtft_property_value: fps = 60
[    7.750570] graphics fb0: fb_ili9488 frame buffer, 480x320, 300 KiB video memory, 4 KiB buffer memory, fps=62, spi1.0 at 50 MHz
[    7.791151] systemd[1]: Starting Load/Save Screen Backlight Brightness of backlight:fb_ili9488...
[    8.038627] systemd[1]: Finished Load/Save Screen Backlight Brightness of backlight:fb_ili9488.

```

```
fly@flygemini:~$ dmesg | grep touch
[    7.369233] ads7846 spi1.1: touchscreen, irq 93
```
