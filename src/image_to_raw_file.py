import cv2
import numpy as np
import shutil
import os

SD_CARD_PATH : str = "E:/Images"

if __name__ == "__main__":
    WIDTH = 300
    HEIGHT = 300

    IMAGE_TO_DECODE : str = "rat_chilling.jpg"
    img = cv2.imread(IMAGE_TO_DECODE)

    if img is None:
        raise RuntimeError("Failed to load image")

    if not os.path.exists(SD_CARD_PATH):
        raise RuntimeError("SD card path not found. Check if SD card is connected to PC")
    # Resize first
    img = cv2.resize(img, (WIDTH, HEIGHT))

    # BGR -> RGB
    img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

    raw_pixel_arr = np.zeros(WIDTH * HEIGHT, dtype=np.uint32)

    idx = 0

    for y in range(HEIGHT):
        for x in range(WIDTH):

            r, g, b = img[y, x]

            # Pack into 0x00RRGGBB
            word = (int(r) << 16) | (int(g) << 8) | int(b)

            raw_pixel_arr[idx] = word

            # if idx < 10:
            #     print(
            #         f"PIXEL {idx}: "
            #         f"R={r} G={g} B={b} "
            #         f"PACKED=0x{word:08X}"
            #     )

            idx += 1
    RAW_FILE_NAME : str = "raw_image.bin"

    # Write raw binary
    raw_pixel_arr.tofile(RAW_FILE_NAME)
    shutil.copy("raw_image.bin", SD_CARD_PATH)
    print(f"Binary image ({IMAGE_TO_DECODE}) written and saved to SD card at path: {SD_CARD_PATH} as {RAW_FILE_NAME}.")