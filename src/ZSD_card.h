#ifndef ZSD_CARD_H
#define ZSD_CARD_H

/*
Library for using SD cards with the Smart Zynq SP board.
Built on top of FATfs file system layer
*/

#include <stdio.h>
#include <xsdps.h>
#include <stdbool.h>
#include <ff.h>
#include "xil_types.h"

#ifdef ZYNQ_LCD_ST7789_H
    #define USING_LCD = 1U
#else 
    #define USING_LCD = 0U
#endif

typedef enum {
    SD_OK = 0,
    SD_ERR_INIT,
    SD_ERR_MOUNT,
    SD_ERR_IO
} ZSD_RETURN_STATUS;

ZSD_RETURN_STATUS ZSD_init(void);
/*
path = NULL for pwd search
*/
ZSD_RETURN_STATUS ZSD_list_files(const char *path);
void ZSD_get_current_dir(char *out, size_t out_size);
bool ZSD_change_dir(const char *path);
ZSD_RETURN_STATUS ZSD_print_card_info(void);
ZSD_RETURN_STATUS ZSD_read_file(const char *path, u8 *buffer, UINT buf_size, UINT *bytes_read);
ZSD_RETURN_STATUS ZSD_write_file(const char *path, const u8 *data, size_t num_bytes);
bool ZSD_find_file(const char *path, const char *name);
ZSD_RETURN_STATUS ZSD_delete_file(const char *path);
#endif // ZSD_CARD_H
