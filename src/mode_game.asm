	
	
	#define_mode GAME, mode_game.init  ;initialize entire game
	#define_mode GAME_LEVEL, mode_game.init_level  ;initialize new level
	#define_mode GAME_ROOM, mode_game.init_room  ;initialize new room
	#define_mode GAME_MAIN, mode_game.main  ;main procedure
	
	
	
	
mode_game	.block


	#define_zp_vars game
	#define_vars game


	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; global game vars
	.section zp_vars_global

level	.byte ?

men	.byte ?

score	.fill 3
hiscore	.fill 3


	.send
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; game vars
	
	.section zp_vars_game
	
game_cnt	.word ?
	
	;bit 7 - demo mode
	;bit 1 - teleport mode
	;bit 0 - game paused
demo_mode	.byte ?

oam_index	.byte ?
	
	.send
	
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
INITIAL_OAM_INDEX = $40
	
DIRECTION_UP = 0
DIRECTION_DOWN = 1
DIRECTION_LEFT = 2
DIRECTION_RIGHT = 3
	
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; global game init
	
init
	
	lda #5
	sta men
	lda #0
	sta level
	sta score+0
	sta score+1
	sta score+2
	
	inc mode
	rts
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; level init
	
init_level
	
	;;;;;;;;;;;;;;; init mazes
	
	ldx #AMT_MAZES-1
-	jsr set_maze_ptr
	jsr init_maze
	ldx maze
	dex
	bpl -
	
	
	;;;;;;;;;;;;;;; init objects
	
	jsr init_player
	jsr init_monsters
	jsr init_treasures
	
	;;;;;;;;;;;;;;; ready
	
	ldx #4
	jsr set_maze_ptr
	
	inc mode
	rts
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; room/display init
	
init_room
	
	
	;;;;;;;;;;;;;;;;; game per-maze init
	
	jsr init_player_maze
	jsr init_monsters_maze
	jsr init_treasures_maze
	
	;;;;;;;;;;;;;;; drawing
	
	lda #' '
	ldx #0
	jsr fill_both_nametables
	
	jsr draw_status_bar
	
	jsr draw_maze
	jsr draw_treasures
	
	;;;;;;;;;;;;;;;; misc ppu setup
	
	;; 8/8 sprites so anything going into the status bar is hidden
	;; sprite 0 MUST always be on because of the sprite 0 hit
	
	ldx #0
-	
	lda #$3e
	sta OAM+$01,x
	sta OAM+$21,x
	lda #$20
	sta OAM+$02,x
	sta OAM+$22,x
	lda #$00
	sta OAM+$03,x
	sta OAM+$23,x
	inx
	inx
	inx
	inx
	cpx #$20
	bcc -
	
	lda #SPRITE_Y_BASE - $10
	sta OAM+$00
	jsr move_status_bar_sprites_bottom
	lda #SPRITE_Y_BASE - $20
	jsr move_status_bar_sprites_top
	
	lda #INITIAL_OAM_INDEX
	sta oam_index
	
	lda #$e8
	sta ppuscroll_y
	
	inc mode
	rts
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; main procedure
	
main
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; demo mode quitting/pausing
	
	lda demo_mode  ;quit demo if start/select
	bpl _not_demo
	lda joy
	and #$30
	beq _no_demo_pausing
	lda #MODE_TITLE
	sta mode_init_flag
	gpl _no_demo_pausing
	
_not_demo
	lda joy  ;pause/unpause if start
	and #$10
	beq _no_pausing
	lda demo_mode
	eor #1
	cmp #2
	bne +
	lda treasure_effects
	and #~TREASURE_EFFECT_TELEPORT
	sta treasure_effects
	lda #0
+	sta demo_mode
	jmp _after_pause
	
_no_pausing
	lda demo_mode  ;teleport if select
	cmp #1
	beq _no_teleport
	lda treasure_effects
	and #TREASURE_EFFECT_TELEPORT
	beq _no_teleport
	lda joy
	and #$20
	beq _no_teleport
	
	lda #3
	sta demo_mode
	ldx maze
	inx
	cpx #AMT_MAZES
	bcc +
	ldx #0
+	jsr set_maze_ptr
	
	lda #$80
	sta monster_introducing
	lda #MODE_GAME_ROOM
	sta mode_init_flag
	
_no_teleport
	
_after_pause
	
_no_demo_pausing
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; scrolling sprite 0 hit
	
	lda ppumask
	cmp #$1e
	bne +
	
-	bit $2002
	bvs -
-	bit $2002
	bvc -
	
	lda maze_x_scroll
	sta $2005
	sta $2005
	
+	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; game logic
	
	lda demo_mode
	lsr
	bcs _is_paused
	
	jsr handle_player
	jsr handle_monsters
	jsr handle_treasures
	
	inc game_cnt+0
	bne +
	inc game_cnt+1
+	
	
_is_paused
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; rendering
	
	lda #$ef
	.for i = INITIAL_OAM_INDEX, i < $100, i=i+4
		sta OAM + i
	.next
	
	jsr set_maze_x_scroll_around_player
	jsr render_status_bar
	
	jsr render_player
	jsr render_monsters
	jsr render_treasures
	
	lda #$1e
	sta ppumask
	
	rts
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

direction_horz_tbl	.char 0,0 ;,-1,1
direction_vert_tbl	.char -1,1,0,0
	
	
	
	
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; includes
	
	.include "game/maze.asm"
	.include "game/status_bar.asm"
	.include "game/player.asm"
	.include "game/monsters.asm"
	.include "game/treasures.asm"
	
	
	
	
	
	
	
	.bend
	