	.cpu "6502i"
	
	
	.enc "ascii"
	.cdef " ~",$20
	
	
	.text "NES",$1a
	.byte $01,$00
	.byte 1
	
	
	.enc "gametext"
	.cdef "  ",$a1
	.cdef "09",$a2
	.cdef "AZ",$ac
	.cdef "az",$ac
	.cdef "..",$c6
	.cdef "==",$c7
	.cdef "??",$c8
	.cdef "©©",$cb
	
	
	
	
NMI_TASK_BUF = $100
OAM = $200
	
	.virtual 0
temp_sub	.fill 9
temp	.fill 3
	.dsection zp_vars_global
zp_vars_global_end
	.endv
	
	.virtual $0300
	.dsection vars_global
vars_global_end
	.endv
	
	
	
define_zp_vars	.segment
		.virtual zp_vars_global_end
			.dsection zp_vars_\1
			.cerror * > $f0, "zp_vars_@1 too long"
		.endv
	.endm
	
define_vars	.segment
		.virtual vars_global_end
			.dsection vars_\1
			.cerror * > $800, "vars_@1 too long"
		.endv
	.endm
	
	
	
	

	* = $10
	.logical $c000
	
chr_rom
	.binary "data/gfx.chr",0,$2000
	* = $d000
	.binary "gen/chr-secret.chr"
	
	* = $e000
	
	
	.include "music.asm"
	
	

	.include "reset.asm"
	.include "nmi.asm"
	.include "ppu.asm"
	.include "math.asm"
	
	
	
	
	
CURRENT_MODE := 0
define_mode	.segment
		MODE_\1 = CURRENT_MODE
		.section mode_tbl_lo
			.byte <\2
		.send
		.section mode_tbl_hi
			.byte >\2
		.send
		CURRENT_MODE += 1
	.endm


	.include "mode_title.asm"
	.include "mode_level_complete.asm"
	.include "mode_game.asm"
	
	
	
	
	
	.fill $fffa-*
	
	.word nmi,reset,reset
	.here
	
	
	