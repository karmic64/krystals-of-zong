
	.section zp_vars_global
	
nmi_recurse	.byte ?

nmi_cnt	.byte ?
	
nmi_task_buf_index	.byte ?
	
ppuctrl	.byte ?
ppumask	.byte ?
ppuscroll_x	.byte ?
ppuscroll_y	.byte ?

palette_bg	.byte ?
palette_all	.logical *
palette_bg_all	.logical *
palette_bg_0	.fill 3
palette_bg_1	.fill 3
palette_bg_2	.fill 3
palette_bg_3	.fill 3
	.here
palette_spr_all	.logical *
palette_spr_0	.fill 3
palette_spr_1	.fill 3
palette_spr_2	.fill 3
palette_spr_3	.fill 3
	.here
	.here
	
	
rawjoy	.byte ?
joy	.byte ?
	
mode_init_flag	.byte ?
mode	.byte ?
	
	.send
	
	
	
sub_nmi
	pha
	txa
	pha
	tya
	pha
	
	jsr music_play
	
	pla
	tay
	pla
	tax
	pla
	dec nmi_recurse
	rti
	
	
	
init_mode
	sta mode
	lda #DEFAULT_PPUCTRL
	sta mode_init_flag
	sta ppuctrl
	lda #0
	sta ppuscroll_x
	sta ppuscroll_y
	sta ppumask
	geq nmi._after_mode_init
	
	

nmi
	inc nmi_recurse
	bne sub_nmi
	
	lda mode_init_flag
	bpl init_mode
	
	ldx #$ff
	txs
	rts
	
_return_nmi_task = *-1
	
	lda ppumask
	and #$18
	beq _no_palette
	
	lda #$3f
	sta $2006
	lda #$00
	sta $2006
	
	ldx palette_bg
	
	.for i = 0, i < palette_all, i=i+1
		.if i % 3 == 0
			stx $2007
		.endif
		lda palette_all + i
		sta $2007
	.next
	
_no_palette
	
	lda ppumask
	and #$10
	beq +
	lda #>OAM
	sta $4014
+	
	
_after_mode_init
	lda ppuctrl
	sta $2000
	lda ppuscroll_x
	sta $2005
	lda ppuscroll_y
	sta $2005
	lda ppumask
	sta $2001
	
	ldx #$ff
	txs
	
	
	lda #0
	sta nmi_task_buf_index
	
	inc nmi_cnt
	
	
	jsr music_play
	
	jsr rand
	
	ldy rawjoy
	ldx #1
	stx $4016
	stx rawjoy
	dex
	stx $4016
-	lda $4016
	and #3
	cmp #1
	rol rawjoy
	bcc -
	tya
	eor #$ff
	and rawjoy
	sta joy
	
	
	jsr execute_mode
	
	
	ldx nmi_task_buf_index
	lda #<nmi._return_nmi_task
	sta NMI_TASK_BUF + 0,x
	lda #>nmi._return_nmi_task
	sta NMI_TASK_BUF + 1,x
	
	dec nmi_recurse
	jmp *
	
	
	
	
execute_mode
	ldx mode
	lda mode_tbl_lo,x
	sta temp+0
	lda mode_tbl_hi,x
	sta temp+1
jmp_temp
	jmp (temp)
	
mode_tbl_lo	.dsection mode_tbl_lo
mode_tbl_hi	.dsection mode_tbl_hi
	
	
	
	