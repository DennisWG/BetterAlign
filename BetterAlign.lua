--[[
	Author: Dennis Werner Garske (DWG)
	License: MIT License
]]

local _G = _G or getfenv(0);
local BetterAlign = _G.BetterAlign or {};
_G.BetterAlign = BetterAlign;

-- The amount of squares fully displayed horizontally on the screen
BetterAlign.boxSize = 32;
-- Locks or unlocks the helper bars
BetterAlign.locked = false;

local function round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

-- Registers various events for the given frame to enable it's behaviour
-- frame: The helper bar frame
-- horizontal: true if helper bar is horizontal, false otherwhise
function BetterAlign.RegisterEventsForFrame(frame, horizontal)
    -- Highlight on mouse enter
    frame:SetScript("OnEnter", function(self)
        getglobal(self:GetName().."Texture"):SetColorTexture(0, 0, 1, 1);
        getglobal(self.sibling:GetName().."Texture"):SetColorTexture(0, 0, 1, 1);
    end);
    
    -- Unhighlight on mouse exit
    frame:SetScript("OnLeave", function(self)
        if self.dragging then
            return;
        end
        getglobal(self:GetName().."Texture"):SetColorTexture(0, 1, 0, 1);
        getglobal(self.sibling:GetName().."Texture"):SetColorTexture(0, 1, 0, 1);
    end);

    -- Update position and color when dragging
    frame:SetScript("OnDragStart", function(self)
        if BetterAlign.locked then
            return;
        end
        
        self.dragging = true;
        getglobal(self:GetName().."Texture"):SetColorTexture(0, 0, 1, 1);
        getglobal(self.sibling:GetName().."Texture"):SetColorTexture(0, 0, 1, 1);
        -- Follow mouse and mirror movement on sibling bar
        self:SetScript("OnUpdate", function(self)
            local scale, x, y = UIParent:GetEffectiveScale(), GetCursorPosition();
            local xdiff, ydiff;
            local screenMiddle;
            local anchor;
            
            if horizontal then
                xdiff = 0;
                screenMiddle = GetScreenHeight() / 2;
                ydiff = y / scale - screenMiddle;
                anchor = "BOTTOM";
            else
                ydiff = 0;
                screenMiddle = GetScreenWidth() / 2;
                xdiff = x / scale - screenMiddle;
                anchor = "LEFT";
            end

            local x1 = xdiff + screenMiddle;
            local x2 = -xdiff + screenMiddle;

            if x1 > screenMiddle then
                x1 = x1 - self:GetSize()
            else
                x2 = x2 - self:GetSize()
            end

            self:SetPoint(anchor, x1, ydiff + screenMiddle);
            self.sibling:SetPoint(anchor, x2, -ydiff + screenMiddle);
            self:SetUserPlaced(true);
            self.sibling:SetUserPlaced(true);
        end);
    end);
    
    -- Restore color when finished dragging
    frame:SetScript("OnDragStop", function(self)
        self.dragging = nil;
        getglobal(self:GetName().."Texture"):SetColorTexture(0, 1, 0, 1);
        getglobal(self.sibling:GetName().."Texture"):SetColorTexture(0, 1, 0, 1);
        self:SetScript("OnUpdate", nil);
    end);
end

-- Handles the button press of the "BetterAlignButtonAdd"
-- Adds two new helper bars to the player's screen
function BetterAlignOptionsPanel:AddButton_OnClick()
    BetterAlign.Parent = BetterAlign.Parent or CreateFrame('Frame', nil, UIParent);
	BetterAlign.Parent:SetAllPoints(UIParent);

    BetterAlign.Parent.Children = BetterAlign.Parent.Children or {};
    
    local num = #BetterAlign.Parent.Children;
    local name1 = "MoveFrame"..num;
    local name2 = "MoveFrame"..(num + 1);
    local frame1, frame2;
    local horizontal = BetterAlignCheckButtonHorizontal:GetChecked();
    
    if horizontal then
        frame1 = CreateFrame("Frame", name1, BetterAlign.Parent, "BetterAlignHorizontalFrame");
        frame2 = CreateFrame("Frame", name2, BetterAlign.Parent, "BetterAlignHorizontalFrame");
    else
        frame1 = CreateFrame("Frame", name1, BetterAlign.Parent, "BetterAlignVerticalFrame");
        frame2 = CreateFrame("Frame", name2, BetterAlign.Parent, "BetterAlignVerticalFrame");
    end

    table.insert(BetterAlign.Parent.Children, frame1);
    table.insert(BetterAlign.Parent.Children, frame2);
    
    frame1.sibling = frame2;
    frame2.sibling = frame1;
        
    BetterAlign.RegisterEventsForFrame(frame1, horizontal);
    BetterAlign.RegisterEventsForFrame(frame2, horizontal);
end

-- Handles the check button press of the "BetterAlignCheckButtonHide"
-- Hides all helper bars on the player's screen
function BetterAlignOptionsPanel:Hide_OnClick(hide)
    if not BetterAlign.Parent then
        return;
    end
    
    for k, v in pairs(BetterAlign.Parent.Children) do
        if BetterAlignCheckButtonHide:GetChecked() or hide then
            v:Hide();
        else
            v:Show();
        end
    end
end

-- Handles the check button press of the "BetterAlignCheckButtonGrid"
-- Shows or hides the old Align grid
function BetterAlignOptionsPanel:Grid_OnClick()
    if BetterAlignCheckButtonGrid:GetChecked() then
        BetterAlign.ShowGrid();
    else
        BetterAlign.HideGrid();
    end
end

-- Handles the check button press of the "BetterAlignCheckButtonLock"
-- Locks the helper bars in place or unlocks them
function BetterAlignOptionsPanel:Lock_OnClick()
    BetterAlign.locked = BetterAlignCheckButtonLock:GetChecked();
end

-- Handles the OnClick event of the "BetterAlignButtonClose"
-- Closes the BetterAlignOptionsPanel
function BetterAlignOptionsPanel:CloseButton_OnClick()
    BetterAlignOptionsPanel:Hide();
end

-- Handles the OnValueChanged event of the "BetterAlignGridSize"
-- Sets the old Align's grid size
function BetterAlignOptionsPanel:GridSize_OnValueChanged()
    local name = BetterAlignGridSize:GetName();
    local value = BetterAlignGridSize:GetValue();
    
	getglobal(name.. "Text"):SetText(value);
    BetterAlign.boxSize = value;
    
    if BetterAlign.grid and BetterAlign.grid:IsVisible() then
        BetterAlign.ShowGrid();
    end
end

-- Shows the old Align grid
-- remarks: Also creates the grid if it hasn't been created yet
function BetterAlign.ShowGrid()
	if not BetterAlign.grid then
        BetterAlign.CreateGrid()
	elseif BetterAlign.grid.boxSize ~= BetterAlign.boxSize then
        BetterAlign.grid:Hide()
        BetterAlign.CreateGrid()
    else
		BetterAlign.grid:Show()
	end
end

-- Hides the old Align grid
function BetterAlign.HideGrid()
	if BetterAlign.grid then
		BetterAlign.grid:Hide()
	end
end

-- Creates the old Align grid
function BetterAlign.CreateGrid()
	BetterAlign.grid = CreateFrame('Frame', nil, UIParent) 
	BetterAlign.grid.boxSize = BetterAlign.boxSize 
	BetterAlign.grid:SetAllPoints(UIParent) 

	local size = 2 
	local width = GetScreenWidth()
	local ratio = width / GetScreenHeight()
	local height = GetScreenHeight() * ratio

	local wStep = width / BetterAlign.boxSize
	local hStep = height / BetterAlign.boxSize

	for i = 0, BetterAlign.boxSize do 
		local tx = BetterAlign.grid:CreateTexture(nil, 'BACKGROUND') 
		if i == BetterAlign.boxSize / 2 then 
			tx:SetColorTexture(1, 0, 0, 0.5) 
		else 
			tx:SetColorTexture(0, 0, 0, 0.5) 
		end 
		tx:SetPoint("TOPLEFT", BetterAlign.grid, "TOPLEFT", i*wStep - (size/2), 0) 
		tx:SetPoint('BOTTOMRIGHT', BetterAlign.grid, 'BOTTOMLEFT', i*wStep + (size/2), 0) 
	end 
	height = GetScreenHeight()
	
	do
		local tx = BetterAlign.grid:CreateTexture(nil, 'BACKGROUND') 
		tx:SetColorTexture(1, 0, 0, 0.5)
		tx:SetPoint("TOPLEFT", BetterAlign.grid, "TOPLEFT", 0, -(height/2) + (size/2))
		tx:SetPoint('BOTTOMRIGHT', BetterAlign.grid, 'TOPRIGHT', 0, -(height/2 + size/2))
	end
    
	for i = 1, math.floor((height/2)/hStep) do
		local tx = BetterAlign.grid:CreateTexture(nil, 'BACKGROUND') 
		tx:SetColorTexture(0, 0, 0, 0.5)
		
		tx:SetPoint("TOPLEFT", BetterAlign.grid, "TOPLEFT", 0, -(height/2+i*hStep) + (size/2))
		tx:SetPoint('BOTTOMRIGHT', BetterAlign.grid, 'TOPRIGHT', 0, -(height/2+i*hStep + size/2))
		
		tx = BetterAlign.grid:CreateTexture(nil, 'BACKGROUND') 
		tx:SetColorTexture(0, 0, 0, 0.5)
		
		tx:SetPoint("TOPLEFT", BetterAlign.grid, "TOPLEFT", 0, -(height/2-i*hStep) + (size/2))
		tx:SetPoint('BOTTOMRIGHT', BetterAlign.grid, 'TOPRIGHT', 0, -(height/2-i*hStep + size/2))
	end
end

SLASH_BETTERALIGN1 = "/betteralign"
SLASH_BETTERALIGN2 = "/balign"
SLASH_BETTERALIGN3 = "/ba"
SlashCmdList["BETTERALIGN"] = function()
    if BetterAlignOptionsPanel:IsVisible() then
        BetterAlignOptionsPanel:Hide();
        BetterAlignOptionsPanel:Hide_OnClick(true);
    else
        BetterAlignOptionsPanel:Show();
        BetterAlignOptionsPanel:Hide_OnClick(false);
    end
end
