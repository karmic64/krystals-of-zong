
PLAYER_COLOR_1 = C64_COLORS[$e]
PLAYER_COLOR_2 = C64_COLORS[2]
PLAYER_COLOR_3 = C64_COLORS[7]

PLAYER_INITIAL_X = $a0
PLAYER_INITIAL_Y = $9f - SPRITE_Y_BASE

PLAYER_ANIM_INTERVAL = 3



ANGEL_COLOR_1 = C64_COLORS[1]
ANGEL_COLOR_2 = C64_COLORS[2]
ANGEL_COLOR_3 = C64_COLORS[7]

ANGEL_STATE_OFF = 0
ANGEL_STATE_LOWERING = 1
ANGEL_STATE_RISING = 2
ANGEL_STATE_WAITING = 3


	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	.section zp_vars_game
	
	;;;;;;;;;;;;;;;;;;;;;
	
player_x	.word ?
player_y	.byte ?

player_direction	.byte ?

player_walled	.byte ?

	;used for boots
	;this must be 0 when we are directly on the junction grid of 3x3 tiles
player_move_mod_3	.byte ?

player_anim_timer	.byte ?
player_anim_index	.byte ?

	;0-3 - need to change maze in this direction
	;$80+ - don't
maze_move_flag	.byte ?

	;;;;;;;;;;;;;;;;;;;;;
	
angel_state	.byte ?
	
angel_y	.byte ?

angel_anim_index	.byte ?
	
	.send
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	
	
	
init_player_maze
	
	lda #PLAYER_COLOR_1
	sta palette_spr_0+0
	lda #PLAYER_COLOR_2
	sta palette_spr_0+1
	lda #PLAYER_COLOR_3
	sta palette_spr_0+2
	
	
	ldy maze_move_flag
	bpl init_player_move_maze
	
init_player

	lda #<PLAYER_INITIAL_X
	sta player_x+0
	lda #>PLAYER_INITIAL_X
	sta player_x+1

	lda #PLAYER_INITIAL_Y
	sta player_y
	
	lda #1
	sta player_walled
	lda #0
	sta player_direction
	sta player_move_mod_3
	sta player_anim_index
	lda #PLAYER_ANIM_INTERVAL
	sta player_anim_timer

	lda #$ff
	sta maze_move_flag

	lda #ANGEL_STATE_OFF
	sta angel_state
	
	rts
	
	
init_player_move_maze
	
	lda maze_move_add_tbl,y
	clc
	adc maze
	tax
	jsr set_maze_ptr
	
	lda maze_move_x_tbl_lo,y
	sta player_x+0
	lda maze_move_x_tbl_hi,y
	sta player_x+1
	lda maze_move_y_tbl,y
	sta player_y
	lda maze_move_mod_3_tbl,y
	sta player_move_mod_3
	
	lda #$ff
	sta maze_move_flag
	
	jmp move_player
	
	
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
init_angel
	inc angel_state
	
	lda #$cf
	sta angel_y
	
	lda #0
	sta angel_anim_index
	
	sta fireball_active
	
	lda #SONG_AMAZING_GRACE
	sta music_init_flag
	
	lda #$ef
	jsr move_status_bar_sprites_top
	jsr move_status_bar_sprites_bottom
	
	jmp set_angel_palette
	
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
handle_player
	
	lda angel_state
	bne handle_angel
	
	;;;;;;;;;;;;;;;;;;;; is the player on a tile?
	lda player_x
	and #7
	bne _not_on_tile
	lda player_y
	and #7
	bne _not_on_tile

	;;;;;;;;;;; special hotspots
	
	lda player_x+0
	ldx player_x+1
	ldy player_y
	
	cpy #$58
	bne _not_middle_row
	cpx #1
	bcs _maybe_room_change_horz
	cmp #$a0
	bne _no_special_spot
_treasure_chamber
	jsr has_treasure
	bne _no_special_spot
	jsr collect_treasure
	jmp _no_special_spot
	
_maybe_room_change_horz
	cmp #$e0
	beq _room_change_left
	cmp #$60
	bne _no_special_spot
_room_change_right
	lda #DIRECTION_RIGHT
	gne _room_change
_room_change_left
	lda #DIRECTION_LEFT
	gne _room_change
	
_not_middle_row
	cpx #1
	bcs _no_special_spot
	cmp #$a0
	bne _no_special_spot
	cpy #$e0
	beq _room_change_up
	cpy #$d0
	bne _no_special_spot
_room_change_down
	lda #DIRECTION_DOWN
	gne _room_change
_room_change_up
	lda #DIRECTION_UP
	
_room_change
	sta maze_move_flag
	lda #MODE_GAME_ROOM
	sta mode_init_flag
	rts
	
_no_special_spot

	
	;;;;;;;;;;;;;;;; not on a special spot
	
	;;;; if demo mode, make the player move on his own
	
	lda demo_mode
	bpl _not_demo_mode
	
	lda #0
	sta temp
	
	ldy #3  ;survey all possible directions
-	tya  ;never double back
	eor #1
	cmp player_direction
	beq +
	jsr check_player_direction_allowed
	ldy check_direction_allowed.direction
	cmp #1
+	rol temp
	dey
	bpl -
	
	lda temp ;if nowhere to go, just quit
	cmp #$0f
	beq _no_change_junction
	ldy player_direction
	lda bitfield_mask_tbl,y
	eor #$0f
	cmp temp
	beq _no_change_junction
	
	jsr rand ;valid shift count
	and #3
	sta temp_sub
	
	lda temp
	asl
	asl
	asl
	asl
	ora temp
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
	sta player_direction
	gpl _move_player
	
_not_demo_mode
	
	;;;; first, check if the joypad is moving in an allowed direction
	
	jsr get_joy_direction
	cpy #$ff
	beq _no_change_junction
	jsr check_player_direction_allowed
	bne _no_change_junction
	
	ldy check_direction_allowed.direction ;ok, change direction and let player move
_change_junction
	sty player_direction
	jmp _move_player
	
_no_change_junction

	;;;; no direction change, check if we can keep going this way
	
	;lda player_walled
	;beq _after_direction_check
	ldy player_direction
	jsr check_player_direction_allowed
	beq _move_player
	
	lda #1 ;can't keep going, stop movement
	sta player_walled
	
	gne _after_direction_check
	
	
	;;;;;;;;;;;;;;;;; player is not on tile, let him turn backwards only
	
_not_on_tile
	lda demo_mode
	bmi +
	
	jsr get_joy_direction
	tya
	eor #1
	cmp player_direction
	bne +
	sty player_direction
+	

_move_player
	lda #0
	sta player_walled
	ldy player_direction
	jsr move_player

	;;;;;;;;;;;;;;;;;; if the player is actually moving, animate him
_after_direction_check
	
	lda player_walled
	bne _no_anim
	
	dec player_anim_timer
	bne _no_anim
	lda #PLAYER_ANIM_INTERVAL
	sta player_anim_timer
	inc player_anim_index
	
_no_anim




	;;;;;;;;;;;;;;;;;;; check collision with monsters
	
	ldx #AMT_MONSTERS-1
_monster_collide_loop
	lda monster_active
	and bitfield_mask_tbl,x
	beq _no_collide_this_monster
	
	lda level
	and #3
	tay
	lda monsters_y,x
	sec
	sbc player_y
	clc
	adc monster_y_hitbox_offs_tbl,y
	cmp monster_y_hitbox_size_tbl,y
	bcs _no_collide_this_monster
	
	lda monsters_x_lo,x
	sec
	sbc player_x+0
	sta temp_sub+0
	lda monsters_x_hi,x
	sbc player_x+1
	tay
	
	lda temp_sub+0
	clc
	adc #$0c
	bcc +
	iny
+	cpy #0
	bne _no_collide_this_monster
	cmp #$1c
	bcs _no_collide_this_monster
	
	lda sword_time
	bne _kill_mon
	
_kill_player
	lda treasure_effects
	and #TREASURE_EFFECT_INVINCIBLE
	bne +
	jsr init_angel
+	jmp _no_collide_monsters
	
_kill_mon
	lda bitfield_mask_tbl,x
	eor #$ff
	and monster_active
	sta monster_active
	
	stx temp_sub
	ldy #4
	ldx #0
-	lsr
	bcc +
	inx
+	dey
	bpl -
	lda monster_kill_points_lo_tbl,x
	ldy monster_kill_points_hi_tbl,x
	jsr award_points
	ldx temp_sub
	
	lda #SONG_BLIPPING
	sta sfx_init_flag
	
_no_collide_this_monster
	dex
	bpl _monster_collide_loop

_no_collide_monsters





	;;;;;;;;;;;;;;;;;; check collision with fireball
	
	lda fireball_active
	beq _no_collide_fireball
	
	lda treasure_effects
	and #TREASURE_EFFECT_INVINCIBLE
	bne _no_collide_fireball
	
	lda fireball_y
	sec
	sbc player_y
	clc
	adc #$08
	cmp #$10
	bcs _no_collide_fireball
	
	lda fireball_x_lo
	sec
	sbc player_x+0
	sta temp_sub
	lda fireball_x_hi
	sbc player_x+1
	tay
	
	lda temp_sub
	clc
	adc #$0a
	bcc +
	iny
+	cpy #1
	bcs _no_collide_fireball
	cmp #$14
	bcs _no_collide_fireball
	
	jsr init_angel
	
_no_collide_fireball





	;;;;;;;;;;;;;;;;;;; check collision with items
	
	jsr has_key_in_this_maze
	bne _no_collide_key
	
	lda maze_keys_row,x
	ldy maze_keys_column,x
	jsr get_player_item_pixel_distance
	
	clc
	adc #$0d
	bcc +
	iny
+	cpy #1
	bcs _no_collide_key
	cmp #$1a
	bcs _no_collide_key
	
	cpx #$0b
	bcc +
	cpx #$f8
	bcc _no_collide_key
+	
	jsr collect_key
	
_no_collide_key
	
	
	jsr has_sword
	bne _no_collide_sword
	
	lda maze_swords_row,x
	ldy maze_swords_column,x
	jsr get_player_item_pixel_distance
	
	clc
	adc #$0d
	bcc +
	iny
+	cpy #1
	bcs _no_collide_sword
	cmp #$1a
	bcs _no_collide_sword
	
	cpx #$0b
	bcc +
	cpx #$f4
	bcc _no_collide_sword
+	
	jsr collect_sword
	
_no_collide_sword
	
	
	
	lda maze
	cmp torch_maze
	bne _no_collide_torch
	
	lda torch_row
	ldy torch_column
	jsr get_player_item_pixel_distance
	
	clc
	adc #$0d
	bcc +
	iny
+	cpy #1
	bcs _no_collide_torch
	cmp #$1a
	bcs _no_collide_torch
	
	cpx #$0b
	bcc +
	cpx #$f4
	bcc _no_collide_torch
+	
	jsr collect_torch
	
_no_collide_torch
	
	


	rts
	
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; moves the player in direction Y by his speed
	
move_player
	lda direction_horz_tbl,y
	ora direction_vert_tbl,y
	asl
	php
	
	ldx #1
	lda treasure_effects
	and #TREASURE_EFFECT_BOOTS
	beq _set_speed
	
	lda #0 ;mod 3 compare value
	bcc +
	lda #2
+	cmp player_move_mod_3
	bne +
	inx
+	
_set_speed
	stx temp_sub
	
	txa
	plp
	bcc +
	eor #$ff
+	adc player_move_mod_3
	bpl +
	clc
	adc #3
+	cmp #3
	bcc +
	sbc #3
+	sta player_move_mod_3
	
	
	
	lda direction_horz_tbl,y
	beq _no_horz
	asl
	lda temp_sub ;player_speed
	ldx #0
	bcc +
	eor #$ff
	dex
+	adc player_x+0
	sta player_x+0
	txa
	adc player_x+1
	sta player_x+1
_no_horz
	
	
	
	lda direction_vert_tbl,y
	beq _no_vert
	asl
	lda temp_sub ;player_speed
	bcc +
	eor #$ff
+	adc player_y
	sta player_y
_no_vert
	
	rts
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; gets the direction being pointed by the d-pad in Y
	;; $ff means no direction
	
get_joy_direction
	lda #1
	ldy #3
-	bit rawjoy
	bne +
	asl
	dey
	bpl -
+	rts
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;;;;; wrapper for check_direction_allowed with some extra exceptions
	
check_player_direction_allowed
	
	;;; if player has key, is holding A, and is walking towards keyhole
	
	sty check_direction_allowed.direction
	
	lda demo_mode  ;shouldn't be able to manipulate the demo!
	bmi _no_key_check
	lda rawjoy
	bpl _no_key_check
	lda player_y
	cmp #$58
	bne _no_key_check
	lda player_x+1
	bne _no_key_check
	jsr has_key_for_this_maze
	beq _no_key_check
	
	lda player_x+0
	ldy check_direction_allowed.direction
	
	cpy #DIRECTION_RIGHT
	bne +
	cmp #$70
	beq _exception
	cmp #$b8
	beq _exception
+	
	cpy #DIRECTION_LEFT
	bne +
	cmp #$88
	beq _exception
	cmp #$d0
	beq _exception
+	
	
_no_key_check
	
	;;; check as normal
	
	lda player_x+0
	ldy player_x+1
	ldx player_y
	jsr get_maze_position
	
	ldx check_direction_allowed.direction
	jmp check_direction_allowed
	
_exception
	lda #0
	rts
	
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; get distance between player and an item at row A column Y
	
get_player_item_pixel_distance	.block
	
	.virtual temp_sub
x_diff	.word ?
;y_diff	.byte ?
	.endv
	

	jsr get_pixel_position
	
	sec
	sbc player_x+0
	sta x_diff+0
	tya
	sbc player_x+1
	sta x_diff+1
	
	txa
	sec
	sbc player_y
	;sta y_diff
	tax
	
	lda x_diff+0
	ldy x_diff+1
	rts
	
	
	.bend
	
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
handle_angel
	;lda angel_state
	cmp #ANGEL_STATE_RISING
	bcc _lowering
	bne _waiting
	
	;;;;; raise player up
	
_rising
	lda angel_y
	cmp #$cf
	beq +
	dec angel_y
+	
	lda player_y
	cmp #$cf
	beq _to_waiting
	dec player_y
	jmp _animate
	
	;;;;; hit the top, check lives to see if we respawn
	
_to_waiting
	
	lda men
	cmp #1
	bne +
	
	dec men
	
	lda #STATUS_REDRAW_MEN
	ora status_redraw_flags
	sta status_redraw_flags
	
	lda #$22
	ldx #$11
	jsr queue_ppu_addr
	lda #<nmi_task_fastcopy_bytes(size(game_over_text_top))
	sta NMI_TASK_BUF,y
	iny
	lda #>nmi_task_fastcopy_bytes(size(game_over_text_top))
	sta NMI_TASK_BUF,y
	iny
	ldx #size(game_over_text_top)-1
-	lda game_over_text_top,x
	sta NMI_TASK_BUF,y
	iny
	dex
	bpl -
	sty nmi_task_buf_index
	
	lda #$22
	ldx #$31
	jsr queue_ppu_addr
	lda #<nmi_task_fastcopy_bytes(size(game_over_text_bottom))
	sta NMI_TASK_BUF,y
	iny
	lda #>nmi_task_fastcopy_bytes(size(game_over_text_bottom))
	sta NMI_TASK_BUF,y
	iny
	ldx #size(game_over_text_bottom)-1
-	lda game_over_text_bottom,x
	sta NMI_TASK_BUF,y
	iny
	dex
	bpl -
	sty nmi_task_buf_index
	
+	
	inc angel_state
	
	lda #SPRITE_Y_BASE - $20
	jsr move_status_bar_sprites_top
	lda #SPRITE_Y_BASE - $10
	jsr move_status_bar_sprites_bottom
	
	jmp set_torch_palette
	
	
	;;;;;;;; come down to player
	
_lowering
	inc angel_y
	lda player_y
	sec
	sbc #$0f
	cmp angel_y
	bne +
	inc angel_state
+	
	
	;;;;;;;; animation
	
_animate
	lda game_cnt
	and #3
	bne ++
	ldx angel_anim_index
	inx
	cpx #size(angel_anim_tbl)
	bcc +
	tax ;ldx #0
+	stx angel_anim_index
+	rts
	
	
	;;;;;;;; waiting
	
_waiting
	
	;;; try and center the screen
	
	lda maze_x_scroll
	cmp #MAZE_MAX_X_SCROLL / 2
	beq _no_scroll
	bcc _too_far_left

_too_far_right
	dec maze_x_scroll
	rts
	
_too_far_left
	inc maze_x_scroll
	rts
	
_no_scroll
	
	;;;;; check if game over
	
	lda men
	beq _game_over
	
	;;;;; game not over, wait until music ends
	;; and enemies aren't right next to spawn point
	
	lda music_chn_song_track+0
	bne _not_done_waiting
	
	ldx #AMT_MONSTERS-1
-
	lda monster_active
	and bitfield_mask_tbl,x
	beq +
	
	lda monsters_y,x
	cmp #$58
	bcc +
	cmp #$90
	bcs +
	
	lda monsters_x_hi,x
	bne +
	lda monsters_x_lo,x
	cmp #$70
	bcc +
	cmp #$e0
	bcc _not_done_waiting
	
+	
	dex
	bpl -
	
	jsr init_player
	
	dec men
	
	lda #STATUS_REDRAW_MEN
	ora status_redraw_flags
	sta status_redraw_flags
	
_not_done_waiting
	rts
	
_game_over
	
	;;;;; game over, just wait some time
	
	lda game_cnt
	and #3
	bne +
	inc angel_state
	lda angel_state
	cmp #$a0
	bne +
	lda #MODE_TITLE
	sta mode_init_flag
+	rts
	
	
	
	
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
render_player
	
	lda angel_state
	beq _no_render_angel
	cmp #ANGEL_STATE_WAITING
	bcs _no_render_anything
	
	lda #$28
	sta temp_sub
	lda #1
	sta temp_sub+1
	lda player_x+0
	ldy player_x+1
	;clc
	adc #4
	bcc +
	iny
+	ldx angel_y
	jsr add_maze_sprite
	
	ldx angel_anim_index
	lda angel_anim_tbl,x
	sta temp_sub
	
	lda player_x+0
	ldy player_x+1
	sec
	sbc #4
	bcs +
	dey
+	ldx angel_y
	jsr add_maze_sprite
	
	lda #$41
	sta temp_sub+1
	lda player_x+0
	ldy player_x+1
	clc
	adc #12
	bcc +
	iny
+	ldx angel_y
	jsr add_maze_sprite
	
_no_render_angel
	
	lda player_anim_index
	and #7
	tax
	lda player_anim_tbl,x
	sta temp_sub
	lda #$20
	ldy angel_state
	beq +
	lda #$00
+	sta temp_sub+1
	lda player_x+0
	ldy player_x+1
	ldx player_y
	jsr add_double_maze_sprite
	
_no_render_anything
	rts
	
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
set_angel_palette
	lda #ANGEL_COLOR_1
	sta palette_spr_1+0
	lda #ANGEL_COLOR_2
	sta palette_spr_1+1
	lda #ANGEL_COLOR_3
	sta palette_spr_1+2
	rts
	
	
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
player_anim_tbl	.byte $00,$04,$08,$0c,$10,$0c,$08,$04

angel_anim_tbl	.byte $20,$22,$24,$26,$24,$22



game_over_text_top	.text "  GAME  "[::-1]
game_over_text_bottom	.text "  OVER  "[::-1]


