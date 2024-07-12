local mq = require('mq')

local zones = { 'TIME', 'TACVI' }
local NPCs = { 'Klorg', 'Zenma' }
local turnInItems = {
    ['TIME'] = {
        "Earring of Xaoth Kor", "Ethereal Destroyer", "Faceguard of Frenzy", "Fiery Crystal Guard", "Mask of Strategic Insight", "Pauldrons of Purity", "Timeless Coral Greatsword",
        "Cap of Flowing Time", "Edge of Eternity", "Girdle of Intense Durability", "Gloves of the Unseen", "Ring of Evasion", "Runewarded Belt", "Shroud of Provocation", "Symbol of the Planemasters",
        "Time's Antithesis", "Veil of Lost Hopes",
        "Amulet of Crystal Dreams", "Band of Prismatic Focus", "Bracer of Precision", "Circlet of Flowing Time", "Cloak of the Falling Skies", "Hopebringer", "Mantle of Deadly Precision", "Serpent of Vindication",
        "Tactician's Shield", "Winged Storm Boots",
        "Armguards of the Brute", "Cape of Endless Torment", "Coif of Flowing Time", "Cudgel of Venomous Hatred", "Earring of Corporeal Essence", "Hammer of Hours", "Orb of Clinging Death",
        "Talisman of Tainted Energy", "Vanazir, Dreamer's Despair",
        "Bow of the Tempest", "Cord of Potential", "Earring of Temporal Solstice", "Globe of Mystical Protection", "Hammer of Holy Vengeance", "Helm of Flowing Time", "Shinai of the Ancients", "Shoes of Fleeting Fury",
        "Temporal Chainmail Sleeves", "Wand of Temporal Power",
        "Belt of Temporal Bindings", "Boots of Despair", "Celestial Cloak", "Collar of Catastrophe", "Eye of Dreams", "Greatblade of Chaos", "Leggings of Furious Might", "Pulsing Onyx Ring",
        "Symbol of Ancient Summoning", "Timespinner, Blade of the Hunter", "Veil of the Inferno",
        "Belt of Tidal Energy", "Cloak of Retribution", "Earring of Unseen Horrors", "Greaves of Furious Might", "Mask of Simplicity", "Padded Tigerskin Gloves", "Staff of Transcendence", "Timestone Adorned Ring",
        "Wand of Impenetrable Force", "Wristband of Echoed Thoughts", "Zealot's Spiked Bracer",
        "Barrier of Freezing Winds", "Bracer of Timeless Rage", "Earring of Celestial Energy", "Girdle of Stability", "Gloves of Airy Mists", "Jagged Timeforged Blade", "Mantle of Pure Spirit", "Necklace of Eternal Visions",
        "Serrated Dart of Energy", "Shroud of Survival", "Songblade of the Eternal",
        "Band of Primordial Energy", "Darkblade of the Warlord", "Greatstaff of Power", "Pants of Furious Might", "Pauldrons of Devastation", "Platinum Cloak of War", "Ring of Thunderous Forces", "Sandals of Empowerment",
        "Shield of Strife", "Ton Po's Mystical Pouch", "Visor of the Berserker",
        "Bracer of the Inferno", "Cord of Temporal Weavings", "Earring of Influxed Gravity", "Earthen Bracer of Fortitude", "Ethereal Silk Leggings", "Hammer of the Timeweaver", "Prismatic Ring of Resistance", "Shawl of Eternal Forces",
        "Shroud of Eternity", "Silver Hoop of Speed", "Spool of Woven Time", "Stone of Flowing Time", "Talisman of the Elements", "Whorl of Unnatural Forces", "Wristband of Icy Vengeance", 
        "Timeless Breastplate Mold", "Timeless Chain Tunic Pattern", "Timeless Leather Tunic Pattern", "Timeless Silk Robe Pattern"
    },
    ['TACVI'] = {
        'Bracer of Grievous Harm', 'Glinting Onyx of Might', 'Glyphed Sandstone of Idealism', 'Ragestone of Hateful Thoughts', 'Shimmering Granite', 'Wristguard of Chaotic Essence', 'Xxeric\'s Battleworn Bracer', 'Xxeric\'s Warbraid',
        'Bulwark of Lost Souls', 'Death\'s Head Mace', 'Vambraces of Eternal Twilight', 'Sleeves of Malefic Rapture', 'Ring of Organic Darkness', 'Golden Idol of Destruction', 'Earring of Pain Deliverance',
        'Aegis of Midnight', 'Armband of Writhing Shadow', 'Tome of Discordant Magic', 'Ruby of Determined Assault', 'Ring of the Serpent', 'Mask of the Void', 'Armguards of Insidious Corruption',
        'Weighted Hammer of Conviction', 'Scepter of Incantations', 'Pauldron of Dark Auspices', 'Luxurious Satin Slippers', 'Girdle of the Zun\'Muram', 'Gauntlets of Malicious Intent', 'Brutish Blade of Balance', 'Bloodstone Blade of the Zun\'Muram',
        'Zun\'Muram\'s Spear of Doom', 'Shroud of the Legion', 'Runed Gauntlets of the Void', 'Nightmarish Boots of Conflict', 'Jagged Axe of Uncontrolled Rage', 'Dagger of Evil Summons', 'Cloak of Nightmarish Visions', 'Blade of Natural Turmoil',
        'Zun\'Muram\'s Scepter of Chaos', 'Supple Slippers of the Stargazer', 'Mindreaper Club', 'Mantle of Corruption', 'Loop of Entropic Hues', 'Kelp-Covered Hammer', 'Hammer of Delusions', 'Gloves of Wicked Ambition',
        'Xxeric\'s Matted-Fur Mask', 'Rapier of Somber Notes', 'Pendant of Discord', 'Gloves of Coalesced Flame', 'Discordant Dagger of Night', 'Deathblade of the Zun\'Muram', 'Dagger of Death', 'Boots of Captive Screams',
        'Worked Granite of Sundering', 'Tunat\'Muram\'s Chestplate of Agony', 'Tunat\'Muram\'s Chainmail of Pain', 'Tunat\'Muram\'s Bloodied Greaves', 'Solid Stone of the Iron Fist', 'Merciless Enslaver\'s Britches', 'Lightning Prism of Swordplay',
        'Jagged Glowing Prism', 'Greaves of the Tunat\'Muram', 'Greaves of the Dark Ritualist', 'Drape of the Merciless Slaver', 'Dark Tunic of the Enslavers', 'Blade Warstone'
    },
}

local running = true
local open, show = true, true
local doTurnIns = false
local selectedZone = 1
local selectableItems = {['TIME']={},['TACVI']={}}
local startingPlanarSymbols = mq.TLO.Me.AltCurrency('Planar Symbols')()
local startingTaelosianSymbols = mq.TLO.Me.AltCurrency('Taelosian Symbols')()

local function findItems()
    -- Find all tradeable potime or tacvi items in bags which are not attuned
    for _,zone in ipairs(zones) do
        selectableItems[zone] = {}
        for _,item in ipairs(turnInItems[zone]) do
            local itemRef = mq.TLO.FindItem('='..item)
            if itemRef() and not itemRef.NoTrade() and itemRef.ItemSlot() > 22 and itemRef.ItemSlot() < 33 then
                table.insert(selectableItems[zone], {Name=item, ItemSlot=itemRef.ItemSlot(), ItemSlot2=itemRef.ItemSlot2(), Selected=false})
            end
        end
    end
end

local function draw()
    if not open then running = false return end
    open, show = ImGui.Begin('Lazarus Symbol Handin', open)
    if show then
        local redeemedPlanarSymbols = mq.TLO.Me.AltCurrency('Planar Symbols')()
        local redeemedTaelosianSymbols = mq.TLO.Me.AltCurrency('Taelosian Symbols')()
        local gainedPlanarSymbols = mq.TLO.FindItemCount('Planar Symbol')()
        local gainedTaelosianSymbols = mq.TLO.FindItemCount('Taelosian Symbol')()
        ImGui.Text('Planar Symbols: ') ImGui.SameLine() ImGui.TextColored(1,1,0,1,'%s', gainedPlanarSymbols + redeemedPlanarSymbols)
        ImGui.SameLine()
        ImGui.Text('Taelosian Symbols: ') ImGui.SameLine() ImGui.TextColored(1,1,0,1,'%s', gainedTaelosianSymbols + redeemedTaelosianSymbols)
        ImGui.Text('Time Loots: ') ImGui.SameLine() ImGui.TextColored(1,1,0,1,'%s', #selectableItems.TIME)
        ImGui.SameLine()
        ImGui.Text('Tacvi Loots: ') ImGui.SameLine() ImGui.TextColored(1,1,0,1,'%s', #selectableItems.TACVI)
        ImGui.Text('Planar Symbols Gained: ')ImGui.SameLine() ImGui.TextColored(0,1,0,1,'%s', gainedPlanarSymbols)
        ImGui.Text('Taelosian Symbols Gained: ') ImGui.SameLine() ImGui.TextColored(0,1,0,1,'%s',  gainedTaelosianSymbols)
        ImGui.BeginDisabled(doTurnIns)
        local tmpselectedZone = ImGui.Combo('Zone', selectedZone, 'Plane of Time\0Tacvi\0')
        if tmpselectedZone ~= selectedZone then
            selectedZone = tmpselectedZone
        end
        if ImGui.Button('Select All') then
            for _,item in ipairs(selectableItems[zones[selectedZone]]) do
                item.Selected = true
            end
        end
        ImGui.SameLine()
        if ImGui.Button('Turn In Selected Items') then
            doTurnIns = true
        end
        -- ImGui.SameLine()
        -- if ImGui.Button('Redeem') then
        --     mq.cmd('/notify InventoryWindow/IW_AltCurr_PointList ')
        -- end
        for _,item in ipairs(selectableItems[zones[selectedZone]]) do
            item.Selected = ImGui.Checkbox(item.Name, item.Selected)
        end
        ImGui.EndDisabled()
    end
    ImGui.End()
end

mq.imgui.init('symbolturningui', draw)

local function handin(item)
    mq.cmdf('/ctrl /itemnotify "%s" leftmouseup', item.Name)

    local startTime = mq.gettime()
    while not mq.TLO.Cursor() do
        if mq.gettime() - startTime > 5000 then break end
        mq.delay(10)
    end
    mq.delay(100)
    if not mq.TLO.Cursor() then return end

    mq.cmd('/click left target')

    startTime = mq.gettime()
    while mq.TLO.Cursor() do
        if mq.gettime() - startTime > 10000 then break end
        mq.delay(10)
    end
    mq.delay(100)
    if mq.TLO.Cursor() then return end

    mq.cmd('/notify GiveWnd GVW_Give_Button leftmouseup')
    startTime = mq.gettime()
    while not mq.TLO.Cursor() do
        if mq.gettime() - startTime > 5000 then break end
        mq.delay(10)
    end

    while mq.TLO.Cursor() do
        mq.cmd('/autoinv')
        mq.delay(10)
    end
    mq.delay(500, function() return not mq.TLO.Cursor() end)
end

findItems()
while running do
    if doTurnIns then
        mq.cmdf('/mqt npc %s', NPCs[selectedZone])
        for _,item in ipairs(selectableItems[zones[selectedZone]]) do
            if item.Selected then
                handin(item)
            end
        end
        findItems()
        doTurnIns = false
    end
    mq.delay(1000)
end