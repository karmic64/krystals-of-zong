
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
	
MONSTER_COLOR_DARK = C64_COLORS[$0b]

MONSTER_COLOR_VULNERABLE = C64_COLORS[$0a]
MONSTER_COLOR_VULNERABLE_OVER = C64_COLORS[$02]
	
AMT_MONSTERS = 4
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	.section zp_vars_game
	
	;;;;;;;;;;;;;;;;;;;
	
	;bit 7:
	;	1: monsters should be introduced immediately at the corners
	;	0: monsters should be introduced when the player walks in, randomly
	;bits 0-3 - introduced monsters
monster_introducing	.byte ?
	
monster_active	.byte ?
fireball_active	.byte ?

monsters_x_lo	.fill AMT_MONSTERS
fireball_x_lo	.byte ?
monsters_x_hi	.fill AMT_MONSTERS
fireball_x_hi	.byte ?

monsters_y	.fill AMT_MONSTERS
fireball_y	.byte ?

monster_speed_index	.byte ?
monsters_direction	.fill AMT_MONSTERS
fireball_direction	.byte ?

monster_anim_timer	.byte ?
monster_anim_index	.byte ?

monster_color_mode	.byte ?
	
	
	.send
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	
init_monsters
	
	lda #$80
	sta monster_introducing
	
	lda #$00
	sta monster_anim_index
	
	lda level
	lsr
	tax
	lda monster_speed_index_tbl,x
	sta monster_speed_index
	lda monster_anim_interval_tbl,x
	sta monster_anim_timer
	
	rts





init_monsters_maze
	
	lda #0
	sta fireball_active
	
	lda #$ff
	sta monster_color_mode
	
	lda monster_introducing
	bmi _constant_positions
	
	ldx #AMT_MONSTERS-1
-	stx temp
	
	jsr get_random_maze_position
	jsr get_pixel_position
	
	stx temp_sub
	
	ldx temp
	sta monsters_x_lo,x
	sty monsters_x_hi,x
	lda temp_sub
	sta monsters_y,x
	
	lda #0
	sta monsters_direction,x
	
	dex
	bpl -
	
	lda #0
	sta monster_introducing
_set_active
	sta monster_active
	
	rts
	
	
_constant_positions
	
	lda #$10
	sta monsters_x_lo+0
	sta monsters_x_lo+1
	sta monsters_y+0
	sta monsters_y+2
	lda #$30
	sta monsters_x_lo+2
	sta monsters_x_lo+3
	lda #$a0
	sta monsters_y+1
	sta monsters_y+3
	
	lda #0
	sta monsters_x_hi+0
	sta monsters_x_hi+1
	lda #1
	sta monsters_x_hi+2
	sta monsters_x_hi+3
	
	lda #DIRECTION_RIGHT
	sta monsters_direction+0
	lda #DIRECTION_UP
	sta monsters_direction+1
	lda #DIRECTION_DOWN
	sta monsters_direction+2
	lda #DIRECTION_LEFT
	sta monsters_direction+3
	
	lda #$0f
	gne _set_active  ;don't write to introducing, we want to keep it for the first frame

	
	
	
	
	
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
handle_monsters
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; movement
	
	ldx monster_speed_index
	lda monster_speed_tbl,x
	bpl +
	and #$7f
	tax
	stx monster_speed_index
	lda monster_speed_tbl,x
+	beq _no_movement
	sta temp+1
	
	
	ldx #AMT_MONSTERS-1
_monster_loop
	lda monster_active
	and bitfield_mask_tbl,x
	beq _no_movement_this_monster
	
	stx temp
	
	;;;;;;;;;; are we on a tile?
	
	lda monster_introducing  ;on the first frame of a non-random spawn, do not change directions
	bmi _still_moving
	lda monsters_x_lo,x
	ora monsters_y,x
	and #7
	bne _still_moving
	
	;;;;;;;;;; get all possible directions
	
	;lda #0
	sta temp+2
	
	ldy #3
-	tya ;don't double back
	eor #1
	cmp monsters_direction,x
	beq +
	jsr check_monster_direction_allowed
	ldy check_direction_allowed.direction
	cmp #1
+	rol temp+2
	ldx temp
	dey
	bpl -
	
	;;;;;;;;;; can't turn anywhere?
	
	lda temp+2
	cmp #$0f
	beq _no_movement_this_monster
	
	ldy monsters_direction,x
	lda bitfield_mask_tbl,y
	eor #$0f
	cmp temp+2
	beq _after_turn_check
	
	;;;;;;;;;; decide how to move
	
	jsr rand
	and #$0f
	bne _chase
	
	;;;;;;;;;; just turn randomly
	
_turn_random
	jsr rand ;valid shift count
	and #3
	sta temp_sub
	
	lda temp+2
	asl
	asl
	asl
	asl
	ora temp+2
	ldy #0 ;final direction
	geq +
-	ora #$80
-	iny
+	lsr
	bcs --
	dec temp_sub
	bpl -
	
	tya
	and #3
	sta monsters_direction,x
	
	gcc _after_turn_check
	
	;;;;;;;;; make an active effort to get to the player
	
_chase
	
	;;;; find best directions of both axes and opposites
	
	ldy #DIRECTION_LEFT
	lda monsters_x_lo,x
	cmp player_x+0
	lda monsters_x_hi,x
	sbc player_x+1
	bcs +
	iny
+	sty temp_sub+3
	tya
	eor #1
	sta temp_sub+1
	
	ldy #DIRECTION_UP
	lda player_y
	cmp #MAZE_FULL_PIXEL_HEIGHT
	bcs +
	lda monsters_y,x
	cmp player_y
	bcs +
	iny
+	sty temp_sub+2
	tya
	eor #1
	sta temp_sub+0
	
	;;;; if we prefer the other axis, swap them
	
	lda game_cnt+1
	and #3
	bne +
	lda game_cnt+0
	lsr
	bcc +
	
	lda temp_sub+0
	ldy temp_sub+1
	sty temp_sub+0
	sta temp_sub+1
	
	lda temp_sub+2
	ldy temp_sub+3
	sty temp_sub+2
	sta temp_sub+3
	
+	
	
	;;;;; swap middle two randomly
	
	jsr rand
	and #3
	bne +
	
	lda temp_sub+1
	ldy temp_sub+2
	sty temp_sub+1
	sta temp_sub+2
	
+	
	
	;;;;; find the first match
	
	ldy #3
-	ldx temp_sub,y
	lda bitfield_mask_tbl,x
	and temp+2
	beq +
	dey
	bpl -
	
+	txa
	ldx temp
	sta monsters_direction,x
	
	
	
	;;;;;;;;;; if we're on a tile, check for fireball shot
	
_after_turn_check
	
	lda angel_state
	bne _no_shoot_fireball
	
	lda level
	and #3
	cmp #3
	bne _no_shoot_fireball
	
	lda fireball_active
	bne _no_shoot_fireball
	
	;;;; try and find the direction we directly line up with the player
	
	lda monsters_y,x
	cmp player_y
	bne _fireball_not_on_x
	
	ldy #DIRECTION_LEFT
	lda monsters_x_lo,x
	cmp player_x+0
	lda monsters_x_hi,x
	sbc player_x+1
	bcs _found_fireball_direction
	iny
	gcc _found_fireball_direction
	
	
_fireball_not_on_x
	lda monsters_x_lo,x
	cmp player_x+0
	bne _no_shoot_fireball
	lda monsters_x_hi,x
	cmp player_x+1
	bne _no_shoot_fireball
	
	ldy #DIRECTION_UP
	lda player_y
	cmp #MAZE_FULL_PIXEL_HEIGHT
	bcs +
	lda monsters_y,x
	cmp player_y
	bcs +
	iny
+	
	
	;;;;;;;; we got the direction, check if it's ok
	
_found_fireball_direction
	
	tya  ;can't shoot backwards
	eor #1
	cmp monsters_direction,x
	beq _no_shoot_fireball
	
	lda bitfield_mask_tbl,y  ;can't be a wall there
	and temp+2
	bne _no_shoot_fireball
	
	;;;;;;; ok, enable the fireball
	
	lda #1
	sta fireball_active
	
	lda monsters_x_lo,x
	sta fireball_x_lo
	lda monsters_x_hi,x
	sta fireball_x_hi
	
	lda monsters_y,x
	sta fireball_y
	
	sty fireball_direction
	
_no_shoot_fireball
	
	
	;;;;;;;;;; keep moving as normal
	
_still_moving
	jsr move_monster
	
_no_movement_this_monster
	dex
	bpl _monster_loop
	
_no_movement
	inc monster_speed_index
	
	
	
	;;;;;;;;;;;;;;;;;;; check if we should unleash the monsters
	
	lda monster_introducing
	bmi _unleash  ;this technically has no effect but it acknowledges the first frame
	bne _no_introduce
	
	lda player_y
	cmp #$10
	bcc _no_introduce
	cmp #$a1
	bcs _no_introduce
	
	lda player_x+0
	ldy player_x+1
	bne +
	cmp #$10
	bcs _unleash
	gcc _no_introduce
	
+	cmp #$31
	bcs _no_introduce
	
_unleash
	lda #$0f
	sta monster_active
	sta monster_introducing
_no_introduce
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; animation
	
	dec monster_anim_timer
	bne _no_anim
	
	lda level
	lsr
	tax
	lda monster_anim_interval_tbl,x
	sta monster_anim_timer
	
	ldx monster_anim_index
	inx
	cpx #size(monster_anim_index_tbl)
	bcc +
	ldx #0
+	stx monster_anim_index
	
_no_anim
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; colors
	
	ldy #3
	
	lda sword_time
	cmp #SWORD_THRESHOLD+1
	bcs +
	dey
	cmp #1
	bcs +
	dey
	lda torch_time
	beq +
	dey
+	
	cpy monster_color_mode
	beq +
	sty monster_color_mode
	jsr queue_monster_colors
+	
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;; fireball
	
	lda fireball_active
	beq _no_fireball
	
	lda fireball_x_lo
	ldy fireball_x_hi
	beq +
	cmp #<MAZE_FULL_PIXEL_WIDTH  ;just to ensure it won't go out of bounds...
	bcs _kill_fireball
+	
	ldx fireball_y
	cpx #MAZE_FULL_PIXEL_HEIGHT
	bcs _kill_fireball
	
	jsr get_maze_position
	
	ldx fireball_direction
	jsr check_direction_allowed
	beq _move_fireball
	
_kill_fireball
	lda #0
	sta fireball_active
	
	geq _no_fireball
	
_move_fireball
	
	ldy #2 ;get speed
	lda level
	cmp #4
	bcs +
	lda game_cnt
	lsr
	bcs +
	dey
+	sty temp+1
	
	ldx #AMT_MONSTERS
	jsr move_monster
	
_no_fireball
	
	
	
	rts
	
	
	
	
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	
move_monster
	
	ldy monsters_direction,x
	
	lda direction_horz_tbl,y
	beq _no_horz
	cmp #$80
	lda #0
	sta temp_sub
	lda temp+1
	bcc +
	eor #$ff
	dec temp_sub
+	adc monsters_x_lo,x
	sta monsters_x_lo,x
	lda temp_sub
	adc monsters_x_hi,x
	sta monsters_x_hi,x
_no_horz
	
	lda direction_vert_tbl,y
	beq _no_vert
	cmp #$80
	lda temp+1
	bcc +
	eor #$ff
+	adc monsters_y,x
	sta monsters_y,x
_no_vert

	rts
	
	
	
	
	
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
render_monsters
	
	;;;;;;;;;;;;;;; main monsters
	
	lda level
	and #3
	tax
	lda _handler_lo_tbl,x
	sta temp
	lda _handler_hi_tbl,x
	sta temp+1
	
	ldx #AMT_MONSTERS-1
-	lda monster_active
	and bitfield_mask_tbl,x
	beq +
	stx temp+2
	lda monster_anim_flags_or_tbl,x
	sta temp_sub+1
	ldy monster_anim_index
	lda monster_anim_index_tbl,y
	jsr jmp_temp
	ldx temp+2
+	dex
	bpl -
	
	;;;;;;;;;;;;;;; fireball
	
	lda fireball_active
	beq _no_fireball
	
	ldy #$2e
	lda game_cnt
	ldx level
	cpx #4
	bcs +
	lsr
+	lsr
	bcc +
	iny
	iny
	iny
	iny
+	sty temp_sub
	
	lda #$21
	sta temp_sub+1
	
	ldx #AMT_MONSTERS
	jsr get_monster_position
	jsr add_double_maze_sprite
	
_no_fireball
	
	rts
	
	
_handler_tbl = [_snake,_bat,_spider,_mummy]
_handler_lo_tbl	.byte <_handler_tbl
_handler_hi_tbl	.byte >_handler_tbl
	
	
_snake
	asl
	asl
	ora monster_anim_frame_or_tbl,x
	sta temp_sub
	
	jsr get_monster_position
	jmp add_double_maze_sprite
	
	
_bat
	asl
	ora #$10
	ora monster_anim_frame_or_tbl,x
	sta temp_sub
	
	jsr get_monster_position
	jsr add_maze_sprite
	lda temp_sub+1
	eor #$40
	sta temp_sub+1
	jmp add_double_maze_sprite._next
	
	
_spider
	tay
	lda monster_spider_anim_right_tbl,y
	ora monster_anim_frame_or_tbl,x
	pha
	lda monster_spider_anim_left_tbl,y
	ora monster_anim_frame_or_tbl,x
	sta temp_sub
	
	jsr get_monster_position
	jsr add_maze_sprite
	pla
	sta temp_sub
	jmp add_double_maze_sprite._next
	
	
_mummy
	lda #$24
	ora monster_anim_frame_or_tbl,x
	cpy #3
	bcs _mummy_flip
	sta temp_sub
	
	jsr get_monster_position
	jmp add_double_maze_sprite
	
_mummy_flip
	eor #2
	sta temp_sub
	
	lda temp_sub+1
	eor #$40
	sta temp_sub+1
	
	jsr get_monster_position
	jmp add_x_flipped_double_maze_sprite
	
	
	
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; palette handling
	
jmp_temp_sub = queue_monster_colors._jmp_temp_sub
	
queue_monster_colors
	ldy monster_color_mode
	lda _handler_lo_tbl,y
	sta temp_sub+0
	lda _handler_hi_tbl,y
	sta temp_sub+1
_jmp_temp_sub
	jmp (temp_sub)
	
_handler_tbl = [set_monster_initial_colors,_dark,_vulnerable_over,_vulnerable]
_handler_lo_tbl	.byte <_handler_tbl
_handler_hi_tbl	.byte >_handler_tbl


_dark
	lda #MONSTER_COLOR_DARK
	gpl set_monster_same_colors
	
_vulnerable_over
	lda #MONSTER_COLOR_VULNERABLE_OVER
	gpl set_monster_same_colors
	
_vulnerable
	lda #MONSTER_COLOR_VULNERABLE
	gpl set_monster_same_colors

	
	; color in A
set_monster_same_colors
	sta palette_spr_2+0
	sta palette_spr_2+1
	sta palette_spr_2+2
	sta palette_spr_3+0
	rts



	
set_monster_initial_colors
	lda level
	and #3
	tax
	lda monster_0_color_tbl,x
	sta palette_spr_2+0
	lda monster_1_color_tbl,x
	sta palette_spr_2+1
	lda monster_2_color_tbl,x
	sta palette_spr_2+2
	lda monster_3_color_tbl,x
	sta palette_spr_3+0
	rts
	
	
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
get_monster_position
	lda monsters_x_lo,x
	pha
	ldy monsters_x_hi,x
	lda monsters_y,x
	tax
	pla
	rts
	
	
	
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	
	;; wrapper for check_direction_allowed with some extra exceptions
	
check_monster_direction_allowed
	sty check_direction_allowed.direction
	
	;; don't allow monsters to exit the maze
	
	lda monsters_y,x
	
	cpy #DIRECTION_UP
	bne +
	cmp #$10 + 1
	bcc _exception
+	
	cpy #DIRECTION_DOWN
	bne +
	cmp #$a0
	bcs _exception
+
	cpy #DIRECTION_LEFT
	bne +
	lda monsters_x_hi,x
	bne _normal
	lda monsters_x_lo,x
	cmp #$10 + 1
	bcc _exception
+	
	cpy #DIRECTION_RIGHT
	bne +
	lda monsters_x_hi,x
	beq _normal
	lda monsters_x_lo,x
	cmp #$30
	bcs _exception
+	
_normal
	
	;; check as normal
	jsr get_monster_position
	jsr get_maze_position
	ldx check_direction_allowed.direction
	jmp check_direction_allowed
	
	
_exception
	lda #$ff
	rts
	
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; data
	
	
monster_0_color_tbl
	.byte C64_COLORS[$05]
	.byte C64_COLORS[$0c]
	.byte C64_COLORS[$04]
	.byte C64_COLORS[$01]
monster_1_color_tbl
	.byte C64_COLORS[$0d]
	.byte C64_COLORS[$03]
	.byte C64_COLORS[$03]
	.byte C64_COLORS[$01]
monster_2_color_tbl
	.byte C64_COLORS[$0e]
	.byte C64_COLORS[$0f]
	.byte C64_COLORS[$05]
	.byte C64_COLORS[$01]
monster_3_color_tbl
	.byte C64_COLORS[$03]
	.byte C64_COLORS[$0e]
	.byte C64_COLORS[$0e]
	.byte C64_COLORS[$01]
	
	
	
monster_speed_index_tbl
	.byte monster_speed_tbl.level_1_2
	.byte monster_speed_tbl.level_3_4
	.byte monster_speed_tbl.level_5_6
	.byte monster_speed_tbl.level_7_8
	
monster_speed_tbl	.block
		.logical 0
	
level_1_2	.byte 1,0, level_1_2 | $80
level_3_4	.byte 1,1,0, level_3_4 | $80
level_5_6	.byte 1,1,1,0, level_5_6 | $80
level_7_8	.byte 1, level_7_8 | $80
	
		.here
	.bend
	
	
	
monster_anim_interval_tbl	.byte [2,3,4,1] * 3



monster_anim_frame_or_tbl	.byte $40,$80,$c0,$40

monster_anim_flags_or_tbl	.byte $22,$22,$22,$23


monster_anim_index_tbl	.byte 0,1,2,3,2,1

;monster_snake_anim_tbl	.byte $00,$04,$08,$0c

;monster_bat_anim_tbl	.byte $10,$12,$14,$18

monster_spider_anim_left_tbl	.byte $18,$1c,$18,$22
monster_spider_anim_right_tbl	.byte $1a,$1e,$20,$1e
	
	
	
monster_y_hitbox_offs_tbl	.byte $0c,$08,$0c,$0c
monster_y_hitbox_size_tbl	.byte $18,$14,$18,$18
	
	
	
monster_kill_points_lo_tbl	.byte <800,<600,<400,<200
monster_kill_points_hi_tbl	.byte >800,>600,>400,>200
	
	