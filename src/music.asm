
	.virtual $f0
	
	; $00 = not playing
	; $01-$7f = playing song track $xx
	; $80 = stop channel
	; $81-$ff = init song track $xx
music_chn_song_track	.byte ?
music_chn_dur	.byte ?
music_chn_dur_save	.byte ?
music_chn_index	.byte ?
	.fill 4*2
	
	
music_temp	.fill 2
	
	; $00 - nothing/playing song $xx
	; $80 - stop all tracks
	; $81-$ff - init song $xx
music_init_flag	.byte ?
sfx_init_flag	.byte ?
	.endv
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
music_reset
	lda #$c0
	sta $4017
	ldx #7
	stx $4015
	inx
	stx $4001
	stx $4005
-	jsr music_stop_chn
	dex
	dex
	dex
	dex
	bne -
	
	stx music_init_flag
	stx sfx_init_flag
	
	
music_stop_chn
	lda #0
	sta music_chn_song_track,x
music_mute_chn
	lda #$30
	cpx #8
	bne +
	lda #$80
+	sta $4000,x
music_ret
	rts
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
music_init
	tay
	lda song_tbl_0,y
	bpl +
	sta music_chn_song_track+0
+	lda song_tbl_1,y
	bpl +
	sta music_chn_song_track+4
+	lda song_tbl_2,y
	bpl +
	sta music_chn_song_track+8
+	rts
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	
music_play
	
	lda music_init_flag
	bpl _no_song_init
	and #$7f
	sta music_init_flag
	jsr music_init
_no_song_init
	
	lda sfx_init_flag
	bpl _no_sfx_init
	and #$7f
	sta sfx_init_flag
	jsr music_init
_no_sfx_init
	
	
	;;;;;;;;;;;;;;;;;;;;
	
	
	ldx #8
-	jsr +
	dex
	dex
	dex
	dex
	bne -
+	
	ldy music_chn_song_track,x
	beq music_ret
	bpl _no_song_track_init
	tya
	and #$7f
	sta music_chn_song_track,x
	beq music_mute_chn
	tay
	lda song_track_4000_tbl - 1,y
	sta $4000,x
	lda #0
	sta music_chn_index,x
	geq _chn_read_music_data
_no_song_track_init
	
	dec music_chn_dur,x
	bne music_ret
	
_chn_read_music_data
	lda song_track_data_ptr_tbl_lo - 1,y
	sta music_temp + 0
	lda song_track_data_ptr_tbl_hi - 1,y
	sta music_temp + 1
	
	ldy music_chn_index,x
	lda (music_temp),y
	beq music_stop_chn
	asl
	tay
	cpx #8
	bne _not_triangle
	ldx music_chn_song_track + 8
	lda period_tbl - 1,y
	lsr
	ora song_track_4003_tbl - 1,x
	sta $4003 + 8
	lda period_tbl - 2,y
	ror
	sta $4002 + 8
	ldx #8
	gne _done_freq
	
_not_triangle
	lda period_tbl - 2,y
	sta $4002,x
	lda period_tbl - 1,y
	ldy music_chn_song_track,x
	ora song_track_4003_tbl - 1,y
	sta $4003,x
_done_freq
	
	ldy music_chn_index,x
	lda (music_temp),y
	bmi +
	iny
	lda (music_temp),y
	sta music_chn_dur_save,x
+	lda music_chn_dur_save,x
	sta music_chn_dur,x
	
	iny
	sty music_chn_index,x
	rts
	
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	
SONG_STOP = $80
SONG_CHARGE = $81
SONG_AMAZING_GRACE = $82
SONG_BABY_ELEPHANT_WALK = $83
SONG_LIGHT_MY_FIRE = $84
SONG_RICH_MAN = $85
SONG_RAISING = $86
SONG_BLIPPING = $87
	
	
SONG_TRACKS_STOP = [$80,$80,$80]
SONG_TRACKS_CHARGE = [$00,$81,$00]
SONG_TRACKS_AMAZING_GRACE = [$82,$00,$82]
SONG_TRACKS_BABY_ELEPHANT_WALK = [$83,$00,$84]
SONG_TRACKS_LIGHT_MY_FIRE = [$85,$00,$86]
SONG_TRACKS_RICH_MAN = [$00,$87,$00]
SONG_TRACKS_RAISING = [$00,$88,$00]
SONG_TRACKS_BLIPPING = [$00,$89,$00]

SONG_TRACKS_TBL = [SONG_TRACKS_STOP,SONG_TRACKS_CHARGE,SONG_TRACKS_AMAZING_GRACE,SONG_TRACKS_BABY_ELEPHANT_WALK,SONG_TRACKS_LIGHT_MY_FIRE,SONG_TRACKS_RICH_MAN,SONG_TRACKS_RAISING,SONG_TRACKS_BLIPPING]
	
	
SONGS = len(SONG_TRACKS_TBL)
	
song_tbl_0	.for i = 0, i < SONGS, i=i+1
		.byte SONG_TRACKS_TBL[i][0]
	.next
song_tbl_1	.for i = 0, i < SONGS, i=i+1
		.byte SONG_TRACKS_TBL[i][1]
	.next
song_tbl_2	.for i = 0, i < SONGS, i=i+1
		.byte SONG_TRACKS_TBL[i][2]
	.next
	


song_track_4000_tbl
	.byte $3f ;charge jingle
	.byte $8b ;amazing grace
	.byte $bf ;baby elephant walk lead
	.byte $ff ;baby elephant walk bass
	.byte $bf ;light my fire lead
	.byte $ff ;light my fire bass
	.byte $7f ;if i were a rich man
	.byte $5f ;raising
	.byte $7f ;blipping

song_track_4003_tbl
	.byte $08 ;charge jingle
	.byte $08 ;amazing grace
	.byte $08 ;baby elephant walk lead
	.byte $08 ;baby elephant walk bass
	.byte $08 ;light my fire lead
	.byte $08 ;light my fire bass
	.byte $08 ;if i were a rich man
	.byte $18 ;raising
	.byte $08 ;blipping

	
	.include "gen/music-data.asm"
	
	