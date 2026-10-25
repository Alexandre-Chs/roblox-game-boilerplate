--!strict

-- Pure tutorial progression: returns the completed-step index after a milestone is reached.
-- Milestones reached out of order still count; progress never goes backwards.
local TutorialSteps = {}

function TutorialSteps.Advance(current: number, steps: { any }, reached: string): number
	for index, step in steps do
		if step.Id == reached then
			return math.max(current, index)
		end
	end
	return current
end

-- The step to show next, or nil once all are done.
function TutorialSteps.Current<T>(completed: number, steps: { T }): T?
	return steps[completed + 1]
end

return TutorialSteps
