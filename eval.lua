-- Probably never actually use this script for anything ever

local mq = require 'mq'
require 'ImGui'

-- GUI Control variables
local openGUI = true
local shouldDrawGUI = true
local terminate = false

local inputs = {}

-- ImGui main function for rendering the UI window
local uisample = function()
    openGUI, shouldDrawGUI = ImGui.Begin('eval', openGUI)
    if shouldDrawGUI then
        if ImGui.Button('Add') then
            table.insert(inputs, '')
        end
        for i,j in ipairs(inputs) do
            inputs[i] = ImGui.InputText('##input'..i, inputs[i])
            local success, result = pcall(loadstring, 'local mq = require(\'mq\'); return '..inputs[i])
            if success then
                if type(result) == 'function' then
                    local s2, funcresult = pcall(result)
                    if s2 then
                        ImGui.Text(tostring(funcresult or ''))
                    end
                end
            else
                ImGui.Text('Failed to parse input string')
            end
        end
    end
    ImGui.End()
    if not openGUI then
        terminate = true
    end
end

mq.imgui.init('eval', uisample)

while not terminate do
    mq.delay(1000)
end
