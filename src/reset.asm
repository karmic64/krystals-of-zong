


	.section zp_vars_global
reset_string	.fill size(reset_string_cmp)
	.send



reset
	lda #0
	sta $2000
	sta $2001
	sta $2003
	
	jsr music_reset
	
	ldx #RAND_BYTES - 1
-	txa
	eor rand_val,x
	beq +
	sta rand_val,x
+	dex
	bne -
	
	lda $2002
-	jsr rand
	lda $2002
	bpl -
	
	lda #0
	sta mode_init_flag
	lda #$ff
	sta nmi_recurse
	sta rawjoy
	
	ldx #size(reset_string_cmp)-1
-	lda reset_string_cmp,x
	cmp reset_string,x
	bne _needs_reset
	dex
	bpl -
	bmi _no_reset
	
-	lda reset_string_cmp,x
_needs_reset
	sta reset_string,x
	dex
	bpl -
	
	lda #0
	sta mode_game.hiscore+0
	sta mode_game.hiscore+1
	sta mode_game.hiscore+2
_no_reset

-	jsr rand
	lda $2002
	bpl -
	
	ldy #0
	sty $2006
	sty $2006
	sty temp_sub+0
	lda #>chr_rom
	sta temp_sub+1
	ldx #$20
-	lda (temp_sub),y
	sta $2007
	iny
	bne -
	inc temp_sub+1
	dex
	bne -
	
	lda $2002
	lda #DEFAULT_PPUCTRL
	sta ppuctrl
	sta $2000
	jmp *
	



	.enc "ascii"
reset_string_cmp	.text "S.M."
	.enc "gametext"
	
	
	