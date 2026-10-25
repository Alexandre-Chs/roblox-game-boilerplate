--!strict

-- Renders the global top list (ReplicatedStorage attribute "Leaderboard", published by
-- LeaderboardService) on any part tagged Leaderboard that holds a SurfaceGui with a "List"
-- frame and a "RowTemplate" (Rank, Medal, PlayerName, Value).
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)
local UiImages = require(ReplicatedStorage.Config.UiImages)
local abbreviate = require(ReplicatedStorage.Utils.Abbreviate)

type Board = {
	Instance: Instance,
	_trove: typeof(Trove.new()),
}

local MEDALS = { UiImages.MedalGold, UiImages.MedalSilver, UiImages.MedalBronze }

return function(_controllers: { [string]: any })
	local Leaderboard = Component.new({ Tag = "Leaderboard" }) :: any

	function Leaderboard.Construct(self: Board)
		self._trove = Trove.new()
	end

	function Leaderboard.Start(self: Board)
		local list = self.Instance:FindFirstChild("List", true)
		local template = self.Instance:FindFirstChild("RowTemplate", true)
		if not (list and template and template:IsA("GuiObject")) then
			warn(`[Leaderboard] {self.Instance:GetFullName()} needs a SurfaceGui with List and RowTemplate`)
			return
		end
		template.Visible = false
		local rows = self._trove:Extend()
		local function render()
			rows:Clean()
			local raw = ReplicatedStorage:GetAttribute("Leaderboard")
			local ok, entries =
				pcall(HttpService.JSONDecode, HttpService, if type(raw) == "string" then raw else "[]")
			if not ok or type(entries) ~= "table" then
				return
			end
			for rank, entry in entries do
				local row = rows:Add(template:Clone())
				row.Name = `Rank{rank}`
				row.LayoutOrder = rank
				row.Visible = true
				local texts: { [string]: string } = {
					Rank = tostring(rank),
					PlayerName = tostring(entry.Name),
					Value = abbreviate(if type(entry.Value) == "number" then entry.Value else 0),
				}
				for name, text in texts do
					local label = row:FindFirstChild(name, true)
					if label and label:IsA("TextLabel") then
						label.Text = text
					end
				end
				local medal = row:FindFirstChild("Medal", true)
				if medal and medal:IsA("ImageLabel") then
					medal.Visible = MEDALS[rank] ~= nil
					medal.Image = MEDALS[rank] or ""
				end
				local rankLabel = row:FindFirstChild("Rank", true)
				if rankLabel and rankLabel:IsA("GuiObject") then
					rankLabel.Visible = MEDALS[rank] == nil
				end
				row.Parent = list
			end
		end
		self._trove:Connect(ReplicatedStorage:GetAttributeChangedSignal("Leaderboard"), render)
		render()
	end

	function Leaderboard.Stop(self: Board)
		self._trove:Destroy()
	end

	return Leaderboard
end
