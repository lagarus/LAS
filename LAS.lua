-- Lagarus's Admin System v0.3 for tes3mp 0.8 created by lagarus
-- QIP: protection for quest items. Item dont delete for everyone. If item placed by player, after cell reset it will be placed when server start.
-- Trader Mood: disable pesruation with traders. Add charm effect with customable parametres to traders.
-- Object Locker: on server start changes lock level for objects.
--[[
Add the following to customScripts.lua
	las = require("custom.las")
--]] 
--need for Locker
contentFixer = require("contentFixer")

local las = {}

local object_list = {}

local trader_list = {}
local trader_data = {}
local trader_tss = {}

local locker_list = {}

-- текущий режим доступа: модеры и выше. ЗЫ потом переписать и дополнить нормальным описанием
local LAS_stuffRank = 0

local guiID = {}
guiID.adminMain = 34033000
guiID.setQuestItemProtector = 34033001
guiID.QIPList = 34033002
guiID.QIPmain = 34033003

guiID.LOCKERmain = 34033004
guiID.LOCKERList = 34033005

guiID.TraderMoodMain = 34033006
guiID.TraderMoodList = 34033007

--Сохранение данных QIP
local function Save()
    tes3mp.LogAppend(enumerations.log.INFO, "[LAS] Quest items list saved")
    jsonInterface.save("custom/LAS_quest_items.json", object_list)
end
--Загрузка данных QIP
local function Load()
    tes3mp.LogAppend(enumerations.log.INFO, "[LAS] Quest items list loaded")
    object_list = jsonInterface.load("custom/LAS_quest_items.json")
end
--Принудительная загрузка данных QIP
local function ReLoad(pid)
    Players[pid]:Message("[LAS] Quest items list Reloaded.\n")
    tes3mp.LogAppend(enumerations.log.INFO, "[LAS] Quest items list Reloaded by " .. logicHandler.GetChatName(pid))
    object_list = jsonInterface.load("custom/LAS_quest_items.json")
    LASQIPmainMenu(eventStatus,pid)
end
--Режим защиты квестовых предметов QIP
local function QuestItemProtectMode(pid)
    if Players[pid].data.settings.staffRank > LAS_stuffRank then
        if las[pid] == nil then
            las[pid] = {}
            Players[pid]:Message("[LAS] Quest items ProtectMode.\n")
            las[pid].mode = true
        else
            if las[pid].mode == nil then
                Players[pid]:Message("[LAS] Quest items ProtectMode.\n")
                las[pid].mode = true
            else
                if las[pid].mode == true then
                    Players[pid]:Message("[LAS] Quest items ProtectMode DEACTIVATED.\n")
                    las[pid].mode = false
                else
                    Players[pid]:Message("[LAS] Quest items ProtectMode.\n")
                    las[pid].mode = true
                end
            end
        end
    end
    LASQIPmainMenu(eventStatus,pid)
end
--Показать главное меню LAS
function LASmainMenu(eventStatus,pid)
	local message = color.Orange .. "LAS menu"
	tes3mp.CustomMessageBox(pid, guiID.adminMain, message, "Quest Item Protection;Trader Mood;Object Locker;Exit")
end
--Конвертер для вызовa функции показа главного меню LAS
function LASmainMenuC(pid,cmd)
    if Players[pid].data.settings.staffRank > LAS_stuffRank then
	    LASmainMenu(eventStatus,pid)
    end
end
--Главное меню защиты квестовых предметов QIP
function LASQIPmainMenu(eventStatus,pid)
	local message = color.Orange .. "LAS Quest Item Protection menu"
    local choice = "Protection mode"
    local QIPstate = "[off]"
    if las[pid] ~= nil then
        if las[pid].mode ~= nil then
            if las[pid].mode == true then
                QIPstate = "[on]"
            end
        end
    end
    choice = choice .. QIPstate .. ";Item List;Reload Item List;Back"
	tes3mp.CustomMessageBox(pid, guiID.QIPmain, message, choice)
end
--Список защищенных квестовых предметов QIP
function LASquestItemList(eventStatus,pid)
	local message = color.Orange .. "Protected Items List"
	local list = "* ЗАКРЫТЬ *\n"
	
	for ii, obj in pairs(object_list) do
        local ids = obj.refId .. " - " .. obj.uniqueIndex
		list = list .. ids .. "\n"
	end
	
    list = list .. "\n"
	return tes3mp.ListBox(pid, guiID.QIPList, message, list)
end

--Сохранение данных TraderMood
local function SaveTM()
    tes3mp.LogAppend(enumerations.log.INFO, "[LAS] Trader list saved")
    jsonInterface.save("custom/LAS_TraderMood_traders.json", trader_list)
    tes3mp.LogAppend(enumerations.log.INFO, "[LAS] TraderMood config saved")
    jsonInterface.save("custom/LAS_TraderMood_config.json", trader_data)
end
--Загрузка данных TraderMood
local function LoadTM()
    tes3mp.LogAppend(enumerations.log.INFO, "[LAS] TraderMood config loaded")
    trader_data = jsonInterface.load("custom/LAS_TraderMood_config.json")
    tes3mp.LogAppend(enumerations.log.INFO, "[LAS] TraderMood service spell loaded")
    trader_tss = jsonInterface.load("custom/LAS_TSS.json")
    tes3mp.LogAppend(enumerations.log.INFO, "[LAS] Trader list loaded")
    trader_list = jsonInterface.load("custom/LAS_TraderMood_traders.json")

    --если данные пустые - использовать стандартные настройки
    if trader_data == nil then trader_data = {} end
    if trader_list == nil then trader_list = {} end
    if trader_data.attitude == nil then
        trader_data.attitude = 0
    end
    if trader_data.persuationLock == nil then
        trader_data.persuationLock = false
    end
end

--Главное меню TraderMood
function LASTraderMoodMainMenu(eventStatus,pid)
	local message = color.Orange .. "LAS Trader Mood menu"
    local choice = "Mark mode"
    local TMstate = "[off]"
    if las[pid] ~= nil then
        if las[pid].modeTM ~= nil then
            if las[pid].modeTM == true then
                TMstate = "[on]"
            end
        end
    end
    choice = choice .. TMstate .. ";Trader List;Lock Persuation[" .. tostring(trader_data.persuationLock) .. "];+5 attitude;Current(" ..
    tostring(trader_data.attitude) .. ");-5 attitude;Back"
	tes3mp.CustomMessageBox(pid, guiID.TraderMoodMain, message, choice)
end

--Список торговцев TraderMood
function LASTraderMoodTradersList(eventStatus,pid)
	local message = color.Orange .. "Traders List"
	local list = "* ЗАКРЫТЬ *\n"
	
	for ii, obj in pairs(trader_list) do
        local ids = obj.refId
		list = list .. ids .. "\n"
	end
	
    list = list .. "\n"
	return tes3mp.ListBox(pid, guiID.TraderMoodList, message, list)
end

--Режим пометки торговцев TraderMood
local function TraderMoodMarkMode(pid)
    if Players[pid].data.settings.staffRank > LAS_stuffRank then
        if las[pid] == nil then
            las[pid] = {}
            Players[pid]:Message("[LAS] TM mark mode on.\n")
            las[pid].modeTM = true
        else
            if las[pid].modeTM == nil then
                Players[pid]:Message("[LAS] TM mark mode on.\n")
                las[pid].modeTM = true
            else
                if las[pid].modeTM == true then
                    Players[pid]:Message("[LAS] TM mark mode off.\n")
                    las[pid].modeTM = false
                else
                    Players[pid]:Message("[LAS] TM mark mode on.\n")
                    las[pid].modeTM = true
                end
            end
        end
    end
    LASTraderMoodMainMenu(eventStatus,pid)
end


--Сохранение данных Locker
local function SaveL()
    tes3mp.LogAppend(enumerations.log.INFO, "[LAS] Object Locker list saved")
    jsonInterface.save("custom/LAS_locker_data.json", locker_list)
end
--Загрузка данных Locker
local function LoadL()
    tes3mp.LogAppend(enumerations.log.INFO, "[LAS] Object Locker list loaded")
    locker_list = jsonInterface.load("custom/LAS_locker_data.json")
end


--Главное меню Locker
function LASlockerMenu(eventStatus,pid)
	local message = color.Orange .. "LAS Object Locker menu\n" .. color.Default
    local choice = ""

    local polymorph_menu = true
    if las[pid] ~= nil then
        if las[pid].locker_object ~= nil then
            polymorph_menu = false
            message = message .. "Current object:\n" .. las[pid].locker_object.refId .. "(" .. las[pid].locker_object.uniqueIndex .. ")\n" .. 
            las[pid].locker_object.cell .. "\nLock level:" .. las[pid].locker_object.lock
            choice = "+5 to lock;-5 to lock; set 0; set default;Save object;remove from list;Select another;OL objects list;Back"
        end
    end
    if polymorph_menu then
        choice = "Select object;OL objects list;Back"
    end
    
    tes3mp.CustomMessageBox(pid, guiID.LOCKERmain, message, choice)
end

--Список объектов Locker
function LASlockerList(eventStatus,pid)
	local message = color.Orange .. "Object Locker objects list"
	local list = "* ЗАКРЫТЬ *\n"
	
	for ii, obj in pairs(locker_list) do
        local ids = obj.cell .. "(" .. obj.uniqueIndex .. ")"
		list = list .. ids .. "\n"
	end
	
    list = list .. "\n"
	return tes3mp.ListBox(pid, guiID.LOCKERList, message, list)
end

--Режим единичного выбора объекта Locker
local function LockerSelector(pid)
    if Players[pid].data.settings.staffRank > LAS_stuffRank then
        if las[pid] == nil then
            las[pid] = {}
            Players[pid]:Message("[LAS] Select activator.\n")
            las[pid].modeL = true
        else
            if las[pid].modeL == nil then
                Players[pid]:Message("[LAS] Select activator.\n")
                las[pid].modeL = true
            else
                Players[pid]:Message("[LAS] Select activator.\n")
                las[pid].modeL = true
            end
        end
    end
end

--поиск объекта по refId в Locker
local function findObjectLocker(id)
    for i, object in pairs(locker_list) do
        if locker_list[i].uniqueIndex == id then
            return i 
        end
    end
    return false
end

local function COL(id)
    if tostring(type(findObjectLocker(id))) == "boolean" then
        return false
    else
        return true
    end
end

--Отслеживаем прожатия по объектам
--используется следующими приблудами: QIP, TraderMood, Locker
customEventHooks.registerValidator("OnObjectActivate",
    function(eventStatus, pid, cellDescription, objects, targetPlayers)

        --Отслеживание админский действий
        if las[pid] ~= nil then
            --Код пометки предметов QIP
            if las[pid].mode ~= nil then
                if las[pid].mode then
                    for uniqueIndex, object in pairs(objects) do
                        for indexx, questObject in pairs(object_list) do
                            if (questObject.refId == object.refId) and (questObject.uniqueIndex == object.uniqueIndex) then
                                Players[pid]:Message(color.Red .. "[LAS] protect deactivated. QuestItem refid(" .. object.refId ..
                                                         ") uniqueIndex(" .. object.uniqueIndex .. ") .\n" ..
                                                         color.Default)
                                object_list[indexx] = nil
                                Save()
                                Load()
                                return customEventHooks.makeEventStatus(false, false)
                            end
                        end
                        Players[pid]:Message(color.Red .. "[LAS] protected QuestItem refid(" .. object.refId ..
                                                 ") uniqueIndex(" .. object.uniqueIndex .. ") .\n" .. color.Default)
                        local itemLoc = 0
                        if string.sub(object.uniqueIndex, 1, 1) == "0" and string.sub(object.uniqueIndex, 2, 2) == "-" then
                            if LoadedCells[cellDescription].data.objectData[object.uniqueIndex] ~= nil then
                                itemLoc = LoadedCells[cellDescription].data.objectData[object.uniqueIndex].location
                            end
                        end
                        table.insert(object_list, {
                            refId = object.refId,
                            uniqueIndex = object.uniqueIndex,
                            location = itemLoc,
                            cell = tes3mp.GetCell(pid),
                            posX = tes3mp.GetPosX(pid),
                            posY = tes3mp.GetPosY(pid),
                            posZ = tes3mp.GetPosZ(pid),
                            rotX = tes3mp.GetRotX(pid),
                            rotZ = tes3mp.GetRotZ(pid)
                        })
                        Save()
                        return customEventHooks.makeEventStatus(false, false)
                    end
                end
            end
            --Пометка торговцев Trader Mood
            if las[pid].modeTM ~= nil then
                if las[pid].modeTM then
                    for uniqueIndex, object in pairs(objects) do
                        --защита от случайного нажатия не по НПС
                        local break_this = true
                        for uniqueIndexT, _ in pairs(LoadedCells[cellDescription].data.packets.actorList) do
                            if LoadedCells[cellDescription].data.packets.actorList[uniqueIndexT] == uniqueIndex then
                                break_this = false
                            end
                        end
                        if break_this then
                            Players[pid]:Message(color.Red .. "[LAS] Only actors can be marked.\n" .. color.Default)
                            return customEventHooks.makeEventStatus(false, false)
                        end

                        for indexx, curObject in pairs(trader_list) do
                            if (curObject.refId == object.refId) then
                                Players[pid]:Message(color.Red .. "[LAS] trader removed: refid(" .. object.refId ..
                                                         ") uniqueIndex(" .. object.uniqueIndex .. ") .\n" ..
                                                         color.Default)
                                trader_list[indexx] = nil
                                SaveTM()
                                LoadTM()
                                return customEventHooks.makeEventStatus(false, false)
                            end
                        end

                        Players[pid]:Message(color.Red .. "[LAS] trader added: refid(" .. object.refId ..
                                                 ") uniqueIndex(" .. object.uniqueIndex .. ") .\n" .. color.Default)
                        table.insert(trader_list, {
                            refId = object.refId,
                            uniqueIndex = object.uniqueIndex,
                            cell = tes3mp.GetCell(pid),
                            posX = tes3mp.GetPosX(pid),
                            posY = tes3mp.GetPosY(pid),
                            posZ = tes3mp.GetPosZ(pid),
                            rotX = tes3mp.GetRotX(pid),
                            rotZ = tes3mp.GetRotZ(pid)
                        })
                        SaveTM()
                        return customEventHooks.makeEventStatus(false, false)
                    end
                end
            end
            --выбор объекта Locker
            if las[pid].modeL ~= nil then
                if las[pid].modeL then
                    for uniqueIndex, object in pairs(objects) do
                        if COL(object.uniqueIndex) then
                            local id = findObjectLocker(object.uniqueIndex)
                            if locker_list[id] ~= nil then
                                las[pid].locker_object = locker_list[id]
                                las[pid].modeL = false
                                Players[pid]:Message("[LAS] Selected.\n")
                                LASlockerMenu(eventStatus,pid)
                                return customEventHooks.makeEventStatus(false, false)
                            end
                        end
                        las[pid].locker_object = {
                            refId = object.refId,
                            uniqueIndex = object.uniqueIndex,
                            lock = "default",
                            cell = tes3mp.GetCell(pid),
                            posX = tes3mp.GetPosX(pid),
                            posY = tes3mp.GetPosY(pid),
                            posZ = tes3mp.GetPosZ(pid),
                            rotX = tes3mp.GetRotX(pid),
                            rotZ = tes3mp.GetRotZ(pid)
                        }
                        las[pid].modeL = false
                        Players[pid]:Message("[LAS] Selected.\n")
                        LASlockerMenu(eventStatus,pid)
                        return customEventHooks.makeEventStatus(false, false)
                    end
                end
            end
        end

        --TraderMood накидывание сервисного заклинания
        for uniqueIndex, object in pairs(objects) do
            for uniqueIndexT, objectT in pairs(LoadedCells[cellDescription].data.packets.actorList) do
                if LoadedCells[cellDescription].data.packets.actorList[uniqueIndexT] == uniqueIndex then
                    for indexx, curObject in pairs(trader_list) do
                        if (curObject.refId == object.refId) then
                            local need_to_add = true
                            for uIDSA, actor_with_spell in pairs(LoadedCells[cellDescription].data.packets.spellsActive) do
                                if LoadedCells[cellDescription].data.packets.spellsActive[uIDSA] == uniqueIndex then
                                    need_to_add = false
                                    break
                                end
                            end
                            if need_to_add then
                                table.insert(LoadedCells[cellDescription].data.packets.spellsActive, uniqueIndex)
                            end

                            trader_tss["$service_spell"][1]["startTime"] = os.time()
                            trader_tss["$service_spell"][1]["effects"][1]["magnitude"] = trader_data.attitude
                            LoadedCells[cellDescription].data.objectData[uniqueIndex].spellsActive = trader_tss
                            local objectData = LoadedCells[cellDescription].data.objectData
                            local packets = LoadedCells[cellDescription].data.packets
                            LoadedCells[cellDescription]:LoadActorSpellsActive(pid, objectData, packets.spellsActive)
                            return customEventHooks.makeEventStatus(true, true)
                        end
                    end
                end
            end
        end
    end)

--Функция для запрета удаления защищенного предмета
customEventHooks.registerValidator("OnObjectDelete", function(eventStatus, pid, cellDescription, objects)
    for uniqueIndex, object in pairs(objects) do
        for indexx, questObject in pairs(object_list) do
            for indexx, questObject in pairs(object_list) do
                if (questObject.refId == object.refId) and (questObject.uniqueIndex == object.uniqueIndex) then
                    return customEventHooks.makeEventStatus(false, false)
                end
            end
        end
    end
end)

--Функция блокировки убеждения у торговцев из списка TraderMood
customEventHooks.registerHandler("OnObjectDialogueChoice", function(eventStatus, pid, cellDescription, objects)
	for uniqueIndex, object in pairs(objects) do
		if object.dialogueChoiceType == enumerations.dialogueChoice.PERSUASION then
            if trader_data.persuationLock then
                for indexx, curObject in pairs(trader_list) do
                    if (curObject.refId == object.refId) then
                        return customEventHooks.makeEventStatus(false, false)
                    end
                end
            end
		end
	end
end)


--Функция обработки нажатий по граф.интерфейсу
function LASgraphInterface(eventStatus,pid,idGui,data)
	if     idGui == guiID.adminMain then
        if     tonumber(data) == 0 then
            LASQIPmainMenu(eventStatus,pid)
        elseif tonumber(data) == 1 then
            LASTraderMoodMainMenu(eventStatus,pid)
        elseif tonumber(data) == 2 then
            LASlockerMenu(eventStatus,pid)
        end
    elseif idGui == guiID.QIPmain then
        if     tonumber(data) == 0 then
            QuestItemProtectMode(pid)
        elseif tonumber(data) == 1 then
            LASquestItemList(eventStatus,pid)
        elseif tonumber(data) == 2 then
            ReLoad(pid)
        elseif tonumber(data) == 3 then
            LASmainMenu(eventStatus,pid)
        end
    elseif idGui == guiID.QIPList then
        if     tonumber(data) == 0 then
            LASQIPmainMenu(eventStatus,pid)
        else
            if object_list[tonumber(data)] ~= nil then
                tes3mp.SetCell(pid, object_list[tonumber(data)].cell)
                tes3mp.SetRot(pid, object_list[tonumber(data)].rotX, object_list[tonumber(data)].rotZ)
                tes3mp.SetPos(pid, object_list[tonumber(data)].posX, object_list[tonumber(data)].posY, object_list[tonumber(data)].posZ)
                tes3mp.SendCell(pid)
                tes3mp.SendPos(pid)
            end
        end
    elseif idGui == guiID.TraderMoodMain then
        --режим пометки
        if     tonumber(data) == 0 then
            TraderMoodMarkMode(pid)
        --список торговцев
        elseif tonumber(data) == 1 then
            LASTraderMoodTradersList(eventStatus,pid)
        --блокировка убеждения
        elseif tonumber(data) == 2 then
            trader_data.persuationLock = not trader_data.persuationLock
            LASTraderMoodMainMenu(eventStatus,pid)
        -- +5 к отношениям
        elseif tonumber(data) == 3 then
            trader_data.attitude = trader_data.attitude + 5
            LASTraderMoodMainMenu(eventStatus,pid)
        --текущее отношения
        elseif tonumber(data) == 4 then
            LASTraderMoodMainMenu(eventStatus,pid)
        -- -5 к отношениям
        elseif tonumber(data) == 5 then
            trader_data.attitude = trader_data.attitude - 5
            LASTraderMoodMainMenu(eventStatus,pid)
        end
    elseif idGui == guiID.TraderMoodList then
        if     tonumber(data) == 0 then
            LASTraderMoodMainMenu(eventStatus,pid)
        else
            if trader_list[tonumber(data)] ~= nil then
                tes3mp.SetCell(pid, trader_list[tonumber(data)].cell)
                tes3mp.SetRot(pid, trader_list[tonumber(data)].rotX, trader_list[tonumber(data)].rotZ)
                tes3mp.SetPos(pid, trader_list[tonumber(data)].posX, trader_list[tonumber(data)].posY, trader_list[tonumber(data)].posZ)
                tes3mp.SendCell(pid)
                tes3mp.SendPos(pid)
            end
        end
    elseif idGui == guiID.LOCKERmain then
        local def_v = true
        if las[pid] ~= nil then
            if las[pid].locker_object ~= nil then
                def_v = false
            end
        end
        if def_v then
            if tonumber(data) == 0 then
                LockerSelector(pid)
            elseif tonumber(data) == 1 then
                LASlockerList(eventStatus,pid)
            elseif tonumber(data) == 2 then
                LASQIPmainMenu(eventStatus,pid)
            end
        else
            local number_lock = 0
            if tostring(las[pid].locker_object.lock) ~= "default" then
                number_lock = las[pid].locker_object.lock
            end
            -- +5
            if tonumber(data) == 0 then
                las[pid].locker_object.lock = number_lock + 5
                LASlockerMenu(eventStatus,pid)
            -- -5
            elseif tonumber(data) == 1 then
                las[pid].locker_object.lock = number_lock - 5
                if las[pid].locker_object.lock < 0 then
                    las[pid].locker_object.lock = 0
                end
                LASlockerMenu(eventStatus,pid)
            -- set 0
            elseif tonumber(data) == 2 then
                las[pid].locker_object.lock = 0
                LASlockerMenu(eventStatus,pid)
            -- set default
            elseif tonumber(data) == 3 then
                las[pid].locker_object.lock = "default"
                LASlockerMenu(eventStatus,pid)
            -- Save
            elseif tonumber(data) == 4 then
                if COL(las[pid].locker_object.uniqueIndex) then
                    Players[pid]:Message("Find bool")
                    local id = findObjectLocker(las[pid].locker_object.uniqueIndex)
                    if locker_list[id] ~= nil then
                        Players[pid]:Message("Find id")
                        locker_list[id] = las[pid].locker_object
                    else
                        Players[pid]:Message("Find id not finded")
                        table.insert(locker_list, las[pid].locker_object)
                    end
                else
                    table.insert(locker_list, las[pid].locker_object)
                end
                SaveL()
                LoadL()
                Players[pid]:Message("[LAS] Saved " .. las[pid].locker_object.refId .. "(" .. las[pid].locker_object.uniqueIndex .. ")\n")
            -- remove from list
            elseif tonumber(data) == 5 then
                if COL(las[pid].locker_object.uniqueIndex) then
                    local id = findObjectLocker(las[pid].locker_object.uniqueIndex)
                    if locker_list[id] ~= nil then
                        Players[pid]:Message("[LAS] Removed " .. las[pid].locker_object.refId .. "(" .. las[pid].locker_object.uniqueIndex .. ")\n")
                        locker_list[id] = nil
                    end
                end
                las[pid].locker_object = nil
                SaveL()
                LoadL()
            -- selector
            elseif tonumber(data) == 6 then
                LockerSelector(pid)
            -- locker list 
            elseif tonumber(data) == 7 then
                LASlockerList(eventStatus,pid)
            elseif tonumber(data) == 8 then
                LASQIPmainMenu(eventStatus,pid)
            end
        end
    elseif idGui == guiID.LOCKERList then
        if     tonumber(data) == 0 then
            LASlockerMenu(eventStatus,pid)
        else
            if locker_list[tonumber(data)] ~= nil then
                if las[pid] == nil then
                    las[pid] = {}
                end
                las[pid].locker_object = locker_list[tonumber(data)]
                tes3mp.SetCell(pid, locker_list[tonumber(data)].cell)
                tes3mp.SetRot(pid, locker_list[tonumber(data)].rotX, locker_list[tonumber(data)].rotZ)
                tes3mp.SetPos(pid, locker_list[tonumber(data)].posX, locker_list[tonumber(data)].posY, locker_list[tonumber(data)].posZ)
                tes3mp.SendCell(pid)
                tes3mp.SendPos(pid)
                LASlockerMenu(eventStatus,pid)
            end
        end
    end
end



customCommandHooks.registerCommand("las", LASmainMenuC)


customEventHooks.registerValidator("OnGUIAction", LASgraphInterface)


local function findPacket(table, id)
    if type(table) == "table" then
        for i=1, #table do
            if table[i] == id then
                return true
            end
        end
    else
        tes3mp.LogAppend(enumerations.log.INFO, "[LAS] function findPacket use table data for first")
        tes3mp.StopServer(0)
    end
    return false
end


customEventHooks.registerHandler("OnServerPostInit", function()
    --загрузка данных QIP
    if tes3mp.DoesFileExist(tes3mp.GetModDir() .. "/custom/LAS_quest_items.json") then
        tes3mp.LogAppend(enumerations.log.INFO, "[LAS] QIP Item loaded ")
        Load()
        --После загрузки необходимо поставить на место выставленные администрацией предметы
        --и уточнить их uniqueIndex
        for indexx, questObject in pairs(object_list) do
            if object_list[indexx] ~= nil then
                if string.sub(questObject.uniqueIndex, 1, 1) == "0" and string.sub(questObject.uniqueIndex, 2, 2) == "-"
                    and type(questObject.location) == "table" then
                    tes3mp.LogAppend(enumerations.log.INFO, "[LAS] Quest item " .. questObject.refId .. "(" .. questObject.uniqueIndex .. ")")
                    
                    local useTempLoad = false
	                if not LoadedCells[questObject.cell] then
		                logicHandler.LoadCell(questObject.cell)
		                useTempLoad = true
	                end

                    if LoadedCells[questObject.cell].data.objectData[questObject.uniqueIndex] == nil then
                        local objectTable =  {
                            location = questObject.location,
                            refId = questObject.refId,
                            count = 1,
                            charge = 0,
                            enchantmentCharge = 0,
                            soul = 0,
                            scale = 1,
                            packetType = "place"
                        }
                        local uniqueIndex = logicHandler.CreateObjectAtLocation(questObject.cell, questObject.location, objectTable, "place")
                        object_list[indexx].uniqueIndex = uniqueIndex
                        tes3mp.LogAppend(enumerations.log.INFO, "[LAS] placed with uID " .. questObject.uniqueIndex )
                    end

	                if useTempLoad then
		                logicHandler.UnloadCell(questObject.cell)
	                end	
                end
            end
        end
    end
    Save()

    --загрузка данных TraderMood
    if tes3mp.DoesFileExist(tes3mp.GetModDir() .. "/custom/LAS_TSS.json") then
        tes3mp.LogAppend(enumerations.log.INFO, "[LAS] Trader Mood data loaded")
        LoadTM()
    else
        tes3mp.LogAppend(enumerations.log.INFO, "[LAS] Trader Mood needs custom/LAS_TSS.json file for working")
        tes3mp.StopServer(0)
    end

    --Активаторы из списка Locker должны быть закрыты\открыты
    -- 331481 "Seyda Neen, Arrille's Tradehouse" ex_nord_door_01
    if tes3mp.DoesFileExist(tes3mp.GetModDir() .. "/custom/LAS_locker_data.json") then
        tes3mp.LogAppend(enumerations.log.INFO, "[LAS] Load lockstate for objects")
        LoadL()
        local useTempLoad = false
        for one, two in pairs(locker_list) do
            useTempLoad = false
            if tostring(locker_list[one].lock) ~= "default" then       
                if not LoadedCells[locker_list[one].cell] then
                    logicHandler.LoadCell(locker_list[one].cell)
                    useTempLoad = true
                end
                if not findPacket(LoadedCells[locker_list[one].cell].data.packets.lock, locker_list[one].uniqueIndex) then
                    tes3mp.LogAppend(enumerations.log.INFO, "[LAS]" .. locker_list[one].cell .. " " .. locker_list[one].refId .. "(" .. locker_list[one].uniqueIndex .. ") new state " .. locker_list[one].lock)
                    table.insert(LoadedCells[locker_list[one].cell].data.packets.lock, locker_list[one].uniqueIndex)
                    LoadedCells[locker_list[one].cell].data.objectData[locker_list[one].uniqueIndex] = { lockLevel = locker_list[one].lock, refId = locker_list[one].refId}
                else
                    tes3mp.LogAppend(enumerations.log.INFO, "[LAS]" .. locker_list[one].cell .. " " .. locker_list[one].refId .. "(" .. locker_list[one].uniqueIndex .. ") new state " .. locker_list[one].lock)
                    LoadedCells[locker_list[one].cell].data.objectData[locker_list[one].uniqueIndex].lockLevel = locker_list[one].lock
                end
                if useTempLoad then
                    logicHandler.UnloadCell(locker_list[one].cell)
                end
            end
        end
    else
        SaveL()
    end
  
    
    
end)
--Очистка мусорных данных
customEventHooks.registerHandler("OnServerExit", function()
    --Очистка мусорных данных QIP
    local temp_table = {}
    for indexx, questObject in pairs(object_list) do
        if object_list[indexx] ~= nil then
            table.insert(temp_table, {
                refId = questObject.refId,
                uniqueIndex = questObject.uniqueIndex,
                location = questObject.location,
                cell = questObject.cell,
                posX = questObject.posX,
                posY = questObject.posY,
                posZ = questObject.posZ,
                rotX = questObject.rotX,
                rotZ = questObject.rotZ
            })
        end
    end
    --jsonInterface.save("custom/LAS_quest_items.json", temp_table)
    object_list = temp_table
    Save()
    --Очистка мусорных данных TraderMood
    temp_table = {}
    for indexx, traderss in pairs(trader_list) do
        if trader_list[indexx] ~= nil then
            table.insert(temp_table, {
                refId = traderss.refId,
                uniqueIndex = traderss.uniqueIndex,
                cell = traderss.cell,
                posX = traderss.posX,
                posY = traderss.posY,
                posZ = traderss.posZ,
                rotX = traderss.rotX,
                rotZ = traderss.rotZ
            })
        end
    end
    trader_list = temp_table
    SaveTM()
    --Очистка мусорных данных Locker
    local temp_table = {}
    for indexx, locks in pairs(locker_list) do
        if locker_list[indexx] ~= nil then
            table.insert(temp_table, {
                refId = locks.refId,
                uniqueIndex = locks.uniqueIndex,
                lock = locks.lock,
                cell = locks.cell,
                posX = locks.posX,
                posY = locks.posY,
                posZ = locks.posZ,
                rotX = locks.rotX,
                rotZ = locks.rotZ
            })
        end
    end
    locker_list = temp_table
    SaveL()
end)
--Сброс режимов пометок при выходе
customEventHooks.registerValidator("OnPlayerDisconnect", function(eventStatus, pid)
    if Players[pid].data.settings.staffRank > LAS_stuffRank then
        if las[pid] ~= nil then
            las[pid] = nil
        end
    end
end)

return las