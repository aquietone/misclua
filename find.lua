--- @type Mq
local mq = require("mq")

--- @type ImGui
require("ImGui")

local openGUI = true
local shouldDrawGUI = true

-- Constants
local ICON_WIDTH = 20
local ICON_HEIGHT = 20
local COUNT_X_OFFSET = 39
local COUNT_Y_OFFSET = 23
local EQ_ICON_OFFSET = 500
local INVENTORY_DELAY_SECONDS = 0

-- EQ Texture Animation references
local animItems = mq.FindTextureAnimation("A_DragItem")
local animBox = mq.FindTextureAnimation("A_RecessedBox")

-- Bag Contents
local items = {}
local filteredItems = {}

-- Bag Options
local sortOrder = { name = false, stack = false }

-- GUI Activities

local startTime = os.time()
local filterText = ""
local filterChanged = true
local forceRefresh = false

local slotFilter = 'none'
local slotFilterChanged = false

local usedSlots = 0
local selectedItems = {}
--mq.TLO.FindItem('vadd').WornSlot(1)()
local invslots = {'charm','leftear','head','face','rightear','neck','shoulder','arms','back','leftwrist','rightwrist','ranged','hands','mainhand','offhand','leftfinger','rightfinger','chest','legs','feet','waist','powersource','ammo','none'}

local function helpMarker(desc)
    ImGui.TextDisabled("(?)")
    if ImGui.IsItemHovered() then
        ImGui.BeginTooltip()
        ImGui.PushTextWrapPos(ImGui.GetFontSize() * 35.0)
        ImGui.TextUnformatted(desc)
        ImGui.PopTextWrapPos()
        ImGui.EndTooltip()
    end
end

-- Sort routines
local function sortInventory()
    -- Various Sorting
    if sortOrder.name and sortOrder.stack then
        table.sort(items, function(a, b) return a.item.Stack() > b.item.Stack() or (a.item.Stack() == b.item.Stack() and a.item.Name() < b.item.Name()) end)
    elseif sortOrder.stack then
        table.sort(items, function(a, b) return a.item.Stack() > b.item.Stack() end)
    elseif sortOrder.name then
        table.sort(items, function(a, b) return a.item.Name() < b.item.Name() end)
    end
end

-- The beast - this routine is what builds our inventory.
local function createInventory()
    if (os.difftime(os.time(), startTime)) > INVENTORY_DELAY_SECONDS or #items == 0 or forceRefresh then
        startTime = os.time()
        forceRefresh = false
        filterChanged = true
        slotFilterChanged = true
        items = {}
        for i = 23, 34, 1 do
            local slot = mq.TLO.Me.Inventory(i)
            if slot.Container() and slot.Container() > 0 then
                for j = 1, (slot.Container()), 1 do
                    if (slot.Item(j)()) then
                        table.insert(items, {item=slot.Item(j)})
                    end
                end
                table.insert(items, {item=slot})
            elseif slot.ID() ~= nil then
                table.insert(items, {item=slot}) -- We have an item in a bag slot
            end
        end
        usedSlots = #items
        for i = 1, 24, 1 do
            local slot = mq.TLO.Me.Bank(i)
            if slot.Container() and slot.Container() > 0 then
                for j = 1, (slot.Container()), 1 do
                    if (slot.Item(j)()) then
                        table.insert(items, {item=slot.Item(j),bank=true})
                    end
                end
                table.insert(items, {item=slot,bank=true})
            elseif slot.ID() ~= nil then
                table.insert(items, {item=slot,bank=true}) -- We have an item in a bank slot
            end
        end
        for i = 1, 2, 1 do
            local slot = mq.TLO.Me.SharedBank(i)
            if slot.Container() and slot.Container() > 0 then
                for j = 1, (slot.Container()), 1 do
                    if (slot.Item(j)()) then
                        table.insert(items, {item=slot.Item(j),sharedbank=true})
                    end
                end
                table.insert(items, {item=slot,sharedbank=true})
            elseif slot.ID() ~= nil then
                table.insert(items, {item=slot,sharedbank=true}) -- We have an item in a bank slot
            end
        end
        for i = 0, 22, 1 do
            local slot = mq.TLO.InvSlot(i).Item
            if slot.ID() ~= nil then
                table.insert(items, {item=slot,invslot=i})
                for j=1,8 do
                    if slot.AugSlot(j)() then
                        table.insert(items, {item=slot.AugSlot(j).Item, invslot=i, augslot=j})
                    end
                end
            end
        end
        --sortInventory()
    end
end

-- Converts between ItemSlot and /itemnotify pack or bank numbers
local function toPackOrBank(itemSlot, inBank, inSharedBank)
    if inBank then return 'bank'..tostring(itemSlot + 1) end
    if inSharedBank then return 'sharedbank'..tostring(itemSlot + 1) end
    return 'pack'..tostring(itemSlot - 22)
end

-- Converts between ItemSlot2 and /itemnotify numbers
local function toBagSlot(slot_number)
    return slot_number + 1
end

-- Displays static utilities that always show at the top of the UI
local function displayBagUtilities()
    ImGui.PushItemWidth(200)
    local text, selected = ImGui.InputText("Filter", filterText)
    ImGui.PopItemWidth()
    if selected and filterText ~= text then
        filterText = text
        filterChanged = true
    end
    ImGui.SameLine()
    if ImGui.SmallButton("Clear") then filterText = "" filterChanged = true end
    ImGui.SameLine()
    if ImGui.SmallButton("AutoInventory") then mq.cmd('/autoinv') end
    ImGui.SameLine()
    ImGui.PushItemWidth(100)
    if ImGui.BeginCombo('Slot Type', slotFilter) then
        for _,j in ipairs(invslots) do
            if ImGui.Selectable(j, j == slotFilter) then
                slotFilter = j
                slotFilterChanged = true
            end
        end
        ImGui.EndCombo()
    end
    ImGui.PopItemWidth()
    --ImGui.SameLine()
    --if ImGui.SmallButton("Testing") then
    --    for label, item in pairs(selectedItems) do
    --        print(("%s: %s"):format(label, item.Name()))
    --    end
    --end
end

-- Display the collapasable menu area above the items
local function displayBagOptions()

    if not ImGui.CollapsingHeader("Bag Options") then
        ImGui.NewLine()
        return
    end

    if ImGui.Checkbox("Name", sortOrder.name) then
        sortOrder.name = true
    else
        sortOrder.name = false
    end
    ImGui.SameLine()
    helpMarker("Order items from your inventory sorted by the name of the item.")

    if ImGui.Checkbox("Stack", sortOrder.stack) then
        sortOrder.stack = true
    else
        sortOrder.stack = false
    end
    ImGui.SameLine()
    helpMarker("Order items with the largest stacks appearing first.")

    ImGui.Separator()
    ImGui.NewLine()
end

-- Helper to create a unique hidden label for each button.  The uniqueness is
-- necessary for drag and drop to work correctly.
local function buttonLabel(itemSlot, itemSlot2, inBank, inSharedBank, invslot, augslot)
    if augslot then return string.format('##augslot_%s_%s', invslot, augslot) end
    if invslot then return string.format("##invslot_%s", invslot) end
    local container = 'slot'
    if inBank then container = 'bank' end
    if inSharedBank then container = 'sharedbank' end
    if itemSlot2 == -1 then
        return string.format("##%s_%s", container, itemSlot)
    else
        return string.format("##%s_%s_slot_%s", container, itemSlot, itemSlot2)
    end
end

local function getItemLocation(itemSlot, itemSlot2, inBank, inSharedBank, invslot, augslot)
    if augslot then return invslots[invslot+1] .. ' aug ' .. augslot end
    if invslot then return invslots[invslot+1] end
    if itemSlot2 == -1 then
        local prefix = ''
        if inBank then return string.format('bank %s', itemSlot+1) end
        if inSharedBank then return string.format('sharedbank %s', itemSlot+1) end
        return string.format('pack %s', itemSlot-22)
    else
        return "in "..toPackOrBank(itemSlot, inBank, inSharedBank).." "..toBagSlot(itemSlot2)
    end
end

local function drawItemRow(item)
    local itemName = item.item.Name()
    local itemIcon = item.item.Icon()
    local itemSlot = item.item.ItemSlot()
    local itemSlot2 = item.item.ItemSlot2()
    local stack = item.item.Stack()
    local label = buttonLabel(itemSlot, itemSlot2, item.bank, item.sharedbank, item.invslot, item.augslot)

    if ImGui.Checkbox(label..'checkbox', selectedItems[label] ~= nil) then
        selectedItems[label] = item.item
    else
        selectedItems[label] = nil
    end
    ImGui.TableNextColumn()

    -- Reset the cursor to start position, then fetch and draw the item icon
    local cursor_x, cursor_y = ImGui.GetCursorPos()
    animItems:SetTextureCell(itemIcon - EQ_ICON_OFFSET)
    ImGui.DrawTextureAnimation(animItems, ICON_WIDTH, ICON_HEIGHT)

    -- Reset the cursor to start position, then draw a transparent button (for drag & drop)
    ImGui.SetCursorPos(cursor_x, cursor_y)
    ImGui.PushStyleColor(ImGuiCol.Button, 0, 0, 0, 0)
    ImGui.PushStyleColor(ImGuiCol.ButtonHovered, 0, 0.3, 0, 0.2)
    ImGui.PushStyleColor(ImGuiCol.ButtonActive, 0, 0.3, 0, 0.3)
    ImGui.Selectable(label, false, ImGuiSelectableFlags.SpanAllColumns)
    ImGui.PopStyleColor(3)

    local itemLocation = getItemLocation(itemSlot, itemSlot2, item.bank, item.sharedbank, item.invslot, item.augslot)
    if not item.augslot and (not (item.bank or item.sharedbank) or mq.TLO.Window('BigBankWnd').Open()) then
        if ImGui.IsItemHovered() and ImGui.IsMouseReleased(ImGuiMouseButton.Left) then
            mq.cmdf("/nomodkey /shiftkey /itemnotify %s leftmouseup", itemLocation)
            forceRefresh = true
        end
        if ImGui.IsItemHovered() and ImGui.IsMouseReleased(ImGuiMouseButton.Right) then
            mq.cmdf('/squelch /nomodkey /altkey /itemnotify "%s" leftmouseup', itemName)
        end
    end

    ImGui.TableNextColumn()

    ImGui.Text(itemName)

    ImGui.TableNextColumn()

    -- Overlay the stack size text in the lower right corner
    if stack > 1 then
        ImGui.Text(tostring(stack))
    else
        ImGui.Text('1')
    end

    ImGui.TableNextColumn()

    ImGui.Text(itemLocation)
end

-- If there is an item on the cursor, display it.
local function displayItemOnCursor()
    if mq.TLO.Cursor() then
        local cursor_item = mq.TLO.Cursor -- this will be an MQ item, so don't forget to use () on the members!
        local mouse_x, mouse_y = ImGui.GetMousePos()
        local window_x, window_y = ImGui.GetWindowPos()
        local icon_x = mouse_x - window_x + 10
        local icon_y = mouse_y - window_y + 10
        local stack_x = icon_x + COUNT_X_OFFSET
        local stack_y = icon_y + COUNT_Y_OFFSET
        local text_size = ImGui.CalcTextSize(tostring(cursor_item.Stack()))
        ImGui.SetCursorPos(icon_x, icon_y)
        animItems:SetTextureCell(cursor_item.Icon() - EQ_ICON_OFFSET)
        ImGui.DrawTextureAnimation(animItems, ICON_WIDTH, ICON_HEIGHT)
        if cursor_item.Stackable() then
            ImGui.SetCursorPos(stack_x, stack_y)
            ImGui.DrawTextureAnimation(animBox, text_size, ImGui.GetTextLineHeight())
            ImGui.SetCursorPos(stack_x - text_size, stack_y)
            ImGui.TextUnformatted(tostring(cursor_item.Stack()))
        end
    end
end

local ColumnID_Checkbox = 1
local ColumnID_Icon = 2
local ColumnID_Name = 3
local ColumnID_Quantity = 4
local ColumnID_Slot = 5

local current_sort_specs = nil
local function CompareWithSortSpecs(a, b)
    local aName = a and a.item.Name() or ''
    local bName = b and b.item.Name() or ''
    for n = 1, current_sort_specs.SpecsCount, 1 do
        -- Here we identify columns using the ColumnUserID value that we ourselves passed to TableSetupColumn()
        -- We could also choose to identify columns based on their index (sort_spec.ColumnIndex), which is simpler!
        local sort_spec = current_sort_specs:Specs(n)
        local delta = 0

        if sort_spec.ColumnUserID == ColumnID_Name then
            if aName < bName then
                delta = -1
            elseif bName < aName then
                delta = 1
            else
                delta = 0
            end
        elseif sort_spec.ColumnUserID == ColumnID_Quantity then
            delta = (a and a.item.Stack() or 1) - (b and b.item.Stack() or 1)
        end

        if delta ~= 0 then
            if sort_spec.SortDirection == ImGuiSortDirection.Ascending then
                return delta < 0
            end
            return delta > 0
        end
    end

    -- Always return a way to differentiate items.
    -- Your own compare function may want to avoid fallback on implicit sort specs e.g. a Name compare if it wasn't already part of the sort specs.
    return aName < bName
end

local TABLE_FLAGS = bit32.bor(ImGuiTableFlags.ScrollY,ImGuiTableFlags.RowBg,ImGuiTableFlags.BordersOuter,ImGuiTableFlags.BordersV,ImGuiTableFlags.SizingStretchSame,ImGuiTableFlags.Sortable)
local doSort = true
---Handles the bag layout of individual items
local function displayBagContent()
    createInventory()
    --ImGui.SetWindowFontScale(1.25)
    --ImGui.SetCursorPosY(ImGui.GetCursorPosY() - 20)
    --ImGui.TextUnformatted(string.format("Used/Free Slots (%s/%s)", usedSlots, mq.TLO.Me.FreeInventory()))
    --ImGui.SetWindowFontScale(1.0)

    if ImGui.BeginTable('bagtable', 5, TABLE_FLAGS) then
        ImGui.TableSetupScrollFreeze(0, 1)
        ImGui.TableSetupColumn('##checkbox', ImGuiTableColumnFlags.NoSort, 1, ColumnID_Checkbox)
        ImGui.TableSetupColumn('##icon', ImGuiTableColumnFlags.NoSort, 1, ColumnID_Icon)
        ImGui.TableSetupColumn('Name', ImGuiTableColumnFlags.DefaultSort, 5, ColumnID_Name)
        ImGui.TableSetupColumn('Quantity', ImGuiTableColumnFlags.DefaultSort, 2, ColumnID_Quantity)
        ImGui.TableSetupColumn('Slot', ImGuiTableColumnFlags.NoSort, 2, ColumnID_Slot)
        ImGui.TableHeadersRow()

        if filterChanged or slotFilterChanged then
            filteredItems = {}
            if filterText ~= '' then
                for i,item in ipairs(items) do
                    if string.match(string.lower(item.item.Name()), string.lower(filterText)) then
                        if slotFilter == 'none' or item.item.WornSlot(slotFilter)() then
                            table.insert(filteredItems, item)
                        end
                    end
                end
            elseif slotFilter ~= 'none' then
                for i,item in ipairs(items) do
                    if item.item.WornSlot(slotFilter)() then
                        table.insert(filteredItems, item)
                    end
                end
            else
                filteredItems = items
            end
            filterChanged = false
            slotFilterChanged = false
            doSort = true
        end
        local sort_specs = ImGui.TableGetSortSpecs()
        if sort_specs then
            if sort_specs.SpecsDirty or doSort then
                print(string.format('Sort %d items:', #filteredItems))
                for n = 1, sort_specs.SpecsCount, 1 do
                    -- Here we identify columns using the ColumnUserID value that we ourselves passed to TableSetupColumn()
                    -- We could also choose to identify columns based on their index (sort_spec.ColumnIndex), which is simpler!
                    local sort_spec = sort_specs:Specs(n)
                    print(string.format('  Spec=%d ColumnUserID ColumnIndex=%d SortOrder=%d SortDirection=%d',
                        n, sort_spec.ColumnUserID, sort_spec.ColumnIndex, sort_spec.SortOrder, sort_spec.SortDirection))
                end

                if #filteredItems > 1 then
                    current_sort_specs = sort_specs
                    table.sort(filteredItems, CompareWithSortSpecs)
                    current_sort_specs = nil
                end
                sort_specs.SpecsDirty = false
                doSort = false
            end
        end

        local clipper = ImGuiListClipper.new()
        clipper:Begin(#filteredItems)
        while clipper:Step() do
            for row = clipper.DisplayStart+1, clipper.DisplayEnd, 1 do
                local item = filteredItems[row]
                if item then
                    ImGui.TableNextRow()
                    ImGui.TableNextColumn()
                    drawItemRow(item)
                end
            end
        end
        ImGui.EndTable()
    end
end

--- ImGui Program Loop
local function FindGUI()
    if openGUI then
        openGUI, shouldDrawGUI = ImGui.Begin(string.format("Find Item Window"), openGUI, ImGuiWindowFlags.NoScrollbar)
        if shouldDrawGUI then
            displayBagUtilities()
            --displayBagOptions()
            displayBagContent()
            displayItemOnCursor()
        end
        ImGui.End()
    else
        return
    end
end

local function applyStyle()
    ImGui.PushStyleColor(ImGuiCol.TitleBg, .62, .53, .79, .40)
    ImGui.PushStyleColor(ImGuiCol.TitleBgActive, .62, .53, .79, .40)
    ImGui.PushStyleColor(ImGuiCol.TitleBgCollapsed, .62, .53, .79, .40)
    ImGui.PushStyleColor(ImGuiCol.Button, .62, .53, .79, .40)
    ImGui.PushStyleColor(ImGuiCol.ButtonHovered, 1, 1, 1, .87)
    ImGui.PushStyleColor(ImGuiCol.ResizeGrip, .62, .53, .79, .40)
    ImGui.PushStyleColor(ImGuiCol.ResizeGripHovered, .62, .53, .79, 1)
    ImGui.PushStyleColor(ImGuiCol.ResizeGripActive, .62, .53, .79, 1)
    FindGUI()
    ImGui.PopStyleColor(8)
end

mq.imgui.init("FindGUI", applyStyle)

mq.bind('/findwindow', function() openGUI = true end)

--- Main Script Loop
while true do
    mq.delay(1000)
end