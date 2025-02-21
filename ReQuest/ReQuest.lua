-- Ensure ReQuestDB exists
ReQuestDB = ReQuestDB or { lang = "bgn", isVisible = true }

-- Store references to text objects
ReQuestTextObjects = {
    titleTexts = {},
    mainTexts = {},
    subhelpTexts = {},
    helpTexts = {},
    objectiveTexts = {},
    goldTexts = {},
    xpTexts = {}
}

-- Create the main UI Frame with a 10% reduction
local ReQuestFrame = CreateFrame("Frame", "ReQuestFrame", UIPParent, "BasicFrameTemplate")
ReQuestFrame:SetSize(252, 378) -- 10% smaller than original (280x420)
ReQuestFrame:SetPoint("CENTER")
ReQuestFrame:SetMovable(true)
ReQuestFrame:EnableMouse(true)
ReQuestFrame:RegisterForDrag("LeftButton")
ReQuestFrame:SetScript("OnDragStart", ReQuestFrame.StartMoving)
ReQuestFrame:SetScript("OnDragStop", ReQuestFrame.StopMovingOrSizing)
ReQuestFrame:SetClampedToScreen(true)
ReQuestFrame:Hide() -- Start hidden

-- Title text with adjusted font size
ReQuestFrame.title = ReQuestFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
ReQuestFrame.title:SetPoint("TOP", ReQuestFrame, "TOP", 0, -6)
ReQuestFrame.title:SetText("|cffffcc00ReQuest|r")
ReQuestFrame.title:SetFont("Interface\\AddOns\\ReQuest\\Fonts\\allods_west.ttf", 11, "OUTLINE") -- Reduced font size

-- Scrollable area with adjusted size
local scrollFrame = CreateFrame("ScrollFrame", "ReQuestScrollFrame", ReQuestFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetSize(234, 300) -- 10% smaller
scrollFrame:SetPoint("TOP", ReQuestFrame, "TOP", 0, -35)

-- Scrollable content
local scrollChild = CreateFrame("Frame", nil, scrollFrame)
scrollFrame:SetScrollChild(scrollChild)
scrollChild:SetSize(216, 536) -- Adjusted width & height

-- Adjust Scroll Bar positioning
local scrollBar = _G[scrollFrame:GetName() .. "ScrollBar"]
scrollBar:ClearAllPoints()
scrollBar:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", -5, -20)
scrollBar:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", -5, 20)

-- Background texture
local bgTexture = ReQuestFrame:CreateTexture(nil, "BACKGROUND")
bgTexture:SetAllPoints(ReQuestFrame)
bgTexture:SetTexture("Interface\\AddOns\\ReQuest\\Textures\\Background\\QuestBackgroundClassic.PNG")
bgTexture:SetTexCoord(0, 1, 0, 1)
bgTexture:SetPoint("TOPLEFT", ReQuestFrame, "TOPLEFT", 5, -18)
bgTexture:SetPoint("BOTTOMRIGHT", ReQuestFrame, "BOTTOMRIGHT", -5, 5)
-- ✅ Fix for Text Overflow
local function CreateWrappedText(parent, textContent, yOffset)
    local text = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("TOP", parent, "TOP", 0, yOffset)
    text:SetWidth(210) -- Limit text width to prevent overflow
    text:SetJustifyH("LEFT") -- Align text to the left
    text:SetWordWrap(true) -- Enable word wrap
    text:SetText(textContent)
    text:Show()
    return text
end

-- Minimap Button
local minimapButton = CreateFrame("Button", "ReQuestMinimapButton", Minimap)
minimapButton:SetSize(28, 28) -- Slightly smaller
minimapButton:SetFrameStrata("LOW")
minimapButton:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -5, 5)

minimapButton.icon = minimapButton:CreateTexture(nil, "BACKGROUND")
minimapButton.icon:SetTexture("Interface\\ICONS\\INV_Misc_Book_09")
minimapButton.icon:SetSize(18, 18)
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
    for _, subhelp in ipairs(ReQuestTextObjects.subhelpTexts) do
        subhelp:SetText("")
        subhelp:Hide()
    end
    for _, main in ipairs(ReQuestTextObjects.mainTexts) do
        main:SetText("")
        main:Hide()
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

-- Function to get quest main quest description in the selected language
local function GetQuestMain(questID)
    local lang = "fr"
    if ReQuestQuests and ReQuestQuests[questID] then
        return ReQuestQuests[questID]["fr"]
    else
        return "|cffff5555Няма налична информация.|r"
    end
end

-- Function to get quest help in the selected language
local function GetQuestHelp(questID)
    local lang = "bgn"
    if ReQuestQuests and ReQuestQuests[questID] then
        return ReQuestQuests[questID]["bgn"]
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
local function CreateYouTubeLink(videoID, yOffset)
    -- YouTube icon path
    local thumbnailURL = "Interface\\AddOns\\ReQuest\\Icons\\youtube-logo.png"

    -- Create the texture for the thumbnail
    youtubeButton.icon = youtubeButton:CreateTexture(nil, "ARTWORK")
    youtubeButton.icon:SetSize(60, 35)
    youtubeButton.icon:SetPoint("CENTER", youtubeButton, "CENTER", 0, 0)
    youtubeButton.icon:SetTexture(thumbnailURL)

    local url = "https://www.youtube.com/watch?v=" .. videoID
    StaticPopupDialogs["REQUEST_YOUTUBE"] = {
        text = "Копирайте връзката в браузър:",
        button1 = "Close",
        OnShow = function(self)
            self.editBox:SetText(url)
            self.editBox:HighlightText()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        hasEditBox = true,
        editBoxWidth = 260,
        enterClicksFirstButton = true,
    }
    StaticPopup_Show("REQUEST_YOUTUBE")

    youtubeButton:Show()
    --return youtubeButton
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
    
    -- Clear previous quest information
    ClearQuestText()
    ReQuestTextObjects.helpTexts = {}
    ReQuestTextObjects.subhelpTexts = {}
    ReQuestTextObjects.mainTexts = {}
    ReQuestTextObjects.objectiveTexts = {}
    ReQuestTextObjects.goldTexts = {}
    ReQuestTextObjects.xpTexts = {}
    
    local info = C_QuestLog.GetTitleForQuestID(questID)
    if not info then
        print("Invalid quest ID or title not found:", questID)
        return
    end
    print("QuestID:", questID)
    local questHelp = GetQuestHelp(questID)
    local questMain = GetQuestMain(questID)
    local objectives = C_QuestLog.GetQuestObjectives(questID)
    
    -- **Start positioning elements**
    local yOffset = -9
    
    -- **Quest Title**
    local titleText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
    
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
    
    -- **Quest Main Description**
    local mainText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    mainText:SetFont("Interface\\AddOns\\ReQuest\\Fonts\\allods_west.ttf", 10)
    mainText:SetText("|cFF543D1E" .. questMain .. "|r")
    mainText:SetPoint("TOP", scrollChild, "TOP", 0, yOffset)
    mainText:SetWidth(220)
    mainText:SetJustifyH("CENTER")
    mainText:SetWordWrap(true)
    mainText:SetParent(scrollChild)
    mainText:Show()
    table.insert(ReQuestTextObjects.mainTexts, mainText)

    yOffset = yOffset - mainText:GetHeight() - 15 -- Space after quest description
    
    local subhelpText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    subhelpText:SetFont("Interface\\AddOns\\ReQuest\\Fonts\\allods_west.ttf", 13)
    subhelpText:SetText("|cFF543D1EОписание|r")
    subhelpText:SetPoint("TOP", scrollChild, "TOP", 0, yOffset)
    subhelpText:SetWidth(220)
    subhelpText:SetJustifyH("CENTER")
    subhelpText:SetWordWrap(true)
    subhelpText:SetParent(scrollChild)
    subhelpText:Show()
    table.insert(ReQuestTextObjects.subhelpTexts, subhelpText)

    yOffset = yOffset - subhelpText:GetHeight() - 10
    -- **Quest Description**
    local helpText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    helpText:SetFont("Interface\\AddOns\\ReQuest\\Fonts\\allods_west.ttf", 10)
    helpText:SetText("|cFF543D1E" .. questHelp .. "|r")
    helpText:SetPoint("TOP", scrollChild, "TOP", 0, yOffset)
    helpText:SetWidth(220)
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
    objectiveText:SetFont("Interface\\AddOns\\ReQuest\\Fonts\\allods_west.ttf", 10, "OUTLINE")
    objectiveText:SetText(waypointIcon .. questInfo .. "|r")
    objectiveText:SetPoint("TOP", scrollChild, "TOP", 0, yOffset)
    objectiveText:SetWidth(220)
    objectiveText:SetJustifyH("CENTER")
    objectiveText:SetParent(scrollChild)
    objectiveText:Show()
    table.insert(ReQuestTextObjects.objectiveTexts, objectiveText)
    
    yOffset = yOffset - objectiveText:GetHeight() - 20 -- Space before rewards
    
    -- **💰 Gold Reward**
    local rawCoinText = GetCoinText(GetQuestLogRewardMoney(questID))
    local formattedCoinText = FormatCurrencyString(rawCoinText)
    
    local goldText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    goldText:SetFont("Interface\\AddOns\\ReQuest\\Fonts\\allods_west.ttf", 10, "OUTLINE")
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
        xpText:SetFont("Interface\\AddOns\\ReQuest\\Fonts\\allods_west.ttf", 10, "OUTLINE")
        xpText:SetText("|cFF00FF00Награда Опит:|r " .. xpReward .. " XP")
        xpText:SetPoint("TOP", scrollChild, "TOP", 0, yOffset)
        xpText:SetJustifyH("CENTER")
        xpText:SetParent(scrollChild)
        xpText:Show()
        table.insert(ReQuestTextObjects.xpTexts, xpText)
    
        yOffset = yOffset - 25 -- Space after XP reward
    end
    
    -- **🎁 Item Rewards (Brought Closer to XP & Gold)**
    local numRewards = GetNumQuestLogRewards(questID)
    if numRewards and numRewards > 0 then
        for i = 1, numRewards do
            local itemName, itemTexture, numItems, quality, isUsable, itemID, itemLevel = GetQuestLogRewardInfo(i, questID)
            if itemName and itemTexture then
                -- **Create item frame (for better centering)**
                local itemFrame = CreateFrame("Frame", nil, scrollChild)
                itemFrame:SetSize(200, 20) -- Adjust width to your liking
                itemFrame:SetPoint("TOP", scrollChild, "TOP", 0, yOffset)

                -- **Create item icon**
                local itemIcon = itemFrame:CreateTexture(nil, "ARTWORK")
                itemIcon:SetSize(20, 20) -- Slightly larger for visibility
                itemIcon:SetPoint("LEFT", itemFrame, "LEFT", 0, 0) -- Left within the frame
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
                local itemText = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                itemText:SetFont("Interface\\AddOns\\ReQuest\\Fonts\\allods_west.ttf", 10, "OUTLINE")
                itemText:SetText(rarityColor .. itemName .. "|r x" .. numItems)
                itemText:SetPoint("LEFT", itemIcon, "RIGHT", 5, 0)

                -- Store elements
                table.insert(ReQuestTextObjects.objectiveTexts, itemText)
                table.insert(ReQuestTextObjects.itemIcons, itemIcon)

                yOffset = yOffset - 25 -- Adjust spacing for multiple rewards
            end
        end
    end

    -- 🏆 Selectable Rewards (Now Near XP & Gold, Aligned to Left)
    local numChoices = GetNumQuestLogChoices(questID) -- Get the count of selectable rewards
    if numChoices and numChoices > 0 then
        -- Add a text label for clarity
        local chooseText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        chooseText:SetFont("Interface\\AddOns\\ReQuest\\Fonts\\allods_west.ttf", 10, "OUTLINE")
        chooseText:SetText("|cFFFFCC00Възможни Награди:|r")
        chooseText:SetPoint("TOP", scrollChild, "TOP", 0, yOffset) -- Centered horizontally
        chooseText:Show()
        table.insert(ReQuestTextObjects.objectiveTexts, chooseText)

        yOffset = yOffset - 20 -- Space before choices

        for i = 1, numChoices do
            local itemName, itemTexture, numItems, quality, isUsable, itemID, itemLevel = GetQuestLogChoiceInfo(i, questID)

            if itemName and itemTexture then
                -- Create the item icon
                local itemIcon = scrollChild:CreateTexture(nil, "ARTWORK")
                itemIcon:SetSize(32, 32) -- Bigger icons
                itemIcon:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset) -- Align to left
                itemIcon:SetTexture(itemTexture)
                itemIcon:Show()

                -- Tooltip on hover
                itemIcon:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetHyperlink("item:" .. itemID) -- Load full item info from WoW
                    GameTooltip:Show()
                end)
                itemIcon:SetScript("OnLeave", function()
                    GameTooltip:Hide()
                end)

                -- Create the item name text
                local itemText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                itemText:SetFont("Interface\\AddOns\\ReQuest\\Fonts\\allods_west.ttf", 10, "OUTLINE")

                -- Add quality color based on item rarity
                local rarityColor = ITEM_QUALITY_COLORS[quality] and ITEM_QUALITY_COLORS[quality].hex or "|cFFFFFFFF"
                itemText:SetText(rarityColor .. itemName .. "|r x" .. numItems)
                itemText:SetPoint("LEFT", itemIcon, "RIGHT", 5, 0) -- Align text next to icon
                itemText:Show()

                -- Store them to be hidden later
                table.insert(ReQuestTextObjects.objectiveTexts, itemText)
                table.insert(ReQuestTextObjects.itemIcons, itemIcon)

                yOffset = yOffset - 40 -- Adjust spacing between items
            else
                print(" Missing item data for selectable reward " .. i)
            end
        end
    end

    scrollChild:SetHeight(math.abs(yOffset) + 20)
    scrollFrame:UpdateScrollChildRect()
    
    -- Save current quest ID
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

    for _, obj in ipairs(ReQuestTextObjects.subhelpTexts or {}) do
        obj:Hide() -- Hide all previous item icons
    end
    ReQuestTextObjects.subhelpTexts = {}
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
refreshButton:SetSize(90, 27) -- 10% smaller
refreshButton:SetPoint("BOTTOMRIGHT", ReQuestFrame, "BOTTOMRIGHT", -10, 8)
refreshButton:SetText("Назад")
refreshButton:SetScript("OnClick", function()
    UpdateQuestLog()
end)

-- Abandon Button
local abandonButton = CreateFrame("Button", "AbandonQuestButton", ReQuestFrame, "UIPanelButtonTemplate")
abandonButton:SetSize(90, 27) -- 10% smaller
abandonButton:SetPoint("BOTTOMLEFT", ReQuestFrame, "BOTTOMLEFT", 10, 8)
abandonButton:SetText("Махни задача")
abandonButton:SetScript("OnClick", function()
    AbandonCurrentQuest()
end)

-----------------------------------------------------
local thumbnailURL = "Interface\\AddOns\\ReQuest\\Icons\\youtube-logo.png"
-- Create YouTube Button (Persistent)
local youtubeButton = CreateFrame("Button", "YouTubeButton", ReQuestFrame, nil)
youtubeButton:SetSize(50, 15)
youtubeButton:SetPoint("TOPLEFT", ReQuestFrame, "TOPLEFT", 5, -25) -- Anchor to top-left with slight padding
youtubeButton:Hide() -- Hide initially

-- Create the texture for the thumbnail
youtubeButton.icon = youtubeButton:CreateTexture(nil, "ARTWORK")
youtubeButton.icon:SetSize(18, 18)
youtubeButton.icon:SetPoint("CENTER", youtubeButton, "CENTER", 0, 0) -- Center the icon inside the button
youtubeButton.icon:SetTexture(thumbnailURL)

-- Set up the button tooltip
youtubeButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("|cFFFF0000YouTube Guide|r\nКликни, за да гледаш видео", 1, 1, 1)
    GameTooltip:Show()
end)
youtubeButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- Set up click behavior (Opens YouTube popup)
youtubeButton:SetScript("OnClick", function()
    local videoID = GetQuestVideoURL(viewedQuestID)
    if videoID then
        local url = "https://www.youtube.com/watch?v=" .. videoID
        StaticPopupDialogs["REQUEST_YOUTUBE"] = {
            text = "Копирайте връзката в браузър:",
            button1 = "Close",
            OnShow = function(self)
                self.editBox:SetText(url)
                self.editBox:HighlightText()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            hasEditBox = true,
            editBoxWidth = 260,
            enterClicksFirstButton = true,
        }
        StaticPopup_Show("REQUEST_YOUTUBE")
    else
        print("|cFFFF0000[ReQuest] No YouTube guide available for this quest.|r")
    end
end)

-- Function to Show or Hide the YouTube Button Based on Quest Data
local function UpdateYouTubeButton(questID)
    local videoID = GetQuestVideoURL(questID)
    if videoID then
        youtubeButton:Show() -- Show button if video exists
    else
        youtubeButton:Hide() -- Hide button if no video exists
    end
end

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
        refreshButton:Show()
        abandonButton:Show()
        youtubeButton:Show()
        --trackButton:Show()
        ClearScrollChild()
        UpdateReQuestWindow(savedQuestID)
    else
        UpdateQuestLog()
        refreshButton:Hide()
        abandonButton:Hide()
        youtubeButton:Hide()
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

