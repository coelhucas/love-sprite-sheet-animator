--[[
MIT License

Copyright 2019 lcrabbit

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
]]--

local Animator = {}
local mtAnimator = { __index = Animator }

local Animation = {}
local mtAnimation = { __index = Animation }

function Animator.new(sprite, hframes, vframes)
  local animator = {}
  animator.sprite = sprite
  animator.playing = false
  animator.frameWidth = sprite:getWidth() / hframes
  animator.frameHeight = sprite:getHeight() / vframes
  animator.delayToNext = 0
  animator.currentAnimation = {}
  animator.animations = {}
  animator.quads = {}
  animator.mirrored = false

  local spriteDimensions = sprite:getDimensions()

  for vindex = 0, vframes  - 1 do
    for hindex = 0, hframes - 1 do
      -- These premade quads will give more performance because we initialize then based on our sprite sheet and call when we want without creating a new quad every time
      quad = {
        index = table.getn(animator.quads) + 1,
        x = animator.frameWidth * hindex,
        y = animator.frameHeight * vindex,
        w = animator.frameWidth,
        h = animator.frameHeight
      }
      animator.quads[quad.index] = love.graphics.newQuad(quad.x, quad.y, quad.w, quad.h, sprite:getDimensions())
    end
  end

  return setmetatable(animator, mtAnimator)
end

function Animator:newAnimation(name, start, ending, speed, frameDuration, loop)

  if (self.animations[name]) then
    error('An Animation with this name is already defined for this Animator.')
  end

  local animation = {}
  animation.name = name
  animation.start = start or 1
  animation.frame = start or 1
  animation.frameDuration = frameDuration or 0.1
  animation.speed = speed or 1
  animation.ending = ending

  if (loop ~= nil) then
    animation.loop = loop
  else
    animation.loop = true
  end

  self.animations[name] = animation
  return setmetatable(animation, mtAnimation)
end

function Animation:isLastFrame(nextframe)
  return nextframe > self.ending
end

function Animator:isBeyondFrameLimits(nextframe)
  local totalFrames = table.getn(self.quads)
  return nextframe > totalFrames
end

function Animator:update(dt)
  -- This is responsible for making the frame changes and animation loop (if needed)
  if (self.playing) then
    local existingFrames = table.getn(self.quads)
    local nextframe = self.currentAnimation.frame + 1
    -- We must prevent the user of trying to render a non existent frame
    if (self:isBeyondFrameLimits(nextframe)) then
      error('Trying to access a frame greater than the total sprite-sheet frames amount.')
    end

    -- Here we accumulate the time to check whether we go to the next frame
    self.delayToNext = self.delayToNext + dt * self.currentAnimation.speed
    if (self.delayToNext > self.currentAnimation.frameDuration) then
      -- We reset our delay until next frame after changing the current frame
      self.delayToNext = 0

      -- If the next frame is the last one and the animation is in loop, we reset our animation
      if (self.currentAnimation.loop and (self.currentAnimation:isLastFrame(nextframe))) then
        self.currentAnimation.frame = self.currentAnimation.start

      -- If it's not the end of the animation, we update the frame normally
      elseif (not self.currentAnimation:isLastFrame(nextframe)) then
        self.currentAnimation.frame = self.currentAnimation.frame + 1
      end
    end
  elseif (self.delayToNext ~= 0) then
    self.delayToNext = 0
  end
end

function Animator:setMirrored(value)
  self.mirrored = value
end

function Animator:play(animationName, reset)
  -- To start our animation from it's first time. If the new animation is different from the previous one, it'll be done anyway.
  reset = reset or false
  if (type(animationName) ~= 'string' and next(self.currentAnimation) == nil) then
    error('The parameter "animationName" is invalid.')
  end

  if (reset or self.animations[animationName] ~= self.currentAnimation) then
    self.currentAnimation.frame = self.currentAnimation.start
  end

  if not self.playing then self.playing = true end
  self.currentAnimation = self.animations[animationName] ~= nil and self.animations[animationName] or self.currentAnimation
end

function Animator:pause()
  self.playing = false
end

function Animator:stop()
  self.playing = false
  self.currentAnimation.frame = self.currentAnimation.start
end

function Animator:draw(x, y, ox, oy, r, sx, sy)
  if (self.currentAnimation.name) then
    modifier = self.mirrored and -1 or 1
    -- Then we simply draw based on it's specific frame quad and it automagically will render the correct frame
    love.graphics.draw(self.sprite, self.quads[self.currentAnimation.frame], x, y, r or 0, (sx or 1) * modifier, sy or 1, ox or 0, oy or 0)
  end
end

return Animator
