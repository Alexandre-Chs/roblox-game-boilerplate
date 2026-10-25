--!strict

-- Promo codes and community rewards: group reward, friend invites (friends in the server
-- boost coin pickups), a favorite button and Roblox Premium. The favorite prompt only opens on
-- click: Roblox cannot tell whether the game is already a favorite, so an automatic prompt nags.
local AvatarEditorService = game:GetService("AvatarEditorService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Locale = require(ReplicatedStorage.Utils.Locale)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local UiImages = require(ReplicatedStorage.Config.UiImages)
local Find = require(script.Parent.Parent.Find)
local Types = require(script.Parent.Parent.Types)

local Rewards = {}

function Rewards.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local player = Players.LocalPlayer
	local config = GameConfig.Community
	local close: GuiButton? = Find(gui, "Close", "GuiButton")
	local codeBox: TextBox? = Find(gui, "CodeBox", "TextBox")
	local redeem: GuiButton? = Find(gui, "Redeem", "GuiButton")
	local groupRow: GuiObject? = Find(gui, "GroupRow", "GuiObject")
	local claim: GuiButton? = if groupRow then Find(groupRow, "Claim", "GuiButton") else nil
	local inviteRow: GuiObject? = Find(gui, "InviteRow", "GuiObject")
	local invite: GuiButton? = if inviteRow then Find(inviteRow, "Invite", "GuiButton") else nil
	local favoriteRow: GuiObject? = Find(gui, "FavoriteRow", "GuiObject")
	local favorite: GuiButton? = if favoriteRow then Find(favoriteRow, "Favorite", "GuiButton") else nil
	local friendsInfo: TextLabel? = if inviteRow then Find(inviteRow, "Info", "TextLabel") else nil
	local premiumRow: GuiObject? = Find(gui, "PremiumRow", "GuiObject")
	local premium: ImageButton? = if premiumRow then Find(premiumRow, "Premium", "ImageButton") else nil
	local busy = false

	local function request(call: () -> (any, any))
		if busy then
			return
		end
		busy = true
		context.Controllers.SoundController:PlaySfx("Click")
		task.spawn(function()
			local ok, message = call()
			busy = false
			if ok == nil then
				context.Notify("No answer, try again.")
			else
				context.Notify(message)
				context.Controllers.SoundController:PlaySfx(if ok then "Reward" else "Error")
			end
		end)
	end

	local function promptFavorite()
		if game.PlaceId == 0 then
			context.Notify("Publish the game to enable favorites.")
			return
		end
		pcall(
			AvatarEditorService.PromptSetFavorite,
			AvatarEditorService,
			game.PlaceId,
			Enum.AvatarItemType.Asset,
			true
		)
	end

	if close then
		trove:Connect(close.Activated, function()
			context.Close("Rewards")
		end)
	end
	if redeem and codeBox then
		local box: TextBox = codeBox
		trove:Connect(redeem.Activated, function()
			request(function()
				local ok, message = Packets.RedeemCode:Fire(box.Text)
				if ok then
					box.Text = ""
				end
				return ok, message
			end)
		end)
	end
	if groupRow and config.GroupId == 0 then
		-- No group configured: drop the row and shorten the panel by its height.
		groupRow.Visible = false
		local panel = gui:FindFirstChild("Panel")
		if panel and panel:IsA("GuiObject") then
			panel.Size -= UDim2.fromOffset(0, groupRow.Size.Y.Offset + 10)
		end
	end
	if claim then
		trove:Connect(claim.Activated, function()
			request(function()
				return Packets.ClaimGroupReward:Fire()
			end)
		end)
	end
	if invite then
		trove:Connect(invite.Activated, function()
			context.Controllers.SoundController:PlaySfx("Click")
			task.spawn(function()
				local ok, canInvite = pcall(SocialService.CanSendGameInviteAsync, SocialService, player)
				if ok and canInvite then
					SocialService:PromptGameInvite(player)
				else
					context.Notify("Invites are not available right now.")
				end
			end)
		end)
	end
	if friendsInfo then
		local label: TextLabel = friendsInfo
		local function update()
			local count = player:GetAttribute("FriendsInServer")
			local friends = math.min(if type(count) == "number" then count else 0, config.MaxFriends)
			local bonus = math.round(friends * config.FriendBonus * 100)
			label.Text =
				Locale.Format(nil, "FriendsBonus", { friends, bonus }, "Friends here: {1} (+{2}% coins)")
		end
		trove:Connect(player:GetAttributeChangedSignal("FriendsInServer"), update)
		update()
	end
	if favorite then
		trove:Connect(favorite.Activated, promptFavorite)
	end
	-- Premium members get GameConfig.PremiumBonus on coins (Coin.luau); others can subscribe here.
	if premiumRow then
		local label = premiumRow:FindFirstChild("Label")
		if label and label:IsA("TextLabel") then
			label.Text = `Premium: +{math.round(GameConfig.PremiumBonus * 100)}% coins`
		end
	end
	if premium then
		local button: ImageButton = premium
		local function update()
			local active = player.MembershipType == Enum.MembershipType.Premium
			button.Image = if active then UiImages.ButtonGrey else UiImages.ButtonGreen
			local label = button:FindFirstChild("Label")
			if label and label:IsA("TextLabel") then
				label.Text = if active then "Active" else "Get"
			end
		end
		-- Fires after a Premium purchase made during the session.
		trove:Connect(Players.PlayerMembershipChanged, function(changed: Player)
			if changed == player then
				update()
			end
		end)
		update()
		trove:Connect(button.Activated, function()
			if player.MembershipType ~= Enum.MembershipType.Premium then
				context.Controllers.SoundController:PlaySfx("Click")
				pcall(MarketplaceService.PromptPremiumPurchase, MarketplaceService, player)
			end
		end)
	end

	return {
		Modal = true,
		StartsOpen = false,
		Open = function(_self: Types.Screen)
			gui.Enabled = true
		end,
		Close = function(_self: Types.Screen)
			gui.Enabled = false
		end,
		Destroy = function(_self: Types.Screen)
			trove:Destroy()
		end,
	}
end

return Rewards
