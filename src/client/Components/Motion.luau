--!strict

-- Code-driven animation for models tagged Rig (joints made by the server, Utils/Rig.luau).
-- Every frame each Motor6D.Transform rotates its part around the joint's pivot, from the
-- attributes on that part (angles in degrees):
--   OpenAngle  springs to this angle while the model attribute Open is true (lids, doors)
--   Wave, WaveSpeed (cycles/s, 1), WavePhase (0-1, 0)  endless swing (wings, tails)
--   Axis       "X" (default), "Y" or "Z" of the pivot
-- Transform is local to each client, so every player animates the shared state themselves.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Component = require(ReplicatedStorage.Packages.Component)
local Motion = require(ReplicatedStorage.Utils.Motion)
local Trove = require(ReplicatedStorage.Packages.Trove)

type Joint = { Motor: Motor6D, Angle: number, Velocity: number }
type Animated = { Instance: Instance, _trove: typeof(Trove.new()), _joints: { Joint } }

local AXES = { X = Vector3.xAxis, Y = Vector3.yAxis, Z = Vector3.zAxis }
local SPRING_FREQUENCY = 1.5

local function number(value: any, fallback: number): number
	return if type(value) == "number" then value else fallback
end

return function(_controllers: { [string]: any })
	local Animated = Component.new({ Tag = "Rig" }) :: any

	function Animated.Construct(self: Animated)
		self._trove = Trove.new()
		self._joints = {}
	end

	function Animated.Start(self: Animated)
		local function add(item: Instance)
			if item:IsA("Motor6D") then
				table.insert(self._joints, { Motor = item, Angle = 0, Velocity = 0 })
			end
		end
		for _, item in self.Instance:GetDescendants() do
			add(item)
		end
		-- The server may join the parts after this client has streamed the model in.
		self._trove:Connect(self.Instance.DescendantAdded, add)
	end

	function Animated.SteppedUpdate(self: Animated, dt: number)
		local open = self.Instance:GetAttribute("Open") == true
		local now = os.clock()
		for _, joint in self._joints do
			local part = joint.Motor.Part1
			if not part or not joint.Motor.Parent then
				continue
			end
			local openAngle = part:GetAttribute("OpenAngle")
			local target = if open and type(openAngle) == "number" then math.rad(openAngle) else 0
			joint.Angle, joint.Velocity =
				Motion.Spring(joint.Angle, joint.Velocity, target, SPRING_FREQUENCY, dt)
			local angle = joint.Angle
			local wave = part:GetAttribute("Wave")
			if type(wave) == "number" then
				angle += Motion.Wave(
					now,
					number(part:GetAttribute("WaveSpeed"), 1),
					math.rad(wave),
					number(part:GetAttribute("WavePhase"), 0)
				)
			end
			local axis = AXES[part:GetAttribute("Axis") :: any] or Vector3.xAxis
			joint.Motor.Transform = CFrame.fromAxisAngle(axis, angle)
		end
	end

	function Animated.Stop(self: Animated)
		self._trove:Clean()
	end

	return Animated
end
