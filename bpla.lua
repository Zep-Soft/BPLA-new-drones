local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
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
local ScriptVersion = "v1.3"
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

local autoAimEnabled = false
local autoFireEnabled = true
local stopWhenMoving = true
local maxDistance = 2000
local minHeight = 20
local fireBtn = nil
local lastFire = 0
local fireCooldown = 0.15
local fireCountThisCycle = 0

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

local function IsDroneVisible(dronePart, camPos, dist)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {plr.Character, cam}

    local rayDir = (dronePart.Position - camPos).Unit * dist
    local rayResult = workspace:Raycast(camPos, rayDir, rayParams)

    if not rayResult then return true end
    if rayResult.Instance:IsDescendantOf(dronePart.Parent) then return true end
    return false
end

local function FindDrone()
    local dronesFolder = workspace:FindFirstChild("Drones")
    if not dronesFolder then return nil, 0, nil end

    local nearestPos = nil
    local nearestDist = maxDistance
    local nearestName = nil
    local camPos = cam.CFrame.Position

    for _, obj in pairs(dronesFolder:GetChildren()) do
        if obj:IsA("Model") then
            local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if part then
                local pos = part.Position
                local dist = (pos - camPos).Magnitude

                if pos.Y >= minHeight and dist < nearestDist then
                    if IsDroneVisible(part, camPos, dist) then
                        nearestDist = dist
                        nearestPos = pos
                        nearestName = obj.Name
                    end
                end
            end
        end
    end

    return nearestPos, nearestDist, nearestName
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

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 520, 0, 380)
MainFrame.Position = UDim2.new(0.5, -260, 0.5, -190)
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

local MainPage = Instance.new("Frame")
MainPage.Size = UDim2.new(1, 0, 1, 0)
MainPage.BackgroundTransparency = 1
MainPage.Visible = false
MainPage.Parent = ContentArea

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

-- MAIN PAGE
CreateSectionHeader(MainPage, "AIM", 10)

local CheckContainer = Instance.new("Frame")
CheckContainer.Size = UDim2.new(1, -32, 0, 44)
CheckContainer.Position = UDim2.new(0, 16, 0, 40)
CheckContainer.BackgroundColor3 = Theme.Surface
CheckContainer.BorderSizePixel = 0
CheckContainer.Parent = MainPage
CreateCorner(CheckContainer, 10)
CreateStroke(CheckContainer, Theme.Stroke, 1)

local CheckBox = Instance.new("Frame")
CheckBox.Size = UDim2.new(0, 20, 0, 20)
CheckBox.Position = UDim2.new(0, 14, 0.5, -10)
CheckBox.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
CheckBox.BorderSizePixel = 0
CheckBox.Parent = CheckContainer
CreateCorner(CheckBox, 5)

local CheckBoxStroke = Instance.new("UIStroke")
CheckBoxStroke.Color = Theme.Stroke
CheckBoxStroke.Thickness = 1.5
CheckBoxStroke.Parent = CheckBox

local CheckMark = Instance.new("ImageLabel")
CheckMark.Size = UDim2.new(0, 14, 0, 14)
CheckMark.Position = UDim2.new(0.5, -7, 0.5, -7)
CheckMark.BackgroundTransparency = 1
CheckMark.Image = "rbxassetid://6031094667"
CheckMark.ImageColor3 = Theme.Accent
CheckMark.ImageTransparency = 1
CheckMark.Parent = CheckBox

local CheckLabel = Instance.new("TextLabel")
CheckLabel.Size = UDim2.new(1, -50, 1, 0)
CheckLabel.Position = UDim2.new(0, 44, 0, 0)
CheckLabel.BackgroundTransparency = 1
CheckLabel.Text = "Auto-Aim"
CheckLabel.TextColor3 = Theme.Text
CheckLabel.Font = Enum.Font.GothamMedium
CheckLabel.TextSize = 13
CheckLabel.TextXAlignment = Enum.TextXAlignment.Left
CheckLabel.Parent = CheckContainer

local CheckBtn = Instance.new("TextButton")
CheckBtn.Size = UDim2.new(1, 0, 1, 0)
CheckBtn.BackgroundTransparency = 1
CheckBtn.Text = ""
CheckBtn.Parent = CheckContainer

local function UpdateCheckbox()
    if autoAimEnabled then
        CheckBox.BackgroundColor3 = Theme.Accent
        CheckBoxStroke.Color = Theme.Accent
        CheckMark.ImageTransparency = 0
    else
        CheckBox.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
        CheckBoxStroke.Color = Theme.Stroke
        CheckMark.ImageTransparency = 1
    end
end

CheckBtn.MouseButton1Click:Connect(function()
    autoAimEnabled = not autoAimEnabled
    UpdateCheckbox()
end)

CheckContainer.MouseEnter:Connect(function()
    TweenService:Create(CheckContainer, TweenInfo.new(0.15), {
        BackgroundColor3 = Theme.SurfaceHover
    }):Play()
end)

CheckContainer.MouseLeave:Connect(function()
    TweenService:Create(CheckContainer, TweenInfo.new(0.15), {
        BackgroundColor3 = Theme.Surface
    }):Play()
end)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -32, 0, 220)
StatusLabel.Position = UDim2.new(0, 16, 0, 100)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Ожидание Stinger-M..."
StatusLabel.TextColor3 = Theme.TextDim
StatusLabel.Font = Enum.Font.Code
StatusLabel.TextSize = 11
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.TextYAlignment = Enum.TextYAlignment.Top
StatusLabel.TextWrapped = true
StatusLabel.Parent = MainPage

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
            Size = UDim2.new(0, 520, 0, 380),
            Position = UDim2.new(0.5, -260, 0.5, -190)
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
    task.wait(0.5)
    local newBtn = FindFireButton()
    if newBtn then fireBtn = newBtn end
end)

RunService.RenderStepped:Connect(function()
    local hasStinger = plr.Character and plr.Character:FindFirstChild("Stinger-M")

    if not autoAimEnabled then
        StatusLabel.Text = "Auto-Aim выключен"
        StatusLabel.TextColor3 = Theme.TextDim
        return
    end

    if not hasStinger then
        StatusLabel.Text = "⏳ Ожидание Stinger-M в руке..."
        StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 120)
        fireCountThisCycle = 0
        return
    end

    local dronePos, dist, name = FindDrone()

    if dronePos then
        local targetCFrame = CFrame.new(cam.CFrame.Position, dronePos)
        cam.CFrame = cam.CFrame:Lerp(targetCFrame, 0.2)

        local green = IsCircleGreen()
        local statusText = "Цель: " .. tostring(name)
        statusText = statusText .. "\nВысота: " .. math.floor(dronePos.Y)
        statusText = statusText .. "\nДист: " .. math.floor(dist)
        statusText = statusText .. "\nКруг зелёный: " .. (green and "ДА" or "НЕТ")
        statusText = statusText .. "\nВыстрелов: " .. fireCountThisCycle .. "/2"

        if autoFireEnabled then
            if not IsFireBtnValid() then
                fireBtn = FindFireButton()
            end

            if IsFireBtnValid() then
                local isMoving = IsPlayerMoving()

                if stopWhenMoving and isMoving then
                    statusText = statusText .. "\n🚫 Ходьба — стоп"
                elseif not green then
                    fireCountThisCycle = 0
                    statusText = statusText .. "\n⏳ Ждём зелёный круг"
                else
                    if fireCountThisCycle < 2 then
                        local now = tick()
                        if now - lastFire >= fireCooldown then
                            lastFire = now
                            fireCountThisCycle = fireCountThisCycle + 1
                            TapButton(fireBtn)
                            statusText = statusText .. "\n🔥 FIRE (" .. fireCountThisCycle .. "/2)"
                        else
                            statusText = statusText .. "\n⏳ кулдаун"
                        end
                    else
                        statusText = statusText .. "\n✅ 2 выстрела сделано"
                    end
                end
            else
                statusText = statusText .. "\n⏳ Fire не найден"
            end
        end

        StatusLabel.Text = statusText
        StatusLabel.TextColor3 = green and Color3.fromRGB(120, 255, 120) or Color3.fromRGB(255, 220, 120)
    else
        StatusLabel.Text = "Летающих дронов нет\n(мин. высота " .. minHeight .. ")"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 180, 120)
    end
end)

print("Zep Hub: загрузка завершена")
