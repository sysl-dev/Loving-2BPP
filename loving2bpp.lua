local m = {
  __NAME        = "Loving 2BPP",
  __VERSION     = "1.0",
  __AUTHOR      = "C. Hall (SysL)",
  __DESCRIPTION = "Löve2D - 2BPP Format - Reader (Handheld 2BPP is formatted differently)",
  __URL         = "http://github.sysl.dev/",
  __LICENSE     = [[
    MIT LICENSE

    Copyright (c) 2023 Chris / SysL

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  ]],
  __LICENSE_TITLE = "MIT LICENSE"
}

--[[--------------------------------------------------------------------------------------------------------------------------------------------------
  * Warning: I did not want to deal with love2d using FFI for data, so I just read everything as a string.
  * Sorry! This is a little cursed. 
--------------------------------------------------------------------------------------------------------------------------------------------------]]--

--[[--------------------------------------------------------------------------------------------------------------------------------------------------
  * Config / swap between console/handheld as required, change the page sizes in 256 chunks
--------------------------------------------------------------------------------------------------------------------------------------------------]]--
m.config = {
  page_size = 256 * 8, -- 256 per line 
  block_size = 16, -- Two layers of 8 bytes stacked. 
  max_size = 1000000, -- 1MB Max Size Import Default 
  mode = "console",
}

-- Page Width/Height (Using YYCHR's Display as the default, width is 128px / Height is how many 8x8 blocks tall your page is)
local page_width = 128
local page_height = m.config.page_size/32

m.palette = {
  1,
  0.80,
  0.40,
  0.06
}

-- Empty by default 
m.file_buffer = ""
m.file_size = 0
m.pages_to_convert = 0

-- ImageData 
m.single_tile_data = love.image.newImageData(8,8)
m.page_data = love.image.newImageData(page_width, page_height)

--[[--------------------------------------------------------------------------------------------------------------------------------------------------
  * Convert a string number into Binary 
--------------------------------------------------------------------------------------------------------------------------------------------------]]--
local function convert_to_binary(num_or_string)
  -- Convert to hex if a number was passed in.
  if type(num_or_string) ~= "string" then 
                  num_or_string = string.format("%02x", num_or_string):upper()
  end

  -- Look up table
  local hex_conv = {
                  ['0'] = "0000",
                  ['1'] = "0001",
                  ['2'] = "0010",
                  ['3'] = "0011",
                  ['4'] = "0100",
                  ['5'] = "0101",
                  ['6'] = "0110",
                  ['7'] = "0111",
                  ['8'] = "1000",
                  ['9'] = "1001",
                  ['A'] = "1010",
                  ['B'] = "1011",
                  ['C'] = "1100",
                  ['D'] = "1101",
                  ['E'] = "1110",
                  ['F'] = "1111",
  }
  
  local result = ""
  
  for i=1, #num_or_string do
                  result = result .. hex_conv[num_or_string:sub(i,i)]
  end
  
  return result
end

--[[--------------------------------------------------------------------------------------------------------------------------------------------------
  * Read the file into memory, you can also read it into the library's values externally if you want to be fancy with the data.
--------------------------------------------------------------------------------------------------------------------------------------------------]]--
function m.read(path_to_file)
  m.file_buffer, m.file_size = love.filesystem.read(path_to_file, m.config.max_size)
  --print("Reading: " .. path_to_file, "File Size: " .. m.file_size, "String Length: " .. #m.file_buffer, "Config Max Size: " .. m.config.max_size)
  m.pages_to_convert = math.floor(m.file_size/m.config.page_size)
  --print("Graphics Pages: " .. m.pages_to_convert)
end

--[[--------------------------------------------------------------------------------------------------------------------------------------------------
  * Take the raw data and make it into a tile. 
--------------------------------------------------------------------------------------------------------------------------------------------------]]--
function m.convert_tile(tile_number)
  tile_number = tile_number - 1
  -- Lua starts at 1, Select the tile 
  local tile_table = {string.byte(m.file_buffer, 1 + (m.config.block_size * tile_number), m.config.block_size + (m.config.block_size * tile_number))}
  -- Print for reference, remove later 
  --print(unpack(tile_table))

  -- Convert to binary strings for drawing 
  for i=1, #tile_table do 
    tile_table[i] = convert_to_binary(tile_table[i])
  end
  -- Print for reference, remove later 
  --print(unpack(tile_table))

  -- Clear the single tile imagedata 
  m.single_tile_data = love.image.newImageData(8,8)

  if m.config.mode == "console" then -- Format Full 8x8 tile layer 1 / Full 8x8 tile layer 2 / layer 
    -- Combine layered data 
    for y=1, #tile_table/2 do 
      for x=1, #tile_table[y] do
        -- Pixels are 0/1/2/3 based on the layering of tile 1/9, 2/10, ... 8/16; Then we add one to make it align with the palette.
        local color_pixel = tonumber(tile_table[y]:sub(x,x))
        local color_pixel2 = tonumber(tile_table[y+#tile_table/2]:sub(x,x))
        if color_pixel2 == 1 then color_pixel2 = 2 end
        -- Add one to make sure we align to the palette.
        color_pixel = m.palette[color_pixel + color_pixel2 + 1]
        m.single_tile_data:setPixel(x-1, y-1, color_pixel, color_pixel, color_pixel, 1)
      end
    end
  end

  if m.config.mode == "handheld" then  -- format Tile row 1 / tile row 1 second layer / merge
    -- Combine layered data 
    local y_count = 1
    for y=1, #tile_table, 2 do 
      for x=1, #tile_table[y] do
        -- Pixels are 0/1/2/3 based on the layering of tile 1/9, 2/10, ... 8/16; Then we add one to make it align with the palette.
        local color_pixel = tonumber(tile_table[y]:sub(x,x))
        local color_pixel2 = tonumber(tile_table[y+1]:sub(x,x))
        if color_pixel2 == 1 then color_pixel2 = 2 end
        -- Add one to make sure we align to the palette.
        color_pixel = m.palette[color_pixel + color_pixel2 + 1]
        --print(x-1,y_count-1)
        m.single_tile_data:setPixel(x-1, y_count-1, color_pixel, color_pixel, color_pixel, 1)
      end
      y_count = y_count + 1
    end
  end

  return m.single_tile_data
end

--[[--------------------------------------------------------------------------------------------------------------------------------------------------
  * Render a page of tiles.
--------------------------------------------------------------------------------------------------------------------------------------------------]]--
function m.render_page(page_number)
  page_number = page_number - 1

  -- clear page data
  m.page_data = love.image.newImageData(page_width, page_height)

  local cursorx = 0
  local cursory = 0
  for i=1 + (m.config.page_size/m.config.block_size * page_number), m.config.page_size/m.config.block_size + (m.config.page_size/m.config.block_size * page_number) do
    local temp_tile = m.convert_tile(i)
    m.page_data:paste(temp_tile, cursorx, cursory, 0, 0, m.config.block_size-1, m.config.block_size-1)
    cursorx = cursorx + 8
    if cursorx >= page_width then 
      cursory = cursory + 8
      cursorx = 0 
    end
  end

  return m.page_data
end


--[[--------------------------------------------------------------------------------------------------------------------------------------------------
  * End of File
--------------------------------------------------------------------------------------------------------------------------------------------------]]--
return m