	
	
	
	
	#define_mode TITLE, mode_title.init
	#define_mode TITLE_MAIN, mode_title.main
	
	
	
	
mode_title	.block
	

	.virtual zp_vars_global_end
demo_timer	.byte ?
	.endv
	
	
	
init
	jsr init_text_screen
	
	lda #<text_list
	ldx #>text_list
	jsr upload_ppu_list
	
	lda #$300 / 8
	sta demo_timer
	
	lda #SONG_STOP
	sta music_init_flag
	
	inc mode
	rts
	
	
main
	
	lda #$0a
	sta ppumask
	
	
	lda joy
	and #$10
	eor #$10
	beq _set_demo
	
	lda nmi_cnt
	and #$07
	bne +
	dec demo_timer
	bne +
	lda #$80
_set_demo
	sta mode_game.demo_mode
	lda #MODE_GAME
	sta mode_init_flag
+	
	
	
	
	
	rts
	
	
	
	
text_list
	#ppu_centered_string $2100, "WELCOME TO"
	#ppu_centered_string $2140, "CRYSTALS OF ZONG"
	#ppu_centered_string $2180, "BY SEAN MCKINNON"
	#ppu_centered_string $21C0, "© 1983 CYMBAL SOFTWARE INC."
	#ppu_centered_string $2200, "NOW ENTERING LEVEL 1"
	#ppu_centered_string $2240, "CAN YOU SUBDUE THE SNAKES ?"
	#ppu_centered_string $2280, "PRESS START TO BEGIN"
	.byte $ff
	
	
	
	.bend
	
	