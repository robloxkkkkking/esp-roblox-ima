local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Show minimal centered credit notification once on script start
StarterGui:SetCore("SendNotification", {
    Title = "";
    Text = "     credit to imthehas     "; -- padded spaces for rough centering
    Duration = 5;
    Icon = "";
})

-- 🔴 Highlighting function
local function highlightCharacter(character)
    if not character or character == LocalPlayer.Character then return end

    for _, part in character:GetDescendants() do
        if part:IsA("BasePart") then
            -- Outline
            if not part:FindFirstChild("RedOutline") then
                local outline = Instance.new("SelectionBox")
                outline.Name = "RedOutline"
                outline.Adornee = part
                outline.Color3 = Color3.fromRGB(255, 0, 0)
                outline.LineThickness = 0.05
                outline.SurfaceTransparency = 0.5
                outline.Parent = part
            end

            -- Fill
            if not part:FindFirstChild("RedFill") then
                local fill = Instance.new("BoxHandleAdornment")
                fill.Name = "RedFill"
                fill.Adornee = part
                fill.Color3 = Color3.fromRGB(255, 0, 0)
                fill.AlwaysOnTop = true
                fill.ZIndex = 5
                fill.Transparency = 0.7
                fill.Size = part.Size
                fill.Parent = part
            end
        end
    end
end

-- Refresh highlight every 2 seconds while character exists
local function onCharacterAdded(player, character)
    task.spawn(function()
        while character.Parent do
            highlightCharacter(character)
            task.wait(2)
        end
    end)
end

-- Apply to existing players
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        if player.Character then
            onCharacterAdded(player, player.Character)
        end
        player.CharacterAdded:Connect(function(char)
            onCharacterAdded(player, char)
        end)
    end
end

-- Watch for new players
Players.PlayerAdded:Connect(function(player)
    if player == LocalPlayer then return end
    player.CharacterAdded:Connect(function(char)
        onCharacterAdded(player, char)
    end)
end)

-- 🔁 Print "H" every 5 seconds
task.spawn(function()
    while true do
        print("H")
        task.wait(5)
    end
end)
