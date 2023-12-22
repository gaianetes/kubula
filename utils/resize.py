#!/Users/mitchellmurphy/.pyenv/shims/python

from PIL import Image

# read image
image = Image.open("media/logo.png")
# resize
new_image = image.resize((600, 600))
# save image
new_image.save("logo-scaled.png")
