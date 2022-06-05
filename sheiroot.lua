local mq = require('mq')

local my_class = mq.TLO.Me.Class.ShortName():lower()
local cure_target = nil
local shackle = mq.TLO.Spell('Shackle').RankName()
local blood = mq.TLO.Spell('Blood of Mayong').RankName()
local word = mq.TLO.Spell('Word of Greater Rejuvination').RankName()

local function configure_cwtn()
    -- mode 0 so we aren't moving
    mq.cmdf('/multiline ; /%s mode 0; /nav stop; /afollo off;', my_class)
    -- mem blood of mayong if shaman
    if my_class == 'shm' and not mq.TLO.CWTN.MemCureAll() then
        mq.cmd('/shm memcureall on')
    end
    if not mq.TLO.CWTN.Paused() then
        mq.cmdf('/%s pause on', my_class)
    end
    mq.delay('5s')
    -- unpause so it actually mems
    --if mq.TLO.CWTN.Paused() then
    --    mq.cmdf('/%s pause off', my_class)
    --end
    --mq.delay('5s')
    -- enable BYOS to mem root
    if not mq.TLO.CWTN.Byos() then
        mq.cmdf('/%s byos on', my_class)
    end
    -- mem root
    if my_class == 'shm' then
        mq.cmdf('/memspell 6 "%s"', blood)
        mq.delay('5s')
        mq.TLO.Window('SpellBookWnd').DoClose()
    end
    mq.cmdf('/memspell 13 "%s"', shackle)
    mq.delay('5s')
    mq.TLO.Window('SpellBookWnd').DoClose()
    -- mode 2 to chase
    mq.cmdf('/%s mode 2', my_class)
    if mq.TLO.CWTN.Paused() then
        mq.cmdf('/%s pause off', my_class)
    end

    if not mq.TLO.Me.Gem(shackle)() then
        print('Failed to mem Shackle!')
        mq.cmd('/beep')
    end
    if my_class == 'shm' and not mq.TLO.Me.Gem(blood)() then
        print('Failed to mem Blood of Mayong!')
        mq.cmd('/beep')
    end
end

local function do_cure()
    mq.cmdf('/%s pause on', my_class)
    mq.cmdf('/mqtarget pc %s', cure_target)
    mq.delay('1s')
    if mq.TLO.Target.Buff('Touch of Vinitras')() then
        if mq.TLO.Me.AltAbilityReady('Radiant Cure')() and not mq.TLO.Me.Casting() then
            mq.cmd('/alt activate 153')
            mq.delay(500+mq.TLO.Me.AltAbility('Radiant Cure').Spell.CastTime())
        end
    end
    if mq.TLO.Target.Buff('Touch of Vinitras')() and not mq.TLO.Me.Casting() then
        if my_class == 'shm' then
            mq.cmdf('/cast "%s"', blood)
        elseif my_class == 'clr' then
            mq.cmdf('/cast "%s"', word)
        end
        mq.delay(50)
        mq.delay(3000, function() return not mq.TLO.Me.Casting() end)
    end
    if not mq.TLO.Target.Buff('Touch of Vinitras')() then
        cure_target = nil
    end
    mq.cmdf('/%s pause off', my_class)
end

local function do_root()
    mq.cmdf('/%s pause on', my_class)
    mq.cmd('/mqtar datiar xi tavuelim npc')

    while mq.TLO.SpawnCount('datiar xi tavuelim npc')() > 0 do
        if mq.TLO.Target.CleanName() ~= 'datiar xi tavuelim' then
            mq.cmd('/mqtar datiar xi tavuelim npc')
            mq.delay(50)
        end
        if mq.TLO.Me.SpellReady(shackle)() and not mq.TLO.Me.Casting() then
            mq.cmdf('/cast %s', shackle)
            mq.delay(1000+mq.TLO.Spell(shackle).MyCastTime())
        end
    end

    mq.cmdf('/%s pause off', my_class)
end

local function event_in_progress()
    return mq.TLO.SpawnCount('npc Shei Vinitras')() > 0
end

local function event_dt(line, target)
    print('DT event fired')
    cure_target = target
end

mq.event('event_dt', "#*#Shei Vinitras shouts, '#1#, You are unworthy#*#", event_dt)

if mq.TLO.Zone.ShortName() ~= 'akhevatwo_mission' then return end
if my_class ~= 'clr' and my_class ~= 'shm' then return end
if mq.TLO.Task('Shei Vinitras').Objective(1).Status() == 'Done' then return end
print('Shei Vinitras Root lua has started...')
configure_cwtn()

while true
do
    if not event_in_progress() then break end

    mq.doevents()

    if cure_target then
        do_cure()
    end
    if mq.TLO.SpawnCount('datiar xi tavuelim npc')() > 0 then
        do_root()
    end

    mq.delay(10)
end

if my_class == 'shm' then
    mq.cmd('/shm memcureall off')
end
mq.cmdf('/%s byos off', my_class)
print('Shei Vinitras Root lua ended')