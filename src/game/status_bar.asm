
STATUS_REDRAW_SCORE = $01
STATUS_REDRAW_MEN = $02
STATUS_REDRAW_HI = $04
STATUS_REDRAW_ALL = $07



	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	.section zp_vars_game

status_redraw_flags	.byte ?
	
	.send




	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
draw_status_bar
	
	;;;;;;;;;;;;;;;;;;;;;;;; update palette
	
	lda #C64_COLORS[1] ;torch time bar
	sta palette_bg_1+1
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;; write to nametable
	
	lda #<status_list
	ldx #>status_list
	jsr upload_ppu_list
	
	lda #>$203d
	sta $2006
	lda #<$203d
	sta $2006
	lda level
	clc
	adc #'1'
	sta $2007
	
	lda #>$207b
	sta $2006
	lda #<$207b
	sta $2006
	lda maze
	clc
	adc #'1'
	sta $2007
	
	lda #>$206b
	ldy #<$206b
	ldx #treasures
	jsr draw_number_bitfield
	
	lda #>$208b
	ldy #<$208b
	ldx #keys
	jsr draw_number_bitfield
	
	lda #>$23c0  ;torch time attribs
	sta $2006
	lda #<$23c0
	sta $2006
	ldx #8
	lda #$50
-	sta $2007
	dex
	bne -
	
	lda #>$204c  ;torch time bar
	sta $2006
	lda #<$204c
	sta $2006
	lda #7
-	tax
	sec
	sbc torch_time
	bcc _torch_time_full
	cmp #8
	bcc +
	lda #7
+	eor #7
	ora #$d0
	gmi _write_torch_time
_torch_time_full
	lda #$cf
_write_torch_time
	sta $2007
	txa
	clc
	adc #8
	cmp #TORCH_INITIAL_TIME + 7
	bcc -
	
	lda #STATUS_REDRAW_ALL
	sta status_redraw_flags
	
	rts




	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
draw_number_bitfield
	sta $2006
	sty $2006
	ldy #'1'
	gne _load_first
-	
	tya
	and #7
	.if '1' & 7
		cmp #'1' & 7
	.endif
	bne +
	inx
_load_first
	lda 0,x
	sta temp_sub
+	
	lsr temp_sub
	lda #' '
	bcc +
	tya
+	sta $2007
	
	iny
	cpy #'9'+1
	bcc -
	
	rts





	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
render_status_bar
	
	;;;; score
	
	lsr status_redraw_flags
	bcc _no_score
	
	lda score+0
	ldx score+1
	ldy score+2
	jsr hex_to_bcd_24
	
	lda #>$2028
	ldx #<$2028
	jsr queue_render_bcd_24
	
_no_score
	
	;;;; men
	
	lsr status_redraw_flags
	bcc _no_men
	
	lda #>$2034
	ldx #<$2034
	ldy men
	jsr queue_render_single_number
	
_no_men
	
	;;;; hi
	
	lsr status_redraw_flags
	bcc _no_hi
	
	lda hiscore+0
	ldx hiscore+1
	ldy hiscore+2
	jsr hex_to_bcd_24
	
	lda #>$2099
	ldx #<$2099
	jsr queue_render_bcd_24
	
_no_hi
	
	rts
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
move_status_bar_sprites_bottom
	.for i = 4, i < $20, i=i+4
		sta OAM + i
	.next
	rts
	
move_status_bar_sprites_top
	.for i = $20, i < $40, i=i+4
		sta OAM + i
	.next
	rts
	
	
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	; value in YA
award_points
	clc
	adc score+0
	sta score+0
	tya
	adc score+1
	sta score+1
	bcc +
	inc score+2
+	
	
	lda demo_mode
	bpl _update_hiscore
	
_no_update_hiscore
	lda #STATUS_REDRAW_SCORE
	gne +
	
_update_hiscore
	lda score+0
	cmp hiscore+0
	lda score+1
	sbc hiscore+1
	lda score+2
	sbc hiscore+2
	
	lda #STATUS_REDRAW_SCORE
	bcc +
	lda score+0
	sta hiscore+0
	lda score+1
	sta hiscore+1
	lda score+2
	sta hiscore+2
	lda #STATUS_REDRAW_SCORE | STATUS_REDRAW_HI
+	ora status_redraw_flags
	sta status_redraw_flags
	rts
	

	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
status_list
	#ppu_string $2022, "SCORE"
	#ppu_string $2030, "MEN="
	#ppu_string $2037, "LEVEL="
	#ppu_string $2041, "TORCH TIME"
	#ppu_string $2061, "TREASURES"
	#ppu_string $2076, "ROOM"
	#ppu_string $2086, "KEYS"
	#ppu_string $2096, "HI"
	.byte $ff

