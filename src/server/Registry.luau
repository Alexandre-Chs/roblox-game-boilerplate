--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lifecycle = require(ReplicatedStorage.Lifecycle)

local services: { Lifecycle.System } = {
	require(script.Parent.Services.DataService),
	require(script.Parent.Services.TelemetryService),
	require(script.Parent.Services.NotificationService),
	require(script.Parent.Services.GamePassService),
	require(script.Parent.Services.PurchaseService),
	require(script.Parent.Services.ShopService),
	require(script.Parent.Services.DailyRewardService),
	require(script.Parent.Services.SettingsService),
	require(script.Parent.Services.LeaderstatsService),
	require(script.Parent.Services.DebugService),
	require(script.Parent.Services.GameService),
	require(script.Parent.Services.ComponentService),
}

return services
