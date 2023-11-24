# name of project and final file
TARGET=mvbc_master

# environment
CC=arm-none-eabi-gcc
OBJCOPY=arm-none-eabi-objcopy
# AS=arm-none-eabi-as
# LD=arm-none-eabi-ld
RM=rm -f

#cortex-m4
CORE=4
CPUFLAGS=-mthumb -mcpu=cortex-m$(CORE)

# current working directory
PWD=$(shell pwd)

#openocd interface & target, depend debugger and MCU
INTERFACE_CFG=/usr/local/share/openocd/scripts/interface/stlink-v2-1.cfg
TARGET_CFG=/usr/local/share/openocd/scripts/target/stm32f4x.cfg

# include path
INCFLAGS=-I $(PWD)/CMSIS \
		-I $(PWD)/STM32F4xx_StdPeriph_Driver/inc \
		-I $(PWD)/User \
		-I $(PWD)/mvbcDriver \
		-I $(PWD)/Hardware/exti \
		-I $(PWD)/Hardware/fsmc \
		-I $(PWD)/Hardware/gpio \
		-I $(PWD)/Hardware/uart

# .ld file should depend of MCU
LDFLAGS = -T STM32F417IG_FLASH.ld --specs=nosys.specs -Wl,-cref,-u,Reset_Handler -Wl,-Map=$(TARGET).map -Wl,--gc-sections -Wl,--defsym=malloc_getpagesize_P=0x80 -Wl,--start-group -lc -lm -Wl,--end-group

CFLAGS=$(INCFLAGS) -D STM32F40_41xxx -D USE_STDPERIPH_DRIVER -Wall -g

STARTUP_SRC=$(shell find ./ -name 'startup_stm32f40_41xxx.s')
STARTUP_OBJ=$(STARTUP_SRC:%.s=%.o)

C_SRC=$(shell find ./ -name '*.c')
C_OBJ=$(C_SRC:%.c=%.o)

$(TARGET):$(STARTUP_OBJ) $(C_OBJ)
	$(CC) $^ $(CPUFLAGS) $(LDFLAGS) $(CFLAGS) -o $(TARGET).elf
	$(OBJCOPY) $(TARGET).elf $(TARGET).bin
	$(OBJCOPY) $(TARGET).elf -Oihex $(TARGET).hex
	
$(STARTUP_OBJ):$(STARTUP_SRC)
	$(CC) -c $^ $(CPUFLAGS) $(CFLAGS) -o $@
$(C_OBJ):%.o:%.c
	$(CC) -c $^ $(CPUFLAGS) $(CFLAGS) -o $@

clean:
	$(RM) $(shell find ./ -name '*.o') $(TARGET).*
	
download:
	openocd -f $(INTERFACE_CFG) -f $(TARGET_CFG) -c init -c halt -c "flash write_image erase $(PWD)/$(TARGET).bin" -c reset -c shutdown
	
