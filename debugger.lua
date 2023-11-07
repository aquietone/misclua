--[[
    Example:
    Uncomment the test script at the bottom and /lua run debugger

    Usage:
    -- Include the debugger into your lua
    local debugger = require('debugger')
    local debug = debugger.new()

    -- Initialize the debugger imgui window
    debug:init()

    -- Add a table which you want watched by the debugger. It only accepts tables.
    debug:AddWatchedTable('some_table_name', table_to_watch)

    -- Create a button in imgui or use a bind to toggle displaying the debugger.
    if ImGui.Button('Open Debugger') then
        debug:Enable()
    end

    -- From some function you want to debug, capture its local vars:
    function some_function(input1, input2)
        local x
        if debug_flags['some_function'] then
            debug:SetFunctionLocals('some_function', debug:getlocals())
        end
    end
]]
local mq = require('mq')
require('ImGui')

local Debugger = {}
Debugger.__index = Debugger

function Debugger.new(name)
    local newDebugger = setmetatable({
        name = name,
        watched_tables = {},
        current_values = {},
        local_vars = {},
        open = false,
        show = false,
    }, Debugger)
    mq.imgui.init('LuaDebugWindow'..newDebugger.name, function() newDebugger:DrawDebugWindow() end)
    return newDebugger
end

function table.clone(org)
    return {unpack(org)}
end

local function traceback ()
    local level = 3 -- skip traceback() and getlocals() frames
    local stack = 'stack:'
    while true do
        local info = debug.getinfo(level, "nSl")
        if not info then break end
        if info.what == "C" then   -- is a C function?
            stack = stack..'\n\t'.."C function"
        elseif info.what == "Lua" then   -- a Lua function
            stack = stack..'\n\t'..string.format("[%s]:%d: in function '%s'", info.short_src, info.currentline, info.name)
        elseif info.what == "main" then   -- main chunk
            stack = stack..'\n\t'..string.format("[%s]:%d: in main chunk", info.short_src, info.currentline)
        end
        level = level + 1
    end
    return stack
end

function Debugger:getlocals()
    local locals = {}
    local a = 1
    while true do
        local name, value = debug.getlocal(2, a)
        if not name then break end
        locals[name] = value or 'nil'
        a = a + 1
    end
    return {Variables=locals, Traceback=traceback()}
end

function Debugger:Enable()
    self.open = true
end

function Debugger:Disable()
    self.open = false
end

function Debugger:AddWatchedTable(table_name, table_value)
    if not table_name or not table_value or type(table_value) ~= 'table' then return false end
    self.watched_tables[table_name] = table_value
    return true
end

function Debugger:RemoveWatchedTable(table_name)
    if not self.watched_tables[table_name] then return false end
    self.watched_tables[table_name] = nil
    self.current_values[table_name] = nil
    return true
end

function Debugger:SetFunctionLocals(function_name, locals)
    if not function_name or not locals or type(locals) ~= 'table' then return false end
    self.local_vars[function_name] = locals
    return true
end

function Debugger:UnsetFunctionLocals(function_name)
    if not self.local_vars[function_name] then return false end
    self.local_vars[function_name] = nil
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

function Debugger:DrawDebugWindow()
    if not self.open then return end
    self.open, self.show = ImGui.Begin('Lua Debug Window ('..self.name..')', self.open)
    if self.show then
        local first = true
        for table_name, table_value in pairs(self.watched_tables) do
            if first then ImGui.Text('Watched Tables:') first = false end
            if not self.current_values[table_name] then
                self.current_values[table_name] = table.clone(self.watched_tables[table_name])
            end
            DrawTableRoot(table_name, table_value, self.current_values[table_name])
        end
        first = true
        for function_name, function_locals in pairs(self.local_vars) do
            if first then ImGui.Text('Function Local Variables:') first = false end
            DrawTableRoot(function_name, function_locals)
        end
    end
    ImGui.End()
end

-- Begin Test Script
--[[
local debugTableValues = Debugger.new('tables')
debugTableValues:Enable()

local function some_function(input1, input2, input3)
    local x
    debugTableValues:SetFunctionLocals('some_function', debugTableValues:getlocals())
end

local debugFunctionLocals = Debugger.new('functions')
debugFunctionLocals:Enable()

local some_table = {a_value=1, nested_table={b_value=100000}}
debugFunctionLocals:AddWatchedTable('some_table', some_table)

while true do
    mq.delay(1000)
    some_table.a_value = some_table.a_value + 1
    some_table.nested_table.b_value = some_table.nested_table.b_value - 1
    some_function(some_table.a_value, some_table.nested_table.b_value, some_table)
end
]]
-- End Test Script

return Debugger
