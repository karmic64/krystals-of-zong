
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		
RAND_BYTES = 8
RAND_FEED = $af
	
	.section zp_vars_global
rand_val	.fill RAND_BYTES
	.send
	
	
rand
	lda rand_val
	lsr
	.for i = 1, i < RAND_BYTES, i=i+1
		ror rand_val + i
	.next
	bcc +
	eor #RAND_FEED
+	sta rand_val
	rts
	
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	;; divide 8bit A / X
	;; remainder in A, result in temp_sub
	
div_8_8
	
	.virtual temp_sub
dividend	.byte ?
divisor	.byte ?
	.endv
	
	sta dividend
	stx divisor
	
	ldy #8 ;bit count
	lda #0
	clc
_bit_loop
	rol
	cmp divisor
	bcc +
	sbc divisor
+	rol dividend
	dey
	bpl _bit_loop
	
	rts
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	;; convert 3-byte number to unpacked bcd
	;; result in temp_sub (highest digit first)
	
hex_to_bcd_24	.block
	
	.virtual temp_sub
result	.fill 6  ;will contain the remainder of all divisions
dividend	.fill 3	;the 24-bit number to divide by 10. once division finishes this is the quotient
	.endv
	
	sta dividend+0
	stx dividend+1
	sty dividend+2
	
	ldx #5 - 2	;digit counter
_digit_loop
	
	ldy #24	;bit counter
	lda #0
	clc
_bit_loop
	rol
	cmp #10
	bcc +
	sbc #10
+	rol dividend+0
	rol dividend+1
	rol dividend+2
	dey
	bpl _bit_loop  ;needs an extra bit to shift in the last quotient bit
	sta result + 2,x
	dex
	bpl _digit_loop
	
	;; convert the last byte with a table
	ldx dividend+0
	lda bcd_tbl,x
	lsr
	lsr
	lsr
	lsr
	sta result+0
	lda bcd_tbl,x
	and #$0f
	sta result+1
	
	rts
	
	.bend


bcd_tbl
	.for i = 0, i <= 99, i=i+1
		.byte ((i / 10) << 4) | (i % 10)
	.next
	
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	
bitfield_index_tbl
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$01
bitfield_mask_tbl
	.byte $01,$02,$04,$08,$10,$20,$40,$80,$01
	
	
	
	