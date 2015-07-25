#
# if you want the ram-disk device, define this to be the
# size in blocks.
#
RAMDISK =  -DRAMDISK=2048

# This is a basic Makefile for setting the general configuration
include Makefile.header

LDFLAGS	+= -Ttext 0 -e startup_32
CFLAGS	+= $(RAMDISK) -Iinclude
CPP	+= -Iinclude

#
# ROOT_DEV specifies the default root-device when making the image.
# This can be either FLOPPY, /dev/xxxx or empty, in which case the
# default of hd1(0301) is used by 'build'.
#
#ROOT_DEV= 021d	# FLOPPY B
#ROOT_DEV= 0301	# hd1

ARCHIVES=kernel/kernel.o mm/mm.o fs/fs.o
DRIVERS =kernel/blk_drv/blk_drv.a kernel/chr_drv/chr_drv.a
MATH	=kernel/math/math.a
LIBS	=lib/lib.a

.c.s:
	@$(CC) $(CFLAGS) -S -o $*.s $<
.s.o:
	@$(AS)  -o $*.o $<
.c.o:
	@$(CC) $(CFLAGS) -c -o $*.o $<

all:	Image

Image: boot/bootsect boot/setup kernel.sym ramfs
	@cp -f images/kernel.sym images/kernel.tmp
	@$(STRIP) images/kernel.tmp
	@$(OBJCOPY) -O binary -R .note -R .comment images/kernel.tmp images/kernel
	tools/build.sh boot/bootsect boot/setup images/kernel images/Image rootfs/$(RAM_IMG) $(ROOT_DEV)
	@rm images/kernel.tmp
	@rm -f images/kernel
	@sync

boot/head.o: boot/head.s
	@make head.o -C boot/

kernel.sym: boot/head.o init/main.o \
		$(ARCHIVES) $(DRIVERS) $(MATH) $(LIBS)
	@$(LD) $(LDFLAGS) boot/head.o init/main.o \
	$(ARCHIVES) \
	$(DRIVERS) \
	$(MATH) \
	$(LIBS) \
	-o images/kernel.sym
	@nm images/kernel.sym | grep -v '\(compiled\)\|\(\.o$$\)\|\( [aU] \)\|\(\.\.ng$$\)\|\(LASH[RL]DI\)'| sort > images/kernel.map

kernel/math/math.a:
	@make -C kernel/math

kernel/blk_drv/blk_drv.a:
	@make -C kernel/blk_drv

kernel/chr_drv/chr_drv.a:
	@make -C kernel/chr_drv

kernel/kernel.o:
	@make -C kernel

mm/mm.o:
	@make -C mm

fs/fs.o:
	@make -C fs

lib/lib.a:
	@make -C lib

boot/setup: boot/setup.s
	@make setup -C boot

boot/bootsect: boot/bootsect.s
	@make bootsect -C boot

clean:
	@make clean -C rootfs
	@rm -f images/Image images/kernel.map tmp_make core boot/bootsect boot/setup
	@rm -f init/*.o images/kernel.sym boot/*.o typescript* info bochsout.txt
	@make clean -C callgraph
	@for i in mm fs kernel lib boot; do make clean -C $$i; done

distclean: clean
	@rm -f tag* cscope* linux-0.11.*

dep:
	@sed '/\#\#\# Dependencies/q' < Makefile > tmp_make
	@(for i in init/*.c;do echo -n "init/";$(CPP) -M $$i;done) >> tmp_make
	@cp tmp_make Makefile
	@for i in fs kernel mm; do make dep -C $$i; done

# Test on emulators with different prebuilt rootfs
include Makefile.emulators

# Tags for source code reading
include Makefile.tags

# For Call graph generation
include Makefile.callgraph

help:
	@echo "------------------Linux 0.11 Lab (http://tinylab.org/linux-0.11-lab)------------------"
	@echo ""
	@echo "     :: Compile ::"
	@echo ""
	@echo "     make --generate a kernel floppy Image with a fs on hda1"
	@echo "     make clean -- clean the object files"
	@echo "     make distclean -- only keep the source code files"
	@echo ""
	@echo "     :: Test ::"
	@echo ""
	@echo "     make start -- start the kernel in vm (qemu/bochs)"
	@echo "     make start-fd -- start the kernel with fs in floppy"
	@echo "     make start-hd -- start the kernel with fs in hard disk"
	@echo ""
	@echo ""
	@echo "     :: Debug ::"
	@echo ""
	@echo "     make debug -- debug the kernel in qemu/bochs & gdb at port 1234"
	@echo "     make debug-fd -- debug the kernel with fs in floppy"
	@echo "     make debug-hd -- debug the kernel with fs in hard disk"
	@echo ""
	@echo "     make switch -- switch the emulator: qemu and bochs"
	@echo ""
	@echo "     :: Read ::"
	@echo ""
	@echo "     make cscope -- genereate the cscope index databases"
	@echo "     make tags -- generate the tag file"
	@echo "     make cg -- generate callgraph of the default main entry"
	@echo "     make cg f=func d=dir|file b=browser -- generate callgraph of func in file/directory"
	@echo ""
	@echo "     :: More ::"
	@echo ""
	@echo "     >>> README.md <<<"
	@echo ""
	@echo "     ~ Enjoy It ~"
	@echo ""
	@echo "-------------------Linux 0.11 Lab (http://tinylab.org/linux-0.11-lab)-------------------"

### Dependencies:
init/main.o: init/main.c include/unistd.h include/sys/stat.h \
  include/sys/types.h include/sys/times.h include/sys/utsname.h \
  include/utime.h include/time.h include/linux/tty.h include/termios.h \
  include/linux/sched.h include/linux/head.h include/linux/fs.h \
  include/linux/mm.h include/signal.h include/asm/system.h \
  include/asm/io.h include/stddef.h include/stdarg.h include/fcntl.h
