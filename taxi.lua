local mq = require 'mq'
require 'ImGui'

local open, show = false, false
local shownInZone = false
local currentZone = mq.TLO.Zone.ShortName()
local broadcast = '/e3bcga'
if not mq.TLO.Plugin('mq2mono')() then broadcast = '/dgg' end

local validZones = {
    freeporttemple = {
        {Name='Klon',Command='/multiline ; /nav spawn klonopin; /mqt klonopin'},
        {Name='Bank',Command='/nav spawn Donlo'},
        {Name='Shady',Command='/nav spawn Shady'},
    },
    poknowledge = {
        {Name='Valium',Command='/multiline ; /nav spawn valium; /mqt valium'},
        {Name='Bank',Command='/nav spawn Dogle'},
        {Name='Shady',Command='/nav spawn Shady'},
    },
    overthere = {
        {Name='Elias',Command='/multiline ; /nav spawn elias; /mqt elias'}
    },
    kithicor = {
        {Name='Elias',Command='/multiline ; /nav spawn elias; /mqt elias'}
    },
    qrg = {
        {Name='Elias',Command='/multiline ; /nav spawn elias; /mqt elias'}
    },
    qeytoqrg = {
        {Name='HC',Command='/nav spawn laz'}
    },
    oot = {
        {Name='HC',Command='/nav spawn laz'}
    },
    soldungb = {
        {Name='HC',Command='/nav spawn laz'}
    },
    permafrost = {
        {Name='HC',Command='/nav spawn laz'}
    },
    blackburrow = {
        {Name='HC',Command='/nav spawn laz'}
    },
    najena = {
        {Name='HC',Command='/nav spawn laz'}
    },
    runnyeye = {
        {Name='HC',Command='/nav spawn laz'}
    },
    southkarana = {
        {Name='HC',Command='/nav spawn laz'}
    },
    soldunga = {
        {Name='HC',Command='/nav spawn laz'}
    },
    oasis = {
        {Name='HC',Command='/nav spawn laz'}
    },
    befallen = {
        {Name='HC',Command='/nav spawn laz'}
    },
    crushbone = {
        {Name='HC',Command='/nav spawn laz'}
    },
    cazicthule = {
        {Name='HC',Command='/nav spawn laz'}
    },
    unrest = {
        {Name='HC',Command='/nav spawn laz'}
    },
    guktop = {
        {Name='HC',Command='/nav spawn laz'}
    },
    gukbottom = {
        {Name='HC',Command='/nav spawn laz'}
    },
    mistmoore = {
        {Name='HC',Command='/nav spawn laz'}
    },
    hole = {
        {Name='HC',Command='/nav spawn laz'}
    },
    sebilis = {
        {Name='HC',Command='/nav spawn laz'}
    },
    discordtower = {
        {Name='Mission NPCs',Command="/nav spawn Veylara"},
        {Name='Wimbie',Command="/nav spawn wimbie litto"},
        {Name='Lucian',Command="/nav spawn lucian"},
    },
    -- qey2hh1 Elias Blackthorn selana, fenrir
    -- qrg Elias Blackthorn investigate, Tranquility send you
    -- karnor Elias Blackthorn challenge
}

local portNPCs = {
    poknowledge = 'Valium',
    freeporttemple = 'Klonopin',
    nexus = 'Valium',
}
local ports = {
    'T1',
    'T2',
    'T3',
    'T4',
    'T5',
    'Other',
    ['Other'] = {
        'return',
        'poknowledge',
        'sebilis',
        'karnor',
    },
    ['T1'] = {
        'qrg',
        'oot',
        'soldungb',
        'permafrost',
    },
    ['T2'] = {
        'blackburrow',
        'najena',
        'runnyeye',
    },
    ['T3'] = {
        'paw',
        'soldunga',
        'befallen',
        'sro',    
    },
    ['T4'] = {
        'cazicthule',
        'crushbone',
        'guktop',
        'unrest',
    },
    ['T5'] = {
        'hole',
        'mistmoore',
        'gukbottom',
    },
}
local nvs = {
    ['Veylara Duskweave'] = {'first dream', 'second dream'},
    ['Kaedric Morryn'] = {'first spiral', 'second spiral', 'third spiral'},
    ['Selthira'] = {'confirm physician', 'confirm occultist', 'confirm warden', 'confirm brawler'},
}

local function npcIsNear(name)
    return (mq.TLO.Spawn(name).Distance3D() or 100) < 20
end

local function taxiUI()
    local zoneSN = mq.TLO.Zone.ShortName()
    if zoneSN ~= currentZone then
        shownInZone = false
        currentZone = zoneSN
    end
    if not shownInZone and validZones[zoneSN] then
        open, show = true, true
    end
    local zoneCommands = validZones[zoneSN]
    if not zoneCommands then open, show = false, false return end
    if zoneCommands[1].Name == 'HC' and not mq.TLO.Spawn('lazarus untargetable')() then open, show = false, false return end
    if not open then show = false return end
    open, show = ImGui.Begin('Taxi', open, bit32.bor(ImGuiWindowFlags.AlwaysAutoResize, ImGuiWindowFlags.NoTitleBar))
    if show then
        if zoneCommands then
            for _,command in ipairs(zoneCommands) do
                -- if ImGui.Button(string.format('%s', command.Name)) then
                --     mq.cmdf('%s', command.Command)
                -- end
                -- ImGui.SameLine()
                if ImGui.Button(string.format('%s', command.Name)) then
                    if ImGui.IsKeyDown(ImGuiKey.LeftShift) or ImGui.IsKeyDown(ImGuiKey.RightShift) then
                        mq.cmdf('%s', command.Command)
                    else
                        mq.cmdf('%s %s', broadcast, command.Command)
                    end
                end
                ImGui.SameLine()
            end
            if ImGui.Button('Close') then
                shownInZone = true
                open = false
            end
        end
        if portNPCs[zoneSN] then
            if npcIsNear(portNPCs[zoneSN]) then
                for _,tier in ipairs(ports) do
                    ImGui.Separator()
                    ImGui.TextColored(1, 1, 0, 1, '%s: ', tier)
                    ImGui.SameLine()
                    for _,port in ipairs(ports[tier]) do
                        if port ~= 'poknowledge' or zoneSN ~= 'poknowledge' then
                            if ImGui.Button(string.format('%s', port)) then
                                if ImGui.IsKeyDown(ImGuiKey.LeftShift) or ImGui.IsKeyDown(ImGuiKey.RightShift) then
                                    mq.cmdf('/multiline ; /tar %s ; /timed 2 /say %s', portNPCs[zoneSN], port)
                                else
                                    mq.cmdf('%s /multiline ; /tar %s ; /timed 2 /say %s', broadcast, portNPCs[zoneSN], port)
                                end
                            end
                        end
                        ImGui.SameLine()
                    end
                    ImGui.NewLine()
                end
            end
        end
        local myTarget = mq.TLO.Target.CleanName()
        if zoneSN == 'discordtower' and nvs[myTarget] then
            for _,command in ipairs(nvs[myTarget]) do
                if ImGui.Button(string.format('%s', command)) then
                    mq.cmdf('/say %s', command)
                end
                ImGui.SameLine()
            end
        end
        if npcIsNear('lazarus untargetable') then
            if ImGui.Button('Enter 1') then
                if ImGui.IsKeyDown(ImGuiKey.LeftShift) or ImGui.IsKeyDown(ImGuiKey.RightShift) then
                    mq.cmd('/say enter 1')
                else
                    mq.cmdf('%s /say enter 1', broadcast)
                end
            end
        end
    end
    ImGui.End()
    if not open then
        shownInZone = true
    end
end

mq.imgui.init('taxi', taxiUI)

while true do
    mq.delay(1000)
end