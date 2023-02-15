--- @type Mq
local mq = require('mq')
---@class Timer
---@field expiration number #Time, in milliseconds, after which the timer expires.
---@field start_time number #Time since epoch, in milliseconds, when timer is counting from.
local Timer = {
    expiration = 0,
    start_time = 0,
}

---Initialize a new timer istance.
---@param expiration number @The number, in milliseconds, after which the timer will expire.
---@return Timer @The timer instance.
function Timer:new(expiration)
    local t = {
        start_time = mq.gettime(),
        expiration = expiration
    }
    setmetatable(t, self)
    self.__index = self
    return t
end

---Reset the start time value to the current time.
---@param to_value? number @The value to reset the timer to.
function Timer:reset(to_value)
    self.start_time = to_value or mq.gettime()
end

---Check whether the specified timer has passed its expiration.
---@return boolean @Returns true if the timer has expired, otherwise false.
function Timer:timer_expired()
    return mq.gettime() - self.start_time > self.expiration
end

---Get the time remaining before the timer expires.
---@return number @Returns the number of milliseconds remaining until the timer expires.
function Timer:time_remaining()
    return self.expiration - (mq.gettime() - self.start_time)
end

--[[
Uncomment the while loop for example usage:
Running lua script 'timer' with PID 10
not yet, remaining=10000
not yet, remaining=9004
not yet, remaining=8003
not yet, remaining=7003
not yet, remaining=6004
not yet, remaining=5004
not yet, remaining=4004
not yet, remaining=3005
not yet, remaining=2005
not yet, remaining=1005
not yet, remaining=6
timer expired
Ending lua script 'timer' with PID 10 and status 0
]]

--[[
local my_timer = Timer:new(10000)

while true do
    if my_timer:timer_expired() then
        print('timer expired')
        break
    else
        printf('not yet, remaining=%s', my_timer:time_remaining())
    end
    mq.delay(1000)
end
]]

return Timer
