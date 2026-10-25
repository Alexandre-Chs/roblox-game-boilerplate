--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lifecycle = require(ReplicatedStorage.Lifecycle)

local services: { Lifecycle.System } = {
	require(script.Parent.Services.DataService),
	require(script.Parent.Services.TelemetryService),
	require(script.Parent.Services.NotificationService),
	require(script.Parent.Services.GamePassService),
	require(script.Parent.Services.AchievementService),
	require(script.Parent.Services.TutorialService),
	require(script.Parent.Services.ComplianceService),
	require(script.Parent.Services.PurchaseService),
	require(script.Parent.Services.ShopService),
	require(script.Parent.Services.DailyRewardService),
	require(script.Parent.Services.InventoryService),
	require(script.Parent.Services.CodesService),
	require(script.Parent.Services.CommunityService),
	require(script.Parent.Services.LeaderboardService),
	require(script.Parent.Services.SettingsService),
	require(script.Parent.Services.LeaderstatsService),
	require(script.Parent.Services.DebugService),
	require(script.Parent.Services.GameService),
	require(script.Parent.Services.ComponentService),
}

return services
