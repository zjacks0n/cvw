CEXT		:= c
CPPEXT		:= cpp
AEXT		:= s
SEXT		:= S
SRCEXT 		:= \([$(CEXT)$(AEXT)$(SEXT)]\|$(CPPEXT)\)
#SRCS = $(wildcard *.S)
#PROGS = $(patsubst %.S,%,$(SRCS))
SRCDIR = .
SRCEXT = S
SOURCES		?= $(shell find $(SRCDIR) -type f -regex ".*\.$(SRCEXT)" | sort)
OBJEXT = elf
OBJECTS		:= $(SOURCES:.$(SEXT)=.$(OBJEXT))

all: $(OBJECTS)

%.elf.objdump: %.elf

%.elf: $(SRCDIR)/%.$(SEXT) WALLY-init-lib.h Makefile
	echo $@
	riscv64-unknown-elf-gcc -g -o $@ -march=rv64gc -mabi=lp64 -mcmodel=medany \
	    -nostartfiles -T../../examples/link/link.ld $<
	riscv64-unknown-elf-objdump -D $@ > $@.objdump
	riscv64-unknown-elf-elf2hex --bit-width $(if $(findstring rv64,$*),64,32) --input $@ --output $@.memfile
	extractFunctionRadix.sh $@.objdump
    
sim: %.elf
	spike +signature=%.signature.output +signature-granularity=8 %.elf
	diff --ignore-case %.signature.output %.reference_output || exit
	echo "Signature matches! Success!"

clean:
	rm -f *.elf *.objdump *.signature.output



