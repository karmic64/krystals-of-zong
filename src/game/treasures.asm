
	.section zp_vars_game
	
	;;;;;;;;;;;; collection flags
	
treasures	.fill 2
keys	.fill 2
swords	.fill 2
	
	;;;;;;;;;;;; item locations
	
maze_treasures	.fill AMT_MAZES
maze_keys	.fill AMT_MAZES

maze_keys_row	.fill AMT_MAZES
maze_keys_column	.fill AMT_MAZES

maze_swords_row	.fill AMT_MAZES
maze_swords_column	.fill AMT_MAZES

torch_maze	.byte ?
torch_row	.byte ?
torch_column	.byte ?
	
	;;;;;;;;;;;;; item effects
	
torch_time_frac	.byte ?
torch_time	.byte ?

sword_time	.byte ?

treasure_effects	.byte ?
	
	.send
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	
	; also mummy fireball colors
TORCH_COLOR_1 = C64_COLORS[8]
TORCH_COLOR_2 = C64_COLORS[2]
TORCH_COLOR_3 = C64_COLORS[7]


TORCH_INITIAL_TIME = $98
TORCH_INTERVAL = $11

SWORD_INITIAL_TIME = $5a
SWORD_TREASURE_TIME = $ff
SWORD_THRESHOLD = $0f
	
	
TREASURE_EFFECT_INVINCIBLE = $01
TREASURE_EFFECT_LANTERN = $02
TREASURE_EFFECT_BOOTS = $04
TREASURE_EFFECT_TELEPORT = $08
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
init_treasures
	
	;;;;;;;;;;;;;;;;;; mark all as uncollected
	
	lda #0
	sta treasures+0
	sta treasures+1
	sta keys+0
	sta keys+1
	sta treasure_effects
	
	lda level  ;no swords on mummy levels
	and #3
	cmp #3
	lda #0
	bcc +
	lda #$ff
+	sta swords+0
	sta swords+1
	
	
	;;;;;;;;;;;;;;;;;; shuffle items scattered across rooms
	
	ldx #AMT_MAZES-1
-	txa
	sta maze_treasures,x
	sta maze_keys,x
	dex
	bpl -
	
	ldx #AMT_MAZES-1
-	jsr rand
	jsr div_8_8
	tay
	lda maze_treasures,x
	pha
	lda maze_treasures,y
	sta maze_treasures,x
	pla
	sta maze_treasures,y
	
	jsr rand
	jsr div_8_8
	tay
	lda maze_keys,x
	pha
	lda maze_keys,y
	sta maze_keys,x
	pla
	sta maze_keys,y
	
	dex
	bne -
	
	;;;;;;;;;;;;;;;;;;;;;;;;;; set positions
	
	ldx #AMT_MAZES-1
-	
	jsr get_random_maze_position
	sta maze_keys_row,x
	sty maze_keys_column,x
	
	jsr get_random_maze_position
	sta maze_swords_row,x
	sty maze_swords_column,x
	
	dex
	bpl -
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;; init treasure variables
	
	jsr init_torch
	
-	lda #0
	sta sword_time
	
	rts
	
	
	
	
	
init_treasures_maze
	
	lda treasure_effects
	and #~TREASURE_EFFECT_INVINCIBLE
	sta treasure_effects
	
	jmp -
	
	
	
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
collect_torch
	lda #SONG_LIGHT_MY_FIRE
	sta music_init_flag
	
	jsr queue_full_torch_time_bar
	
	lda #<50
	ldy #>50
	jsr award_points
	
	jsr rand ;don't respawn the torch on the same maze
	and #7
	cmp torch_maze
	bcc +
	adc #0
	gcc +
	
init_torch
	
	jsr rand
	ldx #AMT_MAZES
	jsr div_8_8
+	sta torch_maze
	
	jsr get_random_maze_position
	sta torch_row
	sty torch_column
	
	lda #TORCH_INTERVAL
	sta torch_time_frac
	lda #TORCH_INITIAL_TIME
	sta torch_time
	
	rts
	
	
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
set_torch_palette .from draw_treasures
	
draw_treasures	.block
	
	;;;;;;;;;;;;;;;; treasure area attributes
	
	lda #$23
	sta $2006
	lda #$e4
	sta $2006
	lda #$0a
	sta $2007
	sta $2007
	lda #$02
	sta $2007
	
	;;;;;;;;;;;;;;;; treasure
	
	jsr has_treasure
	bne _no_treasure
	
	ldy maze_treasures,x
	lda treasure_tile_tbl,y
	ldx #$22
	stx $2006
	ldx #$14
	stx $2006
	sta $2007
	eor #1
	sta $2007
	ldx #$22
	stx $2006
	ldx #$34
	stx $2006
	eor #3
	sta $2007
	eor #1
	sta $2007
	
	lda treasure_color_tbl,y
	sta palette_bg_2+0
	
_no_treasure
	
	;;;;;;;;;;;;;;;; keyholes
	
	lda ppuctrl
	ora #4
	sta $2000
	lda #$22
	ldx #$10
	jsr draw_keyhole
	ldx #$19
	jsr draw_keyhole
	lda ppuctrl
	sta $2000
	
	lda #C64_COLORS[1]
	sta palette_bg_2+1
	
	;;;;;;;;;;;;;;;;; key sprite palette
	
	ldx maze
	ldy maze_keys,x
	lda maze_color_tbl,y
	sta palette_spr_3+1
	
	;;;;;;;;;;;;;;;;; sword palette
	
	lda #C64_COLORS[1]
	sta palette_spr_3+2
	
	;;;;;;;;;;;;;;;;; torch palette
	
set_torch_palette
	lda #TORCH_COLOR_1
	sta palette_spr_1+0
	lda #TORCH_COLOR_2
	sta palette_spr_1+1
	lda #TORCH_COLOR_3
	sta palette_spr_1+2
	rts
	
	
	
	
draw_keyhole
	sta $2006
	stx $2006
	ldx #$cc
	stx $2007
	inx
	stx $2007
	rts
	
	
	.bend
	
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
handle_treasures
	
	;;;;;;;;;;;;;;;;;;;; flash keyhole
	
	jsr has_key_for_this_maze
	beq _no_keyhole_flash
	
	lda game_cnt
	and #7
	cmp #4
	and #3
	bne _no_keyhole_flash
	
	lda #C64_COLORS[1]
	bcc +
	lda #C64_COLORS[3]
+	sta palette_bg_2+1
	
_no_keyhole_flash
	
	
	
	;;;;;;;;;;;;;;;;;;;;
	
	lda angel_state
	bne _no_handle_treasures
	
	lda game_cnt
	and #3
	bne _no_handle_treasures
	
	
	;;;;;;;;;;;;;;;;;;;; torch
	
	lda torch_time
	beq _no_torch
	
	lda treasure_effects
	and #TREASURE_EFFECT_LANTERN
	bne _no_torch
	
	dec torch_time_frac
	bne _no_torch
	lda #TORCH_INTERVAL
	sta torch_time_frac
	
	dec torch_time
	lda torch_time
	and #7
	ora #$d0
	tay
	lda torch_time
	lsr
	lsr
	lsr
	clc
	adc #$4c
	tax
	lda #$20
	jsr queue_render_single_tile
	
_no_torch
	
	
	;;;;;;;;;;;;;;;;;;;;;; sword
	
	lda sword_time
	beq _no_sword
	
	dec sword_time
	
_no_sword
	
	
	
_no_handle_treasures
	
	rts
	
	
	
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
render_treasures
	
	;;;;;;;;;;;;;;;;;;;;;; key
	
	jsr has_key_in_this_maze
	bne _no_key
	
	lda #$ac
	sta temp_sub
	lda #$23
	sta temp_sub+1
	lda maze_keys_row,x
	ldy maze_keys_column,x
	jsr get_pixel_position
	jsr add_double_maze_sprite
	
_no_key
	
	;;;;;;;;;;;;;;;;;;;;;; sword
	
	jsr has_sword
	bne _no_sword
	
	lda #$f0
	sta temp_sub
	lda #$23
	sta temp_sub+1
	lda maze_swords_row,x
	ldy maze_swords_column,x
	jsr get_pixel_position
	jsr add_double_maze_sprite
	
_no_sword
	
	;;;;;;;;;;;;;;;;;;;;;; torch
	
	lda angel_state  ; because the angel uses the torch's palette
	bne _no_torch    ; the original game behaves the same way
	
	lda maze
	cmp torch_maze
	bne _no_torch
	
	lda game_cnt
	lsr
	lsr
	and #3
	tay
	lda torch_anim_tbl,y
	sta temp_sub
	lda #$21
	sta temp_sub+1
	lda torch_row
	ldy torch_column
	jsr get_pixel_position
	jsr add_double_maze_sprite
	
_no_torch
	
	
	
	
	
	
	rts
	
	
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	
	
	
	
queue_full_torch_time_bar
	ldy nmi_task_buf_index
	lda #<nmi_task_full_torch_time_bar
	sta NMI_TASK_BUF,y
	iny
	lda #>nmi_task_full_torch_time_bar
	sta NMI_TASK_BUF,y
	iny
	sty nmi_task_buf_index
	rts
	
	
nmi_task_full_torch_time_bar = * - 1
	lda #$20
	sta $2006
	lda #$4c
	sta $2006
	
	lda #$cf
	.rept TORCH_INITIAL_TIME / 8
		sta $2007
	.next
	rts
	
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
collect_treasure
	ldx maze
	lda maze_treasures,x
	cmp #8
	beq _over
	
	ldy #SONG_RICH_MAN
	sty sfx_init_flag
	
	tay
	lda _handler_lo_tbl,y
	sta temp_sub+0
	lda _handler_hi_tbl,y
	sta temp_sub+1
	jsr jmp_temp_sub
	
	lda #<500
	ldy #>500
	jsr award_points
	
	ldy bitfield_index_tbl,x
	lda treasures,y
	ora bitfield_mask_tbl,x
	sta treasures,y
	
	lda #$6b ;set number in treasure list
	clc
	adc maze
	tax
	lda #$20
	ldy maze
	iny
	jsr queue_render_single_number
	
	lda #$22 ;hide treasure from screen
	ldx #$14
	ldy #$a0
	jsr queue_repcopy_2
	lda #$22
	ldx #$34
	ldy #$a0
	jmp queue_repcopy_2
	
_over
	lda #MODE_LEVEL_COMPLETE
	sta mode_init_flag
	
	lda #<2000
	ldy #>2000
	jmp award_points
	
	
_handler_tbl = [_invincible,_sword,_lantern,_boots,_score,_teleport,_score,_score]
_handler_lo_tbl	.byte <_handler_tbl
_handler_hi_tbl	.byte >_handler_tbl

_score
	lda #<1000
	ldy #>1000
	jmp award_points
	
_invincible
	lda #TREASURE_EFFECT_INVINCIBLE
	gne _set_treasure_effect
_lantern
	lda #TREASURE_EFFECT_LANTERN
	gne _set_treasure_effect
_boots
	lda #TREASURE_EFFECT_BOOTS
	gne _set_treasure_effect
_teleport
	lda #TREASURE_EFFECT_TELEPORT
	gne _set_treasure_effect
_set_treasure_effect
	ora treasure_effects
	sta treasure_effects
	rts
	
_sword
	lda #$ff
	sta sword_time
	lda #SONG_CHARGE
	sta sfx_init_flag
	rts
	
	
	
	
	
collect_key
	
	ldx maze
	ldy maze_keys,x
	ldx bitfield_index_tbl,y
	lda keys,x
	ora bitfield_mask_tbl,y
	sta keys,x
	
	lda #SONG_RAISING
	sta sfx_init_flag
	
	tya ;set number in key list
	clc
	adc #$8b
	tax
	lda #$20
	iny
	jsr queue_render_single_number
	
	lda #<100
	ldy #>100
	jmp award_points
	
	
	
	
	
	
collect_sword
	
	ldy maze
	ldx bitfield_index_tbl,y
	lda swords,x
	ora bitfield_mask_tbl,y
	sta swords,x
	
	lda #SONG_CHARGE
	sta sfx_init_flag
	
	lda #SWORD_INITIAL_TIME
	sta sword_time
	
	lda #<100
	ldy #>100
	jmp award_points
	
	
	
	
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
has_treasure
	ldx maze
	ldy bitfield_index_tbl,x
	lda treasures,y
	and bitfield_mask_tbl,x
	rts
	
has_key_in_this_maze
	ldy maze
	ldx maze_keys,y
	gpl +
	
has_key_for_this_maze
	ldx maze
+	ldy bitfield_index_tbl,x
	lda keys,y
	and bitfield_mask_tbl,x
	rts
	
has_sword
	ldx maze
	ldy bitfield_index_tbl,x
	lda swords,y
	and bitfield_mask_tbl,x
	rts
	
	
	
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
treasure_tile_tbl	.byte $d8,$dc,$e0,$e4,$e8,$d8,$ec,$f0,$f4
treasure_color_tbl
	.byte C64_COLORS[$0d]
	.byte C64_COLORS[$01]
	.byte C64_COLORS[$08]
	.byte C64_COLORS[$03]
	.byte C64_COLORS[$01]
	.byte C64_COLORS[$08]
	.byte C64_COLORS[$07]
	.byte C64_COLORS[$04]
	.byte C64_COLORS[$0f]
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
torch_anim_tbl	.byte $14,$18,$1c,$18
	