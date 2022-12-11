-- Based on Colds Big Bag from RedGuides
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
local sort_order = { name = false, stack = false }

-- GUI Activities

local start_time = os.time()
local filter_text = ""
local filter_changed = true
local forceRefresh = false

local usedSlots = 0
local selectedItems = {}

local invslots = {'charm','leftear','head','face','rightear','neck','shoulder','arms','back','leftwrist','rightwrist','ranged','hands','mainhand','offhand','leftfinger','rightfinger','chest','legs','feet','waist','powersource','ammo'}

local function help_marker(desc)
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
local function sort_inventory()
    -- Various Sorting
    if sort_order.name and sort_order.stack then
        table.sort(items, function(a, b) return a.item.Stack() > b.item.Stack() or (a.item.Stack() == b.item.Stack() and a.item.Name() < b.item.Name()) end)
    elseif sort_order.stack then
        table.sort(items, function(a, b) return a.item.Stack() > b.item.Stack() end)
    elseif sort_order.name then
        table.sort(items, function(a, b) return a.item.Name() < b.item.Name() end)
    end
end

-- The beast - this routine is what builds our inventory.
local function create_inventory()
    if (os.difftime(os.time(), start_time)) > INVENTORY_DELAY_SECONDS or #items == 0 or forceRefresh then
        start_time = os.time()
        forceRefresh = false
        filter_changed = true
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
        sort_inventory()
    end
end

-- Converts between ItemSlot and /itemnotify pack or bank numbers
local function to_pack_or_bank(itemSlot, inBank, inSharedBank)
    if inBank then return 'bank'..tostring(itemSlot + 1) end
    if inSharedBank then return 'sharedbank'..tostring(itemSlot + 1) end
    return 'pack'..tostring(itemSlot - 22)
end

-- Converts between ItemSlot2 and /itemnotify numbers
local function to_bag_slot(slot_number)
    return slot_number + 1
end

-- Displays static utilities that always show at the top of the UI
local function display_bag_utilities()
    ImGui.PushItemWidth(200)
    local text, selected = ImGui.InputText("Filter", filter_text)
    ImGui.PopItemWidth()
    if selected and filter_text ~= text then
        filter_text = text
        filter_changed = true
    end
    ImGui.SameLine()
    if ImGui.SmallButton("Clear") then filter_text = "" filter_changed = true end
    ImGui.SameLine()
    if ImGui.SmallButton("AutoInventory") then mq.cmd('/autoinv') end
    --ImGui.SameLine()
    --if ImGui.SmallButton("Testing") then
    --    for label, item in pairs(selectedItems) do
    --        print(("%s: %s"):format(label, item.Name()))
    --    end
    --end
end

-- Display the collapasable menu area above the items
local function display_bag_options()

    if not ImGui.CollapsingHeader("Bag Options") then
        ImGui.NewLine()
        return
    end

    if ImGui.Checkbox("Name", sort_order.name) then
        sort_order.name = true
    else
        sort_order.name = false
    end
    ImGui.SameLine()
    help_marker("Order items from your inventory sorted by the name of the item.")

    if ImGui.Checkbox("Stack", sort_order.stack) then
        sort_order.stack = true
    else
        sort_order.stack = false
    end
    ImGui.SameLine()
    help_marker("Order items with the largest stacks appearing first.")

    ImGui.Separator()
    ImGui.NewLine()
end

-- Helper to create a unique hidden label for each button.  The uniqueness is
-- necessary for drag and drop to work correctly.
local function btn_label(itemSlot, itemSlot2, inBank, inSharedBank, invslot, augslot)
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

local function get_item_location(itemSlot, itemSlot2, inBank, inSharedBank, invslot, augslot)
    if augslot then return invslots[invslot+1] .. ' aug ' .. augslot end
    if invslot then return invslots[invslot+1] end
    if itemSlot2 == -1 then
        local prefix = ''
        if inBank then return string.format('bank %s', itemSlot+1) end
        if inSharedBank then return string.format('sharedbank %s', itemSlot+1) end
        return string.format('pack %s', itemSlot-22)
    else
        return "in "..to_pack_or_bank(itemSlot, inBank, inSharedBank).." "..to_bag_slot(itemSlot2)
    end
end

local function draw_item_row(item)
    local itemName = item.item.Name()
    local itemIcon = item.item.Icon()
    local itemSlot = item.item.ItemSlot()
    local itemSlot2 = item.item.ItemSlot2()
    local stack = item.item.Stack()
    local label = btn_label(itemSlot, itemSlot2, item.bank, item.sharedbank, item.invslot, item.augslot)

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
    local selected = ImGui.Selectable(label, false, ImGuiSelectableFlags.SpanAllColumns)
    ImGui.PopStyleColor(3)

    local itemLocation = get_item_location(itemSlot, itemSlot2, item.bank, item.sharedbank, item.invslot, item.augslot)
    if not item.augslot and (not (item.bank or item.sharedbank) or mq.TLO.Window('BigBankWnd').Open()) then
        if selected then
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
local function display_item_on_cursor()
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

local TABLE_FLAGS = bit32.bor(ImGuiTableFlags.ScrollY,ImGuiTableFlags.RowBg,ImGuiTableFlags.BordersOuter,ImGuiTableFlags.BordersV,ImGuiTableFlags.SizingStretchSame)

---Handles the bag layout of individual items
local function display_bag_content()
    create_inventory()
    ImGui.SetWindowFontScale(1.25)
    ImGui.SetCursorPosY(ImGui.GetCursorPosY() - 20)
    ImGui.TextUnformatted(string.format("Used/Free Slots (%s/%s)", usedSlots, mq.TLO.Me.FreeInventory()))
    ImGui.SetWindowFontScale(1.0)

    if ImGui.BeginTable('bagtable', 5, TABLE_FLAGS) then
        ImGui.TableSetupScrollFreeze(0, 1)
        ImGui.TableSetupColumn('##checkbox', ImGuiTableColumnFlags.None, 1)
        ImGui.TableSetupColumn('##icon', ImGuiTableColumnFlags.None, 1)
        ImGui.TableSetupColumn('Name', ImGuiTableColumnFlags.None, 6)
        ImGui.TableSetupColumn('Quantity', ImGuiTableColumnFlags.None, 2)
        ImGui.TableSetupColumn('Slot', ImGuiTableColumnFlags.None, 2)
        ImGui.TableHeadersRow()

        if filter_changed then
            filteredItems = {}
            if filter_text ~= '' then
                for i,item in ipairs(items) do
                    if string.match(string.lower(item.item.Name()), string.lower(filter_text)) then
                        table.insert(filteredItems, item)
                    end
                end
            else
                filteredItems = items
            end
            filter_changed = false
        end
        local clipper = ImGuiListClipper.new()
        clipper:Begin(#filteredItems)
        while clipper:Step() do
            for row = clipper.DisplayStart+1, clipper.DisplayEnd, 1 do
                local item = filteredItems[row]
                if item then
                    ImGui.TableNextRow()
                    ImGui.TableNextColumn()
                    draw_item_row(item)
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
            display_bag_utilities()
            display_bag_options()
            display_bag_content()
            display_item_on_cursor()
        end
        ImGui.End()
    else
        return
    end
end

local function apply_style()
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

mq.imgui.init("FindGUI", apply_style)

mq.bind('/findwindow', function() openGUI = true end)

--- Main Script Loop
while true do
    mq.delay("1s")
end
