-- 🛠 Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- 📦 ESP Toggle State
local ESPEnabled = true

-- 🖼 GUI Setup
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.Name = "CleanESP_UI"
ScreenGui.ResetOnSpawn = false

-- 📐 Square Frame
local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 150, 0, 150)
Frame.Position = UDim2.new(0.05, 0, 0.2, 0)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.BorderSizePixel = 0
Frame.Active = true

local UICorner = Instance.new("UICorner", Frame)
UICorner.CornerRadius = UDim.new(0, 12)

-- 🏷 Title
local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "ESP Toggle"
Title.BackgroundTransparency = 1
Title.TextColor3 = Color3.new(1,1,1)
Title.Font = Enum.Font.Gotham
Title.TextSize = 16

-- 🟢 Switch Background
local SwitchBG = Instance.new("Frame", Frame)
SwitchBG.Position = UDim2.new(0.5, -40, 0.5, -12)
SwitchBG.Size = UDim2.new(0, 80, 0, 24)
SwitchBG.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
SwitchBG.BorderSizePixel = 0

local SwitchCorner = Instance.new("UICorner", SwitchBG)
SwitchCorner.CornerRadius = UDim.new(1, 0)

-- ⚪ Switch Knob
local Knob = Instance.new("Frame", SwitchBG)
Knob.Size = UDim2.new(0, 24, 0, 24)
Knob.Position = UDim2.new(0, 0, 0, 0)
Knob.BackgroundColor3 = Color3.new(1,1,1)
Knob.BorderSizePixel = 0

local KnobCorner = Instance.new("UICorner", Knob)
KnobCorner.CornerRadius = UDim.new(1, 0)

-- Notification GUI (hidden initially)
local notifFrame = Instance.new("Frame", ScreenGui)
notifFrame.Size = UDim2.new(0, 250, 0, 50)
notifFrame.Position = UDim2.new(0.5, -125, 0, -50) -- start just above screen
notifFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
notifFrame.BorderSizePixel = 0
notifFrame.ZIndex = 100
local notifCorner = Instance.new("UICorner", notifFrame)
notifCorner.CornerRadius = UDim.new(0, 8)

-- Shadow Frame for motion blur effect
local shadowFrame = Instance.new("Frame", notifFrame)
shadowFrame.Size = UDim2.new(1, 0, 1, 0)
shadowFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
shadowFrame.BorderSizePixel = 0
shadowFrame.Position = UDim2.new(0, 5, 0, 0) -- slight offset right
shadowFrame.BackgroundTransparency = 0.8
shadowFrame.ZIndex = 95
local shadowCorner = Instance.new("UICorner", shadowFrame)
shadowCorner.CornerRadius = UDim.new(0, 8)

local notifLabel = Instance.new("TextLabel", notifFrame)
notifLabel.Size = UDim2.new(1, 0, 1, 0)
notifLabel.BackgroundTransparency = 1
notifLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
notifLabel.Font = Enum.Font.GothamBold
notifLabel.TextSize = 22
notifLabel.TextStrokeTransparency = 0.5
notifLabel.Text = ""
notifLabel.ZIndex = 110

-- Rainbow edge stroke
local stroke = Instance.new("UIStroke", notifFrame)
stroke.Thickness = 3
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Transparency = 0

local hue = 0

-- Notification queue and state
local notificationQueue = {}
local notificationRunning = false

local function updateRainbow(dt)
	hue = (hue + dt * 0.5) % 1
	stroke.Color = Color3.fromHSV(hue, 1, 1)
end

local function animateNotification(text)
	if notificationRunning then
		table.insert(notificationQueue, text)
		return
	end
	notificationRunning = true

	notifLabel.Text = text

	local hiddenPos = UDim2.new(0.5, -125, 0, -50)
	local visiblePos = UDim2.new(0.5, -125, 0, 10)

	notifFrame.Position = hiddenPos
	shadowFrame.Position = UDim2.new(0, 5, 0, 0)
	shadowFrame.BackgroundTransparency = 0.8

	local slideDuration = 0.3
	local holdDuration = 2 -- changed to 2 seconds

	local function slide(fromPos, toPos, duration)
		local elapsed = 0
		while elapsed < duration do
			local dt = RunService.Heartbeat:Wait()
			elapsed += dt
			local alpha = math.clamp(elapsed / duration, 0, 1)

			local interp = function(a, b) return a + (b - a) * alpha end
			notifFrame.Position = UDim2.new(
				interp(fromPos.X.Scale, toPos.X.Scale),
				interp(fromPos.X.Offset, toPos.X.Offset),
				interp(fromPos.Y.Scale, toPos.Y.Scale),
				interp(fromPos.Y.Offset, toPos.Y.Offset)
			)

			local shadowAlpha = math.clamp(alpha - 0.15, 0, 1)
			shadowFrame.Position = UDim2.new(
				interp(fromPos.X.Scale, toPos.X.Scale),
				interp(fromPos.X.Offset + 5, toPos.X.Offset + 5),
				interp(fromPos.Y.Scale, toPos.Y.Scale),
				interp(fromPos.Y.Offset, toPos.Y.Offset)
			)

			if alpha > 0.85 then
				shadowFrame.BackgroundTransparency = 0.8 + (alpha - 0.85) * 5 * (1 - 0.8)
			else
				shadowFrame.BackgroundTransparency = 0.8
			end

			updateRainbow(dt)
		end

		notifFrame.Position = toPos
		shadowFrame.Position = UDim2.new(toPos.X.Scale, toPos.X.Offset + 5, toPos.Y.Scale, toPos.Y.Offset)
		shadowFrame.BackgroundTransparency = 0.8
	end

	slide(hiddenPos, visiblePos, slideDuration)

	local holdElapsed = 0
	while holdElapsed < holdDuration do
		local dt = RunService.Heartbeat:Wait()
		holdElapsed += dt
		updateRainbow(dt)
	end

	slide(visiblePos, hiddenPos, slideDuration)

	notificationRunning = false

	if #notificationQueue > 0 then
		task.spawn(animateNotification, table.remove(notificationQueue, 1))
	end
end

-- 📦 ESP Functions
local function clearESP(model)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			for _, child in ipairs(part:GetChildren()) do
				if child:IsA("BoxHandleAdornment") and child.Name == "ESPBox" then
					child:Destroy()
				end
			end
		end
	end
end

local function addESP(model)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") and not part:FindFirstChild("ESPBox") then
			local adorn = Instance.new("BoxHandleAdornment")
			adorn.Name = "ESPBox"
			adorn.Adornee = part
			adorn.Size = part.Size
			adorn.AlwaysOnTop = true
			adorn.ZIndex = 10
			adorn.Transparency = 0.7
			adorn.Color3 = Color3.new(1, 0, 0)
			adorn.Parent = part
		end
	end
end

local function isEnemy(model)
	if not model:IsA("Model") or model == LocalPlayer.Character then return false end
	if not model:FindFirstChild("Head") then return false end
	return true
end

local function clearAllESP()
	for _, part in ipairs(workspace:GetDescendants()) do
		if part:IsA("BasePart") then
			local adorn = part:FindFirstChild("ESPBox")
			if adorn then
				adorn:Destroy()
			end
		end
	end
end

-- Toggle update function
local function updateSwitch(state)
	ESPEnabled = state
	local goalPosition = state and UDim2.new(1, -24, 0, 0) or UDim2.new(0, 0, 0, 0)
	local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	TweenService:Create(Knob, tweenInfo, {Position = goalPosition}):Play()

	if ESPEnabled then
		for _, plr in pairs(Players:GetPlayers()) do
			if isEnemy(plr.Character) then
				addESP(plr.Character)
			end
		end
		task.spawn(animateNotification, "ESP ON")
	else
		clearAllESP()
		task.spawn(animateNotification, "ESP OFF")
	end
end

-- Click toggle logic (fixed)
SwitchBG.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		updateSwitch(not ESPEnabled)
	end
end)

-- Initial ESP state
updateSwitch(ESPEnabled)

-- Update ESP for new players or character respawns
Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function(char)
		if ESPEnabled and isEnemy(char) then
			addESP(char)
		end
	end)
end)

-- Also add ESP on existing players' characters if enabled
for _, plr in pairs(Players:GetPlayers()) do
	if plr.Character and isEnemy(plr.Character) then
		if ESPEnabled then addESP(plr.Character) end
	end
	plr.CharacterAdded:Connect(function(char)
		if ESPEnabled and isEnemy(char) then
			addESP(char)
		end
	end)
end
