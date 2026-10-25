--!strict

-- Pure starter-quest rules shared by TutorialService (authority) and the Tutorial screen.
-- done is PlayerData.Tutorial: completed quest id -> true.
local TutorialSteps = {}

export type Step = { Id: string, Reward: number }

-- The quest for this milestone if it is not done yet, else nil (unknown or already paid).
function TutorialSteps.Find<T>(done: { [string]: boolean }, steps: { T }, milestone: string): T?
	for _, step in steps do
		if (step :: any).Id == milestone and not done[milestone] then
			return step
		end
	end
	return nil
end

-- The first quest in display order that is still open; the arrow and beam guide to it.
function TutorialSteps.Current<T>(done: { [string]: boolean }, steps: { T }): T?
	for _, step in steps do
		if not done[(step :: any).Id] then
			return step
		end
	end
	return nil
end

function TutorialSteps.Count(done: { [string]: boolean }, steps: { any }): number
	local count = 0
	for _, step in steps do
		if done[step.Id] then
			count += 1
		end
	end
	return count
end

return TutorialSteps
