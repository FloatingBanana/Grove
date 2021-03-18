local anm = {}
local funcs = {}

local floor = math.floor

local function copy_to_table(from, to)
	for k, v in pairs(from) do
		to[k] = v
	end
end

function anm.newAnimation(imageList, speed, range)
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
	copy_to_table(funcs, new)

	return new
end

function anm.loadFolder(folder, callback)
	local images = {}
	local files = love.filesystem.getDirectoryItems(folder)

	for _, filename in ipairs(files) do
		local file, extension = filename:match("(.*)%.(.*)")

		local result = callback(#files, file, extension)

		if result then
			images[result] = love.graphics.newImage(folder.."/"..file)
		end
	end

	return images
end

function funcs:update(dt)
	if self.playing then
		local dir = self.rewind and 1 or -1

		self.time = self.time + self.speed * dt

		if self.time >= 1 then
			self.frame = self.frame + dir
			self.time = self.time - 1
		end

		if self.loop then
			if self.frame < 1 then
				self.frame = self.range

				if self.onFinish then
					self:onFinish()
				end

			elseif self.frame > self.range then
				self.frame = 1

				if self.onFinish then
					self:onFinish()
				end
			end
		else
			if self.frame < 1 then
				self.frame = 1
				self.playing = false

				if self.onFinish then
					self:onFinish()
				end

			elseif self.frame > self.range then
				self.frame = self.range
				self.playing = false

				if self.onFinish then
					self:onFinish()
				end
			end
		end
	end

	return self
end

function funcs:stop()
	self.playing = false
	self.time = 0

	if self.rewind then
		self.frame = self.range
	else
		self.frame = 1
	end

	return self
end

function funcs:pause()
	self.playing = false

	return self
end

function funcs:play()
	self.playing = true

	if self.rewind then
		if self.frame == 1 then
			self.frame = self.range
		end
	else
		if self.frame == self.range then
			self.frame = 1
		end
	end

	return self
end

function funcs:draw(...)
	love.graphics.draw(self.images[self.frame], ...)

	return self
end

function funcs:getFrame()
	return self.frame
end

function funcs:getSpeed()
	return self.speed
end

function funcs:getRange()
	return self.range
end

function funcs:getImage(frame)
	return self.images[frame or self.frame]
end

function funcs:getAllImages()
	return self.frames
end

function funcs:isLooping()
	return self.loop
end

function funcs:isRewinding()
	return self.rewind
end

function funcs:isPlaying()
	return self.playing
end

function funcs:setFrame(frame)
	self.frame = frame
	self.time = 0

	return self
end

function funcs:setSpeed(speed)
	self.speed = speed

	return self
end

function funcs:setRange(range)
	self.range = range

	return self
end

function funcs:setImage(image, frame)
	self.images[frame or self.frame] = image

	return self
end

function funcs:setAllImages(images)
	self.images = images
	self.range = #images

	return self
end

function funcs:setLoop(loop)
	self.loop = loop

	return self
end

function funcs:setRewind(rewind)
	self.rewind = rewind

	return self
end

return anm