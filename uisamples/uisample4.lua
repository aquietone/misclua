-- Sample ImGui UI which shows a push/pop vs a set
--- @type Mq
local mq = require('mq')
--- @type ImGui
require('ImGui')

-- Script control variables
local terminate = false

-- UI Control variables
local isOpen, shouldDraw = true, true

local favoriteFood = ''
local favoriteDrink = ''

local function updateImGui()
    -- Don't draw the UI if the UI was closed by pressing the X button
    if not isOpen then return end

    -- isOpen will be set false if the X button is pressed on the window
    -- shouldDraw will generally always be true unless the window is collapsed
    isOpen, shouldDraw = ImGui.Begin('UI Sample 4', isOpen)
    -- Only draw the window contents if shouldDraw is true
    if shouldDraw then
        ImGui.Text('All ImGui "Push" function calls must have a matching "Pop" call.')
        ImGui.PushItemWidth(300)
        favoriteFood = ImGui.InputText('Favorite Food', favoriteFood)
        ImGui.PopItemWidth()
        ImGui.Text('Alternatively, use ImGui.SetNextItemWidth(#) instead, which doesn\'t require a pop after')
        ImGui.SetNextItemWidth(100)
        favoriteDrink = ImGui.InputText('Favorite Drink', favoriteDrink)
        ImGui.Text('Some functions take their own sizes as inputs and are not impacted by SetNextItemWidth or PushItemWidth')
        if ImGui.Button('End Sample 4', 300, 50) then
            terminate = true
        end
    end
    -- Always call ImGui.End if begin was called
    ImGui.End()
end

-- Register the ImGui callback
mq.imgui.init('uisample4', updateImGui)

-- Keep the script alive until it is /lua stop'd or the end button is pressed
while not terminate do
    -- Delay so that the script doesn't run in a tight loop, and end delay early if terminate is true
    mq.delay(5000, function() return terminate end)
    -- If the window was closed with the X button, the script is actually still running.
    if not isOpen then
        print('End this script with /lua stop uisamples/uisample4')
    end
end