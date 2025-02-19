-- Ensure ReQuestDB exists
--ReQuestDB = ReQuestDB or { lang = "en", isVisible = true }

-- List of supported languages
-- local supportedLanguages = {
--     en = "English",
--     bgn = "Български",
--     fr = "Français"
-- }

-- Store references to text objects
ReQuestTextObjects = {
    titleTexts = {},
    helpTexts = {},
    objectiveTexts = {},
    goldTexts = {},
    xpTexts = {}
}

-- Create the main UI Frame
local ReQuestFrame = CreateFrame("Frame", "ReQuestFrame", UIPParent, "BasicFrameTemplate")
ReQuestFrame:SetSize(280, 420) -- Adjusted size with new proportions
ReQuestFrame:SetPoint("CENTER")
ReQuestFrame:SetMovable(true)
ReQuestFrame:EnableMouse(true)
ReQuestFrame:RegisterForDrag("LeftButton")
ReQuestFrame:SetScript("OnDragStart", ReQuestFrame.StartMoving)
ReQuestFrame:SetScript("OnDragStop", ReQuestFrame.StopMovingOrSizing)
ReQuestFrame:SetClampedToScreen(true)
ReQuestFrame:Hide() -- Start hidden

-- Title text (adjusted for new size)
ReQuestFrame.title = ReQuestFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
ReQuestFrame.title:SetPoint("TOP", ReQuestFrame, "TOP", 0, -6)
ReQuestFrame.title:SetText("|cffffcc00ReQuest|r")
ReQuestFrame.title:SetFont("Interface\\AddOns\\ReQuest\\Fonts\\allods_west.ttf", 12, "OUTLINE")

-- Scrollable area (adjusted size)
local scrollFrame = CreateFrame("ScrollFrame", "ReQuestScrollFrame", ReQuestFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetSize(260, 360) -- Adjusted width & height proportionally
scrollFrame:SetPoint("TOP", ReQuestFrame, "TOP", 0, -35)

-- Scrollable content (adjusted width & height)
local scrollChild = CreateFrame("Frame", nil, scrollFrame)
scrollFrame:SetScrollChild(scrollChild)
scrollChild:SetSize(240, 640) -- Decreased width slightly for scrollbar space

-- Adjust Scroll Bar positioning to fit the new frame
local scrollBar = _G[scrollFrame:GetName() .. "ScrollBar"]
scrollBar:ClearAllPoints()
scrollBar:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", -5, -20)
scrollBar:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", -5, 20)

local bgTexture = ReQuestFrame:CreateTexture(nil, "BACKGROUND")
bgTexture:SetAllPoints(ReQuestFrame) -- Make it fill the entire frame
bgTexture:SetTexture("Interface\\AddOns\\ReQuest\\Textures\\Background\\QuestBackgroundClassic.PNG")
bgTexture:SetTexCoord(0, 1, 0, 1) -- Ensure full image is used

bgTexture:SetPoint("TOPLEFT", ReQuestFrame, "TOPLEFT", 5, -15)
bgTexture:SetPoint("BOTTOMRIGHT", ReQuestFrame, "BOTTOMRIGHT", -5, 5)
-- ✅ Fix for Text Overflow
local function CreateWrappedText(parent, textContent, yOffset)
    local text = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("TOP", parent, "TOP", 0, yOffset)
    text:SetWidth(230) -- Limit text width to prevent overflow
    text:SetJustifyH("LEFT") -- Align text to the left
    text:SetWordWrap(true) -- Enable word wrap
    text:SetText(textContent)
    text:Show()
    return text
end

-- Language Selection Dropdown
--local langDropdown = CreateFrame("Frame", "ReQuestLangDropdown", ReQuestFrame, "UIDropDownMenuTemplate")
--langDropdown:SetPoint("TOPLEFT", ReQuestFrame, "TOPLEFT", -15, -5)

-- UIDropDownMenu_Initialize(langDropdown, function(self, level)
--     local info = UIDropDownMenu_CreateInfo()
--     for lang, name in pairs(supportedLanguages) do
--         info.text = name
--         info.arg1 = lang
--         info.func = function(_, arg1)
--             ReQuestDB.lang = arg1
--             UIDropDownMenu_SetText(langDropdown, supportedLanguages[arg1])
--             UpdateQuestLog()
--         end
--         UIDropDownMenu_AddButton(info, level)
--     end
-- end)
-- UIDropDownMenu_SetWidth(langDropdown, 120)
-- UIDropDownMenu_SetText(langDropdown, supportedLanguages[ReQuestDB.lang or "en"])

-- Minimap Button
local minimapButton = CreateFrame("Button", "ReQuestMinimapButton", Minimap)
minimapButton:SetSize(32, 32)
minimapButton:SetFrameStrata("LOW")
minimapButton:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -5, 5)

minimapButton.icon = minimapButton:CreateTexture(nil, "BACKGROUND")
minimapButton.icon:SetTexture("Interface\\ICONS\\INV_Misc_Book_09") -- Example book icon
minimapButton.icon:SetSize(20, 20)
minimapButton.icon:SetPoint("CENTER")

minimapButton:SetScript("OnClick", function()
    if ReQuestFrame:IsShown() then
        ReQuestFrame:Hide()
        ReQuestDB.isVisible = false
    else
        ReQuestFrame:Show()
        UpdateQuestLog()
        ReQuestDB.isVisible = true
    end
end)

minimapButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("|cffffcc00ReQuest|r\nClick to open quest log", 1, 1, 1)
    GameTooltip:Show()
end)

minimapButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- Function to clear quest texts
local function ClearQuestText()
    for _, title in ipairs(ReQuestTextObjects.titleTexts) do
        title:SetText("")
        title:Hide()
    end
    for _, help in ipairs(ReQuestTextObjects.helpTexts) do
        help:SetText("")
        help:Hide()
    end
    for _, objective in ipairs(ReQuestTextObjects.objectiveTexts) do
        objective:SetText("")
        objective:Hide()
    end
    for _, gold in ipairs(ReQuestTextObjects.goldTexts) do
        gold:SetText("")
        gold:Hide()
    end
    for _, xp in ipairs(ReQuestTextObjects.xpTexts) do
        xp:SetText("")
        xp:Hide()
    end
end


-- Function to get quest help in the selected language
local function GetQuestHelp(questID)
    local lang = ReQuestDB.lang or "bgn"
    if ReQuestQuests and ReQuestQuests[questID] then
        return ReQuestQuests[questID][lang] or ReQuestQuests[questID]["bgn"]
    else
        return "|cffff5555Няма налична информация.|r"
    end
end


-- Function to clear all children in the scrollable area
local function ClearScrollChild()
     -- Get all children of the scrollChild frame
     local children = { scrollChild:GetChildren() }
     for _, child in ipairs(children) do
         if child.SetText then -- Check if it's a font string
             child:SetText("")
         end
     end
end

-- Function to clear all children in the scrollable area
local function ShowScrollChild()
    -- Get all children of the scrollChild frame
    local children = { scrollChild:GetChildren() }
    for _, child in ipairs(children) do
        child:Show()
        child:SetParent(scrollChild)
    end
    
end

local function GetActiveQuestsForCurrentSession()
    local quests = {} -- Списък за активните куестове
    local numEntries = C_QuestLog.GetNumQuestLogEntries() -- Броят на записите в дневника

    for i = 1, numEntries do
        local info = C_QuestLog.GetInfo(i)
        if info and not info.isHeader then -- Пропускаме хедърите (заглавията на категориите)
            local questID = info.questID
            
            -- Проверяваме дали куестът е активен за текущата сесия и не е забранен
            if not C_QuestLog.IsQuestDisabledForSession(questID) then
                table.insert(quests, questID) -- Запазваме куеста
            end
        end
    end
    
    return quests
end



local screen
local savedQuestID

local campaignIcon = "|TInterface\\AddOns\\ReQuest\\Icons\\CampaignIcon.png:16:16|t"
local normalQuestIcon = "|TInterface\\AddOns\\ReQuest\\Icons\\QuestNormalIcon-export.png:16:16|t"
local metaQuest = "|TInterface\\AddOns\\ReQuest\\Icons\\metaQuest.png:16:16|t"
local waypointIcon = "|TInterface\\AddOns\\ReQuest\\Icons\\waypoint.png:16:16|t"
local goldIcon = "|TInterface\\AddOns\\ReQuest\\Icons\\gold.png:16:16|t"
local silverIcon = "|TInterface\\AddOns\\ReQuest\\Icons\\silver.png:16:16|t"
local copperIcon = "|TInterface\\AddOns\\ReQuest\\Icons\\copper.png:16:16|t"

local function FormatCurrencyString(coinText)
    -- Extract gold, silver, and copper values using correct words
    local gold = coinText:match("(%d+) Gold") or "0"
    local silver = coinText:match("(%d+) Silver") or "0"
    local copper = coinText:match("(%d+) Copper") or "0"

    -- Convert to numbers
    gold = tonumber(gold) or 0
    silver = tonumber(silver) or 0
    copper = tonumber(copper) or 0
    
    -- Construct formatted string with icons
    local formattedText = ""

    if gold > 0 then
        formattedText = formattedText .. gold .. goldIcon .. " "
    end
    if silver > 0 then
        formattedText = formattedText .. silver .. silverIcon .. " "
    end
    if copper > 0 then
        formattedText = formattedText .. copper .. copperIcon
    end

    return formattedText
end

-- Function to create a YouTube button with thumbnail and link
local function CreateYouTubeButton(videoID, yOffset)
    local youtubeButton = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    youtubeButton:SetSize(120, 70)  
    youtubeButton:SetPoint("TOP", scrollChild, "TOP", 0, yOffset) 

    -- Placeholder thumbnail (replace with your own)
    local thumbnailURL = "Interface\\AddOns\\ReQuest\\Icons\\YouTubeThumbnail.png"  

    -- Create the texture for the thumbnail
    youtubeButton.icon = youtubeButton:CreateTexture(nil, "ARTWORK")
    youtubeButton.icon:SetSize(120, 70)  
    youtubeButton.icon:SetPoint("CENTER", youtubeButton, "CENTER", 0, 0)
    youtubeButton.icon:SetTexture(thumbnailURL) 

    -- Set tooltip
    youtubeButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("|cFFFF0000YouTube Guide|r\nClick to watch the guide", 1, 1, 1)
        GameTooltip:Show()
    end)
    youtubeButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Open a Copy-Paste Window
    youtubeButton:SetScript("OnClick", function()
        local url = "https://www.youtube.com/watch?v=" .. videoID
        StaticPopupDialogs["REQUEST_YOUTUBE"] = {
            text = "Копирайте връзката в браузър:",
            button1 = "Close",
            OnShow = function(self) self.editBox:SetText(url) self.editBox:HighlightText() end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            hasEditBox = true,
            editBoxWidth = 260,
            enterClicksFirstButton = true,
        }
        StaticPopup_Show("REQUEST_YOUTUBE")
    end)

    youtubeButton:Show()
    return youtubeButton
end

local function GetQuestVideoURL(questID)
    if ReQuestQuests and ReQuestQuests[questID] then
        return ReQuestQuests[questID]["href"] or nil
    end
    return nil -- Return nil if no video is available
end

-- Store the currently viewed quest ID
local viewedQuestID = nil
-- Function to update the ReQuest window and show the abandon button
-- Функция за обновяване на прозореца за куестове
local function UpdateReQuestWindow(questID)
    screen = 0
    -- Example YouTube video for this quest
    local youtubeVideoID = GetQuestVideoURL(questID)
    if youtubeVideoID then
        local youtubeButton = CreateYouTubeButton(youtubeVideoID, yOffset)
        yOffset = yOffset - 80  -- Adjust spacing to prevent overlapping
    end
    -- Clear previous quest information
    ClearQuestText()
    ReQuestTextObjects.helpTexts = {}
    ReQuestTextObjects.objectiveTexts = {}
    ReQuestTextObjects.goldTexts = {}
    ReQuestTextObjects.xpTexts = {}
    
    local info = C_QuestLog.GetTitleForQuestID(questID)
    if not info then
        print("Invalid quest ID or title not found:", questID)
        return
    end
    
    local questHelp = GetQuestHelp(questID)
    local objectives = C_QuestLog.GetQuestObjectives(questID)
    
    -- **Start positioning elements**
    local yOffset = -10
    
    -- **Quest Title**
    local titleText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    
    if C_CampaignInfo.IsCampaignQuest(questID) then
        titleText:SetText(campaignIcon .. "|cffffcc00" .. info .. "|r")
    elseif C_QuestLog.IsMetaQuest(questID) then
        titleText:SetText(metaQuest .. "|cffffcc00" .. info .. "|r")
    else
        titleText:SetText(normalQuestIcon .. "|cffffcc00" .. info .. "|r")
    end
    
    titleText:SetPoint("TOP", scrollChild, "TOP", 0, yOffset)
    titleText:SetParent(scrollChild)
    titleText:Show()
    table.insert(ReQuestTextObjects.titleTexts, titleText)
    
    yOffset = yOffset - 25 -- Space after title
    
    -- **Quest Description**
    local helpText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    helpText:SetFont("Interface\\AddOns\\ReQuest\\Fonts\\allods_west.ttf", 11)
    helpText:SetText("|cFF543D1E" .. questHelp .. "|r")
    helpText:SetPoint("TOP", scrollChild, "TOP", 0, yOffset)
    helpText:SetWidth(230)
    helpText:SetJustifyH("CENTER")
    helpText:SetWordWrap(true)
    helpText:SetParent(scrollChild)
    helpText:Show()
    table.insert(ReQuestTextObjects.helpTexts, helpText)
    
    yOffset = yOffset - helpText:GetHeight() - 15 -- Space after quest description
    
    -- **Quest Objectives**
    local questInfo = ""
    if objectives then
        for _, obj in ipairs(objectives) do
            local color = obj.finished and "|cFF00FF00" or "|cFFFFFFFF"
            questInfo = questInfo .. color .. obj.text .. " (" .. obj.numFulfilled .. "/" .. obj.numRequired .. ")|r\n"
        end
    end
    
    local objectiveText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    objectiveText:SetFont("Interface\\AddOns\\ReQuest\\Fonts\\allods_west.ttf", 11, "OUTLINE")
    objectiveText:SetText(waypointIcon .. questInfo .. "|r")
    objectiveText:SetPoint("TOP", scrollChild, "TOP", 0, yOffset)
    objectiveText:SetJustifyH("CENTER")
    objectiveText:SetParent(scrollChild)
    objectiveText:Show()
    table.insert(ReQuestTextObjects.objectiveTexts, objectiveText)
    
    yOffset = yOffset - objectiveText:GetHeight() - 20 -- Space before rewards
    
    -- **💰 Gold Reward**
    local rawCoinText = GetCoinText(GetQuestLogRewardMoney(questID))
    local formattedCoinText = FormatCurrencyString(rawCoinText)
    
    local goldText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    goldText:SetFont("Interface\\AddOns\\ReQuest\\Fonts\\allods_west.ttf", 11, "OUTLINE")
    goldText:SetText("|cFF00FF00Парична награда: |r " .. formattedCoinText)
    goldText:SetPoint("TOP", scrollChild, "TOP", 0, yOffset)
    goldText:SetJustifyH("CENTER")
    goldText:SetParent(scrollChild)
    goldText:Show()
    table.insert(ReQuestTextObjects.goldTexts, goldText)
    
    yOffset = yOffset - 20 -- Space after gold reward
    
    -- **🌟 Experience Reward**
    local xpReward = GetQuestLogRewardXP(questID)
    if xpReward and xpReward > 0 then
        local xpText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        xpText:SetFont("Interface\\AddOns\\ReQuest\\Fonts\\allods_west.ttf", 11, "OUTLINE")
        xpText:SetText("|cFF00FF00Награда Опит:|r " .. xpReward .. " XP")
        xpText:SetPoint("TOP", scrollChild, "TOP", 0, yOffset)
        xpText:SetJustifyH("CENTER")
        xpText:SetParent(scrollChild)
        xpText:Show()
        table.insert(ReQuestTextObjects.xpTexts, xpText)
    
        yOffset = yOffset - 20 -- Space after XP reward
    end
    
    -- **🎁 Item Rewards**
    local numRewards = GetNumQuestLogRewards(questID)
    if numRewards and numRewards > 0 then
        for i = 1, numRewards do
            local itemName, itemTexture, numItems, quality, isUsable, itemID, itemLevel = GetQuestLogRewardInfo(i, questID)
            if itemName and itemTexture then
                -- **Create item icon**
                local itemIcon = scrollChild:CreateTexture(nil, "ARTWORK")
                itemIcon:SetSize(16, 16)
                itemIcon:SetPoint("LEFT", scrollChild, "LEFT", 10, yOffset)
                itemIcon:SetTexture(itemTexture)
    
                -- Tooltip on hover
                itemIcon:SetScript("OnEnter", function()
                    GameTooltip:SetOwner(itemIcon, "ANCHOR_RIGHT")
                    GameTooltip:SetHyperlink("item:" .. itemID)
                    GameTooltip:Show()
                end)
                itemIcon:SetScript("OnLeave", function()
                    GameTooltip:Hide()
                end)
    
                -- **Create item text**
                local rarityColor = ITEM_QUALITY_COLORS[quality] and ITEM_QUALITY_COLORS[quality].hex or "|cFFFFFFFF"
                local itemText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                itemText:SetFont("Interface\\AddOns\\ReQuest\\Fonts\\allods_west.ttf", 11, "OUTLINE")
                itemText:SetText(rarityColor .. itemName .. "|r x" .. numItems)
                itemText:SetPoint("LEFT", itemIcon, "RIGHT", 5, 0)
    
                -- Store elements
                table.insert(ReQuestTextObjects.objectiveTexts, itemText)
                table.insert(ReQuestTextObjects.itemIcons, itemIcon)
    
                yOffset = yOffset - 25 -- Space after each item
            end
        end
    end
    
    -- **🔘 Selectable Rewards**
    local numChoices = GetNumQuestLogChoices(questID)
    if numChoices and numChoices > 0 then
        -- Add "Choose Reward" label
        local chooseText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        chooseText:SetFont("Interface\\AddOns\\ReQuest\\Fonts\\allods_west.ttf", 11, "OUTLINE")
        chooseText:SetText("|cFFFFCC00Избери Награда:|r")
        chooseText:SetPoint("TOP", scrollChild, "TOP", 0, yOffset)
        chooseText:Show()
        table.insert(ReQuestTextObjects.objectiveTexts, chooseText)
    
        yOffset = yOffset - 20 -- Space after label
    
        for i = 1, numChoices do
            local itemName, itemTexture, numItems, quality, isUsable, itemID, itemLevel = GetQuestLogChoiceInfo(i, questID)
            if itemName and itemTexture then
                -- Create selectable reward icon & text
                local itemIcon = scrollChild:CreateTexture(nil, "ARTWORK")
                itemIcon:SetSize(32, 32)
                itemIcon:SetPoint("LEFT", scrollChild, "LEFT", 10, yOffset)
                itemIcon:SetTexture(itemTexture)
    
                local itemText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                itemText:SetFont("Interface\\AddOns\\ReQuest\\Fonts\\allods_west.ttf", 11, "OUTLINE")
                itemText:SetText(rarityColor .. itemName .. "|r x" .. numItems)
                itemText:SetPoint("LEFT", itemIcon, "RIGHT", 5, 0)
    
                table.insert(ReQuestTextObjects.objectiveTexts, itemText)
                table.insert(ReQuestTextObjects.itemIcons, itemIcon)
    
                yOffset = yOffset - 40 -- Adjust spacing for selectable rewards
            end
        end
    end
    
    scrollChild:SetHeight(math.abs(yOffset) + 20)
    scrollFrame:UpdateScrollChildRect()
    
    -- Запазване на текущия куест
    viewedQuestID = questID
end

-- Function to update the Quest Log UI/ MENU
local function UpdateQuestLog()
    
    -- First, clear previous rewards before adding new ones
    for _, obj in ipairs(ReQuestTextObjects.objectiveTexts) do
        obj:Hide() -- Hide all previous text objects
    end
    for _, obj in ipairs(ReQuestTextObjects.itemIcons or {}) do
        obj:Hide() -- Hide all previous item icons
    end
    ReQuestTextObjects.objectiveTexts = {}
    ReQuestTextObjects.itemIcons = {}

    screen = 1
    -- Clear previous quest text
    ClearQuestText()
    ReQuestTextObjects.titleTexts = {}

    -- Get the active quests for the current session
    local activeQuests = GetActiveQuestsForCurrentSession()

    if #activeQuests == 0 then
        print("[ReQuest] No active quests found in the quest log.")
        return
    end

    local yOffset = -5

    for _, questID in ipairs(activeQuests) do
       
        local questTitle = C_QuestLog.GetTitleForQuestID(questID)
        viewedQuestID = questID
        -- Create a clickable button
        local questButton = CreateFrame("Button", nil, scrollChild)
        questButton:SetSize(300, 20) -- Button size
        questButton:SetPoint("TOP", scrollChild, "TOP", 0, yOffset)

        -- Add text to the button
        local titleText = questButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        if C_CampaignInfo.IsCampaignQuest(questID) then
            titleText:SetText(campaignIcon .. "|cffffcc00" .. questTitle .. "|r")
        else
            titleText:SetText(normalQuestIcon .. "|cffffcc00" .. questTitle .. "|r")
        end
        if C_QuestLog.IsMetaQuest(questID) then
            titleText:SetText(metaQuest .. "|cffffcc00" .. questTitle .. "|r")
        end
        titleText:SetPoint("CENTER")
        questButton:SetFontString(titleText)

        -- Set up click behavior
        questButton:SetScript("OnClick", function()
            savedQuestID = questID
            UpdateReQuestWindow(questID) -- Load quest details
        end)

        -- Mouse-over highlight effect
        questButton:SetHighlightTexture("Interface\\BUTTONS\\UI-Common-MouseHilight")

        -- Tooltip on hover
        questButton:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("|cffffcc00" .. questTitle .. "|r", 1, 1, 1, 1, true)
            GameTooltip:AddLine("Click to see quest details!", 0, 1, 0)
            GameTooltip:Show()
        end)
        questButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

        questButton:Show()
        table.insert(ReQuestTextObjects.titleTexts, questButton)

        yOffset = yOffset - 25 -- Move down for next entry
    end

    scrollChild:SetHeight(math.abs(yOffset) + 20)
    scrollFrame:UpdateScrollChildRect()
end


-- Ensure the quest log updates when the frame is shown
ReQuestFrame:SetScript("OnShow", function()
    UpdateQuestLog()
end)



-- Function to abandon the current quest
local function AbandonCurrentQuest()
    if viewedQuestID then
        -- Confirmation Dialog
        StaticPopupDialogs["ABANDON_QUEST_CONFIRM"] = {
            text = "Наистина ли искате да изоставите тази задача?",
            button1 = "Да",
            button2 = "Не",
            OnAccept = function()
                C_QuestLog.SetSelectedQuest(viewedQuestID)
                C_QuestLog.SetAbandonQuest(viewedQuestID)
                C_QuestLog.AbandonQuest(viewedQuestID) -- Directly abandon quest
                --print("|cffff5555[ReQuest] Задачата е изоставена: " .. C_QuestLog.GetTitleForQuestID(viewedQuestID) .. "|r")
                viewedQuestID = nil
                StaticPopup_Hide("ABANDON_QUEST_CONFIRM")
                --
                --screen = 0
                --UpdateReQuestWindow(viewedQuestID)
                ClearQuestText()
                UpdateQuestLog()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
        }
        StaticPopup_Show("ABANDON_QUEST_CONFIRM")
    end
end

-- Refresh Button
local refreshButton = CreateFrame("Button", "RefreshTextButton", ReQuestFrame, "UIPanelButtonTemplate")
refreshButton:SetSize(100, 30)
refreshButton:SetPoint("BOTTOMRIGHT", ReQuestFrame, "BOTTOMRIGHT", -15, 10)
refreshButton:SetText("Назад")
refreshButton:SetScript("OnClick", function()
    UpdateQuestLog()
end)

-- Abandon Button
local abandonButton = CreateFrame("Button", "AbandonQuestButton", ReQuestFrame, "UIPanelButtonTemplate")
abandonButton:SetSize(100, 30)
abandonButton:SetPoint("BOTTOMLEFT", ReQuestFrame, "BOTTOMLEFT", 10, 10)
abandonButton:SetText("Махни задача")
abandonButton:SetScript("OnClick", function()
    AbandonCurrentQuest()
end)

-- Ensure the quest log updates when the frame is shown
ReQuestFrame:SetScript("OnShow", function()
    UpdateQuestLog()
end)

-- Track quest changes
local function OnQuestChange()
    if ReQuestFrame:IsShown() then
        -- Force a quest log refresh
        ClearScrollChild()
        UpdateQuestLog()
    else
        --ClearScrollChild()
        --ReQuestFrame:Show()
        UpdateQuestLog()
    end
end

local function OnAccept(self, event, ...)
    if ReQuestFrame:IsShown() then
        -- Force a quest log refresh
        ClearScrollChild()
        UpdateQuestLog()
    else
        ReQuestFrame:Show()
    end
end

local function AutoUpdate()
    if screen == 0 then
        youtubeButton:Show()
        refreshButton:Show()
        abandonButton:Show()
        --trackButton:Show()
        ClearScrollChild()
        UpdateReQuestWindow(savedQuestID)
    else
        UpdateQuestLog()
        youtubeButton:Hide()
        refreshButton:Hide()
        abandonButton:Hide()
        --trackButton:Hide()
    end
end

--Set button click behavior
refreshButton:SetScript("OnClick", function()
    refreshButton:Hide() -- Hide the button
    UpdateQuestLog() -- Reload the quest list
end)

--Set button click behavior
abandonButton:SetScript("OnClick", function()
    abandonButton:Hide() -- Hide the button
    AbandonCurrentQuest() -- Reload the quest list
end)

--local trackValue = false
-- ✅ Фикс за Click Event
-- trackButton:SetScript("OnClick", function()
--     if trackValue == true then
--         trackValue = false
--         C_QuestLog.RemoveQuestWatch(viewedQuestID)
--         trackButton:SetText("Track")
--     else
--         trackValue = true
--         C_QuestLog.AddQuestWatch(viewedQuestID, true) -- Флагът true го добавя към списъка за гледане
--         trackButton:SetText("Untrack")
--     end
-- end)


local ticker = C_Timer.NewTicker(0.6, AutoUpdate)
-- Register events to refresh the quest log dynamically
ReQuestFrame:RegisterEvent("QUEST_LOG_UPDATE")
ReQuestFrame:RegisterEvent("QUEST_REMOVED")
ReQuestFrame:RegisterEvent("QUEST_COMPLETE")
ReQuestFrame:RegisterEvent("UNIT_QUEST_LOG_CHANGED")
ReQuestFrame:RegisterEvent("QUEST_ACCEPT_CONFIRM")
ReQuestFrame:RegisterEvent("QUEST_TURNED_IN")
ReQuestFrame:RegisterEvent("QUEST_POI_UPDATE")
ReQuestFrame:RegisterEvent("QUEST_ACCEPTED")
ReQuestFrame:RegisterEvent("QUEST_WATCH_UPDATE")
ReQuestFrame:RegisterEvent("UNIT_QUEST_LOG_CHANGED")
ReQuestFrame:RegisterEvent("QUEST_ITEM_UPDATE")
ReQuestFrame:RegisterEvent("QUEST_PROGRESS")
ReQuestFrame:SetScript("OnEvent", function(self, event, ...)
    -- Debugging: Print the event being handled
    print(string.format("[ReQuest] Event triggered: %s", event))

    if event == "QUEST_LOG_UPDATE" or event == "QUEST_COMPLETE" or event == "QUEST_PROGRESS" or event == "QUEST_ITEM_UPDATE" or event == "QUEST_ACCEPT_CONFIRM" or event == "QUEST_TURNED_IN" or event == "QUEST_WATCH_UPDATE" or event == "UNIT_QUEST_LOG_CHANGED" then
        OnQuestChange()
    end
end)

-- Restore UI visibility on login
ReQuestFrame:RegisterEvent("ADDON_LOADED")
ReQuestFrame:SetScript("OnEvent", function(self, event, addon)
    if addon == "ReQuest" then
        if ReQuestDB.isVisible then
            ClearScrollChild()
            UpdateQuestLog()
        else
            ReQuestFrame:Show()
        end
    end
end)

ReQuestFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "QUEST_ACCEPTED" then
        OnAccept()
    end
end)

