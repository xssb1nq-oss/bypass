--// ============================================================
--// CSS.JAVA | PROJECT DELTA CORE | v3 DESIGN BUILD
--// Touch-first | Animated UI | Particles | Multi-accent
--// ============================================================

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

repeat task.wait() until workspace.CurrentCamera ~= nil

-- ============================================================
-- CONFIG
-- ============================================================

-- ── Accent presets ────────────────────────────────────────────────────────────
local ACCENT_PRESETS = {
    { Name = "Cyan",    Color = Color3.fromRGB(0,   170, 255) },
    { Name = "Purple",  Color = Color3.fromRGB(150,  80, 255) },
    { Name = "Green",   Color = Color3.fromRGB(0,   220, 120) },
    { Name = "Orange",  Color = Color3.fromRGB(255, 140,  40) },
    { Name = "Red",     Color = Color3.fromRGB(255,  60,  60) },
    { Name = "Pink",    Color = Color3.fromRGB(255,  80, 180) },
    { Name = "Gold",    Color = Color3.fromRGB(255, 200,  40) },
    { Name = "White",   Color = Color3.fromRGB(230, 235, 240) },
}
local ACCENT = ACCENT_PRESETS[1].Color

-- зарегистрированные объекты для live-смены акцента
local AccentTargets = {}  -- { Object, Property }
local function TrackAccent(obj, prop)
    table.insert(AccentTargets, { obj, prop })
    obj[prop] = ACCENT
end
local function SetAccent(c3)
    ACCENT = c3
    for _, t in ipairs(AccentTargets) do
        pcall(function() t[1][t[2]] = c3 end)
    end
end

-- ── Визуальные настройки (частицы, анимации) ─────────────────────────────────
local VFX = {
    Particle      = "snow",   -- "snow" | "rain" | "stars" | "sparks" | "none"
    ParticleCount = 40,
    Animations    = true,     -- глобальный флаг плавных переходов
    OpenAnim      = true,     -- анимация открытия меню
    TabAnim       = true,     -- fade при смене вкладки
}

local C = {
    Main     = Color3.fromRGB(8, 14, 23),
    Sidebar  = Color3.fromRGB(15, 25, 38),
    Content  = Color3.fromRGB(5, 9, 15),
    Row      = Color3.fromRGB(13, 22, 34),
    RowAlt   = Color3.fromRGB(17, 28, 42),
    Stroke   = Color3.fromRGB(24, 38, 56),
    Text     = Color3.fromRGB(230, 235, 240),
    TextDim  = Color3.fromRGB(120, 135, 155),
    Category = Color3.fromRGB(65, 85, 110),
    Danger   = Color3.fromRGB(255, 70, 70),
    PVP      = Color3.fromRGB(255, 80, 80),
    NPCAim   = Color3.fromRGB(255, 140, 40),
}

local ESP = {
    Enabled = false,
    Names = true,
    Distance = true,
    Health = true,
    TeamCheck = false,
    Chams = true,
    Tracers = false,
    MaxDistance = 1000,
}

local NPC = {
    Enabled = false,
    Names = true,
    Distance = true,
    Health = true,
    Chams = true,
    Tracers = false,
    MaxDistance = 500,
    Color = Color3.fromRGB(255, 140, 40),
}

local THREAT = {
    Enabled = false,
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
    TargetKind = nil,
    HoldMode = "none",
    LockKind = nil,
    LockUntil = 0,
}

local FULLBRIGHT = false
local FPS_BOOST = false

local UIState = {
    ShowAimButtons = true,
    ShowFOV = true,
    ShowFlyControls = true,
}

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
-- CAMERA & SECURE PARENT
-- ============================================================

local function Camera()
    return workspace.CurrentCamera
end

local function SecureParent(guiObject)
    if gethui then
        guiObject.Parent = gethui()
        return
    end
    local success = pcall(function()
        guiObject.Parent = CoreGui
    end)
    if not success then
        guiObject.Parent = PlayerGui
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
    local root = GetRoot(LocalPlayer.Character)
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
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true
    params.FilterDescendantsInstances = { LocalPlayer.Character, character }
    local result = workspace:Raycast(cam.CFrame.Position, position - cam.CFrame.Position, params)
    return result == nil
end

-- ============================================================
-- GUI PRIMITIVES
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

local function Tween(obj, props, t, style, dir)
    if not VFX.Animations then
        for k, v in pairs(props) do pcall(function() obj[k] = v end) end
        return
    end
    TweenService:Create(
        obj,
        TweenInfo.new(t or 0.2, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out),
        props
    ):Play()
end

local function NewLabel(parent, text, size, font)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Text = text or ""
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = font or Enum.Font.Gotham
    label.TextSize = size or 12
    label.Parent = parent
    return label
end

-- ============================================================
-- CLEAN OLD GUI
-- ============================================================

local function WipeOldGui(container)
    for _, obj in ipairs(container:GetChildren()) do
        if obj.Name == "NeverloseUI" or obj.Name == "CSSJavaUI" then
            obj:Destroy()
        end
    end
end

WipeOldGui(CoreGui)
WipeOldGui(PlayerGui)
if gethui then
    pcall(function() WipeOldGui(gethui()) end)
end

-- ============================================================
-- CORE GUI (mobile-first)
-- ============================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "CSSJavaUI"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.DisplayOrder = 100000
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SecureParent(Gui)

-- ── Экран загрузки ────────────────────────────────────────────────────────────
local LoadScreen = Instance.new("Frame")
LoadScreen.Name = "LoadScreen"
LoadScreen.Size = UDim2.fromScale(1, 1)
LoadScreen.BackgroundColor3 = Color3.fromRGB(4, 7, 12)
LoadScreen.ZIndex = 200
LoadScreen.Parent = Gui

local LoadTitle = Instance.new("TextLabel")
LoadTitle.Size = UDim2.new(1, 0, 0, 40)
LoadTitle.AnchorPoint = Vector2.new(0.5, 0.5)
LoadTitle.Position = UDim2.new(0.5, 0, 0.42, 0)
LoadTitle.BackgroundTransparency = 1
LoadTitle.Text = "CSS.JAVA"
LoadTitle.Font = Enum.Font.GothamBlack
LoadTitle.TextSize = 32
LoadTitle.TextColor3 = ACCENT
LoadTitle.ZIndex = 201
LoadTitle.Parent = LoadScreen

local LoadSub = Instance.new("TextLabel")
LoadSub.Size = UDim2.new(1, 0, 0, 20)
LoadSub.AnchorPoint = Vector2.new(0.5, 0.5)
LoadSub.Position = UDim2.new(0.5, 0, 0.50, 0)
LoadSub.BackgroundTransparency = 1
LoadSub.Text = "PROJECT DELTA CORE"
LoadSub.Font = Enum.Font.GothamMedium
LoadSub.TextSize = 13
LoadSub.TextColor3 = Color3.fromRGB(100, 120, 145)
LoadSub.ZIndex = 201
LoadSub.Parent = LoadScreen

-- прогресс-бар
local BarBG = Instance.new("Frame")
BarBG.Size = UDim2.fromOffset(200, 3)
BarBG.AnchorPoint = Vector2.new(0.5, 0.5)
BarBG.Position = UDim2.new(0.5, 0, 0.57, 0)
BarBG.BackgroundColor3 = Color3.fromRGB(20, 28, 40)
BarBG.BorderSizePixel = 0
BarBG.ZIndex = 201
BarBG.Parent = LoadScreen
Corner(BarBG, 2)

local BarFill = Instance.new("Frame")
BarFill.Size = UDim2.new(0, 0, 1, 0)
BarFill.BackgroundColor3 = ACCENT
BarFill.BorderSizePixel = 0
BarFill.ZIndex = 202
BarFill.Parent = BarBG
Corner(BarFill, 2)

local LoadStatus = Instance.new("TextLabel")
LoadStatus.Size = UDim2.new(1, 0, 0, 16)
LoadStatus.AnchorPoint = Vector2.new(0.5, 0.5)
LoadStatus.Position = UDim2.new(0.5, 0, 0.62, 0)
LoadStatus.BackgroundTransparency = 1
LoadStatus.Text = "Initializing..."
LoadStatus.Font = Enum.Font.Gotham
LoadStatus.TextSize = 11
LoadStatus.TextColor3 = Color3.fromRGB(80, 100, 125)
LoadStatus.ZIndex = 201
LoadStatus.Parent = LoadScreen

-- анимируем загрузку: фейк-прогресс
task.spawn(function()
    local steps = {
        { 0.15, "Loading modules..." },
        { 0.35, "Initializing ESP..." },
        { 0.55, "Setting up aimbot..." },
        { 0.75, "Applying visual config..." },
        { 0.92, "Building UI..." },
        { 1.00, "Done." },
    }
    for _, step in ipairs(steps) do
        task.wait(0.28)
        TweenService:Create(BarFill, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {
            Size = UDim2.new(step[1], 0, 1, 0)
        }):Play()
        LoadStatus.Text = step[2]
    end
    task.wait(0.3)
    -- fade out
    TweenService:Create(LoadScreen, TweenInfo.new(0.4, Enum.EasingStyle.Quart), {
        BackgroundTransparency = 1
    }):Play()
    TweenService:Create(LoadTitle,  TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
    TweenService:Create(LoadSub,    TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
    TweenService:Create(LoadStatus, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
    TweenService:Create(BarBG,      TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
    TweenService:Create(BarFill,    TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
    task.wait(0.45)
    LoadScreen:Destroy()
end)

-- ── Система частиц (фон экрана) ───────────────────────────────────────────────
local ParticleContainer = Instance.new("Frame")
ParticleContainer.Name = "Particles"
ParticleContainer.Size = UDim2.fromScale(1, 1)
ParticleContainer.BackgroundTransparency = 1
ParticleContainer.ZIndex = 1
ParticleContainer.ClipsDescendants = true
ParticleContainer.Parent = Gui

local ActiveParticles = {}

local PARTICLE_CONFIGS = {
    snow   = { count = 40, speed = 35,  size = {3, 6},   drift = 18,  text = "•",  color = Color3.fromRGB(200, 220, 255), alpha = 0.55 },
    rain   = { count = 55, speed = 280, size = {2, 3},   drift = 40,  text = "|",  color = Color3.fromRGB(150, 190, 255), alpha = 0.35 },
    stars  = { count = 30, speed = 8,   size = {2, 5},   drift = 4,   text = "★",  color = Color3.fromRGB(255, 240, 180), alpha = 0.45 },
    sparks = { count = 35, speed = 55,  size = {3, 7},   drift = 60,  text = "✦",  color = ACCENT,                        alpha = 0.5  },
}

local function ClearParticles()
    for _, p in ipairs(ActiveParticles) do pcall(function() p:Destroy() end) end
    ActiveParticles = {}
end

local ParticleConn = nil

local function SpawnParticles(kind)
    ClearParticles()
    if ParticleConn then ParticleConn:Disconnect() ParticleConn = nil end
    if kind == "none" then return end

    local cfg = PARTICLE_CONFIGS[kind]
    if not cfg then return end

    local cam = workspace.CurrentCamera
    local vw  = cam and cam.ViewportSize.X or 400
    local vh  = cam and cam.ViewportSize.Y or 700

    local function MakeParticle()
        local sz = math.random(cfg.size[1] * 10, cfg.size[2] * 10) / 10
        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Text = cfg.text
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = sz * 3
        lbl.TextColor3 = (kind == "sparks") and ACCENT or cfg.color
        lbl.TextTransparency = cfg.alpha
        lbl.Size = UDim2.fromOffset(sz * 4, sz * 4)
        lbl.Position = UDim2.fromOffset(math.random(0, vw), math.random(-40, -4))
        lbl.ZIndex = 2
        lbl.Parent = ParticleContainer
        table.insert(ActiveParticles, lbl)
        return lbl
    end

    -- инициализируем с разброса по высоте чтобы не все стартовали сверху
    for i = 1, cfg.count do
        local p = MakeParticle()
        p.Position = UDim2.fromOffset(math.random(0, vw), math.random(0, vh))
    end

    -- анимационный цикл через Heartbeat
    local lastT = os.clock()
    ParticleConn = RunService.Heartbeat:Connect(function()
        local now = os.clock()
        local dt  = now - lastT
        lastT = now

        for i = #ActiveParticles, 1, -1 do
            local p = ActiveParticles[i]
            if not p.Parent then
                table.remove(ActiveParticles, i)
                continue
            end
            local py = p.Position.Y.Offset + cfg.speed * dt
            local px = p.Position.X.Offset + math.sin(now * 0.8 + i) * cfg.drift * dt
            if py > vh + 10 then
                -- перемещаем наверх
                p.Position = UDim2.fromOffset(math.random(0, vw), -10)
                if kind == "sparks" then p.TextColor3 = ACCENT end
            else
                p.Position = UDim2.fromOffset(px, py)
            end
        end
    end)
end

-- запускаем с дефолтными частицами после загрузки
task.delay(2.2, function()
    if VFX.Particle ~= "none" then SpawnParticles(VFX.Particle) end
end)

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.fromScale(0.5, 0.5)
MainFrame.Size = UDim2.fromOffset(780, 350)
MainFrame.BackgroundColor3 = C.Main
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Active = true
MainFrame.Parent = Gui
Corner(MainFrame, 10)
Stroke(MainFrame, C.Stroke, 1)

local SIDEBAR_W = 56

local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, SIDEBAR_W, 1, 0)
Sidebar.BackgroundColor3 = C.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

local Logo = Instance.new("TextLabel")
Logo.Size = UDim2.new(1, 0, 0, 44)
Logo.BackgroundTransparency = 1
Logo.Text = "NL"
Logo.TextColor3 = Color3.new(1, 1, 1)
Logo.TextSize = 17
Logo.Font = Enum.Font.GothamBold
Logo.Parent = Sidebar

local MenuScroll = Instance.new("ScrollingFrame")
MenuScroll.Size = UDim2.new(1, 0, 1, -100)
MenuScroll.Position = UDim2.fromOffset(0, 44)
MenuScroll.BackgroundTransparency = 1
MenuScroll.BorderSizePixel = 0
MenuScroll.ScrollBarThickness = 0
MenuScroll.ScrollingDirection = Enum.ScrollingDirection.Y
MenuScroll.CanvasSize = UDim2.new()
MenuScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
MenuScroll.Parent = Sidebar

local MenuLayout = Instance.new("UIListLayout")
MenuLayout.SortOrder = Enum.SortOrder.LayoutOrder
MenuLayout.Padding = UDim.new(0, 4)
MenuLayout.Parent = MenuScroll

local MenuPadding = Instance.new("UIPadding")
MenuPadding.PaddingLeft = UDim.new(0, 8)
MenuPadding.PaddingRight = UDim.new(0, 8)
MenuPadding.Parent = MenuScroll

local AvatarImage = Instance.new("ImageLabel")
AvatarImage.Name = "Avatar"
AvatarImage.AnchorPoint = Vector2.new(0.5, 1)
AvatarImage.Size = UDim2.fromOffset(38, 38)
AvatarImage.Position = UDim2.new(0.5, 0, 1, -8)
AvatarImage.BackgroundColor3 = Color3.fromRGB(20, 30, 45)
AvatarImage.BorderSizePixel = 0
AvatarImage.Parent = Sidebar
Corner(AvatarImage, 19)

task.spawn(function()
    local ok, content = pcall(function()
        return Players:GetUserThumbnailAsync(
            LocalPlayer.UserId,
            Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size420x420
        )
    end)
    if ok and AvatarImage.Parent then
        AvatarImage.Image = content
    end
end)

local ContentZone = Instance.new("Frame")
ContentZone.Name = "ContentZone"
ContentZone.Size = UDim2.new(1, -SIDEBAR_W, 1, 0)
ContentZone.Position = UDim2.new(0, SIDEBAR_W, 0, 0)
ContentZone.BackgroundColor3 = C.Content
ContentZone.BorderSizePixel = 0
ContentZone.Parent = MainFrame

local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 42)
Header.BackgroundTransparency = 1
Header.Parent = ContentZone

local HeaderTitle = NewLabel(Header, "RAGEBOT", 15, Enum.Font.GothamBold)
HeaderTitle.Position = UDim2.fromOffset(14, 0)
HeaderTitle.Size = UDim2.new(1, -160, 1, 0)
HeaderTitle.TextColor3 = Color3.new(1, 1, 1)
HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left

local PingLabel = NewLabel(Header, "-- ms", 11, Enum.Font.GothamBold)
PingLabel.AnchorPoint = Vector2.new(1, 0)
PingLabel.Position = UDim2.new(1, -50, 0, 0)
PingLabel.Size = UDim2.fromOffset(56, 42)
PingLabel.TextColor3 = ACCENT
PingLabel.TextXAlignment = Enum.TextXAlignment.Right

local CloseButton = Instance.new("TextButton")
CloseButton.AnchorPoint = Vector2.new(1, 0.5)
CloseButton.Size = UDim2.fromOffset(32, 32)
CloseButton.Position = UDim2.new(1, -8, 0.5, 0)
CloseButton.BackgroundColor3 = C.RowAlt
CloseButton.Text = "×"
CloseButton.TextColor3 = C.Text
CloseButton.TextSize = 20
CloseButton.Font = Enum.Font.GothamBold
CloseButton.AutoButtonColor = false
CloseButton.Parent = Header
Corner(CloseButton, 8)

local HeaderLine = Instance.new("Frame")
HeaderLine.Size = UDim2.new(1, 0, 0, 1)
HeaderLine.Position = UDim2.new(0, 0, 0, 42)
HeaderLine.BackgroundColor3 = C.Stroke
HeaderLine.BorderSizePixel = 0
HeaderLine.Parent = ContentZone

local Content = Instance.new("ScrollingFrame")
Content.Name = "Content"
Content.Size = UDim2.new(1, 0, 1, -43)
Content.Position = UDim2.fromOffset(0, 43)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 3
Content.ScrollBarImageColor3 = ACCENT
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.CanvasSize = UDim2.new()
Content.Parent = ContentZone

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.Padding = UDim.new(0, 8)
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Parent = Content

local ContentPadding = Instance.new("UIPadding")
ContentPadding.PaddingTop = UDim.new(0, 10)
ContentPadding.PaddingBottom = UDim.new(0, 18)
ContentPadding.PaddingLeft = UDim.new(0, 12)
ContentPadding.PaddingRight = UDim.new(0, 12)
ContentPadding.Parent = Content

-- forward declarations
local OpenTab
local AimNPCButton, AimPVPButton, FlyUpButton, FlyDownButton
local UpdateAimButtonsVisibility

-- ============================================================
-- DRAG SYSTEM
-- ============================================================

local function MakeDraggable(object, handle)
    local dragging = false
    local startPosition
    local startObjectPosition

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
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
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - startPosition
            object.Position = UDim2.new(
                startObjectPosition.X.Scale, startObjectPosition.X.Offset + delta.X,
                startObjectPosition.Y.Scale, startObjectPosition.Y.Offset + delta.Y
            )
        end
    end)
end

MakeDraggable(MainFrame, Header)

-- ============================================================
-- UI LIBRARY
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
    frame.Size = UDim2.new(1, 0, 0, 30)
    frame.BackgroundTransparency = 1
    frame.Parent = Content

    local label = NewLabel(frame, string.upper(text), 12, Enum.Font.GothamBold)
    label.Position = UDim2.fromOffset(2, 0)
    label.Size = UDim2.new(1, -4, 1, 0)
    label.TextColor3 = ACCENT
    label.TextXAlignment = Enum.TextXAlignment.Left
    return frame
end

local function Toggle(text, initial, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 0, 48)
    button.BackgroundColor3 = C.Row
    button.BorderSizePixel = 0
    button.Text = ""
    button.AutoButtonColor = false
    button.Parent = Content
    Corner(button, 8)

    local label = NewLabel(button, text, 13, Enum.Font.GothamMedium)
    label.Position = UDim2.fromOffset(14, 0)
    label.Size = UDim2.new(1, -88, 1, 0)
    label.TextColor3 = C.Text
    label.TextXAlignment = Enum.TextXAlignment.Left

    local switch = Instance.new("Frame")
    switch.AnchorPoint = Vector2.new(1, 0.5)
    switch.Position = UDim2.new(1, -12, 0.5, 0)
    switch.Size = UDim2.fromOffset(46, 26)
    switch.BorderSizePixel = 0
    switch.Parent = button
    Corner(switch, 13)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(20, 20)
    knob.AnchorPoint = Vector2.new(0, 0.5)
    knob.Position = UDim2.new(0, 3, 0.5, 0)
    knob.BorderSizePixel = 0
    knob.Parent = switch
    Corner(knob, 10)

    local value = initial == true

    local function Refresh(animate)
        if value then
            if animate and VFX.Animations then
                Tween(switch, { BackgroundColor3 = ACCENT }, 0.15)
                Tween(knob,   { Position = UDim2.new(1, -23, 0.5, 0), BackgroundColor3 = Color3.new(1,1,1) }, 0.18, Enum.EasingStyle.Back)
            else
                switch.BackgroundColor3 = ACCENT
                knob.BackgroundColor3 = Color3.new(1, 1, 1)
                knob.Position = UDim2.new(1, -23, 0.5, 0)
            end
        else
            if animate and VFX.Animations then
                Tween(switch, { BackgroundColor3 = Color3.fromRGB(30, 42, 58) }, 0.15)
                Tween(knob,   { Position = UDim2.new(0, 3, 0.5, 0), BackgroundColor3 = C.TextDim }, 0.18, Enum.EasingStyle.Back)
            else
                switch.BackgroundColor3 = Color3.fromRGB(30, 42, 58)
                knob.BackgroundColor3 = C.TextDim
                knob.Position = UDim2.new(0, 3, 0.5, 0)
            end
        end
    end

    button.Activated:Connect(function()
        value = not value
        Refresh(true)
        callback(value)
    end)

    Refresh(false)

    return {
        Set = function(v)
            value = v == true
            Refresh(true)
            callback(value)
        end,
        Get = function() return value end,
    }
end

local function Slider(text, min, max, initial, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 66)
    frame.BackgroundColor3 = C.Row
    frame.BorderSizePixel = 0
    frame.Parent = Content
    Corner(frame, 8)

    local label = NewLabel(frame, text, 12, Enum.Font.GothamMedium)
    label.Position = UDim2.fromOffset(14, 6)
    label.Size = UDim2.new(1, -90, 0, 20)
    label.TextColor3 = C.Text
    label.TextXAlignment = Enum.TextXAlignment.Left

    local valueLabel = NewLabel(frame, "", 12, Enum.Font.GothamBold)
    valueLabel.AnchorPoint = Vector2.new(1, 0)
    valueLabel.Position = UDim2.new(1, -14, 0, 6)
    valueLabel.Size = UDim2.fromOffset(60, 20)
    valueLabel.TextColor3 = ACCENT
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right

    local barZone = Instance.new("TextButton")
    barZone.Position = UDim2.new(0, 14, 0, 30)
    barZone.Size = UDim2.new(1, -28, 0, 30)
    barZone.BackgroundTransparency = 1
    barZone.Text = ""
    barZone.AutoButtonColor = false
    barZone.Parent = frame

    local bar = Instance.new("Frame")
    bar.AnchorPoint = Vector2.new(0, 0.5)
    bar.Position = UDim2.new(0, 0, 0.5, 0)
    bar.Size = UDim2.new(1, 0, 0, 8)
    bar.BackgroundColor3 = Color3.fromRGB(24, 38, 56)
    bar.BorderSizePixel = 0
    bar.Parent = barZone
    Corner(bar, 4)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.fromScale(0, 1)
    fill.BackgroundColor3 = ACCENT
    fill.BorderSizePixel = 0
    fill.Parent = bar
    Corner(fill, 4)

    local knob = Instance.new("Frame")
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Size = UDim2.fromOffset(22, 22)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel = 0
    knob.Parent = barZone
    Corner(knob, 11)
    Stroke(knob, ACCENT, 2)

    local value = initial

    local function SetValue(v)
        value = math.clamp(v, min, max)
        local alpha = (value - min) / (max - min)
        fill.Size = UDim2.fromScale(alpha, 1)
        knob.Position = UDim2.new(alpha, 0, 0.5, 0)
        valueLabel.Text = tostring(math.floor(value))
        callback(value)
    end

    local dragging = false

    local function Update(input)
        local alpha = math.clamp(
            (input.Position.X - barZone.AbsolutePosition.X) / math.max(barZone.AbsoluteSize.X, 1),
            0, 1
        )
        SetValue(min + (max - min) * alpha)
    end

    barZone.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            Update(input)
        end
    end)

    barZone.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    barZone.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            Update(input)
        end
    end)

    SetValue(value)
end

local function Action(text, callback, styleColor)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 0, 46)
    button.BackgroundColor3 = C.RowAlt
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = styleColor or C.Text
    button.TextSize = 13
    button.Font = Enum.Font.GothamBold
    button.AutoButtonColor = false
    button.Parent = Content
    Corner(button, 8)
    Stroke(button, styleColor or C.Stroke, 1)

    button.Activated:Connect(function()
        local old = button.BackgroundColor3
        button.BackgroundColor3 = styleColor or ACCENT
        task.delay(0.12, function()
            if button.Parent then button.BackgroundColor3 = old end
        end)
        callback()
    end)

    return button
end

local function Info(text, height)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, height or 56)
    label.BackgroundColor3 = C.Row
    label.BorderSizePixel = 0
    label.Text = text
    label.TextWrapped = true
    label.TextColor3 = C.TextDim
    label.TextSize = 11
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = Content
    Corner(label, 8)

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 12)
    pad.PaddingRight = UDim.new(0, 12)
    pad.Parent = label

    return label
end

local function ColorRow(text, color)
    local label = NewLabel(Content, text, 12, Enum.Font.GothamBold)
    label.Size = UDim2.new(1, 0, 0, 32)
    label.BackgroundColor3 = C.Row
    label.TextColor3 = color
    label.TextXAlignment = Enum.TextXAlignment.Left
    Corner(label, 8)

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 12)
    pad.Parent = label

    return label
end

-- ============================================================
-- DRAWING SYSTEM (tracers + FOV circle)
-- ============================================================

local HasDrawing = false
pcall(function()
    if Drawing and Drawing.new then HasDrawing = true end
end)

local TracerLines = {}
local FOVCircle = nil

local function GetTracerLine(key)
    local line = TracerLines[key]
    if not line and HasDrawing then
        local ok, newLine = pcall(function() return Drawing.new("Line") end)
        if ok and newLine then
            newLine.Thickness = 1.5
            newLine.Transparency = 1
            newLine.Visible = false
            TracerLines[key] = newLine
            line = newLine
        end
    end
    return line
end

local function RemoveTracer(key)
    local line = TracerLines[key]
    if line then
        pcall(function() line:Remove() end)
        TracerLines[key] = nil
    end
end

local function ClearAllDrawings()
    for _, line in pairs(TracerLines) do
        pcall(function() line:Remove() end)
    end
    TracerLines = {}
    if FOVCircle then
        pcall(function() FOVCircle:Remove() end)
        FOVCircle = nil
    end
end

if HasDrawing then
    local ok, circle = pcall(function() return Drawing.new("Circle") end)
    if ok and circle then
        FOVCircle = circle
        FOVCircle.Thickness = 1.5
        FOVCircle.NumSides = 40
        FOVCircle.Filled = false
        FOVCircle.Transparency = 1
        FOVCircle.Color = ACCENT
        FOVCircle.Visible = false
    end
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
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        Lighting.ColorShift_Top = Color3.new(0, 0, 0)
        Lighting.ColorShift_Bottom = Color3.new(0, 0, 0)
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
    for _, object in ipairs(workspace:GetDescendants()) do
        if object:IsA("ParticleEmitter") or object:IsA("Trail") or object:IsA("Beam") then
            object.Enabled = false
        elseif object:IsA("PostEffect") then
            object.Enabled = false
        end
    end
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
    RemoveTracer(player)
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
        billboard.Size = UDim2.fromOffset(220, 60)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.Enabled = ESP.Enabled
        SecureParent(billboard)

        local name = NewLabel(billboard, "[P] " .. player.DisplayName, 13, Enum.Font.GothamBold)
        name.Size = UDim2.new(1, 0, 0, 22)
        name.TextColor3 = Color3.new(1, 1, 1)

        local info = NewLabel(billboard, "", 11)
        info.Size = UDim2.new(1, 0, 0, 20)
        info.Position = UDim2.fromOffset(0, 20)
        info.TextColor3 = Color3.fromRGB(220, 220, 220)

        local healthBack = Instance.new("Frame")
        healthBack.Position = UDim2.new(0.5, -45, 0, 44)
        healthBack.Size = UDim2.fromOffset(90, 4)
        healthBack.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        healthBack.BorderSizePixel = 0
        healthBack.Parent = billboard
        Corner(healthBack, 3)

        local health = Instance.new("Frame")
        health.Size = UDim2.fromScale(1, 1)
        health.BackgroundColor3 = Color3.fromRGB(70, 220, 100)
        health.BorderSizePixel = 0
        health.Parent = healthBack
        Corner(health, 3)

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

    if player.Character then task.spawn(Attach, player.Character) end

    data.Connection = player.CharacterAdded:Connect(function()
        RemovePlayerESP(player)
        task.wait(0.15)
        CreatePlayerESP(player)
    end)
end

local function UpdatePlayerESP(player, data)
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
    local allowed = ESP.Enabled
        and distance <= ESP.MaxDistance
        and not (ESP.TeamCheck and SameTeam(player))

    if data.Billboard then data.Billboard.Enabled = allowed end
    if data.Highlight then data.Highlight.Enabled = allowed and ESP.Chams end
    if not allowed then return end

    data.Name.Visible = ESP.Names
    data.Info.Visible = ESP.Distance

    local text = ""
    if ESP.Distance then text = string.format("%dm", math.floor(distance)) end
    if ESP.Health then
        if text ~= "" then text = text .. "  " end
        text = text .. string.format("%d HP", math.floor(hum.Health))
    end
    data.Info.Text = text

    if ESP.Health then
        data.HealthBack.Visible = true
        data.Health.Size = UDim2.fromScale(math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1), 1)
    else
        data.HealthBack.Visible = false
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then task.spawn(CreatePlayerESP, player) end
end
Players.PlayerAdded:Connect(function(player) task.spawn(CreatePlayerESP, player) end)
Players.PlayerRemoving:Connect(RemovePlayerESP)

-- ============================================================
-- NPC / AI ESP
-- ============================================================

local NPCMarkers = {}

local EXCLUDED_FOLDERS = {
    ViewModels = true,
    ThirdPersonModels = true,
    RealClothing = true,
    ViewModelClothing = true,
    VFX = true,
    SFX = true,
    Temp = true,
    Wrecks = true,
    Vehicles = true,
    PhysicsProjectiles = true,
    DropModels = true,
}

local function InExcludedZone(instance)
    local ancestor = instance.Parent
    while ancestor and ancestor ~= workspace do
        if EXCLUDED_FOLDERS[ancestor.Name] then
            return true
        end
        ancestor = ancestor.Parent
    end
    return false
end

local function ClassifyModel(model)
    if not model:IsA("Model") then return nil end
    if model == LocalPlayer.Character then return nil end
    if Players:GetPlayerFromCharacter(model) then return nil end
    if InExcludedZone(model) then return nil end

    local hum = GetHumanoid(model)
    local root = GetRoot(model)
    if not hum or not root then return nil end

    local subtype = "AI"
    local haystack = string.lower(model.Name)
    for _, tag in ipairs(CollectionService:GetTags(model)) do
        haystack = haystack .. " " .. string.lower(tag)
    end
    for attrName in pairs(model:GetAttributes()) do
        haystack = haystack .. " " .. string.lower(attrName)
    end

    if haystack:find("zombie") then
        subtype = "ZOMBIE"
    elseif haystack:find("bot") then
        subtype = "BOT"
    elseif haystack:find("npc") then
        subtype = "NPC"
    end

    return subtype
end

local function RemoveNPCESP(model)
    local data = NPCMarkers[model]
    if not data then return end
    if data.Billboard then data.Billboard:Destroy() end
    if data.Highlight then data.Highlight:Destroy() end
    RemoveTracer(model)
    NPCMarkers[model] = nil
end

local function ClearNPCs()
    for model in pairs(NPCMarkers) do
        RemoveNPCESP(model)
    end
end

local function CreateNPCESP(model, subtype)
    if NPCMarkers[model] then return end
    local head = model:FindFirstChild("Head") or GetRoot(model)
    if not head then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ProjectDeltaNPC"
    billboard.Adornee = head
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.fromOffset(200, 56)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.Enabled = NPC.Enabled
    SecureParent(billboard)

    local name = NewLabel(billboard, "", 12, Enum.Font.GothamBold)
    name.Size = UDim2.new(1, 0, 0, 20)
    name.TextColor3 = NPC.Color

    local info = NewLabel(billboard, "", 10)
    info.Size = UDim2.new(1, 0, 0, 18)
    info.Position = UDim2.fromOffset(0, 18)
    info.TextColor3 = Color3.fromRGB(225, 225, 225)

    local healthBack = Instance.new("Frame")
    healthBack.Position = UDim2.new(0.5, -45, 0, 40)
    healthBack.Size = UDim2.fromOffset(90, 4)
    healthBack.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    healthBack.BorderSizePixel = 0
    healthBack.Parent = billboard
    Corner(healthBack, 3)

    local health = Instance.new("Frame")
    health.Size = UDim2.fromScale(1, 1)
    health.BackgroundColor3 = NPC.Color
    health.BorderSizePixel = 0
    health.Parent = healthBack
    Corner(health, 3)

    local highlight = Instance.new("Highlight")
    highlight.Name = "ProjectDeltaNPCChams"
    highlight.Adornee = model
    highlight.FillColor = NPC.Color
    highlight.OutlineColor = NPC.Color
    highlight.FillTransparency = 0.8
    highlight.OutlineTransparency = 0.05
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = NPC.Enabled and NPC.Chams
    highlight.Parent = model

    NPCMarkers[model] = {
        Billboard = billboard,
        Highlight = highlight,
        Name = name,
        Info = info,
        HealthBack = healthBack,
        Health = health,
        Subtype = subtype,
    }
end

local function ScanNPCs()
    for _, instance in ipairs(workspace:GetDescendants()) do
        if instance:IsA("Model") and not NPCMarkers[instance] then
            local subtype = ClassifyModel(instance)
            if subtype then
                CreateNPCESP(instance, subtype)
            end
        end
    end
end

local function UpdateNPCESP(model, data)
    if not model:IsDescendantOf(workspace) then
        RemoveNPCESP(model)
        return
    end

    local hum = GetHumanoid(model)
    local root = GetRoot(model)
    if not hum or not root then
        RemoveNPCESP(model)
        return
    end

    if hum.Health <= 0 then
        data.Billboard.Enabled = false
        data.Highlight.Enabled = false
        return
    end

    local distance = DistanceFromPlayer(root.Position)
    local allowed = NPC.Enabled and distance <= NPC.MaxDistance
    data.Billboard.Enabled = allowed
    data.Highlight.Enabled = allowed and NPC.Chams
    if not allowed then return end

    data.Name.Visible = NPC.Names
    data.Name.Text = string.format("[%s] %s", data.Subtype, model.Name)

    local text = ""
    if NPC.Distance then text = string.format("%dm", math.floor(distance)) end
    if NPC.Health then
        if text ~= "" then text = text .. "  " end
        text = text .. string.format("%d HP", math.floor(hum.Health))
    end
    data.Info.Text = text
    data.Info.Visible = (NPC.Distance or NPC.Health)

    if NPC.Health then
        data.HealthBack.Visible = true
        data.Health.Size = UDim2.fromScale(math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1), 1)
    else
        data.HealthBack.Visible = false
    end
end

-- ============================================================
-- TRACER & FOV UPDATE
-- ============================================================

local function UpdateTracers()
    if not HasDrawing then return end
    local cam = Camera()
    if not cam then return end

    local vs = cam.ViewportSize
    local origin = Vector2.new(vs.X / 2, vs.Y - 4)

    for player, data in pairs(PlayerESP) do
        local show = false
        local line = TracerLines[player]

        if ESP.Enabled and ESP.Tracers and data.Character then
            local hum = GetHumanoid(data.Character)
            local root = GetRoot(data.Character)
            if hum and root and hum.Health > 0 then
                local distance = DistanceFromPlayer(root.Position)
                if distance <= ESP.MaxDistance and not (ESP.TeamCheck and SameTeam(player)) then
                    local screen, onScreen = cam:WorldToViewportPoint(root.Position)
                    if onScreen and screen.Z > 0 then
                        line = line or GetTracerLine(player)
                        if line then
                            line.From = origin
                            line.To = Vector2.new(screen.X, screen.Y)
                            line.Color = ACCENT
                            show = true
                        end
                    end
                end
            end
        end

        if line then line.Visible = show end
    end

    for model, data in pairs(NPCMarkers) do
        local show = false
        local line = TracerLines[model]

        if NPC.Enabled and NPC.Tracers and model:IsDescendantOf(workspace) then
            local hum = GetHumanoid(model)
            local root = GetRoot(model)
            if hum and root and hum.Health > 0 then
                local distance = DistanceFromPlayer(root.Position)
                if distance <= NPC.MaxDistance then
                    local screen, onScreen = cam:WorldToViewportPoint(root.Position)
                    if onScreen and screen.Z > 0 then
                        line = line or GetTracerLine(model)
                        if line then
                            line.From = origin
                            line.To = Vector2.new(screen.X, screen.Y)
                            line.Color = NPC.Color
                            show = true
                        end
                    end
                end
            end
        end

        if line then line.Visible = show end
    end
end

local function UpdateFOVCircle()
    if not HasDrawing or not FOVCircle then return end
    local cam = Camera()
    if not cam then return end

    local vs = cam.ViewportSize
    FOVCircle.Position = Vector2.new(vs.X / 2, vs.Y / 2)
    FOVCircle.Radius = AIM.FOV
    FOVCircle.Color = (AIM.HoldMode ~= "none") and Color3.new(1, 1, 1) or ACCENT
    FOVCircle.Visible = AIM.Enabled and UIState.ShowFOV
end

-- ============================================================
-- UNIVERSAL THREAT ESP
-- ============================================================

local ThreatESP = {}

local ThreatTypes = {
    Mine = { Text = "MINE", Color = Color3.fromRGB(255, 60, 60) },
    Tripwire = { Text = "TRIPWIRE", Color = Color3.fromRGB(255, 150, 40) },
    Grenade = { Text = "GRENADE", Color = Color3.fromRGB(255, 210, 60) },
    Trap = { Text = "TRAP", Color = Color3.fromRGB(200, 70, 255) },
    Threat = { Text = "THREAT", Color = Color3.fromRGB(255, 60, 60) },
}

local function CleanName(name)
    return string.lower(tostring(name)):gsub("[%s_%-%./]", "")
end

local function DetectThreat(instance)
    local strings = { instance.Name }
    local parent = instance.Parent
    for i = 1, 5 do
        if not parent then break end
        table.insert(strings, parent.Name)
        parent = parent.Parent
    end
    for _, tag in ipairs(CollectionService:GetTags(instance)) do
        table.insert(strings, tag)
    end

    local text = CleanName(table.concat(strings, " "))
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
    billboard.Size = UDim2.fromOffset(160, 40)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.Enabled = THREAT.Enabled
    SecureParent(billboard)

    local label = NewLabel(billboard, config.Text, 12, Enum.Font.GothamBold)
    label.Size = UDim2.fromScale(1, 1)
    label.TextColor3 = config.Color
    label.TextStrokeTransparency = 0.1

    local highlight = Instance.new("Highlight")
    highlight.Name = "ProjectDeltaThreatHighlight"
    if instance:IsA("Model") then
        highlight.Adornee = instance
    else
        highlight.Adornee = part
    end
    highlight.FillColor = config.Color
    highlight.OutlineColor = config.Color
    highlight.FillTransparency = 0.75
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = THREAT.Enabled
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
    for _, instance in ipairs(workspace:GetDescendants()) do
        if instance:IsA("Model") or instance:IsA("BasePart") then
            CreateThreat(instance)
        end
    end
end

workspace.DescendantAdded:Connect(function(instance)
    task.defer(function()
        if instance:IsA("Model") or instance:IsA("BasePart") then
            CreateThreat(instance)
        end
    end)
end)
workspace.DescendantRemoving:Connect(RemoveThreat)

local function UpdateThreat(instance, data)
    if not instance:IsDescendantOf(workspace) or not data.Part or not data.Part.Parent then
        RemoveThreat(instance)
        return
    end
    local distance = DistanceFromPlayer(data.Part.Position)
    local enabled = THREAT.Enabled and distance <= THREAT.MaxDistance
    data.Billboard.Enabled = enabled
    data.Highlight.Enabled = enabled
    if enabled then
        local config = ThreatTypes[data.Type]
        data.Label.Text = string.format("%s  %dm", config.Text, math.floor(distance))
    end
end

-- ============================================================
-- AIM (dual pool: players / NPCs, hold + tap-lock)
-- ============================================================

local function FindAimTargetPlayers()
    local cam = Camera()
    if not cam then return nil end

    local viewport = cam.ViewportSize
    local center = Vector2.new(viewport.X / 2, viewport.Y / 2)
    local best = nil
    local bestDistance = math.huge
    local localRoot = GetRoot(LocalPlayer.Character)

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if AIM.TeamCheck and SameTeam(player) then continue end

        local character = player.Character
        if not IsAlive(character) then continue end

        local root = GetRoot(character)
        local bone = GetBone(character)
        if not root or not bone then continue end
        if localRoot and (root.Position - localRoot.Position).Magnitude > AIM.MaxDistance then continue end
        if AIM.RequireVisible and not IsVisible(bone.Position, character) then continue end

        local screen, onScreen = cam:WorldToViewportPoint(bone.Position)
        if not onScreen or screen.Z <= 0 then continue end

        local screenDistance = (Vector2.new(screen.X, screen.Y) - center).Magnitude
        if screenDistance <= AIM.FOV and screenDistance < bestDistance then
            bestDistance = screenDistance
            best = bone
        end
    end

    return best
end

local function FindAimTargetNPCs()
    local cam = Camera()
    if not cam then return nil end

    local viewport = cam.ViewportSize
    local center = Vector2.new(viewport.X / 2, viewport.Y / 2)
    local best = nil
    local bestDistance = math.huge
    local localRoot = GetRoot(LocalPlayer.Character)

    for model in pairs(NPCMarkers) do
        if not model:IsDescendantOf(workspace) then continue end

        local hum = GetHumanoid(model)
        local root = GetRoot(model)
        if not hum or not root or hum.Health <= 0 then continue end
        if localRoot and (root.Position - localRoot.Position).Magnitude > AIM.MaxDistance then continue end

        local bone = GetBone(model)
        if not bone then continue end
        if AIM.RequireVisible and not IsVisible(bone.Position, model) then continue end

        local screen, onScreen = cam:WorldToViewportPoint(bone.Position)
        if not onScreen or screen.Z <= 0 then continue end

        local screenDistance = (Vector2.new(screen.X, screen.Y) - center).Magnitude
        if screenDistance <= AIM.FOV and screenDistance < bestDistance then
            bestDistance = screenDistance
            best = bone
        end
    end

    return best
end

local function ValidAimTarget(target)
    if not target or not target.Parent then return false end
    local character = target.Parent
    local hum = GetHumanoid(character)
    if not hum or hum.Health <= 0 then return false end

    local root = GetRoot(character)
    local localRoot = GetRoot(LocalPlayer.Character)
    if root and localRoot and (root.Position - localRoot.Position).Magnitude > AIM.MaxDistance then
        return false
    end
    if AIM.RequireVisible and not IsVisible(target.Position, character) then
        return false
    end
    return true
end

local function ClearAim()
    AIM.Target = nil
    AIM.TargetKind = nil
    AIM.HoldMode = "none"
    AIM.LockKind = nil
    AIM.LockUntil = 0
end

-- ============================================================
-- LOOT / WAYPOINT / MOVEMENT / ANTI-AFK
-- ============================================================

local SHUTDOWN = false

local LootESP = { Enabled = false, MaxDistance = 500 }
local LootMarkers = {}

local function PartOf(instance)
    if instance:IsA("BasePart") then return instance end
    if instance:IsA("Model") and instance.PrimaryPart then return instance.PrimaryPart end
    return instance:FindFirstChildWhichIsA("BasePart", true)
end

local function RemoveLootMarker(instance)
    local data = LootMarkers[instance]
    if not data then return end
    if data.Billboard then data.Billboard:Destroy() end
    if data.Highlight then data.Highlight:Destroy() end
    LootMarkers[instance] = nil
end

local function ClearLoot()
    for instance in pairs(LootMarkers) do
        RemoveLootMarker(instance)
    end
end

local function CreateLootMarker(instance)
    if SHUTDOWN then return end
    if LootMarkers[instance] then return end

    local root = workspace:FindFirstChild("LootContainers")
    if not root or not instance:IsDescendantOf(root) then return end

    local part = PartOf(instance)
    if not part then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ProjectDeltaLoot"
    billboard.Adornee = part
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.fromOffset(170, 34)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.Enabled = LootESP.Enabled
    SecureParent(billboard)

    local label = NewLabel(billboard, instance.Name, 12, Enum.Font.GothamBold)
    label.Size = UDim2.fromScale(1, 1)
    label.TextColor3 = Color3.fromRGB(120, 220, 255)
    label.TextStrokeTransparency = 0.1

    local highlight = Instance.new("Highlight")
    highlight.Name = "ProjectDeltaLootHighlight"
    highlight.Adornee = instance:IsA("Model") and instance or part
    highlight.FillColor = Color3.fromRGB(120, 220, 255)
    highlight.OutlineColor = Color3.fromRGB(120, 220, 255)
    highlight.FillTransparency = 0.85
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = LootESP.Enabled
    highlight.Parent = instance:IsA("Model") and instance or workspace

    LootMarkers[instance] = { Billboard = billboard, Highlight = highlight, Label = label, Part = part }
end

local function ScanLoot()
    local root = workspace:FindFirstChild("LootContainers")
    if not root then return end
    for _, instance in ipairs(root:GetDescendants()) do
        if instance:IsA("Model") or instance:IsA("BasePart") then
            CreateLootMarker(instance)
        end
    end
end

local lootRoot = workspace:FindFirstChild("LootContainers")
if lootRoot then
    lootRoot.DescendantAdded:Connect(function(instance)
        task.defer(function()
            if instance:IsA("Model") or instance:IsA("BasePart") then
                CreateLootMarker(instance)
            end
        end)
    end)
    lootRoot.DescendantRemoving:Connect(RemoveLootMarker)
end

local Waypoint = { Position = nil, Billboard = nil, Label = nil, Anchor = nil }

local function ClearWaypoint()
    if Waypoint.Billboard then Waypoint.Billboard:Destroy() end
    if Waypoint.Anchor then Waypoint.Anchor:Destroy() end
    Waypoint.Billboard = nil
    Waypoint.Label = nil
    Waypoint.Anchor = nil
    Waypoint.Position = nil
end

local function SetWaypoint(position)
    ClearWaypoint()
    Waypoint.Position = position

    local anchor = Instance.new("Part")
    anchor.Name = "ProjectDeltaWaypointAnchor"
    anchor.Anchored = true
    anchor.CanCollide = false
    anchor.CanQuery = false
    anchor.CanTouch = false
    anchor.Transparency = 1
    anchor.Size = Vector3.new(1, 1, 1)
    anchor.CFrame = CFrame.new(position)
    anchor.Parent = workspace

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ProjectDeltaWaypoint"
    billboard.Adornee = anchor
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.fromOffset(150, 30)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    SecureParent(billboard)

    local label = NewLabel(billboard, "WAYPOINT", 12, Enum.Font.GothamBold)
    label.Size = UDim2.fromScale(1, 1)
    label.TextColor3 = Color3.fromRGB(255, 200, 60)
    label.TextStrokeTransparency = 0.1

    Waypoint.Billboard = billboard
    Waypoint.Label = label
    Waypoint.Anchor = anchor
end

local function SetWaypointAtAim()
    local cam = Camera()
    if not cam then return end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true
    params.FilterDescendantsInstances = { LocalPlayer.Character }
    local result = workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * 500, params)
    if result then
        SetWaypoint(result.Position)
    else
        SetWaypoint(cam.CFrame.Position + cam.CFrame.LookVector * 100)
    end
end

local MOVE = { Speed = 16, Jump = 50, Noclip = false, Fly = false, FlySpeed = 50, FlyVertical = 0 }
local flyBV = nil
local flyBG = nil

local function UpdateFlyButtonsVisibility()
    local visible = MOVE.Fly and UIState.ShowFlyControls
    if FlyUpButton then FlyUpButton.Visible = visible end
    if FlyDownButton then FlyDownButton.Visible = visible end
end

local function StopFly()
    MOVE.Fly = false
    MOVE.FlyVertical = 0
    if flyBV then flyBV:Destroy() flyBV = nil end
    if flyBG then flyBG:Destroy() flyBG = nil end
    UpdateFlyButtonsVisibility()
end

local function StartFly()
    local root = GetRoot(LocalPlayer.Character)
    if not root then return end
    StopFly()
    MOVE.Fly = true
    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    flyBV.Velocity = Vector3.zero
    flyBV.Parent = root
    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    flyBG.P = 9e4
    flyBG.Parent = root
    UpdateFlyButtonsVisibility()
end

local AntiAFK = { Enabled = false, Connection = nil }

local function SetAntiAFK(enabled)
    AntiAFK.Enabled = enabled
    if AntiAFK.Connection then
        AntiAFK.Connection:Disconnect()
        AntiAFK.Connection = nil
    end
    if enabled then
        AntiAFK.Connection = LocalPlayer.Idled:Connect(function()
            local vu = game:GetService("VirtualUser")
            local cam = Camera()
            if cam then
                vu:Button2Down(Vector2.new(0, 0), cam.CFrame)
                task.wait(0.1)
                vu:Button2Up(Vector2.new(0, 0), cam.CFrame)
            end
        end)
    end
end

-- ============================================================
-- PANIC
-- ============================================================

local function Panic()
    SHUTDOWN = true
    ESP.Enabled = false
    NPC.Enabled = false
    THREAT.Enabled = false
    AIM.Enabled = false
    ClearAim()
    LootESP.Enabled = false
    MOVE.Noclip = false
    StopFly()
    SetAntiAFK(false)
    ClearWaypoint()
    ClearLoot()
    ClearNPCs()
    ClearAllDrawings()

    for _, container in ipairs({ CoreGui, PlayerGui }) do
        for _, obj in ipairs(container:GetChildren()) do
            if obj.Name:find("ProjectDelta") or obj.Name == "NeverloseUI" then
                obj:Destroy()
            end
        end
    end
    if gethui then
        pcall(function()
            for _, obj in ipairs(gethui():GetChildren()) do
                if obj.Name:find("ProjectDelta") or obj.Name == "NeverloseUI" then
                    obj:Destroy()
                end
            end
        end)
    end
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj.Name == "ProjectDeltaWaypointAnchor" then
            obj:Destroy()
        end
    end
    print("[Neverlose Mobile] PANIC: интерфейс, маркеры и drawing уничтожены.")
end

-- ============================================================
-- DB VIEWER
-- ============================================================

local DB_WEAPON = { "RangedWeapons", "AmmoTypes" }
local DB_ITEMS = { "ItemsList", "DefaultSettings" }

local function DumpIntoContent(folderName)
    ClearContent()
    Section("DB: " .. folderName)

    local root = game:GetService("ReplicatedStorage"):FindFirstChild(folderName)
        or workspace:FindFirstChild(folderName)

    if not root then
        local miss = NewLabel(Content, "Папка не найдена: " .. folderName, 12)
        miss.Size = UDim2.new(1, 0, 0, 34)
        miss.TextColor3 = C.Danger
        miss.TextXAlignment = Enum.TextXAlignment.Left
        return
    end

    local rows = 0
    local MAX_ROWS = 250

    local function visit(instance, depth)
        if rows >= MAX_ROWS then return end
        local line = string.rep("   ", depth) .. instance.Name .. "  [" .. instance.ClassName .. "]"
        if instance:IsA("ValueBase") then
            line = line .. " = " .. tostring(instance.Value)
        end
        for attrName, attrValue in pairs(instance:GetAttributes()) do
            line = line .. string.format("  {%s=%s}", attrName, tostring(attrValue))
        end
        local label = NewLabel(Content, line, 10)
        label.Size = UDim2.new(1, 0, 0, 20)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextColor3 = depth == 0 and Color3.fromRGB(120, 220, 255) or Color3.fromRGB(190, 190, 200)
        rows += 1
        if depth < 2 then
            for _, child in ipairs(instance:GetChildren()) do
                visit(child, depth + 1)
            end
        end
    end

    visit(root, 0)

    Info("Строк: " .. rows .. (rows >= MAX_ROWS and " (лимит 250)" or ""), 34)
end

-- ============================================================
-- CONFIG SAVE / LOAD
-- ============================================================

local CONFIG_PATH = "NeverloseMobile_Config.json"

local function CollectConfig()
    return {
        ESP = {
            Enabled = ESP.Enabled, Names = ESP.Names, Distance = ESP.Distance,
            Health = ESP.Health, TeamCheck = ESP.TeamCheck, Chams = ESP.Chams,
            Tracers = ESP.Tracers, MaxDistance = ESP.MaxDistance,
        },
        NPC = {
            Enabled = NPC.Enabled, Names = NPC.Names, Distance = NPC.Distance,
            Health = NPC.Health, Chams = NPC.Chams, Tracers = NPC.Tracers,
            MaxDistance = NPC.MaxDistance,
        },
        THREAT = { Enabled = THREAT.Enabled, MaxDistance = THREAT.MaxDistance },
        AIM = {
            Enabled = AIM.Enabled, TeamCheck = AIM.TeamCheck,
            RequireVisible = AIM.RequireVisible, FOV = AIM.FOV,
            Smoothness = AIM.Smoothness, MaxDistance = AIM.MaxDistance, Bone = AIM.Bone,
        },
        LootESP = { Enabled = LootESP.Enabled, MaxDistance = LootESP.MaxDistance },
        MOVE = { Speed = MOVE.Speed, Jump = MOVE.Jump, FlySpeed = MOVE.FlySpeed },
        UIState = {
            ShowAimButtons = UIState.ShowAimButtons,
            ShowFOV = UIState.ShowFOV,
            ShowFlyControls = UIState.ShowFlyControls,
        },
        FULLBRIGHT = FULLBRIGHT,
        FPS_BOOST = FPS_BOOST,
    }
end

local DEFAULTS = CollectConfig()

local function ApplyConfig(data)
    if type(data) ~= "table" then return end

    local function merge(dst, src)
        if type(src) ~= "table" then return end
        for k, v in pairs(src) do
            if dst[k] ~= nil and type(v) ~= "table" then
                dst[k] = v
            end
        end
    end

    merge(ESP, data.ESP)
    merge(NPC, data.NPC)
    merge(THREAT, data.THREAT)
    merge(AIM, data.AIM)
    merge(LootESP, data.LootESP)
    merge(MOVE, data.MOVE)
    merge(UIState, data.UIState)

    if data.FULLBRIGHT ~= nil then FULLBRIGHT = data.FULLBRIGHT end
    if data.FPS_BOOST ~= nil then FPS_BOOST = data.FPS_BOOST end

    ClearAim()

    if FULLBRIGHT then SetFullbright(true) end
    if FPS_BOOST then ApplyFPSBoost() end
end

local function SaveConfig()
    pcall(function()
        if writefile then
            writefile(CONFIG_PATH, HttpService:JSONEncode(CollectConfig()))
        end
    end)
end

local function LoadConfig()
    local ok = pcall(function()
        if readfile and isfile and isfile(CONFIG_PATH) then
            ApplyConfig(HttpService:JSONDecode(readfile(CONFIG_PATH)))
        end
    end)
    return ok
end

-- ============================================================
-- TAB BUILDERS
-- ============================================================

local Tabs = {}
local CurrentTab = nil

local function BuildRagebot()
    Section("AIM")
    Toggle("Enable AIM", AIM.Enabled, function(value)
        AIM.Enabled = value
        if not value then ClearAim() end
        UpdateAimButtonsVisibility()
    end)
    Slider("FOV", 30, 600, AIM.FOV, function(value) AIM.FOV = value end)
    Slider("Smoothness", 1, 100, math.floor(AIM.Smoothness * 100), function(value)
        AIM.Smoothness = math.clamp(value / 100, 0.01, 1)
    end)
    Slider("Max Distance", 50, 3000, AIM.MaxDistance, function(value) AIM.MaxDistance = value end)
    Toggle("Team Check (PVP only)", AIM.TeamCheck, function(value) AIM.TeamCheck = value end)
    Toggle("Require Line Of Sight", AIM.RequireVisible, function(value) AIM.RequireVisible = value end)

    Section("ON-SCREEN CONTROL")
    Toggle("Show Aim Buttons", UIState.ShowAimButtons, function(value)
        UIState.ShowAimButtons = value
        UpdateAimButtonsVisibility()
    end)
    Toggle("Show FOV Circle", UIState.ShowFOV, function(value) UIState.ShowFOV = value end)
    Action("CLEAR AIM TARGET", ClearAim)
    Info("При включенном AIM на экране появляются кнопки: оранжевая NPC и красная PVP. Удерживай — аим непрерывно ведет цель. Быстрый тап — фиксирует ближайшую цель на 1.5 сек. Цель липкая: пока жива, аим ее не бросает.", 84)
end

local function BuildAntiAim()
    Section("ANTI AIM")
    Info("В этой сборке раздела нет. Место зарезервировано.", 40)
end

local function BuildLegitbot()
    Section("PRESETS")
    Action("SOFT AIM (FOV 100 / SMOOTH 45)", function()
        AIM.FOV = 100
        AIM.Smoothness = 0.45
        AIM.RequireVisible = true
    end)
    Action("STANDARD (FOV 180 / SMOOTH 20)", function()
        AIM.FOV = 180
        AIM.Smoothness = 0.20
        AIM.RequireVisible = false
    end)
    Info("Пресеты меняют значения аима. Сам аим включается во вкладке Ragebot.", 48)
end

local function BuildPlayers()
    Section("PLAYER ESP")
    Toggle("Enable ESP", ESP.Enabled, function(value) ESP.Enabled = value end)
    Toggle("Names", ESP.Names, function(value) ESP.Names = value end)
    Toggle("Distance", ESP.Distance, function(value) ESP.Distance = value end)
    Toggle("Health Bar", ESP.Health, function(value) ESP.Health = value end)
    Toggle("Team Check", ESP.TeamCheck, function(value) ESP.TeamCheck = value end)
    Toggle("Chams", ESP.Chams, function(value) ESP.Chams = value end)
    Toggle("Tracers", ESP.Tracers, function(value) ESP.Tracers = value end)
    Slider("Max Distance", 50, 3000, ESP.MaxDistance, function(value) ESP.MaxDistance = value end)
    if not HasDrawing then
        Info("Drawing API недоступен в этом эксплойте — трассеры и FOV-круг работать не будут. Остальной вх работает.", 48)
    end
end

local function BuildWeapon()
    Section("ARSENAL DATABASE")
    for _, source in ipairs(DB_WEAPON) do
        Action("OPEN: " .. source, function() DumpIntoContent(source) end)
    end
    Info("Читает реплицированные таблицы оружия и патронов. Только чтение.", 40)
end

local function BuildGrenades()
    Section("UNIVERSAL THREAT ESP")
    Toggle("Enable Threat ESP", THREAT.Enabled, function(value) THREAT.Enabled = value end)
    Slider("Max Distance", 50, 3000, THREAT.MaxDistance, function(value) THREAT.MaxDistance = value end)
    Action("SCAN WORKSPACE", function() ScanThreats() end)
    Info("Ищет Mine, Tripwire, Grenade, Trap и Threat по названиям объектов, родителей и тегам CollectionService.", 56)

    Section("SUPPORTED")
    ColorRow("●  MINE", Color3.fromRGB(255, 60, 60))
    ColorRow("●  TRIPWIRE", Color3.fromRGB(255, 150, 40))
    ColorRow("●  GRENADE", Color3.fromRGB(255, 210, 60))
    ColorRow("●  TRAP", Color3.fromRGB(200, 70, 255))
    ColorRow("●  THREAT", Color3.fromRGB(255, 60, 60))
end

local function BuildBomb()
    Section("RESERVED")
    Info("Раздел зарезервирован под будущие функции.", 40)
end

local function BuildWorld()
    Section("NPC / AI ESP")
    Toggle("Enable NPC ESP", NPC.Enabled, function(value)
        NPC.Enabled = value
        if value then ScanNPCs() end
    end)
    Toggle("NPC Names", NPC.Names, function(value) NPC.Names = value end)
    Toggle("NPC Distance", NPC.Distance, function(value) NPC.Distance = value end)
    Toggle("NPC Health Bar", NPC.Health, function(value) NPC.Health = value end)
    Toggle("NPC Chams", NPC.Chams, function(value) NPC.Chams = value end)
    Toggle("NPC Tracers", NPC.Tracers, function(value) NPC.Tracers = value end)
    Slider("NPC Max Distance", 50, 2000, NPC.MaxDistance, function(value) NPC.MaxDistance = value end)
    Action("SCAN NPC NOW", ScanNPCs)
    Action("CLEAR NPC MARKERS", ClearNPCs)

    Section("LOOT ESP")
    Toggle("Enable Loot ESP", LootESP.Enabled, function(value)
        LootESP.Enabled = value
        if value then ScanLoot() end
    end)
    Slider("Loot Max Distance", 50, 2000, LootESP.MaxDistance, function(value) LootESP.MaxDistance = value end)
    Action("SCAN CONTAINERS", ScanLoot)
    Action("CLEAR MARKERS", ClearLoot)

    Section("WAYPOINT")
    Action("SET WAYPOINT AT AIM", SetWaypointAtAim)
    Action("SET WAYPOINT AT SELF", function()
        local root = GetRoot(LocalPlayer.Character)
        if root then SetWaypoint(root.Position) end
    end)
    Action("TELEPORT TO WAYPOINT", function()
        local root = GetRoot(LocalPlayer.Character)
        if root and Waypoint.Position then
            root.CFrame = CFrame.new(Waypoint.Position + Vector3.new(0, 3, 0, 0))
        end
    end)
    Action("CLEAR WAYPOINT", ClearWaypoint)
end

local function BuildView()
    Section("WORLD")
    Toggle("Fullbright", FULLBRIGHT, function(value) SetFullbright(value) end)
    Toggle("FPS Boost", FPS_BOOST, function(value)
        FPS_BOOST = value
        if value then ApplyFPSBoost() end
    end)
    Action("APPLY FPS BOOST", function() FPS_BOOST = true; ApplyFPSBoost() end)
    Info("Fullbright меняет только Lighting. Объекты карты не удаляются.", 40)
end

local function BuildMain()
    Section("MOVEMENT")
    Slider("WalkSpeed", 16, 60, MOVE.Speed, function(value) MOVE.Speed = value end)
    Slider("JumpPower", 50, 150, MOVE.Jump, function(value) MOVE.Jump = value end)
    Toggle("Noclip", MOVE.Noclip, function(value) MOVE.Noclip = value end)

    Section("FLY")
    Toggle("Fly", MOVE.Fly, function(value)
        if value then StartFly() else StopFly() end
    end)
    Slider("Fly Speed", 10, 200, MOVE.FlySpeed, function(value) MOVE.FlySpeed = value end)
    Toggle("On-Screen Fly Buttons", UIState.ShowFlyControls, function(value)
        UIState.ShowFlyControls = value
        UpdateFlyButtonsVisibility()
    end)
    Info("Когда Fly включен, на экране появляются кнопки ▲ и ▼. Держи их для подъема и спуска.", 48)

    Section("SYSTEM")
    Action("REJOIN", function()
        pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
    end)
    Toggle("Anti-AFK", AntiAFK.Enabled, SetAntiAFK)
    Action("PANIC (WIPE ALL)", Panic, C.Danger)
end

local function BuildInventory()
    Section("ITEM DATABASE")
    for _, source in ipairs(DB_ITEMS) do
        Action("OPEN: " .. source, function() DumpIntoContent(source) end)
    end
    Info("Читает реплицированные таблицы предметов и настроек. Только чтение.", 40)
end

local function BuildVisual()
    Section("ACCENT COLOR")
    for _, preset in ipairs(ACCENT_PRESETS) do
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 42)
        frame.BackgroundColor3 = C.Row
        frame.BorderSizePixel = 0
        frame.Parent = Content
        Corner(frame, 8)

        local swatch = Instance.new("Frame")
        swatch.Size = UDim2.fromOffset(22, 22)
        swatch.Position = UDim2.new(0, 12, 0.5, -11)
        swatch.BackgroundColor3 = preset.Color
        swatch.BorderSizePixel = 0
        swatch.Parent = frame
        Corner(swatch, 5)

        local lbl = NewLabel(frame, preset.Name, 13, Enum.Font.GothamMedium)
        lbl.Position = UDim2.fromOffset(44, 0)
        lbl.Size = UDim2.new(1, -100, 1, 0)
        lbl.TextColor3 = C.Text
        lbl.TextXAlignment = Enum.TextXAlignment.Left

        local activeLabel = NewLabel(frame, ACCENT == preset.Color and "● Active" or "", 11, Enum.Font.Gotham)
        activeLabel.AnchorPoint = Vector2.new(1, 0.5)
        activeLabel.Position = UDim2.new(1, -12, 0.5, 0)
        activeLabel.Size = UDim2.fromOffset(60, 20)
        activeLabel.TextColor3 = preset.Color
        activeLabel.TextXAlignment = Enum.TextXAlignment.Right

        local hit = Instance.new("TextButton", frame)
        hit.Size = UDim2.fromScale(1, 1)
        hit.BackgroundTransparency = 1
        hit.Text = ""
        hit.Activated:Connect(function()
            SetAccent(preset.Color)
            -- обновляем метки в текущей вкладке
            if CurrentTab then OpenTab(CurrentTab) end
        end)
    end

    Section("PARTICLES")
    local PARTICLE_OPTIONS = { "none", "snow", "rain", "stars", "sparks" }
    for _, kind in ipairs(PARTICLE_OPTIONS) do
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 42)
        frame.BackgroundColor3 = C.Row
        frame.BorderSizePixel = 0
        frame.Parent = Content
        Corner(frame, 8)

        local lbl = NewLabel(frame, kind:upper(), 13, Enum.Font.GothamMedium)
        lbl.Position = UDim2.fromOffset(14, 0)
        lbl.Size = UDim2.new(1, -80, 1, 0)
        lbl.TextColor3 = C.Text
        lbl.TextXAlignment = Enum.TextXAlignment.Left

        local activeLbl = NewLabel(frame, VFX.Particle == kind and "● On" or "", 11, Enum.Font.Gotham)
        activeLbl.AnchorPoint = Vector2.new(1, 0.5)
        activeLbl.Position = UDim2.new(1, -12, 0.5, 0)
        activeLbl.Size = UDim2.fromOffset(40, 20)
        activeLbl.TextColor3 = ACCENT
        activeLbl.TextXAlignment = Enum.TextXAlignment.Right

        local hit = Instance.new("TextButton", frame)
        hit.Size = UDim2.fromScale(1, 1)
        hit.BackgroundTransparency = 1
        hit.Text = ""
        hit.Activated:Connect(function()
            VFX.Particle = kind
            SpawnParticles(kind)
            OpenTab("Visual")
        end)
    end

    Section("ANIMATIONS")
    Toggle("All Animations", VFX.Animations, function(v) VFX.Animations = v end)
    Toggle("Open/Close Anim",  VFX.OpenAnim,  function(v) VFX.OpenAnim = v end)
    Toggle("Tab Fade Anim",    VFX.TabAnim,   function(v) VFX.TabAnim = v end)
end

local function BuildScripts()
    Section("BUILD INFO")
    Info("CSS.JAVA v3 — Project Delta Core. Dual aim (NPC/PVP), hold + tap-lock, sticky target, tracers, FOV circle, animated UI, particles.", 80)
    Info("Состояние функций не привязано к Tool. Респаун не сбрасывает GUI.", 40)
end

local function BuildConfigs()
    Section("CONFIGS")
    Action("SAVE CONFIG", function() SaveConfig() end)
    Action("LOAD CONFIG", function()
        LoadConfig()
        UpdateAimButtonsVisibility()
        UpdateFlyButtonsVisibility()
        if CurrentTab then OpenTab(CurrentTab) end
    end)
    Action("RESET TO DEFAULTS", function()
        ApplyConfig(DEFAULTS)
        UpdateAimButtonsVisibility()
        UpdateFlyButtonsVisibility()
        if CurrentTab then OpenTab(CurrentTab) end
    end)
    Info("Файл: " .. CONFIG_PATH .. ". Если эксплойт не дает writefile, кнопки молча не сработают.", 56)
end

Tabs["Ragebot"] = BuildRagebot
Tabs["Anti Aim"] = BuildAntiAim
Tabs["Legitbot"] = BuildLegitbot
Tabs["Players"] = BuildPlayers
Tabs["Weapon"] = BuildWeapon
Tabs["Grenades"] = BuildGrenades
Tabs["Bomb"] = BuildBomb
Tabs["World"] = BuildWorld
Tabs["View"] = BuildView
Tabs["Main"] = BuildMain
Tabs["Inventory"] = BuildInventory
Tabs["Scripts"] = BuildScripts
Tabs["Configs"] = BuildConfigs
Tabs["Visual"] = BuildVisual

-- ============================================================
-- SIDEBAR
-- ============================================================

local ICON_IDS = {
    Ragebot    = "rbxassetid://11738355467",
    AntiAim    = "rbxassetid://131818722808112",
    Legitbot   = "rbxassetid://10088146939",
    Players    = "rbxassetid://117259180607823",
    Weapon     = "rbxassetid://97190175392549",
    Grenades   = "rbxassetid://13424571211",
    Bomb       = "rbxassetid://103342882158009",
    World      = "rbxassetid://4830959433",
    View       = "rbxassetid://6266103551",
    Main       = "rbxassetid://12403104094",
    Inventory  = "rbxassetid://13747709452",
    Scripts    = "rbxassetid://137649072568517",
    Configs    = "rbxassetid://9405931578",
}

local MenuButtons = {}

local function CreateCategory()
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, 12)
    holder.BackgroundTransparency = 1
    holder.Parent = MenuScroll

    local line = Instance.new("Frame")
    line.AnchorPoint = Vector2.new(0.5, 0.5)
    line.Position = UDim2.fromScale(0.5, 0.5)
    line.Size = UDim2.new(0, 22, 0, 1)
    line.BackgroundColor3 = C.Category
    line.BackgroundTransparency = 0.4
    line.BorderSizePixel = 0
    line.Parent = holder
end

local function CreateMenuItem(name, iconId)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 0, 40)
    button.BackgroundColor3 = C.RowAlt
    button.BackgroundTransparency = 1
    button.Text = ""
    button.AutoButtonColor = false
    button.BorderSizePixel = 0
    button.Parent = MenuScroll
    Corner(button, 8)

    local icon = Instance.new("ImageLabel")
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.Position = UDim2.fromScale(0.5, 0.5)
    icon.Size = UDim2.fromOffset(20, 20)
    icon.BackgroundTransparency = 1
    icon.Image = iconId or ""
    icon.ImageColor3 = C.TextDim
    icon.Parent = button

    MenuButtons[name] = { Button = button, Icon = icon }

    button.Activated:Connect(function()
        OpenTab(name)
    end)

    return button
end

OpenTab = function(name)
    local builder = Tabs[name]
    if not builder then return end

    CurrentTab = name

    local function doSwitch()
        HeaderTitle.Text = string.upper(name)
        ClearContent()
        builder()
        -- fade-in контента
        if VFX.TabAnim and VFX.Animations then
            Content.GroupTransparency = 1
            TweenService:Create(Content, TweenInfo.new(0.18, Enum.EasingStyle.Quart), {
                GroupTransparency = 0
            }):Play()
        end
    end

    if VFX.TabAnim and VFX.Animations then
        TweenService:Create(Content, TweenInfo.new(0.10, Enum.EasingStyle.Quart), {
            GroupTransparency = 1
        }):Play()
        task.delay(0.11, doSwitch)
    else
        doSwitch()
    end

    for tabName, refs in pairs(MenuButtons) do
        if tabName == name then
            Tween(refs.Button, { BackgroundTransparency = 0 }, 0.15)
            Tween(refs.Icon,   { ImageColor3 = ACCENT },       0.15)
        else
            Tween(refs.Button, { BackgroundTransparency = 1 }, 0.15)
            Tween(refs.Icon,   { ImageColor3 = C.TextDim },    0.15)
        end
    end
end

CreateCategory()
CreateMenuItem("Ragebot", ICON_IDS.Ragebot)
CreateMenuItem("Anti Aim", ICON_IDS.AntiAim)
CreateMenuItem("Legitbot", ICON_IDS.Legitbot)
CreateCategory()
CreateMenuItem("Players", ICON_IDS.Players)
CreateMenuItem("Weapon", ICON_IDS.Weapon)
CreateMenuItem("Grenades", ICON_IDS.Grenades)
CreateMenuItem("Bomb", ICON_IDS.Bomb)
CreateMenuItem("World", ICON_IDS.World)
CreateMenuItem("View", ICON_IDS.View)
CreateCategory()
CreateMenuItem("Main", ICON_IDS.Main)
CreateMenuItem("Inventory", ICON_IDS.Inventory)
CreateMenuItem("Scripts", ICON_IDS.Scripts)
CreateMenuItem("Configs", ICON_IDS.Configs)
CreateMenuItem("Visual", "rbxassetid://4403645016")

-- ============================================================
-- ON-SCREEN CONTROLS
-- ============================================================

local OpenButton = Instance.new("TextButton")
OpenButton.Name = "OpenButton"
OpenButton.Size = UDim2.fromOffset(54, 54)
OpenButton.Position = UDim2.new(0, 12, 0.5, -27)
OpenButton.BackgroundColor3 = Color3.fromRGB(10, 18, 30)
OpenButton.Text = "N"
OpenButton.TextColor3 = ACCENT
OpenButton.TextSize = 24
OpenButton.Font = Enum.Font.GothamBold
OpenButton.AutoButtonColor = false
OpenButton.Parent = Gui
Corner(OpenButton, 27)
Stroke(OpenButton, ACCENT, 1.5)
MakeDraggable(OpenButton, OpenButton)

-- AIM BUTTONS: PVP (нижняя, под большой палец) и NPC (над ней)

AimPVPButton = Instance.new("TextButton")
AimPVPButton.Name = "AimPVPButton"
AimPVPButton.Size = UDim2.fromOffset(58, 58)
AimPVPButton.Position = UDim2.new(1, -72, 1, -72)
AimPVPButton.BackgroundColor3 = Color3.fromRGB(10, 18, 30)
AimPVPButton.BackgroundTransparency = 0.15
AimPVPButton.Text = "PVP"
AimPVPButton.TextColor3 = C.PVP
AimPVPButton.TextSize = 13
AimPVPButton.Font = Enum.Font.GothamBold
AimPVPButton.AutoButtonColor = false
AimPVPButton.Visible = false
AimPVPButton.Parent = Gui
Corner(AimPVPButton, 29)
Stroke(AimPVPButton, C.PVP, 1.5)

AimNPCButton = Instance.new("TextButton")
AimNPCButton.Name = "AimNPCButton"
AimNPCButton.Size = UDim2.fromOffset(58, 58)
AimNPCButton.Position = UDim2.new(1, -72, 1, -140)
AimNPCButton.BackgroundColor3 = Color3.fromRGB(10, 18, 30)
AimNPCButton.BackgroundTransparency = 0.15
AimNPCButton.Text = "NPC"
AimNPCButton.TextColor3 = C.NPCAim
AimNPCButton.TextSize = 13
AimNPCButton.Font = Enum.Font.GothamBold
AimNPCButton.AutoButtonColor = false
AimNPCButton.Visible = false
AimNPCButton.Parent = Gui
Corner(AimNPCButton, 29)
Stroke(AimNPCButton, C.NPCAim, 1.5)

-- ── Autofire через ServerProjectile ─────────────────────────────────────────
-- Remote найден в ReplicatedStorage.Remotes.ServerProjectile (см. Remote Dumper)
local ServerProjectile = game:GetService("ReplicatedStorage")
    :WaitForChild("Remotes", 5)
    and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("ServerProjectile")

local autoFireActive = false  -- глобальный флаг: хотя бы одна кнопка зажата

-- порог в пикселях: насколько близко кость должна быть к центру экрана
-- чтобы считать "наведено" и выстрелить
local AIM_FIRE_THRESHOLD = 18

local function IsAimed(target)
    local cam = Camera()
    if not cam or not target or not target.Parent then return false end
    local screen, onScreen = cam:WorldToViewportPoint(target.Position)
    if not onScreen or screen.Z <= 0 then return false end
    local vs = cam.ViewportSize
    local center = Vector2.new(vs.X / 2, vs.Y / 2)
    return (Vector2.new(screen.X, screen.Y) - center).Magnitude <= AIM_FIRE_THRESHOLD
end

local function AutoFireLoop()
    while autoFireActive do
        local target = AIM.Target
        -- стреляем только если камера уже навелась (кость в AIM_FIRE_THRESHOLD пикселей от центра)
        if target and target.Parent and ServerProjectile and IsAimed(target) then
            local cam = Camera()
            if cam then
                pcall(function()
                    ServerProjectile:FireServer(target.Position, cam.CFrame.LookVector)
                end)
            end
        end
        task.wait(0.08)
    end
end

local function BindAimButton(button, kind)
    local pressTime = 0

    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1 then
            pressTime = os.clock()
            AIM.HoldMode = kind
            -- запускаем автострельбу при удержании
            if not autoFireActive then
                autoFireActive = true
                task.spawn(AutoFireLoop)
            end
        end
    end)

    button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1 then
            if AIM.HoldMode == kind then
                -- быстрый тап < 0.25с = фиксация цели на 1.5 сек + одиночный выстрел
                if os.clock() - pressTime < 0.25 then
                    AIM.LockKind = kind
                    AIM.LockUntil = os.clock() + 1.5
                    -- одиночный выстрел по зафиксированной цели
                    task.spawn(function()
                        task.wait(0.05)
                        local target = AIM.Target
                        if target and target.Parent and ServerProjectile then
                            local cam = Camera()
                            if cam then
                                pcall(function()
                                    ServerProjectile:FireServer(target.Position, cam.CFrame.LookVector)
                                end)
                            end
                        end
                    end)
                end
                AIM.HoldMode = "none"
                autoFireActive = false  -- останавливаем автострельбу при отпускании
            end
        end
    end)
end

BindAimButton(AimPVPButton, "player")
BindAimButton(AimNPCButton, "npc")

UpdateAimButtonsVisibility = function()
    local visible = AIM.Enabled and UIState.ShowAimButtons
    if AimPVPButton then AimPVPButton.Visible = visible end
    if AimNPCButton then AimNPCButton.Visible = visible end
end

-- FLY BUTTONS (выше кнопок аима)

FlyUpButton = Instance.new("TextButton")
FlyUpButton.Name = "FlyUpButton"
FlyUpButton.Size = UDim2.fromOffset(58, 58)
FlyUpButton.Position = UDim2.new(1, -72, 1, -208)
FlyUpButton.BackgroundColor3 = Color3.fromRGB(10, 18, 30)
FlyUpButton.BackgroundTransparency = 0.15
FlyUpButton.Text = "▲"
FlyUpButton.TextColor3 = C.Text
FlyUpButton.TextSize = 20
FlyUpButton.Font = Enum.Font.GothamBold
FlyUpButton.AutoButtonColor = false
FlyUpButton.Visible = false
FlyUpButton.Parent = Gui
Corner(FlyUpButton, 29)
Stroke(FlyUpButton, C.Stroke, 1.5)

FlyUpButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        MOVE.FlyVertical = 1
    end
end)
FlyUpButton.InputEnded:Connect(function()
    MOVE.FlyVertical = 0
end)

FlyDownButton = Instance.new("TextButton")
FlyDownButton.Name = "FlyDownButton"
FlyDownButton.Size = UDim2.fromOffset(58, 58)
FlyDownButton.Position = UDim2.new(1, -72, 1, -276)
FlyDownButton.BackgroundColor3 = Color3.fromRGB(10, 18, 30)
FlyDownButton.BackgroundTransparency = 0.15
FlyDownButton.Text = "▼"
FlyDownButton.TextColor3 = C.Text
FlyDownButton.TextSize = 20
FlyDownButton.Font = Enum.Font.GothamBold
FlyDownButton.AutoButtonColor = false
FlyDownButton.Visible = false
FlyDownButton.Parent = Gui
Corner(FlyDownButton, 29)
Stroke(FlyDownButton, C.Stroke, 1.5)

FlyDownButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        MOVE.FlyVertical = -1
    end
end)
FlyDownButton.InputEnded:Connect(function()
    MOVE.FlyVertical = 0
end)

-- ============================================================
-- OPEN / CLOSE & RESPONSIVE LAYOUT
-- ============================================================

local Opened = true

local function SetOpen(value)
    Opened = value
    if value then
        MainFrame.Visible = true
        if VFX.OpenAnim and VFX.Animations then
            MainFrame.Size = UDim2.fromOffset(
                MainFrame.Size.X.Offset * 0.85,
                MainFrame.Size.Y.Offset * 0.85
            )
            MainFrame.BackgroundTransparency = 1
            TweenService:Create(MainFrame, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(
                    math.clamp((workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X or 780) - 14, 330, 860),
                    math.clamp((workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y or 350) - 22, 300, 720)
                ),
                BackgroundTransparency = 0,
            }):Play()
        end
    else
        if VFX.OpenAnim and VFX.Animations then
            TweenService:Create(MainFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                BackgroundTransparency = 1,
            }):Play()
            task.delay(0.19, function()
                if not Opened then MainFrame.Visible = false end
            end)
        else
            MainFrame.Visible = false
        end
    end
end

OpenButton.Activated:Connect(function()
    SetOpen(not Opened)
end)

CloseButton.Activated:Connect(function()
    SetOpen(false)
end)

UIS.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.B or input.KeyCode == Enum.KeyCode.RightShift then
        SetOpen(not Opened)
    end
end)

local function UpdateLayout()
    local cam = Camera()
    if not cam then return end

    local vs = cam.ViewportSize
    local w = math.clamp(vs.X - 14, 330, 860)
    local h = math.clamp(vs.Y - 22, 300, 720)

    MainFrame.Size = UDim2.fromOffset(w, h)
    MainFrame.Position = UDim2.fromScale(0.5, 0.5)

    local zoneW = w - SIDEBAR_W
    local pad = math.max(10, math.floor((zoneW - 520) / 2))
    ContentPadding.PaddingLeft = UDim.new(0, pad)
    ContentPadding.PaddingRight = UDim.new(0, pad)
end

UpdateLayout()

local layoutCam = Camera()
if layoutCam then
    layoutCam:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateLayout)
end

-- ============================================================
-- MAIN LOOPS
-- ============================================================

local scanTimer = 0
local npcTimer = 0

RunService.RenderStepped:Connect(function()
    if SHUTDOWN then return end

    for player, data in pairs(PlayerESP) do
        if player.Parent then
            UpdatePlayerESP(player, data)
        else
            RemovePlayerESP(player)
        end
    end

    for model, data in pairs(NPCMarkers) do
        UpdateNPCESP(model, data)
    end

    for instance, data in pairs(ThreatESP) do
        UpdateThreat(instance, data)
    end

    UpdateTracers()
    UpdateFOVCircle()

    if os.clock() - scanTimer >= 1 then
        scanTimer = os.clock()
        ScanThreats()
    end

    if os.clock() - npcTimer >= 1.5 then
        npcTimer = os.clock()
        ScanNPCs()
    end

    -- DUAL AIM: hold = непрерывное ведение, tap-lock = 1.5 сек
    if AIM.Enabled then
        local kind = nil
        if AIM.HoldMode ~= "none" then
            kind = AIM.HoldMode
        elseif AIM.LockUntil and os.clock() <= AIM.LockUntil then
            kind = AIM.LockKind
        end

        if kind then
            if AIM.TargetKind ~= kind then
                AIM.Target = nil
            end

            -- sticky: держим цель, пока валидна; иначе ищем новую
            if not (AIM.Target and ValidAimTarget(AIM.Target)) then
                if kind == "npc" then
                    AIM.Target = FindAimTargetNPCs()
                else
                    AIM.Target = FindAimTargetPlayers()
                end
                AIM.TargetKind = kind
            end

            if AIM.Target then
                local cam = Camera()
                if cam then
                    local targetCF = CFrame.lookAt(cam.CFrame.Position, AIM.Target.Position)
                    cam.CFrame = cam.CFrame:Lerp(targetCF, math.clamp(AIM.Smoothness, 0.01, 1))
                end
            end
        else
            AIM.Target = nil
            AIM.TargetKind = nil
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if SHUTDOWN then return end

    for instance, data in pairs(LootMarkers) do
        if not data.Part or not data.Part.Parent then
            RemoveLootMarker(instance)
        else
            local distance = DistanceFromPlayer(data.Part.Position)
            local on = LootESP.Enabled and distance <= LootESP.MaxDistance
            data.Billboard.Enabled = on
            data.Highlight.Enabled = on
            if on then
                data.Label.Text = string.format("%s  %dm", instance.Name, math.floor(distance))
            end
        end
    end

    if Waypoint.Position and Waypoint.Label then
        Waypoint.Label.Text = string.format("WAYPOINT  %dm", math.floor(DistanceFromPlayer(Waypoint.Position)))
    end

    local character = LocalPlayer.Character
    if character then
        local hum = GetHumanoid(character)
        local root = GetRoot(character)
        if hum and root then
            if hum.WalkSpeed ~= MOVE.Speed then hum.WalkSpeed = MOVE.Speed end
            if hum.JumpPower ~= MOVE.Jump then hum.JumpPower = MOVE.Jump end
            if MOVE.Noclip then
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end
    end

    if MOVE.Fly and flyBV and flyBG then
        local cam = Camera()
        local root = GetRoot(LocalPlayer.Character)
        if cam and root then
            local look = cam.CFrame.LookVector
            local horizontal = Vector3.new(look.X, 0, look.Z)
            if horizontal.Magnitude > 0 then horizontal = horizontal.Unit end
            flyBV.Velocity = horizontal * MOVE.FlySpeed
                + Vector3.new(0, MOVE.FlyVertical * MOVE.FlySpeed * 0.6, 0)
            flyBG.CFrame = cam.CFrame
        end
    end
end)

-- ============================================================
-- PING IN HEADER
-- ============================================================

task.spawn(function()
    while not SHUTDOWN do
        local network = Stats:FindFirstChild("Network")
        local server = network and network:FindFirstChild("ServerStatsItem")
        local ping = server and server:FindFirstChild("Data Ping")
        if ping and PingLabel.Parent then
            PingLabel.Text = math.floor(ping:GetValue()) .. " ms"
        end
        task.wait(3)
    end
end)

-- ============================================================
-- CHARACTER RESPAWN
-- ============================================================

LocalPlayer.CharacterAdded:Connect(function()
    ClearAim()
    task.delay(0.5, function()
        if FULLBRIGHT then SetFullbright(true) end
        if FPS_BOOST then ApplyFPSBoost() end
        ScanThreats()
        ScanNPCs()
    end)
end)

-- ============================================================
-- INITIALIZATION
-- ============================================================

LoadConfig()
UpdateAimButtonsVisibility()
OpenTab("Ragebot")

task.spawn(function()
    task.wait(0.5)
    ScanThreats()
    ScanNPCs()
    if FULLBRIGHT then SetFullbright(true) end
    if FPS_BOOST then ApplyFPSBoost() end
    UpdateLayout()
end)

print("[Neverlose Mobile] v2 TOP BUILD loaded: dual aim + tracers + FOV circle")
