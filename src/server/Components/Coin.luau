--!strict

-- Example feature: delete this file, its factory in ComponentService, the Hud screen,
-- assets/world/Coins and GameConfig.Coin to start a game from a clean slate.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Component = require(ReplicatedStorage.Packages.Component)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)

type Coin = {
	Instance: Instance,
	_trove: typeof(Trove.new()),
	_collected: boolean,
}

return function(services: { [string]: any })
	local Coin = Component.new({ Tag = "Coin" }) :: any

	local function setVisible(part: BasePart, visible: boolean)
		part.Transparency = if visible then 0 else 1
		part.CanTouch = visible
	end

	function Coin.Construct(self: Coin)
		self._trove = Trove.new()
		self._collected = false
	end

	function Coin.Start(self: Coin)
		local part = self.Instance
		if not part:IsA("BasePart") then
			warn(`[Coin] {part:GetFullName()} is tagged Coin but is not a BasePart`)
			return
		end
		self._trove:Connect(part.Touched, function(hit: BasePart)
			if self._collected then
				return
			end
			-- Touched fires on the server, so the client never asks for the reward.
			local character = hit.Parent
			local player = character and Players:GetPlayerFromCharacter(character)
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if not player or not humanoid or humanoid.Health <= 0 then
				return
			end
			if not services.DataService:AdjustCash(player, GameConfig.Coin.Value) then
				return
			end
			self._collected = true
			setVisible(part, false)
			self._trove:Add(task.delay(GameConfig.Coin.RespawnSeconds, function()
				self._collected = false
				setVisible(part, true)
			end))
		end)
	end

	function Coin.Stop(self: Coin)
		self._trove:Destroy()
	end

	return Coin
end
