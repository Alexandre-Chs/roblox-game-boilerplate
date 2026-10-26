--!strict

-- Turns a loose multi-part model (an AI mesh split into parts, a Toolbox model) into a rig:
-- the PrimaryPart (or the largest part) becomes the root, every other part is joined to it by a
-- Motor6D named after the part. An Attachment named "Pivot" inside a part sets that joint's pivot
-- and axes (a lid's hinge, a wing's shoulder); without one the joint pivots on the part's centre.
-- The root stays anchored unless the model has the attribute Anchored = false.
-- Idempotent: parts that already have a joint are skipped. Animate with Motor6D.Transform on the
-- client (Components/Motion.luau); Transform does not replicate.
local Rig = {}

local function largest(model: Model): BasePart?
	local best: BasePart?, volume = nil, -1
	for _, item in model:GetDescendants() do
		if item:IsA("BasePart") then
			local size = item.Size
			if size.X * size.Y * size.Z > volume then
				best, volume = item, size.X * size.Y * size.Z
			end
		end
	end
	return best
end

function Rig.Assemble(model: Model): { [string]: Motor6D }
	local root = model.PrimaryPart or largest(model)
	assert(root, `[Rig] {model:GetFullName()} has no parts`)
	model.PrimaryPart = root
	local motors: { [string]: Motor6D } = {}
	for _, part in model:GetDescendants() do
		if not part:IsA("BasePart") or part == root then
			continue
		end
		if motors[part.Name] then
			warn(`[Rig] {model:GetFullName()} has two parts named {part.Name}; the second is not jointed`)
			continue
		end
		local existing = root:FindFirstChild(part.Name)
		if existing and existing:IsA("Motor6D") then
			motors[part.Name] = existing
			continue
		end
		local pivot = part:FindFirstChild("Pivot")
		local frame = if pivot and pivot:IsA("Attachment") then pivot.WorldCFrame else part.CFrame
		local motor = Instance.new("Motor6D")
		motor.Name = part.Name
		motor.Part0 = root
		motor.Part1 = part
		motor.C0 = root.CFrame:ToObjectSpace(frame)
		motor.C1 = part.CFrame:ToObjectSpace(frame)
		motor.Parent = root
		part.Anchored = false
		part.Massless = true
		motors[part.Name] = motor
	end
	root.Anchored = model:GetAttribute("Anchored") ~= false
	return motors
end

return Rig
