ScriptName = "Flesh-hatcher Mhekarnahz Killer"
Author = "MemoryError"
Version = "3.0"

local API = require("api")
local GUI = require("fleshhatcher.FleshHatcherGUI")

local Config = {
    BANK_CHEST   = 114750,
    ALTAR        = 114748,
    BOSS_PORTAL  = 114764,
    ENTRANCE     = 134744,
    LEDGE        = 134746,
    CORPSE       = 32508,
    BOSS_ID      = 30823,
    DEATH_ANIM   = 37206,
    MAX_FIGHT    = 300,
    EMERGENCY_HP = 20,
    ADREN_CRYSTAL = 114749,
    INSTANCE_EXPIRY_VARBIT = 9925,
}

local Stats = {
    startTime     = os.time(),
    kills         = 0,
    deaths        = 0,
    killTimes     = {},
    killStartTime = 0,
    currentState  = "Idle",
    lastIdle      = os.time(),
}

local hasAttacked = false

local function formatTime(seconds)
    return string.format("%02d:%02d:%02d",
        math.floor(seconds / 3600),
        math.floor((seconds % 3600) / 60),
        seconds % 60)
end

local function getKillStat(compareFn)
    if #Stats.killTimes == 0 then return nil end
    local result = Stats.killTimes[1]
    for i = 2, #Stats.killTimes do
        if compareFn(Stats.killTimes[i], result) then result = Stats.killTimes[i] end
    end
    return formatTime(result)
end

local function getAverageKill()
    if #Stats.killTimes == 0 then return nil end
    local total = 0
    for _, t in ipairs(Stats.killTimes) do total = total + t end
    return formatTime(math.floor(total / #Stats.killTimes))
end

local function buildGUIData()
    local bossHP, bossMaxHP = nil, nil

    if Stats.currentState == "Fighting" then
        local npcs = API.GetAllObjArrayInteract({Config.BOSS_ID}, 50, {1})
        for _, npc in ipairs(npcs) do
            if npc.Id == Config.BOSS_ID and npc.Health then
                bossHP = npc.Health
                bossMaxHP = npc.MaxHealth or 100000
                break
            end
        end
    end

    return {
        state        = Stats.currentState,
        kills        = Stats.kills,
        deaths       = Stats.deaths,
        runtime      = os.time() - Stats.startTime,
        killStartTime = Stats.killStartTime > 0 and Stats.killStartTime or nil,
        killTimes    = Stats.killTimes,
        fastestKill  = getKillStat(function(a, b) return a < b end),
        slowestKill  = getKillStat(function(a, b) return a > b end),
        averageKill  = getAverageKill(),
        bossHealth   = bossHP,
        bossMaxHealth = bossMaxHP,
    }
end


local Utils = {}

function Utils:antiIdle()
    if os.time() - Stats.lastIdle > 120 then
        API.DoRandomEvents()
        API.PIdle2()
        Stats.lastIdle = os.time()
    end
end

function Utils:emergencyCheck()
    if API.GetHPrecent() < Config.EMERGENCY_HP then
        GUI.addWarning("Emergency: HP critically low!")
        return true
    end
    return false
end

function Utils:togglePrayer(prayerId)
    API.DoAction_Interface(0xffffffff, 0xffffffff, 1, 1458, 40, prayerId, API.OFF_ACT_GeneralInterface_route)
    API.RandomSleep2(600, 200, 400)
end

function Utils:activateCurse()
    local sorrow = API.GetABs_name("Sorrow", true)
    local ruination = API.GetABs_name("Ruination", true)

    if sorrow.enabled then
        API.DoAction_Ability("Sorrow", 1, API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(600, 200, 400)
        return true
    elseif ruination.enabled then
        API.DoAction_Ability("Ruination", 1, API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(600, 200, 400)
        return true
    end

    GUI.addWarning("Neither Sorrow nor Ruination found on ability bar")
    return false
end

function Utils:deactivateCurse()
    local sorrow = API.GetABs_name("Sorrow", true)
    local ruination = API.GetABs_name("Ruination", true)

    if sorrow.enabled then
        API.DoAction_Ability("Sorrow", 1, API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(600, 200, 400)
    elseif ruination.enabled then
        API.DoAction_Ability("Ruination", 1, API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(600, 200, 400)
    end
end


local WarsRetreat = {}

function WarsRetreat:teleport()
    if not API.Read_LoopyLoop() then return false end
    Stats.currentState = "Teleporting"
    API.DoAction_Ability("War's Retreat Teleport", 1, API.OFF_ACT_GeneralInterface_route)
    API.RandomSleep2(3000, 1200, 1800)
    return true
end

function WarsRetreat:bank()
    if not API.Read_LoopyLoop() then return false end
    Stats.currentState = "Banking"

    hasAttacked = false -- reset attack state at the start of each kill cycle

    if not API.DoAction_Object1(0x33, API.OFF_ACT_GeneralObject_route3, {Config.BANK_CHEST}, 50) then
        GUI.addWarning("Failed to load preset")
        return false
    end

    API.RandomSleep2(3500, 500, 800)
    return true
end

function WarsRetreat:altar()
    if not API.Read_LoopyLoop() then return false end
    if API.GetPrayPrecent() >= 100 then return true end

    Stats.currentState = "Altar"
    API.DoAction_Object1(0x3d, API.OFF_ACT_GeneralObject_route0, {Config.ALTAR}, 50)
    API.RandomSleep2(3500, 500, 800)
    return true
end

function WarsRetreat:adrenalineCrystal()
    if not API.Read_LoopyLoop() then return false end
    if tonumber(API.GetAdrenalineFromInterface()) >= 100 then return true end

    Stats.currentState = "Adrenaline Crystal"
    API.DoAction_Object1(0x29, API.OFF_ACT_GeneralObject_route0, {Config.ADREN_CRYSTAL}, 50)
    API.RandomSleep2(2900, 100, 100)

    local surge = API.GetABs_name("Surge", true)
    if surge.enabled and surge.cooldown_timer <= 0 then
        API.DoAction_Ability("Surge", 1, API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(100, 50, 50)
    end

    API.DoAction_Object1(0x29, API.OFF_ACT_GeneralObject_route0, {Config.ADREN_CRYSTAL}, 50)
    API.RandomSleep2(1200, 50, 50)

    while API.Read_LoopyLoop() and tonumber(API.GetAdrenalineFromInterface()) < 100 do
        API.RandomSleep2(600, 100, 200)
    end

    return true
end

function WarsRetreat:enterPortal()
    if not API.Read_LoopyLoop() then return false end
    Stats.currentState = "Entering Portal"
    API.DoAction_Object1(0x39, API.OFF_ACT_GeneralObject_route0, {Config.BOSS_PORTAL}, 50)
    API.RandomSleep2(11000, 1000, 1500)
    return true
end


local Boss = {}

function Boss:enterInstance()
    if not API.Read_LoopyLoop() then return false end
    Stats.currentState = "Entering Instance"

    API.DoAction_Object1(0x39, API.OFF_ACT_GeneralObject_route0, {Config.ENTRANCE}, 50)
    API.RandomSleep2(1500, 800, 1200)

    API.KeyboardPress2(0x32, 150, 200)
    API.RandomSleep2(1200, 600, 900)

    if not API.GetInterfaceOpenBySize(1591) then
        API.RandomSleep2(1500, 600, 900)
    end

    if API.GetInterfaceOpenBySize(1591) then
        API.DoAction_Interface(0x24, 0xffffffff, 1, 1591, 60, -1, API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(1800, 800, 1200)
    else
        GUI.addWarning("Instance interface did not open")
        return false
    end

    return true
end

function Boss:navigate()
    if not API.Read_LoopyLoop() then return false end
    Stats.currentState = "Navigating"

    local surge = API.GetABs_name("Surge", true)
    if surge.enabled and surge.cooldown_timer <= 0 then
        API.DoAction_Ability("Surge", 1, API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(0, 400, 600)
    end

    API.DoAction_Object1(0x29, API.OFF_ACT_GeneralObject_route0, {Config.LEDGE}, 50)
    API.RandomSleep2(2600, 1800, 2800)

    Utils:togglePrayer(35)
    Utils:activateCurse()

    return true
end

function Boss:findAlive()
    local npcs = API.GetAllObjArrayInteract({Config.BOSS_ID}, 50, {1})
    for _, npc in ipairs(npcs) do
        if npc.Id == Config.BOSS_ID and (not npc.Health or npc.Health > 0) then
            return npc
        end
    end
    return nil
end

function Boss:loot()
    Stats.currentState = "Looting"

    Utils:togglePrayer(35)
    Utils:deactivateCurse()

    API.RandomSleep2(0, 400, 800)
    local corpses = API.GetAllObjArrayInteract({Config.CORPSE}, 50, {1})

    if #corpses == 0 then
        GUI.addWarning("No corpse found after kill #" .. Stats.kills)
        return
    end

    API.DoAction_NPC(0x29, API.OFF_ACT_InteractNPC_route, {Config.CORPSE}, 50)
    API.RandomSleep2(1200, 800, 1200)

    API.DoAction_Interface(0x24, 0xffffffff, 1, 168, 27, -1, API.OFF_ACT_GeneralInterface_route)
    API.RandomSleep2(1200, 400, 600)
end

function Boss:fight()
    if not API.Read_LoopyLoop() then return false end
    Stats.currentState = "Fighting"
    Stats.killStartTime = os.time()

    local fightStart = os.time()

    while API.Read_LoopyLoop() do
        if GUI.isStopped() then return false end

        while GUI.isPaused() and API.Read_LoopyLoop() do
            API.RandomSleep2(200, 50, 100)
        end

        if Utils:emergencyCheck() then return false end
        if os.time() - fightStart > Config.MAX_FIGHT then return false end

        local boss = self:findAlive()

        if hasAttacked and boss and boss.Anim == Config.DEATH_ANIM then
            local killDuration = os.time() - Stats.killStartTime
            Stats.kills = Stats.kills + 1
            Stats.killTimes[#Stats.killTimes + 1] = killDuration
            Stats.killStartTime = 0

            API.RandomSleep2(4000, 800, 1200)
            self:loot()
            return true
        end

        if boss and not hasAttacked then
            API.DoAction_NPC(0x29, API.OFF_ACT_AttackNPC_route, {Config.BOSS_ID}, 50)
            API.RandomSleep2(1500, 300, 500)
            hasAttacked = true
        end

        Utils:antiIdle()
        API.RandomSleep2(600, 100, 200)
    end

    return false
end


local function waitForGUIStart()
    GUI.reset()
    GUI.loadConfig()

    ClearRender()
    DrawImGui(function()
        if GUI.open then GUI.draw({}) end
    end)

    while API.Read_LoopyLoop() and not GUI.started do
        if not GUI.open or GUI.isCancelled() then
            ClearRender()
            return false
        end
        API.RandomSleep2(100, 50, 0)
    end

    return API.Read_LoopyLoop()
end

local function applyGUIConfig()
    local cfg = GUI.getConfig()
    Config.START_AT_WARS = cfg.startAtWars
    Config.TELEPORT_BETWEEN_KILLS = cfg.teleportBetweenKills
end

local function startLiveGUI()
    GUI.selectInfoTab = true
    ClearRender()
    DrawImGui(function()
        if GUI.open then GUI.draw(buildGUIData()) end
    end)
end

local function runKillCycle()
    if not WarsRetreat:bank() then
        GUI.addWarning("Failed to bank")
        API.RandomSleep2(0, 1000, 2000)
        return
    end

    WarsRetreat:altar()
    WarsRetreat:adrenalineCrystal()

    if not WarsRetreat:enterPortal() then
        GUI.addWarning("Failed to enter portal")
        API.RandomSleep2(0, 600, 1200)
        return
    end

    if not Boss:enterInstance() then
        GUI.addWarning("Failed to enter instance")
        API.RandomSleep2(0, 600, 800)
        return
    end

    Boss:navigate()

    if not Boss:fight() then
        Stats.deaths = Stats.deaths + 1
        Stats.killStartTime = 0
        GUI.addWarning("Fight failed, teleporting back")
        WarsRetreat:teleport()
        API.RandomSleep2(0, 1200, 1800)
        return
    end

    WarsRetreat:teleport()
    API.RandomSleep2(0, 1200, 1800)
end


Write_fake_mouse_do(false)

if not waitForGUIStart() then return end

applyGUIConfig()
startLiveGUI()

while API.Read_LoopyLoop() do
    if GUI.isStopped() then break end

    if GUI.isPaused() then
        Stats.currentState = "Paused"
        API.RandomSleep2(200, 50, 100)
    else
        runKillCycle()
    end
    
    API.RandomSleep2(100, 200, 400)
end

ClearRender()
