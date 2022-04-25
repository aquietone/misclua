-- ${Task[Aten Ha Ra]}
-- Defeat Aten Ha Ra    ${Task[Aten Ha Ra].Objective[1].Done}
-- type(mq.TLO.Task('Aten Ha Ra').Objective(1).Status())
-- Open the chest and claim your reward.
local mq = require("mq")

local i_am_ma = mq.TLO.Group.Member(0).MainAssist()
local my_name = mq.TLO.Me.CleanName()
local ma_name = mq.TLO.Group.MainAssist.CleanName()
local my_class = mq.TLO.Me.Class.ShortName()

--[[
original door loc: 1186.12 0.932035 235.003
side of door loc: 1222.67 -48.97 236.41
]]
local pause_cmds = ('/%s mode 0; /mqp on; /twist off; /timed 5 /afollow off; /nav stop; /target clear'):format(my_class)
local run_away_cmd = '/timed 10 /nav locxyz 1222.67 -48.97 236.41'
local resume_cmds = ('/timed 150 /%s mode 2; /timed 150 /mqp off; /timed 150 /twist on'):format(my_class)

local full_cmd = ('/multiline ; %s; %s; %s;'):format(pause_cmds, run_away_cmd, resume_cmds)

local function event_in_progress()
    return mq.TLO.SpawnCount('npc Aten Ha Ra')() > 0
end

--[[
    If I am targeted and I am not the Main Assist, or
    If MA is targeted and I am not the Main Assist

    1. manual mode
    2. pause and stop twist and stop movement
    3. clear target
    4. move to door
    5. wait
    6. chase mode
    7. resume

    Outcome: if someone other than MA is targeted, that one person runs to the door.
    Outcome: If MA is targeted, everyone else runs to the door and MA stays in place.
]]--
local function event_points(line, target)
    if target == my_name and not i_am_ma then
        mq.cmd(full_cmd)
    elseif target == ma_name and not i_am_ma then
        mq.cmd(full_cmd)
    end
end
local function event_maset(line, ma)
    i_am_ma = mq.TLO.Group.Member(0).MainAssist()
    ma_name = mq.TLO.Group.MainAssist.CleanName()
    print('MA has been reset!')
end

mq.event('event_maset', '#1# is now group Main Assist', event_maset)
mq.event('event_points', '#*#Aten Ha Ra points at #1# with one arm#*#', event_points)

if not mq.TLO.Zone.ShortName() == 'vexthaltwo_mission' then return end
if mq.TLO.Task('Aten Ha Ra').Objective(1).Status() == 'Done' then return end
print('Aten Silence lua started...')

if not mq.TLO.Group.MainAssist() then
    mq.cmd('/beep')
    mq.cmd('/popcustom 5 No Main Assist set!')
end

while true
do
    if not event_in_progress() then break end
    mq.doevents()
    mq.delay(10)
end

print('Aten Silence lua ended')