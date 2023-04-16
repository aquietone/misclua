--[[
splitter.lua v0.1 - aquietone
Lua port of https://github.com/macroquest/macroquest/blob/90e598564c4d7b0358e8e611c9bf0b01a8eaca6e/src/imgui/ImGuiUtils.cpp#L152

Example: Vertical splitter:

local menuSplitter = splitter:new('menu', 10, false, 75, 200)

    local x,y = ImGui.GetCursorPos()
    -- draw vertical splitter
    menuSplitter:draw()
    ImGui.Text('content left of vertical splitter')
    ImGui.SetCursorPos(menuSplitter.offset + menuSplitter.thickness + 5, y)
    ImGui.Text('content right of vertical splitter')

Example: Horizontal splitter:

local headerSplitter = splitter:new('header', 10, true, 75, 200)

    local x,y = ImGui.GetCursorPos()
    -- draw vertical splitter
    headerSplitter:draw(true)
    ImGui.Text('content above horizontal splitter')
    ImGui.SetCursorPos(x, headerSplitter.offset + headerSplitter.thickness + 30)
    ImGui.Text('content below horizontal splitter')

]]
require 'ImGui'

---@class splitter
---@field ID string # Unique ID for the splitter
---@field thickness number # The width or height of the splitter
---@field horizontal boolean # Whether the splitter is horizontal or not
---@field min_size number # The minimum x or y offset the splitter can be dragged to
---@field max_size number # The maximum x or y offset the splitter can be dragged to
---@field offset number # The current x or y offset of the splitter
---@field tmp_offset number # The temporary x or y offset as the splitter is being dragged
local splitter = {}

---@param ID string # Unique ID for the splitter
---@param thickness number # The width or height of the splitter
---@param horizontal boolean # Whether the splitter is horizontal or not
---@param min_size number # The minimum x or y offset the splitter can be dragged to
---@param max_size number # The maximum x or y offset the splitter can be dragged to
function splitter:new(ID, thickness, horizontal, min_size, max_size)
    local s = {
        ID = ID or '',
        thickness = thickness or 10,
        horizontal = horizontal or false,
        min_size = min_size or 75,
        max_size = max_size or 200,
        offset = max_size or 200,
        tmp_offset = max_size or 200
    }
    setmetatable(s, self)
    self.__index = self
    return s
end

---Draws the splitter bar as a button which can be dragged within the defined min and max offsets
function splitter:draw()
    local x,y = ImGui.GetCursorPos()
    local deltaX, deltaY = 0, 0
    if self.horizontal then
        ImGui.SetCursorPosY(y + self.offset)
    else
        ImGui.SetCursorPosX(x + self.offset)
    end

    ImGui.PushStyleColor(ImGuiCol.Button, 0, 0, 0, 0)
    ImGui.PushStyleColor(ImGuiCol.ButtonActive, 0, 0, 0, 0)
    ImGui.PushStyleColor(ImGuiCol.ButtonHovered, 0.6, 0.6, 0.6, 0.1)
    if self.horizontal then
        ImGui.Button('##splitter'..self.ID, -1, self.thickness)
    else
        ImGui.Button('##splitter'..self.ID, self.thickness, -1)
    end
    ImGui.PopStyleColor(3)

    ImGui.SetItemAllowOverlap()

    if ImGui.IsItemActive() then
        deltaX,deltaY = ImGui.GetMouseDragDelta()
        local delta = self.horizontal and deltaY or deltaX

        if delta < self.min_size - self.offset then
            delta = self.min_size - self.offset
        end
        if delta > self.max_size - self.offset then
            delta = self.max_size - self.offset
        end

        self.tmp_offset = self.offset + delta
    else
        self.offset = self.tmp_offset
    end
    ImGui.SetCursorPosX(x)
    ImGui.SetCursorPosY(y)
end

return splitter