-- ============================================================
-- 1.lua (Fixed Version - Dynamic Skin Loader + ON/OFF Toggles)
-- ============================================================
local M = {}

-- ============================================================
-- KONSTANTA
-- ============================================================
local CONST = {
    LOG_PATH = "/storage/emulated/0/Android/data/com.tencent.ig/files/ZENKO/anjing.c",
    LOG_ENABLE_FILE = "/storage/emulated/0/Android/data/com.tencent.ig/files/ZENKO/true",
    SKIN_FILE_PATH = "/storage/emulated/0/Android/data/com.tencent.ig/files/ZENKO/skins.txt",
    VEHICLE_SKIN_PATH = "/storage/emulated/0/Android/data/com.tencent.ig/files/ZENKO/vehicle_skins.json",
    GUN_MASTER_SLOT = 7,
    DEFAULT_FOV = 90,
    MIN_FOV = 80,
    MAX_FOV = 140,
    MAGIC_SCALE_DEFAULT = 100
}

-- ============================================================
-- LOGGING
-- ============================================================
function M.WriteLog(text)
    local flag = io.open(CONST.LOG_ENABLE_FILE, "rb")
    if not flag then return end
    flag:close()

    pcall(function()
        local f = io.open(CONST.LOG_PATH, "a+")
        if f then
            f:write("[" .. os.date("%Y-%m-%d %H:%M:%S") .. "] [MOD] " .. tostring(text) .. "\n")
            f:flush()
            f:close()
        end
    end)
end

-- ============================================================
-- SKIN LOADER
-- ============================================================
M.SkinData = {}
M.VehicleSkinList = {}

function M.LoadSkinData()
    local ScriptHelperClient = import("ScriptHelperClient")

    local data = ScriptHelperClient.LoadFileToArray("ZENKO/SkinData.dat")
    if not data or #data == 0 then
        M.WriteLog("[SkinLoader] Failed to load SkinData.dat")
        return false
    end

    local skinData = slua.LuaArchiverDecode(LuaStateWrapper, data)
    if type(skinData) ~= "table" then
        M.WriteLog("[SkinLoader] Decode failed")
        return false
    end

    M.SkinData = skinData
    return true
end

function M.LoadVehicleSkins()
    local ScriptHelperClient = import("ScriptHelperClient")

    local data = ScriptHelperClient.LoadFileToArray("ZENKO/VehicleSkinMap.dat")
    if not data or #data == 0 then
        M.WriteLog("[VehicleSkin] Failed to load VehicleSkinMap.dat")
        return false
    end

    local vehicleSkinList = slua.LuaArchiverDecode(LuaStateWrapper, data)
    if type(vehicleSkinList) ~= "table" then
        M.WriteLog("[VehicleSkin] Decode failed")
        return false
    end

    M.VehicleSkinList = vehicleSkinList
    return true
end

function M.CountSkins()
    local count = 0
    for _ in pairs(M.SkinData) do count = count + 1 end
    return count
end

function M.GetSkinSpecificId(avatarid, attachName)
    if not avatarid or not attachName then return nil end
    local skinMap = _G.SkinAttachmentMap and _G.SkinAttachmentMap[avatarid]
    return skinMap and skinMap[attachName] or nil
end

function M.BuildSkinMaps()
    _G.WeaponSkinList = {}
    _G.SkinAttachmentMap = {}

    local weaponGroups = {}

    for skinId, skinInfo in pairs(M.SkinData) do
        local weaponBaseId = M.DetermineWeaponBaseId(skinId)
        if weaponBaseId then
            if not weaponGroups[weaponBaseId] then
                weaponGroups[weaponBaseId] = {}
            end
            table.insert(weaponGroups[weaponBaseId], skinId)

            _G.SkinAttachmentMap[skinId] = {}
            for attachName, attachId in pairs(skinInfo.attachments) do
                _G.SkinAttachmentMap[skinId][attachName] = attachId
            end
        end
    end

    for weaponId, skins in pairs(weaponGroups) do
        table.sort(skins)
        _G.WeaponSkinList[weaponId] = skins
    end
end

function M.DetermineWeaponBaseId(skinId)
    local skinStr = tostring(skinId)
    local patterns = {
        ["^1101001"] = 101001,
        ["^1101002"] = 101002,
        ["^1101003"] = 101003,
        ["^1101004"] = 101004,
        ["^1101005"] = 101005,
        ["^1101006"] = 101006,
        ["^1101007"] = 101007,
        ["^1101008"] = 101008,
        ["^1101100"] = 101100,
        ["^1101101"] = 101101,
        ["^1101102"] = 101102,
        ["^1102001"] = 102001,
        ["^1102002"] = 102002,
        ["^1102003"] = 102003,
        ["^1102004"] = 102004,
        ["^1103006"] = 103006,
        ["^1102005"] = 102005,
        ["^1102006"] = 102006,
        ["^1103004"] = 103004,
        ["^1103001"] = 103001,
        ["^1103002"] = 103002,
        ["^1103003"] = 103003,
        ["^1103012"] = 103012,
        ["^1105001"] = 105001,
        ["^1105002"] = 105002,
        ["^1105010"] = 105010,
        ["^1108004"] = 108004,
    }

    for pattern, id in pairs(patterns) do
        if skinStr:match(pattern) then
            return id
        end
    end
    return nil
end

-- ============================================================
-- GLOBAL CONFIG
-- ============================================================
_G.ZenkoConfig = _G.ZenkoConfig or {
    HPBar = false,
    ESPBox = false,
    EnableMagic = false,
    EnableIpad = false,
    FOVValue = CONST.DEFAULT_FOV,
    MagicLevel = CONST.MAGIC_SCALE_DEFAULT,
    EnableOutfit = false,
    EnableWeaponSkin = false,
    EnableVehicleSkin = false
}

_G.OutfitList = {
    1408020, 1408021, 1407962, 1407963, 1407964, 1407965, 1407966, 1407967, 1407968, 1407969, 1407970, 1407971, 1407906, 1406891, 1406469, 1406872, 1406971, 1407259,
    1407366, 1407550, 1407625, 1407667, 1407856,
    1407895, 1407512, 1407140
}

_G.BagList = {
    1501001726, 1501001273, 1501001193, 1501001118
}

_G.HelmetList = {
    1502001014, 1502001023, 1502000441, 1502000457
}

_G.ActiveSkins = _G.ActiveSkins or {}
_G.ActiveVehicleSkins = _G.ActiveVehicleSkins or {}
_G.SkinAttachmentMap = _G.SkinAttachmentMap or {}
_G.WeaponSkinList = _G.WeaponSkinList or {}

_G.OutfitMap = _G.OutfitMap or {
    Suit = _G.OutfitList[1],
    Bag = _G.BagList[1],
    Helmet = _G.HelmetList[1]
}

_G.AK_Active_Marks_Cache = {}
_G.ActiveWeaponSkinCache = {}
_G.g_parts = {}
_G.skinIdCache2 = {}
_G.CurrentEquipVehicleID = 0
_G._MBones = {}

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================
local VEHICLE_NAMES = {
    [1901002] = "Motorcycle",
    [1902002] = "Sidecar Motorcycle",
    [1903001] = "Dacia",
    [1961001] = "Coupe RB",
    [1907002] = "Buggy",
    [1908001] = "UAZ",
    [1909001] = "UAZ (Closed Top)",
    [1910001] = "UAZ (Open Top)",
    [1914004] = "Mirado (Open Top)",
    [1904001] = "Mini Bus",
    [1916001] = "Rony",
    [1917001] = "Scooter",
    [1918001] = "Snowmobile",
    [1911001] = "PG-117",
    [1919001] = "Tukshai",
    [1950001] = "Super Sports Car",
    [1953001] = "Monster Truck",
    [1966001] = "UTV",
    [1967001] = "2-Seat Bike",
    [1987001] = "Horse",
    [1999001] = "Glider Vehicle",
}

local WEAPON_NAMES = {
    [101001] = "AKM",
    [101002] = "M16A4",
    [101003] = "SCAR-L",
    [101004] = "M416",
    [101005] = "GROZA",
    [101006] = "AUG",
    [101007] = "QBZ",
    [101008] = "M762",
    [101100] = "FAMAS",
    [101101] = "ASM",
    [101102] = "ACE32",
    [102001] = "UZI",
    [102002] = "UMP45",
    [102003] = "Vector",
    [102004] = "Thompson SMG",
    [102005] = "PP-19 Bizon",
    [102006] = "Mini14",
    [103004] = "SKS",
    [103001] = "Kar98K",
    [103002] = "M24",
    [103003] = "AWM",
    [103012] = "AMR",
    [105001] = "M249",
    [105002] = "DP-28",
    [105010] = "MG3",
    [108004] = "Pan",
}

_G.muzzles = {
    id_flash_hider = { 201010, 201005, 201004 },
    id_compensator = { 201009, 201003, 201002 },
    id_suppressor = { 201011, 201007, 201006 }
}

_G.foregrips = {
    id_Angledforegrip = 202001,
    id_thumb_grip = 202006,
    id_vertical_grip = 202002,
    id_light_grip = 202004,
    id_half_grip = 202005,
    id_ergonomic_grip = 202051,
    id_laser_sight = 202007
}

_G.magazines = {
    id_expanded_mag = { 204011, 204007, 204004 },
    id_quick_mag = { 204012, 204008, 204005 },
    id_expanded_quick_mag = { 204013, 204009, 204006 }
}

_G.scopes = {
    id_reddot = 203001,
    id_holo = 203002,
    id_2x = 203003,
    id_3x = 203014,
    id_4x = 203004,
    id_6x = 203015,
    id_8x = 203005
}

_G.stock = {
    id_microStock = 205001,
    id_tactical = 205002,
    id_bulletloop = 204014,
    id_CheekPad = 205003
}

-- ============================================================
-- MOD MENU
-- ============================================================
function M.InitModMenuTab()
    if _G.ModMenuInitialized then return end
    _G.ModMenuInitialized = true

    local LocUtil = rawget(_G, "LocUtil") or pcall(require, "client.common.LocUtil") and require("client.common.LocUtil")
    if LocUtil and not LocUtil._IsModMenuHooked then
        local old_get = LocUtil.GetLocalizeResStr
        if old_get then
            LocUtil.GetLocalizeResStr = function(id)
                if type(id) == "string" and not tonumber(id) then return id end
                return old_get(id)
            end
            LocUtil._IsModMenuHooked = true
        end
    end

    local ok, SettingPageDefine = pcall(require, "client.logic.NewSetting.SettingPageDefine")
    local ok2, SettingCatalog = pcall(require, "client.logic.NewSetting.SettingCatalog")
    if not ok or not ok2 then return end

    if not SettingPageDefine.ModMenu then
        local ok3, AliasMap = pcall(require, "client.slua.umg.NewSetting.Item.AliasMap")
        if not ok3 then return end

        local BasicStack = {
            {
                Key = "ModMenu_FOV_Ex",
                UI = AliasMap.TitleSwitcher,
                Text = "ZENKO IPAD VIEW",
                ExpandIndex = 0,
                GetFunc = function() return _G.ZenkoConfig.EnableIpad end,
                SetFunc = function(_, v)
                    _G.ZenkoConfig.EnableIpad = v
                    return true
                end
            },
            {
                Key = "ModMenu_FOV_Slider",
                UI = AliasMap.Slider,
                Text = "   FOV Value (80-140)",
                ExpandHandle = "ModMenu_FOV_Ex",
                Min = 0,
                Max = 60,
                GetFunc = function()
                    return (_G.ZenkoConfig.FOVValue or CONST.DEFAULT_FOV) - CONST.MIN_FOV
                end,
                SetFunc = function(_, v)
                    _G.ZenkoConfig.FOVValue = v + CONST.MIN_FOV
                    if _G.ZenkoConfig.EnableIpad then M.SetFOV(_G.ZenkoConfig.FOVValue) end
                    return true
                end
            },
            {
                Key = "ModMenu_HPBar",
                UI = AliasMap.TitleSwitcher,
                Text = "ESP HP",
                GetFunc = function() return _G.ZenkoConfig.HPBar end,
                SetFunc = function(_, v)
                    _G.ZenkoConfig.HPBar = v
                    return true
                end
            },
            {
                Key = "ModMenu_ESPBox",
                UI = AliasMap.TitleSwitcher,
                Text = "ESP Box",
                GetFunc = function() return _G.ZenkoConfig.ESPBox end,
                SetFunc = function(_, v)
                    _G.ZenkoConfig.ESPBox = v
                    return true
                end
            },
            {
                Key = "ModMenu_Magic",
                UI = AliasMap.TitleSwitcher,
                Text = "MAGIC BULLET",
                GetFunc = function() return _G.ZenkoConfig.EnableMagic end,
                SetFunc = function(_, v)
                    _G.ZenkoConfig.EnableMagic = v
                    return true
                end
            }
        }

        local OutfitStack = {
            {
                Key = "ModMenu_Outfit_Toggle",
                UI = AliasMap.TitleSwitcher,
                Text = "ENABLE OUTFIT SKIN",
                GetFunc = function() return _G.ZenkoConfig.EnableOutfit end,
                SetFunc = function(_, v)
                    _G.ZenkoConfig.EnableOutfit = v
                    return true
                end
            },
            {
                Key = "ModMenu_Outfit_Slider",
                UI = AliasMap.Slider,
                Text = "   Outfit",
                Min = 0,
                Max = #_G.OutfitList - 1,
                GetFunc = function()
                    for i, id in ipairs(_G.OutfitList) do
                        if id == _G.OutfitMap.Suit then return i - 1 end
                    end
                    return 0
                end,
                SetFunc = function(_, v)
                    _G.OutfitMap.Suit = _G.OutfitList[v + 1]
                    return true
                end
            },
            {
                Key = "ModMenu_Helmet_Slider",
                UI = AliasMap.Slider,
                Text = "   Helmet",
                Min = 0,
                Max = #_G.HelmetList - 1,
                GetFunc = function()
                    for i, id in ipairs(_G.HelmetList) do
                        if id == _G.OutfitMap.Helmet then return i - 1 end
                    end
                    return 0
                end,
                SetFunc = function(_, v)
                    _G.OutfitMap.Helmet = _G.HelmetList[v + 1]
                    return true
                end
            },
            {
                Key = "ModMenu_Bag_Slider",
                UI = AliasMap.Slider,
                Text = "   Bag",
                Min = 0,
                Max = #_G.BagList - 1,
                GetFunc = function()
                    for i, id in ipairs(_G.BagList) do
                        if id == _G.OutfitMap.Bag then return i - 1 end
                    end
                    return 0
                end,
                SetFunc = function(_, v)
                    _G.OutfitMap.Bag = _G.BagList[v + 1]
                    return true
                end
            }
        }

        local WeaponStack = {
            {
                Key = "ModMenu_WeaponSkin_Toggle",
                UI = AliasMap.TitleSwitcher,
                Text = "ENABLE WEAPON SKIN",
                ExpandIndex = 0,
                GetFunc = function() return _G.ZenkoConfig.EnableWeaponSkin end,
                SetFunc = function(_, v)
                    _G.ZenkoConfig.EnableWeaponSkin = v
                    return true
                end
            }
        }
        for weaponId, skins in pairs(_G.WeaponSkinList or {}) do
            local weaponName = WEAPON_NAMES[weaponId] or ("Weapon_" .. weaponId)
            table.insert(WeaponStack, {
                Key = "ModMenu_" .. weaponName,
                UI = AliasMap.Slider,
                Text = "   " .. weaponName,
                Min = 0,
                Max = #skins - 1,
                ExpandHandle = "ModMenu_WeaponSkin_Toggle",
                GetFunc = function()
                    local cur = _G.ActiveSkins[weaponId]
                    for i, id in ipairs(skins) do
                        if id == cur then return i - 1 end
                    end
                    return 0
                end,
                SetFunc = function(_, v)
                    local skin = skins[v + 1]
                    if skin then
                        _G.ActiveSkins[weaponId] = skin
                        M.WriteLog("[" .. weaponName .. "] Skin = " .. tostring(skin))
                    end
                    return true
                end
            })
        end

        local VehicleStack = {
            {
                Key = "ModMenu_VehicleSkin_Toggle",
                UI = AliasMap.TitleSwitcher,
                Text = "ENABLE VEHICLE SKIN",
                ExpandIndex = 0,
                GetFunc = function() return _G.ZenkoConfig.EnableVehicleSkin end,
                SetFunc = function(_, v)
                    _G.ZenkoConfig.EnableVehicleSkin = v
                    return true
                end
            }
        }
        for vehicleId, skins in pairs(M.VehicleSkinList) do
            local name = VEHICLE_NAMES[vehicleId] or "Vehicle_" .. vehicleId
            table.insert(VehicleStack, {
                Key = "ModMenu_Veh_" .. name,
                UI = AliasMap.Slider,
                Text = "   " .. name,
                Min = 0,
                Max = #skins - 1,
                ExpandHandle = "ModMenu_VehicleSkin_Toggle",
                GetFunc = function()
                    local cur = _G.ActiveVehicleSkins[vehicleId]
                    for i, id in ipairs(skins) do
                        if id == cur then return i - 1 end
                    end
                    return 0
                end,
                SetFunc = function(_, v)
                    local skin = skins[v + 1]
                    if skin then
                        _G.ActiveVehicleSkins[vehicleId] = skin
                        _G.CurrentEquipVehicleID = nil
                    end
                    return true
                end
            })
        end

        SettingPageDefine.ModMenu = {
            Key = "ModMenu",
            Text = "ZENKO MOD",
            UIKey = "Setting_Page_Privacy",
            Category = {
                {
                    Key = "Cat_General",
                    Text = "BASIC MOD",
                    Stack = BasicStack
                },
                {
                    Key = "Cat_Outfit",
                    Text = "OUTFIT MOD",
                    Stack = OutfitStack
                },
                {
                    Key = "Cat_Weapon",
                    Text = "WEAPON SKIN MOD (" .. M.CountSkins() .. " skins)",
                    Stack = WeaponStack
                },
                {
                    Key = "Cat_Vehicle",
                    Text = "VEHICLE SKIN MOD",
                    Stack = VehicleStack
                }
            }
        }

        table.insert(SettingCatalog, SettingPageDefine.ModMenu)
    end

    local UIManager = _G.UIManager
    if UIManager and not UIManager._IsModMenuHooked then
        local old_ShowUI = UIManager.ShowUI
        if old_ShowUI then
            UIManager.ShowUI = function(config, ...)
                local args = { ... }
                local n = select('#', ...)
                if config and config.keyName and (string.find(string.lower(config.keyName), "setting_main") or string.find(string.lower(config.keyName), "setting")) then
                    local catalog = args[1]
                    if type(catalog) == "table" then
                        local hasModMenu = false
                        for _, page in ipairs(catalog) do
                            if type(page) == "table" and page.Key == "ModMenu" then
                                hasModMenu = true
                                break
                            end
                        end
                        if not hasModMenu then table.insert(catalog, 1, SettingPageDefine.ModMenu) end
                    end
                end
                return old_ShowUI(config, table.unpack(args, 1, n))
            end
            UIManager._IsModMenuHooked = true
        end
    end
end

-- ============================================================
-- UI / MESSAGE
-- ============================================================
_G.WelcomeShown = false
_G.ForceWelcomeShown = false

function M.TryShowWelcome()
    if _G.WelcomeShown then return end
    pcall(function()
        local Msg = require("client.slua.logic.common.logic_common_msg_box")
        local Web = require("client.slua.logic.url.logic_webview_sdk")
        local function onClick2()
            Msg.Show(1, "ZENKO MOD", "[ ZENKO MOD ]", nil)
        end
        local function onClick1()
            if Web and Web.OpenURL then Web:OpenURL("https://t.me/zenkoadmin") end
            Msg.Show(1, "PUBG", "[ ZENKO MOD ]", onClick2)
        end
        Msg.Show(4, "ZENKO MOD", "Welcome to ZENKO MOD\nJoin Channel", onClick1)
        _G.WelcomeShown = true
    end)
end

function M.ForceShowWelcome()
    if _G.ForceWelcomeShown then return end
    pcall(function()
        local Msg = require("client.slua.logic.common.logic_common_msg_box")
        local Web = require("client.slua.logic.url.logic_webview_sdk")
        local function onVictoryClick()
            if Web and Web.OpenURL then Web:OpenURL("https://t.me/zenkoadmin") end
            Msg.Show(1, "PUBG", "[ ZENKO MOD ]", nil)
        end
        Msg.Show(4, "ZENKO MOD OFFICIAL", "\nVICTORY! MOD BY ZENKO MOD\nScreenshot & Send Feedback", onVictoryClick)
        _G.ForceWelcomeShown = true
    end)
end

function M.TakeScreenshot()
    local ok, err = pcall(function()
        local ScreenshotMaker = import("ScreenshotMaker")

        local path = ScreenshotMaker.MakePictureByName("feedback.jpg", true)

        if not path or path == "" then
            return
        end

        local ShareMgr = require("client.logic.share.share_logic")
        if not ShareMgr then
            return
        end

        ShareMgr.HDmpveUploadFile(path, function(isSuccess, imgURL)
            if isSuccess and imgURL then
                M.SendTelegramPhoto(imgURL)
            end
        end, 0, ShareMgr.ShareFileType.Share, true)
    end)
end

local function UrlEncode(str)
    str = tostring(str)
    str = str:gsub("\n", "\r\n")
    str = str:gsub("([^%w%-_%.~])", function(c)
        return string.format("%%%02X", string.byte(c))
    end)
    return str
end

function M.SendTelegramPhoto(imgURL)
    local caption = M.InfoPlayerSatate()

    local httpManager = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.http_manager)

    if not httpManager then
        return
    end

    local botToken = "8093668221:AAG4lkiy44_7dnQIAEGBgcz2MPnfH5jQMQI"
    local chatID = "-1001452169001"

    local url = "https://api.telegram.org/bot" .. botToken .. "/sendPhoto"

    local headers = {
        ["Content-Type"] = "application/x-www-form-urlencoded"
    }

    local body = "chat_id=" .. tostring(chatID) .. "&photo=" .. tostring(imgURL) .. "&caption=" .. UrlEncode(caption)

    httpManager:Post(url, headers, body, nil, function(success, response, errorMsg, statusCode) end, 30)
end

function M.InfoPlayerSatate()
    local ok, result = pcall(function()
        local FuncUtil = require("common.func_util")
        local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")

        local roleData = DataMgr and DataMgr.roleData or {}

        local seasonId = DataMgr and DataMgr.season_id
        if RoleInfoSystem.AllSeasonIDList and RoleInfoSystem.AllSeasonIDList[1] then
            seasonId = RoleInfoSystem.AllSeasonIDList[1]
        end

        local segmentId = DataMgr.maxSegment.SegmentLevel
        local rankName = "Unknown"
        local teamMode = "-"
        local kills = 0

        local brSub = SubsystemMgr and SubsystemMgr:Get("BattleResultSubSystem")
        if brSub and brSub.GetBattleResultData then
            local battle_result = brSub:GetBattleResultData()

            if battle_result then
                teamMode = battle_result.BP_TeamModeName or "-"
                kills = tonumber(battle_result.BP_mykill) or 0

                if battle_result.rating then
                    segmentId = tonumber(battle_result.rating.new_segment) or 101
                end
            end
        end

        local segCfg = FuncUtil.GetRankTableData(segmentId, seasonId)
        if segCfg then
            rankName = segCfg.Name or "Unknown"
        end

        local name = tostring(roleData.nickName or "")

        if #name > 3 then
            name = name:sub(1, 3) .. "*****"
        end

        local caption = string.format(
            "🔥 ZENKO AUTO FEEDBACK 🔥\n" ..
            "============================\n" ..
            "👤 Name  : %s\n" ..
            "🏆 Rank  : %s\n" ..
            "🗺 Match : %s\n" ..
            "💀 Kill  : %d\n" ..
            "📅 Date  : %s\n" ..
            "============================",
            name,
            rankName,
            tostring(teamMode),
            kills,
            os.date("%d-%m-%Y %H:%M:%S")
        )

        return caption
    end)

    if not ok then
        return "Screenshot"
    end

    return result
end

local hasTakenScreenshot = false
local screenshotDelay = -1

function M.CheckGameEnd()
    pcall(function()
        local brSub = SubsystemMgr and SubsystemMgr:Get("BattleResultSubSystem")
        if not brSub then
            return
        end

        local chickenLogic =
            brSub:GetResultProcessLogic("BattleResultChickenDrawLogic")

        if not chickenLogic then
            return
        end

        if chickenLogic.Reason ~= "win" then
            hasTakenScreenshot = false
            screenshotDelay = -1
            return
        end

        if chickenLogic.Reason == "win"
            and not hasTakenScreenshot
            and screenshotDelay == -1 then
            screenshotDelay = 20 -- 20 x 0.1s = 2 detik
        end

        if screenshotDelay > 0 then
            screenshotDelay = screenshotDelay - 1

            if screenshotDelay == 0 then
                hasTakenScreenshot = true
                M.TakeScreenshot()
            end
        end
    end)
end

-- ============================================================
-- FOV
-- ============================================================
function M.SetFOV(fovValue)
    pcall(function()
        local GameplayData = require("GameLua.GameCore.Data.GameplayData")
        local localPlayer = GameplayData.GetPlayerCharacter()
        if not slua.isValid(localPlayer) then return end
        local camera = localPlayer.ThirdPersonCameraComponent
        if slua.isValid(camera) then
            camera:SetFieldOfView(fovValue)
        end
    end)
end

-- ============================================================
-- MAGIC BULLET
-- ============================================================
function M.ResetHitbox()
    pcall(function()
        local allChars = Game:GetAllPlayerPawns()
        if allChars then
            for _, enemy in pairs(allChars) do
                if slua.isValid(enemy) and slua.isValid(enemy.Mesh) then
                    enemy.Mesh:RecreatePhysicsState()
                    enemy.Mesh:UpdateBounds()
                end
            end
        end
        _G._MBones = {}
    end)
end

function M.Magic()
    if not _G.ZenkoConfig.EnableMagic then
        if next(_G._MBones) ~= nil then M.ResetHitbox() end
        return
    end

    pcall(function()
        local GameplayData = require("GameLua.GameCore.Data.GameplayData")
        local char = GameplayData.GetPlayerCharacter()
        if not slua.isValid(char) then return end

        local allChars = Game:GetAllPlayerPawns()
        if not allChars then return end

        local magicScale = _G.ZenkoConfig.MagicLevel or CONST.MAGIC_SCALE_DEFAULT

        for _, enemy in pairs(allChars) do
            if slua.isValid(enemy) and enemy ~= char and enemy.TeamID ~= char.TeamID then
                local mesh = enemy.Mesh
                if not slua.isValid(mesh) then return end

                local physAsset = mesh.PhysicsAssetOverride
                if not slua.isValid(physAsset) and slua.isValid(mesh.SkeletalMesh) then
                    physAsset = mesh.SkeletalMesh.PhysicsAsset
                end
                if not slua.isValid(physAsset) then return end

                local assetName = tostring(physAsset.GetName and physAsset:GetName() or physAsset)
                if _G._MBones[assetName] then return end

                local setups = physAsset.SkeletalBodySetups
                if not setups then return end

                for i = 0, 60 do
                    pcall(function()
                        local bs = (type(setups.Get) == "function" and setups:Get(i)) or setups[i]
                        if not bs or not slua.isValid(bs) then return end

                        local boneName = tostring(bs.BoneName):lower()
                        if not string.find(boneName, "head") then return end

                        local ag = bs.AggGeom
                        if not ag then return end

                        pcall(function()
                            local box = ag.BoxElems
                            if box then
                                local elem = (type(box.Get) == "function" and box:Get(0)) or box[1]
                                if elem then
                                    elem.X, elem.Y, elem.Z = magicScale, magicScale, magicScale
                                    if type(box.Set) == "function" then box:Set(0, elem) else box[1] = elem end
                                end
                            end
                        end)

                        pcall(function()
                            local sphyl = ag.SphylElems
                            if sphyl then
                                local elem = (type(sphyl.Get) == "function" and sphyl:Get(0)) or sphyl[1]
                                if elem then
                                    if elem.Radius then elem.Radius = magicScale end
                                    if elem.Length then elem.Length = magicScale end
                                    if type(sphyl.Set) == "function" then sphyl:Set(0, elem) else sphyl[1] = elem end
                                end
                            end
                        end)

                        pcall(function()
                            local sphere = ag.SphereElems
                            if sphere then
                                local elem = (type(sphere.Get) == "function" and sphere:Get(0)) or sphere[1]
                                if elem and elem.Radius then
                                    elem.Radius = magicScale
                                    if type(sphere.Set) == "function" then sphere:Set(0, elem) else sphere[1] = elem end
                                end
                            end
                        end)
                    end)
                end

                pcall(function()
                    mesh:RecreatePhysicsState()
                    mesh:WakeAllRigidBodies()
                    mesh:UpdateBounds()
                end)
                _G._MBones[assetName] = true
            end
        end
    end)
end

-- ============================================================
-- ESP SYSTEM
-- ============================================================
function M.InitESPSystem()
    pcall(function()
        local GamePlayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools")
        local InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")

        local screenMarkConfig = GamePlayTools.GetCurrentConfig("ScreenMarkConfig")
        if screenMarkConfig then
            if screenMarkConfig[1006] then
                screenMarkConfig[1006].bBindBlocked = true
                screenMarkConfig[1006].bBindOutScreen = true
                screenMarkConfig[1006].MaxWidgetNum = 99
                screenMarkConfig[1006].MaxShowDistance = 6000000
                screenMarkConfig[1006].bScaleByDistance = false
                screenMarkConfig[1006].BindSocketName = "root"
                screenMarkConfig[1006].bUseLuaWorldSocketName = true
                screenMarkConfig[1006].WorldPositionOffset = _ENV.FVector(0, 0, -30)
            end

            if not screenMarkConfig[9999] then
                screenMarkConfig[9999] = {
                    UIPathName =
                    "/Game/Mod/EvoBase/BluePrints/UIBP/QuickSign/QuickSign_TipHitEnemy_UIBP_New.QuickSign_TipHitEnemy_UIBP_New_C",
                    MaxWidgetNum = 99,
                    MaxShowDistance = 6000000,
                    bBindOutScreen = true,
                    bBindBlocked = true,
                    bIsBindingActor = true,
                    BindSocketName = "head",
                    bUseLuaWorldSocketName = true,
                    WorldPositionOffset = _ENV.FVector(0, 0, 50),
                    bNeedPreLoad = true,
                    Priority = 2
                }
                if InGameMarkTools and InGameMarkTools.ScreenMarkManager then
                    pcall(function()
                        InGameMarkTools.ScreenMarkManager:OnInitMarkGroupData(9999)
                    end)
                end
            end
        end

        local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        local ClientHPBarSubSystem = SubsystemMgr:Get("ClientHPBarSubSystem")
        if ClientHPBarSubSystem then
            if ClientHPBarSubSystem.SetPauseCheck then
                ClientHPBarSubSystem:SetPauseCheck(true)
            end
            if ClientHPBarSubSystem.FocusActorCheckParam then
                ClientHPBarSubSystem.FocusActorCheckParam.CheckBlock = false
                ClientHPBarSubSystem.FocusActorCheckParam.CheckDistance = 1000000
            end
        end
    end)
end

function M.UpdateESP()
    pcall(function()
        local GameplayData = require("GameLua.GameCore.Data.GameplayData")
        local InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
        local localPlayer = GameplayData.GetPlayerCharacter()
        if not slua.isValid(localPlayer) then return end

        local allChars = Game:GetAllPlayerPawns()
        if not allChars then return end

        -- Cleanup invalid marks
        for cacheKey, cacheData in pairs(_G.AK_Active_Marks_Cache) do
            local shouldRemove = false
            if not slua.isValid(cacheData.actor) then
                shouldRemove = true
            else
                pcall(function()
                    local actor = cacheData.actor
                    if actor.bHidden or (actor.Mesh and actor.Mesh.bHidden) then
                        shouldRemove = true
                    elseif type(actor.IsDead) == "function" and actor:IsDead() then
                        shouldRemove = true
                    elseif actor.bIsDead == true or actor.bIsDeadFlag == true then
                        shouldRemove = true
                    end
                end)
            end

            if shouldRemove then
                pcall(function()
                    if InGameMarkTools and InGameMarkTools.ClientRemoveMapMark then
                        if cacheData.hpMark then InGameMarkTools.ClientRemoveMapMark(cacheData.hpMark) end
                        if cacheData.distMark then InGameMarkTools.ClientRemoveMapMark(cacheData.distMark) end
                    end
                end)
                _G.AK_Active_Marks_Cache[cacheKey] = nil
            end
        end

        -- Process each enemy
        for _, enemy in pairs(allChars) do
            if slua.isValid(enemy) and enemy ~= localPlayer and enemy.TeamID ~= localPlayer.TeamID then
                if M.IsEnemyValid(enemy) then
                    local isNearDeath = M.IsNearDeath(enemy)
                    if enemy.bHasAKNativeHPBar and enemy.AK_LastKnockState ~= isNearDeath then
                        M.RemoveEnemyMarks(enemy)
                    end
                    enemy.AK_LastKnockState = isNearDeath

                    if not enemy.bHasAKNativeHPBar and _G.ZenkoConfig.HPBar then
                        M.CreateEnemyMarks(enemy)
                    end

                    if _G.ZenkoConfig.ESPBox then
                        pcall(function()
                            if enemy.Replay_IsEnemyFrameUIExisted and not enemy:Replay_IsEnemyFrameUIExisted() then
                                enemy:Replay_CreateEnemyFrameUI(true, true)
                            end
                            if enemy.Replay_SetVisiableOfFrameUI then
                                enemy:Replay_SetVisiableOfFrameUI(true)
                            end
                        end)
                    else
                        pcall(function()
                            if enemy.Replay_SetVisiableOfFrameUI then
                                enemy:Replay_SetVisiableOfFrameUI(false)
                            end
                        end)
                    end
                else
                    M.RemoveEnemyMarks(enemy)
                end
                M.CheckAndDrawEnemyFOV(enemy)
            end
        end
    end)
end

function M.IsEnemyValid(enemy)
    local isDead = false
    pcall(function()
        if type(enemy.IsNearDeath) == "function" then
            if enemy:IsNearDeath() then return end
        elseif enemy.bIsNearDeath then
            return
        end

        if type(enemy.IsDead) == "function" then
            isDead = enemy:IsDead()
        elseif enemy.bIsDead ~= nil then
            isDead = enemy.bIsDead
        elseif enemy.bIsDeadFlag ~= nil then
            isDead = enemy.bIsDeadFlag
        end

        if enemy.bHidden or (enemy.Mesh and enemy.Mesh.bHidden) then
            isDead = true
        end

        if not isDead then
            local health = 100
            if type(enemy.GetHealth) == "function" then
                health = enemy:GetHealth()
            elseif enemy.Health ~= nil then
                health = enemy.Health
            end
            if health <= 0 then isDead = true end
        end
    end)
    return not isDead
end

function M.IsNearDeath(enemy)
    local result = false
    pcall(function()
        if type(enemy.IsNearDeath) == "function" then
            result = enemy:IsNearDeath()
        elseif enemy.bIsNearDeath ~= nil then
            result = enemy.bIsNearDeath
        end
    end)
    return result
end

function M.CreateEnemyMarks(enemy)
    pcall(function()
        local InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
        if InGameMarkTools and InGameMarkTools.ClientAddMapMark then
            enemy.NativeHPBarMark = InGameMarkTools.ClientAddMapMark(1006, _ENV.FVector(0, 0, 0), 0, "", 4, enemy)
            enemy.NativeDistMark = InGameMarkTools.ClientAddMapMark(9999, _ENV.FVector(0, 0, 0), 0, "", 4, enemy)
            enemy.bHasAKNativeHPBar = true
            _G.AK_Active_Marks_Cache[tostring(enemy)] = {
                actor = enemy,
                hpMark = enemy.NativeHPBarMark,
                distMark = enemy.NativeDistMark
            }
        end
    end)
end

function M.RemoveEnemyMarks(enemy)
    pcall(function()
        local InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
        if InGameMarkTools and InGameMarkTools.ClientRemoveMapMark then
            if enemy.NativeHPBarMark then InGameMarkTools.ClientRemoveMapMark(enemy.NativeHPBarMark) end
            if enemy.NativeDistMark then InGameMarkTools.ClientRemoveMapMark(enemy.NativeDistMark) end
        end
    end)
    enemy.NativeHPBarMark = nil
    enemy.NativeDistMark = nil
    enemy.bHasAKNativeHPBar = false
    _G.AK_Active_Marks_Cache[tostring(enemy)] = nil
end

function M.CheckAndDrawEnemyFOV(enemy)
    if not Client or not slua.isValid(enemy) then return false end

    local uCon = slua_GameFrontendHUD:GetPlayerController()
    if not slua.isValid(uCon) then return false end

    local me = uCon:GetPlayerCharacterSafety()
    if not slua.isValid(me) or enemy == me or enemy.TeamID == me.TeamID then return false end
    if not M.IsEnemyValid(enemy) then return false end

    local myPos = me:K2_GetActorLocation()
    local enemyPos = enemy:K2_GetActorLocation()
    local enemyRot = enemy:GetControlRotation()

    local dx, dy, dz = myPos.X - enemyPos.X, myPos.Y - enemyPos.Y, myPos.Z - enemyPos.Z
    local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
    if dist < 1 or dist > 50000 then return false end

    dx, dy, dz = dx / dist, dy / dist, dz / dist
    local yaw, pitch = math.rad(enemyRot.Yaw), math.rad(enemyRot.Pitch)
    local fx, fy, fz = math.cos(pitch) * math.cos(yaw), math.cos(pitch) * math.sin(yaw), math.sin(pitch)

    local dot = fx * dx + fy * dy + fz * dz
    local angle = math.deg(math.acos(math.max(-1, math.min(1, dot))))

    local enemyFOV = 90
    if enemy.PlayerCameraManager then
        enemyFOV = enemy.PlayerCameraManager:GetFOVAngle() or 90
    end
    if enemy.bIsGunADS then enemyFOV = enemyFOV * 0.75 end

    local canSee = uCon:LineOfSightTo(enemy, myPos)
    local isAiming = angle < (enemyFOV / 2) and canSee

    if not canSee and angle < 10 then isAiming = true end

    if isAiming then
        local HUD = uCon:GetHUD()
        if slua.isValid(HUD) and HUD.AddDebugText then
            local mesh = enemy.Mesh
            if slua.isValid(mesh) and mesh.GetSocketLocation then
                local headPos = mesh:GetSocketLocation("head")
                if headPos then
                    local distMeters = dist / 100
                    local step = math.floor(distMeters / 25) * 25
                    local t = math.max(0, math.min(1, step / 350))
                    local zOffset = 125 + 450 * t
                    local fontSize = 1.0 - (1.0 - 0.5) * math.min(1, (distMeters / 500) ^ 2)

                    local text = "AIMING YOU"
                    local color = { R = 255, G = 0, B = 0, A = 255 }
                    if not canSee and angle < 10 then
                        color = { R = 255, G = 0, B = 255, A = 255 }
                        text = "AIMING YOU (WALL)"
                    end

                    HUD:AddDebugText(text, enemy, 0.2, { X = 0, Y = 0, Z = zOffset }, { X = 0, Y = 0, Z = zOffset },
                        color, true, false, true, nil, fontSize, true)
                    return true
                end
            end
        end
    end
    return false
end

-- ============================================================
-- SKIN APPLICATION
-- ============================================================
local function DownloadODPAKFile(itemID)
    if not itemID then return end
    pcall(function()
        local pufferManager = require("client.slua.logic.download.puffer.puffer_manager")
        local pufferConstants = require("client.slua.logic.download.puffer_const")
        local state = pufferManager.GetState(pufferConstants.ENUM_DownloadType.ODPAK, { itemID })
        if state ~= pufferConstants.ENUM_DownloadState.Done then
            pufferManager.Download(pufferConstants.ENUM_DownloadType.ODPAK, { itemID })
        end
    end)
end

function _G.get_group_id(itemId)
    if not ItemUpgradeSystem or not itemId then return nil end
    local result = nil
    pcall(function()
        local cfg = ItemUpgradeSystem:GetUpgradeCfg(itemId)
        if cfg and cfg.GroupID then result = cfg.GroupID end
    end)
    return result
end

function _G.InitParts(groupId, itemId)
    if not itemId then return _G.g_parts end
    if not _G.g_parts[itemId] then _G.g_parts[itemId] = {} end

    pcall(function()
        local realGroupId = groupId or _G.get_group_id(itemId)
        if ItemUpgradeSystem and ItemUpgradeSystem.IsWeaponIsRefit and ItemUpgradeSystem:IsWeaponIsRefit(itemId) then
            realGroupId = ItemUpgradeSystem:GetNormalGroupID(realGroupId)
        end

        local CDataTable = _G.CDataTable or require("client.slua.config.ClientConfig.data_mgr")
        local cfg = CDataTable.GetTableByFilter("ItemUpgradeUnLockConfig", "GroupID", realGroupId)
        if cfg then
            for _, info in pairs(cfg) do
                local partId = info.PartId
                if ItemUpgradeSystem and ItemUpgradeSystem.IsWeaponIsRefit and ItemUpgradeSystem:IsWeaponIsRefit(itemId) then
                    local switched = ItemUpgradeSystem:PartIDSwitch(partId, true)
                    if switched and switched ~= partId then partId = switched end
                end
                local item = CDataTable.GetTableData("Item", partId)
                if item then _G.g_parts[itemId][item.ItemName] = partId end
            end
        end
    end)
    return _G.g_parts
end

function _G.GetSlotFromSkinID(skinid, stock)
    if not skinid or not stock then return 0 end

    local attachmentTypeMap = {
        [1] = { 291004, 291102, 291001, 291006, 291005, 291002, 293003, 293004, 293009, 293007, 293005, 293006, 295001, 295002, 291007, 291003, 292002, 292003, 291011, 291008 },
        [2] = { 205005, 205102, 205007, 205009, 205006 },
        [3] = { 203008, 203009, 203006, 203022, 203010 }
    }

    local targetIDs = attachmentTypeMap[stock]
    if not targetIDs then return 0 end

    local UAvatarUtils = import("AvatarUtils")
    if not UAvatarUtils then return 0 end

    local defaultAttachments = UAvatarUtils.GetWeaponAvatarDefaultAttachmentSkin(skinid, {}, false) or {}
    for _, targetID in ipairs(targetIDs) do
        for attachID, skinID in pairs(defaultAttachments) do
            if attachID == targetID then return skinID end
        end
    end
    return 0
end

function M.GetAttachmentNameFromSkinId(itemid, avatarid)
    if not itemid or itemid < 10000000 then return nil end
    local skinMap = _G.SkinAttachmentMap and _G.SkinAttachmentMap[avatarid]
    if not skinMap then return nil end

    for name, id in pairs(skinMap) do
        if id == itemid then return name end
    end
    return nil
end

local function GetAttachFromMap(avatarid, attachName)
    if not avatarid or not attachName then return nil end

    local skinMap = _G.SkinAttachmentMap and _G.SkinAttachmentMap[avatarid]
    if skinMap and skinMap[attachName] then
        local id = skinMap[attachName]
        if id and id ~= 0 then
            if not _G.skinIdCache2[id] then
                pcall(DownloadODPAKFile, id)
                _G.skinIdCache2[id] = true
            end
            return id
        end
    end
    return nil
end

-- Attachment handler functions
function _G.get_muzzleid(current_id, avatarid)
    local initial_id = current_id
    _G.InitParts(_G.get_group_id(avatarid), avatarid)

    local muzzle_type = nil
    for _, id in ipairs(_G.muzzles.id_flash_hider) do
        if current_id == id then
            muzzle_type = "Flash Hider"
            break
        end
    end
    if not muzzle_type then
        for _, id in ipairs(_G.muzzles.id_compensator) do
            if current_id == id then
                muzzle_type = "Compensator"
                break
            end
        end
    end
    if not muzzle_type then
        for _, id in ipairs(_G.muzzles.id_suppressor) do
            if current_id == id then
                muzzle_type = "Suppressor"
                break
            end
        end
    end

    if muzzle_type then
        local fromMap = GetAttachFromMap(avatarid, muzzle_type)
        if fromMap then
            current_id = fromMap
        elseif _G.g_parts[avatarid] and _G.g_parts[avatarid][muzzle_type] then
            current_id = _G.g_parts[avatarid][muzzle_type]
        end
    end

    return current_id, initial_id ~= current_id
end

function _G.get_forgripid(current_id, avatarid)
    local initial_id = current_id
    _G.InitParts(_G.get_group_id(avatarid), avatarid)

    local grip_name = nil
    if current_id == _G.foregrips.id_Angledforegrip then
        grip_name = "Angled Foregrip"
    elseif current_id == _G.foregrips.id_thumb_grip then
        grip_name = "Thumb Grip"
    elseif current_id == _G.foregrips.id_vertical_grip then
        grip_name = "Vertical Foregrip"
    elseif current_id == _G.foregrips.id_light_grip then
        grip_name = "Light Grip"
    elseif current_id == _G.foregrips.id_half_grip then
        grip_name = "Half Grip"
    elseif current_id == _G.foregrips.id_ergonomic_grip then
        grip_name = "Ergonomic Grip"
    elseif current_id == _G.foregrips.id_laser_sight then
        grip_name = "Laser Sight"
    end

    if grip_name then
        local fromMap = GetAttachFromMap(avatarid, grip_name)
        if fromMap then
            current_id = fromMap
        elseif _G.g_parts[avatarid] then
            current_id = _G.g_parts[avatarid][grip_name] or current_id
        end
    end

    return current_id, initial_id ~= current_id
end

function _G.get_magazinesid(current_id, avatarid)
    local initial_id = current_id
    _G.InitParts(_G.get_group_id(avatarid), avatarid)

    local magazine_type = nil
    for _, id in ipairs(_G.magazines.id_expanded_mag) do
        if current_id == id then
            magazine_type = "Extended Mag"
            break
        end
    end
    if not magazine_type then
        for _, id in ipairs(_G.magazines.id_quick_mag) do
            if current_id == id then
                magazine_type = "Quickdraw Mag"
                break
            end
        end
    end
    if not magazine_type then
        for _, id in ipairs(_G.magazines.id_expanded_quick_mag) do
            if current_id == id then
                magazine_type = "Extended Quickdraw Mag"
                break
            end
        end
    end

    if magazine_type then
        local fromMap = GetAttachFromMap(avatarid, magazine_type)
        if fromMap then
            current_id = fromMap
        elseif _G.g_parts[avatarid] and _G.g_parts[avatarid][magazine_type] then
            current_id = _G.g_parts[avatarid][magazine_type]
        end
    else
        current_id = _G.GetSlotFromSkinID(avatarid, 1) or current_id
    end

    return current_id, initial_id ~= current_id
end

function _G.get_scopeid(current_id, avatarid)
    local initial_id = current_id
    _G.InitParts(_G.get_group_id(avatarid), avatarid)

    local scope_name = nil
    if current_id == _G.scopes.id_reddot then
        scope_name = "Red Dot Sight"
    elseif current_id == _G.scopes.id_holo then
        scope_name = "Holographic Sight"
    elseif current_id == _G.scopes.id_2x then
        scope_name = "2x Scope"
    elseif current_id == _G.scopes.id_3x then
        scope_name = "3x Scope"
    elseif current_id == _G.scopes.id_4x then
        scope_name = "4x Scope"
    elseif current_id == _G.scopes.id_6x then
        scope_name = "6x Scope"
    elseif current_id == _G.scopes.id_8x then
        scope_name = "8x Scope"
    end

    if scope_name then
        local fromMap = GetAttachFromMap(avatarid, scope_name)
        if fromMap then
            current_id = fromMap
        elseif _G.g_parts[avatarid] then
            current_id = _G.g_parts[avatarid][scope_name] or current_id
        end
    else
        current_id = _G.GetSlotFromSkinID(avatarid, 3) or current_id
    end

    return current_id, initial_id ~= current_id
end

function _G.get_stockid(current_id, avatarid)
    local initial_id = current_id
    _G.InitParts(_G.get_group_id(avatarid), avatarid)

    local stock_name = nil
    if current_id == _G.stock.id_microStock then
        stock_name = "Stock"
    elseif current_id == _G.stock.id_tactical then
        stock_name = "Tactical Stock"
    elseif current_id == _G.stock.id_bulletloop then
        stock_name = "Bullet Loop"
    elseif current_id == _G.stock.id_CheekPad then
        stock_name = "Cheek Pad"
    end

    if stock_name then
        local fromMap = GetAttachFromMap(avatarid, stock_name)
        if fromMap then
            current_id = fromMap
        elseif _G.g_parts[avatarid] then
            current_id = _G.g_parts[avatarid][stock_name] or current_id
        end
    else
        current_id = _G.GetSlotFromSkinID(avatarid, 2) or current_id
    end

    return current_id, initial_id ~= current_id
end

local function GetPartIndex(AttachIdx)
    if AttachIdx == 2 then
        return 1 -- Magazine
    elseif AttachIdx == 3 then
        return 3 -- Stock
    elseif AttachIdx == 4 then
        return 2 -- Scope
    end
    return nil
end

function _G.GetDefaultSkinPartID(avatarid, part)
    local avatar = tostring(avatarid)
    local weapon = avatar:sub(-6, -4)
    local skin = avatar:sub(-3, -1)
    return tonumber("101" .. weapon .. skin .. part)
end

function M.ApplySkinAttachments(CurWeapon, oldSkin, newSkin)
    local array = CurWeapon.synData
    if not array or not slua.isValid(array) then return false end

    local changed = false

    for AttachIdx = 0, 4 do
        local Data = array:Get(AttachIdx)
        if not Data then break end

        local itemid = slua.IndexReference(Data, "defineID").TypeSpecificID
        if not itemid or itemid == 0 then goto continue end

        local newId = nil

        -- 1. Name-based mapping
        local attachName = M.GetAttachmentNameFromSkinId(itemid, oldSkin)
        if attachName then
            newId = M.GetSkinSpecificId(newSkin, attachName)
        end

        -- 2. Default part handling
        if not newId then
            local partIndex = GetPartIndex(AttachIdx)
            if partIndex then
                local defaultOld = _G.GetDefaultSkinPartID(oldSkin, partIndex)
                local defaultNew = _G.GetDefaultSkinPartID(newSkin, partIndex)
                if itemid == defaultOld then
                    newId = defaultNew
                end
            end
        end

        -- 3. Fallback attachment handlers
        if not newId and itemid < 10000000 then
            if AttachIdx == 0 then
                newId, _ = _G.get_muzzleid(itemid, newSkin)
            elseif AttachIdx == 1 then
                newId, _ = _G.get_forgripid(itemid, newSkin)
            elseif AttachIdx == 2 then
                newId, _ = _G.get_magazinesid(itemid, newSkin)
            elseif AttachIdx == 3 then
                newId, _ = _G.get_stockid(itemid, newSkin)
            elseif AttachIdx == 4 then
                newId, _ = _G.get_scopeid(itemid, newSkin)
            end
        end

        -- Apply change
        if newId and newId ~= 0 and newId ~= itemid then
            Data.defineID.TypeSpecificID = newId
            array:Set(AttachIdx, Data)
            changed = true
        end

        ::continue::
    end

    if changed and CurWeapon.OnRep_synData then
        pcall(function() CurWeapon:OnRep_synData() end)
    end

    return changed
end

M.SkinLoadedCache = {}

function M.ApplyLocalPlayerSkins()
    local GameplayData = require("GameLua.GameCore.Data.GameplayData")
    local self = GameplayData.GetPlayerCharacter()
    if not slua.isValid(self) then return end

    pcall(function()
        -- Apply outfit, bag, helmet
        if _G.ZenkoConfig.EnableOutfit then
            local ac = self:getAvatarComponent2()
            if slua.isValid(ac) and ac.NetAvatarData then
                local applyData = ac.NetAvatarData.SlotSyncData
                if slua.isValid(applyData) then
                    local bu = import("BackpackUtils")

                    for i = 0, applyData:Num() - 1 do
                        local eq = applyData:Get(i)
                        if eq then
                            local target = 0

                            if eq.SlotID == 5 and _G.OutfitMap.Suit then
                                target = _G.OutfitMap.Suit
                            elseif eq.SlotID == 8 and _G.OutfitMap.Bag and _G.OutfitMap.Bag ~= 501001 then
                                local level = bu and bu.GetEquipmentBagLevel(eq.AdditionalItemID) or 1
                                target = _G.OutfitMap.Bag + (level - 1) * 1000
                            elseif eq.SlotID == 9 and _G.OutfitMap.Helmet and _G.OutfitMap.Helmet ~= 502001 then
                                local level = bu and bu.GetEquipmentHelmetLevel(eq.AdditionalItemID) or 1
                                target = _G.OutfitMap.Helmet + (level - 1) * 1000
                            end

                            if target ~= 0 and eq.ItemId ~= target then
                                if not M.SkinLoadedCache[target] then
                                    pcall(DownloadODPAKFile, target)
                                    M.SkinLoadedCache[target] = true
                                end
                                eq.ItemId = target
                                applyData:Set(i, eq)
                                ac:OnRep_BodySlotStateChanged()
                            end
                        end
                    end
                end
            end
        end

        -- Apply weapon skins
        if _G.ZenkoConfig.EnableWeaponSkin then
            local wm = self.GetWeaponManager and self:GetWeaponManager() or self.WeaponManagerComponent
            if not slua.isValid(wm) then return end

            for i = 1, 3 do
                local wpn = wm:GetInventoryWeaponByPropSlot(i)
                if not slua.isValid(wpn) then goto continue_slot end
                if not slua.isValid(wpn.synData) then goto continue_slot end

                local wID = wpn:GetWeaponID()
                local target = _G.ActiveSkins[wID]
                _G.ActiveWeaponSkinCache[wID] = target

                if not target or target == wID then goto continue_slot end

                if not M.SkinLoadedCache[target] then
                    pcall(DownloadODPAKFile, target)
                    M.SkinLoadedCache[target] = true
                end

                local d = wpn.synData:Get(CONST.GUN_MASTER_SLOT)
                if not d or not d.defineID then goto continue_slot end

                local currentSkin = d.defineID.TypeSpecificID
                local oldSkin = currentSkin
                local needsSkinApply = (currentSkin ~= target)

                local needsAttachUpdate = false
                if needsSkinApply then
                    needsAttachUpdate = true
                else
                    for idx = 0, 4 do
                        local ad = wpn.synData:Get(idx)
                        if ad and ad.defineID then
                            local aid = ad.defineID.TypeSpecificID
                            if aid and aid > 0 then
                                local attachName = M.GetAttachmentNameFromSkinId(aid, oldSkin)
                                if attachName then
                                    local expected = M.GetSkinSpecificId(target, attachName)
                                    if expected and expected ~= aid then
                                        needsAttachUpdate = true
                                        break
                                    end
                                elseif aid < 10000000 then
                                    needsAttachUpdate = true
                                    break
                                end
                            end
                        end
                    end
                end

                if needsSkinApply then
                    local wa = wpn.WeaponAvatarComponent_BP or wpn.WeaponAvatarComponent
                    if slua.isValid(wa) then
                        wa.CachedLoadedID = 0
                    end

                    d.defineID.TypeSpecificID = target
                    d.operationType = 0
                    wpn.synData:Set(CONST.GUN_MASTER_SLOT, d)

                    if wpn.OnRep_synData then
                        wpn:OnRep_synData()
                    end

                    if slua.isValid(wa) then
                        wa.WeaponSkinId = target
                        pcall(function()
                            wa:OnWeaponAvatarLoadedLua(CONST.GUN_MASTER_SLOT, d.defineID)
                        end)

                        if wa.CachedLoadedID ~= target then
                            wa.CachedLoadedID = target
                            if wa.EffectManager then
                                wa.EffectManager:Clear()
                                local h = wa:GetEquippedHandle(CONST.GUN_MASTER_SLOT)
                                wa.EffectManager:Init(h, wa.Object)
                            end
                        end
                    end
                end

                if needsAttachUpdate or needsSkinApply then
                    local attachChanged = M.ApplySkinAttachments(wpn, oldSkin, target)
                    if (needsSkinApply or attachChanged) and wpn.DelayHandleAvatarMeshChanged then
                        pcall(function() wpn:DelayHandleAvatarMeshChanged() end)
                    end
                end

                ::continue_slot::
            end
        end

        -- Apply vehicle skins
        if _G.ZenkoConfig.EnableVehicleSkin then
            local CV = self.CurrentVehicle
            if slua.isValid(CV) then
                local VA = CV.VehicleAvatar
                if slua.isValid(VA) then
                    local defId = tostring(VA:GetDefaultAvatarID() or "")

                    for baseId, skins in pairs(M.VehicleSkinList or {}) do
                        if defId:find(tostring(baseId)) then
                            local skinId = _G.ActiveVehicleSkins[baseId] or skins[1]

                            if _G.CurrentEquipVehicleID ~= skinId then
                                if not M.SkinLoadedCache[skinId] then
                                    pcall(DownloadODPAKFile, skinId)
                                    M.SkinLoadedCache[skinId] = true
                                end

                                VA._modLastSkinId = VA.ClientUsedAvatarID or VA:GetDefaultAvatarID() or 0
                                VA.curSwitchEffectId = 7303001
                                VA:ChangeItemAvatar(skinId, true)
                                _G.CurrentEquipVehicleID = skinId
                            end
                            break
                        end
                    end
                end
            end
        end
    end)
end

-- ============================================================
-- KILL MESSAGE HOOK
-- ============================================================
function M.HookKillMessage()
    pcall(function()
        local SKillInfo = require("GameLua.Mod.BaseMod.Client.KillInfoTips.KillInfo")
        if not SKillInfo or not SKillInfo.__inner_impl then return end

        local O_FileItem = SKillInfo.__inner_impl.FileItem
        if not O_FileItem then return end

        SKillInfo.__inner_impl.FileItem = function(self, DamageRecordData)
            if not self or not DamageRecordData then
                return O_FileItem(self, DamageRecordData)
            end

            local uCon = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
            local uCharacter = uCon and uCon:GetPlayerCharacterSafety()

            if uCharacter and slua.isValid(uCharacter) and DamageRecordData.Causer == uCharacter:GetPlayerNameSafety() then
                local currWeapon = uCharacter:GetCurrentWeapon()
                if currWeapon and slua.isValid(currWeapon) then
                    local itemDef = currWeapon:GetItemDefineID()
                    local weaponDefineID = itemDef and itemDef.TypeSpecificID or 0

                    if weaponDefineID ~= 0 then
                        local ExpandData = slua.LuaArchiverDecode(LuaStateWrapper, DamageRecordData.ExpandDataContent) or
                            {}
                        local finalSkin = _G.ActiveWeaponSkinCache[weaponDefineID]
                        DamageRecordData.CauserWeaponAvatarID = finalSkin
                        DamageRecordData.ExpandDataContent = slua.LuaArchiverEncode(LuaStateWrapper, ExpandData)
                    end
                end
            end

            return O_FileItem(self, DamageRecordData)
        end

        M.WriteLog("[KillMessage] Hook applied")
    end)
end

-- ============================================================
-- VEHICLE EFFECT HOOK
-- ============================================================
function M.HookVehicleEffect()
    pcall(function()
        local VehicleAvatarComponent = require("GameLua.GameCore.Module.Vehicle.Component.VehicleAvatarComponent")
        if not (VehicleAvatarComponent and VehicleAvatarComponent.__inner_impl) then return end

        VehicleAvatarComponent.__inner_impl.CheckCanPlaySkinSwitchEffect = function(_, _, _)
            return true
        end

        VehicleAvatarComponent.__inner_impl.ShowVehicleSwitchEffect = function(self)
            if not self.curSwitchEffectId or self.curSwitchEffectId <= 0 then
                self.curSwitchEffectId = 7303001
            end

            local vehicleActor = self:GetOwner()
            if not slua.isValid(vehicleActor) then return false end

            local currentAvatarID = vehicleActor.ClientUsedAvatarID or 0
            local lastAvatarID = self._modLastSkinId or self.lastEquipedAvatarId or
                (vehicleActor.GetDefaultAvatarID and vehicleActor:GetDefaultAvatarID()) or 0

            self._modLastSkinId = nil

            if lastAvatarID == currentAvatarID then return false end

            self.lastEquipedAvatarId = lastAvatarID

            if self.uSwitchEffectActor then
                self:StopSkinSwitchEffect()
                self.uSwitchEffectActor:K2_DestroyActor()
                self.uSwitchEffectActor = nil
            end

            local world = slua_GameFrontendHUD:GetWorld()
            if not world then return false end

            local VehiclePlateLicenseUtil = require(
                "GameLua.Activity.Commercialize.GamePlay.Vehicle.VehiclePlateLicenseUtil")
            local SkinSwitchEffectActorPath = VehiclePlateLicenseUtil.GetSwitchEffectActorPath()
            local BP_DissolveVehicleClass = import(SkinSwitchEffectActorPath)

            self.uSwitchEffectActor = world:SpawnActor(BP_DissolveVehicleClass, nil, nil, nil)
            if not slua.isValid(self.uSwitchEffectActor) then
                self.uSwitchEffectActor = nil
                return false
            end

            self.uSwitchEffectActor:K2_AttachToActor(vehicleActor, "None", 1, 1, 1, false)
            self.uSwitchEffectActor:K2_SetActorRelativeLocation(FVector(0, 0, 0), false, nil, false)
            self.uSwitchEffectActor:K2_SetActorRelativeRotation(FRotator(0, 0, 0), false, nil, false)

            self:ChangeFakeSwitchVehicleAvatar(self.uSwitchEffectActor.Mesh, lastAvatarID)
            self.uSwitchEffectActor:SetAnimInsAndAnimState(self.uOldVehicleMeshAnimClass, vehicleActor)
            self.uSwitchEffectActor:StartVehicleSwitchEffect(
                vehicleActor, self.curSwitchEffectId, lastAvatarID, currentAvatarID, self:IsLobbyActor()
            )

            self.uOldVehicleMeshAnimClass = nil
            self.lastEquipedAvatarId = currentAvatarID

            return true
        end

        VehicleAvatarComponent.__inner_impl.ResetAnimationState = function(self)
            if self.uSwitchEffectActor then
                self:StopSkinSwitchEffect()
                self.uSwitchEffectActor:K2_DestroyActor()
                self.uSwitchEffectActor = nil
            end
            self.curSwitchEffectId = 7303001
        end

        local O_ReceiveBeginPlay = VehicleAvatarComponent.__inner_impl.ReceiveBeginPlay
        VehicleAvatarComponent.__inner_impl.ReceiveBeginPlay = function(self)
            O_ReceiveBeginPlay(self)
            self:ResetAnimationState()
        end
    end)
end

-- ============================================================
-- START SYSTEMS
-- ============================================================
function M.StartAdvancedSystems(self)
    if not Client or not self then return end

    local GameplayData = require("GameLua.GameCore.Data.GameplayData")
    M.InitESPSystem()

    self:AddGameTimer(0.1, true, function()
        if not slua.isValid(self.Object) then return end
        local localPlayer = GameplayData.GetPlayerCharacter()
        if not slua.isValid(localPlayer) or self.Object ~= localPlayer then return end

        M.UpdateESP()

        if _G.ZenkoConfig.EnableIpad then
            M.SetFOV(_G.ZenkoConfig.FOVValue or CONST.DEFAULT_FOV)
        else
            M.SetFOV(CONST.DEFAULT_FOV)
        end

        if _G.ZenkoConfig.EnableMagic then
            M.Magic()
        else
            _G._MBones = {}
        end

        M.CheckGameEnd()
        M.ApplyLocalPlayerSkins()
    end)
end

-- ============================================================
-- INITIALIZATION
-- ============================================================
function M.InitItemUpgradeSystem()
    M.WriteLog("=== InitItemUpgradeSystem ===")

    local ok, err = pcall(function()
        local ModuleManager = require("client.module_framework.ModuleManager")
        local cfg = ModuleManager.CommonModuleConfig.ItemUpgradeModule

        if not cfg then
            M.WriteLog("ItemUpgradeModule config NOT FOUND")
            return
        end

        ItemUpgradeSystem = ModuleManager.GetModule(cfg)

        if ItemUpgradeSystem then
            M.WriteLog("Init success")
        else
            M.WriteLog("GetModule returned nil")
        end
    end)

    if not ok then
        M.WriteLog("InitItemUpgradeSystem ERROR : " .. tostring(err))
    end
end

-- ============================================================
-- MAIN RUN
-- ============================================================
function M.Bypass()
    local path = "/storage/emulated/0/Android/data/com.tencent.ig/files/ZENKO/1.lua"

    local chunk, err = loadfile(path)
    if not chunk then
        return
    end

    local ok, mod = pcall(chunk)
    if not ok then
        return
    end

    if mod and type(mod.BaseHook) == "function" then
        pcall(mod.BaseHook)
    end
end

function M.Run(beginPlaySelf)
    -- 1. Sistem global jalan dulu (tanpa peduli localPlayer)
    M.Bypass()

    local skinLoaded = M.LoadSkinData()
    M.LoadVehicleSkins()

    if skinLoaded then
        M.BuildSkinMaps()
        M.WriteLog("[SkinLoader] Dynamic skin system initialized")
    else
        M.WriteLog("[SkinLoader] Using fallback static skin data")
    end

    M.InitModMenuTab()
    M.InitItemUpgradeSystem()

    -- 2. Baru di sini ambil & validasi localPlayer (karena baru butuh)
    if beginPlaySelf then
        local GameplayData = require("GameLua.GameCore.Data.GameplayData")
        local localPlayer = GameplayData.GetPlayerCharacter()

        if slua.isValid(localPlayer) and beginPlaySelf.Object == localPlayer then
            M.TryShowWelcome()
            M.StartAdvancedSystems(beginPlaySelf)
        else
            M.WriteLog("[SkinLoader] Skipped player systems: invalid localPlayer")
        end
    end

    -- 3. Hook global
    if _G.ZenkoConfig.EnableWeaponSkin then
        M.HookKillMessage()
    end

    if _G.ZenkoConfig.EnableVehicleSkin then
        M.HookVehicleEffect()
    end
end

return M
