include ./mk/Variables.mk
include ./mk/Compile.mk
-include $(depfiles)

SDKSTAGE     = /home/cross/firmware-rpi/firmware/hardfp
CROSS        = /opt/crosstool-ng/arm-rpi-linux-gnueabi
HOST         := arm-rpi-linux-gnueabi
LD           := $(HOST)-ld
CC           := $(HOST)-gcc
CXX          := $(HOST)-g++
OBJDUMP      := $(HOST)-objdump
RANLIB       := $(HOST)-ranlib
STRIP        := $(HOST)-strip
AR           := $(HOST)-ar
HAVE_LIBCURL := no
HAVE_LIBLIRC := no

CFLAGS	     += -DVERSION='"$(VERSION)"' -I. -Wno-pointer-sign -Ijpeg/80
CFLAGS       += -pipe -mfloat-abi=hard -mcpu=arm1176jzf-s -fomit-frame-pointer -mabi=aapcs-linux -mtune=arm1176jzf-s -mfpu=vfp -Wno-psabi -mno-apcs-stack-check -O3 -mstructure-size-boundary=32 -mno-sched-prolog
LDFLAGS      += -L$(SDKSTAGE)/opt/vc/lib/ -L$(CROSS)/lib
INCLUDES     += -I$(SDKSTAGE)/opt/vc/include -I$(SDKSTAGE)/opt/vc/include/interface/vcos/pthreads -I$(SDKSTAGE)/opt/vc/include/freetype -isystem$(CROSS)/include \
                -isystem/opt/crosstool-ng/boost_1_53_0 -I$(SDKSTAGE)/opt/vc/include/interface/vmcs_host/linux

all: build

########################################################################
# links which conditional stuff/libs
fbi_libs	= PCD GIF PNG TIFF
fbi : LDLIBS += $(call ac_lib_mkvar,$(fbi_libs),LDLIBS)

########################################################################
# rules for fib and object files
OBJS_FBI := fb-gui.o fbi.o fbtools.o desktop.o \
	    parseconfig.o fbiconfig.o \
	    jpegtools.o jpeg/80/transupp.o \
	    dither.o filter.o op.o readers.o \
            rd/read-ppm.o rd/read-bmp.o rd/read-jpeg.o rd/read-png.o rd/read-tiff.o rd/read-gif.o

OBJS_FBI += $(filter-out wr/%,$(call ac_lib_mkvar,$(fbi_libs),OBJS))

fbi : CFLAGS  += -I/opt/fontconfig/include/ -I$(SDKSTAGE)/opt/vc/include/ -I$(SDKSTAGE)/opt/vc/include/freetype/ -I$(CROSS)/include
fbi : LDFLAGS += -lfreetype -lexpat -lfontconfig
fbi : LDLIBS  += $(INCLUDES) -L/opt/fontconfig/lib/
fbi : LDLIBS  += -ljpeg -lexif -lm -lpng -lz -ltiff -lgif

fbi : $(OBJS_FBI)

########################################################################
# general rules
build: fbi

clean:
	-rm -f *.o jpeg/80/*.o rd/*.o wr/*.o $(depfiles) fbi
