-- Sample ImGui UI which does not end the script when the UI is closed
--- @type Mq
local mq = require('mq')
--- @type ImGui
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

mq.imgui.init('uisample1', updateImGui)

while not terminate do
    mq.delay(1000)
end