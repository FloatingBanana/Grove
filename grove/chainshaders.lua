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


local chain = {}
chain.__index = chain

local function clear_array(arr)
	for i=1, #arr do
		arr[i] = nil
	end
end

local function push_to_array(arr, ...)
	for i = 1, select("#", ...) do
		arr[#arr+1] = select(i, ...)
	end
end

local function copy_to_array(from, to)
 for i = 1, #from do
		to[#to+1] = from[i]
	end
end

function chain:start(...)
	if self.isEnabled then
		self.active = true
		self.curr_canvas = love.graphics.getCanvas()
		
		--Setup graphics state
		love.graphics.setCanvas(self.front)
		love.graphics.push("transform")
		love.graphics.origin()
		love.graphics.clear()
	
		push_to_array(self.holding, ...)
	end

	return self
end

local shader_list = {}
function chain:stop()
	if self.isEnabled then
		assert(self.active, "You need to call chain:start() first")

		local blendmode, alphamode = love.graphics.getBlendMode()
		local curr_shader = love.graphics.getShader()
		
		push_to_array(shader_list, unpack(self.shaders))
		push_to_array(shader_list, unpack(self.holding))

		love.graphics.setBlendMode("alpha", "premultiplied")
	
		for i=1, #shader_list do
			--Apply shaders on the back buffer
			love.graphics.setCanvas(self.back)
			love.graphics.clear()
			love.graphics.setShader(shader_list[i])
			love.graphics.draw(self.front)
		
			--Send the results to the front buffer
			love.graphics.setCanvas(self.front)
			love.graphics.clear()
			love.graphics.draw(self.back)
		end

		love.graphics.setShader()
		love.graphics.pop()
		love.graphics.setBlendMode("alpha", "alphamultiply")
		love.graphics.setCanvas(self.curr_canvas)
		
		love.graphics.draw(self.front)

		love.graphics.setBlendMode(blendmode, alphamode)
		love.graphics.setShader(curr_shader)
		
		clear_array(shader_list)
		clear_array(self.holding)

		self.curr_canvas = nil
		self.active = false
	end

	return self
end

function chain:append(...)
	copy_to_array({...}, self.shaders)
	
	return self
end

function chain:removeAppended(...)
	for i=1, select("#", ...) do
		local sh = select(i, ...)
		local find = false
		
		for j=1, #self.shaders do
			if sh == self.shaders[j] then
				table.remove(self.shaders, j)

				find = true
			end
		end

		assert(find, "Item #"..i.." is not appended")
	end
	
	return self
end

function chain:clearAppended()
	clear_array(self.shaders)
	
	return self
end

function chain:resize(width, height)
	self.front = love.graphics.newCanvas(width, height)
	self.back = love.graphics.newCanvas(width, height)
	
	return self
end

function chain:isAppended(sh)
	for i=1, #self.shaders do
		if sh == self.shaders[i] then
			return true
		end
	end

	return false
end

function chain:setEnabled(status)
	if status == nil then
		return self.isEnabled
	else
		self.isEnabled = status
		return self
	end
end

function chain:new(width, height)
	width = width or love.graphics.getWidth()
	height = height or love.graphics.getHeight()
	
	local object =  {
		front = nil,
		back = nil,
		curr_canvas = nil,
		isEnabled = true,
		shaders = {},
		holding = {},
	}

	return setmetatable(object, chain):resize(width, height)
end

-- Default instance
local default = chain:new()
for i, func in pairs(chain) do
	default[i] = function(...) return func(default, ...) end
end

return setmetatable(default, {__call = chain.new})