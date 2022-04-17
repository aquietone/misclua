require 'ImGui'
local lfs = require 'lfs'

local ImGuiFileDialog = {}

-- GUI Control variables
local openGUI = false
local shouldDrawGUI = true
local selected = ''
local internal_selected = ''
local submitted = false

local sorted_items = {}

local ColumnID_Name = 0
local ColumnID_Size = 1
local ColumnID_Date = 2

local sortmappings = {
    [0]='name',
    [1]='size',
    [2]='date',
}
local current_sort_specs = nil
local function CompareWithSortSpecs(a, b)
    for n = 1, current_sort_specs.SpecsCount, 1 do
        local sort_spec = current_sort_specs:Specs(n)
        local delta = 0

        local aval = a[sortmappings[sort_spec.ColumnUserID]]
        local bval = b[sortmappings[sort_spec.ColumnUserID]]
        if sort_spec.ColumnUserID == ColumnID_Name then
            aval = aval:lower()
            bval = bval:lower()
        end
        if aval < bval then
            delta = -1
        elseif bval < aval then
            delta = 1
        else
            delta = 0
        end

        if delta ~= 0 then
            if sort_spec.SortDirection == ImGuiSortDirection.Ascending then
                return delta < 0
            end
            return delta > 0
        end
    end

    -- Always return a way to differentiate items.
    return a.name < b.name
end

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
        if #sorted_items == 0 then
            for file in lfs.dir(path) do
                if file ~= '.' and file ~= '..' and file:find(pattern) then
                    local f = path..'/'..file
                    local attr = lfs.attributes(f)
                    table.insert(sorted_items, {name=file,size=attr.size,date=attr.modification})
                end
            end
        end
        if ImGui.BeginChild('FileTable') then
            local flags = bit32.bor(ImGuiTableFlags.Resizable, ImGuiTableFlags.Sortable, ImGuiTableFlags.RowBg, ImGuiTableFlags.BordersOuter, ImGuiTableFlags.BordersV, ImGuiTableFlags.NoBordersInBody, ImGuiTableFlags.ScrollY)
            if ImGui.BeginTable('File Dialog', 3, flags) then
                ImGui.TableSetupColumn('File Name', ImGuiTableColumnFlags.DefaultSort, -1.0, ColumnID_Name)
                ImGui.TableSetupColumn('Size', ImGuiTableColumnFlags.DefaultSort, -1.0, ColumnID_Size)
                ImGui.TableSetupColumn('Last Updated', ImGuiTableColumnFlags.DefaultSort, -1.0, ColumnID_Date)
                ImGui.TableSetupScrollFreeze(0, 1)

                local sort_specs = ImGui.TableGetSortSpecs()
                if sort_specs then
                    if sort_specs.SpecsDirty then
                        if #sorted_items > 1 then
                            current_sort_specs = sort_specs
                            table.sort(sorted_items, CompareWithSortSpecs)
                            current_sort_specs = nil
                        end
                        sort_specs.SpecsDirty = false
                    end
                end
                ImGui.TableHeadersRow()

                local clipper = ImGuiListClipper.new()
                clipper:Begin(#sorted_items)
                while clipper:Step() do
                    for row_n = clipper.DisplayStart, clipper.DisplayEnd, 1 do
                        local file = sorted_items[row_n + 1]
                        if file then
                            ImGui.TableNextRow()
                            ImGui.TableNextColumn()
                            if ImGui.Selectable(file.name, internal_selected == file.name, ImGuiSelectableFlags.SpanAllColumns) then
                                if internal_selected ~= file.name then
                                    internal_selected = file.name
                                end
                            end
                            if ImGui.IsItemHovered() and ImGui.IsMouseDoubleClicked(0) then
                                openGUI = false
                                selected = internal_selected
                            end
                            ImGui.TableNextColumn()
                            ImGui.Text(file.size)
                            ImGui.TableNextColumn()
                            ImGui.Text(os.date("%c", file.date))
                        end
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

ImGuiFileDialog.reset_filename = function()
    selected = ''
end

return ImGuiFileDialog