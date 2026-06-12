#include <stdint.h>
#include <stdio.h>
#include <xbram.h>
#include <xbram_hw.h>
#include <xil_types.h>
#include <xparameters.h>
#include <xstatus.h>

#include "ZSD_card.h"
// #include "zynq_lcd_st7789.h" // custom driver

#include <sleep.h>
#include <stdint.h>
#include <xil_assert.h>
#include <xscutimer.h>

/************************** Constant Definitions *****************************/

/*
 * The following constants map to the XPAR parameters created in the
 * xparameters.h file. They are defined here such that a user can easily
 * change all the needed parameters in one place.
 */
#ifndef SDT
#define BRAM_DEVICE_ID XPAR_BRAM_0_DEVICE_ID
#else
#define BRAM_DEVICE_ID XPAR_XBRAM_0_BASEADDR
#endif

/************************** Function Prototypes ******************************/

/************************** Variable Definitions *****************************/

/*
 * The following are declared globally so they are zeroed and so they are
 * easily accessible from a debugger
 */
XBram Bram; /* The Instance of the BRAM Driver */

/****************************************************************************/
/**
 *
 * This function is the main function of the BRAM example.
 *
 * @param	None.
 *
 * @return
 *		- XST_SUCCESS to indicate success.
 *		- XST_FAILURE to indicate failure.
 *
 * @note		None.
 *
 *****************************************************************************/

static u32 image_pixels[300 * 300];

int main(void) {
  int Status;

  XBram_Config *ConfigPtr = XBram_LookupConfig(XPAR_XBRAM_0_BASEADDR);
  if (ConfigPtr == (XBram_Config *)NULL) {
    return XST_FAILURE;
  }

  Status = XBram_CfgInitialize(&Bram, ConfigPtr, ConfigPtr->CtrlBaseAddress);
  if (Status != XST_SUCCESS) {
    return XST_FAILURE;
  }

  UINTPTR base_address = (UINTPTR)XPAR_XBRAM_0_BASEADDR;

  printf("Mounting SD card...\n");

  char pwd[200];
  if (ZSD_init() != SD_OK) {
    printf("ERROR WITH SD CARD!\n");
    return 1;
  }
  printf("IN MAIN\n");
  ZSD_print_card_info();

  ZSD_get_current_dir(pwd, sizeof(pwd));
  printf("current directory is: %s\n", pwd);

  int x = ZSD_list_files(NULL);
  printf("File listing status: %d\n", x);
  printf("\n\n");

  x = ZSD_change_dir("Images");
  x = ZSD_list_files(NULL);
  UINT bytes_read = 0;
  x = ZSD_read_file("Images/raw_image.bin", (u8 *)image_pixels, 300 * 300 * 4,
                    &bytes_read);
  if (x != SD_OK) {
    printf("could not read image file on SD card\n");
    return 23;
  }
  printf("Read %d bytes from file on SD card\n", bytes_read);

  for (int y = 0; y < 300; y++) {
    for (int x = 0; x < 300; x++) {

      uint32_t colour =
          image_pixels[y * 300 + x]; // note the upper byte is always sliced off
                                     // here (rgb888)

      // if (x == 0 || x == 299 || y == 0 || y == 299) {
      //   colour = 0x00FFFFFF;
      // } else {
      //   colour = 0x00390E6E;
      // }

      // if (x == 0) {
      //   colour = 0x00FFFFFF;
      // } else if (x == 1 && y == 0) {
      //   colour = 0x00FF0000;
      // } else if (x == 2 && y == 0) {
      //   colour = 0x0000FF00;
      // } else if (x == 3 && y == 0) {
      //   colour = 0x000000FF;
      // } else {
      //   colour = 0x00390E6E;
      // }

      uint32_t addr = (y * 300 + x) << 2;

      XBram_WriteReg(base_address, addr, colour);
    }
  }

  // printf("Inspecting first 5 elements of BRAM:\n");
  // for (int i = 0; i < 5; i++) {
  //   uint32_t pixel = XBram_ReadReg(base_address, i * 4);
  //   printf("ADDRESS %d: %06x\n", i, pixel);
  // }

  xil_printf("End of main\r\n");
  while (1) {
  }
  return XST_SUCCESS;
}
