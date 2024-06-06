#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include "bmp_header.h"
#include "f.h"

typedef struct {
    int32_t width;
    int32_t height;
    uint16_t bitCount;
    uint8_t *data;
} BMPImage;

uint8_t* readBMP(const char *filename, BMPImage *image) {
    FILE *file = fopen(filename, "rb");
    if (!file) {
        fprintf(stderr, "Error: Could not open file %s\n", filename);
        return NULL;
    }

    BITMAPFILEHEADER fileHeader;
    fread(&fileHeader, sizeof(BITMAPFILEHEADER), 1, file);
    if (fileHeader.bfType != 0x4D42) { // 'BM' in little-endian
        fprintf(stderr, "Error: Not a valid BMP file\n");
        fclose(file);
        return NULL;
    }

    BITMAPINFOHEADER infoHeader;
    fread(&infoHeader, sizeof(BITMAPINFOHEADER), 1, file);

    image->width = infoHeader.biWidth;
    image->height = infoHeader.biHeight;
    image->bitCount = infoHeader.biBitCount;

    uint32_t dataSize = infoHeader.biSizeImage;
    if (dataSize == 0) {
        dataSize = infoHeader.biWidth * infoHeader.biHeight * (infoHeader.biBitCount / 8);
    }
    image->data = (uint8_t *)malloc(dataSize);
    if (!image->data) {
        fprintf(stderr, "Error: Could not allocate memory for pixel data\n");
        fclose(file);
        return NULL;
    }

    fseek(file, fileHeader.bfOffBits, SEEK_SET);
    fread(image->data, dataSize, 1, file);

    fclose(file);
    return image->data;
}

BMPImage copyBMPImage(const BMPImage *src) {
    BMPImage dest;

    dest.width = src->width;
    dest.height = src->height;
    dest.bitCount = src->bitCount;

    uint32_t dataSize = src->width * src->height * (src->bitCount / 8);
    dest.data = (uint8_t *)malloc(dataSize);
    if (!dest.data) {
        fprintf(stderr, "Error: Could not allocate memory for pixel data\n");
        // In case of failure, set data to NULL
        dest.data = NULL;
        return dest;
    }

    memcpy(dest.data, src->data, dataSize);

    return dest;
}

int writeBMP(const char *filename, const BMPImage *image) {
    FILE *file = fopen(filename, "wb");
    if (!file) {
        fprintf(stderr, "Error: Could not open file %s for writing\n", filename);
        return 1;
    }

    BITMAPFILEHEADER fileHeader;
    BITMAPINFOHEADER infoHeader;

    // Fill in the file header
    fileHeader.bfType = 0x4D42; // 'BM' in little-endian
    fileHeader.bfSize = sizeof(BITMAPFILEHEADER) + sizeof(BITMAPINFOHEADER) + image->width * image->height * (image->bitCount / 8);
    fileHeader.bfReserved1 = 0;
    fileHeader.bfReserved2 = 0;
    fileHeader.bfOffBits = sizeof(BITMAPFILEHEADER) + sizeof(BITMAPINFOHEADER);

    // Fill in the info header
    infoHeader.biSize = sizeof(BITMAPINFOHEADER);
    infoHeader.biWidth = image->width;
    infoHeader.biHeight = image->height;
    infoHeader.biPlanes = 1;
    infoHeader.biBitCount = image->bitCount;
    infoHeader.biCompression = 0;
    infoHeader.biSizeImage = image->width * image->height * (image->bitCount / 8);
    infoHeader.biXPelsPerMeter = 0;
    infoHeader.biYPelsPerMeter = 0;
    infoHeader.biClrUsed = 0;
    infoHeader.biClrImportant = 0;

    fwrite(&fileHeader, sizeof(BITMAPFILEHEADER), 1, file);
    fwrite(&infoHeader, sizeof(BITMAPINFOHEADER), 1, file);
    fwrite(image->data, infoHeader.biSizeImage, 1, file);

    fclose(file);
    return 0;
}

int main(int argc, char *argv[]) {
    if (argc != 3) {
        fprintf(stderr, "Usage: %s <bmp_file1> <bmp_file2>\n", argv[0]);
        return 1;
    }

    BMPImage image1, image2;

    if (!readBMP(argv[1], &image1)) {
        return 1;
    }

    if (!readBMP(argv[2], &image2)) {
        free(image1.data);  // Clean up allocated memory for the first image if the second fails
        return 1;
    }

    BMPImage result = copyBMPImage(&image1);
    if (!result.data) {
        free(image1.data);
        free(image2.data);
        return 1;
    }

    char input = 'y';
    int32_t x = 50;
    int32_t y = 50;
    while(input == 'y') {
        printf("Set x (0-100): ");
        scanf("%d", &x);
        x = image1.width / 100 * x;
        printf("Set y (0-100): ");
        scanf("%d", &y);
        y = image1.height / 100 * y;

        f(image1.data, image2.data, result.data, image1.width, image1.height,
            image2.width, image2.height, x, y);

        if (writeBMP("result.bmp", &result) != 0) {
            fprintf(stderr, "Error: Could not write BMP file\n");
            free(image1.data);
            free(image2.data);
            return 1;
        }

        result = copyBMPImage(&image1);
        if (!result.data) {
            free(image1.data);
            free(image2.data);
            return 1;
        }

        printf("Blending completed.\nRun the program again (y/n)? ");
        scanf(" %c", &input);
    }

    // Clean up
    free(image1.data);
    free(image2.data);

    return 0;
}
