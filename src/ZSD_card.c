#include "ZSD_card.h"
#include <ff.h>
#include <stdbool.h>
#include <stddef.h>
#include <string.h>
#include <xil_printf.h>
#include <xsdps.h>

/*******************************
        TYPEDEFS HERE
********************************/
#define ZSD_MAX_PATH 256U
#define ROOT_DIR "0:/"

/*******************************
  STATIC GLOBAL VARIABLES HERE
********************************/

static FATFS fs;
static XSdPs sd;
static XSdPs_Config *SD_cfg_ptr = NULL;

static bool had_init = false;
static char current_dir[ZSD_MAX_PATH] = ROOT_DIR; // root directory

/*******************************
    STATIC FUNCTIONS HERE
********************************/

/*******************************
    FUNCTION DEFINITIONS HERE
********************************/

ZSD_RETURN_STATUS ZSD_init(void) {
  if (had_init) {
    return SD_OK;
  }
  int status;

  SD_cfg_ptr = XSdPs_LookupConfig(XPAR_XSDPS_0_BASEADDR);
  if (SD_cfg_ptr == NULL)
    return SD_ERR_INIT;
  status = XSdPs_CfgInitialize(&sd, SD_cfg_ptr, SD_cfg_ptr->BaseAddress);
  if (status != XST_SUCCESS) {
    xil_printf("SD config init failed!\r\n");
    return SD_ERR_INIT;
  }

  status = XSdPs_CardInitialize(&sd);
  if (status != XST_SUCCESS) {
    xil_printf("Card init failed!\r\n");
    return SD_ERR_INIT;
  }
  FRESULT result = f_mount(&fs, ROOT_DIR, 1);
  if (result != FR_OK) {
    xil_printf("Failed to mount filesystem: %d\r\n", result);
    return SD_ERR_INIT;
  }
  had_init = true;
  return SD_OK;
}

ZSD_RETURN_STATUS ZSD_print_card_info(void) {
  if (!had_init) {
    return SD_ERR_INIT;
  }
  printf("SD card name is: %s\n", SD_cfg_ptr->Name);
  printf("SD card detect is: %lu\n", (unsigned long)SD_cfg_ptr->CardDetect);
  printf("SD card bank number is: %lu\n",
         (unsigned long)SD_cfg_ptr->BankNumber);
  printf("SD card base address is: %lu\n",
         (unsigned long)SD_cfg_ptr->BaseAddress);
  switch (sd.CardType) {
  case 0:
    printf("SD card type: SD\n");
    break;
  case 1:
    printf("SD card type: MMC\n");
    break;
  case 2:
    printf("SD card type: eMMC\n");
    break;
  default:
    printf("SD card type not known\n");
  }
  printf("High cappacity support: %s\n",
         sd.HCS ? "supported" : "not supported");
  printf("SD card block size (bytes): %lu\n", (unsigned long)sd.BlkSize);
  printf("SD card version: %hu\n", sd.Card_Version);
  printf("SD card sector count: %lu\n", (unsigned long)sd.SectorCount);
  printf("SD card size (MB): %lu\n",
         (unsigned long)sd.SectorCount / 2048); // assumes block size of 512
  printf("\n");
  return SD_OK;
}

ZSD_RETURN_STATUS ZSD_list_files(const char *path) {
  if (!had_init) {
    return SD_ERR_INIT;
  }
  if (path == NULL) {
    path = current_dir;
  }
  FILINFO fno;
  DIR dir;
  FRESULT res;
  res = f_opendir(&dir, path); // Open directory
  if (res == FR_OK) {
    // xil_printf("Directory opened: %s\r\n", path);
    for (;;) {
      res = f_readdir(&dir, &fno); // Read next entry
      if (res != FR_OK || fno.fname[0] == 0) {
        if (res != FR_OK) {
          printf("Error reading SD card: %d\n", res);
        }
        break; // End of directory
      }
      
      if (fno.fattrib & AM_DIR)
        printf("<DIR> %15s\r\n", fno.fname);
      else
        printf("<FILE>%15s size: %010lu\r\n", fno.fname, fno.fsize);
    }
    f_closedir(&dir);
    return SD_OK;
  } else {
    xil_printf("Failed to open directory. Error: %d\r\n", res);
    return SD_ERR_IO;
  }
}

void ZSD_get_current_dir(char *out, size_t out_size) {
  if (!had_init || !out) {
    return;
  }
  snprintf(out, out_size, "%s", current_dir);
}

bool ZSD_change_dir(const char *path) {
  if (!had_init)
    return false;

  char prev_dir[ZSD_MAX_PATH];
  snprintf(prev_dir, sizeof(prev_dir), "%s", current_dir);
  if (path[0] == '0' && path[1] == ':') // absolute
    snprintf(current_dir, sizeof(current_dir), "%s", path);

  // Handle special cases
  if (path == NULL || strcmp(path, "/") == 0) {
    snprintf(current_dir, sizeof(current_dir), "%s", ROOT_DIR);
  } else if (strcmp(path, "..") == 0) {
    size_t len = strlen(current_dir);
    if (len > 1) {
      // Strip trailing '/'
      if (current_dir[len - 1] == '/')
        current_dir[--len] = '\0';
      // Remove until previous '/'
      while (len > 0 && current_dir[len - 1] != '/')
        len--;
      current_dir[len] = '\0';
    }
    if (strlen(current_dir) == 0)
      strcpy(current_dir, ROOT_DIR);
  } else {
    // Normal directory change
    if (snprintf(current_dir, sizeof(current_dir), "%s%s%s", prev_dir,
                 (prev_dir[strlen(prev_dir) - 1] == '/' ? "" : "/"),
                 path) >= (int)sizeof(current_dir)) {
      xil_printf("Path too long.\r\n");
      strcpy(current_dir, prev_dir);
      return false;
    }
  }

  // Ensure ends with '/'
  size_t len = strlen(current_dir);
  if (current_dir[len - 1] != '/') {
    if (len + 1 < sizeof(current_dir)) {
      current_dir[len] = '/';
      current_dir[len + 1] = '\0';
    } else {
      xil_printf("Path too long.\r\n");
      strcpy(current_dir, prev_dir);
      return false;
    }
  }

  // Test if directory exists
  DIR dir;
  FRESULT res = f_opendir(&dir, current_dir);
  if (res != FR_OK) {
    xil_printf("Could not cd into directory: %s (error %d)\r\n", current_dir,
               res);
    strcpy(current_dir, prev_dir);
    return false;
  }
  f_closedir(&dir);
  return true;
}

ZSD_RETURN_STATUS ZSD_write_file(const char *path, const u8 *data,
                                 size_t num_bytes) {
  if (!had_init) {
    return SD_ERR_INIT;
  }
  if (path == NULL) {
    path = current_dir;
  }

  if (!had_init)
    return SD_ERR_INIT;
  FIL file;
  FRESULT res;
  UINT written;
  res = f_open(&file, path, FA_WRITE | FA_CREATE_ALWAYS);
  if (res != FR_OK)
    return SD_ERR_IO;

  res = f_write(&file, data, num_bytes, &written);
  f_close(&file);
  return (res == FR_OK && written > 0) ? SD_OK : SD_ERR_IO;
}

bool ZSD_find_file(const char *path, const char *name) {
  if (!had_init) {
    return false;
  }
  if (path == NULL) {
    path = current_dir;
  }
  char full_path[ZSD_MAX_PATH];
  strcpy(full_path, path);
  strcat(full_path, name);

  FIL fp;
  int status = f_open(&fp, full_path, FA_READ);
  if (status == FR_OK) {
    f_close(&fp);
    return true;
  } else {
    return false;
  }
}

ZSD_RETURN_STATUS ZSD_delete_file(const char *path) {
  if (!had_init) {
    return SD_ERR_INIT;
  }
  if (path == NULL) {
    return SD_ERR_IO;
  }
  int status;
  status = f_unlink(path);
  return (status == FR_OK);
}

ZSD_RETURN_STATUS ZSD_delete_dir(const char *dir) {
  if (!had_init) {
    return SD_ERR_INIT;
  }
  if (dir == NULL) {
    return SD_ERR_IO;
  }
  int status;
  status = f_unlink(dir);
  return (status == FR_OK);
}

ZSD_RETURN_STATUS ZSD_read_file(const char *path, u8 *buffer, UINT buf_size,
                                UINT *bytes_read) {
  if (!had_init) {
    return SD_ERR_INIT;
  }
  if (buffer == NULL || buf_size == 0 || path == NULL || bytes_read == NULL) {
    return SD_ERR_IO;
  }
  int status;
  FIL fp;
  status = f_open(&fp, path, FA_READ);
  if (status != FR_OK) {
    *bytes_read = 0;
    return SD_ERR_IO;
  }
  status = f_read(&fp, (void *)buffer, buf_size, bytes_read);
  if (status != FR_OK) {
    *bytes_read = 0;
    return SD_ERR_IO;
  }
  f_close(&fp);
  return SD_OK;
}
