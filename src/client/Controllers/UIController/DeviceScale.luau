--!strict

-- Fits fixed-size designs on every screen. Each UIScale named "DeviceScale" in PlayerGui is
-- set from the viewport: with DesignWidth/DesignHeight attributes (a modal panel's size in
-- pixels) the panel resizes until it fits; without them (Hud pieces) it follows a 960x540
-- reference (a small laptop window). Clamped between MIN (still readable on phones) and MAX
-- (big monitors and Retina windows, where 1:1 pixels look tiny).
local MIN = 0.5
local MAX = 1.3
local REFERENCE_X, REFERENCE_Y = 960, 540

local DeviceScale = {}

-- Pure fit (tested in tests/run.luau): design size in pixels, or nil for the Hud reference.
function DeviceScale.Fit(viewportX: number, viewportY: number, width: number?, height: number?): number
	local value = if width and height
		then math.min(viewportX * 0.96 / width, viewportY * 0.9 / height)
		else math.min(viewportX / REFERENCE_X, viewportY / REFERENCE_Y)
	return math.clamp(value, MIN, MAX)
end

function DeviceScale.For(scale: UIScale, viewport: Vector2): number
	local width = scale:GetAttribute("DesignWidth")
	local height = scale:GetAttribute("DesignHeight")
	if type(width) == "number" and type(height) == "number" then
		return DeviceScale.Fit(viewport.X, viewport.Y, width, height)
	end
	return DeviceScale.Fit(viewport.X, viewport.Y, nil, nil)
end

-- Rescales every DeviceScale under root now and whenever the viewport or a new one appears.
function DeviceScale.Watch(trove: any, root: Instance)
	local GuiService = game:GetService("GuiService")
	local Workspace = game:GetService("Workspace")
	local function viewport(): Vector2
		local camera = Workspace.CurrentCamera
		local size = if camera then camera.ViewportSize else Vector2.new(REFERENCE_X, REFERENCE_Y)
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
	-- Only the current camera is watched; a replaced camera's connection is dropped.
	local cameraTrove = trove:Extend()
	local function watchCamera()
		cameraTrove:Clean()
		local camera = Workspace.CurrentCamera
		if camera then
			cameraTrove:Connect(camera:GetPropertyChangedSignal("ViewportSize"), applyAll)
		end
		applyAll()
	end
	trove:Connect(Workspace:GetPropertyChangedSignal("CurrentCamera"), watchCamera)
	watchCamera()
end

return DeviceScale
