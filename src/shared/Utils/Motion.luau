--!strict

-- Pure curves for code-driven animation (client Components/Motion.luau). Angles in radians,
-- time in seconds, speeds in cycles per second. No instances, tested in tests/run.luau.
local Motion = {}

-- Endless back-and-forth: wings, tails, swaying props.
function Motion.Wave(time: number, speed: number, amplitude: number, phase: number): number
	return amplitude * math.sin((time * speed + phase) * 2 * math.pi)
end

-- Critically damped spring step: reaches the target without overshoot, stable for any dt.
function Motion.Spring(
	position: number,
	velocity: number,
	target: number,
	frequency: number,
	dt: number
): (number, number)
	local omega = 2 * math.pi * frequency
	local offset = position - target
	local decay = math.exp(-omega * dt)
	local slope = velocity + omega * offset
	return target + (offset + slope * dt) * decay, (velocity - slope * omega * dt) * decay
end

-- Gait phase in [0, 1) advanced by distance travelled, so feet never slide whatever the speed.
function Motion.Stride(phase: number, distance: number, strideLength: number): number
	return (phase + distance / strideLength) % 1
end

return Motion
