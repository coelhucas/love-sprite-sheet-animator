local Animator = {}
local mtAnimator = { __index = Animator }

local Animation = {}
local mtAnimation = { __index = Animation }

accumulator = 1

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

  vindexAccumulator = 1
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

function Animator:newAnimation(name, start, ending, speed, loop)
  local animation = {}
  animation.start = start or 1
  animation.frame = start or 1
  animation.loop = loop or true
  animation.speed = speed or 1
  animation.ending = ending

  self.animations[name] = animation
  return setmetatable(animation, mtAnimation)
end

function Animator:update(dt)
  -- This is responsible for making the frame changes and animation loop (if needed)
  if (self.playing) then
    self.delayToNext = self.delayToNext + dt * self.currentAnimation.speed
    if (self.delayToNext > 0.1) then
      self.delayToNext = 0
      if (self.currentAnimation.loop and (self.currentAnimation.frame + 1 > table.getn(self.quads) or self.currentAnimation.frame + 1 > self.currentAnimation.ending)) then
        self.currentAnimation.frame = self.currentAnimation.start
      elseif (self.currentAnimation.frame + 1 <= self.currentAnimation.ending) then
        self.currentAnimation.frame = self.currentAnimation.frame + 1
      end
    end
  elseif (self.delayToNext ~= 0) then
    self.delayToNext = 0
  end
end

function Animator:play(animationName, reset)
  -- To start our animation from it's first time. If the new animation is different from the previous one, it'll be done anyway.
  resetFrame = reset or false
  if (animationName == nil and self.currentAnimation == {}) then
    error('Missing parameter "animationName"')
  end

  if (resetFrame or self.animations[animationName] ~= self.currentAnimation) then
    self.currentAnimation.frame = self.currentAnimation.start
  end

  if not playing then self.playing = true end
  self.currentAnimation = self.animations[animationName] ~= nil and self.animations[animationName] or self.currentAnimation
end

function Animator:pause()
  self.playing = false
end

function Animator:stop()
  self.playing = false
  self.currentAnimation.frame = self.currentAnimation.start
end

function Animator:draw(x, y)
  if (self.currentAnimation ~= {}) then
    -- Then we simply draw based on it's specific frame quad and it automagically will render the correct frame
    love.graphics.draw(self.sprite, self.quads[self.currentAnimation.frame], x, y)
  end
end

return Animator
