require 'ImGui'
local lfs = require 'lfs'

local ImGuiFileDialog = {}

-- GUI Control variables
local openGUI = false
local shouldDrawGUI = true
local selected = ''
local internal_selected = ''
local submitted = false

-- ImGui main function for rendering the UI window
ImGuiFileDialog.draw_file_selector = function(path, pattern)
    openGUI, shouldDrawGUI = ImGui.Begin('Select a file...', openGUI)
    if shouldDrawGUI then
        if ImGui.Button('Open') then
            openGUI = false
            selected = internal_selected
        end
        ImGui.SameLine()
        if ImGui.Button('Cancel') then
            openGUI = false
            selected = ''
        end
        ImGui.SameLine()
        internal_selected, submitted = ImGui.InputTextWithHint('##filename', 'Enter file name here...', internal_selected, ImGuiInputTextFlags.EnterReturnsTrue)
        if submitted then
            openGUI = false
            selected = internal_selected
        end
        if ImGui.BeginChild('FileTable') then
            local flags = bit32.bor(ImGuiTableFlags.Resizable, ImGuiTableFlags.RowBg, ImGuiTableFlags.BordersOuter, ImGuiTableFlags.BordersV, ImGuiTableFlags.NoBordersInBody, ImGuiTableFlags.ScrollY)
            if ImGui.BeginTable('File Dialog', 3, flags) then
                ImGui.TableSetupColumn('File Name', ImGuiTableColumnFlags.None)
                ImGui.TableSetupColumn('Size', ImGuiTableColumnFlags.None)
                ImGui.TableSetupColumn('Last Updated', ImGuiTableColumnFlags.None)
                ImGui.TableSetupScrollFreeze(0, 1)
                ImGui.TableHeadersRow()
                ImGui.TableNextRow()
                ImGui.TableNextColumn()
                for file in lfs.dir(path) do
                    if file ~= '.' and file ~= '..' and file:find(pattern) then--and file:lower():find(internal_selected) then
                        if ImGui.Selectable(file, internal_selected == file, ImGuiSelectableFlags.SpanAllColumns) then
                            if internal_selected ~= file then
                                internal_selected = file
                            end
                        end
                        ImGui.TableNextColumn()
                        local f = path..'/'..file
                        local attr = lfs.attributes(f)
                        ImGui.Text(attr.size)
                        ImGui.TableNextColumn()
                        ImGui.Text(os.date("%c", attr.modification))
                        ImGui.TableNextRow()
                        ImGui.TableNextColumn()
                    end
                end
                ImGui.EndTable()
            end
        end
        ImGui.EndChild()
    end
    ImGui.End()
end

ImGuiFileDialog.is_file_selector_open = function()
    return openGUI
end

ImGuiFileDialog.set_file_selector_open = function(open)
    openGUI = open
    internal_selected = selected
end

ImGuiFileDialog.get_filename = function()
    return selected
end

return ImGuiFileDialog