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


local draworder = {}
draworder.__index = draworder

local unpack = unpack or table.unpack

local function isCallable(v)
	local mt = getmetatable(v)

	return type(v) == "function" or (mt and mt.__call)
end

local function defaultSort(a, b)
	if a.order == b.order then
		return a.stack < b.stack
	else
		return a.order < b.order
	end
end

function draworder:_recicle_from_list(index)
	local t = self.list[index]

	for j=1, #t do
		t[j] = nil
	end

	t.func = nil
	t.order = nil
	t.stack = nil
	self.pool[#self.pool+1] = t
end

function draworder:queue(order, func, ...)
	local t = nil

	if #self.pool == 0 then
		t = {...}
	else
		t = self.pool[1]
		table.remove(self.pool, 1)

		for i = 1, select("#", ...) do
			t[i] = select(i, ...)
		end
	end

	t.order = order
	t.func = func
	t.stack = #self.list + 1
	self.list[t.stack] = t
end

function draworder:present()
	if #self.list > 1 then
		table.sort(self.list, self.sortFunc)
	end

	for i, item in ipairs(self.list) do
		local func = item.func

		if isCallable(func) then
			func(unpack(item))
		else
			love.graphics[func](unpack(item))
		end

		self:_recicle_from_list(i)
	end
end


function draworder:setSortingFunction(func)
	self.sortFunc = func or defaultSort
end

function draworder:clearQueue()
	for i=1, #self.list do
		self:_recicle_from_list(i)
	end
end

function draworder:clearCache()
	self.list = {}
	self.pool = {}
end

function draworder:new()
	local obj = {
		pool = {},
		list = {},
		sortFunc = defaultSort,
	}

	return setmetatable(obj, draworder)
end

-- Default instance
local default = draworder:new()
for i, func in pairs(draworder) do
	default[i] = function(...) return func(default, ...) end
end

return setmetatable(default, {__index = draworder, __call = draworder.new})