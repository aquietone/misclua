local mq = require('mq')
require('ImGui')
local PackageMan = require('mq.PackageMan')

local ok, _ = pcall(require, 'ssl')
if not ok then
    PackageMan.Install('luasec')
end
local http = PackageMan.Require('luasocket', 'socket.http')

local isOpen, shouldDraw = true, true
local terminate = false

local noMatches = 'No items matched your search'

local mruggesURL = 'https://lookerstudio.google.com/u/0/reporting/52461d5f-db88-4410-bd83-f4ed7ad83ca7/page/26OZC'
local bazaarURL = 'https://lazaruseq.com/Magelo/index.php?page=bazaar'
local queryFormat = bazaarURL .. '&trader=&class=-1&race=-1&slot=-1&stat=-1&aug_type=2147483647&type=-1&pricemin=&pricemax=&direction=DESC&orderby=tradercost&start=%s&item=%s'
local doQuery = false
local queryString = ''
local queryResult = ''

local chunks = {}

local function drawResultRow(result)
    ImGui.Text(result.item)
    ImGui.TableNextColumn()
    ImGui.Text('%s', result.price)
    ImGui.TableNextColumn()
    ImGui.Text(result.seller)
    ImGui.TableNextColumn()
    if ImGui.Button('Go To') then
        mq.cmdf('/nav spawn pc =%s', result.seller)
    end
    --ImGui.TableNextColumn()
end

local ColumnID_Item = 1
local ColumnID_Price = 2
local ColumnID_Seller = 3
local ColumnID_GoTo = 4
local current_sort_specs = nil
local function CompareWithSortSpecs(a, b)
    for n = 1, current_sort_specs.SpecsCount, 1 do
        -- Here we identify columns using the ColumnUserID value that we ourselves passed to TableSetupColumn()
        -- We could also choose to identify columns based on their index (sort_spec.ColumnIndex), which is simpler!
        local sort_spec = current_sort_specs:Specs(n)
        local delta = 0

        local sortA = a
        local sortB = b
        if sort_spec.ColumnUserID == ColumnID_Item then
            sortA = a.item
            sortB = b.item
        elseif sort_spec.ColumnUserID == ColumnID_Price then
            sortA = a.price
            sortB = b.price
        elseif sort_spec.ColumnUserID == ColumnID_Seller then
            sortA = a.seller
            sortB = b.seller
        end
        if sortA < sortB then
            delta = -1
        elseif sortB < sortA then
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
    -- Your own compare function may want to avoid fallback on implicit sort specs e.g. a Name compare if it wasn't already part of the sort specs.
    return a.seller < b.seller
end

local TABLE_FLAGS = bit32.bor(ImGuiTableFlags.ScrollY,ImGuiTableFlags.RowBg,ImGuiTableFlags.BordersOuter,ImGuiTableFlags.BordersV,ImGuiTableFlags.SizingStretchSame,ImGuiTableFlags.Sortable,
                                ImGuiTableFlags.Hideable, ImGuiTableFlags.Resizable, ImGuiTableFlags.Reorderable)
local function bazaar()
    if not isOpen then return end

    isOpen, shouldDraw = ImGui.Begin('Bazaar', isOpen)
    if shouldDraw then
        local selected = false
        ImGui.SetNextItemWidth(250)
        queryString, selected = ImGui.InputText('##searchtext', queryString, ImGuiInputTextFlags.EnterReturnsTrue)
        if not doQuery and selected and queryString ~= '' then
            doQuery = true
        end
        ImGui.SameLine()
        if ImGui.Button('Search') and not doQuery and queryString ~= '' then
            doQuery = true
        end
        ImGui.SameLine()
        if ImGui.Button('\xee\x89\x90 Mrugge\'s') then
            os.execute('start '..mruggesURL)
        end
        ImGui.SameLine()
        if ImGui.Button('\xee\x89\x90 Bazaar') then
            os.execute('start '..bazaarURL)
        end
        if doQuery then
            ImGui.SameLine()
            ImGui.TextColored(ImVec4(1, 1, 0, 1), 'Searching . . .')
        end
        local _, yAvail = ImGui.GetContentRegionAvail()
        if ImGui.BeginTable('bazaartable', 4, TABLE_FLAGS, -1, yAvail-15) then
            ImGui.TableSetupScrollFreeze(0, 1)
            ImGui.TableSetupColumn('Item', ImGuiTableColumnFlags.DefaultSort, 3, ColumnID_Item)
            ImGui.TableSetupColumn('Price', ImGuiTableColumnFlags.DefaultSort, 1, ColumnID_Price)
            ImGui.TableSetupColumn('Seller', ImGuiTableColumnFlags.DefaultSort, 2, ColumnID_Seller)
            ImGui.TableSetupColumn('Go To', ImGuiTableColumnFlags.None, 1, ColumnID_GoTo)
            ImGui.TableHeadersRow()

            if not doQuery then
                local sort_specs = ImGui.TableGetSortSpecs()
                if sort_specs then
                    if sort_specs.SpecsDirty then
                        current_sort_specs = sort_specs
                        table.sort(chunks, CompareWithSortSpecs)
                        current_sort_specs = nil
                        sort_specs.SpecsDirty = false
                    end
                end

                local clipper = ImGuiListClipper.new()
                clipper:Begin(#chunks)
                while clipper:Step() do
                    for row = clipper.DisplayStart+1, clipper.DisplayEnd, 1 do
                        local item = chunks[row]
                        if item then
                            ImGui.TableNextRow()
                            ImGui.TableNextColumn()
                            drawResultRow(item)
                        end
                    end
                end
            end
            ImGui.EndTable()
        end
    end
    ImGui.End()
end

local function executeQuery(start)
    local query = queryFormat:format(start, queryString:gsub(' ', '+'))
    queryResult = http.request(query)
    if queryResult then
        if queryResult:find(noMatches) then
            queryResult = 'No matches found'
        else
            local tableIndex = queryResult:find('WindowNestedBlue PositionBazaarRight')
            if not tableIndex then return 0 end
            local itemWindowsIndex = queryResult:find('ITEM WINDOWS')
            queryResult = queryResult:sub(tableIndex, itemWindowsIndex)
            local itemsIndex = queryResult:find('#item0')
            if not itemsIndex then return 0 end
            queryResult = queryResult:sub(itemsIndex, -1)
            while true do
                local itemIdx = queryResult:find('href=\'#\'>')
                if not itemIdx then break end
                local remainingIdx = queryResult:find('</a')
                local itemName = queryResult:sub(itemIdx+9, remainingIdx-1)

                queryResult = queryResult:sub(remainingIdx)

                local priceIdx = queryResult:find('<td>')
                remainingIdx = queryResult:find('<img')
                local price = queryResult:sub(priceIdx+4, remainingIdx-1)

                queryResult = queryResult:sub(remainingIdx)

                local sellerIdx = queryResult:find('ASC\'>')
                remainingIdx = queryResult:find('</a')
                local seller = queryResult:sub(sellerIdx+5, remainingIdx-1)

                queryResult = queryResult:sub(remainingIdx+4)

                --printf('%s %s %s', itemName, price, seller)
                table.insert(chunks, {item=itemName, price=price, seller=seller})
            end
        end
    end
    return #chunks
end

mq.imgui.init('bazaar', bazaar)

while not terminate do
    mq.delay(1000)
    if doQuery then
        chunks = {}
        local start = 0
        for i=1,5 do
            start = executeQuery(start)
            if start < 25*i then
                --printf('stopping loop, start=%s', start)
                break
            end
        end
        doQuery = false
    end
end