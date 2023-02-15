-- Sample ImGui UI which performs some action when a button is pressed.
-- This script will also exit when pressing the X on the window.
--- @type Mq
local mq = require('mq')
--- @type ImGui
require('ImGui')

-- Script control variables
local terminate = false

-- UI Control variables
local isOpen, shouldDraw = true, true

-- Store a flag outside of the ImGui callback to track whether the Buff People button was pressed
local shouldBuff = false

-- The buff routine to be called by the main loop
local function doBuffs()
    print('Buffing people now')
end

local function updateImGui()
    -- Don't draw the UI if the UI was closed by pressing the X button
    if not isOpen then return end

    -- isOpen will be set false if the X button is pressed on the window
    -- shouldDraw will generally always be true unless the window is collapsed
    isOpen, shouldDraw = ImGui.Begin('UI Sample 3', isOpen)
    -- Only draw the window contents if shouldDraw is true
    if shouldDraw then
        -- Draw the Buff People button, and set the flag to true which is stored outside the ImGui callback
        -- Do not begin running the buff related code from within the ImGui callback.
        if ImGui.Button('Buff People') then
            shouldBuff = true
        end
    end
    -- Always call ImGui.End if begin was called
    ImGui.End()
end

-- Register the ImGui callback
mq.imgui.init('uisample3', updateImGui)

-- Keep the script alive until it is /lua stop'd or the X is pressed on the window
while isOpen do
    -- If the Buff People button was clicked, shouldBuff will now be true.
    -- Call doBuffs from the main script loop and then set doBuffs back to false so we don't repeatedly try to buff.
    if shouldBuff then
        doBuffs()
        shouldBuff = false
    end
    mq.delay(1000)
end