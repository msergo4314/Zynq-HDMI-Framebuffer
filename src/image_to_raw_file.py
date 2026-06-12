import cv2
import numpy as np
import shutil
import os

SD_CARD_PATH : str = "E:/Images"
TEST_PATTERN : str = "border"
IMAGE_TO_DECODE : str = "rat_chilling.jpg"

if __name__ == "__main__":
    WIDTH = 300
    HEIGHT = 300

    if not os.path.exists(SD_CARD_PATH):
        raise RuntimeError("SD card path not found. Check if SD card is connected to PC")

    raw_pixel_arr : list[np.uint32] = np.zeros(WIDTH * HEIGHT, dtype=np.uint32)

    idx : int = 0

    if TEST_PATTERN == "image":
        img = cv2.imread(IMAGE_TO_DECODE)

        if img is None:
            raise RuntimeError("Failed to load image")
        
        # Resize first
        img = cv2.resize(img, (WIDTH, HEIGHT))

        # BGR -> RGB
        img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        for y in range(HEIGHT):
            for x in range(WIDTH):

                r, g, b = img[y, x]

                # Pack into 0x00RRGGBB
                word = (int(r) << 16) | (int(g) << 8) | int(b)

                raw_pixel_arr[idx] = word
        print(f"Binary image ({IMAGE_TO_DECODE}) written and saved to SD card at path: {SD_CARD_PATH} as {RAW_FILE_NAME}.")
    elif TEST_PATTERN == "border":
        for y in range(HEIGHT):
            for x in range(WIDTH):

                if x == 0 or x == WIDTH - 1 or y == 0 or y == HEIGHT - 1:
                    word = 0x00FFFFFF   # white
                else:
                    word = 0x00000000   # black

                raw_pixel_arr[idx] = word
                idx += 1
    elif TEST_PATTERN == "corners":
        for y in range(HEIGHT):
            for x in range(WIDTH):

                word = 0x00000000

                if x == 0 and y == 0:
                    word = 0x00FFFFFF    # white

                elif x == WIDTH-1 and y == 0:
                    word = 0x00FF0000    # red

                elif x == 0 and y == HEIGHT-1:
                    word = 0x0000FF00    # green

                elif x == WIDTH-1 and y == HEIGHT-1:
                    word = 0x000000FF    # blue

                raw_pixel_arr[idx] = word
                idx += 1
    elif TEST_PATTERN == "checkerboard":
        for y in range(HEIGHT):
            for x in range(WIDTH):

                if (x + y) % 2 == 0:
                    word = 0x00FFFFFF
                else:
                    word = 0x00000000

                raw_pixel_arr[idx] = word
                idx += 1
    else:
        print(f'Configuration string "TEST_PATTERN" is an invalid string literal ({TEST_PATTERN})')
        raise RuntimeError

    RAW_FILE_NAME : str = "raw_image.bin"

    # Write raw binary
    raw_pixel_arr.tofile(RAW_FILE_NAME)
    shutil.copy("raw_image.bin", SD_CARD_PATH)