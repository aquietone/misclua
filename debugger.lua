--[[
    Example:
    Uncomment the test script at the bottom and /lua run debugger

    Usage:
    -- Include the debugger into your lua
    local debugger = require('debugger')

    -- Initialize the debugger imgui window
    debugger.init()

    -- Add a table which you want watched by the debugger. It only accepts tables.
    debugger.AddWatchedTable('some_table_name', table_to_watch)

    -- Create a button in imgui or use a bind to toggle displaying the debugger.
    if ImGui.Button('Open Debugger') then
        debugger.Enable()
    end

    -- From some function you want to debug, capture its local vars:
    function some_function(input1, input2)
        local x
        if debug['some_function'] then
            debugger.SetFunctionLocals('some_function', debugger.getlocals())
        end
    end
]]
local mq = require('mq')
require('ImGui')

local watched_tables = {}
local current_values = {}
local local_vars = {}

function table.clone(org)
    return {unpack(org)}
end

local open, show = false, false
local Debugger = {}

function Debugger.getlocals()
    local locals = {}
    local a = 1
    while true do
        local name, value = debug.getlocal(2, a)
        if not name then break end
        locals[name] = value or 'nil'
        a = a + 1
    end
    return locals
end

function Debugger.Init()
    mq.imgui.init('LuaDebugWindow', Debugger.DrawDebugWindow)
end

function Debugger.Enable()
    open = true
end

function Debugger.Disable()
    open = false
end

function Debugger.AddWatchedTable(table_name, table_value)
    if not table_name or not table_value or type(table_value) ~= 'table' then return false end
    watched_tables[table_name] = table_value
    return true
end

function Debugger.RemoveWatchedTable(table_name)
    if not watched_tables[table_name] then return false end
    watched_tables[table_name] = nil
    current_values[table_name] = nil
    return true
end

function Debugger.SetFunctionLocals(function_name, locals)
    local_vars[function_name] = locals
end

function Debugger.UnsetFunctionLocals(function_name)
    if not local_vars[function_name] then return false end
    local_vars[function_name] = nil
    return true
end

local function DrawTable(table_value, current)
    for key, value in pairs(table_value) do
        if value and type(value) == 'table' then
            ImGui.PushStyleColor(ImGuiCol.Text, 1, 1, 0, 1)
            if ImGui.TreeNode(key) then
                ImGui.PopStyleColor()
                if current and not current[key] then
                    current[key] = table.clone(table_value)
                end
                DrawTable(value, current and current[key] or nil)
                ImGui.TreePop()
            else
                ImGui.PopStyleColor()
            end
        else
            if current and not current[key] then current[key] = value end
            ImGui.TextColored(1, 1, 0, 1, '%s:', key)
            ImGui.SameLine()
            ImGui.Text(value)
            if current and (value ~= current[key] or (current[key..'_debug_timer'] and mq.gettime() - current[key..'_debug_timer'] < 500)) then
                ImGui.SameLine()
                ImGui.TextColored(0, 1, 0, 1, '(Changed)')
                if value ~= current[key] then
                    current[key] = value
                    current[key..'_debug_timer'] = mq.gettime()
                end
            end
        end
    end
end

local function DrawTableRoot(table_name, table_value, current)
    ImGui.PushStyleColor(ImGuiCol.Text, 1, 1, 0, 1)
    if ImGui.TreeNode(table_name) then
        ImGui.PopStyleColor()
        DrawTable(table_value, current)
        ImGui.TreePop()
    else
        ImGui.PopStyleColor()
    end
end

function Debugger.DrawDebugWindow()
    if not open then return end
    open, show = ImGui.Begin('Lua Debug Window', open)
    if show then
        ImGui.Text('Watched Tables:')
        for table_name, table_value in pairs(watched_tables) do
            if not current_values[table_name] then
                current_values[table_name] = table.clone(watched_tables[table_name])
            end
            DrawTableRoot(table_name, table_value, current_values[table_name])
        end
        ImGui.Text('Function Local Variables:')
        for function_name, function_locals in pairs(local_vars) do
            DrawTableRoot(function_name, function_locals)
        end
    end
    ImGui.End()
end

-- Begin Test Script
--[[
local function some_function(input1, input2, input3)
    local x
    Debugger.SetFunctionLocals('some_function', Debugger.getlocals())
end

local some_table = {a_value=1, nested_table={b_value=100000}}
Debugger.Init()
Debugger.AddWatchedTable('some_table', some_table)
Debugger.Enable()
while true do
    mq.delay(1000)
    some_table.a_value = some_table.a_value + 1
    some_table.nested_table.b_value = some_table.nested_table.b_value - 1
    some_function(some_table.a_value, some_table.nested_table.b_value, some_table)
end
]]
-- End Test Script

return Debugger