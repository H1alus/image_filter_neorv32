from PIL import Image
image = Image.open("peperoni.png").convert("L")
pixels = list(image.getdata())
with open("inputfile.txt", "w") as f:
    [f.write(f"{pixel:08X}\n") for pixel in pixels]
