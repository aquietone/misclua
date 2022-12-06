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

-- Bag Options
local sort_order = { name = false, stack = false }

-- GUI Activities

local start_time = os.time()
local search_text = ""
local search_changed = true
local shouldSearchBank = false
local forceRefresh = false

local searchResults = {}
local resultItems = {}

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

-- Displays static utilities that always show at the top of the UI
local function display_bag_utilities()
    ImGui.PushItemWidth(200)
    local text, selected = ImGui.InputText("Search", search_text)
    ImGui.PopItemWidth()
    if selected and search_text ~= text then
        search_text = text
        search_changed = true
    end
    ImGui.SameLine()
    if ImGui.SmallButton("Clear") then search_text = "" search_changed = true end
    ImGui.SameLine()
    shouldSearchBank = ImGui.Checkbox('Search Bank', shouldSearchBank)
end

-- Helper to create a unique hidden label for each button.  The uniqueness is
-- necessary for drag and drop to work correctly.
local function btn_label(itemSlot, itemSlot2, inBank, inSharedBank, invslot)
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

local itemRequest = nil
-- {toon=toon, item=result, count=count}
local function draw_item_row(item)
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

local TABLE_FLAGS = bit32.bor(ImGuiTableFlags.ScrollY,ImGuiTableFlags.RowBg,ImGuiTableFlags.BordersOuter,ImGuiTableFlags.BordersV,ImGuiTableFlags.SizingStretchSame)

local update_results = true
---Handles the bag layout of individual items
local function display_bag_content()
    ImGui.SetWindowFontScale(1.25)
    ImGui.SetWindowFontScale(1.0)

    if ImGui.BeginTable('itemtable', 5, TABLE_FLAGS) then
        ImGui.TableSetupScrollFreeze(0, 1)
        ImGui.TableSetupColumn('##request', ImGuiTableColumnFlags.None, 2)
        ImGui.TableSetupColumn('Name', ImGuiTableColumnFlags.None, 6)
        ImGui.TableSetupColumn('Toon', ImGuiTableColumnFlags.None, 3)
        ImGui.TableSetupColumn('Quantity', ImGuiTableColumnFlags.None, 2)
        ImGui.TableSetupColumn('In Bags', ImGuiTableColumnFlags.None, 2)
        ImGui.TableHeadersRow()

        if update_results then
            resultItems = searchResults
            update_results = false
        end
        local clipper = ImGuiListClipper.new()
        clipper:Begin(#resultItems)
        while clipper:Step() do
            for row = clipper.DisplayStart+1, clipper.DisplayEnd, 1 do
                local item = resultItems[row]
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
        openGUI, shouldDrawGUI = ImGui.Begin(string.format("Search Window"), openGUI, ImGuiWindowFlags.NoScrollbar)
        if shouldDrawGUI then
            display_bag_utilities()
            display_bag_content()
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

mq.imgui.init("SearchGUI", apply_style)

mq.bind('/search', function() openGUI = true end)

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

local searchBags = 'FindItem[%s]'
local searchBank = 'FindItemBank[%s]'
local countBags = 'FindItemCount[%s]'
local countBank = 'FindItemBankCount[%s]'

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

--- Main Script Loop
while true do
    mq.delay(250)
    if search_changed and search_text ~= '' then
        searchResults = {}
        local toons = split(mq.TLO.DanNet.Peers())
        for _,toon in ipairs(toons) do
            local searchedBank = false
            local result = query(toon, searchBags:format(search_text), 500)
            if result == 'NULL' and shouldSearchBank then
                result = query(toon, searchBank:format(search_text), 500)
                searchedBank = true
            end
            if result ~= 'NULL' then
                local search = countBags
                if searchedBank then
                    search = countBank
                end
                local count = query(toon, search:format(search_text), 500)
                table.insert(searchResults, {toon=toon, item=result, count=count, inbags=(searchedBank==false)})
            end
        end
        search_changed = false
        update_results = true
    end
    if itemRequest then
        sendRequest()
    end
end