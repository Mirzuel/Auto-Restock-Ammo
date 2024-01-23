AutoAmmo_Quantity = 0
local ammoID;
local ammoTable = {}
ammoTable[LE_ITEM_WEAPON_GUNS] = {
    [1] =  2516,
    [10] = 2519,
    [25] = 3033,
    [40] = 11284,
}
ammoTable[LE_ITEM_WEAPON_BOWS] = {
    [1] = 2512,
    [10] = 2515,
    [25] = 3030,
    [40] = 11285,
}
ammoTable[LE_ITEM_WEAPON_CROSSBOW] = ammoTable[LE_ITEM_WEAPON_BOWS]

function AutoAmmo_ItemToBuy()
    local rangedItemID = GetInventoryItemID("player", 18)
    if rangedItemID ~= nil then
        local subclassID  = select(7, GetItemInfoInstant(rangedItemID))
        ammoID = nil
        local playerLevel = UnitLevel("PLAYER");
        if subclassID == LE_ITEM_WEAPON_BOWS or subclassID == LE_ITEM_WEAPON_GUNS or subclassID == LE_ITEM_WEAPON_CROSSBOW then
            while (playerLevel > 0) and (ammoID == nil) do
                ammoID = ammoTable[subclassID][playerLevel]
                playerLevel = playerLevel - 1;
            end
        end
    else
        ammoID = nil;
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("MERCHANT_SHOW")
frame:SetScript("OnEvent", function(self, event, ...)
    AutoAmmo_ItemToBuy();
    local i = GetMerchantNumItems();
    
    -- Tilføj denne betingelse for at kontrollere, om vendor sælger ammunition
    local vendorSellsAmmo = false
    while i > 0 do
        local merchItemID = GetMerchantItemID(i)
        if merchItemID == ammoID then
            vendorSellsAmmo = true
            break
        end
        i = i - 1
    end

    local toBuy = AutoAmmo_Quantity - GetItemCount(ammoID)
    
    -- Tjek om vendor sælger ammunition, før dialogen vises
    if vendorSellsAmmo and toBuy > 0 and ammoID ~= nil then
        local dialog = AutoAmmo_ShowConfirmationDialog()
        if dialog and dialog.data then
            i = GetMerchantNumItems(); -- Nulstil i, så vi kan iterere igen
            while i > 0 and toBuy > 0 and ammoID ~= nil do
                local merchItemID = GetMerchantItemID(i)
                if merchItemID == ammoID then
                    while (toBuy > 200) do
                        BuyMerchantItem(i, 200)
                        toBuy = toBuy - 200
                    end
                    if toBuy > 0 then
                        BuyMerchantItem(i, toBuy)
                        toBuy = 0
                    end
                end
                i = i - 1
            end
        end
    end
end)

function AutoAmmo_ShowConfirmationDialog()
    local dialog = StaticPopup_Show("AUTOAMMO_CONFIRM_DIALOG")
    if dialog then
        dialog.data = nil -- Nulstil datafeltet, så vi er sikre på, det er klart.
    end
    return dialog
end

function AutoAmmo_Command(arg1)
    AutoAmmo_ItemToBuy();
    if arg1 == "" then
        StaticPopup_Show("AUTOAMMO_DIALOG")
    elseif tonumber(arg1) ~= nil then
        AutoAmmo_Quantity = tonumber(arg1)
        if ammoID ~= nil then
            local ammoName = select(1, GetItemInfo(ammoID))
            if ammoName == nil then
                ammoName = "ammo"
            end
            print("Stockpiling " .. AutoAmmo_Quantity .. " " .. ammoName)
        else
            print("Stockpiling " .. AutoAmmo_Quantity .. " ammo when you get a weapon that needs it.")
        end
    else
        print("Available command is /aa <number>")
    end
end

SLASH_AUTOAMMO1 = "/aa"
SLASH_AUTOAMMO2 = "/autoammo"
SlashCmdList.AUTOAMMO = AutoAmmo_Command

StaticPopupDialogs["AUTOAMMO_DIALOG"] = {
    text = "Enter quantity:",
    button1 = "OK",
    button2 = "Cancel",
    OnAccept = function(self)
        local quantity = tonumber(self.editBox:GetText())
        if quantity then
            AutoAmmo_Quantity = quantity
            local ammoName = select(1, GetItemInfo(ammoID))
            if ammoName == nil then
                ammoName = "ammo"
            end
            print("Stockpiling " .. AutoAmmo_Quantity .. " " .. ammoName)
        else
            print("Invalid quantity.")
        end
    end,
    EditBoxOnEnterPressed = function(self)
        local quantity = tonumber(self:GetText())
        if quantity then
            AutoAmmo_Quantity = quantity
            local ammoName = select(1, GetItemInfo(ammoID))
            if ammoName == nil then
                ammoName = "ammo"
            end
            print("Stockpiling " .. AutoAmmo_Quantity .. " " .. ammoName)
        else
            print("Invalid quantity.")
        end
        self:GetParent():Hide()
    end,
    hasEditBox = true,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["AUTOAMMO_CONFIRM_DIALOG"] = {
    text = "Do you want to purchase ammo?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function(self)
        self.data = true -- Tildel "true" til datafeltet for at indikere, at brugeren trykkede "Yes"
        -- Resten af købslogikken skal flyttes herfra til OnAccept
        local i = GetMerchantNumItems();
        local toBuy = AutoAmmo_Quantity - GetItemCount(ammoID)
        while i > 0 and toBuy > 0 and ammoID ~= nil do
            local merchItemID = GetMerchantItemID(i)
            if merchItemID == ammoID then
                while (toBuy > 200) do
                    BuyMerchantItem(i, 200)
                    toBuy = toBuy - 200
                end
                if toBuy > 0 then
                    BuyMerchantItem(i, toBuy)
                    toBuy = 0
                end
            end
            i = i - 1;
        end
    end,
    OnCancel = function(self)
        self.data = false -- Tildel "false" til datafeltet for at indikere, at brugeren trykkede "No"
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

