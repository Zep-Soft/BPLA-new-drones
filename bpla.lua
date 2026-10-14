local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local plr = Players.LocalPlayer
local cam = workspace.CurrentCamera

local Theme = {
    Background   = Color3.fromRGB(18, 18, 22),
    Surface      = Color3.fromRGB(26, 26, 32),
    SurfaceHover = Color3.fromRGB(36, 36, 44),
    Accent       = Color3.fromRGB(88, 132, 255),
    Text         = Color3.fromRGB(235, 235, 240),
    TextDim      = Color3.fromRGB(130, 130, 145),
    Stroke       = Color3.fromRGB(50, 50, 60),
}

local ScriptName = "Zep Hub"
local ScriptVersion = "v0.5"
local ScriptAuthor = "Z3pty0rbex (@Aminb1000)"

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZepHub_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game:GetService("CoreGui")

local function CreateCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 12)
    c.Parent = parent
    return c
end

local function CreateStroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or Theme.Stroke
    s.Thickness = thickness or 1
    s.Transparency = 0.3
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

-- ЗВУКИ
local HitSoundIDs = {
    136688569661082,
    7531253465,
}
local MissSoundID = 117671199302919

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

-- ДЕТЕКТ ПОПАДАНИЯ
local watchedParts = {}
local baseDistances = {}
local pendingTime = 0
local CHECK_TIME = 3
local hasPending = false
local watchStartHeight = 0

local hitCount = 0
local missCount = 0

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
    local absPos = button.AbsolutePosition
    local absSize = button.AbsoluteSize
    local x = absPos.X + absSize.X / 2
    local y = absPos.Y + absSize.Y / 2
    VIM:SendMouseButtonEvent(x, y, 0, true, game, 1)
    task.wait(0.02)
    VIM:SendMouseButtonEvent(x, y, 0, false, game, 1)
end

-- ЗАХВАТ ЧАСТЕЙ ДРОНА
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

-- UI
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

local WelcomePage = Instance.new("Frame")
WelcomePage.Size = UDim2.new(1, 0, 1, 0)
WelcomePage.BackgroundTransparency = 1
WelcomePage.Visible = true
WelcomePage.Parent = ContentArea

local SettingsPage = Instance.new("Frame")
SettingsPage.Size = UDim2.new(1, 0, 1, 0)
SettingsPage.BackgroundTransparency = 1
SettingsPage.Visible = false
SettingsPage.Parent = ContentArea

local InfoPage = Instance.new("Frame")
InfoPage.Size = UDim2.new(1, 0, 1, 0)
InfoPage.BackgroundTransparency = 1
InfoPage.Visible = false
InfoPage.Parent = ContentArea

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

local MainPadding = Instance.new("UIPadding")
MainPadding.PaddingTop = UDim.new(0, 8)
MainPadding.PaddingBottom = UDim.new(0, 8)
MainPadding.Parent = MainPage

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

    return Container
end

CreateCheckbox(MainPage, "Auto-Aim", 40, false, function(v)
    autoAimEnabled = v
end)

CreateSectionHeader(MainPage, "Звуки", 92)

CreateCheckbox(MainPage, "Кастомные звуки", 122, false, function(v)
    customSoundsEnabled = v
end)

local function CreateIdField(parent, label, defaultId, yOffset, onApply)
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
        if id then
            PlaySoundById(id)
        end
    end)

    ApplyBtn.MouseButton1Click:Connect(function()
        local id = tonumber(Input.Text)
        if id then
            onApply(id)
            ApplyBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
            task.wait(0.3)
            ApplyBtn.BackgroundColor3 = Color3.fromRGB(60, 80, 180)
        end
    end)

    return Container
end

CreateIdField(MainPage, "Попадание 1", HitSoundIDs[1], 168, function(id)
    HitSoundIDs[1] = id
end)

CreateIdField(MainPage, "Попадание 2", HitSoundIDs[2], 204, function(id)
    HitSoundIDs[2] = id
end)

CreateIdField(MainPage, "Промах", MissSoundID, 240, function(id)
    MissSoundID = id
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

CreateSectionHeader(SettingsPage, "Настройки", 16)
CreateCard(SettingsPage, "Контент", "Добавим позже", 45)

CreateSectionHeader(InfoPage, "Информация", 16)
CreateCard(InfoPage, "Автор", ScriptAuthor, 45)

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

task.spawn(function()
    while true do
        task.wait(0.5)
        local newBtn = FindFireButton()
        if newBtn then fireBtn = newBtn end
    end
end)

plr.CharacterAdded:Connect(function(char)
    fireBtn = nil
    fireCountThisCycle = 0
    watchedParts = {}
    baseDistances = {}
    hasPending = false
    task.wait(1)
    local newBtn = FindFireButton()
    if newBtn then fireBtn = newBtn end
end)

RunService.RenderStepped:Connect(function()
    local now = tick()

    -- ДЕТЕКТ ПОПАДАНИЯ (по разлёту частей)
    if hasPending and #watchedParts >= 2 then
        local firstPart = watchedParts[1]
        local maxGrowth = 0
        local partsAlive = 0
        local skipAsMiss = false

        if firstPart and firstPart.Parent then
            -- Проверка: если дрон упал на 40+ studs от высоты выстрела → сам упал
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
                            if growth > maxGrowth then
                                maxGrowth = growth
                            end
                        end
                    end
                end
            end

            if maxGrowth >= 1.5 or partsAlive < #watchedParts then
                hitCount = hitCount + 1
                if customSoundsEnabled then
                    PlayHitSound()
                end
                StatsLabel.Text = "Сбито: " .. hitCount .. "  ·  Промахов: " .. missCount
                hasPending = false
                watchedParts = {}
                baseDistances = {}
            elseif now - pendingTime >= CHECK_TIME then
                missCount = missCount + 1
                if customSoundsEnabled then
                    PlayMissSound()
                end
                StatsLabel.Text = "Сбито: " .. hitCount .. "  ·  Промахов: " .. missCount
                hasPending = false
                watchedParts = {}
                baseDistances = {}
            end
        end
    end

    if not autoAimEnabled then
        return
    end

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

                            -- Запоминаем дрона только после реального выстрела
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

print("Zep Hub v0.5: загрузка завершена")
