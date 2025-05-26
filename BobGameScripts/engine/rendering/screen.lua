--#build
--#priority 110

---@class sprite_to_draw
---@field sprite sprite | integer
---@field dest_x integer
---@field dest_y integer
---@field src_x integer
---@field src_y integer
---@field src_w integer
---@field src_h integer
---@field flip_h boolean
---@field flip_v boolean
---@field layer integer
---@field type integer
---@field draw_index integer
---@field block integer?

---@class screen
---@field private sprite_manager sprite_manager
---@field public x integer
---@field public y integer
---@field public z integer
---@field private screen integer[]
---@field private prev_screen integer[]
---@field private total_pixels integer
---@field private sprites_to_draw sprite_to_draw[] 
---@field private sprites_to_draw_count integer
---@field public width integer
---@field public height integer
Screen = {}
Screen.__index = Screen

---@param sprite_manager sprite_manager
---@param x integer
---@param y integer
---@param z integer
---@param width integer
---@param height integer
function Screen.new(sprite_manager, x, y, z, width, height)
    local self = setmetatable({}, Screen)
    self.sprite_manager = sprite_manager
    self.x = x
    self.y = y
    self.z = z
    self.width = width
    self.height = height
    self.screen = {}
    self.prev_screen = {}
    self.total_pixels = width * height
    self.sprites_to_draw = {}
    self.sprites_to_draw_count = 0
    for i = 1, self.total_pixels, 1 do
        self.screen[i] = block.none
        self.prev_screen[i] = block.none
    end

    if is_mod_swap_chain_enabled then
        initialize_swap_chain(x, y, z + 1, width, height)
    end
    return self
end

---@param block integer
function Screen:clear(block)
    local total_pixels = self.total_pixels
    local screen = self.screen
    for i = 1, total_pixels, 1 do
        screen[i] = block
    end
end

function Screen:reset()
    local total_pixels = self.total_pixels
    local screen = self.screen
    local prev_screen = self.prev_screen
    for i = 1, total_pixels, 1 do
        screen[i] = block.none
        prev_screen[i] = block.none
    end
end

function Screen:begin()
    local total_pixels = self.total_pixels
    local screen = self.screen
    local prev_screen = self.prev_screen
    for i = 1, total_pixels, 1 do
        prev_screen[i] = screen[i]
    end

    for index, value in ipairs(self.sprites_to_draw) do
        self.sprites_to_draw[index] = nil
    end
    self.sprites_to_draw_count = 0
    self.sprite_index = 0
end

---@param sprite sprite
---@param src_x integer
---@param src_y integer
---@param src_w integer
---@param src_h integer
---@param dest_x integer
---@param dest_y integer
---@param layer integer
---@param flip_horizontally boolean
---@param flip_vertically boolean
---@param block integer?
---@param draw_id integer
---@overload fun(self: screen, sprite: sprite, src_x: integer, src_y: integer, src_w: integer, src_h: integer, dest_x: integer, dest_y: integer, layer: integer)
---@overload fun(self: screen, sprite: sprite, src_x: integer, src_y: integer, src_w: integer, src_h: integer, dest_x: integer, dest_y: integer, layer: integer, flip_horizontally: boolean, flip_vertically: boolean)
---@overload fun(self: screen, sprite: sprite, src_x: integer, src_y: integer, src_w: integer, src_h: integer, dest_x: integer, dest_y: integer, layer: integer, flip_horizontally: boolean, flip_vertically: boolean, block: integer?)
function Screen:draw(sprite, src_x, src_y, src_w, src_h, dest_x, dest_y, layer, flip_horizontally, flip_vertically, block, draw_id)
    local i = self.sprites_to_draw_count + 1
    local t = self.sprites_to_draw[i]
    if t == nil then
        ---@diagnostic disable-next-line: missing-fields
        t = {}
        table.insert(self.sprites_to_draw, i, t);
    end

    if draw_id == nil then
        draw_id = i
    end

    t.sprite = sprite
    t.src_x = src_x
    t.src_y = src_y
    t.src_w = src_w
    t.src_h = src_h
    t.dest_x = dest_x
    t.dest_y = dest_y
    t.flip_h = flip_horizontally
    t.flip_v = flip_vertically
    t.layer = layer
    t.type = 1
    t.draw_index = draw_id
    t.block = block
    self.sprites_to_draw_count = i
end

---@param block integer
---@param dest_x integer
---@param dest_y integer
---@param layer integer
---@param draw_id integer
---@overload fun(self: screen, block: integer, dest_x: integer, dest_y: integer, layer: integer)
function Screen:draw_pixel(block, dest_x, dest_y, layer, draw_id)
    local i = self.sprites_to_draw_count + 1
    local t = self.sprites_to_draw[i]
    if t == nil then
        ---@diagnostic disable-next-line: missing-fields
        t = {}
        table.insert(self.sprites_to_draw, i, t);
    end

    if draw_id == nil then
        draw_id = i
    end

    t.sprite = block
    t.dest_x = dest_x
    t.dest_y = dest_y
    t.layer = layer
    t.type = 2
    t.draw_index = draw_id
    self.sprites_to_draw_count = i
end

---@param font font
---@param text string
---@param dest_x integer
---@param dest_y integer
---@param layer integer
---@param block integer
function Screen:draw_text(font, text, dest_x, dest_y, layer, block)
    local x = dest_x
    local _, measure_y = font:measure(text)
    local y = dest_y + measure_y - font:get_glyph(font:get_glyph_index("unknown", 1)).height
    for i = 1, text:len() do
        local byte = text:byte(i, i)
        local glyph = font:get_glyph(font:get_glyph_index(text, i))
        if byte == 10 then
            -- 10 == \n
            y = y - glyph.advance
            x = dest_x
        elseif byte == 32 then
            -- 32 == space
            x = x + glyph.advance
        else
            local y_offset = glyph.bearing_y - glyph.height
            self:draw(font.sprite, glyph.x, glyph.y, glyph.width, glyph.height, x, y + y_offset, layer, false, false, block)
            x = x + glyph.advance
        end
    end
end

---@param min_x number
---@param min_y number
---@param max_x number
---@param max_y number
---@param block integer
---@param layer integer
function Screen:draw_box_outline(min_x, min_y, max_x, max_y, block, layer)
    min_x = math.floor(min_x)
    min_y = math.floor(min_y)
    max_x = math.ceil(max_x)
    max_y = math.ceil(max_y)
    for x = min_x, max_x do
        self:draw_pixel(block, x, min_y, layer)
        self:draw_pixel(block, x, max_y, layer)
    end
    for y = min_y + 1, max_y - 1 do
        self:draw_pixel(block, min_x, y, layer)
        self:draw_pixel(block, max_x, y, layer)
    end
end

---@param min_x number
---@param min_y number
---@param max_x number
---@param max_y number
---@param block integer
---@param layer integer
function Screen:draw_box(min_x, min_y, max_x, max_y, block, layer)
    min_x = math.floor(min_x)
    min_y = math.floor(min_y)
    max_x = math.ceil(max_x)
    max_y = math.ceil(max_y)
    for x = min_x, max_x do
        for y = min_y, max_y do
            self:draw_pixel(block, x, y, layer)
        end
    end
end

function Screen:present()
    self:draw_all_sprites()

    if is_mod_swap_chain_enabled then
        self:present_swap_chain()
    else
        self:present_vanilla()
    end
end

---@private
function Screen:draw_all_sprites()
    table.sort(self.sprites_to_draw, function (left, right)
        if left.layer == right.layer then
            return left.draw_index < right.draw_index
        end

        return left.layer < right.layer
    end)

    local screen = self.screen
    local screen_w = self.width
    local screen_h = self.height
    local none = block.none
    for i = 1, self.sprites_to_draw_count, 1 do
        local sprite_to_draw = self.sprites_to_draw[i]
        local sprite = sprite_to_draw.sprite
        local dest_x = sprite_to_draw.dest_x
        local dest_y = sprite_to_draw.dest_y

        if sprite_to_draw.type == 2 then
            ---@cast sprite integer
            
            -- Prevent screen wrapping
            if dest_x >= 0 and dest_x < screen_w and dest_y >= 0 and dest_y < screen_h then
                if sprite ~= block.none then
                    local j = (dest_y * screen_w) + dest_x + 1
                    screen[j] = sprite
                end
            end
        else
            ---@cast sprite sprite
            local sprite_data = sprite.data
            local sprite_w = sprite.width
            local src_x = sprite_to_draw.src_x
            local src_y = sprite_to_draw.src_y
            local src_w = sprite_to_draw.src_w
            local src_h = sprite_to_draw.src_h
            local flip_h = sprite_to_draw.flip_h
            local flip_v = sprite_to_draw.flip_v
            local block_override = sprite_to_draw.block

            for x = 1, src_w, 1 do
                for y = 1, src_h, 1 do
                    local dx, dy
                    if flip_h then
                        dx = dest_x + (src_w - x)
                    else
                        dx = dest_x + x - 1
                    end

                    -- Sprite data is upside down as y0 is the top of the sprite data,
                    -- but y0 is the bottom of the screen, so we invert the flip
                    if flip_v then
                        dy = dest_y + y - 1
                    else
                        dy = dest_y + (src_h - y)
                    end

                    -- Prevent screen wrapping
                    if dx >= 0 and dx < screen_w and dy >= 0 and dy < screen_h then
                        local si = ((src_y + y - 1) * sprite_w) + src_x + x
                        local b = sprite_data[si]
                        if b ~= none then
                            if block_override ~= nil then
                                b = block_override
                            end

                            local j = ((dy) * screen_w) + dx + 1
                            screen[j] = b
                        end
                    end
                end
            end
        end
    end
end

---@private
function Screen:present_vanilla()
    local screen = self.screen
    local prev_screen = self.prev_screen
    local screen_x = self.x
    local screen_y = self.y
    local width = self.width
    local z = self.z
    for i = 1, self.total_pixels, 1 do
        local block = screen[i]
        if prev_screen[i] ~= block then
            local i1 = i - 1
            local x = screen_x + (i1 % width)
            local y = screen_y + math.floor(i1 / width)
            set_block(x, y, z, block, 0)
        end
    end
    commit()
end

---@private
function Screen:present_swap_chain()
    local screen = self.screen
    local prev_screen = self.prev_screen
    local width = self.width
    for i = 1, self.total_pixels, 1 do
        local block = screen[i]
        if prev_screen[i] ~= block then
            local i1 = i - 1
            local x = (i1 % width)
            local y = math.floor(i1 / width)
            swap_chain_set_pixel(x, y, block)
        end
    end
    swap_chain_present()
end