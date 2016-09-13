###
### Target: rebuild, buildchip, assembleimage, clean
###

all: assembleimage

rebuild: clean, buildchip, assembleimage

CHIP_BUILDROOT=~/CHIP-buildroot
OUTPUTDIR=output
TOPDIR := $(shell pwd)
# Variables for use in Make constructs
comma := ,
empty :=
space := $(empty) $(empty)
LINUX_BUILD_VERSION=$(shell grep BR2_LINUX_KERNEL_VERSION $(CHIP_BUILDROOT)/.config | sed 's/BR2_LINUX_KERNEL_VERSION="\(.*\)\"/\1/' | sed -e 's/debian\/\(.*\)/\1/')
LINUX_VERSION=$(shell echo $(LINUX_BUILD_VERSION) | sed -e 's/\([0-9]\+\.[0-9]\+\.[0-9]\+\)\(.*\)/\1/')

CHIPIMAGES=$(OUTPUTDIR)/image/startusbboot $(OUTPUTDIR)/image/u-boot-dtb.bin $(OUTPUTDIR)/image/sunxi-spl.bin $(OUTPUTDIR)/image/sun5i-r8-chip.dtb $(OUTPUTDIR)/image/zImage $(OUTPUTDIR)/image/boot-fel.scr initrd

assembleimage: preassemble directories $(CHIPIMAGES) postassemble

preassemble:
	@echo "============ Assemble Image Begins =============="

postassemble:
	@echo "============ Assemble Image Done   =============="

directories: $(OUTPUTDIR)/image $(OUTPUTDIR)/target $(OUTPUTDIR)/target/etc $(OUTPUTDIR)/target/etc/init.d \
 	$(OUTPUTDIR)/target/dev $(OUTPUTDIR)/target/proc $(OUTPUTDIR)/target/sys $(OUTPUTDIR)/target/mnt $(OUTPUTDIR)/target/bin

$(OUTPUTDIR)/image $(OUTPUTDIR)/target $(OUTPUTDIR)/target/etc $(OUTPUTDIR)/target/etc/init.d \
 	$(OUTPUTDIR)/target/dev $(OUTPUTDIR)/target/proc $(OUTPUTDIR)/target/sys $(OUTPUTDIR)/target/mnt $(OUTPUTDIR)/target/bin:
	mkdir -p $@

$(OUTPUTDIR)/image/startusbboot: startusbboot

$(OUTPUTDIR)/image/zImage: $(CHIP_BUILDROOT)/output/images/zImage

$(OUTPUTDIR)/image/boot-fel.scr: screen.conf
	mkimage -A arm -T script -C none -n "Starting USB Boot through FEL" -d $< $@

$(OUTPUTDIR)/image/u-boot-dtb.bin: $(CHIP_BUILDROOT)/output/images/u-boot-dtb.bin

$(OUTPUTDIR)/image/sunxi-spl.bin: $(CHIP_BUILDROOT)/output/images/sunxi-spl.bin

$(OUTPUTDIR)/image/sun5i-r8-chip.dtb: $(CHIP_BUILDROOT)/output/images/sun5i-r8-chip.dtb

RAMFS = $(addprefix $(OUTPUTDIR)/target/,$(shell cd ramfs && find . -type f)) \
	$(addprefix $(OUTPUTDIR)/target/,$(shell cd ramfs && find . -type l))

$(OUTPUTDIR)/target/% : ramfs/%
	@test -d $(@D) || mkdir -p $(@D) && cp -f -R --preserve=links  $< $@

$(OUTPUTDIR)/target/lib:
	@rm -Rf $(OUTPUTDIR)/target/lib/

$(OUTPUTDIR)/target/bin/busybox: $(CHIP_BUILDROOT)/output/target/bin/busybox

$(OUTPUTDIR)/target/bin/sh: $(OUTPUTDIR)/target/bin/busybox
	ln -s busybox $@

LIBSOURCE =  $(addprefix $(OUTPUTDIR)/target/lib/,$(shell cd $(CHIP_BUILDROOT)/output/target/lib && find . -type f)) \
             $(addprefix $(OUTPUTDIR)/target/lib/,$(shell cd $(CHIP_BUILDROOT)/output/target/lib && find . -type l)) \
	     $(addprefix $(OUTPUTDIR)/target/sbin/,$(shell cd $(CHIP_BUILDROOT)/output/target/sbin && find . -type f)) \
	     $(addprefix $(OUTPUTDIR)/target/sbin/,$(shell cd $(CHIP_BUILDROOT)/output/target/sbin && find . -type l)) \
	     $(addprefix $(OUTPUTDIR)/target/bin/,$(shell cd $(CHIP_BUILDROOT)/output/target/bin && find . -type f)) \
	     $(addprefix $(OUTPUTDIR)/target/bin/,$(shell cd $(CHIP_BUILDROOT)/output/target/bin && find . -type l)) \
	     $(addprefix $(OUTPUTDIR)/target/usr/lib/,$(shell cd $(CHIP_BUILDROOT)/output/target/usr/lib && find . -type f)) \
	     $(addprefix $(OUTPUTDIR)/target/usr/lib/,$(shell cd $(CHIP_BUILDROOT)/output/target/usr/lib && find . -type l)) \
	     $(addprefix $(OUTPUTDIR)/target/, usr/bin/kmod) \
	     $(addprefix $(OUTPUTDIR)/target/, lib32) $(addprefix $(OUTPUTDIR)/target/, linuxrc)
	     


$(OUTPUTDIR)/target/% : $(CHIP_BUILDROOT)/output/target/%
	@test -d $(@D) || mkdir -p $(@D) && cp -f -R --preserve=links  $< $@

$(OUTPUTDIR)/%:
	@test -d $(@D) || mkdir -p $(@D) && cp -f -R --preserve=links  $< $@

#initrd: preinitrd \
	$(RAMFS) \
	$(OUTPUTDIR)/target/init \
	$(OUTPUTDIR)/target/etc/inittab \
	$(OUTPUTDIR)/target/etc/init.d/S10modules \
	$(OUTPUTDIR)/target/etc/init.d/rcS \
	$(OUTPUTDIR)/target/etc/init.d/rcK \
	$(OUTPUTDIR)/target/etc/modules \
	$(OUTPUTDIR)/target/lib \
	$(OUTPUTDIR)/target/bin/busybox \
	$(OUTPUTDIR)/target/bin/sh \
	$(LIBSOURCE) \
	$(OUTPUTDIR)/image/initrd.img

initrd: preinitrd \
	$(OUTPUTDIR)/image/initrd.img
	@echo "initrd done"

$(OUTPUTDIR)/image/initrd.img: $(OUTPUTDIR)/tmp/initrd.gz
	mkimage -A arm -T ramdisk -n "initrd ramdisk" -d $< $@

$(OUTPUTDIR)/tmp/initrd.gz: $(RAMFS) $(LIBSOURCE) 
	@test -d $(@D) || mkdir -p $(@D) && cd $(OUTPUTDIR)/target && pwd && find . | cpio -ov -R 0:0 -H newc | gzip > ../../$@
	
preinitrd:
	@echo "Generating initrd"
	@echo "copying kernel modules and libraries..."

buildchip:
	@echo "============ Make CHIP-buildroot =============="
	@cd $(CHIP_BUILDROOT) && $(MAKE) j=8
	@echo "============ CHIP-buildroot Done =============="

echo:
	@echo $(LINUX_BUILD_VERSION)
	@echo $(LINUX_VERSION)

clean:
	rm -Rf $(OUTPUTDIR)

.PHONY: directories buildchip assembleimage preassemble postassemble initrd clean
.INTERMEDIATE: 
