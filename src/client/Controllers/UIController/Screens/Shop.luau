--!strict

-- Shop screen. Pairs with assets/ui/Shop.model.json. Conversion patterns, all data-driven:
--   Deals tab: a daily discounted item with a countdown, plus the best coin pack and a pass.
--   Items: rarity cards; "Need N" when short, which jumps to the Coins tab.
--   Coins: tiered Robux packs with POPULAR / BEST VALUE badges and bonus labels.
--   Passes: permanent perks.
-- The server decides every purchase and price; this screen only displays and requests.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local DailyDeal = require(ReplicatedStorage.Utils.DailyDeal)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Monetization = require(ReplicatedStorage.Config.Monetization)
local Packets = require(ReplicatedStorage.Packets)
local ShopCatalog = require(ReplicatedStorage.Config.ShopCatalog)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Effects = require(script.Parent.Parent.Effects)
local Find = require(script.Parent.Parent.Find)
local Types = require(script.Parent.Parent.Types)

local ROBUX = "\u{E002}"
-- 🪙 does not render in Roblox fonts; 💰 does.
local COIN = "💰"
local TABS = { "Featured", "Items", "Coins", "Passes" }
local MESSAGES: { [string]: string } = {
	Ok = "Purchased!",
	NotEnoughCash = "Not enough coins.",
	AlreadyOwned = "You already own this.",
	UnknownItem = "This item is not for sale.",
	NotLoaded = "Still loading, try again.",
}
local SOON = "Coming soon: set its id in Config/Monetization."

-- Card gradients per rarity (top, bottom).
local RARITY: { [string]: { Color3 } } = {
	Common = { Color3.new(0.55, 0.6, 0.72), Color3.new(0.32, 0.36, 0.48) },
	Rare = { Color3.new(0.3, 0.6, 1), Color3.new(0.15, 0.3, 0.8) },
	Epic = { Color3.new(0.75, 0.4, 1), Color3.new(0.42, 0.16, 0.78) },
	Legendary = { Color3.new(1, 0.8, 0.25), Color3.new(0.92, 0.42, 0.08) },
}
local BUTTON: { [string]: { Color3 } } = {
	Coins = { Color3.new(1, 0.88, 0.3), Color3.new(1, 0.62, 0.12) },
	Robux = { Color3.new(0.42, 0.92, 0.42), Color3.new(0.13, 0.62, 0.22) },
	Short = { Color3.new(1, 0.45, 0.45), Color3.new(0.8, 0.18, 0.24) },
	Owned = { Color3.new(0.55, 0.58, 0.65), Color3.new(0.35, 0.37, 0.44) },
	Tab = { Color3.new(0.3, 0.5, 1), Color3.new(0.18, 0.28, 0.75) },
	ActiveTab = { Color3.new(1, 0.9, 0.35), Color3.new(1, 0.65, 0.15) },
}

local function paint(object: Instance, colors: { Color3 })
	local gradient = object:FindFirstChildOfClass("UIGradient")
	if gradient then
		gradient.Color = ColorSequence.new(colors[1], colors[2])
	end
end

local function setTexts(parent: Instance, fields: { [string]: string })
	for field, value in fields do
		local label = parent:FindFirstChild(field)
		if label and label:IsA("TextLabel") then
			label.Text = value
		end
	end
end

-- Buttons carry their text in a child "Label" (a UIGradient would tint the button's own text).
local function setLabel(button: Instance, value: string)
	local label = button:FindFirstChild("Label")
	if label and label:IsA("TextLabel") then
		label.Text = value
	end
end

local function clock(seconds: number): string
	return string.format("%02d:%02d:%02d", seconds // 3600, seconds % 3600 // 60, seconds % 60)
end

local function sorted<T>(map: { [string]: T }, order: (T) -> number): { { Name: string, Value: T } }
	local list = {}
	for name, value in map do
		table.insert(list, { Name = name, Value = value })
	end
	table.sort(list, function(a, b)
		return order(a.Value) < order(b.Value)
	end)
	return list
end

local Shop = {}

function Shop.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local controllers = context.Controllers
	local data = controllers.DataController
	local player = Players.LocalPlayer

	local dim: Frame? = Find(gui, "Dim", "Frame")
	local panel: Frame? = Find(gui, "Panel", "Frame")
	local pages: Frame? = Find(gui, "Pages", "Frame")
	local tabs: Frame? = Find(gui, "Tabs", "Frame")
	local templates = gui:FindFirstChild("Templates", true)
	-- Look up by path where names repeat inside templates (Amount, Buy, Icon...).
	local header = panel and panel:FindFirstChild("Header")
	local balanceFrame = header and header:FindFirstChild("Balance")
	local balance: TextLabel? = if balanceFrame then Find(balanceFrame, "Amount", "TextLabel") else nil
	local close: TextButton? = if header then Find(header, "Close", "TextButton") else nil
	local deal: Frame? = Find(gui, "Deal", "Frame")
	if not (panel and pages and tabs and templates and deal) then
		warn("[Shop] Shop.model.json is missing required elements; shop disabled")
		return {
			Modal = true,
			StartsOpen = false,
			Open = function() end,
			Close = function() end,
			Destroy = function()
				trove:Destroy()
			end,
		}
	end
	local templateFolder: Instance = templates
	local dealCard: Frame = deal
	local pagesFrame: Frame = pages
	local busy = false
	local timerThread: thread? = nil
	-- Re-renders every card from current data; filled as cards are built.
	local refreshers: { () -> () } = {}
	local function refreshAll()
		for _, refresh in refreshers do
			refresh()
		end
	end

	local function today(): number
		return DailyDeal.Today(workspace:GetServerTimeNow())
	end
	local function priceOf(item: ShopCatalog.Item): number
		return DailyDeal.Price(item, today(), ShopCatalog.Items, GameConfig.ShopDealDiscount)
	end
	local function cash(): number
		local value = data:Get({ "Cash" })
		return if type(value) == "number" then value else 0
	end
	local function owns(itemId: string): boolean
		return data:Get({ "Inventory", itemId }) == true
	end

	-- Tabs ------------------------------------------------------------------
	local current = "Featured"
	local function select(name: string)
		current = name
		for _, tabName in TABS do
			local page = pagesFrame:FindFirstChild(tabName)
			local tab = tabs:FindFirstChild(tabName)
			if page and page:IsA("GuiObject") then
				page.Visible = tabName == name
			end
			if tab and tab:IsA("TextButton") then
				paint(tab, if tabName == name then BUTTON.ActiveTab else BUTTON.Tab)
			end
		end
		local page = pagesFrame:FindFirstChild(name)
		if page and page:IsA("GuiObject") then
			Effects.Pop(page, 0.96)
		end
	end
	for _, tabName in TABS do
		local tab = tabs:FindFirstChild(tabName)
		if tab and tab:IsA("TextButton") then
			Effects.Press(trove, tab)
			trove:Connect(tab.Activated, function()
				controllers.SoundController:PlaySfx("Click")
				select(tabName)
			end)
		end
	end

	-- Buying with coins -----------------------------------------------------
	local function buyItem(item: ShopCatalog.Item, card: GuiObject)
		if busy then
			return
		end
		if owns(item.Id) then
			context.Notify(MESSAGES.AlreadyOwned)
			return
		end
		local missing = priceOf(item) - cash()
		if missing > 0 then
			-- Conversion path: show exactly what is missing and where to get it.
			context.Notify(`You need {missing} more coins. Grab a pack!`)
			select("Coins")
			return
		end
		busy = true
		task.spawn(function()
			local ok, reason = Packets.BuyItem:Fire(item.Id)
			busy = false
			if ok == true then
				controllers.SoundController:PlaySfx("Purchase")
				Effects.Pop(card, 1.15)
			end
			context.Notify(
				if ok == nil then "No answer, try again." else MESSAGES[reason] or tostring(reason)
			)
		end)
	end

	local function renderBuy(button: TextButton, item: ShopCatalog.Item)
		if owns(item.Id) then
			setLabel(button, "Owned ✓")
			paint(button, BUTTON.Owned)
			return
		end
		local price = priceOf(item)
		local missing = price - cash()
		if missing > 0 then
			setLabel(button, `Need {COIN} {missing}`)
			paint(button, BUTTON.Short)
		else
			setLabel(button, `{COIN} {price}`)
			paint(button, BUTTON.Coins)
		end
	end

	-- Robux offers ----------------------------------------------------------
	local function robuxPrice(button: TextButton, id: number, infoType: Enum.InfoType)
		if id == 0 then
			setLabel(button, "Soon")
			return
		end
		setLabel(button, "...")
		trove:Add(task.spawn(function()
			local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, id, infoType)
			if ok and type(info) == "table" and type(info.PriceInRobux) == "number" then
				setLabel(button, `{ROBUX} {info.PriceInRobux}`)
			else
				setLabel(button, "Buy")
			end
		end))
	end

	local function buildPack(
		name: string,
		pack: Monetization.CoinPack,
		parent: Instance,
		order: number
	): Frame?
		local template = templateFolder:FindFirstChild("PackTemplate")
		if not (template and template:IsA("Frame")) then
			return nil
		end
		local card = template:Clone()
		card.Name = name
		card.LayoutOrder = order
		card.Visible = true
		local badge = card:FindFirstChild("Badge")
		if badge and badge:IsA("TextLabel") then
			badge.Visible = pack.Badge ~= nil
			badge.Text = pack.Badge or ""
		end
		local icon = card:FindFirstChild("Icon")
		if icon and icon:IsA("TextLabel") then
			icon.Text = pack.Icon
		end
		local amount = card:FindFirstChild("Amount")
		if amount and amount:IsA("TextLabel") then
			amount.Text = `{COIN} {pack.Coins}`
		end
		local bonus = card:FindFirstChild("Bonus")
		if bonus and bonus:IsA("TextLabel") then
			bonus.Text = pack.Bonus or ""
		end
		local buy = card:FindFirstChild("Buy")
		if buy and buy:IsA("TextButton") then
			robuxPrice(buy, pack.Id, Enum.InfoType.Product)
			Effects.Press(trove, buy)
			trove:Connect(buy.Activated, function()
				if pack.Id == 0 then
					context.Notify(SOON)
					return
				end
				MarketplaceService:PromptProductPurchase(player, pack.Id)
			end)
		end
		card.Parent = parent
		trove:Add(card)
		return card
	end

	local function buildPass(
		name: string,
		pass: Monetization.GamePass,
		parent: Instance,
		order: number
	): Frame?
		local template = templateFolder:FindFirstChild("PassTemplate")
		if not (template and template:IsA("Frame")) then
			return nil
		end
		local card = template:Clone()
		card.Name = name
		card.LayoutOrder = order
		card.Visible = true
		setTexts(
			card,
			{ Icon = pass.Icon, PassName = pass.Name, Description = pass.Description } :: { [string]: string }
		)
		local buy = card:FindFirstChild("Buy")
		if buy and buy:IsA("TextButton") then
			local attribute = `Pass_{name}`
			local function render()
				if player:GetAttribute(attribute) == true then
					setLabel(buy, "Owned ✓")
					paint(buy, BUTTON.Owned)
				else
					paint(buy, BUTTON.Robux)
					robuxPrice(buy, pass.Id, Enum.InfoType.GamePass)
				end
			end
			render()
			trove:Connect(player:GetAttributeChangedSignal(attribute), render)
			Effects.Press(trove, buy)
			trove:Connect(buy.Activated, function()
				if player:GetAttribute(attribute) == true then
					return
				end
				if pass.Id == 0 then
					context.Notify(SOON)
					return
				end
				MarketplaceService:PromptGamePassPurchase(player, pass.Id)
			end)
		end
		card.Parent = parent
		trove:Add(card)
		return card
	end

	-- Items page ------------------------------------------------------------
	local itemsPage = pagesFrame:FindFirstChild("Items")
	local itemTemplate = templateFolder:FindFirstChild("ItemTemplate")
	if itemsPage and itemTemplate and itemTemplate:IsA("Frame") then
		for _, item in ShopCatalog.Items do
			local card = itemTemplate:Clone()
			card.Name = item.Id
			card.LayoutOrder = item.Order
			card.Visible = true
			paint(card, RARITY[item.Rarity] or RARITY.Common)
			setTexts(
				card,
				{ Icon = item.Icon, ItemName = item.Name, RarityLabel = string.upper(item.Rarity) }
			)
			local dealTag = card:FindFirstChild("DealTag")
			local buy = card:FindFirstChild("Buy")
			if buy and buy:IsA("TextButton") then
				Effects.Press(trove, buy)
				trove:Connect(buy.Activated, function()
					buyItem(item, card)
				end)
				table.insert(refreshers, function()
					renderBuy(buy, item)
					if dealTag and dealTag:IsA("TextLabel") then
						dealTag.Text = `-{math.round(GameConfig.ShopDealDiscount * 100)}%`
						dealTag.Visible = DailyDeal.ItemId(today(), ShopCatalog.Items) == item.Id
							and not owns(item.Id)
					end
				end)
			end
			card.Parent = itemsPage
			trove:Add(card)
		end
	end

	-- Coins and Passes pages ------------------------------------------------
	local coinsPage = pagesFrame:FindFirstChild("Coins")
	local packs = sorted(Monetization.CoinPacks, function(pack)
		return pack.Order
	end)
	if coinsPage then
		for index, entry in packs do
			buildPack(entry.Name, entry.Value, coinsPage, index)
		end
	end
	local passesPage = pagesFrame:FindFirstChild("Passes")
	local passes = sorted(Monetization.GamePasses, function(pass)
		return pass.Order
	end)
	if passesPage then
		for index, entry in passes do
			buildPass(entry.Name, entry.Value, passesPage, index)
		end
	end

	-- Featured page: daily deal, best pack, first pass ----------------------
	-- The two biggest packs side by side (anchoring), then the first pass full width.
	local featuredPage = dealCard.Parent
	local picks = featuredPage and featuredPage:FindFirstChild("Picks")
	if picks then
		for index = math.max(1, #packs - 1), #packs do
			buildPack(packs[index].Name, packs[index].Value, picks, index)
		end
	end
	local passPick = featuredPage and featuredPage:FindFirstChild("PassPick")
	if passPick and passes[1] then
		buildPass(passes[1].Name, passes[1].Value, passPick, 1)
	end
	local shine = dealCard:FindFirstChild("Shine")
	local shineGradient = shine and shine:FindFirstChildOfClass("UIGradient")
	if shineGradient then
		Effects.Shine(trove, shineGradient)
	end
	local dealBuy = dealCard:FindFirstChild("Buy")
	if dealBuy and dealBuy:IsA("TextButton") then
		Effects.Press(trove, dealBuy)
		trove:Connect(dealBuy.Activated, function()
			local item = ShopCatalog.ById[DailyDeal.ItemId(today(), ShopCatalog.Items) or ""]
			if item then
				buyItem(item, dealCard)
			end
		end)
	end
	table.insert(refreshers, function()
		local item = ShopCatalog.ById[DailyDeal.ItemId(today(), ShopCatalog.Items) or ""]
		if not item then
			dealCard.Visible = false
			return
		end
		setTexts(dealCard, {
			Icon = item.Icon,
			ItemName = item.Name,
			OldPrice = `<s>{COIN} {item.Price}</s>`,
			Discount = `-{math.round(GameConfig.ShopDealDiscount * 100)}%`,
		})
		if dealBuy and dealBuy:IsA("TextButton") then
			renderBuy(dealBuy, item)
		end
	end)

	-- Responsive grid: 3 columns on wide screens, 2 on phones -----------------
	local function layout()
		local columns = if pagesFrame.AbsoluteSize.X >= 520 then 3 else 2
		local width = if columns == 3 then 0.32 else 0.48
		for _, pageName in { "Items", "Coins" } do
			local page = pagesFrame:FindFirstChild(pageName)
			local grid = page and page:FindFirstChildOfClass("UIGridLayout")
			if grid then
				grid.CellSize = UDim2.new(width, 0, 0, grid.CellSize.Y.Offset)
			end
		end
	end
	layout()
	trove:Connect(pagesFrame:GetPropertyChangedSignal("AbsoluteSize"), layout)

	-- Live data -------------------------------------------------------------
	trove:Add(data:Observe({ "Cash" }, function(value: any)
		if balance then
			balance.Text = `{COIN} {if type(value) == "number" then value else "..."}`
		end
		refreshAll()
	end))
	trove:Add(data:Observe({ "Inventory" }, function()
		refreshAll()
	end))

	if close then
		Effects.Press(trove, close)
		trove:Connect(close.Activated, function()
			controllers.SoundController:PlaySfx("Click")
			context.Close("Shop")
		end)
	end
	local timer: TextLabel? = Find(dealCard, "Timer", "TextLabel")
	local panelScale = panel:FindFirstChild("Scale")

	local function stopTimer()
		if timerThread then
			task.cancel(timerThread)
			timerThread = nil
		end
	end

	select(current)

	return {
		Modal = true,
		StartsOpen = false,
		Open = function(_self: Types.Screen)
			gui.Enabled = true
			refreshAll()
			Packets.ShopOpened:Fire()
			if dim then
				dim.BackgroundTransparency = 1
				Effects.Fade(dim, 0.45)
			end
			if panelScale and panelScale:IsA("UIScale") then
				panelScale.Scale = 0.8
				TweenService:Create(
					panelScale,
					TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
					{ Scale = 1 }
				):Play()
			end
			stopTimer()
			timerThread = task.spawn(function()
				local lastDay = today()
				while true do
					if timer then
						timer.Text = `Ends in {clock(DailyDeal.SecondsLeft(workspace:GetServerTimeNow()))}`
					end
					if today() ~= lastDay then
						lastDay = today()
						refreshAll()
					end
					task.wait(1)
				end
			end)
		end,
		Close = function(_self: Types.Screen)
			stopTimer()
			gui.Enabled = false
		end,
		Destroy = function(_self: Types.Screen)
			stopTimer()
			trove:Destroy()
		end,
	}
end

return Shop
