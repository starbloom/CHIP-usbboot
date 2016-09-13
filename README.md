# CHIP-usbboot


I am happy to share my way to test CHIP custom kernel builds before deploying it to the CHIP boot directory. I myself crashed more than a few times. Without a serial to USB cable, I know the pain to flash the CHIP just to get the control back again but lose all the usual customization. So this is an easier way to boot of the kernel and have some essential tools to do testing and repair if needed.

To use this USB boot tool, download the source code 

git clone https://github.com/starbloom/CHIP-usbboot.git

Change the Makefile to the CHIP-buildroot location and type make. The image is stored in output/image folder.

Now use a wire to connect the FEL and Ground, then connect your CHIP computer using micro USB cable. There are excellent instructions and pictures on http://docs.getchip.com/chip.html to show you the steps.

Once it's powered on, type "cd output/image; ./startusbboot". It takes about 20 seconds to upload the new kernel and images to CHIP and another 10 seconds to boot. But you should be able to connect through "screen /dev/ttyACM0 115200". If you do hook up TV and USB keyboard, there is a second console waiting for you there. The root file system is mounted at /mnt.

Feel free to customize the RAMFS or additional packages. I am using CHIP as my mini wifi router/repeater as we speak.

Special thanks to the following folks... You gave me the idea to put the buildroot together with USB boot. Thanks.

A rescue tool. no uart by Guest https://bbs.nextthing.co/t/a-rescue-tool-no-uart/9042

Compile the Linux kernel for Chip: my personal HOWTO by renzo https://bbs.nextthing.co/t/compile-the-linux-kernel-for-chip-my-personal-howto/2669

and many other helpful posts on https://bbs.nextthing.co/
