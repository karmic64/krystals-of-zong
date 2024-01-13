#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <math.h>
#include <errno.h>



#define C64_PAL_CLOCK 985248.0
#define C64_NTSC_CLOCK 1022727.0

#define NES_NTSC_CLOCK 1789773.0
#define NES_PAL_CLOCK 1662607.0



#define SONGS 9
#define SONG_TBL_BASE 0x2dce



uint16_t data_base;
uint8_t data[0x800];

uint8_t * get_data_ptr(unsigned addr) {
	return &data[addr - data_base];
}

unsigned get_data(unsigned addr) {
	return data[addr - data_base];
}

unsigned get_data_16(unsigned addr) {
	return get_data(addr) | (get_data(addr+1) << 8);
}

unsigned get_data_16_big(unsigned addr) {
	return get_data(addr+1) | (get_data(addr) << 8);
}



uint8_t periods;
uint16_t period_tbl[0x80];




int main(int argc, char * argv[]) {
	if (argc != 3) {
		puts("usage: convert infile outfile");
		return EXIT_FAILURE;
	}
	const char * in_name = argv[1];
	const char * out_name = argv[2];
	
	FILE * f = NULL;
	
	
	/************************************************************************/
	f = fopen(in_name, "rb");
	if (!f) {
		printf("can't open %s: %s\n", in_name, strerror(errno));
		return EXIT_FAILURE;
	}
	data_base = fgetc(f) | (fgetc(f) << 8);
	fread(data, 1, 0x800, f);
	fclose(f);
	
	
	
	/*************************************************************************/
	f = fopen(out_name, "w");
	if (!f) {
		printf("can't open %s: %s\n", out_name, strerror(errno));
		return EXIT_FAILURE;
	}
	
	fprintf(f, "song_track_data_ptr_tbl_lo .byte ");
	for (unsigned i = 0; i < SONGS; i++) {
		fprintf(f, "<song_track_%u_data,", i);
	}
	fseek(f, -1, SEEK_CUR);
	fputc('\n', f);
	fprintf(f, "song_track_data_ptr_tbl_hi .byte ");
	for (unsigned i = 0; i < SONGS; i++) {
		fprintf(f, ">song_track_%u_data,", i);
	}
	fseek(f, -1, SEEK_CUR);
	fputc('\n', f);
	
	for (unsigned song = 0; song < SONGS; song++) {
		fprintf(f, "song_track_%u_data .byte ", song);
		
		unsigned song_data_base = get_data_16(SONG_TBL_BASE + (song * 8));
		uint8_t * p = get_data_ptr(song_data_base);
		
		unsigned prv_dur = -1;
		while (*p) {
			unsigned fv = p[2] | (p[1] << 8);
			double ff = fv * C64_PAL_CLOCK / 16777216.0;
			// for triangle
			unsigned fp = round(NES_NTSC_CLOCK / (16.0 * ff));
			
			unsigned fpi = 0;
			for ( ; fpi < periods; fpi++) {
				if (fp == period_tbl[fpi]) {
					break;
				}
			}
			if (fpi == periods) {
				period_tbl[periods++] = fp;
			}
			
			fpi++;
			if (*p != prv_dur) {
				fprintf(f,"$%02X,$%02X, ", fpi, *p);
				prv_dur = *p;
			} else {
				fprintf(f,"$%02X, ", fpi | 0x80);
			}
			
			p += 3;
		}
		fprintf(f, "$00\n");
	}
	
	fprintf(f, "period_tbl .word ");
	for (unsigned i = 0; i < periods; i++) {
		fprintf(f, "$%04X,", period_tbl[i]);
	}
	fseek(f, -1, SEEK_CUR);
	fputc('\n', f);
	
	fclose(f);
	
	
}
