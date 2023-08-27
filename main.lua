love.graphics.setDefaultFilter("nearest","nearest")

local loving_2bpp = require("loving2bpp")
loving_2bpp.read("2bpp.txt")
local tile = love.graphics.newImage(loving_2bpp.render_page(1))



function love.draw()
love.graphics.print("This is so cursed.")
love.graphics.draw(tile, 20, 20, 0, 4, 4)

end