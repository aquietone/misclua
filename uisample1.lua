-- Sample ImGui UI which does not end the script when the UI is closed.
local mq = require('mq')
require('ImGui')

-- Script control variables
local terminate = false

-- UI Control variables
local isOpen, shouldDraw = true, true

local function updateImGui()
    -- Don't draw the UI if the UI was closed by pressing the X button
    if not isOpen then return end

    -- isOpen will be set false if the X button is pressed on the window
    -- shouldDraw will generally always be true unless the window is collapsed
    isOpen, shouldDraw = ImGui.Begin('UI Sample 1', isOpen)
    -- Only draw the window contents if shouldDraw is true
    if shouldDraw then
        if ImGui.Button('End Sample 1') then
            terminate = true
        end
    end
    -- Always call ImGui.End if begin was called
    ImGui.End()
end

-- Register the ImGui callback
mq.imgui.init('uisample1', updateImGui)

-- Keep the script alive until it is /lua stop'd or the end button is pressed
while not terminate do
    -- Delay so that the script doesn't run in a tight loop, and end delay early if terminate is true
    mq.delay(5000, function() return terminate end)
    -- If the window was closed with the X button, the script is actually still running.
    if not isOpen then
        print('End this script with /lua stop uisamples/uisample1')
    end
end