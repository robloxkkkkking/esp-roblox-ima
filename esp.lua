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
Frame.Draggable = false -- we'll add custom drag

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
notifFrame.Position = UDim2.new(0.5, -125, 0, -50)
notifFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
notifFrame.BorderSizePixel = 0
notifFrame.ZIndex = 100
notifFrame.BackgroundTransparency = 0

local notifCorner = Instance.new("UICorner", notifFrame)
notifCorner.CornerRadius = UDim.new(0, 8)

local shadowFrame = Instance.new("Frame", notifFrame)
shadowFrame.Size = UDim2.new(1, 0, 1, 0)
shadowFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
shadowFrame.BorderSizePixel = 0
shadowFrame.Position = UDim2.new(0, 5, 0, 0)
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
notifLabel.TextTransparency = 0

local stroke = Instance.new("UIStroke", notifFrame)
stroke.Thickness = 3
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Transparency = 0

local hue = 0
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
	notifFrame.Position = UDim2.new(0.5, -125, 0, -50)
	notifFrame.BackgroundTransparency = 0
	notifLabel.TextTransparency = 0

	local slideIn = TweenService:Create(notifFrame, TweenInfo.new(0.3), {Position = UDim2.new(0.5, -125, 0, 10)})
	slideIn:Play()
	slideIn.Completed:Wait()

	wait(1) -- Stay visible

	local fadeOut = TweenService:Create(notifFrame, TweenInfo.new(1), {
		BackgroundTransparency = 1
	})
	local textFade = TweenService:Create(notifLabel, TweenInfo.new(1), {
		TextTransparency = 1
	})

	fadeOut:Play()
	textFade:Play()

	fadeOut.Completed:Wait()
	notifFrame.Position = UDim2.new(0.5, -125, 0, -50)

	notificationRunning = false
	if #notificationQueue > 0 then
		task.spawn(animateNotification, table.remove(notificationQueue, 1))
	end
end

-- 🟩 ESP Core Functions
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

-- 🟢 Toggle Handler
local function updateSwitch(state)
	ESPEnabled = state
	local goalPosition = state and UDim2.new(1, -24, 0, 0) or UDim2.new(0, 0, 0, 0)
	local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	TweenService:Create(Knob, tweenInfo, {Position = goalPosition}):Play()

	if state then
		local neonGreen = Color3.fromRGB(0, 255, 127)
		local normalGreen = Color3.fromRGB(0, 255, 0)
		SwitchBG.BackgroundColor3 = neonGreen
		task.delay(2, function()
			TweenService:Create(SwitchBG, tweenInfo, {BackgroundColor3 = normalGreen}):Play()
		end)
		for _, plr in pairs(Players:GetPlayers()) do
			if isEnemy(plr.Character) then
				addESP(plr.Character)
			end
		end
		task.spawn(animateNotification, "ESP ON")
	else
		clearAllESP()
		TweenService:Create(SwitchBG, tweenInfo, {BackgroundColor3 = Color3.fromRGB(60,60,60)}):Play()
		task.spawn(animateNotification, "ESP OFF")
	end
end

local toggled = ESPEnabled
SwitchBG.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		toggled = not toggled
		updateSwitch(toggled)
	end
end)

updateSwitch(ESPEnabled)

-- 🧍 Character & Player Handling
Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function(char)
		if ESPEnabled and isEnemy(char) then
			addESP(char)
		end
	end)
end)

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

-- 🖱️ Draggable GUI
local dragging = false
local dragStart, startPos

Frame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = Frame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
		local delta = input.Position - dragStart
		Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)
