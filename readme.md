## Loving 2BPP
This is a small library for Love2D to render 2BPP data into the ImageData format for whatever you want to do with it.
Included with this library is:

 - An example of 2bpp graphics
 - A **Very Cursed Method** to read the data.
### Using Loving 2BPP
```lua
-- Require the library
local loving_2bpp =  require("loving2bpp")
-- Read in the file
loving_2bpp.read("2bpp.txt")
-- Choose a tile or a page to render
-- Page example
local page = love.graphics.newImage(loving_2bpp.render_page(1))

-- Tile Example
local tile = love.graphics.newImage(loving_2bpp.convert_tile(1))

-- Then, once done you can draw it like a normal image/split it with quads/etc
function  love.draw()
love.graphics.print("This is so cursed.")
love.graphics.draw(tile, 20, 20, 0, 4, 4)
end
```

### Config
Change the values directly:
```lua
loving_2bpp.config = {
page_size  =  256  *  8, -- 256 per line
block_size  =  16, -- (Tile Layer A, Tile Layer B)
max_size  =  1000000, -- 1MB Max Size Import Default
mode  =  "console", -- Console or Handheld, each has different types of 2BPP rendering.
}
```

### Read more about the 2BPP format for Console and Handheld

 - https://www.huderlem.com/demos/gameboy2bpp.html
 - https://sneslab.net/wiki/Graphics_Format#How_It_Works (This explains it close enough, just up to the 2bpp part)

