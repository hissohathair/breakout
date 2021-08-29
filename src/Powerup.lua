--[[
    GD50
    Breakout Remake

    -- Powerup Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents a "Powerup" which starts falling from the screen, and when hit
    by the player's paddle, will spawn additional balls.
]]

Powerup = Class{}

local POWERUP_SPEED = 30
local ROTATION_SPEED = 0.35

function Powerup:init(x, y)
    self.x = x
    self.y = y
    self.width = 16
    self.height = 16

    -- on init, begin falling
    self.rotation = 0
    self.dy = POWERUP_SPEED
    self.inPlay = true 
    self.skin = 9 -- 9th powerup sprite (see Util.lua)
end

--[[
    Called when a brick is spawning a new powerup
]]
function Powerup:reset(brick)
    self.x = brick.x + brick.width / 2
    self.y = brick.y + brick.height / 2
    self.rotation = 0
    self.dy = POWERUP_SPEED
    self.inPlay = true 
    self.skin = 9
end

--[[
    Expects an argument with a bounding box for the paddle, and returns true if
    the bounding boxes of this and the argument overlap.

    TODO: This code copied from Ball.lua, should probably move AABB test
    to Util.lua
]]
function Powerup:collides(target)
    -- first, check to see if the left edge of either is farther to the right
    -- than the right edge of the other
    if self.x > target.x + target.width or target.x > self.x + self.width then
        return false
    end

    -- then check to see if the bottom edge of either is higher than the top
    -- edge of the other
    if self.y > target.y + target.height or target.y > self.y + self.height then
        return false
    end 

    -- if the above aren't true, they're overlapping
    return true
end

--[[
    Called when the player hits the powerup with their paddle. Currently only
    skip #9 is supported -- this spawns more balls from the paddle.
]]
function Powerup:hit(paddle, orig_balls)
    -- register the hit
    self.inPlay = false
    gSounds['powerup']:play()

    -- execute the powerup (2 new balls, flying off randomly)
    local balls = { Ball(), Ball() }
    for k, ball in pairs(balls) do
        -- ball spawns at players paddle
        ball.skin = math.random(7)
        ball.x = paddle.x + (paddle.width / 2) - (ball.width / 2)
        ball.y = paddle.y - ball.height

        -- ball flies off in randomish direction
        ball.dx = math.random(-200, 200)
        ball.dy = math.random(-50, -60)
    end

    -- merge in the list of original balls
    i = 3
    for k, ball in pairs(orig_balls) do
        balls[i] = ball
        i = i + 1
    end
    return balls
end

function Powerup:update(dt)
    -- fall and spin
    self.y = self.y + self.dy * dt
    self.rotation = self.rotation + ROTATION_SPEED * dt
    if self.rotation > math.pi * 2 then
        self.rotation = 0 
    end

    -- powerup goes out of play once it drops off screen
    if self.y > VIRTUAL_HEIGHT then
        self.inPlay = false
    end
end

function Powerup:render()
    love.graphics.draw(gTextures['main'], gFrames['powerups'][self.skin],
        self.x, self.y, self.rotation)
end

