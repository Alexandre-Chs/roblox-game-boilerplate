--!strict

-- Joins every model tagged Rig into one animatable assembly (Utils/Rig.luau). The client
-- animates the joints (client Components/Motion.luau).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Component = require(ReplicatedStorage.Packages.Component)
local RigUtil = require(ReplicatedStorage.Utils.Rig)

type Rig = { Instance: Instance }

return function(_services: { [string]: any })
	local Rig = Component.new({ Tag = "Rig" }) :: any

	function Rig.Start(self: Rig)
		local model = self.Instance
		if model:IsA("Model") then
			RigUtil.Assemble(model)
		else
			warn(`[Rig] {model:GetFullName()} is tagged Rig but is not a Model`)
		end
	end

	return Rig
end
