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


local res = {mouse = {}, touch = {}}

local min, max, floor = math.min, math.max, math.floor

local getWidth = love.graphics.getWidth
local getHeight = love.graphics.getHeight
local mousegetPosition = love.mouse.getPosition
local touchgetPosition = love.touch.getPosition

local NULL = function(_) return _ end
local clamp = nil
local resized = false

local conf = {
	centered = false,
	aspectRatio = true,
	clampMouse = false,
	clip = true,
	width = getWidth(),
	height = getHeight()
}
local replaced = {}

local oldsx, oldsy, oldsw, oldsh = 0, 0, 0, 0
local transform = love.math.newTransform()

local function clampMouse(x, y)
	if conf.clampMouse then
		return min(max(x, 0), conf.width), min(max(y, 0), conf.height)
	end
	return x, y
end

function res.init(c)
	if c.replace then
		res.replace(c.replace)
	end

	c.width = c.width or getWidth()
	c.height = c.height or getHeight()

	conf = c
end

function res.start()
	assert(not resized, "Missing \"stop()\" function")

	local scalerW = getWidth()/conf.width
	local scalerH = getHeight()/conf.height

	if conf.aspectRatio then
		scalerW = min(scalerW, scalerH)
		scalerH = scalerW
	end

	local centerXoffset = 0
	local centerYoffset = 0
	if conf.centered then
		centerXoffset = (getWidth() - conf.width * scalerW)/2
		centerYoffset = (getHeight() - conf.height * scalerH)/2
	end

	if conf.clip then
		oldsx, oldsy, oldsw, oldsh = love.graphics.getScissor()
		love.graphics.setScissor(centerXoffset, centerYoffset, conf.width * scalerW + 1, conf.height * scalerH + 1)
	end

	transform:setTransformation(centerXoffset, centerYoffset, 0, scalerW, scalerH)
	love.graphics.applyTransform(transform)
	resized = true
end

function res.stop()
	assert(resized, "Missing \"start()\" function")
	love.graphics.applyTransform(transform:inverse())

	if conf.clip then
		love.graphics.setScissor(oldsx, oldsy, oldsw, oldsh)
	end

	resized = false
end

function res.toResized(x,y)
	local pointx, pointy = transform:transformPoint(x, y)
	return floor(pointx), floor(pointy)
end

function res.toGlobal(x,y)
	local pointx, pointy =  transform:inverseTransformPoint(x, y)
	return floor(pointx), floor(pointy)
end

function res.mouse.getPosition()
	local x, y =  res.toGlobal(mousegetPosition())
	return clampMouse(x, y)
end

function res.mouse.getX()
	local x, y = res.mouse.getPosition()
	return x
end

function res.mouse.getY()
	local x, y = res.mouse.getPosition()
	return y
end

function res.touch.getPosition(id)
	local x, y = res.toResized(touchgetPosition(id))
	return clampMouse(x, y)
end


function res.replace(modules)
	if #modules == 0 then
		modules = {"graphics","mouse","touch"}
	end

	for i, event in ipairs(modules) do
		if event == "graphics" and not replaced.graphics then
			--draw
			local olddraw = love.draw or NULL
			love.draw = function()
				res.start()
				olddraw()
				res.stop()
			end
		end

		if event == "mouse" and not replaced.mouse then
			love.mouse.getX = res.mouse.getX
			love.mouse.getY = res.mouse.getY
			love.mouse.getPosition = res.mouse.getPosition

			--mousepressed
			local oldmousepressed = love.mousepressed or NULL
			love.mousepressed = function(x, y, button, isTouch, presses)
				x, y = res.toResized(x, y)
				oldmousepressed(x, y, button, isTouch, presses)
			end

			--mousereleased
			local oldmousereleased = love.mousereleased or NULL
			love.mousereleased = function(x, y, button, isTouch, presses)
				x, y = res.toResized(x, y)
				oldmousereleased(x, y, button, isTouch, presses)
			end

			--mousemoved
			local oldmousemoved = love.mousemoved or NULL
			love.mousemoved = function(x, y, dx, dy, isTouch)
				x, y = res.toResized(x, y)
				dx, dy = res.toResized(dx, dy)
				oldmousemoved(x, y, dx, dy,  isTouch)
			end
		end

		if event == "touch" and not replaced.touch then
			love.touch.getPosition = res.touch.getPosition

			--touchpressed
			local oldtouchpressed = love.touchpressed or NULL
			love.touchpressed = function(id, x, y, dx, dy, pressure)
				x, y = res.toResized(x, y)
				dx, dy = res.toResized(dx, dy)
				oldtouchpressed(id, x, y, dx, dy, pressure)
			end

			--touchreleased
			local oldtouchreleased = love.touchreleased or NULL
			love.touchreleased = function(id, x, y, dx, dy, pressure)
				x, y = res.toResized(x, y)
				dx, dy = res.toResized(dx, dy)
				oldtouchreleased(id, x, y, dx, dy, pressure)
			end

			--touchmoved
			local oldtouchmoved = love.touchmoved or NULL
			love.touchmoved = function(id, x, y, dx, dy, pressure)
				x, y = res.toResized(x, y)
				dx, dy = res.toResized(dx, dy)
				oldtouchmoved(id, x, y, dx, dy, pressure)
			end
		end

		replaced[event] = true
	end
end

return res