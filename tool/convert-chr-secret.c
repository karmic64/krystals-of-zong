#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <errno.h>

#include "image.h"


#define MAP_WIDTH 0x10
#define MAP_HEIGHT 0x0a

#define TILE_WIDTH 8
#define TILE_HEIGHT 8
#define TILE_BITPLANES 2


int main(int argc, char * argv[]) {
	if (argc != 3) {
		puts("usage: convert-chr-secret inpng outchr");
		return EXIT_FAILURE;
	}
	const char * png_name = argv[1];
	const char * chr_name = argv[2];
	
	/***************************************************/
	image_t i;
	if (read_image_from_png(&i, png_name)) {
		return EXIT_FAILURE;
	}
	
	/***************************************************/
	uint8_t c[MAP_HEIGHT][MAP_WIDTH][TILE_BITPLANES][TILE_HEIGHT];
	memset(&c, 0, sizeof(c));
	FILE * f = fopen(chr_name, "wb");
	if (!f) {
		printf("can't open %s: %s\n",chr_name,strerror(errno));
		return EXIT_FAILURE;
	}
	for (unsigned ym = 0; ym < MAP_HEIGHT; ym++) {
		for (unsigned xm = 0; xm < MAP_WIDTH; xm++) {
			for (unsigned yt = 0; yt < TILE_HEIGHT; yt++) {
				for (unsigned xt = 0; xt < TILE_WIDTH; xt++) {
					unsigned x = (xm * TILE_WIDTH) + xt;
					unsigned y = (ym * TILE_HEIGHT) + yt;
					unsigned b = get_image_pixel(&i, x, y);
					for (unsigned bpl = 0; bpl < TILE_BITPLANES; bpl++) {
						if (b & (1 << bpl)) {
							c[ym][xm][bpl][yt] |= 0x80 >> xt;
						}
					}
				}
			}
		}
	}
	fwrite(&c, 1, sizeof(c), f);
	fclose(f);
	
}
