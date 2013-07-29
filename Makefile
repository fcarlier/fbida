srcdir	= .
include $(srcdir)/mk/Variables.mk
resdir	=  $(DESTDIR)$(RESDIR)

# fixup flags
CFLAGS	+= -DVERSION='"$(VERSION)"' -I$(srcdir) -Wno-pointer-sign

SDKSTAGE=/home/cross/firmware-rpi/firmware/hardfp
CROSS=/opt/crosstool-ng/arm-rpi-linux-gnueabi
FLOAT=hard

HOST :=arm-rpi-linux-gnueabi

LD := $(HOST)-ld
CC := $(HOST)-gcc
CXX := $(HOST)-g++
OBJDUMP := $(HOST)-objdump
RANLIB := $(HOST)-ranlib
STRIP := $(HOST)-strip
AR := $(HOST)-ar

CFLAGS                  += -pipe -mfloat-abi=$(FLOAT) -mcpu=arm1176jzf-s -fomit-frame-pointer -mabi=aapcs-linux -mtune=arm1176jzf-s -mfpu=vfp -Wno-psabi -mno-apcs-stack-check -O3 -mstructure-size-boundary=32 -mno-sched-prolog
LDFLAGS                 += -L$(SDKSTAGE)/opt/vc/lib/ -L$(CROSS)/lib
INCLUDES                += -I$(SDKSTAGE)/opt/vc/include -I$(SDKSTAGE)/opt/vc/include/interface/vcos/pthreads -I$(SDKSTAGE)/opt/vc/include/freetype -isystem$(CROSS)/include -isystem/opt/crosstool-ng/boost_1_53_0 -I$(SDKSTAGE)/opt/vc/include/interface/vmcs_host/linux

all: build
TARGETS := exiftran thumbnail.cgi fbi

CFLAGS  += -Ijpeg/80

# transparent http/ftp access using curl depends on fopencookie (glibc)
ifneq ($(HAVE_GLIBC),yes)
  HAVE_LIBCURL	:= no
endif

# catch fopen calls for transparent ftp/http access
ifeq ($(HAVE_LIBCURL),yes)
  fbi : CFLAGS   += -D_GNU_SOURCE
  fbi : LDFLAGS  += -Wl,--wrap=fopen
endif


########################################################################
# conditional stuff

includes        = ENDIAN_H STRCASESTR NEW_EXIF
libraries       = PCD GIF PNG TIFF
fbi_libs	= PCD GIF PNG TIFF

PNG_LDLIBS	:= -lpng -lz
TIFF_LDLIBS	:= -ltiff
GIF_LDLIBS	:= -lgif

PNG_OBJS	:= rd/read-png.o
TIFF_OBJS	:= rd/read-tiff.o
GIF_OBJS	:= rd/read-gif.o

# common objs
OBJS_READER	:= readers.o rd/read-ppm.o rd/read-bmp.o rd/read-jpeg.o

# link which conditional libs
fbi : LDLIBS += $(call ac_lib_mkvar,$(fbi_libs),LDLIBS)


########################################################################
# rules for the small tools

CFLAGS += -I/opt/crosstool-ng/arm-rpi-linux-gnueabi/include

# jpeg/exif libs
exiftran      : LDLIBS += -ljpeg -lexif -lm
thumbnail.cgi : LDLIBS += -lexif -lm

exiftran: exiftran.o genthumbnail.o jpegtools.o \
	jpeg/80/transupp.o \
	filter.o op.o readers.o rd/read-jpeg.o
thumbnail.cgi: thumbnail.cgi.o


########################################################################
# rules for fbi

# object files
OBJS_FBI := \
	fb-gui.o fbi.o fbtools.o desktop.o \
	parseconfig.o fbiconfig.o \
	jpegtools.o jpeg/80/transupp.o \
	dither.o filter.o op.o

OBJS_FBI += $(filter-out wr/%,$(call ac_lib_mkvar,$(fbi_libs),OBJS))

# jpeg/exif libs
fbi : CFLAGS += -I/opt/fontconfig/include/ -I/home/cross/firmware-rpi/firmware/hardfp/opt/vc/include/ -I/home/cross/firmware-rpi/firmware/hardfp/opt/vc/include/freetype/
fbi : LDFLAGS += -lfreetype -lexpat -lfontconfig
fbi : LDLIBS += $(INCLUDES)
fbi : LDLIBS += -ljpeg -lexif -lm $(PNG_LDLIBS) $(TIFF_LDLIBS) $(GIF_LDLIBS)
fbi : LDLIBS += -L/opt/fontconfig/lib/ -L/home/cross/firmware-rpi/firmware/hardfp/opt/vc/lib/ -I/home/cross/firmware-rpi/firmware/hardfp/opt/vc/include/ -I/home/cross/firmware-rpi/firmware/hardfp/opt/vc/include/freetype/

fbi: $(OBJS_FBI) $(OBJS_READER) $(PNG_OBJS) $(TIFF_OBJS) $(GIF_OBJS)


########################################################################
# general rules

build: check-libjpeg $(TARGETS)

check-libjpeg:
	@test -d jpeg/80 || \
		( echo "Need files from libjpeg 80 in jpeg/"; false)

install: build

clean:
	-rm -f *.o jpeg/80/*.o rd/*.o wr/*.o $(depfiles) fbi exiftran thumbnail.cgi

include $(srcdir)/mk/Compile.mk
-include $(depfiles)
