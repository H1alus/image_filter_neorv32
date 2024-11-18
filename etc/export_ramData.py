import numpy as np
from PIL import Image

with open("ram.txt", "r") as f:
    arr = np.array([int(x.strip(), 0) for x in f.readlines()], dtype=np.uint8)
Image.fromarray(arr.reshape((32, 32))).save("image_out.png")
