--!strict

-- Example feature: a prompt that opens a model (chest, door, gate) for everyone. The server owns
-- the model attribute Open; the client animates parts with an OpenAngle attribute (client
-- Components/Motion.luau). Listen to GetAttributeChangedSignal("Open") to pay a reward.
-- Model attributes: ActionText ("Open"), AutoClose (seconds, 0 = stays open; default 3).
-- An Attachment named PromptPoint places the prompt; without one it sits on the root part.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)

type Openable = { Instance: Instance, _trove: typeof(Trove.new()) }

return function(_services: { [string]: any })
	local Openable = Component.new({ Tag = "Openable" }) :: any

	function Openable.Construct(self: Openable)
		self._trove = Trove.new()
	end

	function Openable.Start(self: Openable)
		local model = self.Instance
		local point = model:FindFirstChild("PromptPoint", true)
		local root = if model:IsA("Model") then model.PrimaryPart else nil
		local anchor = point or root or model:FindFirstChildWhichIsA("BasePart", true)
		if not anchor then
			warn(`[Openable] {model:GetFullName()} has no part to hold the prompt`)
			return
		end
		local actionText = model:GetAttribute("ActionText")
		local autoClose = model:GetAttribute("AutoClose")
		local delay = if type(autoClose) == "number" then autoClose else 3
		local prompt = self._trove:Add(Instance.new("ProximityPrompt"))
		prompt.ActionText = if type(actionText) == "string" then actionText else "Open"
		prompt.HoldDuration = 0.3
		prompt.MaxActivationDistance = 10
		-- A prompt at the root's centre sits inside the mesh; line of sight would hide it.
		prompt.RequiresLineOfSight = point ~= nil
		prompt.Parent = anchor
		model:SetAttribute("Open", false)
		self._trove:Connect(prompt.Triggered, function()
			if model:GetAttribute("Open") then
				return
			end
			model:SetAttribute("Open", true)
			prompt.Enabled = false
			if delay > 0 then
				self._trove:Add(task.delay(delay, function()
					model:SetAttribute("Open", false)
					prompt.Enabled = true
				end))
			end
		end)
	end

	function Openable.Stop(self: Openable)
		self._trove:Clean()
	end

	return Openable
end
