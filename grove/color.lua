--[[
	MIT License

	Copyright (c) 2021 Thales Maia de Moraes

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
]]


local m_max, m_min, m_abs, m_floor, m_sqrt = math.max, math.min, math.abs, math.floor, math.sqrt

local color = {}
setmetatable(color, color)

-- https://docs.microsoft.com/en-us/dotnet/api/system.drawing.color?view=net-5.0
local predefined_colors = {
    BLACK = 0xFF000000, WHITE = 0xFFFFFFFF, RED = 0xFFFF0000, GREEN = 0xFF00FF00, BLUE = 0xFF0000FF, YELLOW = 0xFFFFFF00, GRAY = 0xFF808080,
    CYAN = 0xFF00FFFF, MAGENTA = 0xFFFF00FF, AQUA = 0xFF00FFFF, BROWN = 0xFFA52A2A, PINK = 0xFFFFC0CB, CORAL = 0xFFFF7F50, CRIMSON = 0xFFDC143C,
    DARK_BLUE = 0xFF00008B, DARK_CYAN = 0xFF008B8B, DARK_GRAY = 0xFFA9A9A9, DARK_GREEN = 0xFF006400, DARK_RED = 0xFF8B0000, GOLD = 0xFFFFD700,
    IVORY = 0xFFFFFFF0, LIME = 0xFF00FF00, PURPLE = 0xFF800080
}


local function isColor(c)
    return getmetatable(c) == color
end

local function clamp(n, min, max)
    return m_max(m_min(n, max), min)
end

local function lerp(from, to, progress)
    return from + (to - from) * progress
end

local function validate_hex(hex)
    return type(hex) == "string" and hex:find("#") == 1 and #hex > 1 and not hex:find("[^0-9A-Fa-f]", 2)
end

local function hex_to_rgba(hex)
    if type(hex) == "number" then
        hex = ("%x"):format(hex)
    else
        assert(validate_hex(hex), "Invalid HEX string")

        hex = hex:sub(2, -1)
    end

    if #hex < 8 then
        hex = hex..("f"):rep(8 - #hex)
    end

    local a = tonumber(hex:sub(1, 2), 16)/255
    local r = tonumber(hex:sub(3, 4), 16)/255
    local g = tonumber(hex:sub(5, 6), 16)/255
    local b = tonumber(hex:sub(7, 8), 16)/255

    return r, g, b, a
end

local function rgba_to_hex(r, g, b, a)
    r = (r or 1) * 255
    g = (g or 1) * 255
    b = (b or 1) * 255
    a = (a or 1) * 255

    return ("#%x%x%x%x"):format(a, r, g, b)
end

local function rgb_to_hsv(r, g, b)
    local cmax = m_max(r, m_max(g, b))
    local cmin = m_min(r, m_min(g, b))
    local diff = cmax - cmin
    local h, s = 0, 0
    local v = cmax

    if cmax == cmin then
        h = 0
    elseif cmax == r then
        h = (60 * ((g - b) / diff) + 360) % 360
    elseif cmax == g then
        h = (60 * ((b - r) / diff) + 120) % 360
    elseif cmax == b then
        h = (60 * ((r - g) / diff) + 240) % 360
    end

    if cmax ~= 0 then
        s = (diff / cmax)
    end

    return h, s, v
end

local function rgb_to_hsl(r, g, b)
    local cmax = m_max(r, m_max(g, b))
    local cmin = m_min(r, m_min(g, b))
    local diff = cmax - cmin
    local h, s = 0, 0

    if cmax == cmin then
        h = 0
    elseif cmax == r then
        h = (60 * ((g - b) / diff) + 360) % 360
    elseif cmax == g then
        h = (60 * ((b - r) / diff) + 120) % 360
    elseif cmax == b then
        h = (60 * ((r - g) / diff) + 240) % 360
    end

    local l = (cmax + cmin)/2

    if diff ~= 0 then
        s = diff/(1 - m_abs(2 * l - 1))
    end

    return h, s, l
end


local function hsv_to_rgb(h, s, v)
    local c = v * s
    local x = c * (1 - m_abs((h / 60) % 2 - 1))
    local m = v - c
    local ir, ig, ib = 0, 0, 0

    h = h % 360

    if h < 60 then
        ir, ig, ib = c, x, 0
    elseif h < 120 then
        ir, ig, ib = x, c, 0
    elseif h < 180 then
        ir, ig, ib = 0, c, x
    elseif h < 240 then
        ir, ig, ib = 0, x, c
    elseif h < 300 then
        ir, ig, ib = x, 0, c
    elseif h < 360 then
        ir, ig, ib = c, 0, x
    end

    return ir + m, ig + m, ib + m
end

local function hsl_to_rgb(h, s, l)
    local c = (1 - m_abs(2 * l - 1)) * s
    local x = c * (1 - m_abs((h / 60) % 2 - 1))
    local m = l - c/2
    local ir, ig, ib = 0, 0, 0

    h = h % 360

    if h < 60 then
        ir, ig, ib = c, x, 0
    elseif h < 120 then
        ir, ig, ib = x, c, 0
    elseif h < 180 then
        ir, ig, ib = 0, c, x
    elseif h < 240 then
        ir, ig, ib = 0, x, c
    elseif h < 300 then
        ir, ig, ib = x, 0, c
    elseif h < 360 then
        ir, ig, ib = c, 0, x
    end

    return ir + m, ig + m, ib + m
end



function color:__call(r, g, b, a)
    local obj = nil

    if not r or (r and g) then
        obj = {r or 1, g or 1, b or 1, a or 1}

    elseif type(r) == "string" or type(r) == "number" then
        obj = {hex_to_rgba(r)}
    else
        error("Invalid arguments to create color")
    end

    return setmetatable(obj, color)
end

local color_index = {
    r = 1, red   = 1,
    g = 2, green = 2,
    b = 3, blue  = 3,
    a = 4, alpha = 4
}
function color:__index(key)
    if color_index[key] then
        return self[color_index[key]]
    end

    if key == "hex" then
        return rgba_to_hex(self:getRGBA())
    end

    -- get hue
    if key == "h" or key == "hue" then
        local h, s, l = self:getHSL()
        return h
    end

    -- get saturation (HSL)
    if key == "s" or key == "saturation" then
        local h, s, l = self:getHSL()
        return s
    end

    -- get lightness (HSL)
    if key == "l" or key == "lightness" then
        local h, s, l = self:getHSL()
        return l
    end

    -- get saturation (HSV)
    if key == "ss" or key == "ssaturation" then
        local h, s, v = self:getHSV()
        return s
    end

    -- get value (HSV)
    if key == "v" or key == "value" then
        local h, s, v = self:getHSV()
        return v
    end

    if predefined_colors[key] then
        return color(predefined_colors[key])
    end

    return rawget(color, key)
end



function color:__newindex(key, value)
    if color_index[key] and value then
        self[color_index[key]] = clamp(value, 0, 1)
        return
    end

    if key == "hex" then
        self:setRGBA(hex_to_rgba(value))
        return
    end

    -- set hue
    if key == "h" or key == "hue" then
        local h, s, l = self:getHSL()
        self:setHSL(value, s, l)
        return
    end

    -- set saturation (HSL)
    if key == "s" or key == "saturation" then
        local h, s, l = self:getHSL()
        self:setHSL(h, value, l)
        return
    end

    -- set lightness (HSL)
    if key == "l" or key == "lightness" then
        local h, s, l = self:getHSL()
        self:setHSL(h, s, value)
        return
    end

    -- set saturation (HSV)
    if key == "ss" or key == "ssaturation" then
        local h, s, v = self:getHSV()
        self:setHSV(h, value, v)
        return
    end

    -- set value (HSV)
    if key == "v" or key == "value" then
        local h, s, v = self:getHSV()
        self:setHSV(h, s, value)
        return
    end

    rawset(self, key, value)
end

----------------
-- arithmetic --
----------------

function color:add(other)
    if type(other) == "number" then
        self:setRGBA(self.r + other, self.g + other, self.b + other, self.a + other)

    elseif isColor(other) then
        self:setRGBA(self.r + other.r, self.g + other.g, self.b + other.b, self.a + other.a)
    else
        error("Attempt to add a "..type(other).." to color")
    end

    return self
end

function color:subtract(other)
    if type(other) == "number" then
        self:setRGBA(self.r - other, self.g - other, self.b - other, self.a - other)

    elseif isColor(other) then
        self:setRGBA(self.r - other.r, self.g - other.g, self.b - other.b, self.a - other.a)
    else
        error("Attempt to subtract a"..type(other).." from color")
    end

    return self
end

function color:multiply(other)
    if type(other) == "number" then
        self:setRGBA(self.r * other, self.g * other, self.b * other, self.a * other)

    elseif isColor(other) then
        self:setRGBA(self.r * other.r, self.g * other.g, self.b * other.b, self.a * other.a)
    else
        error("Attempt to multiply "..type(other).." to color")
    end

    return self
end

function color:divide(other)
    if type(other) == "number" then
        self:setRGBA(self.r / other, self.g / other, self.b / other, self.a / other)

    elseif isColor(other) then
        self:setRGBA(self.r / other.r, self.g / other.g, self.b / other.b, self.a / other.a)
    else
        error("Attempt to multiply "..type(other).." to color")
    end

    return self
end

function color:invert()
    self:setRGBA(1 - self.r, 1 - self.g, 1 - self.b, self.a)

    return self
end

function color:shiftHue(deg)
    assert(type(deg) == "number", "Degree must be a number")
    self.hue = (self.hue + deg) % 360

    return self
end

---------------
-- Operators --
---------------
function color:__add(other)
    return self:clone():add(other)
end

function color:__sub(other)
    return self:clone():subtract(other)
end

function color:__mul(other)
    return self:clone():multiply(other)
end

function color:__div(other)
    return self:clone():divide(other)
end

function color:__unm()
    return self:clone():invert()
end

function color:__pow(value)
    return self:clone():shiftHue(value)
end

function color:__tostring()
    return ("Color (r: %.3f g: %.3f b: %.3f a: %.3f)"):format(self:getRGBA())
end

-----------------
------ HSV ------
-----------------
function color:setHSV(h, s, v)
    self.r, self.g, self.b = hsv_to_rgb(h, s, v)

    return self
end

function color:getHSV()
    return rgb_to_hsv(self.r, self.g, self.b)
end

-----------------
------ HSL ------
-----------------
function color:setHSL(h, s, v)
    self.r, self.g, self.b = hsl_to_rgb(h, s, v)

    return self
end

function color:getHSL()
    return rgb_to_hsl(self.r, self.g, self.b)
end

----------------
----- RGBA -----
----------------
function color:setRGBA(r, g, b, a)
    self.r = r or self.r
    self.g = g or self.g
    self.b = b or self.b
    self.a = a or self.a

    return self
end

function color:getRGBA()
    return self.r, self.g, self.b, self.a
end

function color:setByteRGBA(r, g, b, a)
    self.r = r and (r/255) or self.r
    self.g = g and (g/255) or self.g
    self.b = b and (b/255) or self.b
    self.a = a and (a/255) or self.a

    return self
end

function color:getByteRGBA()
    return m_floor(self.r * 255), m_floor(self.g * 255), m_floor(self.b * 255), m_floor(self.a * 255)
end

----------------
----- Misc -----
----------------
function color:clone()
    return color(self:getRGBA())
end

---------------
---- Utils ----
---------------
function color.lerp(from, to, progress)
    return color(
        lerp(from.r, to.r, progress),
        lerp(from.g, to.g, progress),
        lerp(from.b, to.b, progress),
        lerp(from.a, to.a, progress)
    )
end

function color.distance(a, b)
    local dr = a.r - b.r
    local dg = a.g - b.b
    local db = a.b - b.b
    local da = a.a - b.a

    return m_sqrt(dr * dr + dg * dg + db * db + da * da)
end

color.HSVtoRGB = hsv_to_rgb
color.RGBtoHSV = rgb_to_hsv
color.HSLtoRGB = hsl_to_rgb
color.RGBtoHSL = rgb_to_hsl
color.HEXtoRGBA = hex_to_rgba
color.RGBAtoHEX = rgba_to_hex
color.validateHEX = validate_hex

return color