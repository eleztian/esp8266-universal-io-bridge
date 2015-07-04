SDKROOT			= /nfs/src/esp/opensdk
SDKLD			= $(SDKROOT)/sdk/ld

CFLAGS			= -Os -Wall -Wno-pointer-sign -nostdlib -mlongcalls -mtext-section-literals  -D__ets__ -DICACHE_FLASH
CINC			= -I$(SDKROOT)/lx106-hal/include -I$(SDKROOT)/xtensa-lx106-elf/xtensa-lx106-elf/include \
					-I$(SDKROOT)/xtensa-lx106-elf/xtensa-lx106-elf/sysroot/usr/include -I$(SDKROOT)/sdk/include -I.
LDFLAGS			= -nostdlib -Wl,--no-check-sections -u call_user_start -Wl,-static
LDSCRIPT		= -T$(SDKLD)/eagle.app.v6.ld
LDSDK			= -L$(SDKROOT)/sdk/lib
LDLIBS			= -lc -lgcc -lhal -lpp -lphy -lnet80211 -llwip -lwpa -lmain -lpwm

OBJS			= application.o config.o gpios.o i2c.o queue.o stats.o uart.o user_main.o util.o
HEADERS			= esp-uart-register.h \
				  application.h application-parameters.h config.h gpios.h i2c.h stats.h queue.h uart.h user_main.h user_config.h
FW				= fw.elf
FW1				= fw-0x00000.bin
FW2				= fw-0x40000.bin
ZIP				= espbasicbridge.zip 

V ?= $(VERBOSE)
ifeq ("$(V)","1")
	Q :=
	vecho := @true
else
	Q := @
	vecho := @echo
endif

.PHONY:	all reset flash zip

all:			$(FW1) $(FW2)

zip:			all
				$(Q) zip -9 $(ZIP) $(FW1) $(FW2) LICENSE README.md

flash:			all
				$(Q) espflash $(FW1) $(FW2)

clean:
				$(vecho) "CLEAN"
				$(Q) rm -f $(OBJS) $(FW) $(FW1) $(FW2) $(ZIP)

config.o:		$(HEADERS)
gpio.o:			$(HEADERS)
i2c.o:			$(HEADERS)
user_main.o:	$(HEADERS)

$(FW1):			$(FW)
				$(vecho) "FW1 $@"
				$(Q) esptool.py elf2image $(FW)
				$(Q) mv $(FW)-0x00000.bin $(FW1)
				$(Q) -mv $(FW)-0x40000.bin $(FW2)

$(FW2):			$(FW)
				$(vecho) "FW2 $@"
				$(Q) esptool.py elf2image $(FW)
				$(Q) -mv $(FW)-0x00000.bin $(FW1)
				$(Q) mv $(FW)-0x40000.bin $(FW2)

$(FW):			$(OBJS)
				$(vecho) "LD $@"
				$(Q) xtensa-lx106-elf-gcc $(LDSDK) $(LDSCRIPT) $(LDFLAGS) -Wl,--start-group $(LDLIBS) $(OBJS) -Wl,--end-group -o $@

%.o:			%.c
				$(vecho) "CC $<"
				$(Q) xtensa-lx106-elf-gcc $(CINC) $(CFLAGS) -c $< -o $@
