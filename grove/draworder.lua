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