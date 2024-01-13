// Image-related defines.

#pragma once

#include <stdlib.h>
#include <stdio.h>
#include <setjmp.h>

#include <png.h>


/************************ image struct *****************************/

typedef struct {
	png_uint_32 width;
	png_uint_32 height;
	png_uint_32 stride;
	int bit_depth;
	int color_type;
	
	int palette_size;
	png_color * palette;
	
	png_byte * data;
	png_byte ** rows;
} image_t;

void init_image(image_t * i) {
	if (i->palette_size) {
		i->palette = malloc(i->palette_size * sizeof(*i->palette));
	}
	
	i->data = malloc(i->height * i->stride);
	
	i->rows = malloc(i->height * sizeof(*i->rows));
	for (unsigned y = 0; y < i->height; y++) {
		i->rows[y] = i->data + (y * i->stride);
	}
}

void free_image(image_t * i) {
	if (i->palette_size && i->palette) {
		free(i->palette);
	}
	if (i->data) free(i->data);
	if (i->rows) free(i->rows);
}



/************************** reading ******************************/

int read_image_from_png(image_t * i, const char * png_name) {
	FILE * f = fopen(png_name, "rb");
	if (!f) {
		printf("can't open %s: %s\n", png_name,strerror(errno));
		return 1;
	}
	png_structp png_ptr = png_create_read_struct(
		PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
	if (!png_ptr) {
		fclose(f);
		puts("can't create png struct");
		return 1;
	}
	png_infop info_ptr = png_create_info_struct(png_ptr);
	if (!info_ptr) {
		png_destroy_read_struct(&png_ptr, NULL, NULL);
		fclose(f);
		puts("can't create png info struct");
		return 1;
	}
	
	if (setjmp(png_jmpbuf(png_ptr))) {
		png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
		fclose(f);
		return 1;
	}
	png_init_io(png_ptr,f);
	png_read_info(png_ptr,info_ptr);
	png_get_IHDR(png_ptr,info_ptr,
		&i->width, &i->height,
		&i->bit_depth, &i->color_type, NULL,
		NULL,NULL);
	i->stride = png_get_rowbytes(png_ptr,info_ptr);
	png_color * palette = NULL;
	png_get_PLTE(png_ptr,info_ptr,&palette,&i->palette_size);
	
	init_image(i);
	memcpy(i->palette, palette, i->palette_size * sizeof(*i->palette));
	png_read_image(png_ptr,i->rows);
	
	png_read_end(png_ptr,NULL);
	png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
	fclose(f);
	return 0;
}


unsigned get_image_pixel(image_t * i, unsigned x, unsigned y) {
	size_t xx = x;
	unsigned xm = 0xff;
	unsigned xms = 0;
	unsigned bs = 0;
	switch (i->bit_depth) {
		case 1:
			xx = x / 8;
			xm = 0x80;
			xms = x & 7;
			bs = xms ^ 7;
			break;
		case 2:
			xx = x / 4;
			xm = 0xc0;
			xms = (x & 3) * 2;
			bs = xms ^ 6;
			break;
		case 4:
			xx = x / 2;
			xm = 0xf0;
			xms = (x & 1) * 4;
			bs = xms ^ 8;
			break;
	}
	return (i->rows[y][xx] & (xm >> xms)) >> bs;
}




/************************* writing *******************************/

int write_image_to_png(image_t * i, const char * png_name) {
	FILE * f = fopen(png_name, "wb");
	if (!f) {
		printf("can't open %s: %s\n", png_name,strerror(errno));
		return 1;
	}
	png_structp png_ptr = png_create_write_struct(
		PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
	if (!png_ptr) {
		fclose(f);
		puts("can't create png struct");
		return 1;
	}
	png_infop info_ptr = png_create_info_struct(png_ptr);
	if (!info_ptr) {
		png_destroy_write_struct(&png_ptr, NULL);
		fclose(f);
		puts("can't create png info struct");
		return 1;
	}
	
	if (setjmp(png_jmpbuf(png_ptr))) {
		png_destroy_write_struct(&png_ptr, &info_ptr);
		fclose(f);
		return 1;
	}
	png_init_io(png_ptr,f);
	png_set_IHDR(png_ptr,info_ptr,i->width,i->height,
		i->bit_depth,i->color_type,PNG_INTERLACE_NONE,
		PNG_COMPRESSION_TYPE_DEFAULT,PNG_FILTER_TYPE_DEFAULT);
	if (i->palette_size) {
		png_set_PLTE(png_ptr,info_ptr,i->palette,i->palette_size);
	}
	png_set_rows(png_ptr,info_ptr,i->rows);
	png_write_png(png_ptr,info_ptr,PNG_TRANSFORM_IDENTITY,NULL);
	
	png_destroy_write_struct(&png_ptr, &info_ptr);
	fclose(f);
	return 0;
}
