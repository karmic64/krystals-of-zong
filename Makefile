ifdef COMSPEC
DOTEXE:=.exe
else
DOTEXE:=
endif


#########################################

.PHONY: default
default: Krystals-of-Zong.nes


#########################################


CFLAGS:=-s -Ofast -Wall
CLIBS:=-lpng

TOOLS:=convert-music convert-chr-secret

gen/%.d: tool/%.c
	$(CC) -M -MF $@ -MP -MT tool/$*$(DOTEXE) $<

%$(DOTEXE): %.c
	$(CC) $(CFLAGS) -o $@ $< $(CLIBS)

-include $(addprefix gen/,$(addsuffix .d,$(TOOLS)))


#########################################

gen/music-data.asm: tool/convert-music$(DOTEXE) data/orig-music-data.prg
	$^ $@

gen/chr-secret.chr: tool/convert-chr-secret$(DOTEXE) data/chr-secret.png
	$^ $@

Krystals-of-Zong.nes gen/main.d: src/main.asm gen/music-data.asm gen/chr-secret.chr
	64tass -a -B -C -f --make-phony -M gen/main.d -I . -o Krystals-of-Zong.nes $<

-include gen/main.d

