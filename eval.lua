-- eval.lua
---@type Mq
local mq = require 'mq'
---@type ImGui
require 'ImGui'

-- GUI Control variables
local openGUI = true
local shouldDrawGUI = true
local terminate = false

local inputs = {}

local function drawControlButtons()
    if ImGui.Button('Add') then
        table.insert(inputs, '')
    end
    ImGui.SameLine()
    ImGui.PushStyleColor(ImGuiCol.Button, .6, 0, 0, 1)
    if ImGui.Button('Clear') then
        inputs = {}
    end
    ImGui.PopStyleColor()
end

local function processInput(input)
    local success, result = pcall(loadstring, 'local mq = require(\'mq\'); return '..input)
    if success then
        if type(result) == 'function' then
            success, result = pcall(result)
            if success then
                local mqtype = nil
                if type(result) == 'userdata' then
                    mqtype = pcall(mq.gettype, result)
                end
                return result, type(result), mqtype and mqtype or ''
            end
        end
    end
end

local  function handleEvalEntry(input)
    if not input or input:len() == 0 then return end
    -- evaluating 'mq.tlo' causes a client crash, so prevent parsing it and warn about case sensitivity instead.
    local output, outputType, mqType
    if input:lower():find('mq.tlo') and not input:find('mq.TLO') then
        output = '\'mq.TLO\' is case sensitive'
        outputType = 'N/A'
        mqType = 'N/A'
    else
        output, outputType, mqType = processInput(input)
    end
    ImGui.TextColored(0,1,1,1,'Output:')
    ImGui.SameLine()
    ImGui.SetCursorPosX(60)
    ImGui.Text("%s", output)
    ImGui.TextColored(0,1,1,1,'Type:')
    ImGui.SameLine()
    ImGui.SetCursorPosX(60)
    ImGui.Text("%s", outputType)
    ImGui.SameLine()
    ImGui.SetCursorPosX(140)
    ImGui.TextColored(0,1,1,1,'MQType:')
    ImGui.SameLine()
    ImGui.SetCursorPosX(200)
    ImGui.Text("%s", mqType)
end

local evalui = function()
    openGUI, shouldDrawGUI = ImGui.Begin('Lua Expression Evaluator', openGUI)
    if shouldDrawGUI then
        local width, height = ImGui.GetWindowSize()
        if ImGui.GetContentRegionAvail() < 350 then
            ImGui.SetWindowSize(350, height)
        end
        drawControlButtons()

        ImGui.PushStyleColor(ImGuiCol.Button, .6, 0, 0, 1)
        for i,j in ipairs(inputs) do
            ImGui.PushItemWidth(width-45)
            inputs[i] = ImGui.InputTextWithHint('##input'..i, 'mq.TLO.Me.CleanName()', inputs[i])
            ImGui.PopItemWidth()
            ImGui.SameLine()

            if ImGui.Button('X##'..i) then
                table.remove(inputs, i)
            end

            handleEvalEntry(inputs[i])
        end
        ImGui.PopStyleColor()
    end
    ImGui.End()
    if not openGUI then
        terminate = true
    end
end

mq.imgui.init('eval', evalui)

while not terminate do
    mq.delay(1000)
end
