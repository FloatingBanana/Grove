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

local floor = math.floor

local anm = {}
anm.__index = anm

function anm.loadFolder(folder, callback)
	local images = {}
	local files = love.filesystem.getDirectoryItems(folder)

	for _, filename in ipairs(files) do
		local file, extension = filename:match("(.*)%.(.*)")

		local result = callback(#files, file, extension)

		if result then
			images[result] = love.graphics.newImage(folder.."/"..file.."."..extension)
		end
	end

	return images
end

function anm:update(dt)
	if self.playing then
		local dir = self.rewind and -1 or 1

		self.time = self.time + self.speed * dt

		if self.time >= 1 then
			self.frame = self.frame + dir
			self.time = self.time - 1
		end

		local startFrame = self.rewind and 1 or self.range
		local endFrame = self.rewind and self.range or 1

		if self.frame < 1 or self.frame > self.range then
			self.playing = self.loop
			self.frame = self.loop and endFrame or startFrame

			if self.onFinish then
				self:onFinish()
			end
		end
	end

	return self
end

function anm:draw(...)
	love.graphics.draw(self.images[self.frame], ...)

	return self
end

function anm:stop()
	self.playing = false
	self.time = 0
	self.frame = self.rewind and self.range or 1

	return self
end

function anm:pause()
	self.playing = false

	return self
end

function anm:play()
	self.playing = true

	local startFrame = self.rewind and self.range or 1
	local endFrame = self.rewind and 1 or self.range

	if self.frame == endFrame then
		self.frame = startFrame
	end

	return self
end

function anm:getFrame()
	return self.frame
end

function anm:getSpeed()
	return self.speed
end

function anm:getRange()
	return self.range
end

function anm:getImage(frame)
	return self.images[frame or self.frame]
end

function anm:getAllImages()
	return self.frames
end

function anm:isLooping()
	return self.loop
end

function anm:isRewinding()
	return self.rewind
end

function anm:isPlaying()
	return self.playing
end

function anm:setFrame(frame)
	self.frame = frame
	self.time = 0

	return self
end

function anm:setSpeed(speed)
	self.speed = speed

	return self
end

function anm:setRange(range)
	self.range = range

	return self
end

function anm:setImage(image, frame)
	self.images[frame or self.frame] = image

	return self
end

function anm:setAllImages(images)
	self.images = images
	self.range = #images

	return self
end

function anm:setLoop(loop)
	self.loop = loop

	return self
end

function anm:setRewind(rewind)
	self.rewind = rewind

	return self
end

function anm.__call(_, imageList, speed, range)
	local new = {
		images = imageList,
		speed = speed or 30,
		frame = 1,
		time = 0,
		playing = false,
		rewind = false,
		loop = false,
		range = range or #imageList
	}

	return setmetatable(new, anm)
end

return setmetatable({}, anm)