
	;; maze dimensions, including 1 tile of border w/ entrances
MAZE_WIDTH = 40
MAZE_HEIGHT = 22

	;; bytes needed to store a maze
	;; mazes are stored column by column, left to right
MAZE_WIDTH_BITS = 40
MAZE_HEIGHT_BITS = 24
MAZE_COLUMN_BYTE_SIZE = (MAZE_HEIGHT_BITS / 8)
MAZE_BYTE_SIZE = MAZE_COLUMN_BYTE_SIZE * MAZE_WIDTH_BITS

	;; maze padding tiles
MAZE_X_PADDING = 1
MAZE_Y_PADDING = 1

MAZE_X_PIXEL_PADDING = MAZE_X_PADDING * 8
MAZE_Y_PIXEL_PADDING = MAZE_Y_PADDING * 8

	;; full maze dimensions including padding
MAZE_FULL_WIDTH = MAZE_WIDTH + (MAZE_X_PADDING * 2)
MAZE_FULL_HEIGHT = MAZE_HEIGHT + (MAZE_Y_PADDING * 2)

MAZE_FULL_PIXEL_WIDTH = MAZE_FULL_WIDTH * 8
MAZE_FULL_PIXEL_HEIGHT = MAZE_FULL_HEIGHT * 8
MAZE_MAX_X_SCROLL = MAZE_FULL_PIXEL_WIDTH - $100
	
SPRITE_Y_BASE = $2f

	;; number of mazes/rooms
AMT_MAZES = 9


	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	.section zp_vars_game
	
maze	.byte ?
maze_ptr	.word ?

maze_x_scroll	.byte ?
	
	.send


	.section vars_game
	
maze_data	.fill MAZE_BYTE_SIZE * AMT_MAZES

	.send



	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
set_maze_ptr
	stx maze
	lda maze_tbl_lo,x
	sta maze_ptr+0
	lda maze_tbl_hi,x
	sta maze_ptr+1
	rts





	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; set up maze data in ram
	
init_maze	.block

	;;;;;;;;;;;;;;;;;;;;; left border
	
	ldy #0
	lda #$ff
-	sta (maze_ptr),y
	iny
	cpy #MAZE_COLUMN_BYTE_SIZE
	bcc -
	
	;;;;;;;;;;;;;;;;;;;;; upper border/empty area/lower border
	
-	lda #1
	sta (maze_ptr),y
	.for i = 0, i < MAZE_COLUMN_BYTE_SIZE-1, i=i+1
		iny
		.if i < MAZE_COLUMN_BYTE_SIZE-2
			lda #0
			sta (maze_ptr),y
		.endif
	.next
	lda #($ff << ((MAZE_HEIGHT - 1) & 7)) & $ff
	sta (maze_ptr),y
	iny
	cpy #MAZE_BYTE_SIZE - MAZE_COLUMN_BYTE_SIZE
	bcc -
	
	;;;;;;;;;;;;;;;;;;;;; right border
	
	lda #$ff
-	sta (maze_ptr),y
	iny
	cpy #MAZE_BYTE_SIZE
	bcc -
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; generate maze
	
gen	.block
	
	.virtual temp_sub
gen_index	.byte ?
	
row	.byte ?
column	.byte ?

rand_and	.byte ?
rand_val	.byte ?
	.endv
	
	ldx #size(maze_gen_column) - 1
_gen_loop
	stx gen_index
	
	;;;;;;;;;;;;;;; set wall on top and bottom
	
	ldy maze_gen_column,x
	lda maze_gen_row,x
	tax
	stx row
	sty column
	jsr set_maze_bit
	
	lda #MAZE_HEIGHT
	clc
	sbc row
	tax
	ldy column
	jsr set_maze_bit
	
	;;;;;;;;;;;;;;; get random wall info
	
	ldx gen_index
	lda maze_gen_random,x
	beq _no_random
	tay
	dey
	tya
	sta rand_and
	
	;;;;;;;;;;;;;;; do top random walls
	
	jsr rand
	and rand_and
	cmp #1
	lda maze_gen_0,x
	bcc +
	lda maze_gen_1,x
+	sta rand_val
	
	jsr add_random_wall
	
	;;;;;;;;;;;;;;; do bottom random walls
	
	lda #MAZE_HEIGHT
	clc
	sbc row
	sta row
	
	jsr rand
	and rand_and
	cmp #1
	ldx gen_index
	ldy maze_gen_0,x
	bcc +
	ldy maze_gen_1,x
+	lda maze_gen_bottom_rand_tbl,y
	sta rand_val
	
	jsr add_random_wall
	
_no_random
	
	ldx gen_index
	dex
	bpl _gen_loop
	
	.bend
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; extra walls surrounding treasure
	
	ldy #MAZE_COLUMN_BYTE_SIZE * ((MAZE_WIDTH / 2) - 1) + ((MAZE_HEIGHT / 2) - 2) / 8
	lda #$12
	ora (maze_ptr),y
	sta (maze_ptr),y
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; mirror maze horizontally
	
	.block
	
	.virtual temp_sub
index_left	.byte ?
index_right	.byte ?
	.endv
	
	ldy #MAZE_COLUMN_BYTE_SIZE
	sty index_left
	ldy #MAZE_BYTE_SIZE - MAZE_COLUMN_BYTE_SIZE
_mirror_loop
	sty index_right
	
	ldy index_left
	.for i = 0, i < MAZE_COLUMN_BYTE_SIZE, i=i+1
		lda (maze_ptr),y
		.if i < MAZE_COLUMN_BYTE_SIZE-1
			pha
		.endif
		iny
	.next
	sty index_left
	
	ldy index_right
	.for i = MAZE_COLUMN_BYTE_SIZE - 1, i >= 0, i=i-1
		dey
		.if i < MAZE_COLUMN_BYTE_SIZE-1
			pla
		.endif
		sta (maze_ptr),y
	.next
	
	cpy #MAZE_COLUMN_BYTE_SIZE * (MAZE_WIDTH / 2)
	bne _mirror_loop
	
	.bend
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; entrances
	
	ldx maze
	lda maze_gen_room_entrances_tbl,x
	lsr
	sta temp_sub
	bcc _no_up
	ldy #MAZE_COLUMN_BYTE_SIZE * ((MAZE_WIDTH / 2) - 1)
	lda #$fe
	and (maze_ptr),y
	sta (maze_ptr),y
	.rept MAZE_COLUMN_BYTE_SIZE
		iny
	.next
	lda #$fe
	and (maze_ptr),y
	sta (maze_ptr),y
_no_up
	
	lsr temp_sub
	bcc _no_down
	ldy #MAZE_COLUMN_BYTE_SIZE * ((MAZE_WIDTH / 2) - 1) + (MAZE_COLUMN_BYTE_SIZE - 1)
	lda #$1f
	and (maze_ptr),y
	sta (maze_ptr),y
	.rept MAZE_COLUMN_BYTE_SIZE
		iny
	.next
	lda #$1f
	and (maze_ptr),y
	sta (maze_ptr),y
_no_down
	
	lsr temp_sub
	bcc _no_left
	ldy #((MAZE_HEIGHT / 2) - 1) / 8
	lda #$f3
	and (maze_ptr),y
	sta (maze_ptr),y
_no_left
	
	lsr temp_sub
	bcc _no_right
	ldy #MAZE_COLUMN_BYTE_SIZE * (MAZE_WIDTH - 1) + ((MAZE_HEIGHT / 2) - 1) / 8
	lda #$f3
	and (maze_ptr),y
	sta (maze_ptr),y
_no_right
	
	
	
	rts
	


add_random_wall
	ldx gen.rand_val
	lda gen.column
	clc
	adc maze_gen_random_wall_0_column_tbl,x
	tay
	lda gen.row
	clc
	adc maze_gen_random_wall_0_row_tbl,x
	tax
	jsr set_maze_bit
	
	ldx gen.rand_val
	lda gen.column
	clc
	adc maze_gen_random_wall_1_column_tbl,x
	tay
	lda gen.row
	clc
	adc maze_gen_random_wall_1_row_tbl,x
	tax
	jmp set_maze_bit



	.bend





	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; draw maze on nametable
	
draw_maze
	
	;;;;;;;;;;;;;;;;;;;;;;;;;; set up palette
	
	ldx maze
	lda maze_color_tbl,x
	sta palette_bg_0+2
	sta palette_bg_1+2
	sta palette_bg_2+2
	sta palette_bg_3+2
	
	lda #MAZE_WALL_COLOR_1
	sta palette_bg_0+0
	lda #MAZE_WALL_COLOR_2
	sta palette_bg_0+1
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;; write maze to nametable
	
	lda ppuctrl  ;vertical writing
	ora #4
	sta $2000
	
	ldy #0
_column_loop
	sty temp_sub  ;column index
	
	;; set ppu addr
	cpy #32
	lda #>$23c0 - (MAZE_FULL_HEIGHT * 32) - $20
	bcc +
	ora #$0c
+	sta $2006

	tya
	and #31
	ora #<$23c0 - (MAZE_FULL_HEIGHT * 32) - $20
	sta $2006
	
	tya
	sec
	sbc #MAZE_X_PADDING
	bcc +
	cmp #MAZE_WIDTH
	bcc ++
	lda #MAZE_WIDTH-1
	gne ++
+	lda #0
+	sta temp_sub+2
	tay
	
	;; draw tiles
	ldx #0  ;row index
_row_loop
	stx temp_sub+1
	txa
	sec
	sbc #MAZE_Y_PADDING
	bcc +
	cmp #MAZE_HEIGHT
	bcc ++
	lda #MAZE_HEIGHT-1
	gne ++
+	lda #0
+	tax
	
	jsr get_maze_bit
	ldy temp_sub+2
	ldx temp_sub+1
	cmp #1
	lda #$a0
	bcc +
	lda #$ce
+	sta $2007
	inx
	cpx #MAZE_FULL_HEIGHT
	bcc _row_loop
	
	ldy temp_sub
	iny
	cpy #MAZE_FULL_WIDTH
	bcc _column_loop
	
	lda ppuctrl
	sta $2000
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	lda #MAZE_MAX_X_SCROLL / 2
	sta maze_x_scroll
	
	rts




	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; maze access
	
	;;; X = row, Y = column
	
get_maze_byte	.proc
	lda maze_column_index_tbl,y
	clc
	adc maze_row_index_tbl,x
	tay
	lda (maze_ptr),y
	rts
	.pend
	
	
get_maze_bit	.proc
	jsr get_maze_byte
	and maze_row_mask_tbl,x
	rts
	.pend
	
	
set_maze_bit	.proc
	jsr get_maze_byte
	ora maze_row_mask_tbl,x
	sta (maze_ptr),y
	rts
	.pend
	
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	;; check if a mob is allowed to move in a direction
	;; row in A, column in Y, direction in X
	;; returns Z=1 if not allowed, Z=0 if allowed
	
check_direction_allowed	.block
	
	.virtual temp_sub
row	.byte ?
column	.byte ?

direction	.byte ?
	.endv
	
	stx direction
	
	sta row
	clc
	adc maze_collision_row_add_tbl,x
	bmi _row_clamp_low
	cmp #MAZE_HEIGHT
	bcc _row_set
	lda #MAZE_HEIGHT-1
	gne _row_set
_row_clamp_low
	lda #0
_row_set
	sta row
	
	tya
	sta column
	clc
	adc maze_collision_column_add_tbl,x
	bmi _column_clamp_low
	cmp #MAZE_WIDTH
	bcc _column_set
	lda #MAZE_WIDTH-1
	gne _column_set
_column_clamp_low
	lda #0
_column_set
	sta column
	tay
	
	ldx row
	;ldy column
	jsr get_maze_bit
	bne _exit  ;we already know it is not allowed
	
	ldx row
	ldy column
	lda direction
	and #2
	beq _checking_row
_checking_column ;going left/right, checking a column
	inx
	gpl _check_next
_checking_row ;going up/down, checking a row
	iny
_check_next
	jmp get_maze_bit
	
_exit
	rts
	
.bend
	
	
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;;;;;;; convert between pixel/maze positions
	
	
	;; convert pixel-position (YA,X) to maze position row A column Y
	
get_maze_position
	sty temp_sub
	.rept 3
		lsr temp_sub
		ror
	.next
	tay
	txa
	lsr
	lsr
	lsr
	cmp #MAZE_HEIGHT + 4
	bcc +
	ora #$e0
+	rts
	
	
	
	;; convert maze position row A column Y to pixel-position (YA,X)
	
get_pixel_position
	asl
	asl
	asl
	tax
	tya
	ldy #0
	asl
	asl
	asl
	bcc +
	iny
+	rts
	
	
	
	
	
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	;; for items/monsters
	;; returns row in A and column in Y
	
get_random_maze_position	.block
	
	.virtual temp_sub
column	.byte ?	
	.endv
	
	jsr rand
	and #7
	tay
	lda maze_random_column_tbl,y
	sta column
	
	jsr rand
	and #3
	tay
	lda maze_random_row_tbl,y
	
	ldy column
	rts
	
	.bend
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
set_maze_x_scroll_around_player
	lda angel_state
	bne _ignore
	
	lda player_x+0
	ldx player_x+1
	sec
	sbc #$80 - 8
	bcs +
	dex
+	cpx #$80
	bcs _too_far_left
	cpx #1
	bcs _too_far_right
	cmp #MAZE_MAX_X_SCROLL + 1
	bcc +
_too_far_right
	lda #MAZE_MAX_X_SCROLL
+	sta maze_x_scroll
	rts
	
_too_far_left
	lda #0
	sta maze_x_scroll
	
_ignore
	rts
	
	
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	;; add sprite(s) to the OAM relative to maze scroll
	;;	x-pos in YA, y-pos in X, image in temp_sub, flags in temp_sub+1
	
	
add_maze_sprite	.block
	
	.virtual temp_sub
image	.byte ?
flags	.byte ?

x	.word ?

oam_x	.byte ?
	.endv
	
	sta x+0
	sty x+1
no_reload
	
	sec
	sbc maze_x_scroll
	bcs +
	dey
+	cpy #1
	bcs _no_sprite
	sta oam_x
	
	ldy oam_index
	txa
	;clc
	adc #SPRITE_Y_BASE
	sta OAM+0,y
	lda image
	sta OAM+1,y
	lda flags
	sta OAM+2,y
	lda oam_x
	sta OAM+3,y
	
	iny
	iny
	iny
	iny
	bne +
	ldy #INITIAL_OAM_INDEX
+	sty oam_index
	
_no_sprite
	rts
	
	.bend
	
	
	
	
add_double_maze_sprite
	
	jsr add_maze_sprite
	inc add_maze_sprite.image
	inc add_maze_sprite.image
_next
	lda add_maze_sprite.x+0
	ldy add_maze_sprite.x+1
	clc
	adc #8
	bcc +
	iny
+	jmp add_maze_sprite
	
	
	
	
add_x_flipped_double_maze_sprite
	
	jsr add_maze_sprite
	dec add_maze_sprite.image
	dec add_maze_sprite.image
	jmp add_double_maze_sprite._next
	
	
	
	
	
	
	
	
	


	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; pointers to each maze
	
maze_tbl_lo	.for i = 0, i < AMT_MAZES, i=i+1
		.byte <maze_data + MAZE_BYTE_SIZE*i
	.next
	
maze_tbl_hi	.for i = 0, i < AMT_MAZES, i=i+1
		.byte >maze_data + MAZE_BYTE_SIZE*i
	.next



	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; maze row/column index tables
	
maze_column_index_tbl
	.for i = 0, i < MAZE_WIDTH, i=i+1
		.byte MAZE_COLUMN_BYTE_SIZE * i
	.next


maze_row_index_tbl
	.for i = 0, i < MAZE_HEIGHT, i=i+1
		.byte i / 8
	.next


maze_row_mask_tbl
	.for i = 0, i < MAZE_HEIGHT, i=i+1
		.byte 1 << (i & 7)
	.next



	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; data for collision check
	
maze_collision_column_add_tbl	.char [0,0,-1,2] - MAZE_X_PADDING
maze_collision_row_add_tbl	.char [-1,2,0,0] - MAZE_Y_PADDING





	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; data for maze exits
	
maze_move_x_tbl_lo	.byte $a0,$a0,$58,$e8
maze_move_x_tbl_hi	.byte $00,$00,$01,$ff

maze_move_y_tbl	.byte $c8,$e8,$58,$58

	;add padding tiles/1 tile border
maze_move_mod_3_tbl	.byte ($c8 - MAZE_Y_PIXEL_PADDING - 8) % 3, (-$18 - MAZE_Y_PIXEL_PADDING - 8) % 3, ($158 - MAZE_X_PIXEL_PADDING - 8) % 3, (-$18 - MAZE_X_PIXEL_PADDING - 8) % 3
	
maze_move_add_tbl	.char -3,3,-1,1




	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; data for item positions
	
maze_random_row_tbl	.byte [1,2,4,5] * 3 + 1 + MAZE_Y_PADDING
maze_random_column_tbl	.byte [1,2,3,4,8,9,$0a,$0b] * 3 + 1 + MAZE_X_PADDING






	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; generation data
	
MAZE_GEN_DATA = binary("data/orig-maze-gen-data.prg",2)

maze_gen_column	.for i = len(MAZE_GEN_DATA) - 5, i >= 0, i=i-5
		.byte MAZE_GEN_DATA[i] + 2
	.next
maze_gen_row	.for i = len(MAZE_GEN_DATA) - 4, i >= 0, i=i-5
		.byte MAZE_GEN_DATA[i] + 1
	.next
maze_gen_random	.for i = len(MAZE_GEN_DATA) - 3, i >= 0, i=i-5
		.byte MAZE_GEN_DATA[i]
	.next
maze_gen_0	.for i = len(MAZE_GEN_DATA) - 2, i >= 0, i=i-5
		.byte MAZE_GEN_DATA[i]
	.next
maze_gen_1	.for i = len(MAZE_GEN_DATA) - 1, i >= 0, i=i-5
		.byte MAZE_GEN_DATA[i]
	.next


	;; original tables:
	;;	$11c1: 02 54 a2 50
	;;	$11c5: 2a 53 7a 51
	;; the index to the tile itself is 52!
	
maze_gen_random_wall_0_column_tbl	.char 0,2,0,-2
maze_gen_random_wall_0_row_tbl	.char -2,0,2,0
	
maze_gen_random_wall_1_column_tbl	.char 0,1,0,-1
maze_gen_random_wall_1_row_tbl	.char -1,0,1,0



maze_gen_bottom_rand_tbl	.byte 2,1,0,3



maze_gen_room_entrances_tbl	.byte $0a,$0e,$06,$0b,$0f,$07,$09,$0d,$05



	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; colors
	
maze_color_tbl
	.byte C64_COLORS[$04]
	.byte C64_COLORS[$02]
	.byte C64_COLORS[$06]
	.byte C64_COLORS[$0e]
	.byte C64_COLORS[$05]
	.byte C64_COLORS[$0f]
	.byte C64_COLORS[$07]
	.byte C64_COLORS[$08]
	.byte C64_COLORS[$03]


MAZE_WALL_COLOR_1 = C64_COLORS[7]
MAZE_WALL_COLOR_2 = C64_COLORS[2]




