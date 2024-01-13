

DEFAULT_PPUCTRL = $b0

	;; approximate equivalents to c64 colors (colodore palette)
C64_COLORS = [$0f,$30,$16,$2c,$14,$2a,$11,$38, $17,$07,$26,$00,$10,$3a,$31,$10]



	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; nmi tasks


nmi_task_set_addr = * - 1
	pla
	sta $2006
	pla
	sta $2006
	rts
	

	.rept $20
		pla
		sta $2007
	.next
nmi_task_fastcopy = * - 1
	rts

nmi_task_fastcopy_bytes .function bytes
	.endf nmi_task_fastcopy - (bytes * 4)
	
	
nmi_task_repcopy_2 = * - 1
	pla
	.rept 2
		sta $2007
	.next
	rts




	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; nmi task helpers
	
	
	
	; ppu addr in AX
queue_ppu_addr
	ldy nmi_task_buf_index
_no_reload
	sta NMI_TASK_BUF + 2,y
	txa
	sta NMI_TASK_BUF + 3,y
	lda #<nmi_task_set_addr
	sta NMI_TASK_BUF + 0,y
	lda #>nmi_task_set_addr
	sta NMI_TASK_BUF + 1,y
	.rept 4
		iny
	.next
	rts
	
	
	
	; amount of bytes in A
queue_fastcopy_bytes
	asl
	asl
	eor #$ff
	sec
	adc #<nmi_task_fastcopy
	sta NMI_TASK_BUF,y
	iny
	lda #$ff
	adc #>nmi_task_fastcopy
	sta NMI_TASK_BUF,y
	iny
	rts
	
	
	
	; tile id in Y
	; ppu addr in AX
queue_render_single_tile
	sty temp_sub
	jsr queue_ppu_addr
	lda #<nmi_task_fastcopy_bytes(1)
	sta NMI_TASK_BUF,y
	iny
	lda #>nmi_task_fastcopy_bytes(1)
	sta NMI_TASK_BUF,y
	iny
	lda temp_sub
	sta NMI_TASK_BUF,y
	iny
	sty nmi_task_buf_index
	rts
	
	
	
	; number in Y
	; ppu addr in AX
queue_render_single_number
	sty temp_sub
	jsr queue_ppu_addr
	lda #<nmi_task_fastcopy_bytes(1)
	sta NMI_TASK_BUF,y
	iny
	lda #>nmi_task_fastcopy_bytes(1)
	sta NMI_TASK_BUF,y
	iny
	lda temp_sub
	clc
	adc #'0'
	sta NMI_TASK_BUF,y
	iny
	sty nmi_task_buf_index
	rts
	
	
	
	; 6-byte bcd value in temp_sub
	; ppu addr in AX
queue_render_bcd_24
	jsr queue_ppu_addr
	lda #<nmi_task_fastcopy_bytes(6)
	sta NMI_TASK_BUF,y
	iny
	lda #>nmi_task_fastcopy_bytes(6)
	sta NMI_TASK_BUF,y
	iny
	ldx #0
	clc
-	lda temp_sub,x
	adc #'0'
	sta NMI_TASK_BUF,y
	iny
	inx
	cpx #6
	bcc -
	sty nmi_task_buf_index
	rts



	; tile id in Y
	; ppu addr in AX
queue_repcopy_2
	sty temp_sub
	jsr queue_ppu_addr
	lda #<nmi_task_repcopy_2
	sta NMI_TASK_BUF,y
	iny
	lda #>nmi_task_repcopy_2
	sta NMI_TASK_BUF,y
	iny
	lda temp_sub
	sta NMI_TASK_BUF,y
	iny
	sty nmi_task_buf_index
	rts






	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


fill_both_nametables
	ldy #$20
	jsr fill_nametable
	ldy #$2c

	;tile value in A
	;attrib value in X
	;ptr hibyte in Y
fill_nametable
	sty $2006
	ldy #0
	sty $2006
-	sta $2007
	sta $2007
	sta $2007
	iny
	bne -
-	sta $2007
	iny
	cpy #$c0
	bcc -
-	stx $2007
	iny
	bne -
-	rts
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ppu lists
	
pascal_string	.macro
		.byte len(\1)
		.text \1
	.endm
	
ppu_string	.macro
		.byte >\1
		.byte <\1
		#pascal_string \2
	.endm
	
ppu_centered_string	.macro
		.byte >(\1 + (($20 - len(\2)) / 2))
		.byte <(\1 + (($20 - len(\2)) / 2))
		#pascal_string \2
	.endm
	
	
upload_ppu_list
	sta temp_sub+0
	stx temp_sub+1
	
_loop
	ldy #0
	lda (temp_sub),y
	bmi -
	sta $2006
	iny
	lda (temp_sub),y
	sta $2006
	iny
	lax (temp_sub),y
_byte
	iny
	lda (temp_sub),y
	sta $2007
	dex
	bne _byte
	tya
	sec
	adc temp_sub+0
	sta temp_sub+0
	bcc _loop
	inc temp_sub+1
	gcs _loop
	
	
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	
	;;; used by title/level complete screen
	
init_text_screen
	lda #C64_COLORS[0]
	sta palette_bg
	
	ldx #size(palette_all) - 1
	lda #C64_COLORS[5]
-	sta palette_all,x
	dex
	bpl -
	
	lda #' '
	ldx #0
	geq fill_both_nametables
	
	
	
	
	
	
	
	