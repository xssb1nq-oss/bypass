--// ============================================================
--// PROJECT DELTA | UNIVERSAL ROBLOX STUDIO EDITION
--// LocalScript
--// Place: StarterPlayer > StarterPlayerScripts
--// PATCHED: CoreGui Injection & Teleport Stability
--// ============================================================

-- Ожидание полной загрузки мира и камеры для предотвращения краша при телепортации
if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

repeat task.wait() until workspace.CurrentCamera ~= nil

-- ============================================================
-- CONFIG
-- ============================================================

local ACCENT = Color3.fromRGB(130, 90, 255)

local ESP = {
	Enabled = false,
	Names = true,
	Distance = true,
	Health = true,
	TeamCheck = false,
	Chams = true,
	MaxDistance = 1000,
}

local AIM = {
	Enabled = false,
	TeamCheck = false,
	RequireVisible = false,

	FOV = 180,
	Smoothness = 0.20,
	MaxDistance = 1000,

	Bone = "Head",

	Target = nil,
	TargetTime = 0,
}

local FULLBRIGHT = false
local FPS_BOOST = false

-- ============================================================
-- ORIGINAL LIGHTING
-- ============================================================

local OriginalLighting = {
	Brightness = Lighting.Brightness,
	ClockTime = Lighting.ClockTime,
	FogEnd = Lighting.FogEnd,
	GlobalShadows = Lighting.GlobalShadows,
	Ambient = Lighting.Ambient,
	OutdoorAmbient = Lighting.OutdoorAmbient,
	ColorShiftTop = Lighting.ColorShift_Top,
	ColorShiftBottom = Lighting.ColorShift_Bottom,
}

-- ============================================================
-- CAMERA
-- ============================================================

local function Camera()
	return workspace.CurrentCamera
end

-- ============================================================
-- SECURE GUI PARENT (COREGUI)
-- ============================================================

local function SecureParent(guiObject)
    local success = pcall(function()
        guiObject.Parent = CoreGui
    end)
    if not success then
        guiObject.Parent = PlayerGui -- Фоллбэк, если CoreGui заблокирован
    end
end

-- ============================================================
-- GENERAL HELPERS
-- ============================================================

local function GetRoot(character)
	if not character then return nil end
	return character:FindFirstChild("HumanoidRootPart")
		or character.PrimaryPart
		or character:FindFirstChildWhichIsA("BasePart")
end

local function GetHumanoid(character)
	if not character then return nil end
	return character:FindFirstChildOfClass("Humanoid")
end

local function IsAlive(character)
	local hum = GetHumanoid(character)
	local root = GetRoot(character)
	return hum ~= nil and root ~= nil and hum.Health > 0
end

local function SameTeam(player)
	if not player then return false end
	if not LocalPlayer.Team or not player.Team then return false end
	return LocalPlayer.Team == player.Team
end

local function DistanceFromPlayer(position)
	local character = LocalPlayer.Character
	local root = GetRoot(character)
	if not root then return math.huge end
	return (position - root.Position).Magnitude
end

local function GetBone(character)
	if not character then return nil end
	return character:FindFirstChild(AIM.Bone)
		or character:FindFirstChild("Head")
		or character:FindFirstChild("UpperTorso")
		or character:FindFirstChild("Torso")
		or GetRoot(character)
end

local function IsVisible(position, character)
	local cam = Camera()
	if not cam then return false end

	local origin = cam.CFrame.Position
	local direction = position - origin

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true
	params.FilterDescendantsInstances = { LocalPlayer.Character, character }

	local result = workspace:Raycast(origin, direction, params)
	return result == nil
end

-- ============================================================
-- GUI HELPERS
-- ============================================================

local function Corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = parent
	return c
end

local function Stroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or ACCENT
	s.Thickness = thickness or 1
	s.Parent = parent
	return s
end

local function NewLabel(parent, text, size)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Text = text or ""
	label.TextColor3 = Color3.new(1,1,1)
	label.Font = Enum.Font.Gotham
	label.TextSize = size or 12
	label.Parent = parent
	return label
end

-- ============================================================
-- CLEAN OLD GUI
-- ============================================================

local oldCore = CoreGui:FindFirstChild("ProjectDeltaUI")
local oldPlayer = PlayerGui:FindFirstChild("ProjectDeltaUI")

if oldCore then oldCore:Destroy() end
if oldPlayer then oldPlayer:Destroy() end

-- ============================================================
-- MAIN GUI
-- ============================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "ProjectDeltaUI"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.DisplayOrder = 100000
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

SecureParent(Gui) -- Защита от очистки PlayerGui

local UIScale = Instance.new("UIScale")
UIScale.Parent = Gui

local function UpdateScale()
	local cam = Camera()
	if not cam then return end
	local size = cam.ViewportSize
	UIScale.Scale = math.clamp(math.min(size.X / 900, size.Y / 650), 0.72, 1)
end

-- ============================================================
-- OPEN BUTTON
-- ============================================================

local OpenButton = Instance.new("TextButton")
OpenButton.Name = "OpenButton"
OpenButton.Size = UDim2.fromOffset(58,58)
OpenButton.Position = UDim2.new(0,18,0.5,-29)
OpenButton.BackgroundColor3 = Color3.fromRGB(15,15,20)
OpenButton.Text = "Δ"
OpenButton.TextColor3 = ACCENT
OpenButton.TextSize = 27
OpenButton.Font = Enum.Font.GothamBold
OpenButton.AutoButtonColor = false
OpenButton.Parent = Gui

Corner(OpenButton,14)
Stroke(OpenButton,ACCENT,1.5)

-- ============================================================
-- MAIN PANEL
-- ============================================================

local Panel = Instance.new("Frame")
Panel.Name = "MainPanel"
Panel.AnchorPoint = Vector2.new(0.5,0.5)
Panel.Position = UDim2.fromScale(0.5,0.5)
Panel.Size = UDim2.fromOffset(720,500)
Panel.BackgroundColor3 = Color3.fromRGB(12,12,16)
Panel.BorderSizePixel = 0
Panel.Parent = Gui

Corner(Panel,12)
Stroke(Panel,Color3.fromRGB(45,45,55),1)

-- ============================================================
-- TOP BAR
-- ============================================================

local Top = Instance.new("Frame")
Top.Size = UDim2.new(1,0,0,52)
Top.BackgroundColor3 = Color3.fromRGB(18,18,23)
Top.BorderSizePixel = 0
Top.Parent = Panel

Corner(Top,12)

local Title = NewLabel(Top, "PROJECT DELTA", 16)
Title.Position = UDim2.fromOffset(18,4)
Title.Size = UDim2.fromOffset(300,28)
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left

local SubTitle = NewLabel(Top, "UNIVERSAL STUDIO", 9)
SubTitle.Position = UDim2.fromOffset(18,29)
SubTitle.Size = UDim2.fromOffset(250,15)
SubTitle.TextColor3 = Color3.fromRGB(120,120,130)
SubTitle.TextXAlignment = Enum.TextXAlignment.Left

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(32,32)
Close.Position = UDim2.new(1,-44,0,10)
Close.BackgroundColor3 = Color3.fromRGB(30,30,37)
Close.Text = "×"
Close.TextColor3 = Color3.fromRGB(230,230,235)
Close.TextSize = 20
Close.Font = Enum.Font.Gotham
Close.AutoButtonColor = false
Close.Parent = Top

Corner(Close,8)

-- ============================================================
-- SIDEBAR & CONTENT
-- ============================================================

local Sidebar = Instance.new("Frame")
Sidebar.Position = UDim2.fromOffset(10,62)
Sidebar.Size = UDim2.fromOffset(150,428)
Sidebar.BackgroundColor3 = Color3.fromRGB(17,17,22)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Panel

Corner(Sidebar,10)

local SideLayout = Instance.new("UIListLayout")
SideLayout.Padding = UDim.new(0,6)
SideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
SideLayout.Parent = Sidebar

local SidePadding = Instance.new("UIPadding")
SidePadding.PaddingTop = UDim.new(0,8)
SidePadding.PaddingBottom = UDim.new(0,8)
SidePadding.Parent = Sidebar

local Content = Instance.new("ScrollingFrame")
Content.Position = UDim2.fromOffset(170,62)
Content.Size = UDim2.new(1,-180,1,-72)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 4
Content.ScrollBarImageColor3 = ACCENT
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.Parent = Panel

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.Padding = UDim.new(0,8)
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Parent = Content

local ContentPadding = Instance.new("UIPadding")
ContentPadding.PaddingBottom = UDim.new(0,10)
ContentPadding.Parent = Content

-- ============================================================
-- DRAG SYSTEM
-- ============================================================

local function MakeDraggable(object, handle)
	local dragging = false
	local startPosition
	local startObjectPosition

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			startPosition = input.Position
			startObjectPosition = object.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	UIS.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - startPosition
			object.Position = UDim2.new(
				startObjectPosition.X.Scale, startObjectPosition.X.Offset + delta.X,
				startObjectPosition.Y.Scale, startObjectPosition.Y.Offset + delta.Y
			)
		end
	end)
end

MakeDraggable(Panel,Top)
MakeDraggable(OpenButton,OpenButton)

-- ============================================================
-- UI FUNCTIONS
-- ============================================================

local function ClearContent()
	for _, object in ipairs(Content:GetChildren()) do
		if not object:IsA("UIListLayout") and not object:IsA("UIPadding") then
			object:Destroy()
		end
	end
end

local function Section(text)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1,0,0,38)
	frame.BackgroundColor3 = Color3.fromRGB(18,18,23)
	frame.BorderSizePixel = 0
	frame.Parent = Content
	Corner(frame,8)

	local label = NewLabel(frame,text,11)
	label.Position = UDim2.fromOffset(12,0)
	label.Size = UDim2.new(1,-24,1,0)
	label.TextColor3 = ACCENT
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	return frame
end

local function Toggle(text,initial,callback)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1,0,0,42)
	button.BackgroundColor3 = Color3.fromRGB(18,18,23)
	button.BorderSizePixel = 0
	button.Text = ""
	button.AutoButtonColor = false
	button.Parent = Content
	Corner(button,8)

	local label = NewLabel(button,text,12)
	label.Position = UDim2.fromOffset(12,0)
	label.Size = UDim2.new(1,-75,1,0)
	label.TextColor3 = Color3.fromRGB(225,225,230)
	label.TextXAlignment = Enum.TextXAlignment.Left

	local switch = Instance.new("Frame")
	switch.AnchorPoint = Vector2.new(1,0.5)
	switch.Position = UDim2.new(1,-12,0.5,0)
	switch.Size = UDim2.fromOffset(40,21)
	switch.BorderSizePixel = 0
	switch.Parent = button
	Corner(switch,12)

	local dot = Instance.new("Frame")
	dot.Size = UDim2.fromOffset(15,15)
	dot.AnchorPoint = Vector2.new(0,0.5)
	dot.Position = UDim2.new(0,3,0.5,0)
	dot.BorderSizePixel = 0
	dot.Parent = switch
	Corner(dot,10)

	local value = initial == true

	local function Refresh()
		if value then
			switch.BackgroundColor3 = ACCENT
			dot.BackgroundColor3 = Color3.new(1,1,1)
			dot.Position = UDim2.new(1,-18,0.5,0)
		else
			switch.BackgroundColor3 = Color3.fromRGB(40,40,48)
			dot.BackgroundColor3 = Color3.fromRGB(150,150,155)
			dot.Position = UDim2.new(0,3,0.5,0)
		end
	end

	button.Activated:Connect(function()
		value = not value
		Refresh()
		callback(value)
	end)

	Refresh()

	return {
		Set = function(v)
			value = v == true
			Refresh()
			callback(value)
		end,
		Get = function() return value end,
	}
end

local function Action(text,callback)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1,0,0,42)
	button.BackgroundColor3 = Color3.fromRGB(22,22,28)
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = Color3.fromRGB(235,235,240)
	button.TextSize = 12
	button.Font = Enum.Font.GothamBold
	button.AutoButtonColor = false
	button.Parent = Content
	Corner(button,8)
	Stroke(button,Color3.fromRGB(50,50,60),1)

	button.Activated:Connect(function()
		local old = button.BackgroundColor3
		button.BackgroundColor3 = ACCENT
		task.delay(0.12,function()
			if button.Parent then button.BackgroundColor3 = old end
		end)
		callback()
	end)

	return button
end

local function Slider(text,min,max,initial,callback)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1,0,0,58)
	frame.BackgroundColor3 = Color3.fromRGB(18,18,23)
	frame.BorderSizePixel = 0
	frame.Parent = Content
	Corner(frame,8)

	local label = NewLabel(frame,text,11)
	label.Position = UDim2.fromOffset(12,4)
	label.Size = UDim2.new(1,-80,0,22)
	label.TextXAlignment = Enum.TextXAlignment.Left

	local valueLabel = NewLabel(frame,"",11)
	valueLabel.AnchorPoint = Vector2.new(1,0)
	valueLabel.Position = UDim2.new(1,-12,0,4)
	valueLabel.Size = UDim2.fromOffset(55,22)
	valueLabel.TextColor3 = ACCENT
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right

	local bar = Instance.new("Frame")
	bar.Position = UDim2.fromOffset(12,35)
	bar.Size = UDim2.new(1,-24,0,7)
	bar.BackgroundColor3 = Color3.fromRGB(40,40,48)
	bar.BorderSizePixel = 0
	bar.Parent = frame
	Corner(bar,5)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(0,1)
	fill.BackgroundColor3 = ACCENT
	fill.BorderSizePixel = 0
	fill.Parent = bar
	Corner(fill,5)

	local value = initial

	local function SetValue(v)
		value = math.clamp(v,min,max)
		local alpha = (value-min)/(max-min)
		fill.Size = UDim2.fromScale(alpha,1)
		valueLabel.Text = tostring(math.floor(value))
		callback(value)
	end

	local dragging = false

	local function Update(input)
		local alpha = math.clamp((input.Position.X-bar.AbsolutePosition.X)/bar.AbsoluteSize.X, 0, 1)
		SetValue(min+(max-min)*alpha)
	end

	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			Update(input)
		end
	end)

	UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	UIS.InputChanged:Connect(function(input)
		if dragging then
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				Update(input)
			end
		end
	end)

	SetValue(value)
end

-- ============================================================
-- PLAYER ESP
-- ============================================================

local PlayerESP = {}

local function RemovePlayerESP(player)
	local data = PlayerESP[player]
	if not data then return end
	if data.Billboard then data.Billboard:Destroy() end
	if data.Highlight then data.Highlight:Destroy() end
	PlayerESP[player] = nil
end

local function CreatePlayerESP(player)
	if player == LocalPlayer then return end
	RemovePlayerESP(player)

	local data = {}
	PlayerESP[player] = data

	local function Attach(character)
		if player.Character ~= character then return end
		task.wait(0.1)
		if player.Character ~= character then return end

		local head = character:FindFirstChild("Head") or GetRoot(character)
		if not head then return end

		local billboard = Instance.new("BillboardGui")
		billboard.Name = "ProjectDeltaESP"
		billboard.Adornee = head
		billboard.AlwaysOnTop = true
		billboard.Size = UDim2.fromOffset(220,60)
		billboard.StudsOffset = Vector3.new(0,3,0)
		billboard.Enabled = ESP.Enabled

		SecureParent(billboard) -- Патч CoreGui

		local name = NewLabel(billboard, player.DisplayName, 13)
		name.Size = UDim2.new(1,0,0,22)
		name.Position = UDim2.fromOffset(0,0)
		name.Font = Enum.Font.GothamBold
		name.TextColor3 = ESP.NameColor or Color3.new(1,1,1)

		local info = NewLabel(billboard, "", 11)
		info.Size = UDim2.new(1,0,0,20)
		info.Position = UDim2.fromOffset(0,20)
		info.TextColor3 = Color3.fromRGB(220,220,220)

		local healthBack = Instance.new("Frame")
		healthBack.Position = UDim2.new(0.5,-45,0,44)
		healthBack.Size = UDim2.fromOffset(90,4)
		healthBack.BackgroundColor3 = Color3.fromRGB(35,35,35)
		healthBack.BorderSizePixel = 0
		healthBack.Parent = billboard
		Corner(healthBack,3)

		local health = Instance.new("Frame")
		health.Size = UDim2.fromScale(1,1)
		health.BackgroundColor3 = Color3.fromRGB(70,220,100)
		health.BorderSizePixel = 0
		health.Parent = healthBack
		Corner(health,3)

		local highlight = Instance.new("Highlight")
		highlight.Name = "ProjectDeltaChams"
		highlight.Adornee = character
		highlight.FillColor = ACCENT
		highlight.OutlineColor = ACCENT
		highlight.FillTransparency = 0.78
		highlight.OutlineTransparency = 0.05
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.Enabled = ESP.Enabled and ESP.Chams
		highlight.Parent = character

		data.Character = character
		data.Billboard = billboard
		data.Highlight = highlight
		data.Name = name
		data.Info = info
		data.HealthBack = healthBack
		data.Health = health
	end

	if player.Character then task.spawn(Attach,player.Character) end

	data.Connection = player.CharacterAdded:Connect(function(character)
		RemovePlayerESP(player)
		task.wait(0.15)
		CreatePlayerESP(player)
	end)
end

local function UpdatePlayerESP(player,data)
	if not data.Character or player.Character ~= data.Character then return end

	local character = data.Character
	local hum = GetHumanoid(character)
	local root = GetRoot(character)

	if not hum or not root or hum.Health <= 0 then
		if data.Billboard then data.Billboard.Enabled = false end
		if data.Highlight then data.Highlight.Enabled = false end
		return
	end

	local distance = DistanceFromPlayer(root.Position)
	local allowed = ESP.Enabled and distance <= ESP.MaxDistance and not (ESP.TeamCheck and SameTeam(player))

	if data.Billboard then data.Billboard.Enabled = allowed end
	if data.Highlight then data.Highlight.Enabled = allowed and ESP.Chams end

	if not allowed then return end

	data.Name.Visible = ESP.Names
	data.Info.Visible = ESP.Distance

	local text = ""
	if ESP.Distance then text = string.format("%dm", math.floor(distance)) end
	if ESP.Health then
		if text ~= "" then text = text.."  " end
		text = text..string.format("%d HP", math.floor(hum.Health))
	end

	data.Info.Text = text

	if ESP.Health then
		data.HealthBack.Visible = true
		local percent = math.clamp(hum.Health/math.max(hum.MaxHealth,1), 0, 1)
		data.Health.Size = UDim2.fromScale(percent,1)
	else
		data.HealthBack.Visible = false
	end
end

for _,player in ipairs(Players:GetPlayers()) do
	if player ~= LocalPlayer then task.spawn(CreatePlayerESP,player) end
end

Players.PlayerAdded:Connect(function(player) task.spawn(CreatePlayerESP,player) end)
Players.PlayerRemoving:Connect(RemovePlayerESP)

-- ============================================================
-- UNIVERSAL THREAT ESP
-- ============================================================

local ThreatESP = {}

local ThreatTypes = {
	Mine = { Text = "MINE", Color = Color3.fromRGB(255,60,60) },
	Tripwire = { Text = "TRIPWIRE", Color = Color3.fromRGB(255,150,40) },
	Grenade = { Text = "GRENADE", Color = Color3.fromRGB(255,210,60) },
	Trap = { Text = "TRAP", Color = Color3.fromRGB(200,70,255) },
	Threat = { Text = "THREAT", Color = Color3.fromRGB(255,60,60) },
}

local function CleanName(name)
	return string.lower(tostring(name)):gsub("[%s_%-%./]", "")
end

local function DetectThreat(instance)
	local strings = { instance.Name }
	local parent = instance.Parent
	for i = 1,5 do
		if not parent then break end
		table.insert(strings, parent.Name)
		parent = parent.Parent
	end

	for _,tag in ipairs(CollectionService:GetTags(instance)) do table.insert(strings, tag) end

	local text = CleanName(table.concat(strings," "))

	if text:find("tripwire") or text:find("wiretrap") then return "Tripwire"
	elseif text:find("mine") or text:find("landmine") or text:find("claymore") then return "Mine"
	elseif text:find("grenade") or text:find("frag") or text:find("explosive") then return "Grenade"
	elseif text:find("trap") then return "Trap"
	elseif text:find("threat") then return "Threat" end

	return nil
end

local function ThreatPart(instance)
	if instance:IsA("BasePart") then return instance end
	if instance:IsA("Model") then
		if instance.PrimaryPart then return instance.PrimaryPart end
		return instance:FindFirstChildWhichIsA("BasePart", true)
	end
	return instance:FindFirstChildWhichIsA("BasePart", true)
end

local function RemoveThreat(instance)
	local data = ThreatESP[instance]
	if not data then return end
	if data.Billboard then data.Billboard:Destroy() end
	if data.Highlight then data.Highlight:Destroy() end
	ThreatESP[instance] = nil
end

local function CreateThreat(instance)
	if ThreatESP[instance] then return end
	if not instance:IsDescendantOf(workspace) then return end

	local threatType = DetectThreat(instance)
	if not threatType then return end

	local part = ThreatPart(instance)
	if not part then return end

	local config = ThreatTypes[threatType]
	if not config then return end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ProjectDeltaThreat"
	billboard.Adornee = part
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.fromOffset(160,40)
	billboard.StudsOffset = Vector3.new(0,2.5,0)
	billboard.Enabled = ESP.Enabled

	SecureParent(billboard) -- Патч CoreGui

	local label = NewLabel(billboard, config.Text, 12)
	label.Size = UDim2.fromScale(1,1)
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = config.Color
	label.TextStrokeTransparency = 0.1

	local highlight = Instance.new("Highlight")
	highlight.Name = "ProjectDeltaThreatHighlight"
	if instance:IsA("Model") then highlight.Adornee = instance else highlight.Adornee = part end
	highlight.FillColor = config.Color
	highlight.OutlineColor = config.Color
	highlight.FillTransparency = 0.75
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Enabled = ESP.Enabled
	highlight.Parent = instance:IsA("Model") and instance or workspace

	ThreatESP[instance] = {
		Billboard = billboard,
		Highlight = highlight,
		Label = label,
		Part = part,
		Type = threatType,
	}
end

local function ScanThreats()
	for _,instance in ipairs(workspace:GetDescendants()) do
		if instance:IsA("Model") or instance:IsA("BasePart") then
			CreateThreat(instance)
		end
	end
end

workspace.DescendantAdded:Connect(function(instance)
	task.defer(function()
		if instance:IsA("Model") or instance:IsA("BasePart") then CreateThreat(instance) end
	end)
end)

workspace.DescendantRemoving:Connect(RemoveThreat)

local function UpdateThreat(instance,data)
	if not instance:IsDescendantOf(workspace) or not data.Part or not data.Part.Parent then
		RemoveThreat(instance)
		return
	end

	local distance = DistanceFromPlayer(data.Part.Position)
	local enabled = ESP.Enabled and distance <= ESP.MaxDistance

	data.Billboard.Enabled = enabled
	data.Highlight.Enabled = enabled

	if enabled then
		local config = ThreatTypes[data.Type]
		data.Label.Text = string.format("%s  %dm", config.Text, math.floor(distance))
	end
end

-- ============================================================
-- AIM
-- ============================================================

local function FindAimTarget()
	local cam = Camera()
	if not cam then return nil end

	local viewport = cam.ViewportSize
	local center = Vector2.new(viewport.X/2, viewport.Y/2)
	local best = nil
	local bestDistance = math.huge
	local localRoot = GetRoot(LocalPlayer.Character)

	for _,player in ipairs(Players:GetPlayers()) do
		if player == LocalPlayer then continue end
		if AIM.TeamCheck and SameTeam(player) then continue end

		local character = player.Character
		if not IsAlive(character) then continue end

		local root = GetRoot(character)
		local bone = GetBone(character)
		if not root or not bone then continue end

		if localRoot then
			local worldDistance = (root.Position-localRoot.Position).Magnitude
			if worldDistance > AIM.MaxDistance then continue end
		end

		if AIM.RequireVisible and not IsVisible(bone.Position, character) then continue end

		local screen, onScreen = cam:WorldToViewportPoint(bone.Position)
		if not onScreen or screen.Z <= 0 then continue end

		local screenDistance = (Vector2.new(screen.X, screen.Y)-center).Magnitude
		if screenDistance <= AIM.FOV and screenDistance < bestDistance then
			bestDistance = screenDistance
			best = bone
		end
	end

	return best
end

local function ActivateAim()
	if not AIM.Enabled then AIM.Target = nil return end

	local target = FindAimTarget()
	if target then
		AIM.Target = target
		AIM.TargetTime = os.clock()+1.5
	else
		AIM.Target = nil
		AIM.TargetTime = 0
	end
end

local function ValidAimTarget(target)
	if not target or not target.Parent then return false end

	local character = target.Parent
	local hum = GetHumanoid(character)
	if not hum or hum.Health <= 0 then return false end

	local root = GetRoot(character)
	local localRoot = GetRoot(LocalPlayer.Character)

	if root and localRoot then
		if (root.Position-localRoot.Position).Magnitude > AIM.MaxDistance then return false end
	end

	if AIM.RequireVisible and not IsVisible(target.Position, character) then return false end
	return true
end

-- ============================================================
-- FULLBRIGHT & FPS BOOST
-- ============================================================

local function SetFullbright(enabled)
	FULLBRIGHT = enabled
	if enabled then
		Lighting.Brightness = 3
		Lighting.ClockTime = 14
		Lighting.FogEnd = 100000
		Lighting.GlobalShadows = false
		Lighting.Ambient = Color3.new(1,1,1)
		Lighting.OutdoorAmbient = Color3.new(1,1,1)
		Lighting.ColorShift_Top = Color3.new(0,0,0)
		Lighting.ColorShift_Bottom = Color3.new(0,0,0)
	else
		Lighting.Brightness = OriginalLighting.Brightness
		Lighting.ClockTime = OriginalLighting.ClockTime
		Lighting.FogEnd = OriginalLighting.FogEnd
		Lighting.GlobalShadows = OriginalLighting.GlobalShadows
		Lighting.Ambient = OriginalLighting.Ambient
		Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
		Lighting.ColorShift_Top = OriginalLighting.ColorShiftTop
		Lighting.ColorShift_Bottom = OriginalLighting.ColorShiftBottom
	end
end

local function ApplyFPSBoost()
	if not FPS_BOOST then return end
	Lighting.GlobalShadows = false
	pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)

	for _,object in ipairs(workspace:GetDescendants()) do
		if object:IsA("ParticleEmitter") or object:IsA("Trail") or object:IsA("Beam") then
			object.Enabled = false
		elseif object:IsA("PostEffect") then
			object.Enabled = false
		end
	end
end

-- ============================================================
-- TABS & BUILDS
-- ============================================================

local CurrentTab = "Combat"

local function Tab(text)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1,-12,0,42)
	button.BackgroundColor3 = Color3.fromRGB(17,17,22)
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = Color3.fromRGB(175,175,185)
	button.TextSize = 12
	button.Font = Enum.Font.GothamBold
	button.AutoButtonColor = false
	button.Parent = Sidebar
	Corner(button,8)

	button.Activated:Connect(function()
		CurrentTab = text
		for _,child in ipairs(Sidebar:GetChildren()) do
			if child:IsA("TextButton") then
				if child == button then
					child.BackgroundColor3 = Color3.fromRGB(30,26,40)
					child.TextColor3 = ACCENT
				else
					child.BackgroundColor3 = Color3.fromRGB(17,17,22)
					child.TextColor3 = Color3.fromRGB(175,175,185)
				end
			end
		end

		if text == "Combat" then BuildCombat()
		elseif text == "ESP" then BuildESP()
		elseif text == "Threats" then BuildThreats()
		elseif text == "Render" then BuildRender()
		elseif text == "Misc" then BuildMisc() end
	end)

	return button
end

function BuildCombat()
	ClearContent()
	Section("AIM")
	Toggle("Enable AIM", AIM.Enabled, function(value)
		AIM.Enabled = value
		if not value then AIM.Target = nil; AIM.TargetTime = 0 end
	end)
	Action("TARGET — AIM AT NEAREST", function() ActivateAim() end)
	Slider("FOV", 30, 600, AIM.FOV, function(value) AIM.FOV = value end)
	Slider("Smoothness", 1, 100, AIM.Smoothness*100, function(value) AIM.Smoothness = math.clamp(value/100, 0.01, 1) end)
	Slider("Max Distance", 50, 3000, AIM.MaxDistance, function(value) AIM.MaxDistance = value end)
	Toggle("Team Check", AIM.TeamCheck, function(value) AIM.TeamCheck = value end)
	Toggle("Require Line Of Sight", AIM.RequireVisible, function(value) AIM.RequireVisible = value end)
	Section("CONTROL")
	Action("CLEAR AIM TARGET", function() AIM.Target = nil; AIM.TargetTime = 0 end)
end

function BuildESP()
	ClearContent()
	Section("PLAYER ESP")
	Toggle("Enable ESP", ESP.Enabled, function(value) ESP.Enabled = value end)
	Toggle("Names", ESP.Names, function(value) ESP.Names = value end)
	Toggle("Distance / Health", ESP.Distance, function(value) ESP.Distance = value end)
	Toggle("Health Bar", ESP.Health, function(value) ESP.Health = value end)
	Toggle("Team Check", ESP.TeamCheck, function(value) ESP.TeamCheck = value end)
	Toggle("Chams", ESP.Chams, function(value) ESP.Chams = value end)
	Slider("Max Distance", 50, 3000, ESP.MaxDistance, function(value) ESP.MaxDistance = value end)
end

function BuildThreats()
	ClearContent()
	Section("UNIVERSAL THREAT ESP")
	Toggle("Enable Threat ESP", ESP.Enabled, function(value) ESP.Enabled = value end)
	Action("SCAN WORKSPACE", function() ScanThreats() end)

	local info = Instance.new("TextLabel")
	info.Size = UDim2.new(1,0,0,105)
	info.BackgroundColor3 = Color3.fromRGB(18,18,23)
	info.BorderSizePixel = 0
	info.TextWrapped = true
	info.Text = "Автоматически ищет Mine, Tripwire, Grenade, Trap и Threat. Проверяются названия объектов, названия родителей и CollectionService Tags."
	info.TextColor3 = Color3.fromRGB(165,165,175)
	info.TextSize = 11
	info.Font = Enum.Font.Gotham
	info.Parent = Content
	Corner(info,8)

	Section("SUPPORTED")
	for _,data in ipairs({
		{"●  MINE",Color3.fromRGB(255,60,60)},
		{"●  TRIPWIRE",Color3.fromRGB(255,150,40)},
		{"●  GRENADE",Color3.fromRGB(255,210,60)},
		{"●  TRAP",Color3.fromRGB(200,70,255)},
		{"●  THREAT",Color3.fromRGB(255,60,60)},
	}) do
		local label = NewLabel(Content, data[1], 11)
		label.Size = UDim2.new(1,0,0,32)
		label.BackgroundColor3 = Color3.fromRGB(18,18,23)
		label.TextColor3 = data[2]
		label.TextXAlignment = Enum.TextXAlignment.Left
		Corner(label,7)
	end
end

function BuildRender()
	ClearContent()
	Section("WORLD")
	Toggle("Fullbright", FULLBRIGHT, function(value) SetFullbright(value) end)
	Toggle("FPS Boost", FPS_BOOST, function(value)
		FPS_BOOST = value
		if value then ApplyFPSBoost() end
	end)
	Action("APPLY FPS BOOST", function() FPS_BOOST = true; ApplyFPSBoost() end)

	local info = Instance.new("TextLabel")
	info.Size = UDim2.new(1,0,0,80)
	info.BackgroundColor3 = Color3.fromRGB(18,18,23)
	info.BorderSizePixel = 0
	info.TextWrapped = true
	info.Text = "Fullbright изменяет только Lighting. Стены, дороги, NPC, оружие, ящики и другие объекты карты не удаляются."
	info.TextColor3 = Color3.fromRGB(165,165,175)
	info.TextSize = 11
	info.Font = Enum.Font.Gotham
	info.Parent = Content
	Corner(info,8)
end

function BuildMisc()
	ClearContent()
	Section("MISC")
	Action("GET PING", function()
		local stats = game:GetService("Stats")
		local network = stats:FindFirstChild("Network")
		local server = network and network:FindFirstChild("ServerStatsItem")
		local ping = server and server:FindFirstChild("Data Ping")
		if ping then
			Title.Text = "PING: "..math.floor(ping:GetValue())
			task.delay(2, function() if Title.Parent then Title.Text = "PROJECT DELTA" end end)
		end
	end)

	Action("REJOIN", function() pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end) end)
	Action("SCAN THREATS", function() ScanThreats() end)

	Section("STATE")
	local info = Instance.new("TextLabel")
	info.Size = UDim2.new(1,0,0,105)
	info.BackgroundColor3 = Color3.fromRGB(18,18,23)
	info.BorderSizePixel = 0
	info.TextWrapped = true
	info.Text = "Состояние функций не привязано к Tool. Equip / Unequip оружия не выключает AIM, ESP или Fullbright. ScreenGui также не сбрасывается после Respawn."
	info.TextColor3 = Color3.fromRGB(165,165,175)
	info.TextSize = 11
	info.Font = Enum.Font.Gotham
	info.Parent = Content
	Corner(info,8)
end

local CombatTab = Tab("Combat")
Tab("ESP")
Tab("Threats")
Tab("Render")
Tab("Misc")

CombatTab.BackgroundColor3 = Color3.fromRGB(30,26,40)
CombatTab.TextColor3 = ACCENT
BuildCombat()

-- ============================================================
-- OPEN / CLOSE
-- ============================================================

local Opened = true

local function SetOpen(value)
	Opened = value
	Panel.Visible = Opened
end

OpenButton.Activated:Connect(function() SetOpen(not Opened) end)
Close.Activated:Connect(function() SetOpen(false) end)

UIS.InputBegan:Connect(function(input,processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.RightShift then SetOpen(not Opened) end
end)

-- ============================================================
-- RESPONSIVE
-- ============================================================

local function UpdateLayout()
	local cam = Camera()
	if not cam then return end
	local size = cam.ViewportSize

	if size.X < 650 then
		Panel.Size = UDim2.fromOffset(math.clamp(size.X-30, 310, 620), math.clamp(size.Y-40, 420, 620))
		Sidebar.Size = UDim2.new(0, 120, 1, -72)
		Content.Position = UDim2.fromOffset(133, 62)
		Content.Size = UDim2.new(1, -143, 1, -72)
	else
		Panel.Size = UDim2.fromOffset(720, 500)
		Sidebar.Size = UDim2.fromOffset(150, 428)
		Content.Position = UDim2.fromOffset(170, 62)
		Content.Size = UDim2.new(1, -180, 1, -72)
	end

	UpdateScale()
end

UpdateLayout()

local cam = Camera()
if cam then cam:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateLayout) end

-- ============================================================
-- MAIN LOOP
-- ============================================================

local scanTimer = 0

RunService.RenderStepped:Connect(function()
	for player,data in pairs(PlayerESP) do
		if player.Parent then UpdatePlayerESP(player, data) else RemovePlayerESP(player) end
	end

	for instance,data in pairs(ThreatESP) do UpdateThreat(instance, data) end

	if os.clock()-scanTimer >= 1 then
		scanTimer = os.clock()
		ScanThreats()
	end

	if AIM.Enabled and AIM.Target then
		if not ValidAimTarget(AIM.Target) then
			AIM.Target = nil
			AIM.TargetTime = 0
		elseif os.clock() <= AIM.TargetTime then
			local cam = Camera()
			if cam then
				local target = AIM.Target.Position
				local targetCF = CFrame.lookAt(cam.CFrame.Position, target)
				cam.CFrame = cam.CFrame:Lerp(targetCF, math.clamp(AIM.Smoothness, 0.01, 1))
			end
		else
			AIM.Target = nil
		end
	end
end)

-- ============================================================
-- CHARACTER RESPAWN
-- ============================================================

LocalPlayer.CharacterAdded:Connect(function()
	AIM.Target = nil
	AIM.TargetTime = 0
	task.delay(0.5, function()
		if FULLBRIGHT then SetFullbright(true) end
		if FPS_BOOST then ApplyFPSBoost() end
		ScanThreats()
	end)
end)

-- ============================================================
-- INITIALIZATION
-- ============================================================

task.spawn(function()
	task.wait(0.5)
	ScanThreats()
	if FULLBRIGHT then SetFullbright(true) end
	if FPS_BOOST then ApplyFPSBoost() end
	UpdateScale()
	UpdateLayout()
end)

print("[Project Delta] Universal Studio Edition loaded & patched.")
