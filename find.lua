--- @type Mq
local mq = require("mq")

--- @type ImGui
require("ImGui")

local openGUI = true
local shouldDrawGUI = true

local openSearchGUI = false
local shouldDrawSearchGUI = false

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

-- Filter options

local startTime = os.time()
local forceRefresh = false

local filterChanged = true
local filterText = ""
local slotFilter = 'none'
local typeFilter = 'none'
local locationFilter = 'all'

local doSort = true

local invslots = {'charm','leftear','head','face','rightear','neck','shoulder','arms','back','leftwrist','rightwrist','ranged','hands','mainhand','offhand','leftfinger','rightfinger','chest','legs','feet','waist','powersource','ammo'}
local invslotfilters = {'none','charm','ears','head','face','neck','shoulder','arms','back','wrists','ranged','hands','mainhand','offhand','fingers','chest','legs','feet','waist','powersource','ammo'}
local itemtypefilters = {'none','Armor','weapon','Augmentation','container','Food','Drink','Combinable'}
local locationfilters = {'all','on person','bank'}

local searchText = ''
local searchResults = {}
local resultItems = {}
local searchChanged = true
local shouldSearchBank = true
local searchUpdateResults = true

local usingDanNet = true

-- The beast - this routine is what builds our inventory.
local function createInventory()
    if (os.difftime(os.time(), startTime)) > INVENTORY_DELAY_SECONDS or #items == 0 or forceRefresh then
        startTime = os.time()
        forceRefresh = false
        filterChanged = true
        searchChanged = true
        items = {}
        for i = 23, 34, 1 do
            local slot = mq.TLO.Me.Inventory(i)
            if slot.Container() and slot.Container() > 0 then
                for j = 1, (slot.Container()), 1 do
                    local bagSlot = slot.Item(j)
                    if bagSlot() then
                        table.insert(items, {item=bagSlot, itemslot=bagSlot.ItemSlot(), itemslot2=bagSlot.ItemSlot2()})
                    end
                end
                table.insert(items, {item=slot, itemslot=slot.ItemSlot(), itemslot2=slot.ItemSlot2()})
            elseif slot.ID() ~= nil then
                table.insert(items, {item=slot, itemslot=slot.ItemSlot(), itemslot2=slot.ItemSlot2()}) -- We have an item in a bag slot
            end
        end
        for i = 1, 24, 1 do
            local slot = mq.TLO.Me.Bank(i)
            if slot.Container() and slot.Container() > 0 then
                for j = 1, (slot.Container()), 1 do
                    local bagSlot = slot.Item(j)
                    if bagSlot() then
                        table.insert(items, {item=bagSlot, bank=true, itemslot=bagSlot.ItemSlot(), itemslot2=bagSlot.ItemSlot2()})
                    end
                end
                table.insert(items, {item=slot, bank=true, itemslot=slot.ItemSlot(), itemslot2=slot.ItemSlot2()})
            elseif slot.ID() ~= nil then
                table.insert(items, {item=slot, bank=true, itemslot=slot.ItemSlot(), itemslot2=slot.ItemSlot2()}) -- We have an item in a bank slot
            end
        end
        for i = 1, 2, 1 do
            local slot = mq.TLO.Me.SharedBank(i)
            if slot.Container() and slot.Container() > 0 then
                for j = 1, (slot.Container()), 1 do
                    local bagSlot = slot.Item(j)
                    if bagSlot() then
                        table.insert(items, {item=bagSlot, sharedbank=true, itemslot=bagSlot.ItemSlot(), itemslot2=bagSlot.ItemSlot2()})
                    end
                end
                table.insert(items, {item=slot, sharedbank=true, itemslot=slot.ItemSlot(), itemslot2=slot.ItemSlot2()})
            elseif slot.ID() ~= nil then
                table.insert(items, {item=slot, sharedbank=true, itemslot=slot.ItemSlot(), itemslot2=slot.ItemSlot2()}) -- We have an item in a bank slot
            end
        end
        for i = 0, 22, 1 do
            local slot = mq.TLO.InvSlot(i).Item
            if slot.ID() ~= nil then
                table.insert(items, {item=slot, invslot=i, itemslot=slot.ItemSlot(), itemslot2=slot.ItemSlot2()})
                for j=1,8 do
                    local augSlot = slot.AugSlot(j).Item
                    if augSlot() then
                        table.insert(items, {item=augSlot, invslot=i, augslot=j, itemslot=augSlot.ItemSlot(), itemslot2=augSlot.ItemSlot2()})
                    end
                end
            end
        end
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
        slotFilter = 'none'
        typeFilter = 'none'
        locationFilter = 'all'
        filterChanged = true
    end
    ImGui.SameLine()
    if ImGui.SmallButton("Clear") then filterText = "" filterChanged = true end
    ImGui.SameLine()
    if ImGui.SmallButton("AutoInventory") then mq.cmd('/autoinv') end
    if usingDanNet then
        ImGui.SameLine()
        if ImGui.SmallButton("Search Toons") then openSearchGUI = true end
    end
end

local function drawFilterMenu(label, filter, filterOptions)
    if ImGui.BeginCombo(label, filter) then
        for _,option in ipairs(filterOptions) do
            if ImGui.Selectable(option, option == filter) then
                if filter ~= option then
                    ImGui.EndCombo()
                    return option, true
                end
            end
        end
        ImGui.EndCombo()
    end
    return filter, false
end

local function displayMenus()
    ImGui.PushItemWidth(100)
    local tempFilterChanged = false
    slotFilter, tempFilterChanged = drawFilterMenu('Slot Type', slotFilter, invslotfilters)
    filterChanged = filterChanged or tempFilterChanged
    ImGui.SameLine()
    typeFilter, tempFilterChanged = drawFilterMenu('Item Type', typeFilter, itemtypefilters)
    filterChanged = filterChanged or tempFilterChanged
    ImGui.SameLine()
    locationFilter, tempFilterChanged = drawFilterMenu('Location', locationFilter, locationfilters)
    filterChanged = filterChanged or tempFilterChanged
    ImGui.PopItemWidth()
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

local function onLeftClick(item, itemLocation)
    if not item.augslot and (not (item.bank or item.sharedbank) or mq.TLO.Window('BigBankWnd').Open()) then
        if not mq.TLO.Cursor() and not mq.TLO.Me.Casting() then
            mq.cmdf("/nomodkey /shiftkey /itemnotify %s leftmouseup", itemLocation)
            forceRefresh = true
        end
    end
end

local function onRightClick(item, itemName)
    if not item.augslot and (not (item.bank or item.sharedbank) or mq.TLO.Window('BigBankWnd').Open()) then
        mq.cmdf('/squelch /nomodkey /altkey /itemnotify "%s" leftmouseup', itemName)
    end
end

local function handleClicks(item, itemLocation, itemName)
    if ImGui.IsItemHovered() and ImGui.IsMouseReleased(ImGuiMouseButton.Left) then
        onLeftClick(item, itemLocation)
    end
    if ImGui.IsItemHovered() and ImGui.IsMouseReleased(ImGuiMouseButton.Right) then
        onRightClick(item, itemName)
    end
end

local function drawItemRow(item)
    local itemName = item.item.Name()
    local itemIcon = item.item.Icon()
    local itemSlot = item.itemslot--.ItemSlot()
    local itemSlot2 = item.itemslot2--.ItemSlot2()
    local stack = item.item.Stack()
    if not (itemName and itemIcon and itemSlot and itemSlot2 and stack) then return end
    local label = buttonLabel(itemSlot, itemSlot2, item.bank, item.sharedbank, item.invslot, item.augslot)
    local itemLocation = getItemLocation(itemSlot, itemSlot2, item.bank, item.sharedbank, item.invslot, item.augslot)

    -- Reset the cursor to start position, then fetch and draw the item icon
    local cursor_x, cursor_y = ImGui.GetCursorPos()
    animItems:SetTextureCell(itemIcon - EQ_ICON_OFFSET)
    ImGui.DrawTextureAnimation(animItems, ICON_WIDTH, ICON_HEIGHT)

    -- Reset the cursor to start position, then draw a transparent button (for drag & drop)
    ImGui.SetCursorPos(cursor_x, cursor_y)
    ImGui.PushStyleColor(ImGuiCol.Button, 0, 0, 0, 0)
    ImGui.PushStyleColor(ImGuiCol.ButtonHovered, 0, 0.3, 0, 0.2)
    ImGui.PushStyleColor(ImGuiCol.ButtonActive, 0, 0.3, 0, 0.3)
    ImGui.Selectable(label, false, bit32.bor(ImGuiSelectableFlags.SpanAllColumns, ImGuiSelectableFlags.AllowItemOverlap))
    ImGui.PopStyleColor(3)
    handleClicks(item, itemLocation, itemName)

    ImGui.TableNextColumn()

    ImGui.Text(itemName)
    --handleClicks(item, itemLocation, itemName)

    ImGui.TableNextColumn()

    -- Overlay the stack size text in the lower right corner
    if stack > 1 then
        ImGui.Text(tostring(stack))
    else
        ImGui.Text('1')
    end
    --handleClicks(item, itemLocation, itemName)

    ImGui.TableNextColumn()

    ImGui.Text(itemLocation)
    --handleClicks(item, itemLocation, itemName)

    if usingDanNet then
        ImGui.TableNextColumn()

        if ImGui.Button('Search##'..label) then
            searchText = itemName
            searchChanged = true
            openSearchGUI = true
        end
    end
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

local ColumnID_Icon = 1
local ColumnID_Name = 2
local ColumnID_Quantity = 3
local ColumnID_Slot = 4
local ColumnID_Search = 5

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
        elseif sort_spec.ColumnUserID == ColumnID_Slot then
            local aSlotNum = tonumber(a.itemslot) or 0
            local aSlot2Num = tonumber(a.itemslot2) or 0
            local bSlotNum = tonumber(b.itemslot) or 0
            local bSlot2Num = tonumber(b.itemslot2) or 0
            if aSlotNum < bSlotNum then
                delta = -1
            elseif bSlotNum < aSlotNum then
                delta = 1
            else
                if aSlot2Num < bSlot2Num then
                    delta = -1
                elseif bSlot2Num < aSlot2Num then
                    delta = 1
                else
                    delta = 0
                end
            end
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

local function applyTextFilter(item)
    return string.match(string.lower(item.item.Name()), string.lower(filterText))
end

local leftrightslots = {ears='leftear',wrists='leftwrist',fingers='leftfinger'}
local function applySlotFilter(item)
    local tempSlotFilter = leftrightslots[slotFilter] or slotFilter
    return item.item.WornSlot(tempSlotFilter)()
end

local function applyTypeFilter(item)
    return (typeFilter == 'weapon' and (item.item.Damage() > 0 or item.item.Type() == 'Shield')) or
            (typeFilter == 'container' and item.item.Container() > 0) or
            item.item.Type() == typeFilter
end

local function applyLocationFilter(item)
    return (locationFilter == 'on person' and not (item.bank or item.sharedbank)) or
            (locationFilter == 'bank' and (item.bank or item.sharedbank))
end

local function filterItems()
    if filterChanged then
        filteredItems = {}

        local filterFunction = nil
        local filterFuncs = {}
        if filterText ~= '' then table.insert(filterFuncs, applyTextFilter) end
        if slotFilter ~= 'none' then table.insert(filterFuncs, applySlotFilter) end
        if typeFilter ~= 'none' then table.insert(filterFuncs, applyTypeFilter) end
        if locationFilter ~= 'all' then table.insert(filterFuncs, applyLocationFilter) end

        if #filterFuncs > 0 then
            filterFunction = function(item)
                for _,func in ipairs(filterFuncs) do
                    if not func(item) then return false end
                end
                return true
            end
            for i,item in ipairs(items) do
                if filterFunction(item) then
                    table.insert(filteredItems, item)
                end
            end
        else
            filteredItems = items
        end

        filterChanged = false
        doSort = true
    end
end

local TABLE_FLAGS = bit32.bor(ImGuiTableFlags.ScrollY,ImGuiTableFlags.RowBg,ImGuiTableFlags.BordersOuter,ImGuiTableFlags.BordersV,ImGuiTableFlags.SizingStretchSame,ImGuiTableFlags.Sortable)
---Handles the bag layout of individual items
local function displayBagContent()
    createInventory()
    local numColumns = usingDanNet and 5 or 4
    if ImGui.BeginTable('bagtable', numColumns, TABLE_FLAGS) then
        ImGui.TableSetupScrollFreeze(0, 1)
        ImGui.TableSetupColumn('##icon', ImGuiTableColumnFlags.NoSort, 1, ColumnID_Icon)
        ImGui.TableSetupColumn('Name', ImGuiTableColumnFlags.DefaultSort, 5, ColumnID_Name)
        ImGui.TableSetupColumn('Quantity', ImGuiTableColumnFlags.DefaultSort, 2, ColumnID_Quantity)
        ImGui.TableSetupColumn('Slot', ImGuiTableColumnFlags.DefaultSort, 2, ColumnID_Slot)
        if usingDanNet then
            ImGui.TableSetupColumn('Search', ImGuiTableColumnFlags.NoSort, 2, ColumnID_Search)
        end
        ImGui.TableHeadersRow()

        filterItems()
        local sort_specs = ImGui.TableGetSortSpecs()
        if sort_specs then
            if sort_specs.SpecsDirty or doSort then
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

local itemRequest = nil
-- {toon=toon, item=result, count=count}
local function drawSearchItemRow(item)
    local itemName = item.item
    local itemToon = item.toon
    local itemCount = item.count
    local itemInBags = item.inbags
    --local label = btn_label(itemSlot, itemSlot2, item.bank, item.sharedbank, item.invslot)

    if itemInBags and ImGui.Button('Request##'..itemName..itemToon) then
        itemRequest = {toon=itemToon, name=itemName}
    end
    ImGui.TableNextColumn()

    ImGui.Text(itemName)

    ImGui.TableNextColumn()

    ImGui.Text(itemToon)

    ImGui.TableNextColumn()

    ImGui.Text(tostring(itemCount))

    ImGui.TableNextColumn()

    ImGui.Text(tostring(itemInBags))

    ImGui.TableNextColumn()
end

-- Displays static utilities that always show at the top of the UI
local function displaySearchOptions()
    ImGui.PushItemWidth(200)
    local text, selected = ImGui.InputText("Search", searchText)
    ImGui.PopItemWidth()
    if selected and searchText ~= text then
        searchText = text
        searchChanged = true
    end
    ImGui.SameLine()
    if ImGui.SmallButton("Clear") then 
        searchText = ""
        searchChanged = true
        searchResults = {}
        searchUpdateResults = true    
    end
    ImGui.SameLine()
    local newShouldSearchBank = ImGui.Checkbox('Search Bank', shouldSearchBank)
    if newShouldSearchBank ~= shouldSearchBank then
        searchChanged = true
        shouldSearchBank = newShouldSearchBank
    end
end

---Handles the bag layout of individual items
local function displaySearchContent()
    if ImGui.BeginTable('searchitemtable', 5, TABLE_FLAGS) then
        ImGui.TableSetupScrollFreeze(0, 1)
        ImGui.TableSetupColumn('Gimme##request', ImGuiTableColumnFlags.None, 2)
        ImGui.TableSetupColumn('Name', ImGuiTableColumnFlags.None, 6)
        ImGui.TableSetupColumn('Toon', ImGuiTableColumnFlags.None, 3)
        ImGui.TableSetupColumn('Quantity', ImGuiTableColumnFlags.None, 2)
        ImGui.TableSetupColumn('In Bags', ImGuiTableColumnFlags.None, 2)
        ImGui.TableHeadersRow()

        if searchUpdateResults then
            resultItems = searchResults
            searchUpdateResults = false
        end
        local clipper = ImGuiListClipper.new()
        clipper:Begin(#resultItems)
        while clipper:Step() do
            for row = clipper.DisplayStart+1, clipper.DisplayEnd, 1 do
                local item = resultItems[row]
                if item then
                    ImGui.TableNextRow()
                    ImGui.TableNextColumn()
                    drawSearchItemRow(item)
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
            displayMenus()
            displayBagContent()
            displayItemOnCursor()
        end
        ImGui.End()
        if not openSearchGUI then return end
        openSearchGUI, shouldDrawSearchGUI = ImGui.Begin(string.format("Search Window"), openGUI, ImGuiWindowFlags.NoScrollbar)
        if shouldDrawSearchGUI then
            displaySearchOptions()
            displaySearchContent()
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

local function split(input, sep)
    if sep == nil then
        sep = "|"
    end
    local t={}
    for str in string.gmatch(input, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

local function query(peer, query, timeout)
    mq.cmdf('/dquery %s -q "%s"', peer, query)
    mq.delay(timeout, function() return mq.TLO.DanNet(peer).QReceived(query)() > 0 end)
    local value = mq.TLO.DanNet(peer).Q(query)()
    return value
end

local searchBags = 'FindItem[=%s]'
local searchBank = 'FindItemBank[=%s]'
local countBags = 'FindItemCount[=%s]'
local countBank = 'FindItemBankCount[=%s]'

local function sendRequest()
    local spawn = mq.TLO.Spawn('pc ='..itemRequest.toon)
    if spawn() and spawn.Distance3D() < 15 then
        mq.cmdf('/dex %s /nomodkey /shiftkey /itemnotify "$\\{FindItem[%s]}" leftmouseup', itemRequest.toon, itemRequest.name)
        mq.delay(100)
        mq.cmdf('/dex %s /mqtar %s', itemRequest.toon, mq.TLO.Me.CleanName())
        mq.delay(100)
        mq.cmdf('/dex %s /click left target', itemRequest.toon)
        mq.delay(2000, function() return mq.TLO.Window('TradeWnd').Open() end)
        mq.delay(200)
        mq.cmdf('/dex %s /timed 5 /yes', itemRequest.toon)
        mq.delay(500)
        mq.cmdf('/yes')
    else
        mq.cmdf('/popcustom 5 %s is not in range to request %s', itemRequest.toon, itemRequest.name)
    end
    itemRequest = nil
end

if mq.TLO.DanNet then
    usingDanNet = true
else
    usingDanNet = false
end

mq.imgui.init("FindGUI", applyStyle)

mq.bind('/findwindow', function() openGUI = true end)

--- Main Script Loop
while true do
    mq.delay(250)
    if usingDanNet and searchChanged and searchText ~= '' then
        searchResults = {}
        local toons = split(mq.TLO.DanNet.Peers())
        for _,toon in ipairs(toons) do
            if toon ~= mq.TLO.Me.CleanName():lower() then
                local searchedBank = false
                local result = query(toon, searchBags:format(searchText), 500)
                if result == 'NULL' and shouldSearchBank then
                    result = query(toon, searchBank:format(searchText), 500)
                    searchedBank = true
                end
                if result ~= 'NULL' then
                    local search = countBags
                    if searchedBank then
                        search = countBank
                    end
                    local count = query(toon, search:format(searchText), 500)
                    table.insert(searchResults, {toon=toon, item=result, count=count, inbags=(searchedBank==false)})
                end
            end
        end
        searchChanged = false
        searchUpdateResults = true
    end
    if itemRequest then
        sendRequest()
    end
end