local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local plr = Players.LocalPlayer
local cam = workspace.CurrentCamera

-- ФУНКЦИИ СОЗДАНИЯ (ОБЪЯВЛЕНЫ СРАЗУ)
local function CreateCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 12)
    c.Parent = parent
    return c
end

local function CreateStroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(50, 50, 60)
    s.Thickness = thickness or 1
    s.Transparency = 0.3
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

-- СОХРАНЕНИЕ
local function SaveFile(name, data)
    pcall(function()
        if writefile then
            writefile("ZepHub_" .. name .. ".json", data)
        end
    end)
end

local function LoadFile(name)
    local data = nil
    pcall(function()
        if readfile and isfile and isfile("ZepHub_" .. name .. ".json") then
            data = readfile("ZepHub_" .. name .. ".json")
        end
    end)
    return data
end

local savedTheme = "Midnight"
local savedHit1 = 136688569661082
local savedHit2 = 7531253465
local savedMiss = 117671199302919

do
    local themeData = LoadFile("Theme")
    if themeData then savedTheme = themeData end

    local s1 = LoadFile("Hit1")
    if s1 and tonumber(s1) then savedHit1 = tonumber(s1) end

    local s2 = LoadFile("Hit2")
    if s2 and tonumber(s2) then savedHit2 = tonumber(s2) end

    local sm = LoadFile("Miss")
    if sm and tonumber(sm) then savedMiss = tonumber(sm) end
end

-- ТЕМЫ
local Themes = {
    Midnight = {
        Background   = Color3.fromRGB(18, 18, 26),
        Surface      = Color3.fromRGB(26, 26, 38),
        SurfaceHover = Color3.fromRGB(36, 36, 52),
        Accent       = Color3.fromRGB(88, 120, 255),
        Text         = Color3.fromRGB(235, 235, 240),
        TextDim      = Color3.fromRGB(130, 130, 155),
        Stroke       = Color3.fromRGB(50, 50, 70),
    },
    Crimson = {
        Background   = Color3.fromRGB(26, 18, 18),
        Surface      = Color3.fromRGB(38, 26, 26),
        SurfaceHover = Color3.fromRGB(52, 36, 36),
        Accent       = Color3.fromRGB(255, 64, 64),
        Text         = Color3.fromRGB(240, 235, 235),
        TextDim      = Color3.fromRGB(155, 130, 130),
        Stroke       = Color3.fromRGB(70, 50, 50),
    },
    Emerald = {
        Background   = Color3.fromRGB(18, 26, 22),
        Surface      = Color3.fromRGB(26, 38, 32),
        SurfaceHover = Color3.fromRGB(36, 52, 42),
        Accent       = Color3.fromRGB(64, 192, 96),
        Text         = Color3.fromRGB(235, 240, 235),
        TextDim      = Color3.fromRGB(130, 155, 130),
        Stroke       = Color3.fromRGB(50, 70, 50),
    },
    Purple = {
        Background   = Color3.fromRGB(22, 18, 26),
        Surface      = Color3.fromRGB(32, 26, 38),
        SurfaceHover = Color3.fromRGB(44, 36, 52),
        Accent       = Color3.fromRGB(160, 96, 255),
        Text         = Color3.fromRGB(240, 235, 240),
        TextDim      = Color3.fromRGB(150, 130, 155),
        Stroke       = Color3.fromRGB(65, 50, 70),
    },
}

local Theme = Themes[savedTheme] or Themes.Midnight

-- ЗВУКИ
local HitSoundIDs = {savedHit1, savedHit2}
local MissSoundID = savedMiss

local function PlaySoundById(soundId)
    local s = Instance.new("Sound")
    s.SoundId = "rbxassetid://" .. tostring(soundId)
    s.Volume = 2
    s.Parent = SoundService
    s:Play()
    task.delay(5, function()
        if s and s.Parent then s:Destroy() end
    end)
end

local function PlayHitSound()
    local pick = HitSoundIDs[math.random(1, #HitSoundIDs)]
    PlaySoundById(pick)
end

local function PlayMissSound()
    PlaySoundById(MissSoundID)
end

-- СОСТОЯНИЕ
local ScriptName = "Zep Hub"
local ScriptVersion = "v1.0"
local ScriptAuthor = "Z3pty0rbex (@Aminb1000)"

local autoAimEnabled = false
local autoFireEnabled = true
local stopWhenMoving = true
local customSoundsEnabled = false
local maxDistance = 2000
local minHeight = 20
local fireBtn = nil
local lastFire = 0
local fireCooldown = 0.15
local fireCountThisCycle = 0

local watchedParts = {}
local baseDistances = {}
local pendingTime = 0
local CHECK_TIME = 3
local hasPending = false
local watchStartHeight = 0

local hitCount = 0
local missCount = 0

local AutoAimBox, AutoAimBoxStroke, AutoAimMark

local function UpdateCheckboxVisual()
    if not AutoAimBox then return end
    if autoAimEnabled then
        AutoAimBox.BackgroundColor3 = Theme.Accent
        if AutoAimBoxStroke then AutoAimBoxStroke.Color = Theme.Accent end
        if AutoAimMark then AutoAimMark.ImageTransparency = 0 end
    else
        AutoAimBox.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
        if AutoAimBoxStroke then AutoAimBoxStroke.Color = Theme.Stroke end
        if AutoAimMark then AutoAimMark.ImageTransparency = 1 end
    end
end

local function GetCircle()
    local pg = plr:FindFirstChild("PlayerGui")
    if not pg then return nil end
    local sg = pg:FindFirstChild("StingerGui")
    if not sg then return nil end
    local fr = sg:FindFirstChild("Frame")
    if not fr then return nil end
    return fr:FindFirstChild("Circle")
end

local function IsCircleGreen()
    local circle = GetCircle()
    if not circle then return false end
    local c = circle.ImageColor3
    return c.G > 0.6 and c.R < 0.5 and c.B < 0.5
end

local function FindFireButton()
    local pg = plr:FindFirstChild("PlayerGui")
    if not pg then return nil end
    local sg = pg:FindFirstChild("ShootGui")
    if not sg then return nil end
    local fr = sg:FindFirstChild("Frame")
    if not fr then return nil end
    local button = fr:FindFirstChild("Button")
    if button and button:IsA("TextButton") and button.Visible then
        return button
    end
    return nil
end

local function IsFireBtnValid()
    if not fireBtn then return false end
    if not fireBtn.Parent then return false end
    if not fireBtn.Visible then return false end
    local char = plr.Character
    if char then
        if not char:FindFirstChild("Stinger-M") then return false end
    else
        return false
    end
    return true
end

local function FindDrone()
    local folder = workspace:FindFirstChild("Drones")
    if not folder then return nil, 0, nil, nil end
    local nearestPos, nearestDist, nearestName, nearestObj = nil, maxDistance, nil, nil
    local camPos = cam.CFrame.Position
    for _, obj in pairs(folder:GetChildren()) do
        if obj:IsA("Model") then
            local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if part then
                local pos = part.Position
                local dist = (pos - camPos).Magnitude
                if pos.Y >= minHeight and dist < nearestDist then
                    nearestDist = dist
                    nearestPos = pos
                    nearestName = obj.Name
                    nearestObj = obj
                end
            end
        end
    end
    return nearestPos, nearestDist, nearestName, nearestObj
end

local function IsPlayerMoving()
    local char = plr.Character
    if not char then return false end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    return humanoid.MoveDirection.Magnitude > 0.1
end

local function TapButton(button)
    if not button or not button.Parent then return end
    local absPos = button.AbsolutePosition
    local absSize = button.AbsoluteSize
    if absSize.X > 0 and absSize.Y > 0 then
        local x = absPos.X + absSize.X / 2
        local y = absPos.Y + absSize.Y / 2
        pcall(function()
            VIM:SendMouseButtonEvent(x, y, 0, true, game, 1)
            task.wait(0.02)
            VIM:SendMouseButtonEvent(x, y, 0, false, game, 1)
        end)
    end
    pcall(function() button.MouseButton1Click:Fire() end)
    pcall(function() button:Activate() end)
end

local function CaptureDrone(drone)
    local parts = {}
    for _, obj in pairs(drone:GetDescendants()) do
        if obj:IsA("BasePart") then
            table.insert(parts, obj)
        end
    end
    local baseDists = {}
    if #parts >= 2 then
        local firstPart = parts[1]
        for i = 2, #parts do
            local d = (parts[i].Position - firstPart.Position).Magnitude
            table.insert(baseDists, d)
        end
    end
    return parts, baseDists
end

-- SCREENGUI + MAIN FRAME
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZepHub_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game:GetService("CoreGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 520, 0, 420)
MainFrame.Position = UDim2.new(0.5, -260, 0.5, -210)
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = false
MainFrame.Visible = false
MainFrame.Parent = ScreenGui
CreateCorner(MainFrame, 16)
CreateStroke(MainFrame, Theme.Stroke, 1)

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 48)
TitleBar.BackgroundColor3 = Theme.Surface
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
CreateCorner(TitleBar, 16)

local TitleBarFix = Instance.new("Frame")
TitleBarFix.Size = UDim2.new(1, 0, 0.5, 0)
TitleBarFix.Position = UDim2.new(0, 0, 0.5, 0)
TitleBarFix.BackgroundColor3 = Theme.Surface
TitleBarFix.BorderSizePixel = 0
TitleBarFix.Parent = TitleBar

local Logo = Instance.new("Frame")
Logo.Size = UDim2.new(0, 22, 0, 22)
Logo.Position = UDim2.new(0, 16, 0.5, -11)
Logo.BackgroundColor3 = Theme.Accent
Logo.BorderSizePixel = 0
Logo.Parent = TitleBar
CreateCorner(Logo, 11)

local LogoInner = Instance.new("Frame")
LogoInner.Size = UDim2.new(0, 8, 0, 8)
LogoInner.Position = UDim2.new(0.5, -4, 0.5, -4)
LogoInner.BackgroundColor3 = Theme.Background
LogoInner.BorderSizePixel = 0
LogoInner.Parent = Logo
CreateCorner(LogoInner, 4)

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(0, 220, 1, 0)
TitleText.Position = UDim2.new(0, 48, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = ScriptName .. "  ·  " .. ScriptVersion
TitleText.TextColor3 = Theme.Text
TitleText.Font = Enum.Font.GothamBold
TitleText.TextSize = 14
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -40, 0.5, -14)
CloseBtn.BackgroundColor3 = Theme.Surface
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Theme.TextDim
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 18
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = TitleBar
CreateCorner(CloseBtn, 8)

CloseBtn.MouseEnter:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.15), {
        BackgroundColor3 = Color3.fromRGB(220, 60, 60),
        TextColor3 = Color3.fromRGB(255, 255, 255)
    }):Play()
end)
CloseBtn.MouseLeave:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.15), {
        BackgroundColor3 = Theme.Surface,
        TextColor3 = Theme.TextDim
    }):Play()
end)

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 140, 1, -48)
Sidebar.Position = UDim2.new(0, 0, 0, 48)
Sidebar.BackgroundColor3 = Theme.Surface
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

local SidebarDivider = Instance.new("Frame")
SidebarDivider.Size = UDim2.new(0, 1, 1, 0)
SidebarDivider.Position = UDim2.new(1, 0, 0, 0)
SidebarDivider.BackgroundColor3 = Theme.Stroke
SidebarDivider.BorderSizePixel = 0
SidebarDivider.BackgroundTransparency = 0.5
SidebarDivider.Parent = Sidebar

local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -140, 1, -48)
ContentArea.Position = UDim2.new(0, 140, 0, 48)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent = MainFrame

-- СТРАНИЦЫ
local WelcomePage = Instance.new("Frame")
WelcomePage.Size = UDim2.new(1, 0, 1, 0)
WelcomePage.BackgroundTransparency = 1
WelcomePage.Visible = true
WelcomePage.Parent = ContentArea

local MainPage = Instance.new("ScrollingFrame")
MainPage.Size = UDim2.new(1, 0, 1, 0)
MainPage.BackgroundTransparency = 1
MainPage.BorderSizePixel = 0
MainPage.ScrollBarThickness = 4
MainPage.ScrollBarImageColor3 = Theme.Accent
MainPage.CanvasSize = UDim2.new(0, 0, 0, 0)
MainPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
MainPage.Visible = false
MainPage.Parent = ContentArea

local SettingsPage = Instance.new("ScrollingFrame")
SettingsPage.Size = UDim2.new(1, 0, 1, 0)
SettingsPage.BackgroundTransparency = 1
SettingsPage.BorderSizePixel = 0
SettingsPage.ScrollBarThickness = 4
SettingsPage.ScrollBarImageColor3 = Theme.Accent
SettingsPage.CanvasSize = UDim2.new(0, 0, 0, 0)
SettingsPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
SettingsPage.Visible = false
SettingsPage.Parent = ContentArea

local InfoPage = Instance.new("ScrollingFrame")
InfoPage.Size = UDim2.new(1, 0, 1, 0)
InfoPage.BackgroundTransparency = 1
InfoPage.BorderSizePixel = 0
InfoPage.ScrollBarThickness = 4
InfoPage.ScrollBarImageColor3 = Theme.Accent
InfoPage.CanvasSize = UDim2.new(0, 0, 0, 0)
InfoPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
InfoPage.Visible = false
InfoPage.Parent = ContentArea

local function CreateSectionHeader(parent, text, yOffset)
    local Header = Instance.new("TextLabel")
    Header.Size = UDim2.new(1, -32, 0, 20)
    Header.Position = UDim2.new(0, 16, 0, yOffset)
    Header.BackgroundTransparency = 1
    Header.Text = string.upper(text)
    Header.TextColor3 = Theme.Accent
    Header.Font = Enum.Font.GothamBold
    Header.TextSize = 10
    Header.TextXAlignment = Enum.TextXAlignment.Left
    Header.Parent = parent
    return Header
end

local function CreateCard(parent, title, subtitle, yOffset)
    local Card = Instance.new("Frame")
    Card.Size = UDim2.new(1, -32, 0, 56)
    Card.Position = UDim2.new(0, 16, 0, yOffset)
    Card.BackgroundColor3 = Theme.Surface
    Card.BorderSizePixel = 0
    Card.Parent = parent
    CreateCorner(Card, 10)
    CreateStroke(Card, Theme.Stroke, 1)

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -20, 0, 20)
    Title.Position = UDim2.new(0, 14, 0, 10)
    Title.BackgroundTransparency = 1
    Title.Text = title
    Title.TextColor3 = Theme.Text
    Title.Font = Enum.Font.GothamMedium
    Title.TextSize = 13
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Card

    local Subtitle = Instance.new("TextLabel")
    Subtitle.Size = UDim2.new(1, -20, 0, 16)
    Subtitle.Position = UDim2.new(0, 14, 0, 30)
    Subtitle.BackgroundTransparency = 1
    Subtitle.Text = subtitle
    Subtitle.TextColor3 = Theme.TextDim
    Subtitle.Font = Enum.Font.Gotham
    Subtitle.TextSize = 11
    Subtitle.TextXAlignment = Enum.TextXAlignment.Left
    Subtitle.Parent = Card

    Card.MouseEnter:Connect(function()
        TweenService:Create(Card, TweenInfo.new(0.15), {
            BackgroundColor3 = Theme.SurfaceHover
        }):Play()
    end)
    Card.MouseLeave:Connect(function()
        TweenService:Create(Card, TweenInfo.new(0.15), {
            BackgroundColor3 = Theme.Surface
        }):Play()
    end)

    return Card
end

CreateSectionHeader(WelcomePage, "Добро пожаловать", 16)
CreateCard(WelcomePage, "Zep Hub", "Загружен и готов к работе", 45)
CreateCard(WelcomePage, "Версия", ScriptVersion, 110)
CreateCard(WelcomePage, "Автор", ScriptAuthor, 175)

-- ГЛАВНАЯ
CreateSectionHeader(MainPage, "AIM", 10)

local function CreateCheckbox(parent, text, yOffset, defaultState, callback)
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, -32, 0, 40)
    Container.Position = UDim2.new(0, 16, 0, yOffset)
    Container.BackgroundColor3 = Theme.Surface
    Container.BorderSizePixel = 0
    Container.Parent = parent
    CreateCorner(Container, 10)
    CreateStroke(Container, Theme.Stroke, 1)

    local Box = Instance.new("Frame")
    Box.Size = UDim2.new(0, 20, 0, 20)
    Box.Position = UDim2.new(0, 12, 0.5, -10)
    Box.BackgroundColor3 = defaultState and Theme.Accent or Color3.fromRGB(10, 10, 12)
    Box.BorderSizePixel = 0
    Box.Parent = Container
    CreateCorner(Box, 5)

    local BoxStroke = Instance.new("UIStroke")
    BoxStroke.Color = defaultState and Theme.Accent or Theme.Stroke
    BoxStroke.Thickness = 1.5
    BoxStroke.Parent = Box

    local Mark = Instance.new("ImageLabel")
    Mark.Size = UDim2.new(0, 14, 0, 14)
    Mark.Position = UDim2.new(0.5, -7, 0.5, -7)
    Mark.BackgroundTransparency = 1
    Mark.Image = "rbxassetid://6031094667"
    Mark.ImageColor3 = Theme.Accent
    Mark.ImageTransparency = defaultState and 0 or 1
    Mark.Parent = Box

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -50, 1, 0)
    Label.Position = UDim2.new(0, 42, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Theme.Text
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 12
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Container

    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 1, 0)
    Btn.BackgroundTransparency = 1
    Btn.Text = ""
    Btn.Parent = Container

    local state = defaultState
    Btn.MouseButton1Click:Connect(function()
        state = not state
        if state then
            Box.BackgroundColor3 = Theme.Accent
            BoxStroke.Color = Theme.Accent
            Mark.ImageTransparency = 0
        else
            Box.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
            BoxStroke.Color = Theme.Stroke
            Mark.ImageTransparency = 1
        end
        callback(state)
    end)

    Container.MouseEnter:Connect(function()
        TweenService:Create(Container, TweenInfo.new(0.15), {
            BackgroundColor3 = Theme.SurfaceHover
        }):Play()
    end)
    Container.MouseLeave:Connect(function()
        TweenService:Create(Container, TweenInfo.new(0.15), {
            BackgroundColor3 = Theme.Surface
        }):Play()
    end)

    return Container, Box, BoxStroke, Mark
end

local AutoAimContainer, Box, BoxStroke, Mark = CreateCheckbox(MainPage, "Auto-Aim", 40, false, function(v)
    autoAimEnabled = v
end)
AutoAimBox = Box
AutoAimBoxStroke = BoxStroke
AutoAimMark = Mark

CreateSectionHeader(MainPage, "Звуки", 92)

CreateCheckbox(MainPage, "Кастомные звуки", 122, false, function(v)
    customSoundsEnabled = v
end)

local function CreateIdField(parent, label, defaultId, yOffset, onChange)
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, -32, 0, 32)
    Container.Position = UDim2.new(0, 16, 0, yOffset)
    Container.BackgroundColor3 = Theme.Surface
    Container.BorderSizePixel = 0
    Container.Parent = parent
    CreateCorner(Container, 8)
    CreateStroke(Container, Theme.Stroke, 1)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0, 90, 1, 0)
    Label.Position = UDim2.new(0, 8, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = label
    Label.TextColor3 = Theme.TextDim
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 10
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Container

    local Input = Instance.new("TextBox")
    Input.Size = UDim2.new(1, -180, 1, 0)
    Input.Position = UDim2.new(0, 100, 0, 0)
    Input.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
    Input.Text = tostring(defaultId)
    Input.TextColor3 = Theme.Text
    Input.Font = Enum.Font.Code
    Input.TextSize = 10
    Input.BorderSizePixel = 0
    Input.TextXAlignment = Enum.TextXAlignment.Left
    Input.ClearTextOnFocus = false
    Input.Parent = Container
    CreateCorner(Input, 6)

    local InputPad = Instance.new("UIPadding")
    InputPad.PaddingLeft = UDim.new(0, 6)
    InputPad.PaddingRight = UDim.new(0, 6)
    InputPad.Parent = Input

    local PlayBtn = Instance.new("TextButton")
    PlayBtn.Size = UDim2.new(0, 26, 0, 20)
    PlayBtn.Position = UDim2.new(1, -60, 0.5, -10)
    PlayBtn.BackgroundColor3 = Color3.fromRGB(60, 100, 60)
    PlayBtn.Text = "▶"
    PlayBtn.TextColor3 = Color3.fromRGB(200, 255, 200)
    PlayBtn.Font = Enum.Font.GothamBold
    PlayBtn.TextSize = 11
    PlayBtn.BorderSizePixel = 0
    PlayBtn.Parent = Container
    CreateCorner(PlayBtn, 5)

    local ApplyBtn = Instance.new("TextButton")
    ApplyBtn.Size = UDim2.new(0, 26, 0, 20)
    ApplyBtn.Position = UDim2.new(1, -30, 0.5, -10)
    ApplyBtn.BackgroundColor3 = Color3.fromRGB(60, 80, 180)
    ApplyBtn.Text = "✓"
    ApplyBtn.TextColor3 = Color3.fromRGB(200, 220, 255)
    ApplyBtn.Font = Enum.Font.GothamBold
    ApplyBtn.TextSize = 11
    ApplyBtn.BorderSizePixel = 0
    ApplyBtn.Parent = Container
    CreateCorner(ApplyBtn, 5)

    PlayBtn.MouseButton1Click:Connect(function()
        local id = tonumber(Input.Text)
        if id then PlaySoundById(id) end
    end)

    ApplyBtn.MouseButton1Click:Connect(function()
        local id = tonumber(Input.Text)
        if id then
            onChange(id)
            ApplyBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
            task.wait(0.3)
            ApplyBtn.BackgroundColor3 = Color3.fromRGB(60, 80, 180)
        end
    end)

    return Input
end

CreateIdField(MainPage, "Попадание 1", HitSoundIDs[1], 168, function(id)
    HitSoundIDs[1] = id
    SaveFile("Hit1", tostring(id))
end)
CreateIdField(MainPage, "Попадание 2", HitSoundIDs[2], 204, function(id)
    HitSoundIDs[2] = id
    SaveFile("Hit2", tostring(id))
end)
CreateIdField(MainPage, "Промах", MissSoundID, 240, function(id)
    MissSoundID = id
    SaveFile("Miss", tostring(id))
end)

CreateSectionHeader(MainPage, "Статистика", 280)

local StatsLabel = Instance.new("TextLabel")
StatsLabel.Size = UDim2.new(1, -32, 0, 36)
StatsLabel.Position = UDim2.new(0, 16, 0, 304)
StatsLabel.BackgroundColor3 = Theme.Surface
StatsLabel.Text = "Сбито: 0  ·  Промахов: 0"
StatsLabel.TextColor3 = Theme.Text
StatsLabel.Font = Enum.Font.GothamMedium
StatsLabel.TextSize = 12
StatsLabel.Parent = MainPage
CreateCorner(StatsLabel, 10)
CreateStroke(StatsLabel, Theme.Stroke, 1)

local Spacer = Instance.new("Frame")
Spacer.Size = UDim2.new(1, 0, 0, 20)
Spacer.Position = UDim2.new(0, 0, 0, 348)
Spacer.BackgroundTransparency = 1
Spacer.Parent = MainPage

-- НАСТРОЙКИ
CreateSectionHeader(SettingsPage, "Тема оформления", 10)

local ThemeButtons = {}

local function ApplyTheme(themeName)
    Theme = Themes[themeName]
    savedTheme = themeName
    SaveFile("Theme", themeName)

    MainFrame.BackgroundColor3 = Theme.Background
    TitleBar.BackgroundColor3 = Theme.Surface
    TitleBarFix.BackgroundColor3 = Theme.Surface
    Sidebar.BackgroundColor3 = Theme.Surface
    Logo.BackgroundColor3 = Theme.Accent
    LogoInner.BackgroundColor3 = Theme.Background

    TitleText.TextColor3 = Theme.Text
    CloseBtn.BackgroundColor3 = Theme.Surface
    CloseBtn.TextColor3 = Theme.TextDim

    SidebarDivider.BackgroundColor3 = Theme.Stroke

    for name, btn in pairs(ThemeButtons) do
        if name == themeName then
            btn.BackgroundColor3 = Theme.Accent
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            btn.BackgroundColor3 = Theme.Surface
            btn.TextColor3 = Theme.TextDim
        end
    end
end

local y = 40
for name, colors in pairs(Themes) do
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -32, 0, 36)
    Btn.Position = UDim2.new(0, 16, 0, y)
    Btn.BackgroundColor3 = Theme.Surface
    Btn.Text = name
    Btn.TextColor3 = Theme.TextDim
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 11
    Btn.BorderSizePixel = 0
    Btn.AutoButtonColor = false
    Btn.Parent = SettingsPage
    CreateCorner(Btn, 10)

    local ColorStrip = Instance.new("Frame")
    ColorStrip.Size = UDim2.new(0, 4, 1, -10)
    ColorStrip.Position = UDim2.new(0, 6, 0, 5)
    ColorStrip.BackgroundColor3 = colors.Accent
    ColorStrip.BorderSizePixel = 0
    ColorStrip.Parent = Btn
    CreateCorner(ColorStrip, 2)

    Btn.MouseButton1Click:Connect(function()
        ApplyTheme(name)
    end)

    ThemeButtons[name] = Btn
    y = y + 42
end

if ThemeButtons[savedTheme] then
    ThemeButtons[savedTheme].BackgroundColor3 = Theme.Accent
    ThemeButtons[savedTheme].TextColor3 = Color3.fromRGB(255, 255, 255)
end

CreateSectionHeader(SettingsPage, "Сохранение", y + 10)

local SaveBtn = Instance.new("TextButton")
SaveBtn.Size = UDim2.new(1, -32, 0, 36)
SaveBtn.Position = UDim2.new(0, 16, 0, y + 40)
SaveBtn.BackgroundColor3 = Color3.fromRGB(60, 140, 60)
SaveBtn.Text = "💾 СОХРАНИТЬ НАСТРОЙКИ"
SaveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SaveBtn.Font = Enum.Font.GothamBold
SaveBtn.TextSize = 11
SaveBtn.BorderSizePixel = 0
SaveBtn.AutoButtonColor = false
SaveBtn.Parent = SettingsPage
CreateCorner(SaveBtn, 10)

SaveBtn.MouseButton1Click:Connect(function()
    SaveFile("Hit1", tostring(HitSoundIDs[1]))
    SaveFile("Hit2", tostring(HitSoundIDs[2]))
    SaveFile("Miss", tostring(MissSoundID))
    SaveFile("Theme", savedTheme)
    SaveBtn.Text = "✅ СОХРАНЕНО"
    SaveBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 60)
    task.wait(1.5)
    SaveBtn.Text = "💾 СОХРАНИТЬ НАСТРОЙКИ"
    SaveBtn.BackgroundColor3 = Color3.fromRGB(60, 140, 60)
end)

local ResetBtn = Instance.new("TextButton")
ResetBtn.Size = UDim2.new(1, -32, 0, 36)
ResetBtn.Position = UDim2.new(0, 16, 0, y + 84)
ResetBtn.BackgroundColor3 = Color3.fromRGB(160, 60, 60)
ResetBtn.Text = "🗑 СБРОСИТЬ ВСЁ"
ResetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ResetBtn.Font = Enum.Font.GothamBold
ResetBtn.TextSize = 11
ResetBtn.BorderSizePixel = 0
ResetBtn.AutoButtonColor = false
ResetBtn.Parent = SettingsPage
CreateCorner(ResetBtn, 10)

ResetBtn.MouseButton1Click:Connect(function()
    pcall(function()
        if delfile then
            delfile("ZepHub_Hit1.json")
            delfile("ZepHub_Hit2.json")
            delfile("ZepHub_Miss.json")
            delfile("ZepHub_Theme.json")
        end
    end)
    ResetBtn.Text = "✅ СБРОШЕНО"
    ResetBtn.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
end)

-- ИНФО
CreateSectionHeader(InfoPage, "О скрипте", 10)
CreateCard(InfoPage, "Название", "Zep Hub", 40)
CreateCard(InfoPage, "Версия", "v1.0 (Release)", 100)
CreateCard(InfoPage, "Автор", "Z3pty0rbex (@Aminb1000)", 160)

CreateSectionHeader(InfoPage, "Об игре", 230)
CreateCard(InfoPage, "Название", "БПЛА [Новые дроны]", 260)
CreateCard(InfoPage, "Создатель", "ILP Studio", 320)

local OnlineLabel = Instance.new("TextLabel")
OnlineLabel.Size = UDim2.new(1, -32, 0, 56)
OnlineLabel.Position = UDim2.new(0, 16, 0, 380)
OnlineLabel.BackgroundColor3 = Theme.Surface
OnlineLabel.Text = "Онлайн: 0 игроков"
OnlineLabel.TextColor3 = Theme.Text
OnlineLabel.Font = Enum.Font.GothamMedium
OnlineLabel.TextSize = 13
OnlineLabel.TextXAlignment = Enum.TextXAlignment.Left
OnlineLabel.Parent = InfoPage
CreateCorner(OnlineLabel, 10)
CreateStroke(OnlineLabel, Theme.Stroke, 1)

local OnlinePad = Instance.new("UIPadding")
OnlinePad.PaddingLeft = UDim.new(0, 14)
OnlinePad.Parent = OnlineLabel

task.spawn(function()
    while true do
        task.wait(2)
        pcall(function()
            OnlineLabel.Text = "Онлайн: " .. #Players:GetPlayers() .. " игроков"
        end)
    end
end)

CreateSectionHeader(InfoPage, "Статистика сессии", 450)

local SessionStats = Instance.new("TextLabel")
SessionStats.Size = UDim2.new(1, -32, 0, 96)
SessionStats.Position = UDim2.new(0, 16, 0, 480)
SessionStats.BackgroundColor3 = Theme.Surface
SessionStats.Text = "Сбито: 0\nПромахов: 0\nТочность: 0%"
SessionStats.TextColor3 = Theme.Text
SessionStats.Font = Enum.Font.Code
SessionStats.TextSize = 11
SessionStats.TextXAlignment = Enum.TextXAlignment.Left
SessionStats.TextYAlignment = Enum.TextYAlignment.Top
SessionStats.Parent = InfoPage
CreateCorner(SessionStats, 10)
CreateStroke(SessionStats, Theme.Stroke, 1)

local SessPad = Instance.new("UIPadding")
SessPad.PaddingTop = UDim.new(0, 10)
SessPad.PaddingLeft = UDim.new(0, 14)
SessPad.Parent = SessionStats

task.spawn(function()
    while true do
        task.wait(1)
        pcall(function()
            local total = hitCount + missCount
            local acc = 0
            if total > 0 then
                acc = math.floor((hitCount / total) * 100)
            end
            SessionStats.Text = "Сбито: " .. hitCount
            SessionStats.Text = SessionStats.Text .. "\nПромахов: " .. missCount
            SessionStats.Text = SessionStats.Text .. "\nТочность: " .. acc .. "%"
        end)
    end
end)

CreateSectionHeader(InfoPage, "Changelog", 590)

local ChangelogData = {
    {"v1.0", "Release", "Инфо, настройки, темы, сохранение, статистика"},
    {"v0.9", "Themes Update", "4 темы: Midnight, Crimson, Emerald, Purple"},
    {"v0.8", "Settings Core", "Сохранение ID звуков и темы"},
    {"v0.7", "Counter Update", "Счётчик, фикс тапов, скроллинг"},
    {"v0.6", "Death Fix", "Авто-выключение при смерти"},
    {"v0.5", "Height Check", "Игнор упавших дронов"},
    {"v0.4", "Smart Hit Detection", "Детект попадания по разлёту частей"},
    {"v0.3", "Fire Rate Fix", "Промах через 3 сек"},
    {"v0.2", "Better Detection", "Проверка попадания, скроллинг"},
    {"v0.1", "First Release", "Auto-Aim, 2 клика за круг"},
}

local yCL = 620
for _, entry in ipairs(ChangelogData) do
    local ver, name, desc = entry[1], entry[2], entry[3]
    local Card = Instance.new("Frame")
    Card.Size = UDim2.new(1, -32, 0, 50)
    Card.Position = UDim2.new(0, 16, 0, yCL)
    Card.BackgroundColor3 = Theme.Surface
    Card.BorderSizePixel = 0
    Card.Parent = InfoPage
    CreateCorner(Card, 10)
    CreateStroke(Card, Theme.Stroke, 1)

    local VerLabel = Instance.new("TextLabel")
    VerLabel.Size = UDim2.new(0, 60, 0, 20)
    VerLabel.Position = UDim2.new(0, 14, 0, 6)
    VerLabel.BackgroundTransparency = 1
    VerLabel.Text = ver
    VerLabel.TextColor3 = Theme.Accent
    VerLabel.Font = Enum.Font.GothamBold
    VerLabel.TextSize = 12
    VerLabel.TextXAlignment = Enum.TextXAlignment.Left
    VerLabel.Parent = Card

    local NameLabel = Instance.new("TextLabel")
    NameLabel.Size = UDim2.new(1, -100, 0, 20)
    NameLabel.Position = UDim2.new(0, 80, 0, 6)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Text = name
    NameLabel.TextColor3 = Theme.Text
    NameLabel.Font = Enum.Font.GothamMedium
    NameLabel.TextSize = 11
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left
    NameLabel.Parent = Card

    local DescLabel = Instance.new("TextLabel")
    DescLabel.Size = UDim2.new(1, -28, 0, 16)
    DescLabel.Position = UDim2.new(0, 14, 0, 28)
    DescLabel.BackgroundTransparency = 1
    DescLabel.Text = desc
    DescLabel.TextColor3 = Theme.TextDim
    DescLabel.Font = Enum.Font.Gotham
    DescLabel.TextSize = 10
    DescLabel.TextXAlignment = Enum.TextXAlignment.Left
    DescLabel.Parent = Card

    yCL = yCL + 56
end

-- ВКЛАДКИ
local Pages = {
    Welcome = WelcomePage,
    Main = MainPage,
    Settings = SettingsPage,
    Info = InfoPage,
}

local Tabs = {}
local ActiveTab = nil
local TabObjects = {}

local function SwitchPage(pageKey)
    for _, page in pairs(Pages) do
        page.Visible = false
    end
    if Pages[pageKey] then
        Pages[pageKey].Visible = true
    end
end

local function CreateTab(name, pageKey)
    local Tab = Instance.new("TextButton")
    Tab.Size = UDim2.new(1, -16, 0, 38)
    Tab.Position = UDim2.new(0, 8, 0, 8 + (#Tabs * 44))
    Tab.BackgroundColor3 = Theme.Surface
    Tab.BackgroundTransparency = 1
    Tab.Text = ""
    Tab.BorderSizePixel = 0
    Tab.Parent = Sidebar
    CreateCorner(Tab, 8)

    local Indicator = Instance.new("Frame")
    Indicator.Size = UDim2.new(0, 3, 0.5, 0)
    Indicator.Position = UDim2.new(0, 0, 0.25, 0)
    Indicator.BackgroundColor3 = Theme.Accent
    Indicator.BorderSizePixel = 0
    Indicator.BackgroundTransparency = 1
    Indicator.Parent = Tab
    CreateCorner(Indicator, 2)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -20, 1, 0)
    Label.Position = UDim2.new(0, 20, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = Theme.TextDim
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Tab

    local SetActive = function(state)
        if state then
            TweenService:Create(Tab, TweenInfo.new(0.2), {
                BackgroundTransparency = 0.85,
                BackgroundColor3 = Theme.Accent
            }):Play()
            TweenService:Create(Label, TweenInfo.new(0.2), {
                TextColor3 = Theme.Text
            }):Play()
            TweenService:Create(Indicator, TweenInfo.new(0.2), {
                BackgroundTransparency = 0
            }):Play()
        else
            TweenService:Create(Tab, TweenInfo.new(0.2), {
                BackgroundTransparency = 1,
                BackgroundColor3 = Theme.Surface
            }):Play()
            TweenService:Create(Label, TweenInfo.new(0.2), {
                TextColor3 = Theme.TextDim
            }):Play()
            TweenService:Create(Indicator, TweenInfo.new(0.2), {
                BackgroundTransparency = 1
            }):Play()
        end
    end

    TabObjects[Tab] = SetActive

    Tab.MouseEnter:Connect(function()
        if ActiveTab ~= Tab then
            TweenService:Create(Tab, TweenInfo.new(0.15), {
                BackgroundTransparency = 0.9,
                BackgroundColor3 = Theme.SurfaceHover
            }):Play()
        end
    end)

    Tab.MouseLeave:Connect(function()
        if ActiveTab ~= Tab then
            TweenService:Create(Tab, TweenInfo.new(0.15), {
                BackgroundTransparency = 1,
                BackgroundColor3 = Theme.Surface
            }):Play()
        end
    end)

    Tab.MouseButton1Click:Connect(function()
        if ActiveTab and TabObjects[ActiveTab] then
            TabObjects[ActiveTab](false)
        end
        ActiveTab = Tab
        SetActive(true)
        SwitchPage(pageKey)
    end)

    table.insert(Tabs, Tab)
    return Tab
end

CreateTab("Главная", "Main")
CreateTab("Настройки", "Settings")
CreateTab("Инфо", "Info")

SwitchPage("Welcome")

-- ОТКРЫВАШКА
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
ToggleBtn.Position = UDim2.new(0, 20, 0.5, -25)
ToggleBtn.BackgroundColor3 = Theme.Background
ToggleBtn.Text = ""
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Active = true
ToggleBtn.Parent = ScreenGui
CreateCorner(ToggleBtn, 25)
CreateStroke(ToggleBtn, Theme.Accent, 1.5)

local ToggleIcon = Instance.new("Frame")
ToggleIcon.Size = UDim2.new(0, 22, 0, 22)
ToggleIcon.Position = UDim2.new(0.5, -11, 0.5, -11)
ToggleIcon.BackgroundColor3 = Theme.Accent
ToggleIcon.BorderSizePixel = 0
ToggleIcon.Parent = ToggleBtn
CreateCorner(ToggleIcon, 6)

local ToggleIconInner = Instance.new("Frame")
ToggleIconInner.Size = UDim2.new(0, 8, 0, 8)
ToggleIconInner.Position = UDim2.new(0.5, -4, 0.5, -4)
ToggleIconInner.BackgroundColor3 = Theme.Background
ToggleIconInner.BorderSizePixel = 0
ToggleIconInner.Parent = ToggleIcon
CreateCorner(ToggleIconInner, 2)

local IsDraggingToggle = false
local ToggleDragStart = nil
local ToggleStartPos = nil
local ToggleMoved = false

ToggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        IsDraggingToggle = true
        ToggleMoved = false
        ToggleDragStart = input.Position
        ToggleStartPos = ToggleBtn.Position
    end
end)

ToggleBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        IsDraggingToggle = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if IsDraggingToggle and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - ToggleDragStart
        if math.abs(delta.X) > 3 or math.abs(delta.Y) > 3 then
            ToggleMoved = true
        end
        ToggleBtn.Position = UDim2.new(
            ToggleStartPos.X.Scale, ToggleStartPos.X.Offset + delta.X,
            ToggleStartPos.Y.Scale, ToggleStartPos.Y.Offset + delta.Y
        )
    end
end)

ToggleBtn.MouseButton1Click:Connect(function()
    if ToggleMoved then return end
    if MainFrame.Visible then
        local tween = TweenService:Create(MainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        })
        tween:Play()
        tween.Completed:Connect(function()
            MainFrame.Visible = false
        end)
    else
        MainFrame.Size = UDim2.new(0, 0, 0, 0)
        MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        MainFrame.Visible = true
        task.wait(0.02)
        TweenService:Create(MainFrame, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 520, 0, 420),
            Position = UDim2.new(0.5, -260, 0.5, -210)
        }):Play()
    end
end)

ToggleBtn.MouseEnter:Connect(function()
    TweenService:Create(ToggleBtn, TweenInfo.new(0.15), {
        BackgroundColor3 = Theme.SurfaceHover
    }):Play()
end)
ToggleBtn.MouseLeave:Connect(function()
    TweenService:Create(ToggleBtn, TweenInfo.new(0.15), {
        BackgroundColor3 = Theme.Background
    }):Play()
end)

-- ПЕРЕТАСКИВАНИЕ
local dragging, dragStart, startPos

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)

TitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    local tween = TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0)
    })
    tween:Play()
    tween.Completed:Connect(function()
        MainFrame.Visible = false
    end)
end)

-- FIRE BTN
task.spawn(function()
    while true do
        task.wait(0.5)
        local newBtn = FindFireButton()
        if newBtn then fireBtn = newBtn end
    end
end)

local function OnDeath()
    autoAimEnabled = false
    UpdateCheckboxVisual()
    fireBtn = nil
    fireCountThisCycle = 0
    watchedParts = {}
    baseDistances = {}
    hasPending = false
    pendingTime = 0
    watchStartHeight = 0
end

local function BindHumanoid(character)
    if not character then return end
    local humanoid = character:WaitForChild("Humanoid", 5)
    if humanoid then
        humanoid.Died:Connect(OnDeath)
    end
end

if plr.Character then BindHumanoid(plr.Character) end

plr.CharacterAdded:Connect(function(char)
    fireBtn = nil
    fireCountThisCycle = 0
    watchedParts = {}
    baseDistances = {}
    hasPending = false

    BindHumanoid(char)

    task.wait(1.5)
    local newBtn = FindFireButton()
    if newBtn then fireBtn = newBtn end
end)

-- ГЛАВНЫЙ ЦИКЛ
RunService.RenderStepped:Connect(function()
    local now = tick()

    if hasPending and #watchedParts >= 2 then
        local firstPart = watchedParts[1]
        local maxGrowth = 0
        local partsAlive = 0
        local skipAsMiss = false

        if firstPart and firstPart.Parent then
            local currentY = firstPart.Position.Y
            if watchStartHeight - currentY >= 40 then
                skipAsMiss = true
            end
        end

        if skipAsMiss then
            hasPending = false
            watchedParts = {}
            baseDistances = {}
        else
            if firstPart and firstPart.Parent then
                partsAlive = 1
                for i = 2, #watchedParts do
                    local part = watchedParts[i]
                    if part and part.Parent then
                        partsAlive = partsAlive + 1
                        local nowDist = (part.Position - firstPart.Position).Magnitude
                        local baseDist = baseDistances[i - 1] or 0
                        if baseDist > 0.1 then
                            local growth = nowDist / baseDist
                            if growth > maxGrowth then maxGrowth = growth end
                        end
                    end
                end
            end

            if maxGrowth >= 1.5 or partsAlive < #watchedParts then
                hitCount = hitCount + 1
                if customSoundsEnabled then PlayHitSound() end
                StatsLabel.Text = "Сбито: " .. hitCount .. "  ·  Промахов: " .. missCount
                hasPending = false
                watchedParts = {}
                baseDistances = {}
            elseif now - pendingTime >= CHECK_TIME then
                missCount = missCount + 1
                if customSoundsEnabled then PlayMissSound() end
                StatsLabel.Text = "Сбито: " .. hitCount .. "  ·  Промахов: " .. missCount
                hasPending = false
                watchedParts = {}
                baseDistances = {}
            end
        end
    end

    if not autoAimEnabled then return end

    local hasStinger = plr.Character and plr.Character:FindFirstChild("Stinger-M")
    if not hasStinger then
        fireCountThisCycle = 0
        return
    end

    local dronePos, dist, name, droneObj = FindDrone()

    if dronePos then
        local targetCFrame = CFrame.new(cam.CFrame.Position, dronePos)
        cam.CFrame = cam.CFrame:Lerp(targetCFrame, 0.2)

        local green = IsCircleGreen()

        if autoFireEnabled then
            if not IsFireBtnValid() then
                fireBtn = FindFireButton()
            end

            if IsFireBtnValid() then
                local isMoving = IsPlayerMoving()
                if stopWhenMoving and isMoving then
                    -- стоп
                elseif not green then
                    fireCountThisCycle = 0
                else
                    if fireCountThisCycle < 2 then
                        if now - lastFire >= fireCooldown then
                            lastFire = now
                            fireCountThisCycle = fireCountThisCycle + 1
                            TapButton(fireBtn)

                            if fireCountThisCycle == 1 and droneObj then
                                watchedParts, baseDistances = CaptureDrone(droneObj)
                                pendingTime = now
                                hasPending = true
                                local wp = droneObj.PrimaryPart or droneObj:FindFirstChildWhichIsA("BasePart")
                                watchStartHeight = wp and wp.Position.Y or 0
                            end
                        end
                    end
                end
            end
        end
    end
end)

print("Zep Hub v1.0 (Release) загружен")
