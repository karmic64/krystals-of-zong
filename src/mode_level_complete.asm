
	#define_mode LEVEL_COMPLETE, mode_level_complete.init
	#define_mode LEVEL_COMPLETE_MAIN, mode_level_complete.main
	
	
mode_level_complete	.block
	
	
	
init
	
	jsr init_text_screen
	
	lda #<text_list
	ldx #>text_list
	jsr upload_ppu_list
	
	lda mode_game.score+0
	ldx mode_game.score+1
	ldy mode_game.score+2
	jsr hex_to_bcd_24
	lda #>$20e2 + len("score ")
	ldx #<$20e2 + len("score ")
	jsr queue_render_bcd_24
	
	lda #>$2142 + len("level ")
	ldx #<$2142 + len("level ")
	ldy mode_game.level
	iny
	jsr queue_render_single_number
	
	lda #>$2182 + len("now entering level ")
	ldx #<$2182 + len("now entering level ")
	ldy mode_game.level
	cpy #7
	beq +
	iny
	sty mode_game.level
+	iny
	jsr queue_render_single_number
	
	lda #>$21c2 + len("can you ")
	ldx #<$21c2 + len("can you ")
	jsr queue_ppu_addr
	lda mode_game.level
	and #3
	tax
	lda challenge_index_tbl,x
	tax
	lda challenges,x
	sta temp
	clc
	adc #2
	jsr queue_fastcopy_bytes
-	inx
	lda challenges,x
	sta NMI_TASK_BUF,y
	iny
	dec temp
	bne -
	lda #' '
	sta NMI_TASK_BUF,y
	iny
	lda #'?'
	sta NMI_TASK_BUF,y
	iny
	sty nmi_task_buf_index
	
	
	lda #SONG_BABY_ELEPHANT_WALK
	sta music_init_flag
	
	inc mode
	rts
	
	
main
	
	lda #$0a
	sta ppumask
	
	lda joy
	and #$10
	beq +
	lda #MODE_GAME_LEVEL
	sta mode_init_flag
+	
	
	rts
	
	
	
text_list
	#ppu_string $20e2, "score"
	#ppu_string $2142, "level   completed"
	#ppu_string $2182, "now entering level"
	#ppu_string $21c2, "can you"
	#ppu_string $2222, "press start to begin"
	#ppu_string $237a, x"c9c6cac6"
	.byte $ff
	
	
	
	
CHALLENGE_PTRS = [challenge_1,challenge_2,challenge_3,challenge_4]
challenge_index_tbl	.byte CHALLENGE_PTRS - challenges

challenges
challenge_1	#pascal_string "subdue the snakes"
challenge_2	#pascal_string "beat the bats"
challenge_3	#pascal_string "survive the spiders"
challenge_4	#pascal_string "master the mummies"
	
	.bend