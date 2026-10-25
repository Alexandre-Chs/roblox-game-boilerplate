--!strict

-- Fits fixed-size designs on every screen. Each UIScale named "DeviceScale" in PlayerGui is
-- set from the viewport: with DesignWidth/DesignHeight attributes (a modal panel's size in
-- pixels) the panel resizes until it fits; without them (Hud pieces) it follows a 960x540
-- reference (a small laptop window). Clamped between MIN (still readable on phones) and MAX
-- (big monitors and Retina windows, where 1:1 pixels look tiny).
local GuiService = game:GetService("GuiService")
local Workspace = game:GetService("Workspace")

local MIN = 0.5
local MAX = 1.3
local REFERENCE = Vector2.new(960, 540)

local DeviceScale = {}

function DeviceScale.For(scale: UIScale, viewport: Vector2): number
	local width = scale:GetAttribute("DesignWidth")
	local height = scale:GetAttribute("DesignHeight")
	local value = if type(width) == "number" and type(height) == "number"
		then math.min(viewport.X * 0.96 / width, viewport.Y * 0.9 / height)
		else math.min(viewport.X / REFERENCE.X, viewport.Y / REFERENCE.Y)
	return math.clamp(value, MIN, MAX)
end

-- Rescales every DeviceScale under root now and whenever the viewport or a new one appears.
function DeviceScale.Watch(trove: any, root: Instance)
	local function viewport(): Vector2
		local camera = Workspace.CurrentCamera
		local size = if camera then camera.ViewportSize else REFERENCE
		local inset = GuiService:GetGuiInset()
		return Vector2.new(size.X, size.Y - inset.Y)
	end
	local function apply(scale: Instance)
		if scale:IsA("UIScale") and scale.Name == "DeviceScale" then
			local fitted = DeviceScale.For(scale, viewport())
			-- Kept as an attribute too, so open animations can ease to it from any midpoint.
			scale:SetAttribute("Fitted", fitted)
			scale.Scale = fitted
		end
	end
	local function applyAll()
		for _, descendant in root:GetDescendants() do
			apply(descendant)
		end
	end
	trove:Connect(root.DescendantAdded, apply)
	local function watchCamera()
		local camera = Workspace.CurrentCamera
		if camera then
			trove:Connect(camera:GetPropertyChangedSignal("ViewportSize"), applyAll)
		end
		applyAll()
	end
	trove:Connect(Workspace:GetPropertyChangedSignal("CurrentCamera"), watchCamera)
	watchCamera()
end

return DeviceScale
