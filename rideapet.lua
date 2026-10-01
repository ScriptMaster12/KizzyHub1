--//====================================================
--// Ride A Pet Egg Hub - Lite (Main + ESP + Tools + Settings, same GUI)
--//====================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

-- Prevent Auto Load / queue-on-teleport / executor autoexec from starting
-- multiple KizzyHub copies at the same time.
local KizzyEnv = (type(getgenv) == "function" and getgenv()) or _G
if KizzyEnv.KizzyHubRunning then
    return
end
KizzyEnv.KizzyHubRunning = true

-- Clean stale KizzyHub auto-execute loaders left in other executor folders.
-- Older builds could leave more than one EggHub_AutoLoad.lua behind, causing
-- the hub/notifications to start 2-3 times on every server hop.
do
    if type(isfile) == "function" and type(delfile) == "function" then
        local staleLoaders = {
            "autoexec/EggHub_AutoLoad.lua",
            "Autoexec/EggHub_AutoLoad.lua",
            "autoexecute/EggHub_AutoLoad.lua",
            "AutoExecute/EggHub_AutoLoad.lua",
        }
        for _, path in ipairs(staleLoaders) do
            pcall(function()
                if isfile(path) then
                    delfile(path)
                end
            end)
        end
    end
end
local KIZZYHUB_SESSION_STARTED = os.clock()
local KIZZYHUB_VERSION = "1.1.0"

-- Forward declarations so the startup logger (defined early) can see these later-initialised values.
local EspEnabled, AutoFarmEnabled, AutoLavaMutation, MoveMode, AntiAFKEnabled, PT


-- KIZZYHUB ANIMATED LOADING SCREEN
do
    local old = PlayerGui:FindFirstChild("KizzyHub_LoadingScreen")
    if old then old:Destroy() end

    local g = Instance.new("ScreenGui")
    g.Name = "KizzyHub_LoadingScreen"
    g.IgnoreGuiInset = true
    g.ResetOnSpawn = false
    g.DisplayOrder = 1000000
    g.Parent = PlayerGui

    local bg = Instance.new("Frame")
    bg.Size = UDim2.fromScale(1,1)
    bg.BackgroundColor3 = Color3.fromRGB(9,10,16)
    bg.BackgroundTransparency = 1
    bg.BorderSizePixel = 0
    bg.Parent = g

    local card = Instance.new("Frame")
    card.AnchorPoint = Vector2.new(.5,.5)
    card.Position = UDim2.fromScale(.5,.5)
    card.Size = UDim2.fromOffset(330,150)
    card.BackgroundColor3 = Color3.fromRGB(20,21,31)
    card.BackgroundTransparency = 1
    card.BorderSizePixel = 0
    card.Parent = bg
    local cc = Instance.new("UICorner"); cc.CornerRadius=UDim.new(0,16); cc.Parent=card
    local stroke=Instance.new("UIStroke"); stroke.Color=Color3.fromRGB(80,130,220); stroke.Transparency=1; stroke.Thickness=1.5; stroke.Parent=card
    local scale=Instance.new("UIScale"); scale.Scale=.88; scale.Parent=card

    local title=Instance.new("TextLabel")
    title.BackgroundTransparency=1
    title.Position=UDim2.fromOffset(18,28)
    title.Size=UDim2.new(1,-36,0,34)
    title.Font=Enum.Font.GothamBold
    title.Text="Loading KizzyHub..."
    title.TextColor3=Color3.fromRGB(245,246,255)
    title.TextTransparency=1
    title.TextSize=22
    title.Parent=card

    local discord=Instance.new("TextButton")
    discord.BackgroundTransparency=1
    discord.Position=UDim2.fromOffset(18,69)
    discord.Size=UDim2.new(1,-36,0,24)
    discord.Font=Enum.Font.GothamMedium
    discord.Text="discord.gg/zgFRf3uJDH"
    discord.TextColor3=Color3.fromRGB(145,165,235)
    discord.TextTransparency=1
    discord.TextSize=12
    discord.Parent=card

    local barBg=Instance.new("Frame")
    barBg.Position=UDim2.fromOffset(24,112)
    barBg.Size=UDim2.new(1,-48,0,5)
    barBg.BackgroundColor3=Color3.fromRGB(45,47,62)
    barBg.BackgroundTransparency=1
    barBg.BorderSizePixel=0
    barBg.Parent=card
    local bc=Instance.new("UICorner"); bc.CornerRadius=UDim.new(1,0); bc.Parent=barBg

    local bar=Instance.new("Frame")
    bar.Size=UDim2.fromScale(0,1)
    bar.BackgroundColor3=Color3.fromRGB(80,130,220)
    bar.BorderSizePixel=0
    bar.Parent=barBg
    local fc=Instance.new("UICorner"); fc.CornerRadius=UDim.new(1,0); fc.Parent=bar

    discord.Activated:Connect(function()
        local invite="https://discord.gg/zgFRf3uJDH"
        if type(setclipboard)=="function" then pcall(setclipboard,invite)
        elseif type(toclipboard)=="function" then pcall(toclipboard,invite) end
    end)

    TweenService:Create(bg,TweenInfo.new(.28),{BackgroundTransparency=.08}):Play()
    TweenService:Create(card,TweenInfo.new(.32,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{BackgroundTransparency=0}):Play()
    TweenService:Create(stroke,TweenInfo.new(.32),{Transparency=.25}):Play()
    TweenService:Create(scale,TweenInfo.new(.38,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()
    TweenService:Create(title,TweenInfo.new(.25),{TextTransparency=0}):Play()
    TweenService:Create(discord,TweenInfo.new(.35),{TextTransparency=0}):Play()
    TweenService:Create(barBg,TweenInfo.new(.35),{BackgroundTransparency=0}):Play()

    local running=true
    task.spawn(function()
        local dots=0
        while running and g.Parent do
            dots=(dots%3)+1
            title.Text="Loading KizzyHub"..string.rep(".",dots)
            task.wait(.35)
        end
    end)

    local loadTween=TweenService:Create(bar,TweenInfo.new(5,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Size=UDim2.fromScale(1,1)})
    loadTween:Play()
    loadTween.Completed:Wait()
    running=false
    title.Text="KizzyHub Loaded!"
    task.wait(.3)

    TweenService:Create(scale,TweenInfo.new(.24,Enum.EasingStyle.Quint,Enum.EasingDirection.In),{Scale=.94}):Play()
    TweenService:Create(card,TweenInfo.new(.24),{BackgroundTransparency=1}):Play()
    TweenService:Create(stroke,TweenInfo.new(.2),{Transparency=1}):Play()
    TweenService:Create(title,TweenInfo.new(.18),{TextTransparency=1}):Play()
    TweenService:Create(discord,TweenInfo.new(.18),{TextTransparency=1}):Play()
    TweenService:Create(barBg,TweenInfo.new(.18),{BackgroundTransparency=1}):Play()
    TweenService:Create(bg,TweenInfo.new(.28),{BackgroundTransparency=1}):Play()
    task.wait(.3)
    g:Destroy()
end



local ESP_NAME = "RenderedEggsESP_AutoFarm"

--====================================================
-- EXECUTOR COMPATIBILITY CHECK
--====================================================
local ExecutorCompatibility = {
    Name = "Unknown Executor",
    FileSaving = false,
    HttpRequests = false,
    Clipboard = false,
}

do
    local ok, name = pcall(function()
        if type(identifyexecutor) == "function" then
            local executorName = identifyexecutor()
            if executorName and tostring(executorName) ~= "" then
                return tostring(executorName)
            end
        end
        if type(getexecutorname) == "function" then
            local executorName = getexecutorname()
            if executorName and tostring(executorName) ~= "" then
                return tostring(executorName)
            end
        end
        return "Unknown Executor"
    end)
    if ok and name then
        ExecutorCompatibility.Name = name
    end

    ExecutorCompatibility.FileSaving =
        type(writefile) == "function"
        and type(readfile) == "function"
        and type(isfile) == "function"

    ExecutorCompatibility.HttpRequests =
        type(request) == "function"
        or type(http_request) == "function"
        or (type(syn) == "table" and type(syn.request) == "function")
        or (type(http) == "table" and type(http.request) == "function")

    ExecutorCompatibility.Clipboard =
        type(setclipboard) == "function"
        or type(toclipboard) == "function"
end

local function executorSupportText()
    if ExecutorCompatibility.FileSaving and ExecutorCompatibility.HttpRequests then
        return "Full Support"
    elseif ExecutorCompatibility.FileSaving or ExecutorCompatibility.HttpRequests then
        return "Limited Support"
    end
    return "Not Supported"
end

local function showExecutorCompatibility()
    local support = executorSupportText()
    local good = support == "Full Support"

    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "KizzyHub • Compatibility",
            Text = ExecutorCompatibility.Name .. "\n" .. support,
            Duration = 6,
        })
    end)

    return good, support
end

task.spawn(function()
    task.wait(1)
    showExecutorCompatibility()
end)


-- Clean up leftovers
if PlayerGui:FindFirstChild("RenderedEggsESP_AutoFarm_GUI") then
    PlayerGui.RenderedEggsESP_AutoFarm_GUI:Destroy()
end
if PlayerGui:FindFirstChild("PetTools_ESP_GUI") then
    PlayerGui.PetTools_ESP_GUI:Destroy()
end
if PlayerGui:FindFirstChild("RenderedEggsESP_AutoFarm_Overlay") then
    PlayerGui.RenderedEggsESP_AutoFarm_Overlay:Destroy()
end
for _, obj in ipairs(workspace:GetDescendants()) do
    if obj.Name == ESP_NAME then
        obj:Destroy()
    end
end

local Folder = workspace:FindFirstChild("RenderedEggs")
if not Folder then
    warn("[KizzyHub] Waiting for workspace.RenderedEggs...")
    Folder = workspace:WaitForChild("RenderedEggs")
end

--====================================================
-- CONFIG & STATE
--====================================================

local UPDATE_RATE = 0.5
local CLAIM_DELAY = 0.15
local MAX_ATTEMPTS = 6
local ATTEMPT_WAIT = 0.25
local RETURN_DELAY = 0.3

local ESPs = {}
local Connections = {}

local Running = true
local SelectedEgg = nil
local Claiming = false
local IsMinimized = false
EspEnabled = false
AutoFarmEnabled = false
AutoLavaMutation = true
MoveMode = "TP" -- "TP" or "Fly"

-- Shared state used by the new Main-tab farm. The webhook implementation is
-- defined later in the file, so Main calls through this bridge once available.
MainFarmWebhookClaim = nil
VolcanoMutationSerial = 0

-- Volcano / Lava Mutation state.
-- Kept compact because this hub is already a very large Luau chunk.
VolcanoState = {
    Radius = 10,
    TopWait = 10,
    DipCooldown = 1,
    LastDip = 0,
    Position1 = Vector3.new(-4914.52100, 41295.43359, -3705.13477),
    Position3 = Vector3.new(-4968.01562, 41281.78906, -3650.59204),
    TweenSpeed = 80,
    WasInside = false,
}

local Character
local RootPart
local BasePosition = nil
local BaseModel = nil
local BaseName = "Not detected"

--====================================================
-- BASE DETECTION
--====================================================

local function getRootPart(model)
    if model and model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then
        return model.PrimaryPart
    end
    return model and model:FindFirstChildWhichIsA("BasePart", true)
end

local function getBasePosition(model)
    if not model then return nil end
    local preferred = {"SpawnLocation", "Spawn", "BaseSpawn", "PlayerSpawn", "Center", "Core", "Main", "Primary", "Base"}
    for _, name in ipairs(preferred) do
        local obj = model:FindFirstChild(name, true)
        if obj then
            if obj:IsA("BasePart") then return obj.Position end
            if obj:IsA("Attachment") then return obj.WorldPosition end
            if obj:IsA("SpawnLocation") then return obj.Position end
        end
    end
    local part = getRootPart(model)
    if part then return part.Position end
    local ok, cf = pcall(function() return model:GetBoundingBox() end)
    return ok and cf.Position or nil
end

local function valueMatchesPlayer(value)
    if not value then return false end
    local text = tostring(value):lower()
    return text == tostring(LocalPlayer.UserId):lower()
        or text == LocalPlayer.Name:lower()
        or text == LocalPlayer.DisplayName:lower()
end

local function findsYourLabel(model)
    for _, gui in ipairs(model:GetDescendants()) do
        if gui:IsA("BillboardGui") or gui:IsA("SurfaceGui") then
            for _, child in ipairs(gui:GetDescendants()) do
                if (child:IsA("TextLabel") or child:IsA("TextButton")) and child.Text then
                    local text = child.Text:lower()
                    if text:match("^%s*your%s") then
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function candidateScore(model)
    if not model or not model:IsA("Model") or model == Character or model:IsDescendantOf(Folder) then return -math.huge end
    local name = model.Name:lower()
    local score = 0
    if name:find("base", 1, true) then score += 15 end
    if name:find("plot", 1, true) then score += 14 end
    if name:find("ranch", 1, true) then score += 14 end
    if name:find("island", 1, true) then score += 10 end
    if name:find("tycoon", 1, true) then score += 8 end

    if findsYourLabel(model) then score += 120 end

    for _, attr in ipairs({"Owner", "OwnerName", "OwnerUserId", "UserId", "Player", "PlayerName", "ClaimedBy", "Username"}) do
        local v = model:GetAttribute(attr)
        if v ~= nil then
            score += 8
            if valueMatchesPlayer(v) then score += 80 end
        end
    end

    local pos = getBasePosition(model)
    if not pos then return -math.huge end
    return score
end

local function detectBase()
    local best, bestScore, bestPos = nil, -math.huge, nil

    for _, gui in ipairs(workspace:GetDescendants()) do
        if gui:IsA("BillboardGui") or gui:IsA("SurfaceGui") then
            local isYours = false
            for _, child in ipairs(gui:GetDescendants()) do
                if (child:IsA("TextLabel") or child:IsA("TextButton")) and child.Text
                    and child.Text:lower():match("^%s*your%s") then
                    isYours = true
                    break
                end
            end

            if isYours then
                local adornee = gui.Adornee or gui.Parent
                local pos
                if adornee then
                    if adornee:IsA("BasePart") then
                        pos = adornee.Position
                    elseif adornee:IsA("Attachment") then
                        pos = adornee.WorldPosition
                    elseif adornee:IsA("Model") then
                        pos = getBasePosition(adornee)
                    end
                end
                if pos then
                    local owner = adornee and (adornee:IsA("Model") and adornee or adornee:FindFirstAncestorOfClass("Model")) or nil
                    best, bestScore, bestPos = owner or gui, 150, pos
                    break
                end
            end
        end
    end

    if not best then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") then
                local score = candidateScore(obj)
                if score > bestScore then
                    local pos = getBasePosition(obj)
                    if pos then
                        best, bestScore, bestPos = obj, score, pos
                    end
                end
            end
        end
    end

    if best and bestScore >= 30 then
        BaseModel = best
        BasePosition = bestPos
        BaseName = best:GetFullName():gsub("^Workspace%.", "")
        return true
    end

    if RootPart and RootPart.Parent then
        BaseModel = nil
        BasePosition = RootPart.Position
        BaseName = "Spawn fallback"
        return true
    end
    return false
end

-- Re-detects which plot/base belongs to the local player (the first pass can run before the map is ready).
local function RefreshOwnedPlot()
    return detectBase()
end

if LocalPlayer.Character then
    Character = LocalPlayer.Character
    RootPart = Character:FindFirstChild("HumanoidRootPart")
    task.defer(detectBase)
    task.delay(2,function()
        if Running and RefreshOwnedPlot then pcall(RefreshOwnedPlot) end
    end)
end

table.insert(Connections, LocalPlayer.CharacterAdded:Connect(function(character)
    Character = character
    RootPart = character:WaitForChild("HumanoidRootPart", 5)
    task.wait(0.5)
    detectBase()
end))

--====================================================
-- EGG FILTER & LUCK PARSER
--====================================================

local function isEggModel(model)
    if not model:IsA("Model") then return false end
    local parent = model.Parent
    while parent and parent ~= Folder do
        if parent:IsA("Model") then return false end
        parent = parent.Parent
    end
    return parent == Folder
end

local function isOurs(inst)
    return inst.Name == ESP_NAME or inst:FindFirstAncestor(ESP_NAME) ~= nil
end

local function looksLikeLuck(text)
    if not text then return false end
    return text:match("^%s*[xX]?%s*[%d%.,]+%s*[KMBTQkmbtq]*%s*[xX]?%s*$") ~= nil
end

local function getEggLuck(model)
    local luckValue = model:GetAttribute("Luck")
        or model:GetAttribute("Tier")
        or model:GetAttribute("Multiplier")
        or model:GetAttribute("Value")

    if luckValue then return tostring(luckValue) end

    for _, child in ipairs(model:GetDescendants()) do
        if not isOurs(child) then
            if child:IsA("ValueBase") then
                local name = child.Name:lower()
                if name:find("luck") or name:find("tier") or name:find("mult") or name:find("value") then
                    return tostring(child.Value)
                end
            elseif child:IsA("TextLabel") and looksLikeLuck(child.Text) then
                return child.Text
            end
        end
    end

    for _, child in ipairs(model:GetChildren()) do
        if child:IsA("NumberValue") or child:IsA("IntValue") then
            return tostring(child.Value)
        end
    end

    return "1"
end

local LUCK_SUFFIX = { k = 1e3, m = 1e6, b = 1e9, t = 1e12, qa = 1e15, qi = 1e18 }

local function parseLuck(text)
    text = (tostring(text):gsub(",", ""))
    local num, suffix = text:match("([%d%.]+)%s*(%a*)")
    num = tonumber(num) or 0
    local mult = LUCK_SUFFIX[(suffix or ""):lower()] or 1
    return num * mult
end

local function getSortedEggs()
    local list = {}
    for model, data in pairs(ESPs) do
        if model.Parent then
            if not data.LuckNum then data.LuckNum = parseLuck(getEggLuck(model)) end
            table.insert(list, { Model = model, Luck = data.LuckNum, Dist = data.Dist or math.huge })
        end
    end
    table.sort(list, function(a, b)
        if a.Luck ~= b.Luck then return a.Luck > b.Luck end
        return a.Dist < b.Dist
    end)
    local models = {}
    for i, entry in ipairs(list) do models[i] = entry.Model end
    return models
end

--====================================================
-- GUI SETUP
--====================================================

local THEME = {
    Bg = Color3.fromRGB(22, 22, 28),
    Bar = Color3.fromRGB(34, 34, 46),
    Panel = Color3.fromRGB(15, 15, 21),
    Button = Color3.fromRGB(46, 46, 62),
    Accent = Color3.fromRGB(80, 130, 220),
    InactiveTab = Color3.fromRGB(30, 30, 38),
    ActiveTab = Color3.fromRGB(50, 50, 68),
    SelectedRow = Color3.fromRGB(60, 90, 140),
}

local function round(obj, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = obj
    return corner
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RenderedEggsESP_AutoFarm_GUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = PlayerGui

-- Main Window
local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(410, 330)
Main.Position = UDim2.new(0.5, -205, 0.4, -165)
Main.BackgroundColor3 = THEME.Bg
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = ScreenGui
round(Main, 12)

-- Mobile / small-screen responsiveness. Keeps the existing layout intact while
-- making the whole hub larger on phones and preventing it from overflowing.
local MainScale = Instance.new("UIScale")
MainScale.Name = "ResponsiveScale"
MainScale.Parent = Main

local function updateResponsiveLayout()
    local cam = workspace.CurrentCamera
    if not cam then return end
    local vp = cam.ViewportSize
    local widthScale = math.max(0.78, (vp.X - 20) / 340)
    local heightScale = math.max(0.78, (vp.Y - 80) / 330)
    local scale = math.clamp(math.min(widthScale, heightScale), 0.82, 1.18)

    -- Touch devices get a little extra size when the screen has room.
    if UserInputService.TouchEnabled then
        scale = math.min(scale, 1.14)
    end

    MainScale.Scale = scale
    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    Main.Position = UDim2.fromScale(0.5, 0.5)
end

updateResponsiveLayout()
if workspace.CurrentCamera then
    table.insert(Connections, workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateResponsiveLayout))
end

-- Floating Bubble Button (When Minimized)
local Bubble = Instance.new("TextButton")
Bubble.AnchorPoint = Vector2.new(0.5, 0.5)
Bubble.Size = UserInputService.TouchEnabled and UDim2.fromOffset(58, 58) or UDim2.fromOffset(50, 50)
Bubble.Position = Main.Position
Bubble.BackgroundColor3 = THEME.Accent
Bubble.BorderSizePixel = 0
Bubble.Font = Enum.Font.GothamBold
Bubble.Text = "🥚"
Bubble.TextColor3 = Color3.new(1, 1, 1)
Bubble.TextSize = 20
Bubble.Visible = false
Bubble.Parent = ScreenGui
round(Bubble, 25)

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 32)
TitleBar.BackgroundColor3 = THEME.Bar
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main
round(TitleBar, 12)

local Title = Instance.new("TextLabel")
Title.BackgroundTransparency = 1
Title.Position = UDim2.fromOffset(12, 0)
Title.Size = UDim2.new(1, -75, 1, 0)
Title.Font = Enum.Font.GothamBold
Title.Text = "KIZZYHUB"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

local Close = Instance.new("TextButton")
Close.BackgroundColor3 = Color3.fromRGB(60, 60, 78)
Close.BorderSizePixel = 0
Close.Position = UDim2.new(1, -30, 0, 4)
Close.Size = UDim2.fromOffset(24, 24)
Close.Font = Enum.Font.GothamBold
Close.Text = "×"
Close.TextColor3 = Color3.fromRGB(255, 90, 90)
Close.TextSize = 16
Close.Parent = TitleBar
round(Close, 6)

local MinButton = Instance.new("TextButton")
MinButton.BackgroundColor3 = Color3.fromRGB(60, 60, 78)
MinButton.BorderSizePixel = 0
MinButton.Position = UDim2.new(1, -58, 0, 4)
MinButton.Size = UDim2.fromOffset(24, 24)
MinButton.Font = Enum.Font.GothamBold
MinButton.Text = "-"
MinButton.TextColor3 = Color3.fromRGB(220, 220, 240)
MinButton.TextSize = 16
MinButton.Parent = TitleBar
round(MinButton, 6)

-- Tab Bar Container
local TabBar = Instance.new("Frame")
TabBar.Position = UDim2.fromOffset(10, 40)
TabBar.Size = UDim2.new(1, -20, 0, 32)
TabBar.BackgroundTransparency = 1
TabBar.Parent = Main

local function createTabButton(name, posX, sizeX)
    local btn = Instance.new("TextButton")
    btn.Position = UDim2.new(posX, 0, 0, 0)
    btn.Size = UDim2.new(sizeX, -4, 1, 0)
    btn.BackgroundColor3 = THEME.InactiveTab
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamMedium
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(180, 180, 200)
    btn.TextSize = UserInputService.TouchEnabled and 11 or 10
    btn.Parent = TabBar
    round(btn, 6)
    return btn
end

local TABW = 1/7
local TabMain = createTabButton("Main", 0*TABW, TABW)
local TabAutoFarm = createTabButton("Auto Farm", 1*TABW, TABW)
local TabPets = createTabButton("Pets", 2*TABW, TABW)
local TabESP = createTabButton("ESP", 3*TABW, TABW)
local TabTools = createTabButton("Misc", 4*TABW, TABW)
local TabSettings = createTabButton("Settings", 5*TABW, TABW)
local TabFeedback = createTabButton("Feedback", 6*TABW, TABW)

-- Content Panels Container
local ContentFrame = Instance.new("Frame")
ContentFrame.Position = UDim2.fromOffset(10, 80)
ContentFrame.Size = UDim2.new(1, -20, 1, -112)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = Main

local DiscordFooter = Instance.new("TextButton")
DiscordFooter.AnchorPoint = Vector2.new(0.5, 1)
DiscordFooter.Position = UDim2.new(0.5, 0, 1, -6)
DiscordFooter.Size = UDim2.new(1, -20, 0, 18)
DiscordFooter.BackgroundTransparency = 1
DiscordFooter.Font = Enum.Font.GothamMedium
DiscordFooter.Text = "discord.gg/zgFRf3uJDH  •  Tap to Copy"
DiscordFooter.TextColor3 = Color3.fromRGB(145, 165, 235)
DiscordFooter.TextSize = 10
DiscordFooter.Parent = Main
DiscordFooter.Activated:Connect(function()
    local invite = "https://discord.gg/zgFRf3uJDH"
    local copied = false
    if type(setclipboard) == "function" then copied = pcall(setclipboard, invite)
    elseif type(toclipboard) == "function" then copied = pcall(toclipboard, invite) end
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "KizzyHub • Discord",
            Text = copied and "Discord invite copied!" or "Clipboard is unavailable on this executor.",
            Duration = 4,
        })
    end)
end)


local function createPanel()
    local p = Instance.new("Frame")
    p.Size = UDim2.new(1, 0, 1, 0)
    p.BackgroundTransparency = 1
    p.Visible = false
    p.Parent = ContentFrame
    return p
end

local PanelEggs = createPanel()
local PanelAuto = createPanel()
local PanelMain = createPanel()
local PanelPets = createPanel()
local PanelESP = createPanel()
local PanelTools = createPanel()
local PanelSettings = createPanel()
local PanelFeedback = createPanel()

-- Hidden backing panel (no tab). Shared code still reads its widgets.
PanelEggs.Visible = false

PanelMain.Visible = true
TabMain.BackgroundColor3 = THEME.ActiveTab
TabMain.TextColor3 = Color3.new(1, 1, 1)

local function switchTab(activeTab, activePanel)
    for _, tabPair in ipairs({
        {TabMain, PanelMain},
        {TabAutoFarm, PanelAuto},
        {TabPets, PanelPets},
        {TabESP, PanelESP},
        {TabTools, PanelTools},
        {TabSettings, PanelSettings},
        {TabFeedback, PanelFeedback}
    }) do
        tabPair[1].BackgroundColor3 = THEME.InactiveTab
        tabPair[1].TextColor3 = Color3.fromRGB(180, 180, 200)
        tabPair[2].Visible = false
    end
    activeTab.BackgroundColor3 = THEME.ActiveTab
    activeTab.TextColor3 = Color3.new(1, 1, 1)
    activePanel.Visible = true
end

TabMain.MouseButton1Click:Connect(function() switchTab(TabMain, PanelMain) end)
TabAutoFarm.MouseButton1Click:Connect(function() switchTab(TabAutoFarm, PanelAuto) end)
TabPets.MouseButton1Click:Connect(function() switchTab(TabPets, PanelPets) end)
TabESP.MouseButton1Click:Connect(function() switchTab(TabESP, PanelESP) end)
TabTools.MouseButton1Click:Connect(function() switchTab(TabTools, PanelTools) end)
TabSettings.MouseButton1Click:Connect(function() switchTab(TabSettings, PanelSettings) end)
TabFeedback.MouseButton1Click:Connect(function() switchTab(TabFeedback, PanelFeedback) end)

-- Rebuild PanelAuto as the new highest-luck Auto Farm tab.
for _, child in ipairs(PanelAuto:GetChildren()) do
    child:Destroy()
end

-- Shared movement lock: visible to both Main Auto Eggs and Misc.
local VolcanoRouteActive = false
HubMisc = { Moving = false, PetJob = false } -- true while Auto Place / Auto Hatch is moving the player

--====================================================
-- MAIN TAB - Ride A Pet egg system
-- Ported from Ride A Pet_RideAPet_Mobile.lua (same logic, Egg Hub GUI)
--====================================================
do
    local POSITION_1 = Vector3.new(-4914.52100, 41295.43359, -3705.13477)
    local POSITION_3 = Vector3.new(-4968.01562, 41281.78906, -3650.59204)

    local TWEEN_SPEED = 80
    local NEXT_EGG_WAIT_TIME = 0 -- no delay before moving to the next egg
    local TOP_WAIT_TIME = 10 -- original volcano mutation wait

    local SYSTEM_ENABLED = true   -- set to false if you want it to start OFF
    local AUTO_LM = true

    local VOLCANO_RADIUS = 10
    local VOLCANO_FIRE_COOLDOWN = 1

    local RADIUS = 20
    local WAIT_BEFORE_PROXIMITY = 0 -- instant pickup
    local HOLD_DURATION = 0 -- instant pickup
    local REPEAT_COUNT = 3

    local busy = false
    local recovering = false
    local lastVolcanoFire = 0
    local pendingEggs = {}

    local PRIORITY_LIST = { "volcanic", "cherub", "solaris", "blackhole" }
    -- Map egg selector. Defaults preserve the original four special eggs.
    local SelectedMapEggs = {
        volcanic = true,
        cherub = true,
        solaris = true,
        blackhole = true,
    }
    local SPECIAL_VOLCANO_EGGS = {
        volcanic = true,
        cherub = true,
        solaris = true,
        blackhole = true,
    }

    local AUTO_FARM_ENABLED = false
    local AUTO_FARM_MIN_TEXT = ""
    local AUTO_FARM_SETTINGS_FILE = "EggHub_AutoFarm.json"

    local updateStatus, refreshPriorities, refreshEggSelectorButton -- assigned after the UI is built

    -- Everything stops when the hub is closed (Running = false).
    local function active()
        return Running and SYSTEM_ENABLED
    end

    local function notify(message)
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "AUTO EGGS",
                Text = message,
                Duration = 3,
            })
        end)
    end

    local function normalizeName(name)
        local s = tostring(name or ""):lower():gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
        return s
    end

    local function getRoot()
        local character = LocalPlayer.Character
        return character and character:FindFirstChild("HumanoidRootPart")
    end

    local function getPosition(object)
        if not object then return nil end
        if object:IsA("BasePart") then return object.Position end
        if object:IsA("Model") then
            if object.PrimaryPart then return object.PrimaryPart.Position end
            local success, pivot = pcall(function() return object:GetPivot() end)
            if success then return pivot.Position end
        end
        local part = object:FindFirstChildWhichIsA("BasePart", true)
        return part and part.Position
    end

    local function matchesKeyword(egg, keyword)
        return normalizeName(egg.Name):find(normalizeName(keyword), 1, true) ~= nil
    end

    local function teleportToPosition(position)
        local root = getRoot()
        if not root then return false end
        root.CFrame = CFrame.new(position)
        return true
    end

    local function tweenToPosition(position)
        if not active() then return false end
        local root = getRoot()
        if not root then return false end

        local distance = (root.Position - position).Magnitude
        if distance <= 1 then return true end

        local tween = TweenService:Create(
            root,
            TweenInfo.new(distance / TWEEN_SPEED, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
            { CFrame = CFrame.new(position) }
        )
        tween:Play()
        tween.Completed:Wait()

        return active() and root.Parent ~= nil
    end

    -- Fallback used when workspace.Volcano.VolcanoTop is not streamed in / not found.
    local VOLCANO_FALLBACK = POSITION_1

    local function findVolcanoTop()
        local volcano = workspace:FindFirstChild("Volcano")
        local target = volcano and (volcano:FindFirstChild("VolcanoTop", true))
        if not target then
            -- last resort: search the whole workspace once
            target = workspace:FindFirstChild("VolcanoTop", true)
        end
        return target
    end

    local function getVolcanoTopPosition()
        local target = findVolcanoTop()
        if target then
            if target:IsA("BasePart") then return target.Position end
            local ok, pivot = pcall(function() return target:GetPivot() end)
            if ok then return pivot.Position end
            local part = target:FindFirstChildWhichIsA("BasePart", true)
            if part then return part.Position end
        end
        return nil
    end

    local function teleportToVolcanoTop()
        local root = getRoot()
        if not root then return false end

        local pos = getVolcanoTopPosition()

        if not pos then
            -- Volcano is far away and StreamingEnabled hasn't loaded it yet:
            -- hop to the known volcano area, request streaming, and wait for it.
            pcall(function() LocalPlayer:RequestStreamAroundAsync(VOLCANO_FALLBACK, 3) end)
            root.CFrame = CFrame.new(VOLCANO_FALLBACK)
            local t0 = tick()
            while not pos and tick() - t0 < 3 do
                task.wait(0.1)
                pos = getVolcanoTopPosition()
            end
        end

        pos = pos or VOLCANO_FALLBACK
        root = getRoot()
        if not root then return false end
        root.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
        return true
    end

    local function teleportToOwnPlot()
        local plots = workspace:FindFirstChild("Plots")
        if not plots then return false end

        for _, plot in ipairs(plots:GetChildren()) do
            local data = plot:FindFirstChild("Data")
            local owner = data and data:FindFirstChild("Owner")

            if owner then
                local isMine = false
                if owner:IsA("ObjectValue") then
                    isMine = owner.Value == LocalPlayer
                elseif owner:IsA("StringValue") then
                    isMine = owner.Value == LocalPlayer.Name or owner.Value == LocalPlayer.DisplayName
                elseif owner:IsA("IntValue") or owner:IsA("NumberValue") then
                    isMine = owner.Value == LocalPlayer.UserId
                end

                if isMine then
                    local root = getRoot()
                    if root then
                        root.CFrame = plot:GetPivot() + Vector3.new(0, 5, 0)
                        return true
                    end
                end
            end
        end
        return false
    end

    local function returnToBaseAndConfirm()
        if not teleportToOwnPlot() then
            return false
        end

        -- Give Roblox/Delta a moment to apply the plot teleport before another
        -- priority egg is allowed to move the character again.
        task.wait(0.25)

        local plots = workspace:FindFirstChild("Plots")
        local root = getRoot()
        if not plots or not root then
            task.wait(0.75)
            return true
        end

        local myPlot
        for _, plot in ipairs(plots:GetChildren()) do
            local data = plot:FindFirstChild("Data")
            local owner = data and data:FindFirstChild("Owner")
            if owner then
                local mine = false
                if owner:IsA("ObjectValue") then
                    mine = owner.Value == LocalPlayer
                elseif owner:IsA("StringValue") then
                    mine = owner.Value == LocalPlayer.Name or owner.Value == LocalPlayer.DisplayName
                elseif owner:IsA("IntValue") or owner:IsA("NumberValue") then
                    mine = owner.Value == LocalPlayer.UserId
                end
                if mine then
                    myPlot = plot
                    break
                end
            end
        end

        if myPlot then
            local target = myPlot:GetPivot().Position + Vector3.new(0, 5, 0)
            local deadline = os.clock() + 2
            repeat
                root = getRoot()
                if not root then break end
                if (root.Position - target).Magnitude <= 20 then break end
                root.CFrame = CFrame.new(target)
                task.wait(0.1)
            until os.clock() >= deadline
        end

        -- Important: keep the farm lock for a moment while visibly at base.
        -- The next egg can start immediately after this; there is no 15s next-egg wait.
        task.wait(0.75)
        return true
    end

    local function readEggStat(egg, wanted)
        wanted = tostring(wanted):lower()
        if wanted == "luck" then
            local ok, luck = pcall(getEggLuck, egg)
            if ok and luck and tostring(luck) ~= "" and tostring(luck) ~= "?" then
                return tostring(luck)
            end
        end
        for _, attrName in ipairs({"Luck", "Tier", "Multiplier", "Value", "Weight", "Mass", "Kg"}) do
            if attrName:lower() == wanted
                or (wanted == "luck" and (attrName == "Tier" or attrName == "Multiplier" or attrName == "Value"))
                or (wanted == "weight" and (attrName == "Mass" or attrName == "Kg")) then
                local value = egg:GetAttribute(attrName)
                if value ~= nil then return tostring(value) end
            end
        end
        for _, child in ipairs(egg:GetDescendants()) do
            if child:IsA("ValueBase") then
                local n = child.Name:lower()
                if (wanted == "luck" and (n:find("luck",1,true) or n:find("tier",1,true) or n:find("mult",1,true)))
                    or (wanted == "weight" and (n:find("weight",1,true) or n:find("mass",1,true) or n == "kg")) then
                    return tostring(child.Value)
                end
            elseif child:IsA("TextLabel") then
                local n = child.Name:lower()
                local text = tostring(child.Text or "")
                if wanted == "luck" and (n:find("luck",1,true) or text:lower():find("luck",1,true)) then
                    return text:gsub("[Ll][Uu][Cc][Kk]%s*[:%-]?%s*", "")
                elseif wanted == "weight" and (n:find("weight",1,true) or text:lower():find("kg",1,true)) then
                    local w = text:match("([%d%.,]+%s*[Kk][Gg])")
                    if w then return w end
                end
            end
        end
        return wanted == "luck" and "?" or "?"
    end

    local function eggSelectionKey(egg)
        return normalizeName(egg and egg.Name or "")
    end

    local function isMapEggSelected(egg)
        local key = eggSelectionKey(egg)
        if SelectedMapEggs[key] then return true end
        -- Preserve keyword matching for the original four special eggs.
        for special in pairs(SPECIAL_VOLCANO_EGGS) do
            if SelectedMapEggs[special] and key:find(special, 1, true) then return true end
        end
        return false
    end

    local function specialVolcanoKind(egg)
        local key = eggSelectionKey(egg)
        for special in pairs(SPECIAL_VOLCANO_EGGS) do
            if key:find(special, 1, true) then return special end
        end
        return nil
    end

    local function findPriorityEgg()
        -- Original four keep their priority order when selected.
        for _, priority in ipairs(PRIORITY_LIST) do
            if SelectedMapEggs[normalizeName(priority)] then
                for _, egg in ipairs(Folder:GetChildren()) do
                    if matchesKeyword(egg, priority) then
                        return egg, specialVolcanoKind(egg)
                    end
                end
            end
        end

        -- Then process any other map egg the user selected.
        for _, egg in ipairs(Folder:GetChildren()) do
            if isMapEggSelected(egg) then
                return egg, specialVolcanoKind(egg)
            end
        end
        return nil, nil
    end

    local function findHighestLuckEgg(minimum)
        local bestEgg, bestLuck = nil, -math.huge
        for _, egg in ipairs(Folder:GetChildren()) do
            if egg and egg.Parent then
                local luck = parseLuck(getEggLuck(egg))
                if luck >= minimum and luck > bestLuck then
                    bestEgg = egg
                    bestLuck = luck
                end
            end
        end
        return bestEgg, bestLuck
    end

    local function logMainFarmClaim(eggName, luckStr, startedAt)
        if MainFarmWebhookClaim then
            task.spawn(MainFarmWebhookClaim, eggName, luckStr, {
                Elapsed = os.clock() - startedAt,
                Confirmed = eggName,
                Source = "Main"
            })
        end
    end


        local function waitForEggToDisappear(egg)
    	while SYSTEM_ENABLED and egg and egg.Parent do
    		task.wait(0.5)
    	end

    	return egg and not egg.Parent
    end

    local function processVolcanic(egg)
    	if not egg or not egg.Parent then
    		return
    	end

    	-- 1. P1 → P3
    	teleportToPosition(POSITION_1)
    	task.wait(0.2)

    	if not tweenToPosition(POSITION_3) then
    		return
    	end

    	task.wait(0.2)

    	-- 2. Go to volcanic egg
    	if not egg.Parent then
    		returnToBaseAndConfirm()
    		return
    	end

    	local position = getPosition(egg)

    	if not position then
    		returnToBaseAndConfirm()
    		return
    	end

    	teleportToPosition(position)

    	notify("At volcanic egg - waiting for disappearance")

    	-- 3. Wait until egg disappears
    	local disappeared = waitForEggToDisappear(egg)

    	if not SYSTEM_ENABLED then
    		return
    	end

    	if not disappeared then
    		returnToBaseAndConfirm()
    		return
    	end

    	notify("Volcanic egg disappeared")

    	-- 4. Egg disappeared → P3
    	teleportToPosition(POSITION_3)
    	task.wait(0.2)

    	-- 5. P3 → P1
    	if not tweenToPosition(POSITION_1) then
    		return
    	end

    	task.wait(0.2)

    	-- 6. P1 → VolcanoTop
    	if not teleportToVolcanoTop() then
    		returnToBaseAndConfirm()
    		return
    	end

    	notify("At VolcanoTop - dip")

    	
    	-- 8. After dip finishes → wait 15 seconds
    	task.wait(TOP_WAIT_TIME)

    	-- 9. Return to own plot
    	returnToBaseAndConfirm()
    end

    local function processNormal(egg, useVolcano)
    	if not egg or not egg.Parent then
    		return
    	end

    	local position = getPosition(egg)

    	if not position then
    		returnToBaseAndConfirm()
    		return
    	end

    	teleportToPosition(position)

    	notify("At egg - waiting for disappearance")

    	local disappeared = waitForEggToDisappear(egg)

    	if not SYSTEM_ENABLED then
    		return
    	end

    	if not disappeared then
    		returnToBaseAndConfirm()
    		return
    	end

    	if AUTO_LM and useVolcano then
    		notify("Egg disappeared - going VolcanoTop")

    		if teleportToVolcanoTop() then
    			task.wait(TOP_WAIT_TIME)
    		end
    	end

    	returnToBaseAndConfirm()
    end

    local function addPriority(keyword)
        keyword = normalizeName(keyword)
        if keyword == "" then return end

        for index, existing in ipairs(PRIORITY_LIST) do
            if normalizeName(existing) == keyword then
                table.remove(PRIORITY_LIST, index)
                break
            end
        end

        table.insert(PRIORITY_LIST, 1, keyword)
        notify("Priority added: " .. keyword)
    end

    local function removePriority(keyword)
        keyword = normalizeName(keyword)
        for index, existing in ipairs(PRIORITY_LIST) do
            if normalizeName(existing) == keyword then
                table.remove(PRIORITY_LIST, index)
                notify("Priority removed: " .. keyword)
                return
            end
        end
    end

    local function saveAutoFarmSettings()
        if type(writefile) ~= "function" then return end
        pcall(function()
            writefile(AUTO_FARM_SETTINGS_FILE, HttpService:JSONEncode({
                Enabled = AUTO_FARM_ENABLED == true,
                Minimum = tostring(AUTO_FARM_MIN_TEXT or ""),
            }))
        end)
    end

    local function loadAutoFarmSettings()
        -- First run intentionally stays OFF with a blank minimum.
        if type(isfile) ~= "function" or type(readfile) ~= "function" or not isfile(AUTO_FARM_SETTINGS_FILE) then
            return
        end
        local ok, data = pcall(function()
            return HttpService:JSONDecode(readfile(AUTO_FARM_SETTINGS_FILE))
        end)
        if ok and type(data) == "table" then
            AUTO_FARM_ENABLED = data.Enabled == true
            AUTO_FARM_MIN_TEXT = type(data.Minimum) == "string" and data.Minimum or ""
        end
    end

    loadAutoFarmSettings()

    ------------------------------------------------------------------
    -- AUTO FARM TAB - highest luck at/above minimum
    ------------------------------------------------------------------
    local AutoFarmScroll = Instance.new("ScrollingFrame")
    AutoFarmScroll.Size = UDim2.fromScale(1,1)
    AutoFarmScroll.BackgroundTransparency = 1
    AutoFarmScroll.BorderSizePixel = 0
    AutoFarmScroll.ScrollBarThickness = 4
    AutoFarmScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    AutoFarmScroll.CanvasSize = UDim2.new()
    AutoFarmScroll.Parent = PanelAuto

    local AFLayout = Instance.new("UIListLayout")
    AFLayout.Padding = UDim.new(0,8)
    AFLayout.SortOrder = Enum.SortOrder.LayoutOrder
    AFLayout.Parent = AutoFarmScroll

    local function afCard(height)
        local f=Instance.new("Frame")
        f.Size=UDim2.new(1,-8,0,height)
        f.BackgroundColor3=THEME.Panel
        f.BorderSizePixel=0
        f.Parent=AutoFarmScroll
        round(f,9)
        return f
    end

    local AFHeader=afCard(68)
    local AFAccent=Instance.new("Frame")
    AFAccent.Size=UDim2.new(0,4,1,-14)
    AFAccent.Position=UDim2.fromOffset(0,7)
    AFAccent.BorderSizePixel=0
    AFAccent.BackgroundColor3=Color3.fromRGB(190,75,75)
    AFAccent.Parent=AFHeader
    round(AFAccent,4)

    local AFTitle=Instance.new("TextLabel")
    AFTitle.Position=UDim2.fromOffset(14,8)
    AFTitle.Size=UDim2.new(1,-28,0,22)
    AFTitle.BackgroundTransparency=1
    AFTitle.Font=Enum.Font.GothamBold
    AFTitle.Text="AUTO FARM  •  OFF"
    AFTitle.TextColor3=Color3.fromRGB(255,135,135)
    AFTitle.TextSize=14
    AFTitle.TextXAlignment=Enum.TextXAlignment.Left
    AFTitle.Parent=AFHeader

    local AFSub=Instance.new("TextLabel")
    AFSub.Position=UDim2.fromOffset(14,31)
    AFSub.Size=UDim2.new(1,-28,0,28)
    AFSub.BackgroundTransparency=1
    AFSub.Font=Enum.Font.GothamMedium
    AFSub.Text="Claims the highest-luck egg at your minimum or higher."
    AFSub.TextColor3=Color3.fromRGB(160,165,190)
    AFSub.TextSize=10
    AFSub.TextWrapped=true
    AFSub.TextXAlignment=Enum.TextXAlignment.Left
    AFSub.Parent=AFHeader

    local AFMinCard=afCard(76)
    local AFMinLabel=Instance.new("TextLabel")
    AFMinLabel.Position=UDim2.fromOffset(10,7)
    AFMinLabel.Size=UDim2.new(1,-20,0,18)
    AFMinLabel.BackgroundTransparency=1
    AFMinLabel.Font=Enum.Font.GothamBold
    AFMinLabel.Text="MINIMUM LUCK"
    AFMinLabel.TextColor3=Color3.fromRGB(150,185,255)
    AFMinLabel.TextSize=10
    AFMinLabel.TextXAlignment=Enum.TextXAlignment.Left
    AFMinLabel.Parent=AFMinCard

    local AFMinBox=Instance.new("TextBox")
    AFMinBox.Position=UDim2.fromOffset(9,31)
    AFMinBox.Size=UDim2.new(1,-18,0,35)
    AFMinBox.BackgroundColor3=Color3.fromRGB(22,24,34)
    AFMinBox.BorderSizePixel=0
    AFMinBox.ClearTextOnFocus=false
    AFMinBox.Text=AUTO_FARM_MIN_TEXT
    AFMinBox.PlaceholderText="Example: 100B, 500B, 1T"
    AFMinBox.PlaceholderColor3=Color3.fromRGB(105,110,135)
    AFMinBox.TextColor3=Color3.fromRGB(235,237,248)
    AFMinBox.Font=Enum.Font.GothamBold
    AFMinBox.TextSize=12
    AFMinBox.Parent=AFMinCard
    round(AFMinBox,7)

    local AFStatus=afCard(55)
    local AFStatusText=Instance.new("TextLabel")
    AFStatusText.Position=UDim2.fromOffset(10,5)
    AFStatusText.Size=UDim2.new(1,-20,1,-10)
    AFStatusText.BackgroundTransparency=1
    AFStatusText.Font=Enum.Font.GothamMedium
    AFStatusText.Text="Waiting..."
    AFStatusText.TextColor3=Color3.fromRGB(175,180,200)
    AFStatusText.TextSize=10
    AFStatusText.TextWrapped=true
    AFStatusText.TextXAlignment=Enum.TextXAlignment.Left
    AFStatusText.Parent=AFStatus

    local AFToggle=Instance.new("TextButton")
    AFToggle.Size=UDim2.new(1,-8,0,38)
    AFToggle.BackgroundColor3=THEME.Button
    AFToggle.BorderSizePixel=0
    AFToggle.Font=Enum.Font.GothamBold
    AFToggle.Text="Auto Farm"
    AFToggle.TextColor3=Color3.fromRGB(235,235,245)
    AFToggle.TextSize=12
    AFToggle.TextXAlignment=Enum.TextXAlignment.Left
    AFToggle.TextYAlignment=Enum.TextYAlignment.Center
    AFToggle.Parent=AutoFarmScroll
    round(AFToggle,8)

    local AFTogglePadding=Instance.new("UIPadding")
    AFTogglePadding.PaddingLeft=UDim.new(0,12)
    AFTogglePadding.PaddingRight=UDim.new(0,10)
    AFTogglePadding.Parent=AFToggle

    local AFSwitch=Instance.new("Frame")
    AFSwitch.AnchorPoint=Vector2.new(1,0.5)
    AFSwitch.Position=UDim2.new(1,0,0.5,0)
    AFSwitch.Size=UDim2.fromOffset(42,22)
    AFSwitch.BackgroundColor3=Color3.fromRGB(72,74,88)
    AFSwitch.BorderSizePixel=0
    AFSwitch.Parent=AFToggle
    round(AFSwitch,11)

    local AFKnob=Instance.new("Frame")
    AFKnob.Size=UDim2.fromOffset(18,18)
    AFKnob.Position=UDim2.fromOffset(2,2)
    AFKnob.BackgroundColor3=Color3.fromRGB(225,225,235)
    AFKnob.BorderSizePixel=0
    AFKnob.Parent=AFSwitch
    round(AFKnob,9)

    local function updateAutoFarmVisual()
        if AUTO_FARM_ENABLED then
            AFTitle.Text="AUTO FARM  •  RUNNING"
            AFTitle.TextColor3=Color3.fromRGB(120,255,145)
            AFAccent.BackgroundColor3=Color3.fromRGB(65,190,105)
            AFToggle.Text="Auto Farm"
            AFToggle.BackgroundColor3=THEME.Button
            AFSwitch.BackgroundColor3=Color3.fromRGB(65,190,105)
            AFKnob.Position=UDim2.fromOffset(22,2)
        else
            AFTitle.Text="AUTO FARM  •  OFF"
            AFTitle.TextColor3=Color3.fromRGB(255,135,135)
            AFAccent.BackgroundColor3=Color3.fromRGB(190,75,75)
            AFToggle.Text="Auto Farm"
            AFToggle.BackgroundColor3=THEME.Button
            AFSwitch.BackgroundColor3=Color3.fromRGB(72,74,88)
            AFKnob.Position=UDim2.fromOffset(2,2)
        end
    end

    AFMinBox.FocusLost:Connect(function()
        local txt=tostring(AFMinBox.Text or ""):gsub("^%s+",""):gsub("%s+$","")
        AUTO_FARM_MIN_TEXT=txt
        AFMinBox.Text=txt
        saveAutoFarmSettings()
    end)

    AFToggle.Activated:Connect(function()
        AUTO_FARM_ENABLED=not AUTO_FARM_ENABLED
        if AUTO_FARM_ENABLED then
            SYSTEM_ENABLED=true
            recovering=false
        end
        updateAutoFarmVisual()
        saveAutoFarmSettings()
        if updateStatus then updateStatus() end
    end)

    updateAutoFarmVisual()
    if AUTO_FARM_ENABLED then
        SYSTEM_ENABLED = true
        recovering = false
    end

    ------------------------------------------------------------------
    -- UI (Main tab, Egg Hub style)
    ------------------------------------------------------------------
    local MainScroll = Instance.new("ScrollingFrame")
    MainScroll.Size = UDim2.fromScale(1, 1)
    MainScroll.BackgroundTransparency = 1
    MainScroll.BorderSizePixel = 0
    MainScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    MainScroll.CanvasSize = UDim2.new()
    MainScroll.ScrollBarThickness = 4
    MainScroll.Parent = PanelMain

    local MainLayout = Instance.new("UIListLayout")
    MainLayout.Padding = UDim.new(0, 6)
    MainLayout.SortOrder = Enum.SortOrder.LayoutOrder
    MainLayout.Parent = MainScroll

    local mainOrder = 0
    local function nextMainOrder()
        mainOrder += 1
        return mainOrder
    end

    local function mainLabel(text, height)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, -8, 0, height or 30)
        l.BackgroundColor3 = THEME.Panel
        l.BorderSizePixel = 0
        l.Font = Enum.Font.GothamMedium
        l.Text = text
        l.TextColor3 = Color3.fromRGB(220, 220, 235)
        l.TextSize = 11
        l.TextWrapped = true
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.TextYAlignment = Enum.TextYAlignment.Top
        l.LayoutOrder = nextMainOrder()
        l.Parent = MainScroll
        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, 8)
        pad.PaddingTop = UDim.new(0, 4)
        pad.Parent = l
        round(l, 6)
        return l
    end

    local function mainButton(text)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, -8, 0, 34)
        b.BackgroundColor3 = THEME.Button
        b.BorderSizePixel = 0
        b.Font = Enum.Font.GothamBold
        b.Text = text
        b.TextColor3 = Color3.new(1, 1, 1)
        b.TextSize = UserInputService.TouchEnabled and 12 or 11
        b.LayoutOrder = nextMainOrder()
        b.Parent = MainScroll
        round(b, 7)
        return b
    end

    -- Cleaner Main dashboard card
    local StatusCard = Instance.new("Frame")
    StatusCard.Size = UDim2.new(1, -8, 0, 62)
    StatusCard.BackgroundColor3 = THEME.Panel
    StatusCard.BorderSizePixel = 0
    StatusCard.LayoutOrder = nextMainOrder()
    StatusCard.Parent = MainScroll
    round(StatusCard, 9)

    local StatusAccent = Instance.new("Frame")
    StatusAccent.Size = UDim2.new(0, 4, 1, -14)
    StatusAccent.Position = UDim2.fromOffset(7, 7)
    StatusAccent.BorderSizePixel = 0
    StatusAccent.BackgroundColor3 = THEME.Accent
    StatusAccent.Parent = StatusCard
    round(StatusAccent, 2)

    local StatusTitle = Instance.new("TextLabel")
    StatusTitle.BackgroundTransparency = 1
    StatusTitle.Position = UDim2.fromOffset(20, 7)
    StatusTitle.Size = UDim2.new(1, -28, 0, 20)
    StatusTitle.Font = Enum.Font.GothamBold
    StatusTitle.Text = "AUTO EGGS"
    StatusTitle.TextColor3 = Color3.fromRGB(240, 240, 250)
    StatusTitle.TextSize = 13
    StatusTitle.TextXAlignment = Enum.TextXAlignment.Left
    StatusTitle.Parent = StatusCard

    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Position = UDim2.fromOffset(20, 28)
    StatusLabel.Size = UDim2.new(1, -28, 0, 25)
    StatusLabel.Font = Enum.Font.GothamMedium
    StatusLabel.Text = ""
    StatusLabel.TextColor3 = Color3.fromRGB(190, 195, 210)
    StatusLabel.TextSize = 10
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.Parent = StatusCard

    local function sectionTitle(text)
        local l = mainLabel(text, 22)
        l.BackgroundTransparency = 1
        l.Font = Enum.Font.GothamBold
        l.TextColor3 = Color3.fromRGB(150, 185, 255)
        l.TextSize = 10
        l.TextYAlignment = Enum.TextYAlignment.Center
        return l
    end

    local function mainToggle(label, initial)
        local b = mainButton("")
        b.Size = UDim2.new(1, -8, 0, 38)
        b.Text = ""

        local labelText = Instance.new("TextLabel")
        labelText.BackgroundTransparency = 1
        labelText.Position = UDim2.fromOffset(11, 0)
        labelText.Size = UDim2.new(1, -78, 1, 0)
        labelText.Font = Enum.Font.GothamBold
        labelText.Text = label
        labelText.TextColor3 = Color3.fromRGB(235, 235, 245)
        labelText.TextSize = UserInputService.TouchEnabled and 12 or 11
        labelText.TextXAlignment = Enum.TextXAlignment.Left
        labelText.Parent = b

        local track = Instance.new("Frame")
        track.AnchorPoint = Vector2.new(1, 0.5)
        track.Position = UDim2.new(1, -9, 0.5, 0)
        track.Size = UDim2.fromOffset(48, 24)
        track.BorderSizePixel = 0
        track.Parent = b
        round(track, 12)

        local knob = Instance.new("Frame")
        knob.AnchorPoint = Vector2.new(0.5, 0.5)
        knob.Size = UDim2.fromOffset(18, 18)
        knob.BorderSizePixel = 0
        knob.BackgroundColor3 = Color3.fromRGB(245, 245, 250)
        knob.Parent = track
        round(knob, 9)

        local first = true
        local function draw(on, instant)
            local trackColor = on and Color3.fromRGB(65, 190, 105) or Color3.fromRGB(75, 75, 90)
            local knobPos = on and UDim2.new(1, -12, 0.5, 0) or UDim2.new(0, 12, 0.5, 0)
            if first or instant then
                track.BackgroundColor3 = trackColor
                knob.Position = knobPos
                first = false
            else
                TweenService:Create(track, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = trackColor}):Play()
                TweenService:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = knobPos}):Play()
            end
        end
        draw(initial, true)
        return b, draw
    end

    sectionTitle("AUTOMATION")
    local SystemBtn, drawSystemToggle = mainToggle("Auto Eggs", SYSTEM_ENABLED)
    local LavaBtn, drawLavaToggle = mainToggle("Auto Lava Mutation", AUTO_LM)

    sectionTitle("QUICK TELEPORTS")
    local TeleportRow = Instance.new("Frame")
    TeleportRow.Size = UDim2.new(1, -8, 0, 38)
    TeleportRow.BackgroundTransparency = 1
    TeleportRow.LayoutOrder = nextMainOrder()
    TeleportRow.Parent = MainScroll

    local function halfButton(text, x)
        local b = Instance.new("TextButton")
        b.Position = UDim2.new(x, x == 0 and 0 or 3, 0, 0)
        b.Size = UDim2.new(0.5, -3, 1, 0)
        b.BackgroundColor3 = THEME.Button
        b.BorderSizePixel = 0
        b.Font = Enum.Font.GothamBold
        b.Text = text
        b.TextColor3 = Color3.fromRGB(235, 235, 245)
        b.TextSize = UserInputService.TouchEnabled and 11 or 10
        b.Parent = TeleportRow
        round(b, 7)
        return b
    end

    local PlotBtn = halfButton("My Base", 0)
    local TopBtn = halfButton("Volcano Top", 0.5)

    sectionTitle("EGG PRIORITY")

    local PriorityBox = Instance.new("TextBox")
    PriorityBox.Size = UDim2.new(1, -8, 0, 36)
    PriorityBox.BackgroundColor3 = THEME.Panel
    PriorityBox.BorderSizePixel = 0
    PriorityBox.Font = Enum.Font.GothamMedium
    PriorityBox.PlaceholderText = "Enter egg name..."
    PriorityBox.PlaceholderColor3 = Color3.fromRGB(130, 130, 150)
    PriorityBox.Text = ""
    PriorityBox.TextColor3 = Color3.new(1, 1, 1)
    PriorityBox.TextSize = 11
    PriorityBox.ClearTextOnFocus = false
    PriorityBox.LayoutOrder = nextMainOrder()
    PriorityBox.Parent = MainScroll
    round(PriorityBox, 7)
    local inputPad = Instance.new("UIPadding")
    inputPad.PaddingLeft = UDim.new(0, 10)
    inputPad.PaddingRight = UDim.new(0, 10)
    inputPad.Parent = PriorityBox

    local PriorityActions = Instance.new("Frame")
    PriorityActions.Size = UDim2.new(1, -8, 0, 34)
    PriorityActions.BackgroundTransparency = 1
    PriorityActions.LayoutOrder = nextMainOrder()
    PriorityActions.Parent = MainScroll

    local function priorityAction(text, x)
        local b = Instance.new("TextButton")
        b.Position = UDim2.new(x, x == 0 and 0 or 3, 0, 0)
        b.Size = UDim2.new(0.5, -3, 1, 0)
        b.BackgroundColor3 = THEME.Button
        b.BorderSizePixel = 0
        b.Font = Enum.Font.GothamBold
        b.Text = text
        b.TextColor3 = Color3.fromRGB(235, 235, 245)
        b.TextSize = 10
        b.Parent = PriorityActions
        round(b, 7)
        return b
    end

    local AddBtn = priorityAction("Add / Move Up", 0)
    local RemoveBtn = priorityAction("Remove", 0.5)

    local PriorityLabel = mainLabel("", 54)
    PriorityLabel.BackgroundColor3 = THEME.Panel
    PriorityLabel.Font = Enum.Font.GothamMedium
    PriorityLabel.TextSize = 10

    sectionTitle("MAP EGG SELECTOR")

    local EggSelectorBtn = mainButton("Choose Map Eggs")
    EggSelectorBtn.Visible = false
    EggSelectorBtn.Size = UDim2.new(1, -8, 0, 0)

    local SelectorOverlay = Instance.new("Frame")
    SelectorOverlay.Size = UDim2.new(1, -8, 0, 280)
    SelectorOverlay.BackgroundColor3 = Color3.fromRGB(18, 19, 27)
    SelectorOverlay.BorderSizePixel = 0
    SelectorOverlay.Visible = true
    SelectorOverlay.ZIndex = 10
    SelectorOverlay.LayoutOrder = nextMainOrder()
    SelectorOverlay.Parent = MainScroll
    round(SelectorOverlay, 10)

    local SelectorTitle = Instance.new("TextLabel")
    SelectorTitle.Position = UDim2.fromOffset(12, 8)
    SelectorTitle.Size = UDim2.new(1, -24, 0, 22)
    SelectorTitle.BackgroundTransparency = 1
    SelectorTitle.Font = Enum.Font.GothamBold
    SelectorTitle.Text = "MAP EGGS"
    SelectorTitle.TextColor3 = Color3.fromRGB(240, 242, 255)
    SelectorTitle.TextSize = 13
    SelectorTitle.TextXAlignment = Enum.TextXAlignment.Left
    SelectorTitle.ZIndex = 12
    SelectorTitle.Parent = SelectorOverlay

    local SelectorSearch = Instance.new("TextBox")
    SelectorSearch.Position = UDim2.fromOffset(10, 36)
    SelectorSearch.Size = UDim2.new(1, -20, 0, 30)
    SelectorSearch.BackgroundColor3 = THEME.Panel
    SelectorSearch.BorderSizePixel = 0
    SelectorSearch.Font = Enum.Font.GothamMedium
    SelectorSearch.PlaceholderText = "Search eggs..."
    SelectorSearch.PlaceholderColor3 = Color3.fromRGB(105,110,130)
    SelectorSearch.Text = ""
    SelectorSearch.TextColor3 = Color3.fromRGB(235,235,245)
    SelectorSearch.TextSize = 10
    SelectorSearch.TextXAlignment = Enum.TextXAlignment.Left
    SelectorSearch.ClearTextOnFocus = false
    SelectorSearch.ZIndex = 12
    SelectorSearch.Parent = SelectorOverlay
    round(SelectorSearch, 7)
    local searchPad = Instance.new("UIPadding")
    searchPad.PaddingLeft = UDim.new(0,9)
    searchPad.PaddingRight = UDim.new(0,9)
    searchPad.Parent = SelectorSearch

    local SelectorScroll = Instance.new("ScrollingFrame")
    SelectorScroll.Position = UDim2.fromOffset(10, 72)
    SelectorScroll.Size = UDim2.new(1, -20, 1, -116)
    SelectorScroll.BackgroundTransparency = 1
    SelectorScroll.BorderSizePixel = 0
    SelectorScroll.ScrollBarThickness = 3
    SelectorScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    SelectorScroll.CanvasSize = UDim2.new()
    SelectorScroll.ZIndex = 12
    SelectorScroll.Parent = SelectorOverlay
    local selectorLayout = Instance.new("UIListLayout")
    selectorLayout.Padding = UDim.new(0,5)
    selectorLayout.SortOrder = Enum.SortOrder.LayoutOrder
    selectorLayout.Parent = SelectorScroll

    local SelectorFooter = Instance.new("Frame")
    SelectorFooter.Position = UDim2.new(0,10,1,-38)
    SelectorFooter.Size = UDim2.new(1,-20,0,30)
    SelectorFooter.BackgroundTransparency = 1
    SelectorFooter.ZIndex = 12
    SelectorFooter.Parent = SelectorOverlay

    local function footerButton(text, x, width)
        local b = Instance.new("TextButton")
        b.Position = UDim2.new(x,0,0,0)
        b.Size = UDim2.new(width,-4,1,0)
        b.BackgroundColor3 = THEME.Button
        b.BorderSizePixel = 0
        b.Font = Enum.Font.GothamBold
        b.Text = text
        b.TextColor3 = Color3.fromRGB(235,235,245)
        b.TextSize = 9
        b.ZIndex = 13
        b.Parent = SelectorFooter
        round(b,6)
        return b
    end
    local SelectAllBtn = footerButton("All",0,0.22)
    local SelectNoneBtn = footerButton("None",0.22,0.22)
    local SpecialOnlyBtn = footerButton("4 Special",0.44,0.56)

    local function countSelectedMapEggs()
        local n = 0
        for _ in pairs(SelectedMapEggs) do n += 1 end
        return n
    end

    refreshEggSelectorButton = function()
        SelectorTitle.Text = "MAP EGGS  •  " .. tostring(countSelectedMapEggs()) .. " SELECTED"
    end

    local refreshMapEggRows
    refreshMapEggRows = function()
        for _, child in ipairs(SelectorScroll:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end

        local query = normalizeName(SelectorSearch.Text)
        local rows, seen = {}, {}
        for _, egg in ipairs(Folder:GetChildren()) do
            local key = eggSelectionKey(egg)
            if key ~= "" and not seen[key] and (query == "" or key:find(query,1,true)) then
                seen[key] = true
                table.insert(rows, {
                    Key = key,
                    Name = egg.Name,
                    Luck = readEggStat(egg,"luck"),
                    Weight = readEggStat(egg,"weight"),
                    Special = specialVolcanoKind(egg) ~= nil,
                })
            end
        end
        table.sort(rows,function(a,b)
            local aLuck = parseLuck(a.Luck)
            local bLuck = parseLuck(b.Luck)
            if aLuck ~= bLuck then return aLuck > bLuck end
            return a.Name:lower() < b.Name:lower()
        end)

        for _, info in ipairs(rows) do
            local row = Instance.new("TextButton")
            row.Size = UDim2.new(1,-4,0,42)
            row.BackgroundColor3 = THEME.Panel
            row.BorderSizePixel = 0
            row.Text = ""
            row.ZIndex = 13
            row.Parent = SelectorScroll
            round(row,7)

            local label = Instance.new("TextLabel")
            label.Position = UDim2.fromOffset(9,4)
            label.Size = UDim2.new(1,-64,1,-8)
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.GothamMedium
            label.Text = info.Name .. (info.Special and "  •  VOLCANO" or "") .. "\\n🍀 " .. info.Luck .. "     ⚖ " .. info.Weight
            label.TextColor3 = Color3.fromRGB(225,228,242)
            label.TextSize = 9
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.TextYAlignment = Enum.TextYAlignment.Center
            label.ZIndex = 14
            label.Parent = row

            local track = Instance.new("Frame")
            track.AnchorPoint = Vector2.new(1,0.5)
            track.Position = UDim2.new(1,-8,0.5,0)
            track.Size = UDim2.fromOffset(42,22)
            track.BorderSizePixel = 0
            track.ZIndex = 14
            track.Parent = row
            round(track,11)

            local knob = Instance.new("Frame")
            knob.AnchorPoint = Vector2.new(0.5,0.5)
            knob.Size = UDim2.fromOffset(16,16)
            knob.BackgroundColor3 = Color3.fromRGB(245,245,250)
            knob.BorderSizePixel = 0
            knob.ZIndex = 15
            knob.Parent = track
            round(knob,8)

            local function draw()
                local on = SelectedMapEggs[info.Key] == true
                track.BackgroundColor3 = on and THEME.Accent or Color3.fromRGB(58,61,76)
                knob.Position = on and UDim2.new(1,-11,0.5,0) or UDim2.new(0,11,0.5,0)
            end
            draw()

            local locked = false
            row.Activated:Connect(function()
                if locked then return end
                locked = true
                if SelectedMapEggs[info.Key] then SelectedMapEggs[info.Key] = nil else SelectedMapEggs[info.Key] = true end
                draw()
                refreshEggSelectorButton()
                task.delay(0.18,function() locked=false end)
            end)
        end
    end

    SelectorSearch:GetPropertyChangedSignal("Text"):Connect(function()
        refreshMapEggRows()
    end)
    SelectAllBtn.Activated:Connect(function()
        for _, egg in ipairs(Folder:GetChildren()) do SelectedMapEggs[eggSelectionKey(egg)] = true end
        refreshMapEggRows(); refreshEggSelectorButton()
    end)
    SelectNoneBtn.Activated:Connect(function()
        table.clear(SelectedMapEggs)
        refreshMapEggRows(); refreshEggSelectorButton()
    end)
    SpecialOnlyBtn.Activated:Connect(function()
        table.clear(SelectedMapEggs)
        for key in pairs(SPECIAL_VOLCANO_EGGS) do SelectedMapEggs[key] = true end
        refreshMapEggRows(); refreshEggSelectorButton()
    end)
    task.spawn(function()
        while Running and ScreenGui.Parent do
            task.wait(1)
            refreshMapEggRows()
        end
    end)
    refreshEggSelectorButton()
    refreshMapEggRows()

    local CommandsLabel = mainLabel("Commands:  *on   *off   *auto lm   *off auto lm   *addp [egg]   *remp [egg]", 34)
    CommandsLabel.TextColor3 = Color3.fromRGB(145, 150, 170)
    CommandsLabel.TextSize = 9

    updateStatus = function()
        StatusTitle.Text = SYSTEM_ENABLED and "AUTO EGGS  •  RUNNING" or "AUTO EGGS  •  PAUSED"
        StatusTitle.TextColor3 = SYSTEM_ENABLED and Color3.fromRGB(120, 255, 145) or Color3.fromRGB(255, 135, 135)
        StatusAccent.BackgroundColor3 = SYSTEM_ENABLED and Color3.fromRGB(65, 190, 105) or Color3.fromRGB(190, 75, 75)
        StatusLabel.Text = "Egg Farm: " .. (SYSTEM_ENABLED and "ON" or "OFF") .. "     •     Lava Mutation: " .. (AUTO_LM and "ON" or "OFF")
        drawSystemToggle(SYSTEM_ENABLED)
        drawLavaToggle(AUTO_LM)
    end

    refreshPriorities = function()
        PriorityLabel.Text = "Priority Order\n" .. table.concat(PRIORITY_LIST, "   →   ")
    end

    SystemBtn.Activated:Connect(function()
        SYSTEM_ENABLED = not SYSTEM_ENABLED
        if not SYSTEM_ENABLED then recovering = false end
        notify("Auto Eggs: " .. (SYSTEM_ENABLED and "ON" or "OFF"))
        updateStatus()
    end)

    LavaBtn.Activated:Connect(function()
        AUTO_LM = not AUTO_LM
        notify("Auto Lava Mutation: " .. (AUTO_LM and "ON" or "OFF"))
        updateStatus()
    end)

    PlotBtn.Activated:Connect(function()
        if not teleportToOwnPlot() then notify("Could not detect your plot") end
    end)

    TopBtn.Activated:Connect(function()
        if not teleportToVolcanoTop() then notify("VolcanoTop was not found") end
    end)

    AddBtn.Activated:Connect(function()
        if normalizeName(PriorityBox.Text) ~= "" then
            addPriority(PriorityBox.Text)
            PriorityBox.Text = ""
            refreshPriorities()
        end
    end)

    RemoveBtn.Activated:Connect(function()
        if normalizeName(PriorityBox.Text) ~= "" then
            removePriority(PriorityBox.Text)
            PriorityBox.Text = ""
            refreshPriorities()
        end
    end)

    updateStatus()
    refreshPriorities()

    ------------------------------------------------------------------
    -- Chat commands (only your own messages)
    ------------------------------------------------------------------
    local function processCommand(message)
        message = normalizeName(message)

        if message == "*on" then
            SYSTEM_ENABLED = true
            recovering = false
            notify("System enabled")
        elseif message == "*off" then
            SYSTEM_ENABLED = false
            AUTO_LM = false
            recovering = false
            notify("System disabled")
        elseif message == "*auto lm" then
            AUTO_LM = true
            notify("Auto Lava Mutation: ON")
        elseif message == "*off auto lm" then
            AUTO_LM = false
            notify("Auto Lava Mutation: OFF")
        elseif message:sub(1, 6) == "*addp " then
            addPriority(message:sub(7))
        elseif message:sub(1, 6) == "*remp " then
            removePriority(message:sub(7))
        else
            return
        end

        updateStatus()
        refreshPriorities()
    end

    pcall(function()
        table.insert(Connections, TextChatService.MessageReceived:Connect(function(message)
            local source = message and message.TextSource
            if message and message.Text and source and source.UserId == LocalPlayer.UserId then
                processCommand(message.Text)
            end
        end))
    end)

    ------------------------------------------------------------------
    -- Priority egg loop
    ------------------------------------------------------------------
    task.spawn(function()
        while Running do
            if active() and not busy and not recovering then
                local egg, priority
                if AUTO_FARM_ENABLED then
                    local minLuck = parseLuck(AUTO_FARM_MIN_TEXT)
                    egg = findHighestLuckEgg(minLuck)
                    priority = egg and specialVolcanoKind(egg) or nil
                    if egg then
                        AFStatusText.Text = "Target: " .. tostring(egg.Name) .. "  •  Luck: " .. tostring(getEggLuck(egg)) .. "  •  Minimum: " .. AUTO_FARM_MIN_TEXT
                    else
                        AFStatusText.Text = "No egg currently meets the " .. AUTO_FARM_MIN_TEXT .. " minimum."
                    end
                else
                    egg, priority = findPriorityEgg()
                end

                if egg then
                    busy = true

                    VolcanoRouteActive = true
                    do -- let Auto Place / Hatch stop moving us before we start
                        local t0 = tick()
                        while HubMisc.Moving and tick() - t0 < 5 do task.wait(0.05) end
                    end
                    local ok, err = pcall(function()
                        if priority == "volcanic" then
                            processVolcanic(egg)
                        else
                            processNormal(egg, priority ~= nil and SPECIAL_VOLCANO_EGGS[priority] == true)
                        end
                    end)
                    VolcanoRouteActive = false
                    if not ok then warn("[Main] egg routine error: " .. tostring(err)) end

                    if active() and NEXT_EGG_WAIT_TIME > 0 then
                        task.wait(NEXT_EGG_WAIT_TIME)
                    end

                    busy = false
                else
                    if not AUTO_FARM_ENABLED then
                        AFStatusText.Text = "Auto Farm is OFF."
                    end
                    task.wait(1)
                end
            else
                task.wait(0.2)
            end
        end
    end)

    ------------------------------------------------------------------
    -- Auto Lava: fire the dip once when you enter the VolcanoTop radius
    ------------------------------------------------------------------
        ------------------------------------------------------------------
    -- Auto Lava Mutation - exact behavior from working mobile code
    ------------------------------------------------------------------
    local wasInsideVolcano = false

    table.insert(Connections, RunService.Heartbeat:Connect(function()
        if not SYSTEM_ENABLED or not AUTO_LM then
            wasInsideVolcano = false
            return
        end

        local root = getRoot()
        local topPosition = getVolcanoTopPosition()

        if not root or not topPosition then
            wasInsideVolcano = false
            return
        end

        local distance = (root.Position - topPosition).Magnitude
        local isInside = distance <= VOLCANO_RADIUS

        if isInside and not wasInsideVolcano then
            wasInsideVolcano = true
            task.spawn(function()
                task.wait(0.5)
                pcall(function()
                    local Event = game:GetService("ReplicatedStorage").packages.Net["RE/VolcanoDip"]
                    Event:FireServer()
                end)
            end)
        elseif not isInside then
            wasInsideVolcano = false
        end
    end))

    ------------------------------------------------------------------
    -- Proximity egg collector
    ------------------------------------------------------------------
    local function findPrompt(egg)
    	for _, obj in ipairs(egg:GetDescendants()) do
    		if obj:IsA("ProximityPrompt") then
    			return obj
    		end
    	end

    	return nil
    end

    local function getPromptPart(prompt, egg)
    	if not prompt or not prompt.Parent then
    		return nil
    	end

    	if prompt.Parent:IsA("BasePart") then
    		return prompt.Parent
    	end

    	if egg:IsA("BasePart") then
    		return egg
    	end

    	return egg:FindFirstChildWhichIsA(
    		"BasePart",
    		true
    	)
    end

    local function collectEgg(egg, prompt)
    	if not egg or not prompt then
    		return
    	end

    	for _ = 1, REPEAT_COUNT do
    		if not active() then
    			return
    		end

    		if not egg.Parent or not prompt.Parent then
    			return
    		end

    		local root = getRoot()
    		local promptPart =
    			getPromptPart(prompt, egg)

    		if not root or not promptPart then
    			return
    		end

    		local distance =
    			(root.Position - promptPart.Position).Magnitude

    		if distance > RADIUS then
    			return
    		end

    		if prompt.Enabled then
    			pcall(function() prompt.HoldDuration = 0 end)
    			local fired = false
    			if typeof(fireproximityprompt) == "function" then
    				fired = pcall(fireproximityprompt, prompt)
    			end
    			if not fired then
    				prompt:InputHoldBegin()
    				if HOLD_DURATION > 0 then task.wait(HOLD_DURATION) else task.wait() end
    				if prompt.Parent then prompt:InputHoldEnd() end
    			end
    		end

    		task.wait(0.05)
    	end
    end

    -- Run proximity system separately so it DOES NOT
    -- block the GUI code below it.
    task.spawn(function()

    	while Running and task.wait() do

    		if not active() then
    			continue
    		end

    		local root = getRoot()

    		if not root then
    			continue
    		end

    		for _, egg in ipairs(Folder:GetChildren()) do

    			if not egg.Parent then
    				continue
    			end

    			local prompt = findPrompt(egg)

    			if not prompt then
    				continue
    			end

    			local promptPart =
    				getPromptPart(prompt, egg)

    			if not promptPart then
    				continue
    			end

    			local distance =
    				(root.Position - promptPart.Position).Magnitude

    			if distance <= RADIUS
    				and not pendingEggs[egg] then

    				-- Mark this egg as waiting.
    				pendingEggs[egg] = true

    				task.spawn(function()

    					-- Wait 5 seconds before holding
    					-- the proximity prompt.
    					if WAIT_BEFORE_PROXIMITY > 0 then task.wait(WAIT_BEFORE_PROXIMITY) end

    					-- Re-check everything after 5 seconds.
    					if not active() then
    						pendingEggs[egg] = nil
    						return
    					end

    					if not egg.Parent then
    						pendingEggs[egg] = nil
    						return
    					end

    					if not prompt.Parent then
    						pendingEggs[egg] = nil
    						return
    					end

    					local currentRoot =
    						getRoot()

    					local currentPart =
    						getPromptPart(
    							prompt,
    							egg
    						)

    					if not currentRoot
    						or not currentPart then

    						pendingEggs[egg] = nil
    						return
    					end

    					local currentDistance =
    						(
    							currentRoot.Position
    							- currentPart.Position
    						).Magnitude

    					-- Only interact if still within 10 studs.
    					if currentDistance <= RADIUS then

    						collectEgg(
    							egg,
    							prompt
    						)
    					end

    					-- Allow this egg to be detected again
    					-- after the current attempt finishes.
    					pendingEggs[egg] = nil
    				end)
    			end
    		end
    	end
    end)

    -- Clean up references when an egg disappears.
    Folder.ChildRemoved:Connect(function(egg)
    	pendingEggs[egg] = nil
    end)
    task.delay(1, function() notify("KizzyHub loaded") end)
end




--====================================================
-- LITE TOOLS
-- Only Auto Place Egg + Auto Hatch are kept here.
--====================================================

local ToolsScroll = Instance.new("ScrollingFrame")
ToolsScroll.Size = UDim2.fromScale(1, 1)
ToolsScroll.BackgroundTransparency = 1
ToolsScroll.BorderSizePixel = 0
ToolsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
ToolsScroll.CanvasSize = UDim2.new()
ToolsScroll.ScrollBarThickness = 4
ToolsScroll.Parent = PanelTools

local ToolsLayout = Instance.new("UIListLayout")
ToolsLayout.Padding = UDim.new(0, 6)
ToolsLayout.Parent = ToolsScroll

-- Turns a plain TextButton into a labelled switch with an ON/OFF pill.
local function pillize(btn, label)
    btn.Text = ""

    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1
    t.Position = UDim2.fromOffset(10, 0)
    t.Size = UDim2.new(1, -78, 1, 0)
    t.Font = Enum.Font.GothamBold
    t.Text = label
    t.TextColor3 = Color3.fromRGB(235, 235, 245)
    t.TextSize = UserInputService.TouchEnabled and 12 or 11
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Parent = btn

    local track = Instance.new("Frame")
    track.AnchorPoint = Vector2.new(1, 0.5)
    track.Position = UDim2.new(1, -8, 0.5, 0)
    track.Size = UDim2.fromOffset(48, 24)
    track.BorderSizePixel = 0
    track.Parent = btn
    round(track, 12)

    local knob = Instance.new("Frame")
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Size = UDim2.fromOffset(18, 18)
    knob.BorderSizePixel = 0
    knob.BackgroundColor3 = Color3.fromRGB(245, 245, 250)
    knob.Parent = track
    round(knob, 9)

    local firstDraw = true
    return function(on, instant)
        local trackColor = on and Color3.fromRGB(65, 190, 105) or Color3.fromRGB(75, 75, 90)
        local knobPos = on and UDim2.new(1, -12, 0.5, 0) or UDim2.new(0, 12, 0.5, 0)

        if firstDraw or instant then
            track.BackgroundColor3 = trackColor
            knob.Position = knobPos
            firstDraw = false
        else
            TweenService:Create(track, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = trackColor
            }):Play()
            TweenService:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = knobPos
            }):Play()
        end
    end
end

local function toolControl(text)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -8, 0, 36)
    b.BackgroundColor3 = THEME.Button
    b.BorderSizePixel = 0
    b.Font = Enum.Font.GothamBold
    b.Text = text
    b.TextColor3 = Color3.new(1, 1, 1)
    b.TextSize = UserInputService.TouchEnabled and 12 or 11
    b.Parent = ToolsScroll
    round(b, 7)
    return b
end

do
    -- Max Luck upgrade: same Plot.Upgrades("Max") call used by the uploaded reference.
    local function findMaxLuckRemote()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local gameRemotes = remotes and remotes:FindFirstChild("Game")
        local exact = gameRemotes and gameRemotes:FindFirstChild("Plot.Upgrades")
        if exact then return exact end

        -- Some executors run before the remotes finish replicating. Search again dynamically.
        for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
            if obj.Name == "Plot.Upgrades" and (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) then
                return obj
            end
        end
        return nil
    end

    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local reusableRemotes = remotes and remotes:FindFirstChild("Reusable")
    local maxLuckRemote = findMaxLuckRemote()

    local maxLuckHeader = Instance.new("TextLabel")
    maxLuckHeader.Size = UDim2.new(1, -8, 0, 18)
    maxLuckHeader.BackgroundTransparency = 1
    maxLuckHeader.Font = Enum.Font.GothamBold
    maxLuckHeader.Text = "🍀 MAX LUCK"
    maxLuckHeader.TextColor3 = Color3.fromRGB(150, 185, 255)
    maxLuckHeader.TextSize = 11
    maxLuckHeader.TextXAlignment = Enum.TextXAlignment.Left
    maxLuckHeader.Parent = ToolsScroll

    local buyMaxLuckBtn = toolControl("Auto Max Luck", 38)
    buyMaxLuckBtn.TextXAlignment = Enum.TextXAlignment.Left
    buyMaxLuckBtn.TextYAlignment = Enum.TextYAlignment.Center

    local maxLuckPadding = Instance.new("UIPadding")
    maxLuckPadding.PaddingLeft = UDim.new(0, 12)
    maxLuckPadding.PaddingRight = UDim.new(0, 10)
    maxLuckPadding.Parent = buyMaxLuckBtn

    local maxLuckSwitch = Instance.new("Frame")
    maxLuckSwitch.Name = "ToggleSwitch"
    maxLuckSwitch.AnchorPoint = Vector2.new(1, 0.5)
    maxLuckSwitch.Position = UDim2.new(1, 0, 0.5, 0)
    maxLuckSwitch.Size = UDim2.fromOffset(48, 24)
    maxLuckSwitch.BackgroundColor3 = Color3.fromRGB(72, 74, 88)
    maxLuckSwitch.BorderSizePixel = 0
    maxLuckSwitch.Parent = buyMaxLuckBtn
    round(maxLuckSwitch, 11)

    local maxLuckKnob = Instance.new("Frame")
    maxLuckKnob.Name = "Knob"
    maxLuckKnob.Size = UDim2.fromOffset(18, 18)
    maxLuckKnob.Position = UDim2.fromOffset(3, 3)
    maxLuckKnob.BackgroundColor3 = Color3.fromRGB(225, 225, 235)
    maxLuckKnob.BorderSizePixel = 0
    maxLuckKnob.Parent = maxLuckSwitch
    round(maxLuckKnob, 9)
    buyMaxLuckBtn.BackgroundColor3 = THEME.Button
    local autoMaxLuckEnabled = false

    local maxLuckStatus = Instance.new("TextLabel")
    maxLuckStatus.Size = UDim2.new(1, -8, 0, 30)
    maxLuckStatus.BackgroundTransparency = 1
    maxLuckStatus.Font = Enum.Font.GothamMedium
    maxLuckStatus.Text = "Uses the game's Max Luck upgrade."
    maxLuckStatus.TextColor3 = Color3.fromRGB(165, 170, 195)
    maxLuckStatus.TextSize = 10
    maxLuckStatus.TextWrapped = true
    maxLuckStatus.TextXAlignment = Enum.TextXAlignment.Left
    maxLuckStatus.Parent = ToolsScroll

    local lastMaxLuckFire = 0

    local function setMaxLuckStatus(text, good)
        maxLuckStatus.Text = tostring(text)
        maxLuckStatus.TextColor3 = good
            and Color3.fromRGB(100, 240, 145)
            or Color3.fromRGB(255, 145, 145)
    end

    for _, remoteName in ipairs({"GameMessage", "GameWarning"}) do
        local messageRemote = reusableRemotes and reusableRemotes:FindFirstChild(remoteName)
        if messageRemote and messageRemote:IsA("RemoteEvent") then
            messageRemote.OnClientEvent:Connect(function(message)
                if type(message) ~= "string" or os.clock() - lastMaxLuckFire > 3 then return end
                if message:find("^Upgraded") then
                    setMaxLuckStatus(message, true)
                else
                    setMaxLuckStatus(message, false)
                end
            end)
        end
    end

    local function updateAutoMaxLuckVisual()
        buyMaxLuckBtn.Text = "Auto Max Luck"
        buyMaxLuckBtn.BackgroundColor3 = THEME.Button
        maxLuckSwitch.BackgroundColor3 = autoMaxLuckEnabled
            and Color3.fromRGB(65, 190, 105)
            or Color3.fromRGB(72, 74, 88)
        maxLuckKnob.Position = autoMaxLuckEnabled
            and UDim2.fromOffset(22, 2)
            or UDim2.fromOffset(2, 2)
    end

    local function buyMaxLuck()
        print("[Egg Hub][Max Luck] Attempting Max Luck upgrade...")

        -- Exact path used by the working code:
        -- ReplicatedStorage -> Remotes -> Game -> Plot -> Upgrades
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if not remotes then
            warn("[Egg Hub][Max Luck] FAILED: ReplicatedStorage.Remotes not found.")
            setMaxLuckStatus("Remotes unavailable - check console", false)
            return false
        end

        local gameRemotes = remotes:FindFirstChild("Game")
        if not gameRemotes then
            warn("[Egg Hub][Max Luck] FAILED: ReplicatedStorage.Remotes.Game not found.")
            print("[Egg Hub][Max Luck] Remotes children:")
            for _, child in ipairs(remotes:GetChildren()) do
                print("  - " .. child.Name .. " [" .. child.ClassName .. "]")
            end
            setMaxLuckStatus("Remotes.Game unavailable - check console", false)
            return false
        end

        local plot = gameRemotes:FindFirstChild("Plot")
        if not plot then
            warn("[Egg Hub][Max Luck] FAILED: ReplicatedStorage.Remotes.Game.Plot not found.")
            print("[Egg Hub][Max Luck] Game children:")
            for _, child in ipairs(gameRemotes:GetChildren()) do
                print("  - " .. child.Name .. " [" .. child.ClassName .. "]")
            end
            setMaxLuckStatus("Game.Plot unavailable - check console", false)
            return false
        end

        local r = plot:FindFirstChild("Upgrades")
        if not r then
            warn("[Egg Hub][Max Luck] FAILED: ReplicatedStorage.Remotes.Game.Plot.Upgrades not found.")
            print("[Egg Hub][Max Luck] Plot children:")
            for _, child in ipairs(plot:GetChildren()) do
                print("  - " .. child.Name .. " [" .. child.ClassName .. "]")
            end
            setMaxLuckStatus("Plot.Upgrades unavailable - check console", false)
            return false
        end

        print("[Egg Hub][Max Luck] Found remote:", r:GetFullName(), "[" .. r.ClassName .. "]")

        if not r:IsA("RemoteEvent") then
            warn("[Egg Hub][Max Luck] FAILED: Upgrades is " .. r.ClassName .. ", expected RemoteEvent.")
            setMaxLuckStatus("Upgrades wrong type - check console", false)
            return false
        end

        lastMaxLuckFire = os.clock()
        local ok, err = pcall(function()
            r:FireServer("Max")
        end)

        if not ok then
            warn("[Egg Hub][Max Luck] FAILED FireServer(\"Max\"): " .. tostring(err))
            setMaxLuckStatus("Max Luck failed - check console", false)
            return false
        end

        print("[Egg Hub][Max Luck] SUCCESS: FireServer(\"Max\") sent.")
        setMaxLuckStatus("Requested max plot luck upgrade", true)
        return true
    end

    buyMaxLuckBtn.Activated:Connect(function()
        autoMaxLuckEnabled = not autoMaxLuckEnabled
        updateAutoMaxLuckVisual()
        if autoMaxLuckEnabled then
            setMaxLuckStatus("Auto Buy Max Luck started.", true)
        else
            setMaxLuckStatus("Auto Buy Max Luck stopped.", true)
        end
    end)

    task.spawn(function()
        while Running do
            if autoMaxLuckEnabled then
                buyMaxLuck()
                task.wait(3)
            else
                task.wait(0.25)
            end
        end
    end)

    updateAutoMaxLuckVisual()
end

do
    -- Auto Place / Auto Hatch restored to the earlier working flow:
    -- return to ranch -> wait for basket delivery -> place into free nests;
    -- for hatching, move within range of each ready egg before firing Hatch.
    local enabledPlace = false
    local enabledHatch = false
    local busy = false
    local hatchCooldown = {}

    local placeBtn = toolControl("Auto Place Egg: OFF")
    local hatchBtn = toolControl("Auto Hatch: OFF")

    local drawPlace = pillize(placeBtn, "Auto Place Egg")
    local drawHatch = pillize(hatchBtn, "Auto Hatch")
    local function paint()
        drawPlace(enabledPlace)
        drawHatch(enabledHatch)
    end

    placeBtn.MouseButton1Click:Connect(function()
        enabledPlace = not enabledPlace
        paint()
    end)

    hatchBtn.MouseButton1Click:Connect(function()
        enabledHatch = not enabledHatch
        paint()
    end)

    paint()

    local function gameRemote(name)
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local gameRemotes = remotes and remotes:FindFirstChild("Game")
        return gameRemotes and gameRemotes:FindFirstChild(name)
    end

    local function character()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if hum and root and hum.Health > 0 then
            return char, hum, root
        end
    end

    local function myPlot()
        local plots = workspace:FindFirstChild("Plots")
        if not plots then return nil end
        for _, plot in ipairs(plots:GetChildren()) do
            local data = plot:FindFirstChild("Data")
            local owner = data and data:FindFirstChild("Owner")
            if owner and owner.Value == LocalPlayer then
                return plot
            end
        end
        return nil
    end

    local function basket()
        local b = LocalPlayer:FindFirstChild("Basket")
        return b and b:GetChildren() or {}
    end

    local eggDefs, generalData, dayNight
    local function loadEggModules()
        if eggDefs and generalData and dayNight then return true end
        local ok = pcall(function()
            eggDefs = require(ReplicatedStorage.GameData.Eggs)
            generalData = require(ReplicatedStorage.GameData.General)
            dayNight = require(ReplicatedStorage.GameServices.DayNight)
        end)
        return ok and eggDefs and generalData and dayNight
    end

    local function allTools()
        local result = {}
        for _, holder in ipairs({LocalPlayer:FindFirstChild("Backpack"), LocalPlayer.Character}) do
            if holder then
                for _, item in ipairs(holder:GetChildren()) do
                    if item:IsA("Tool") then result[#result+1] = item end
                end
            end
        end
        return result
    end

    local function eggTools()
        local result = {}
        if not loadEggModules() then return result end
        for _, tool in ipairs(allTools()) do
            if eggDefs[tool.Name] and not tool:GetAttribute("PetKey") then
                result[#result+1] = tool
            end
        end
        table.sort(result, function(a,b)
            return ((eggDefs[a.Name] and eggDefs[a.Name].Luck) or 0)
                > ((eggDefs[b.Name] and eggDefs[b.Name].Luck) or 0)
        end)
        return result
    end

    local function freeNests()
        local result = {}
        local plot = myPlot()
        local nests = plot and plot:FindFirstChild("Nests")
        if nests then
            for _, nest in ipairs(nests:GetChildren()) do
                if nest:GetAttribute("Unlocked") and not nest:GetAttribute("Occupied") then
                    result[#result+1] = nest
                end
            end
        end
        table.sort(result, function(a,b)
            return (tonumber(a.Name) or 0) < (tonumber(b.Name) or 0)
        end)
        return result
    end

    local function moveTo(position, radius)
        local _, hum, root = character()
        if not root then return false end
        radius = radius or 12

        hum:UnequipTools()
        local target = position + Vector3.new(0, math.max(3, hum.HipHeight + root.Size.Y/2), 0)
        local distance = (root.Position-target).Magnitude

        if distance <= radius then return true end

        -- Same basic flight/tween idea as the earlier automation code.
        local speed = math.clamp(tonumber(FlySpeedBox and FlySpeedBox.Text) or 500, 40, 20000)
        local duration = math.max(0.05, distance/speed)
        local oldPlatform = hum.PlatformStand
        local oldRotate = hum.AutoRotate
        hum.PlatformStand = true
        hum.AutoRotate = false

        local tween = TweenService:Create(
            root,
            TweenInfo.new(duration, Enum.EasingStyle.Linear),
            {CFrame = CFrame.new(target) * root.CFrame.Rotation}
        )
        tween:Play()
        task.spawn(function()
            while tween.PlaybackState == Enum.PlaybackState.Playing do
                if VolcanoRouteActive then tween:Cancel() break end
                task.wait(0.05)
            end
        end)
        tween.Completed:Wait()

        hum.PlatformStand = oldPlatform
        hum.AutoRotate = oldRotate
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        task.wait(0.15)

        return root.Parent and (root.Position-target).Magnitude <= math.max(radius, 15)
    end

    local function onPlot()
        local _,_,root = character()
        local plot = myPlot()
        local base = plot and plot:FindFirstChild("Baseplate")
        if not root or not base then return false end
        local p = base.CFrame:PointToObjectSpace(root.Position)
        return math.abs(p.X) < base.Size.X/2
            and math.abs(p.Z) < base.Size.Z/2
            and math.abs(p.Y) < 35
    end

    local function home()
        local plot = myPlot()
        local base = plot and plot:FindFirstChild("Baseplate")
        if not base then return false end

        if #basket() == 0 and onPlot() then return true end

        local before = {}
        for _,tool in ipairs(eggTools()) do before[tool] = true end

        if not moveTo(base.Position + Vector3.new(0,3,0), 12) then
            return false
        end

        -- When carrying basket eggs, reaching the ranch converts them to tools.
        if #basket() > 0 then
            local deadline = os.clock()+4
            while os.clock()<deadline and #basket()>0 do
                task.wait(0.1)
            end
        end

        return true
    end

    local function waitFor(predicate, seconds)
        local deadline = os.clock() + seconds
        repeat
            local ok, value = pcall(predicate)
            if ok and value then return value end
            task.wait(0.1)
        until os.clock() >= deadline
        return false
    end

    local function placeOnce()
        if busy or Claiming or VolcanoRouteActive or HubMisc.PetJob or not enabledPlace then return end
        if #basket()==0 and #eggTools()==0 then return end

        local remote = gameRemote("EggPlaced")
        if not remote or not remote:IsA("RemoteEvent") then return end

        busy = true
        HubMisc.Moving = true
        pcall(function()
            -- Earlier code always returned home first so basket eggs are delivered.
            if not home() then return end

            local nests = freeNests()
            if #nests==0 then return end

            waitFor(function() return #eggTools()>0 end, 2)

            for _,nest in ipairs(nests) do
                if Claiming or VolcanoRouteActive or HubMisc.PetJob or not enabledPlace then break end

                local tool = eggTools()[1]
                if not tool then break end

                local _,hum = character()
                if not hum then break end
                hum:EquipTool(tool)
                task.wait(0.15)

                remote:FireServer({NestId=nest.Name})

                -- Earlier code required server confirmation before moving on.
                if not waitFor(function()
                    return nest:GetAttribute("Occupied")
                end, 3) then
                    break
                end
            end
        end)
        busy = false
        HubMisc.Moving = false
    end

    local function eggTimers()
        local rows = {}
        if not loadEggModules() then return rows end

        local plot = myPlot()
        local eggs = plot and plot:FindFirstChild("Eggs")
        if not eggs then return rows end

        for _,egg in ipairs(eggs:GetChildren()) do
            local info = egg:FindFirstChild("EggData", true)
            local data = eggDefs[egg.Name]
            local start = info and info:FindFirstChild("PlaceTime")
            local weight = info and info:FindFirstChild("Weight")

            if data and start then
                local ok, remaining = pcall(function()
                    local total = generalData.GrowthTimeFor(data.GrowthTime or 0, weight and weight.Value or 1)
                    return dayNight.GrowthRealRemaining(start.Value, total)
                end)

                if ok and tonumber(remaining) then
                    rows[#rows+1] = {
                        Object=egg,
                        Key=egg:GetAttribute("EggKey"),
                        Name=egg.Name,
                        Remaining=remaining
                    }
                end
            end
        end

        table.sort(rows,function(a,b) return a.Remaining<b.Remaining end)
        return rows
    end

    local function hatchOnce()
        if busy or Claiming or VolcanoRouteActive or HubMisc.PetJob or not enabledHatch then return end

        local remote = gameRemote("Hatch")
        if not remote or not remote:IsA("RemoteEvent") then return end

        busy = true
        HubMisc.Moving = true
        pcall(function()
            for _,egg in ipairs(eggTimers()) do
                if Claiming or VolcanoRouteActive or HubMisc.PetJob or not enabledHatch then break end

                if egg.Remaining<=0 and egg.Key
                    and os.clock()>=(hatchCooldown[egg.Key] or 0) then

                    hatchCooldown[egg.Key]=os.clock()+5

                    local _,_,root=character()
                    if not root then break end

                    -- This was missing from the Lite rewrite:
                    -- get within hatch range before firing the remote.
                    if egg.Object.Parent
                        and (root.Position-egg.Object:GetPivot().Position).Magnitude>12 then
                        if not moveTo(egg.Object:GetPivot().Position,12) then break end
                    end

                    if egg.Object.Parent then
                        remote:FireServer({EggKey=egg.Key})

                        -- Wait for server confirmation (egg disappears).
                        waitFor(function()
                            return not egg.Object.Parent
                        end,8)
                    end
                end
            end
        end)
        busy=false
        HubMisc.Moving = false
    end

    task.spawn(function()
        while Running and ScreenGui.Parent do
            task.wait(1)
            if enabledPlace then placeOnce() end
            if enabledHatch then hatchOnce() end
        end
    end)
end

-- --- PANEL ESP CONTENTS ---
local ESPCfg = {
    Name = true, Luck = true, Dist = true, Tier = true,
    Outline = true, Tracers = false, Arrow = false, Mark = true,
}
local ESPOptionNames = {
    Name = "Name", Luck = "Luck", Dist = "Distance", Tier = "Tier Colors",
    Outline = "Outline", Tracers = "Tracers", Arrow = "Arrow", Mark = "Mark Selected",
}
local ESPOptionButtons = {}
local onESPSettingChanged = function() end -- wired to saveSettings further down
local ESPToggleBtn, ESPMinBox, ESPMaxBox, refreshESPControls -- assigned below (kept as few top-level locals as possible)

do
    -- Old ESP controls removed. Only the scroll container remains; Egg ESP+ fills it.
    local ESPScroll = Instance.new("ScrollingFrame")
    ESPScroll.Size = UDim2.new(1, 0, 1, 0)
    ESPScroll.BackgroundTransparency = 1
    ESPScroll.BorderSizePixel = 0
    ESPScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    ESPScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ESPScroll.ScrollBarThickness = 4
    ESPScroll.Parent = PanelESP

    local ESPLayout = Instance.new("UIListLayout")
    ESPLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ESPLayout.Padding = UDim.new(0, 6)
    ESPLayout.Parent = ESPScroll

    -- Detached boxes keep the settings save/load code working (never shown).
    ESPMinBox = Instance.new("TextBox")
    ESPMaxBox = Instance.new("TextBox")
    ESPToggleBtn = Instance.new("TextButton")
    refreshESPControls = function() end
end


-- --- PANEL SETTINGS CONTENTS (WEBHOOKS) ---
local SettingsScroll = Instance.new("ScrollingFrame")
SettingsScroll.Size = UDim2.new(1, 0, 1, 0)
SettingsScroll.BackgroundTransparency = 1
SettingsScroll.BorderSizePixel = 0
SettingsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
SettingsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
SettingsScroll.ScrollBarThickness = 4
SettingsScroll.Parent = PanelSettings

local SettingsLayout = Instance.new("UIListLayout")
SettingsLayout.SortOrder = Enum.SortOrder.LayoutOrder
SettingsLayout.Padding = UDim.new(0, 6)
SettingsLayout.Parent = SettingsScroll

local settingsOrder = 0
local function nextOrder()
    settingsOrder += 1
    return settingsOrder
end

local CompatibilityCard = Instance.new("Frame")
CompatibilityCard.Size = UDim2.new(1, -8, 0, 72)
CompatibilityCard.BackgroundColor3 = THEME.Panel
CompatibilityCard.BorderSizePixel = 0
CompatibilityCard.LayoutOrder = nextOrder()
CompatibilityCard.Parent = SettingsScroll
round(CompatibilityCard, 8)

local CompatibilityTitle = Instance.new("TextLabel")
CompatibilityTitle.Position = UDim2.fromOffset(10, 7)
CompatibilityTitle.Size = UDim2.new(1, -20, 0, 18)
CompatibilityTitle.BackgroundTransparency = 1
CompatibilityTitle.Font = Enum.Font.GothamBold
CompatibilityTitle.Text = "EXECUTOR COMPATIBILITY"
CompatibilityTitle.TextColor3 = Color3.fromRGB(150, 185, 255)
CompatibilityTitle.TextSize = 11
CompatibilityTitle.TextXAlignment = Enum.TextXAlignment.Left
CompatibilityTitle.Parent = CompatibilityCard

local CompatibilityText = Instance.new("TextLabel")
CompatibilityText.Position = UDim2.fromOffset(10, 27)
CompatibilityText.Size = UDim2.new(1, -20, 0, 38)
CompatibilityText.BackgroundTransparency = 1
CompatibilityText.Font = Enum.Font.GothamMedium
CompatibilityText.Text = ExecutorCompatibility.Name
    .. "  •  " .. executorSupportText()
do
    local support = executorSupportText()
    if support == "Full Support" then
        CompatibilityText.TextColor3 = Color3.fromRGB(110, 240, 145)
    elseif support == "Limited Support" then
        CompatibilityText.TextColor3 = Color3.fromRGB(255, 190, 100)
    else
        CompatibilityText.TextColor3 = Color3.fromRGB(255, 110, 110)
    end
end
CompatibilityText.TextSize = 10
CompatibilityText.TextWrapped = true
CompatibilityText.TextXAlignment = Enum.TextXAlignment.Left
CompatibilityText.TextYAlignment = Enum.TextYAlignment.Top
CompatibilityText.Parent = CompatibilityCard

local function makeHeader(text)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -8, 0, 18)
    l.BackgroundTransparency = 1
    l.Font = Enum.Font.GothamBold
    l.Text = text
    l.TextColor3 = Color3.fromRGB(150, 185, 255)
    l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.LayoutOrder = nextOrder()
    l.Parent = SettingsScroll
    return l
end

local function makeInput(placeholder, default)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -8, 0, 28)
    box.BackgroundColor3 = THEME.Panel
    box.BorderSizePixel = 0
    box.Font = Enum.Font.GothamMedium
    box.Text = default or ""
    box.PlaceholderText = placeholder
    box.PlaceholderColor3 = Color3.fromRGB(110, 110, 130)
    box.TextColor3 = Color3.new(1, 1, 1)
    box.TextSize = 10
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.ClearTextOnFocus = false
    box.ClipsDescendants = true
    box.LayoutOrder = nextOrder()
    box.Parent = SettingsScroll
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 8)
    pad.PaddingRight = UDim.new(0, 8)
    pad.Parent = box
    round(box, 6)
    return box
end

local function makeToggleRow()
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -8, 0, 38)
    row.BackgroundTransparency = 1
    row.LayoutOrder = nextOrder()
    row.Parent = SettingsScroll

    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0.62, -3, 1, 0)
    toggle.BackgroundColor3 = THEME.Button
    toggle.BorderSizePixel = 0
    toggle.Font = Enum.Font.GothamBold
    toggle.TextSize = 11
    toggle.Parent = row
    round(toggle, 6)

    local test = Instance.new("TextButton")
    test.Position = UDim2.new(0.62, 3, 0, 0)
    test.Size = UDim2.new(0.38, -3, 1, 0)
    test.BackgroundColor3 = THEME.Accent
    test.BorderSizePixel = 0
    test.Font = Enum.Font.GothamBold
    test.Text = "Send Test"
    test.TextColor3 = Color3.new(1, 1, 1)
    test.TextSize = 10
    test.Parent = row
    round(test, 6)

    return toggle, test
end

local SettingsToggleVisuals = setmetatable({}, {__mode = "k"})

local function setToggleVisual(btn, label, on)
    if not btn or not btn.Parent then return end

    local visual = SettingsToggleVisuals[btn]
    if not visual then
        btn.Text = ""

        local labelText = Instance.new("TextLabel")
        labelText.BackgroundTransparency = 1
        labelText.Position = UDim2.fromOffset(8, 0)
        labelText.Size = UDim2.new(1, -66, 1, 0)
        labelText.Font = Enum.Font.GothamBold
        labelText.TextColor3 = Color3.fromRGB(235, 235, 245)
        labelText.TextSize = UserInputService.TouchEnabled and 11 or 10
        labelText.TextXAlignment = Enum.TextXAlignment.Left
        labelText.Parent = btn

        local track = Instance.new("Frame")
        track.AnchorPoint = Vector2.new(1, 0.5)
        track.Position = UDim2.new(1, -6, 0.5, 0)
        track.Size = UDim2.fromOffset(48, 24)
        track.BorderSizePixel = 0
        track.Parent = btn
        round(track, 11)

        local knob = Instance.new("Frame")
        knob.AnchorPoint = Vector2.new(0.5, 0.5)
        knob.Size = UDim2.fromOffset(18, 18)
        knob.BorderSizePixel = 0
        knob.BackgroundColor3 = Color3.fromRGB(245, 245, 250)
        knob.Parent = track
        round(knob, 8)

        visual = {Label = labelText, Track = track, Knob = knob, First = true}
        SettingsToggleVisuals[btn] = visual
    end

    visual.Label.Text = label
    local trackColor = on and Color3.fromRGB(65, 190, 105) or Color3.fromRGB(75, 75, 90)
    local knobPos = on and UDim2.new(1, -12, 0.5, 0) or UDim2.new(0, 12, 0.5, 0)

    if visual.First then
        visual.Track.BackgroundColor3 = trackColor
        visual.Knob.Position = knobPos
        visual.First = false
    else
        TweenService:Create(visual.Track, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = trackColor
        }):Play()
        TweenService:Create(visual.Knob, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = knobPos
        }):Play()
    end
end


-- Anti AFK
makeHeader(" AFK")
local AntiAFKBtn = Instance.new("TextButton")
AntiAFKBtn.Size = UDim2.new(1, -8, 0, 38)
AntiAFKBtn.BackgroundColor3 = THEME.Button
AntiAFKBtn.BorderSizePixel = 0
AntiAFKBtn.Font = Enum.Font.GothamBold
AntiAFKBtn.TextSize = 11
AntiAFKBtn.LayoutOrder = nextOrder()
AntiAFKBtn.Parent = SettingsScroll
round(AntiAFKBtn, 6)

local ANTI_AFK_SETTINGS_FILE = "KizzyHub_AntiAFK.json"
AntiAFKEnabled = false
local AntiAFKConnection = nil
local AntiAFKRelease = false

local function saveAntiAFKSetting()
    if type(writefile) ~= "function" then return end
    pcall(function()
        writefile(ANTI_AFK_SETTINGS_FILE, HttpService:JSONEncode({Enabled = AntiAFKEnabled == true}))
    end)
end

local function loadAntiAFKSetting()
    if type(readfile) ~= "function" or type(isfile) ~= "function" then return end
    pcall(function()
        if not isfile(ANTI_AFK_SETTINGS_FILE) then return end
        local data = HttpService:JSONDecode(readfile(ANTI_AFK_SETTINGS_FILE))
        if type(data) == "table" then AntiAFKEnabled = data.Enabled == true end
    end)
end

loadAntiAFKSetting()

local function stopAntiAFK()
    if AntiAFKConnection then
        pcall(function() AntiAFKConnection:Disconnect() end)
        AntiAFKConnection = nil
    end
    if AntiAFKRelease then
        pcall(function()
            VirtualUser:Button2Up(Vector2.zero, workspace.CurrentCamera.CFrame)
        end)
        AntiAFKRelease = false
    end
end

local function startAntiAFK()
    stopAntiAFK()
    if not AntiAFKEnabled then return end

    AntiAFKConnection = LocalPlayer.Idled:Connect(function()
        if not Running or not AntiAFKEnabled then return end

        local ok = pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:Button2Down(Vector2.zero, workspace.CurrentCamera.CFrame)
            AntiAFKRelease = true
        end)

        if ok then
            task.delay(0.2, function()
                if AntiAFKRelease then
                    pcall(function()
                        VirtualUser:Button2Up(Vector2.zero, workspace.CurrentCamera.CFrame)
                    end)
                    AntiAFKRelease = false
                end
            end)
        end
    end)
end

local function refreshAntiAFK()
    setToggleVisual(AntiAFKBtn, "Anti AFK", AntiAFKEnabled)
end

AntiAFKBtn.Activated:Connect(function()
    AntiAFKEnabled = not AntiAFKEnabled
    if AntiAFKEnabled then
        startAntiAFK()
    else
        stopAntiAFK()
    end
    saveAntiAFKSetting()
    refreshAntiAFK()
end)

if AntiAFKEnabled then startAntiAFK() end
refreshAntiAFK()

-- Movement mode (used by Auto Farm and the manual TP button)
makeHeader(" Movement")
local MoveModeBtn = Instance.new("TextButton")
MoveModeBtn.Size = UDim2.new(1, -8, 0, 38)
MoveModeBtn.BackgroundColor3 = THEME.Button
MoveModeBtn.BorderSizePixel = 0
MoveModeBtn.Font = Enum.Font.GothamBold
MoveModeBtn.TextSize = 11
MoveModeBtn.LayoutOrder = nextOrder()
MoveModeBtn.Parent = SettingsScroll
round(MoveModeBtn, 6)

local FlySpeedBox = makeInput("Fly speed in studs/sec (e.g. 500, max 20000)", "500")

local drawMoveMode = pillize(MoveModeBtn, "Fly to Egg (OFF = teleport)")
local function updateMoveVisual()
    drawMoveMode(MoveMode == "Fly")
end
updateMoveVisual()


--====================================================
-- AUTO LOAD / AUTO EXECUTE
--====================================================
makeHeader(" Auto Load")

local AutoLoadBtn = Instance.new("TextButton")
AutoLoadBtn.Size = UDim2.new(1, -8, 0, 28)
AutoLoadBtn.BackgroundColor3 = THEME.Button
AutoLoadBtn.BorderSizePixel = 0
AutoLoadBtn.Font = Enum.Font.GothamBold
AutoLoadBtn.TextSize = 11
AutoLoadBtn.LayoutOrder = nextOrder()
AutoLoadBtn.Parent = SettingsScroll
round(AutoLoadBtn, 6)

local AUTOLOAD_CONFIG = "EggHub_AutoLoad.json"
local AUTOLOAD_SOURCE_FILE = "EggHub_AutoLoad_Source.lua"
local AUTOLOAD_SOURCE = nil -- FastStart: reuse saved source if available
local AUTOLOAD_CANDIDATES = {
    "autoexec/EggHub_AutoLoad.lua",
    "Autoexec/EggHub_AutoLoad.lua",
    "autoexecute/EggHub_AutoLoad.lua",
    "AutoExecute/EggHub_AutoLoad.lua",
}

local function getQueueOnTeleport()
    if type(queue_on_teleport) == "function" then return queue_on_teleport end
    if type(queueonteleport) == "function" then return queueonteleport end
    if type(syn) == "table" and type(syn.queue_on_teleport) == "function" then return syn.queue_on_teleport end
    if type(fluxus) == "table" and type(fluxus.queue_on_teleport) == "function" then return fluxus.queue_on_teleport end
    return nil
end

local function readAutoLoadEnabled()
    if type(isfile) ~= "function" or type(readfile) ~= "function" or not isfile(AUTOLOAD_CONFIG) then
        return false
    end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(AUTOLOAD_CONFIG))
    end)
    return ok and type(data) == "table" and data.Enabled == true
end

local function saveAutoLoadEnabled(enabled)
    if type(writefile) ~= "function" then return false end
    return pcall(function()
        writefile(AUTOLOAD_CONFIG, HttpService:JSONEncode({Enabled = enabled == true}))
    end)
end

local function makeLoader()
    return [[
repeat task.wait() until game:IsLoaded()
task.wait(1)
if type(isfile) == "function" and type(readfile) == "function"
    and isfile("EggHub_AutoLoad_Source.lua") then
    local ok, source = pcall(readfile, "EggHub_AutoLoad_Source.lua")
    if ok and type(source) == "string" then
        local env = (type(getgenv) == "function" and getgenv()) or _G
        env.KizzyHubCurrentSource = source
        local fn = loadstring(source)
        if fn then pcall(fn) end
    end
end
]]
end

local function saveHubSource()
    if type(writefile) ~= "function" then return false end

    local source = AUTOLOAD_SOURCE
    local env = (type(getgenv) == "function" and getgenv()) or _G

    -- Override the stale saved copy with the exact current source when the
    -- current loader supplied it. No second KizzyHub copy is embedded here.
    if (not source or source == "") and type(env.KizzyHubCurrentSource) == "string" then
        source = env.KizzyHubCurrentSource
    end

    if source and source ~= "" then
        return pcall(writefile, AUTOLOAD_SOURCE_FILE, source)
    end

    return type(isfile) == "function" and isfile(AUTOLOAD_SOURCE_FILE)
end

local function queueNextTeleport()
    local q = getQueueOnTeleport()
    if not q then return false end
    local loader = makeLoader()
    return pcall(q, loader)
end

local function tryInstallNativeAutoExec()
    if type(writefile) ~= "function" then return nil end
    local loader = makeLoader()

    for _, path in ipairs(AUTOLOAD_CANDIDATES) do
        local folder = path:match("^(.-)/")
        if folder and type(makefolder) == "function" then
            pcall(makefolder, folder)
        end

        local ok = pcall(writefile, path, loader)
        if ok and type(isfile) == "function" then
            local existsOk, exists = pcall(isfile, path)
            if existsOk and exists then
                return path
            end
        end
    end

    return nil
end

local function removeNativeAutoExec()
    if type(delfile) ~= "function" or type(isfile) ~= "function" then return end
    for _, path in ipairs(AUTOLOAD_CANDIDATES) do
        local ok, exists = pcall(isfile, path)
        if ok and exists then pcall(delfile, path) end
    end
end

local AutoLoadEnabled = readAutoLoadEnabled()

local function refreshAutoLoadVisual()
    setToggleVisual(AutoLoadBtn, "Auto Load on Join", AutoLoadEnabled)
end

local function enableAutoLoad()
    if not saveHubSource() then
        return false, "Your executor cannot save the hub source."
    end

    AutoLoadEnabled = true
    saveAutoLoadEnabled(true)

    local nativePath = tryInstallNativeAutoExec()
    local queued = queueNextTeleport()

    if nativePath then
        return true, "Enabled. Native auto-execute loader installed."
    elseif queued then
        return true, "Enabled for teleports/rejoins. Fresh joins still require your executor's Auto Execute feature."
    end

    AutoLoadEnabled = false
    saveAutoLoadEnabled(false)
    return false, "This executor does not expose Auto Execute or queue-on-teleport to scripts."
end

local function disableAutoLoad()
    AutoLoadEnabled = false
    saveAutoLoadEnabled(false)
    removeNativeAutoExec()
    return true, "Auto Load disabled."
end

AutoLoadBtn.Activated:Connect(function()
    local ok, message
    if AutoLoadEnabled then
        ok, message = disableAutoLoad()
    else
        ok, message = enableAutoLoad()
    end

    refreshAutoLoadVisual()
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "KizzyHub • Auto Load",
            Text = message,
            Duration = 6,
        })
    end)
end)

-- If Auto Load was already enabled, refresh the saved source and queue this hub
-- again for the next server teleport/rejoin.
if AutoLoadEnabled then
    task.spawn(function()
        saveHubSource()
        tryInstallNativeAutoExec()
        queueNextTeleport()
    end)
end

refreshAutoLoadVisual()


-- Webhook 1: High-luck spawn alerts
makeHeader(" Webhook 1 - Egg Spawn Alerts")
local SpawnUrlBox = makeInput("Discord webhook URL for spawn alerts")
local SpawnMinBox = makeInput("Min luck to alert (e.g. 100B)", "100B")
local SpawnToggleBtn, SpawnTestBtn = makeToggleRow()
setToggleVisual(SpawnToggleBtn, "Spawn Alerts", false)

-- Webhook 2: Auto farm claims
makeHeader(" Webhook 2 - Auto Farm Claims")
local FarmUrlBox = makeInput("Discord webhook URL for auto farm claims")
local FarmToggleBtn, FarmTestBtn = makeToggleRow()
setToggleVisual(FarmToggleBtn, "Farm Logs", false)

-- Webhook 3: your hatches
makeHeader(" Webhook 3 - Your Hatches")
local HatchUI = {}
HatchUI.Url = makeInput("Discord webhook URL for your hatches")
HatchUI.Min = makeInput("Min pet luck to notify (blank = every hatch)", "")
HatchUI.Toggle, HatchUI.Test = makeToggleRow()
setToggleVisual(HatchUI.Toggle, "Hatch Alerts", false)

--====================================================
-- SERVER HOP (under webhooks)
--====================================================
do
    local TeleportService = game:GetService("TeleportService")
    local hopBusy = false

    makeHeader(" Server Hop")

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -8, 0, 32)
    row.BackgroundTransparency = 1
    row.LayoutOrder = nextOrder()
    row.Parent = SettingsScroll

    local function hopButton(text, xScale, xOff, wScale, wOff, color)
        local b = Instance.new("TextButton")
        b.Position = UDim2.new(xScale, xOff, 0, 0)
        b.Size = UDim2.new(wScale, wOff, 1, 0)
        b.BackgroundColor3 = color
        b.BorderSizePixel = 0
        b.Font = Enum.Font.GothamBold
        b.Text = text
        b.TextColor3 = Color3.new(1, 1, 1)
        b.TextSize = 11
        b.AutoButtonColor = true
        b.Parent = row
        round(b, 6)
        return b
    end

    local HopAnyBtn = hopButton("Server Hop", 0, 0, 0.5, -3, THEME.Accent)
    local HopSmallBtn = hopButton("Smallest Server", 0.5, 3, 0.5, -3, THEME.Button)

    local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request
        or (fluxus and fluxus.request)

    local function notify(text)
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "KizzyHub • Server Hop",
                Text = text,
                Duration = 5,
            })
        end)
    end

    local function fetchPage(cursor)
        local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&excludeFullGames=true&limit=100")
            :format(game.PlaceId)
        if cursor then url = url .. "&cursor=" .. HttpService:UrlEncode(cursor) end

        local body
        if httpRequest then
            local ok, res = pcall(httpRequest, {Url = url, Method = "GET"})
            if ok and res and res.StatusCode == 200 then body = res.Body end
        end
        if not body then
            local ok, res = pcall(function() return game:HttpGet(url) end)
            if ok then body = res end
        end
        if type(body) ~= "string" then return nil end

        local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
        if ok and type(data) == "table" then return data end
        return nil
    end

    -- Collect joinable servers (not this one, not full). Pages are sorted by
    -- player count ascending, so the first pages hold the emptiest servers.
    local function collectServers(maxPages)
        local list, cursor = {}, nil
        for _ = 1, maxPages do
            local data = fetchPage(cursor)
            if not data then break end
            for _, s in ipairs(data.data or {}) do
                if s.id ~= game.JobId and type(s.playing) == "number"
                    and type(s.maxPlayers) == "number" and s.playing < s.maxPlayers then
                    list[#list + 1] = s
                end
            end
            cursor = data.nextPageCursor
            if not cursor then break end
            task.wait(0.4)
        end
        return list
    end

    local function doHop(smallest)
        if hopBusy then return end
        hopBusy = true
        local btn = smallest and HopSmallBtn or HopAnyBtn
        local oldText = btn.Text
        btn.Text = "Searching..."

        task.spawn(function()
            local servers = collectServers(smallest and 1 or 3)
            local target
            if #servers > 0 then
                if smallest then
                    table.sort(servers, function(a, b) return a.playing < b.playing end)
                    target = servers[1]
                else
                    target = servers[math.random(1, #servers)]
                end
            end

            if not target then
                notify("No other servers found. Try again in a moment.")
                btn.Text = oldText
                hopBusy = false
                return
            end

            -- Keep Auto Load working across the hop (these helpers are defined above).
            if AutoLoadEnabled then
                pcall(saveHubSource)
                pcall(queueNextTeleport)
            end

            btn.Text = "Teleporting..."
            local failConn
            failConn = TeleportService.TeleportInitFailed:Connect(function(player)
                if player ~= LocalPlayer then return end
                if failConn then failConn:Disconnect() end
                notify("Teleport failed. Try again.")
                btn.Text = oldText
                hopBusy = false
            end)

            local ok = pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, target.id, LocalPlayer)
            end)
            if not ok then
                if failConn then failConn:Disconnect() end
                notify("Teleport error. Try again.")
                btn.Text = oldText
                hopBusy = false
                return
            end

            -- Safety reset in case the teleport silently never happens.
            task.delay(15, function()
                if failConn then failConn:Disconnect() end
                if hopBusy then
                    btn.Text = oldText
                    hopBusy = false
                end
            end)
        end)
    end

    HopAnyBtn.Activated:Connect(function() doHop(false) end)
    HopSmallBtn.Activated:Connect(function() doHop(true) end)
end

-- Automation controls intentionally hidden from the Settings tab.
-- Keep the objects alive because existing config/callback code references them.
local UpgradeUI = {}
UpgradeUI.Toggle, UpgradeUI.Now = makeToggleRow()
UpgradeUI.Now.Text = "⬆ Upgrade Now"
setToggleVisual(UpgradeUI.Toggle, "Auto Upgrade", false)
UpgradeUI.Interval = makeInput("Seconds between luck upgrades (min 3, blank = 10)", "")
UpgradeUI.Toggle.Parent.Visible = false
UpgradeUI.Interval.Visible = false

-- Settings remote/debug tools are kept internally for callback compatibility, but hidden from the UI.
local SettingsToolsHeader = makeHeader("Tools")
local ToolBtns = {}
do
    local function toolButton(text)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, -8, 0, 28)
        b.BackgroundColor3 = THEME.Accent
        b.BorderSizePixel = 0
        b.Font = Enum.Font.GothamBold
        b.Text = text
        b.TextColor3 = Color3.new(1, 1, 1)
        b.TextSize = 11
        b.LayoutOrder = nextOrder()
        b.Parent = SettingsScroll
        round(b, 6)
        return b
    end

    ToolBtns.CopyRemotes = toolButton(" Copy All Remotes")
    ToolBtns.PlayerData = toolButton(" Copy Player Data")
    ToolBtns.ScanBox = makeInput("Scan keywords, comma separated (e.g. volcano, dragon, egg)", "volcano, volkaris, dragon, lava")
    ToolBtns.Scan = toolButton(" Copy World Scan")

    ToolBtns.LogToggle, ToolBtns.LogCopy = makeToggleRow()
    ToolBtns.LogCopy.Text = " Copy Log"
    setToggleVisual(ToolBtns.LogToggle, "Remote Logger", false)

    ToolBtns.NoiseToggle, ToolBtns.LogClear = makeToggleRow()
    ToolBtns.LogClear.Text = "Clear Log"
    setToggleVisual(ToolBtns.NoiseToggle, "Hide Noise", true)

    -- Hidden from Settings. Do not destroy these because callbacks later in the script use them.
    SettingsToolsHeader.Visible = false
    ToolBtns.CopyRemotes.Visible = false
    ToolBtns.PlayerData.Visible = false
    ToolBtns.ScanBox.Visible = false
    ToolBtns.Scan.Visible = false
    ToolBtns.LogToggle.Parent.Visible = false
    ToolBtns.NoiseToggle.Parent.Visible = false
end

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -8, 0, 30)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Font = Enum.Font.GothamMedium
StatusLabel.Text = "Status: idle"
StatusLabel.TextColor3 = Color3.fromRGB(170, 170, 190)
StatusLabel.TextSize = 10
StatusLabel.TextWrapped = true
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.TextYAlignment = Enum.TextYAlignment.Top
StatusLabel.LayoutOrder = nextOrder()
StatusLabel.Parent = SettingsScroll

local ActivityLabel = Instance.new("TextLabel")
ActivityLabel.Size = UDim2.new(1, -8, 0, 112)
ActivityLabel.BackgroundTransparency = 1
ActivityLabel.Font = Enum.Font.GothamMedium
ActivityLabel.TextSize = 10
ActivityLabel.TextColor3 = Color3.fromRGB(210, 215, 235)
ActivityLabel.TextXAlignment = Enum.TextXAlignment.Left
ActivityLabel.TextYAlignment = Enum.TextYAlignment.Top
ActivityLabel.TextWrapped = true
ActivityLabel.LayoutOrder = nextOrder()
ActivityLabel.Parent = SettingsScroll
ActivityLabel.Visible = false -- removed from Settings UI; kept so live updates do not error

local RefreshPlotBtn = Instance.new("TextButton")
RefreshPlotBtn.Size = UDim2.new(1, -8, 0, 28)
RefreshPlotBtn.BackgroundColor3 = THEME.Button
RefreshPlotBtn.BorderSizePixel = 0
RefreshPlotBtn.Font = Enum.Font.GothamBold
RefreshPlotBtn.Text = "Refresh Plot Eggs"
RefreshPlotBtn.TextColor3 = Color3.new(1, 1, 1)
RefreshPlotBtn.TextSize = 10
RefreshPlotBtn.LayoutOrder = nextOrder()
RefreshPlotBtn.Parent = SettingsScroll
RefreshPlotBtn.Visible = false -- removed from Settings UI; kept so its handler does not error
round(RefreshPlotBtn, 6)

local DebugBtn = Instance.new("TextButton")
DebugBtn.Size = UDim2.new(1, -8, 0, 28)
DebugBtn.BackgroundColor3 = THEME.Button
DebugBtn.BorderSizePixel = 0
DebugBtn.Font = Enum.Font.GothamBold
DebugBtn.Text = "Copy Debug Info (Selected Egg)"
DebugBtn.TextColor3 = Color3.new(1, 1, 1)
DebugBtn.TextSize = 10
DebugBtn.LayoutOrder = nextOrder()
DebugBtn.Parent = SettingsScroll
DebugBtn.Visible = false -- removed from Settings UI; kept so its handler does not error
round(DebugBtn, 6)



--====================================================
-- FEEDBACK TAB
--====================================================
do
    local FEEDBACK_WEBHOOK = "https://discord.com/api/webhooks/1554789695802703914/rK0Grw8-13TuSj6-4T7oGHdKPgxzJ3Qdpob3eAjLOlKlmBxOP4Tl-mt1TdoxMy_SCX3c"
    local FEEDBACK_COOLDOWN = 24 * 60 * 60
    local FEEDBACK_MAX_CHARS = 1000
    local feedbackFile = "EggHub_Feedback_" .. tostring(LocalPlayer.UserId) .. ".txt"
    local sessionLastFeedback = 0
    local selectedCategory = "Suggestion"
    local submitting = false

    local function trim(text)
        return tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
    end

    local function readLastFeedback()
        local value = sessionLastFeedback
        pcall(function()
            if type(isfile) == "function" and type(readfile) == "function" and isfile(feedbackFile) then
                local saved = tonumber(readfile(feedbackFile))
                if saved then value = math.max(value, saved) end
            end
        end)
        return value
    end

    local function saveLastFeedback(timestamp)
        sessionLastFeedback = timestamp
        pcall(function()
            if type(writefile) == "function" then
                writefile(feedbackFile, tostring(timestamp))
            end
        end)
    end

    local function formatRemaining(seconds)
        seconds = math.max(0, math.ceil(seconds))
        local h = math.floor(seconds / 3600)
        local m = math.floor((seconds % 3600) / 60)
        local sec = seconds % 60
        return string.format("%02dh %02dm %02ds", h, m, sec)
    end

    local FeedbackScroll = Instance.new("ScrollingFrame")
    FeedbackScroll.Size = UDim2.new(1, 0, 1, 0)
    FeedbackScroll.BackgroundTransparency = 1
    FeedbackScroll.BorderSizePixel = 0
    FeedbackScroll.ScrollBarThickness = 3
    FeedbackScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    FeedbackScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    FeedbackScroll.Parent = PanelFeedback

    local FeedbackLayout = Instance.new("UIListLayout")
    FeedbackLayout.SortOrder = Enum.SortOrder.LayoutOrder
    FeedbackLayout.Padding = UDim.new(0, 8)
    FeedbackLayout.Parent = FeedbackScroll

    local HeaderCard = Instance.new("Frame")
    HeaderCard.Size = UDim2.new(1, -8, 0, 70)
    HeaderCard.BackgroundColor3 = THEME.Panel
    HeaderCard.BorderSizePixel = 0
    HeaderCard.LayoutOrder = 1
    HeaderCard.Parent = FeedbackScroll
    round(HeaderCard, 9)

    local Accent = Instance.new("Frame")
    Accent.Size = UDim2.new(0, 4, 1, -14)
    Accent.Position = UDim2.fromOffset(0, 7)
    Accent.BackgroundColor3 = THEME.Accent
    Accent.BorderSizePixel = 0
    Accent.Parent = HeaderCard
    round(Accent, 4)

    local HeaderTitle = Instance.new("TextLabel")
    HeaderTitle.Position = UDim2.fromOffset(14, 9)
    HeaderTitle.Size = UDim2.new(1, -25, 0, 22)
    HeaderTitle.BackgroundTransparency = 1
    HeaderTitle.Font = Enum.Font.GothamBold
    HeaderTitle.Text = "SEND FEEDBACK"
    HeaderTitle.TextColor3 = Color3.fromRGB(240, 242, 255)
    HeaderTitle.TextSize = 14
    HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
    HeaderTitle.Parent = HeaderCard

    local HeaderSub = Instance.new("TextLabel")
    HeaderSub.Position = UDim2.fromOffset(14, 31)
    HeaderSub.Size = UDim2.new(1, -25, 0, 30)
    HeaderSub.BackgroundTransparency = 1
    HeaderSub.Font = Enum.Font.GothamMedium
    HeaderSub.Text = "Found a bug or have an idea? Send it directly to the KizzyHub team. One submission every 24 hours."
    HeaderSub.TextColor3 = Color3.fromRGB(165, 170, 195)
    HeaderSub.TextSize = 10
    HeaderSub.TextWrapped = true
    HeaderSub.TextXAlignment = Enum.TextXAlignment.Left
    HeaderSub.TextYAlignment = Enum.TextYAlignment.Top
    HeaderSub.Parent = HeaderCard

    local CategoryCard = Instance.new("Frame")
    CategoryCard.Size = UDim2.new(1, -8, 0, 64)
    CategoryCard.BackgroundColor3 = THEME.Panel
    CategoryCard.BorderSizePixel = 0
    CategoryCard.LayoutOrder = 2
    CategoryCard.Parent = FeedbackScroll
    round(CategoryCard, 9)

    local CategoryTitle = Instance.new("TextLabel")
    CategoryTitle.Position = UDim2.fromOffset(10, 6)
    CategoryTitle.Size = UDim2.new(1, -20, 0, 18)
    CategoryTitle.BackgroundTransparency = 1
    CategoryTitle.Font = Enum.Font.GothamBold
    CategoryTitle.Text = "FEEDBACK TYPE"
    CategoryTitle.TextColor3 = Color3.fromRGB(150, 185, 255)
    CategoryTitle.TextSize = 10
    CategoryTitle.TextXAlignment = Enum.TextXAlignment.Left
    CategoryTitle.Parent = CategoryCard

    local categories = {"Suggestion", "Bug", "Other"}
    local categoryButtons = {}

    local function refreshCategories()
        for name, button in pairs(categoryButtons) do
            local active = name == selectedCategory
            button.BackgroundColor3 = active and THEME.Accent or THEME.Button
            button.TextColor3 = active and Color3.new(1,1,1) or Color3.fromRGB(185,190,210)
        end
    end

    for index, name in ipairs(categories) do
        local button = Instance.new("TextButton")
        button.Position = UDim2.new((index - 1) / 3, 6, 0, 29)
        button.Size = UDim2.new(1/3, -8, 0, 27)
        button.BackgroundColor3 = THEME.Button
        button.BorderSizePixel = 0
        button.Font = Enum.Font.GothamBold
        button.Text = name
        button.TextColor3 = Color3.fromRGB(185,190,210)
        button.TextSize = 10
        button.Parent = CategoryCard
        round(button, 6)
        categoryButtons[name] = button
        button.MouseButton1Click:Connect(function()
            selectedCategory = name
            refreshCategories()
        end)
    end
    refreshCategories()

    local InputCard = Instance.new("Frame")
    InputCard.Size = UDim2.new(1, -8, 0, 164)
    InputCard.BackgroundColor3 = THEME.Panel
    InputCard.BorderSizePixel = 0
    InputCard.LayoutOrder = 3
    InputCard.Parent = FeedbackScroll
    round(InputCard, 9)

    local InputTitle = Instance.new("TextLabel")
    InputTitle.Position = UDim2.fromOffset(10, 7)
    InputTitle.Size = UDim2.new(1, -20, 0, 18)
    InputTitle.BackgroundTransparency = 1
    InputTitle.Font = Enum.Font.GothamBold
    InputTitle.Text = "YOUR FEEDBACK"
    InputTitle.TextColor3 = Color3.fromRGB(150, 185, 255)
    InputTitle.TextSize = 10
    InputTitle.TextXAlignment = Enum.TextXAlignment.Left
    InputTitle.Parent = InputCard

    local FeedbackBox = Instance.new("TextBox")
    FeedbackBox.Position = UDim2.fromOffset(9, 29)
    FeedbackBox.Size = UDim2.new(1, -18, 0, 104)
    FeedbackBox.BackgroundColor3 = Color3.fromRGB(22, 24, 34)
    FeedbackBox.BorderSizePixel = 0
    FeedbackBox.ClearTextOnFocus = false
    FeedbackBox.MultiLine = true
    FeedbackBox.Text = ""
    FeedbackBox.PlaceholderText = "Tell us what you would like improved, added, or fixed..."
    FeedbackBox.PlaceholderColor3 = Color3.fromRGB(105, 110, 135)
    FeedbackBox.TextColor3 = Color3.fromRGB(235, 237, 248)
    FeedbackBox.Font = Enum.Font.GothamMedium
    FeedbackBox.TextSize = 11
    FeedbackBox.TextWrapped = true
    FeedbackBox.TextXAlignment = Enum.TextXAlignment.Left
    FeedbackBox.TextYAlignment = Enum.TextYAlignment.Top
    FeedbackBox.Parent = InputCard
    round(FeedbackBox, 7)

    local BoxPadding = Instance.new("UIPadding")
    BoxPadding.PaddingTop = UDim.new(0, 8)
    BoxPadding.PaddingBottom = UDim.new(0, 8)
    BoxPadding.PaddingLeft = UDim.new(0, 8)
    BoxPadding.PaddingRight = UDim.new(0, 8)
    BoxPadding.Parent = FeedbackBox

    local CharCount = Instance.new("TextLabel")
    CharCount.AnchorPoint = Vector2.new(1, 0)
    CharCount.Position = UDim2.new(1, -10, 0, 138)
    CharCount.Size = UDim2.fromOffset(120, 18)
    CharCount.BackgroundTransparency = 1
    CharCount.Font = Enum.Font.GothamMedium
    CharCount.Text = "0 / " .. FEEDBACK_MAX_CHARS
    CharCount.TextColor3 = Color3.fromRGB(130, 135, 160)
    CharCount.TextSize = 9
    CharCount.TextXAlignment = Enum.TextXAlignment.Right
    CharCount.Parent = InputCard

    FeedbackBox:GetPropertyChangedSignal("Text"):Connect(function()
        if #FeedbackBox.Text > FEEDBACK_MAX_CHARS then
            FeedbackBox.Text = FeedbackBox.Text:sub(1, FEEDBACK_MAX_CHARS)
            FeedbackBox.CursorPosition = #FeedbackBox.Text + 1
        end
        CharCount.Text = tostring(#FeedbackBox.Text) .. " / " .. FEEDBACK_MAX_CHARS
        CharCount.TextColor3 = #FeedbackBox.Text >= FEEDBACK_MAX_CHARS and Color3.fromRGB(255,145,145) or Color3.fromRGB(130,135,160)
    end)

    local StatusCard = Instance.new("Frame")
    StatusCard.Size = UDim2.new(1, -8, 0, 42)
    StatusCard.BackgroundColor3 = THEME.Panel
    StatusCard.BorderSizePixel = 0
    StatusCard.LayoutOrder = 4
    StatusCard.Parent = FeedbackScroll
    round(StatusCard, 9)

    local CooldownLabel = Instance.new("TextLabel")
    CooldownLabel.Position = UDim2.fromOffset(10, 0)
    CooldownLabel.Size = UDim2.new(1, -20, 1, 0)
    CooldownLabel.BackgroundTransparency = 1
    CooldownLabel.Font = Enum.Font.GothamBold
    CooldownLabel.TextSize = 10
    CooldownLabel.TextXAlignment = Enum.TextXAlignment.Left
    CooldownLabel.Parent = StatusCard

    local SubmitButton = Instance.new("TextButton")
    SubmitButton.Size = UDim2.new(1, -8, 0, 36)
    SubmitButton.BackgroundColor3 = THEME.Accent
    SubmitButton.BorderSizePixel = 0
    SubmitButton.Font = Enum.Font.GothamBold
    SubmitButton.Text = "Submit Feedback"
    SubmitButton.TextColor3 = Color3.new(1, 1, 1)
    SubmitButton.TextSize = 12
    SubmitButton.LayoutOrder = 5
    SubmitButton.Parent = FeedbackScroll
    round(SubmitButton, 8)

    local ResultLabel = Instance.new("TextLabel")
    ResultLabel.Size = UDim2.new(1, -8, 0, 30)
    ResultLabel.BackgroundTransparency = 1
    ResultLabel.Font = Enum.Font.GothamMedium
    ResultLabel.Text = ""
    ResultLabel.TextColor3 = Color3.fromRGB(160, 165, 190)
    ResultLabel.TextSize = 9
    ResultLabel.TextWrapped = true
    ResultLabel.LayoutOrder = 6
    ResultLabel.Parent = FeedbackScroll

    local function updateCooldownUI()
        local remaining = FEEDBACK_COOLDOWN - (os.time() - readLastFeedback())
        if remaining > 0 then
            CooldownLabel.Text = "Next feedback available in  " .. formatRemaining(remaining)
            CooldownLabel.TextColor3 = Color3.fromRGB(255, 190, 105)
            SubmitButton.Text = "Feedback On Cooldown"
            SubmitButton.BackgroundColor3 = Color3.fromRGB(60, 63, 78)
            SubmitButton.AutoButtonColor = false
        else
            CooldownLabel.Text = "Ready to send feedback"
            CooldownLabel.TextColor3 = Color3.fromRGB(115, 225, 155)
            SubmitButton.Text = "Submit Feedback"
            SubmitButton.BackgroundColor3 = THEME.Accent
            SubmitButton.AutoButtonColor = true
        end
    end

    task.spawn(function()
        while Running and PanelFeedback.Parent do
            updateCooldownUI()
            task.wait(1)
        end
    end)

    SubmitButton.MouseButton1Click:Connect(function()
        if submitting then return end

        local feedback = trim(FeedbackBox.Text)
        if #feedback < 5 then
            ResultLabel.Text = "Please enter at least 5 characters before submitting."
            ResultLabel.TextColor3 = Color3.fromRGB(255, 145, 145)
            return
        end

        local remaining = FEEDBACK_COOLDOWN - (os.time() - readLastFeedback())
        if remaining > 0 then
            ResultLabel.Text = "You can send another feedback in " .. formatRemaining(remaining) .. "."
            ResultLabel.TextColor3 = Color3.fromRGB(255, 190, 105)
            updateCooldownUI()
            return
        end

        local requestFn = getExecutorRequest()
        if type(requestFn) ~= "function" then
            ResultLabel.Text = "Feedback could not be sent from this executor."
            ResultLabel.TextColor3 = Color3.fromRGB(255, 145, 145)
            return
        end

        submitting = true
        SubmitButton.Text = "Sending..."
        SubmitButton.AutoButtonColor = false

        task.spawn(function()
            local gameName = "Unknown Game"
            pcall(function()
                local MarketplaceService = game:GetService("MarketplaceService")
                local info = MarketplaceService:GetProductInfo(game.PlaceId)
                if info and info.Name then gameName = tostring(info.Name) end
            end)

            local executorName = "Unknown"
            pcall(function()
                if type(identifyexecutor) == "function" then
                    executorName = tostring(identifyexecutor())
                elseif type(getexecutorname) == "function" then
                    executorName = tostring(getexecutorname())
                end
            end)

            local payload = {
                username = "Ride A Pet | Feedback",
                embeds = {{
                    title = selectedCategory == "Bug" and "New Bug Report" or (selectedCategory == "Suggestion" and "New Suggestion" or "New Feedback"),
                    description = feedback,
                    color = selectedCategory == "Bug" and 15158332 or (selectedCategory == "Suggestion" and 5793266 or 10181046),
                    author = {
                        name = string.format("%s (@%s)", LocalPlayer.DisplayName, LocalPlayer.Name),
                    },
                    fields = {
                        {
                            name = "Feedback Type",
                            value = "**" .. selectedCategory .. "**",
                            inline = true,
                        },
                        {
                            name = "Player",
                            value = string.format("User ID: `%s`\nAccount Age: **%d days**", tostring(LocalPlayer.UserId), tonumber(LocalPlayer.AccountAge) or 0),
                            inline = true,
                        },
                        {
                            name = "Game",
                            value = string.format("**%s**\nPlace ID: `%s`", gameName, tostring(game.PlaceId)),
                            inline = true,
                        },
                        {
                            name = "Session",
                            value = string.format("Executor: **%s**\nPlayers: **%d/%d**", executorName, #Players:GetPlayers(), Players.MaxPlayers),
                            inline = true,
                        },
                        {
                            name = "Server",
                            value = "Job ID: `" .. (game.JobId ~= "" and game.JobId or "Studio / Unknown") .. "`",
                            inline = false,
                        },
                    },
                    footer = {text = "KizzyHub | Feedback"},
                    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                }}
            }

            local ok, response = pcall(function()
                return requestFn({
                    Url = FEEDBACK_WEBHOOK .. "?wait=true",
                    Method = "POST",
                    Headers = {
                        ["Content-Type"] = "application/json",
                        ["Accept"] = "application/json",
                    },
                    Body = HttpService:JSONEncode(payload),
                })
            end)

            local status
            if ok and type(response) == "table" then
                status = tonumber(response.StatusCode or response.Status or response.status_code or response.status)
            end

            if ok and (not status or (status >= 200 and status < 300)) then
                local now = os.time()
                saveLastFeedback(now)
                FeedbackBox.Text = ""
                ResultLabel.Text = "Thanks! Your feedback was sent successfully."
                ResultLabel.TextColor3 = Color3.fromRGB(115, 225, 155)
            else
                ResultLabel.Text = status and ("Could not send feedback. HTTP " .. tostring(status) .. ".") or "Could not send feedback. Please try again."
                ResultLabel.TextColor3 = Color3.fromRGB(255, 145, 145)
            end

            submitting = false
            updateCooldownUI()
        end)
    end)

    updateCooldownUI()
end


--====================================================
-- (old ESP drawing removed - Egg ESP+ in the Pet Tools module replaces it)
--====================================================
local function clearESPVisuals() end
local function updateESP() end

--====================================================
-- ESP EGG REGISTRY (restored for Lite build)
--====================================================
local function registerESPEgg(model)
    if not model or not model.Parent or ESPs[model] then return end
    local part = getRootPart(model)
    if not part then return end

    local luckStr = getEggLuck(model)
    ESPs[model] = {
        Part = part,
        LuckStr = luckStr,
        LuckNum = parseLuck(luckStr),
    }
end

local function unregisterESPEgg(model)
    local data = ESPs[model]
    if data then
        clearESPVisuals(data)
        ESPs[model] = nil
    end
    if SelectedEgg == model then
        SelectedEgg = nil
    end
end

for _, model in ipairs(Folder:GetChildren()) do
    task.defer(registerESPEgg, model)
end

table.insert(Connections, Folder.ChildAdded:Connect(function(model)
    task.wait(0.05)
    registerESPEgg(model)
end))

table.insert(Connections, Folder.ChildRemoved:Connect(function(model)
    unregisterESPEgg(model)
end))


--====================================================
-- OLD WEBHOOK MESSAGE HELPERS / SESSION STATS
--====================================================
local SessionStart=os.time()
local FarmClaimCount,FarmTotalLuck,FarmBestNum=0,0,0
local FarmBestText="None yet"
local GameName="Unknown Game"
task.spawn(function()
    local ok,info=pcall(function() return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId) end)
    if ok and type(info)=="table" and info.Name then GameName=info.Name end
end)
local SHORT_SUFFIXES={{1e18,"Qi"},{1e15,"Qa"},{1e12,"T"},{1e9,"B"},{1e6,"M"},{1e3,"K"}}
local function formatShort(n)
    for _,v in ipairs(SHORT_SUFFIXES) do if n>=v[1] then return string.format("%.2f%s",n/v[1],v[2]) end end
    return tostring(math.floor(n))
end
local function formatCommas(n)
    local rev=string.format("%.0f",n):reverse():gsub("(%d%d%d)","%1,")
    return (rev:reverse():gsub("^,",""))
end
local function formatDuration(sec) return string.format("%dh %02dm",math.floor(sec/3600),math.floor((sec%3600)/60)) end
local function playersText() return string.format("%d/%d",#Players:GetPlayers(),Players.MaxPlayers) end
local function countEggs(minLuck)
    local total,high=0,0
    for m,d in pairs(ESPs) do
        if m.Parent then total+=1 if (d.LuckNum or 0)>=minLuck then high+=1 end end
    end
    return total,high
end

--====================================================
-- ORIGINAL-STYLE WEBHOOK RUNTIME
--====================================================
do
    local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request or (fluxus and fluxus.request)
    local SETTINGS_FILE = "EggHub_Settings.json"
    local SpawnWebhookEnabled = false
    local FarmWebhookEnabled = false
    local HatchWebhookEnabled = false
    local HatchCount = 0

    local function setStatus(text, good)
        StatusLabel.Text = "Status: " .. text
        StatusLabel.TextColor3 = good and Color3.fromRGB(90,255,150) or Color3.fromRGB(255,120,120)
    end

    local function field(name, value, inline)
        return {name=tostring(name), value=tostring(value), inline=inline ~= false}
    end

    local function buildEmbed(info)
        return {embeds={{
            title=info.Title,
            description=info.Description,
            color=info.Color,
            fields=info.Fields,
            author={
                name=string.format("%s (@%s)",LocalPlayer.DisplayName,LocalPlayer.Name),
                icon_url=string.format("https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=150&height=150&format=png",LocalPlayer.UserId),
            },
            timestamp=os.date("!%Y-%m-%dT%H:%M:%SZ"),
            footer={text="KizzyHub • "..info.Footer},
        }}}
    end

    local function sendWebhook(url, payload, label)
        url = tostring(url or ""):match("^%s*(.-)%s*$")
        if url == "" then setStatus((label or "webhook") .. ": URL is empty", false); return false end
        if not httpRequest then setStatus("webhooks unavailable on this executor", false); return false end

        local ok, response = pcall(httpRequest, {
            Url = url,
            Method = "POST",
            Headers = {["Content-Type"]="application/json"},
            Body = HttpService:JSONEncode(payload)
        })
        if not ok then setStatus((label or "webhook") .. " failed", false); return false end

        local code = tonumber(response and (response.StatusCode or response.Status)) or 0
        if code >= 200 and code < 300 then
            setStatus((label or "webhook") .. " sent", true)
            return true
        end
        setStatus((label or "webhook") .. " HTTP " .. tostring(code), false)
        return false
    end

    local function notifySpawn(model,data)
        local isTest=model==nil
        local eggName=isTest and "Test Egg" or model.Name
        local luckStr=isTest and SpawnMinBox.Text or getEggLuck(model)
        local luckNum=parseLuck(luckStr)
        local total,high=countEggs(parseLuck(SpawnMinBox.Text))
        local rank=1
        for m,d in pairs(ESPs) do if m.Parent and (d.LuckNum or 0)>luckNum then rank+=1 end end
        local distText,posText="N/A","N/A"
        if data then
            if data.Part and data.Part.Parent then
                local pos=data.Part.Position
                local root=RootPart
                if root then distText=string.format("%d studs",math.floor((root.Position-pos).Magnitude)) end
                posText=string.format("`%d, %d, %d`",math.floor(pos.X),math.floor(pos.Y),math.floor(pos.Z))
            end
        end
        local autoText=SYSTEM_ENABLED and " ON - will claim" or " OFF"
        sendWebhook(SpawnUrlBox.Text,buildEmbed({
            Title=isTest and " Test - Spawn Alert" or " High Luck Egg Spawned!",
            Description=string.format("**%s** just spawned with ** %s** luck!\nSpawned <t:%d:R>",eggName,luckStr,os.time()),
            Color=isTest and 0x5865F2 or 0xFFD700,Footer="Spawn Alert",
            Fields={
                field(" Egg",eggName),field(" Luck",luckStr),field(" Exact Luck",formatCommas(luckNum)),
                field(" Distance",distText),field(" Position",posText),field(" Rank",string.format("#%d of %d eggs",rank,total)),
                field(" High-Luck Eggs Up",tostring(high)),field(" Auto Farm",autoText),field(" Players",playersText()),
                field(" Game",GameName,false),
                field(" Server",string.format("Place `%d`\nJob `%s`",game.PlaceId,game.JobId~="" and game.JobId or "N/A"),false),
            }
        }),"Spawn alert")
    end

    local function notifyFarmClaim(eggName,luckStr,info)
        info=info or {}
        local luckNum=parseLuck(luckStr)
        if not info.IsTest then
            FarmClaimCount+=1 FarmTotalLuck+=luckNum
            if luckNum>FarmBestNum then FarmBestNum=luckNum FarmBestText=string.format("%s ( %s)",eggName,luckStr) end
        end
        local uptime=os.time()-SessionStart
        local perHour=FarmClaimCount/math.max(uptime/3600,0.05)
        local eggsLeft=countEggs(math.huge)
        sendWebhook(FarmUrlBox.Text,buildEmbed({
            Title=info.IsTest and " Test - Farm Log" or " Auto Farm Claimed Egg!",
            Description=string.format("Claimed **%s** with ** %s** luck\nClaimed <t:%d:R>",eggName,luckStr,os.time()),
            Color=info.IsTest and 0x5865F2 or 0x57F287,Footer="Auto Farm Log",
            Fields={
                field(" Egg",eggName),field(" Luck",luckStr),field(" Exact Luck",formatCommas(luckNum)),
                field(" Claim Time",info.Elapsed and string.format("%.2fs",info.Elapsed) or "N/A"),
                field(" Server Check",info.IsTest and "N/A" or (info.Confirmed and (" Confirmed: "..tostring(info.Confirmed)) or " Unconfirmed (egg vanished)")),
                field(" Attempts",info.Attempts and string.format("%d/%d",info.Attempts,MAX_ATTEMPTS) or "N/A"),
                field(" Eggs Left",tostring(eggsLeft)),field(" Move Mode",MoveMode=="Fly" and " Fly" or " TP"),
                field(" Session Claims",tostring(FarmClaimCount)),field(" Session Total Luck",formatShort(FarmTotalLuck)),
                field(" Claims/Hour",string.format("%.1f",perHour)),field(" Best This Session",FarmBestText,false),
                field(" Uptime",formatDuration(uptime)),field(" Players",playersText()),field(" Game",GameName),
                field(" Server",string.format("Place `%d`\nJob `%s`",game.PlaceId,game.JobId~="" and game.JobId or "N/A"),false),
            }
        }),"Farm log")
    end

    local function notifyHatch(info,isTest)
        local luck=tonumber(info.Luck) or 0
        HatchCount+=isTest and 0 or 1
        local luckText=luck>=1000 and formatShort(luck) or tostring(info.Luck or "?")
        local mutation=info.Mutation and tostring(info.Mutation) or "None"
        sendWebhook(HatchUI.Url.Text,buildEmbed({
            Title=isTest and " Test - Hatch Alert" or " You Hatched a Pet!",
            Description=string.format("**%s** hatched from a **%s**\nHatched <t:%d:R>",tostring(info.PetName or "?"),tostring(info.EggName or "?"),os.time()),
            Color=isTest and 0x5865F2 or (info.Mutation and 0xE91E63 or 0xB57BFF),Footer="Hatch Alert",
            Fields={
                field(" Pet",tostring(info.PetName or "?")),field(" Egg",tostring(info.EggName or "?")),
                field(" Luck",luckText),field(" Weight",info.Weight and string.format("%.2f",info.Weight) or "N/A"),
                field(" Mutation",mutation),field(" Luck Event","x"..tostring(info.LuckEventMultiplier or 1)),
                field(" Age",tostring(info.Age or "N/A")),field(" Session Hatches",tostring(HatchCount)),
                field(" Game",GameName),
                field(" Server",string.format("Place `%d`\nJob `%s`",game.PlaceId,game.JobId~="" and game.JobId or "N/A"),false),
            }
        }),"Hatch alert")
    end

    local function saveSettings()
        if not writefile then return end
        pcall(function()
            writefile(SETTINGS_FILE, HttpService:JSONEncode({
                SpawnUrl=SpawnUrlBox.Text,
                SpawnMin=SpawnMinBox.Text,
                SpawnOn=SpawnWebhookEnabled,
                FarmUrl=FarmUrlBox.Text,
                FarmOn=FarmWebhookEnabled,
                HatchUrl=HatchUI.Url.Text,
                HatchMin=HatchUI.Min.Text,
                HatchOn=HatchWebhookEnabled,
                MoveMode=MoveMode,
                FlySpeed=FlySpeedBox.Text,
                EspOn=EspEnabled,
                EspMin=ESPMinBox.Text,
                EspMax=ESPMaxBox.Text,
                EspOpts=ESPCfg
            }))
        end)
    end

    local function loadSettings()
        if not (isfile and readfile and isfile(SETTINGS_FILE)) then return end
        local ok,data = pcall(function() return HttpService:JSONDecode(readfile(SETTINGS_FILE)) end)
        if not ok or type(data) ~= "table" then return end

        SpawnUrlBox.Text = data.SpawnUrl or ""
        SpawnMinBox.Text = data.SpawnMin or "100B"
        FarmUrlBox.Text = data.FarmUrl or ""
        HatchUI.Url.Text = data.HatchUrl or ""
        HatchUI.Min.Text = data.HatchMin or ""

        SpawnWebhookEnabled = data.SpawnOn == true
        FarmWebhookEnabled = data.FarmOn == true
        HatchWebhookEnabled = data.HatchOn == true

        MoveMode = data.MoveMode == "Fly" and "Fly" or "TP"
        FlySpeedBox.Text = data.FlySpeed or "500"
        EspEnabled = data.EspOn == true
        ESPMinBox.Text = data.EspMin or ""
        ESPMaxBox.Text = data.EspMax or ""

        if type(data.EspOpts) == "table" then
            for key in pairs(ESPCfg) do
                if type(data.EspOpts[key]) == "boolean" then ESPCfg[key] = data.EspOpts[key] end
            end
        end

        setToggleVisual(SpawnToggleBtn,"Spawn Alerts",SpawnWebhookEnabled)
        setToggleVisual(FarmToggleBtn,"Farm Logs",FarmWebhookEnabled)
        setToggleVisual(HatchUI.Toggle,"Hatch Alerts",HatchWebhookEnabled)
        refreshESPControls()
        updateMoveVisual()
    end

    loadSettings()

    MoveModeBtn.MouseButton1Click:Connect(function()
        MoveMode = MoveMode == "TP" and "Fly" or "TP"
        updateMoveVisual()
        saveSettings()
    end)

    SpawnToggleBtn.MouseButton1Click:Connect(function()
        SpawnWebhookEnabled = not SpawnWebhookEnabled
        setToggleVisual(SpawnToggleBtn,"Spawn Alerts",SpawnWebhookEnabled)
        saveSettings()
    end)

    FarmToggleBtn.MouseButton1Click:Connect(function()
        FarmWebhookEnabled = not FarmWebhookEnabled
        setToggleVisual(FarmToggleBtn,"Farm Logs",FarmWebhookEnabled)
        saveSettings()
    end)

    HatchUI.Toggle.MouseButton1Click:Connect(function()
        HatchWebhookEnabled = not HatchWebhookEnabled
        setToggleVisual(HatchUI.Toggle,"Hatch Alerts",HatchWebhookEnabled)
        saveSettings()
    end)

    SpawnTestBtn.MouseButton1Click:Connect(function() notifySpawn(nil,nil) end)
    FarmTestBtn.MouseButton1Click:Connect(function()
        notifyFarmClaim("Test Egg","100B",{Attempts=1,Elapsed=0.42,IsTest=true})
    end)
    HatchUI.Test.MouseButton1Click:Connect(function()
        notifyHatch({PetName="Kangaroo",EggName="Stone Egg",Luck=200,Weight=14.5,LuckEventMultiplier=1,Age=1},true)
    end)

    for _,box in ipairs({SpawnUrlBox,SpawnMinBox,FarmUrlBox,HatchUI.Url,HatchUI.Min,FlySpeedBox,ESPMinBox,ESPMaxBox}) do
        box.FocusLost:Connect(saveSettings)
    end
    onESPSettingChanged = saveSettings

    MainFarmWebhookClaim = function(eggName,luckStr,info)
        if FarmWebhookEnabled then notifyFarmClaim(eggName,luckStr,info) end
    end

    -- Spawn alerts use the existing RenderedEggs folder and old ESP data.
    table.insert(Connections, Folder.ChildAdded:Connect(function(model)
        task.wait(0.15)
        if not SpawnWebhookEnabled or not model.Parent then return end
        local luck = getEggLuck(model)
        if parseLuck(luck) >= parseLuck(SpawnMinBox.Text) then
            notifySpawn(model, ESPs[model])
        end
    end))

    -- Hatch alerts use the same game Hatch remote as the old code.
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local gameFolder = remotes and remotes:FindFirstChild("Game")
    local hatchRemote = gameFolder and gameFolder:FindFirstChild("Hatch")
    if hatchRemote and hatchRemote:IsA("RemoteEvent") then
        table.insert(Connections,hatchRemote.OnClientEvent:Connect(function(info)
            if type(info) ~= "table" then return end
            local owner = info.Owner
            if owner ~= LocalPlayer and owner ~= LocalPlayer.UserId then return end

            HatchCount += 1
            ActivityLabel.Text = "Confirmed pickups: -- | Last: --\nSatchel: unverified | Plot eggs: --\nHatches: "..HatchCount.." | Arrival: --\nVolcano: active"

            if HatchWebhookEnabled and (tonumber(info.Luck) or 0) >= parseLuck(HatchUI.Min.Text) then
                notifyHatch(info,false)
            end
        end))
    end

    RefreshPlotBtn.MouseButton1Click:Connect(function()
        local r = gameFolder and gameFolder:FindFirstChild("RequestPlotEggs")
        if r and r:IsA("RemoteEvent") then
            r:FireServer(false)
            setStatus("requested plot snapshot",true)
        else
            setStatus("RequestPlotEggs unavailable",false)
        end
    end)

    DebugBtn.MouseButton1Click:Connect(function()
        local text = "Selected Egg: "..tostring(SelectedEgg and SelectedEgg.Name or "none")
            .."\nMove Mode: "..tostring(MoveMode)
            .."\nESP: "..tostring(EspEnabled)
            .."\nBase: "..tostring(BaseName)
        if setclipboard then
            setclipboard(text)
            setStatus("debug info copied",true)
        else
            setStatus("clipboard unavailable",false)
        end
    end)

    StatusLabel.Text = "Status: idle"
end

--====================================================
-- EGG & VOLCANO ACTIVITY - LIVE LITE BRIDGE
--====================================================
do
    local Activity = {
        Pickups = 0,
        LastPickup = "None",
        Hatches = 0,
        Arrival = "Idle",
        Volcano = "Idle",
        LastFolderCount = #Folder:GetChildren(),
    }

    local function plotEggCount()
        local plots = workspace:FindFirstChild("Plots")
        if not plots then return "?" end

        for _, plot in ipairs(plots:GetChildren()) do
            local owner = plot:FindFirstChild("Owner")
            local mine = false
            if owner then
                if owner:IsA("ObjectValue") then
                    mine = owner.Value == LocalPlayer
                elseif owner:IsA("StringValue") then
                    mine = owner.Value == LocalPlayer.Name or owner.Value == tostring(LocalPlayer.UserId)
                elseif owner:IsA("IntValue") or owner:IsA("NumberValue") then
                    mine = tonumber(owner.Value) == LocalPlayer.UserId
                end
            end
            if mine then
                local eggs = plot:FindFirstChild("Eggs")
                return eggs and #eggs:GetChildren() or 0
            end
        end
        return "?"
    end

    local function volcanoStatus()
        local root = RootPart
        if not root or not root.Parent then
            local char = LocalPlayer.Character
            root = char and char:FindFirstChild("HumanoidRootPart")
        end

        local volcano = workspace:FindFirstChild("Volcano")
        local top = volcano and volcano:FindFirstChild("VolcanoTop")
        if not root or not top then return Activity.Volcano end

        local pos
        if top:IsA("BasePart") then
            pos = top.Position
        elseif top:IsA("Model") then
            pos = top:GetPivot().Position
        end
        if not pos then return Activity.Volcano end

        local dist = (root.Position - pos).Magnitude
        if dist <= 10 then return "At VolcanoTop / dipping" end
        if dist <= 100 then return "Near VolcanoTop" end
        return Activity.Volcano
    end

    local function refreshActivity()
        ActivityLabel.Text = string.format(
            "Confirmed pickups: %s | Last: %s\nRendered eggs: %s | Plot eggs: %s\nHatches: %s | Arrival: %s\nVolcano: %s",
            tostring(Activity.Pickups),
            tostring(Activity.LastPickup),
            tostring(#Folder:GetChildren()),
            tostring(plotEggCount()),
            tostring(Activity.Hatches),
            tostring(Activity.Arrival),
            tostring(volcanoStatus())
        )
    end

    -- A RenderedEgg disappearing is the same event the Lite collector relies on
    -- after reaching/collecting an egg, so use it for the live pickup display.
    table.insert(Connections, Folder.ChildRemoved:Connect(function(egg)
        Activity.Pickups += 1
        Activity.LastPickup = egg and egg.Name or "Egg"
        Activity.Arrival = "Pickup confirmed"
        refreshActivity()
    end))

    table.insert(Connections, Folder.ChildAdded:Connect(function(egg)
        Activity.Arrival = "Egg spawned: " .. tostring(egg.Name)
        refreshActivity()
    end))

    -- Observe the existing VolcanoDip remote response/event when available.
    local packages = ReplicatedStorage:FindFirstChild("packages")
    local net = packages and packages:FindFirstChild("Net")
    local dip = net and net:FindFirstChild("RE/VolcanoDip")
    if dip and dip:IsA("RemoteEvent") then
        table.insert(Connections, dip.OnClientEvent:Connect(function()
            Activity.Volcano = "Dip registered"
            refreshActivity()
        end))
    end

    -- Count local hatch notifications independently of webhook enable state.
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local gameFolder = remotes and remotes:FindFirstChild("Game")
    local hatchRemote = gameFolder and gameFolder:FindFirstChild("Hatch")
    if hatchRemote and hatchRemote:IsA("RemoteEvent") then
        table.insert(Connections, hatchRemote.OnClientEvent:Connect(function(info)
            if type(info) ~= "table" then return end
            local owner = info.Owner
            if owner == LocalPlayer or owner == LocalPlayer.UserId
                or tostring(owner) == tostring(LocalPlayer.UserId)
                or tostring(owner) == LocalPlayer.Name then
                Activity.Hatches += 1
                Activity.Arrival = "Hatched: " .. tostring(info.PetName or "Pet")
                refreshActivity()
            end
        end))
    end

    task.spawn(function()
        while Running do
            task.wait(0.5)
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then
                RootPart = root
            end

            local v = volcanoStatus()
            if v == "At VolcanoTop / dipping" or v == "Near VolcanoTop" then
                Activity.Volcano = v
            elseif not Claiming then
                Activity.Volcano = "Idle"
            end

            refreshActivity()
        end
    end)

    refreshActivity()
end

--====================================================
-- PET TOOLS MODULE: Best Pets / Food / Sell + Favorites / Egg ESP+
-- Ported from the "RideAPetCompact" script. Kept self-contained in one do-block
-- so it adds almost no top-level locals to this large chunk.
--====================================================
do
local Env = getgenv and getgenv() or _G
if Env.PetToolsUnload then pcall(Env.PetToolsUnload) end

HubMisc = HubMisc or { Moving = false }
local HM = HubMisc

PT = {
    Alive = true, Ready = false, Epoch = 0, Job = nil, JobThread = nil,
    Status = "Loading pet tools...", Cooldowns = {}, Markers = {}, Errors = {},
    Redraws = {}, Placed = 0,
    FoodBought = 0, FoodFed = 0, SoldPets = 0, FavoritedPets = 0,
    FoodStatus = "Choose food and a pet", SellStatus = "Ready",
    FavoriteRequests = {}, FavTypes = {}, FavRarities = {}, ESPRarities = {},
    FoodBuyItems = { Grass = true }, FoodFeedItems = { Grass = true }, FoodFeedPets = {},
    RarityNames = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Ethereal" },
    RarityColors = {
        Common = Color3.fromRGB(230,235,237), Rare = Color3.fromRGB(100,195,255),
        Epic = Color3.fromRGB(197,145,255), Legendary = Color3.fromRGB(255,213,104),
        Mythic = Color3.fromRGB(255,125,160), Divine = Color3.fromRGB(255,245,182),
        Ethereal = Color3.fromRGB(120,255,215),
    },
    Options = {
        AutoBest = false, BestMetric = "Income", TweenSpeed = 180,
        AutoBuyFood = false, AutoFeed = false, ManualFeedCount = 1,
        AutoFavorites = false, AutoSell = false,
        ESP = false, ESPName = true, ESPRarity = true, ESPDistance = true, ESPWeight = true,
        ESPMutation = true, ESPLuck = true, ESPBoxes = false, ESPTracers = false,
        ESPMaxDistance = 5000, ESPCount = 40, ESPSize = 13, ESPMinLuck = 0, ESPMutatedOnly = false,
    },
}
for _, r in ipairs(PT.RarityNames) do PT.ESPRarities[r] = true end

--------------------------------------------------------------------
-- Small helpers
--------------------------------------------------------------------
function PT:Notify(text)
    pcall(function()
        StarterGui:SetCore("SendNotification", { Title = "PET TOOLS", Text = text, Duration = 3 })
    end)
end

function PT:Err(context, message)
    local v = context .. ": " .. tostring(message)
    self.Status = v
    if self.Errors[#self.Errors] ~= v then
        table.insert(self.Errors, v)
        if #self.Errors > 8 then table.remove(self.Errors, 1) end
        warn("[PetTools] " .. v)
    end
end

function PT:Format(value)
    value = tonumber(value)
    if not value then return "?" end
    if value == math.huge then return "Unlimited" end
    for _, unit in ipairs({ {1e12, "T"}, {1e9, "B"}, {1e6, "M"}, {1e3, "K"} }) do
        if math.abs(value) >= unit[1] then return string.format("%.2f%s", value / unit[1], unit[2]) end
    end
    return (string.format("%.2f", value):gsub("%.?0+$", ""))
end

function PT:Count(set)
    local n = 0
    for _, v in pairs(set) do if v then n = n + 1 end end
    return n
end

-- True when the volcano route / claim system / another hub system owns movement.
function PT:Blocked()
    return VolcanoRouteActive or Claiming or (HM.Moving and not self.Job)
end

function PT:Live()
    return self.Alive and Running
end

function PT:Valid(token)
    return self.Alive and Running and self.Epoch == token and not VolcanoRouteActive
end

function PT:Ready1(key, interval)
    local now = os.clock()
    if now < (self.Cooldowns[key] or 0) then return false end
    self.Cooldowns[key] = now + interval
    return true
end

function PT:WaitFor(predicate, seconds, token)
    local deadline = os.clock() + seconds
    repeat
        if token and not self:Valid(token) then return false end
        if not self.Alive then return false end
        local ok, value = pcall(predicate)
        if ok and value then return value end
        task.wait(0.1)
    until os.clock() >= deadline
    return false
end

--------------------------------------------------------------------
-- Game access
--------------------------------------------------------------------
function PT:Character()
    local c = LocalPlayer.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    local r = c and c:FindFirstChild("HumanoidRootPart")
    if h and r and h.Health > 0 then return c, h, r end
end

function PT:Value(name, default)
    local v = self.Saved and self.Saved:FindFirstChild(name)
    if v then return v.Value end
    return default
end

function PT:Plot()
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil end
    for _, plot in ipairs(plots:GetChildren()) do
        local data = plot:FindFirstChild("Data")
        local owner = data and data:FindFirstChild("Owner")
        if owner then
            local mine = false
            if owner:IsA("ObjectValue") then mine = owner.Value == LocalPlayer
            elseif owner:IsA("StringValue") then mine = owner.Value == LocalPlayer.Name or owner.Value == LocalPlayer.DisplayName
            elseif owner:IsA("IntValue") or owner:IsA("NumberValue") then mine = owner.Value == LocalPlayer.UserId end
            if mine then return plot end
        end
    end
end

function PT:OnPlot()
    local _, _, root = self:Character()
    local plot = self:Plot()
    local base = plot and plot:FindFirstChild("Baseplate")
    if not root or not base then return false end
    local p = base.CFrame:PointToObjectSpace(root.Position)
    return math.abs(p.X) < base.Size.X / 2 and math.abs(p.Z) < base.Size.Z / 2 and math.abs(p.Y) < 35
end

function PT:Tools()
    local result = {}
    for _, holder in ipairs({ LocalPlayer:FindFirstChild("Backpack"), LocalPlayer.Character }) do
        if holder then
            for _, item in ipairs(holder:GetChildren()) do
                if item:IsA("Tool") then table.insert(result, item) end
            end
        end
    end
    return result
end

function PT:Tool(name, key)
    for _, tool in ipairs(self:Tools()) do
        if (not name or tool.Name == name) and (not key or tool:GetAttribute("PetKey") == key) then return tool end
    end
end

function PT:Equip(tool)
    local _, humanoid = self:Character()
    if humanoid and tool and tool.Parent then humanoid:EquipTool(tool) return true end
    return false
end

function PT:Fire(name, ...)
    if not self.Alive or not self.Remotes then return false end
    local remote = self.Remotes:FindFirstChild(name)
    if not remote or not remote:IsA("RemoteEvent") then return false end
    remote:FireServer(...)
    return true
end

function PT:Dismount(token)
    if LocalPlayer:GetAttribute("IsRiding") then
        self:Fire("PetDismount")
        return self:WaitFor(function() return not LocalPlayer:GetAttribute("IsRiding") end, 3, token)
    end
    return true
end

--------------------------------------------------------------------
-- Movement (tween flight, cancels instantly if the volcano route starts)
--------------------------------------------------------------------
function PT:StopMovement()
    if self.FlightConnection then self.FlightConnection:Disconnect() self.FlightConnection = nil end
    if self.FlightTween then pcall(function() self.FlightTween:Cancel() self.FlightTween:Destroy() end) self.FlightTween = nil end
    local f = self.Flight
    self.Flight = nil
    if f then
        for part, value in pairs(f.Collisions) do if part.Parent then part.CanCollide = value end end
        if f.Humanoid.Parent then
            f.Humanoid.PlatformStand = f.PlatformStand
            f.Humanoid.AutoRotate = f.AutoRotate
        end
        if f.Root.Parent then
            f.Root.AssemblyLinearVelocity = Vector3.zero
            f.Root.AssemblyAngularVelocity = Vector3.zero
        end
    end
end

function PT:MoveTo(position, token, radius)
    if not self:Valid(token) or not self:Dismount(token) then return false end
    local character, humanoid, root = self:Character()
    if not root then return false end
    self:StopMovement()
    humanoid:UnequipTools()
    local target = position + Vector3.new(0, math.max(3, humanoid.HipHeight + root.Size.Y / 2), 0)
    local collisions = {}
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then collisions[part] = part.CanCollide end
    end
    self.Flight = { Root = root, Humanoid = humanoid, Collisions = collisions, PlatformStand = humanoid.PlatformStand, AutoRotate = humanoid.AutoRotate }
    humanoid.PlatformStand = true
    humanoid.AutoRotate = false
    local speed = math.clamp(self.Options.TweenSpeed, 40, 350)
    local duration = math.max(0.1, (root.Position - target).Magnitude / speed)
    local tween = TweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Linear), { CFrame = CFrame.new(target) * root.CFrame.Rotation })
    self.FlightTween = tween
    self.FlightConnection = RunService.Stepped:Connect(function()
        if root.Parent and humanoid.Health > 0 then
            for part in pairs(collisions) do if part.Parent then part.CanCollide = false end end
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end
    end)
    tween:Play()
    local deadline = os.clock() + duration + 3
    while self:Valid(token) and root.Parent and humanoid.Health > 0 and os.clock() < deadline
        and tween.PlaybackState == Enum.PlaybackState.Playing do
        self.Status = "Flying | " .. self:Format((root.Position - target).Magnitude) .. " studs left"
        task.wait(0.05)
    end
    local completed = tween.PlaybackState == Enum.PlaybackState.Completed
    self:StopMovement()
    if not completed or not self:Valid(token) then return false end
    task.wait(0.1)
    local _, _, current = self:Character()
    if current ~= root or (root.Position - target).Magnitude > math.max(radius or 9, 12) then
        self.Status = "Server rejected movement; will retry"
        return false
    end
    return true
end

function PT:Home(token)
    if not self:Valid(token) then return false end
    if self:OnPlot() then return true end
    local plot = self:Plot()
    local base = plot and plot:FindFirstChild("Baseplate")
    if not base then return false end
    return self:MoveTo(base.Position + Vector3.new(0, 3, 0), token, 12)
end

--------------------------------------------------------------------
-- Job system (one action at a time, cancellable)
--------------------------------------------------------------------
function PT:CancelJob()
    self.Epoch = self.Epoch + 1
    local th = self.JobThread
    self.JobThread = nil
    if self.Job then HM.Moving = false end
    HM.PetJob = false
    self.Job = nil
    self:StopMovement()
    if th and th ~= coroutine.running() then pcall(task.cancel, th) end
end

function PT:StartJob(name, callback)
    if not self.Alive or self.Job or not self.Ready then return false end
    if self:Blocked() then return false end
    local token = self.Epoch
    self.Job = name
    self.Status = name
    HM.Moving = true
    HM.PetJob = true
    self.JobThread = task.spawn(function()
        local ok, err = xpcall(function() callback(token) end, debug.traceback)
        if not ok and self.Epoch == token then self:Err(name, err) end
        if self.Epoch == token then
            self:StopMovement()
            self.Job = nil
            self.JobThread = nil
            HM.Moving = false
            HM.PetJob = false
        end
    end)
    return true
end

--------------------------------------------------------------------
-- Pets (list + Auto Place Best Pets)
--------------------------------------------------------------------
function PT:PetList()
    local result, seen = {}, {}
    local D, S = self.Data, self.Services
    local function add(object, state, placed)
        local key = object:GetAttribute("PetKey")
        local name = object:GetAttribute("PetName") or object.Name
        local data = D.Pets[name]
        if not key or type(data) ~= "table" or seen[key] then return end
        seen[key] = true
        local age = object:GetAttribute("Age") or (state and state.CurrentAge) or 1
        local weight = object:GetAttribute("Weight") or 10
        local mutation = object:GetAttribute("Mutation")
        local spawnMutation = object:GetAttribute("SpawnMutation")
        local factor = 1
        pcall(function() factor = D.Mutations.CombinedFactor(mutation, spawnMutation) or 1 end)
        local income = state and (state.DisplayIncome or state.Income)
        if not income then income = (data.Income or 0) * weight / 10 * factor end
        local speed = 0
        pcall(function() speed = S.PetAging.DisplaySpeedFor(data.Speed or 0, weight) * factor end)
        table.insert(result, {
            Key = key, Name = name, Object = object, State = state, Placed = placed, Age = age,
            Weight = weight, Income = income, Speed = speed, Rarity = data.Rarity,
            Mutation = mutation, Favorite = object:GetAttribute("Favorited") == true,
        })
    end
    if self.Renderer then
        pcall(function()
            for _, state in pairs(self.Renderer.GetAll()) do
                if state.OwnerUserId == LocalPlayer.UserId and state.Model and state.Model.Parent then
                    add(state.Model, state, true)
                end
            end
        end)
    end
    local plot = self:Plot()
    if plot and plot:FindFirstChild("Pets") then
        for _, pet in ipairs(plot.Pets:GetChildren()) do add(pet, nil, true) end
    end
    for _, tool in ipairs(self:Tools()) do add(tool, nil, false) end
    local _, _, root = self:Character()
    local joint = root and root:FindFirstChild("PetMountJoint")
    if joint and joint.Part1 then add(joint.Part1.Parent, nil, false) end
    table.sort(result, function(a, b) return a.Income > b.Income end)
    return result
end

function PT:PlaceBest(token)
    if not self:Home(token) or not self:Dismount(token) then return end

    local metric = self.Options.BestMetric
    local pets = self:PetList()
    if #pets == 0 then
        self.Status = "No owned pets were detected"
        return
    end

    table.sort(pets, function(a, b)
        local av = metric == "Speed" and (a.Speed or 0) or (a.Income or 0)
        local bv = metric == "Speed" and (b.Speed or 0) or (b.Income or 0)
        if av == bv then return tostring(a.Key) < tostring(b.Key) end
        return av > bv
    end)

    local capacity = tonumber(LocalPlayer:GetAttribute("MaxPets"))
        or tonumber(self:Value("MaxPets", 5))
        or 5
    capacity = math.max(1, math.floor(capacity))

    local desired, desiredOrder = {}, {}
    for i = 1, math.min(capacity, #pets) do
        desired[pets[i].Key] = true
        desiredOrder[#desiredOrder + 1] = pets[i].Key
    end

    -- Pick up every placed pet that is not part of the best set.
    for _, pet in ipairs(self:PetList()) do
        if not self:Valid(token) then return end
        if pet.Placed and not desired[pet.Key] then
            self.Status = "Picking up " .. tostring(pet.Name)
            if not self:Fire("PickupPet", pet.Key) then
                self:Err("Auto Best", "PickupPet remote is unavailable")
                return
            end
            if not self:WaitFor(function()
                return self:Tool(nil, pet.Key) ~= nil
            end, 4, token) then
                self:Err("Auto Best", "Pickup was not confirmed for " .. tostring(pet.Name))
                return
            end
            task.wait(0.1)
        end
    end

    local plot = self:Plot()
    local base = plot and plot:FindFirstChild("Baseplate")
    if not base then
        self:Err("Auto Best", "Your plot Baseplate was not found")
        return
    end

    -- Re-read after pickups. This avoids stale Placed state.
    local current = {}
    for _, pet in ipairs(self:PetList()) do current[pet.Key] = pet end

    for i, key in ipairs(desiredOrder) do
        if not self:Valid(token) then return end
        local pet = current[key]

        if not pet or not pet.Placed then
            local tool = self:Tool(nil, key)
            if not tool then
                -- Inventory can update a frame later after PickupPet.
                self:WaitFor(function() return self:Tool(nil, key) end, 2, token)
                tool = self:Tool(nil, key)
            end

            if tool then
                self.Status = "Placing " .. tostring(tool:GetAttribute("PetName") or tool.Name)
                self:Equip(tool)
                task.wait(0.15)
                if not self:Valid(token) then return end

                local cols = math.max(1, math.ceil(math.sqrt(capacity)))
                local spacing = math.max(3, math.min(9, (math.min(base.Size.X, base.Size.Z) - 12) / cols))
                local row = math.floor((i - 1) / cols)
                local col = (i - 1) % cols
                local x = (col - (cols - 1) / 2) * spacing
                local z = (row - (cols - 1) / 2) * spacing
                local pos = (base.CFrame * CFrame.new(x, 4, z)).Position

                if not self:Fire("PlacePet", key, pos) then
                    self:Err("Auto Best", "PlacePet remote is unavailable")
                    return
                end

                local confirmed = self:WaitFor(function()
                    for _, owned in ipairs(self:PetList()) do
                        if owned.Key == key and owned.Placed then return true end
                    end
                    return false
                end, 4, token)

                if not confirmed then
                    self:Err("Auto Best", "Placement was not confirmed for " .. tostring(tool.Name))
                    return
                end

                self.Placed = (self.Placed or 0) + 1
                task.wait(0.1)
            else
                self:Err("Auto Best", "Could not find pet tool for key " .. tostring(key))
                return
            end
        end
    end

    local placedBest = 0
    for _, pet in ipairs(self:PetList()) do
        if pet.Placed and desired[pet.Key] then placedBest += 1 end
    end
    self.Status = string.format("Best pets placed by %s (%d/%d)", string.lower(metric), placedBest, math.min(capacity, #pets))
end

--------------------------------------------------------------------
-- Food (auto buy + auto feed)
--------------------------------------------------------------------
function PT:FoodAmount(tool)
    if not tool or not tool.Parent then return 0 end
    local data = tool:FindFirstChild("Data")
    local amount = data and data:FindFirstChild("Amount")
    if amount and amount:IsA("ValueBase") then return math.max(0, math.floor(tonumber(amount.Value) or 0)) end
    return 1
end

function PT:FoodCount(name)
    local count = 0
    for _, tool in ipairs(self:Tools()) do if tool.Name == name then count = count + self:FoodAmount(tool) end end
    return count
end

function PT:FoodStock(name)
    local main = LocalPlayer.PlayerGui:FindFirstChild("Main")
    local shop = main and main:FindFirstChild("Shop")
    local holders = shop and shop:FindFirstChild("Holders")
    local food = holders and holders:FindFirstChild("Food")
    local card = food and food:FindFirstChild(name)
    local stock = card and card:FindFirstChild("Stock", true)
    if stock and stock:IsA("TextLabel") then return tonumber(stock.Text:match("(%d+)")) end
    return nil
end

function PT:CanBuyFood(name)
    local item = self.Data.Shop.Food[name]
    if not item or type(item.Price) ~= "number" then return false, "Choose an available food" end
    local stock = self:FoodStock(name)
    if stock == nil then return false, "Open the game's Food shop once to load stock" end
    if stock <= 0 then return false, name .. " is out of stock" end
    if (tonumber(self:Value("Cash", 0)) or 0) < item.Price then return false, "Not enough cash" end
    return true
end

function PT:NextFoodPurchase()
    local reason, start = "Choose foods to buy", 0
    for i, name in ipairs(self.FoodNames) do if name == self.LastFoodPurchase then start = i break end end
    for step = 1, #self.FoodNames do
        local name = self.FoodNames[(start + step - 1) % #self.FoodNames + 1]
        if self.FoodBuyItems[name] then
            local allowed, message = self:CanBuyFood(name)
            if allowed then return name end
            reason = message
        end
    end
    self.FoodStatus = reason
    return nil
end

function PT:BuyFood(token, name, amount, automatic)
    amount = math.clamp(math.floor(amount or 1), 1, 100)
    local bought = 0
    for _ = 1, amount do
        if not self:Valid(token) or not self.FoodBuyItems[name] or (automatic and not self.Options.AutoBuyFood) then return false end
        local allowed, reason = self:CanBuyFood(name)
        if not allowed then self.FoodStatus = reason break end
        local before = self:FoodCount(name)
        self.FoodStatus = "Buying " .. name
        self:Fire("BuyWithCash", "Food", name)
        local confirmed = self:WaitFor(function() return self:FoodCount(name) > before end, 3, token)
        if not confirmed then
            self.FoodStatus = "Purchase not confirmed; retrying later"
            if automatic then self.Cooldowns.FoodShop = os.clock() + 2 end
            break
        end
        self.FoodBought = self.FoodBought + 1
        self.LastFoodPurchase = name
        bought = bought + 1
        self.FoodStatus = "Bought " .. name .. " x" .. bought
        if bought < amount then task.wait(0.15) end
    end
    self.Status = self.FoodStatus
    return bought > 0
end

function PT:BuySelectedFoods(token)
    local selected, before = 0, self.FoodBought
    for _, name in ipairs(self.FoodNames) do
        if not self:Valid(token) then return false end
        if self.FoodBuyItems[name] then selected = selected + 1 self:BuyFood(token, name, 1, false) end
    end
    if selected == 0 then self.FoodStatus = "Choose foods to buy"
    elseif self.FoodBought > before then self.FoodStatus = "Bought " .. (self.FoodBought - before) .. " food portions" end
    self.Status = self.FoodStatus
end

function PT:FindPet(key)
    for _, pet in ipairs(self:PetList()) do if pet.Key == key then return pet end end
end

function PT:MaxAge()
    return (self.Services.PetAging and self.Services.PetAging.MaxAge) or 100
end

function PT:CanFeedPet(key, name)
    local pet = self:FindPet(key)
    if not pet then return false, "Choose an owned pet first" end
    if pet.Age >= self:MaxAge() then return false, pet.Name .. " is at max age" end
    if self:FoodCount(name) <= 0 then return false, "No " .. tostring(name) .. " in inventory" end
    return true
end

function PT:NextFeedingFood()
    local start, selected = 0, 0
    for i, name in ipairs(self.FoodNames) do if name == self.LastFedFood then start = i break end end
    for step = 1, #self.FoodNames do
        local name = self.FoodNames[(start + step - 1) % #self.FoodNames + 1]
        if self.FoodFeedItems[name] then
            selected = selected + 1
            if self:FoodCount(name) > 0 then return name end
        end
    end
    return nil, selected > 0 and "No chosen feeding food in inventory" or "Choose foods for feeding"
end

function PT:NextFoodPet()
    local candidates, selected = {}, 0
    for _, pet in ipairs(self:PetList()) do
        if self.FoodFeedPets[pet.Key] then
            selected = selected + 1
            if pet.Age < self:MaxAge() then candidates[#candidates + 1] = pet end
        end
    end
    if selected == 0 then self.FoodStatus = "Choose pets to feed" return nil end
    if #candidates == 0 then self.FoodStatus = "Chosen pets are at max age" return nil end
    table.sort(candidates, function(a, b) return a.Key < b.Key end)
    local chosen = candidates[1]
    for _, pet in ipairs(candidates) do
        if not self.LastAutoFedPet or pet.Key > self.LastAutoFedPet then chosen = pet break end
    end
    local name, message = self:NextFeedingFood()
    if not name then self.FoodStatus = message return nil end
    local allowed, reason = self:CanFeedPet(chosen.Key, name)
    if not allowed then self.FoodStatus = reason return nil end
    return chosen.Key
end

function PT:FeedPet(token, automatic, key)
    local function finish(success, message)
        if message then self.FoodStatus = message self.Status = message end
        return success
    end
    local name, message = self:NextFeedingFood()
    if not name then return finish(false, message) end
    local function active()
        return self:Valid(token) and self.FoodFeedItems[name] == true and self.FoodFeedPets[key] == true
            and (not automatic or self.Options.AutoFeed)
    end
    if not active() then return finish(false) end
    local allowed, reason = self:CanFeedPet(key, name)
    if not allowed then return finish(false, reason) end
    local pet = self:FindPet(key)
    local food = self:Tool(name)
    if pet.Placed and pet.Object:IsA("Model") then
        local _, _, root = self:Character()
        if not root then return finish(false) end
        local position = pet.Object:GetPivot().Position
        if (root.Position - position).Magnitude > 18 and not self:MoveTo(position, token, 10) then return finish(false) end
    end
    self:Equip(food)
    task.wait(0.15)
    if not active() then return finish(false) end
    allowed, reason = self:CanFeedPet(key, name)
    if not allowed then return finish(false, reason) end
    local before = self:FoodAmount(food)
    if before <= 0 then return finish(false, "Food is no longer available") end
    self:Fire("FeedPet", key, name)
    local consumed = self:WaitFor(function() return self:FoodAmount(food) < before end, 3, token)
    if not self:Valid(token) then return finish(false) end
    if not consumed then return finish(false, "Feeding not confirmed. Place the pet on your ranch and retry.") end
    self.FoodFed = self.FoodFed + 1
    self.LastFedFood = name
    self.FoodStatus = "Fed " .. pet.Name .. " | " .. name
    self.Status = self.FoodStatus
    task.wait(0.35)
    return finish(true)
end

function PT:FeedSelectedPets(token, amount)
    amount = math.clamp(math.floor(tonumber(amount) or 1), 1, 1000)
    local selected, fed, fedPets, partial = 0, 0, 0, false
    for _, pet in ipairs(self:PetList()) do
        if not self:Valid(token) then return end
        if self.FoodFeedPets[pet.Key] then
            selected = selected + 1
            local portions = 0
            for _ = 1, amount do
                if not self:Valid(token) then return end
                if not self.FoodFeedPets[pet.Key] or not self:FeedPet(token, false, pet.Key) then partial = true break end
                fed = fed + 1
                portions = portions + 1
            end
            if portions > 0 then fedPets = fedPets + 1 end
        end
    end
    if selected == 0 then self.FoodStatus = "Choose pets to feed"
    elseif fed > 0 then self.FoodStatus = "Fed " .. fed .. " portions to " .. fedPets .. " pets" .. (partial and " (partial)" or "") end
    self.Status = self.FoodStatus
end

--------------------------------------------------------------------
-- Sell + Favorites (Richie dialogue)
--------------------------------------------------------------------
function PT:SellVendor()
    local stalls = workspace:FindFirstChild("Stalls")
    local stall = stalls and stalls:FindFirstChild("Sell")
    local npc = stall and stall:FindFirstChild("Richie")
    local root = npc and npc:FindFirstChild("HumanoidRootPart")
    local prompt = root and root:FindFirstChildOfClass("ProximityPrompt")
    return npc, root, prompt
end

function PT:InventoryPets()
    local placed, seen, result = {}, {}, {}
    for _, pet in ipairs(self:PetList()) do if pet.Placed then placed[pet.Key] = true end end
    local _, _, root = self:Character()
    local joint = root and root:FindFirstChild("PetMountJoint")
    local mounted = joint and joint.Part1 and joint.Part1.Parent
    local mountedKey = mounted and mounted:GetAttribute("PetKey")
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local character = LocalPlayer.Character
    for _, tool in ipairs(self:Tools()) do
        local key = tool:GetAttribute("PetKey")
        local name = tool:GetAttribute("PetName") or tool.Name
        local data = self.Data.Pets[name]
        if key and type(data) == "table" and not seen[key] and not placed[key] and key ~= mountedKey
            and (tool.Parent == backpack or tool.Parent == character) then
            seen[key] = true
            result[#result + 1] = { Key = key, Name = name, Rarity = data.Rarity, Tool = tool, Favorite = tool:GetAttribute("Favorited") == true }
        end
    end
    table.sort(result, function(a, b) if a.Name == b.Name then return a.Key < b.Key end return a.Name < b.Name end)
    return result
end

function PT:MatchesFavorite(pet)
    return self.FavTypes[pet.Name] == true and self.FavRarities[pet.Rarity] == true
end

function PT:InventorySellPets()
    local result = {}
    for _, pet in ipairs(self:InventoryPets()) do
        -- Never sell favorites, pending favorites, or anything the favorite rules match.
        if not pet.Favorite and not self.FavoriteRequests[pet.Key] and not self:MatchesFavorite(pet) then
            result[#result + 1] = pet
        end
    end
    return result
end

function PT:UpdateFavoriteRequests()
    if not next(self.FavoriteRequests) then return end
    for _, pet in ipairs(self:PetList()) do
        if pet.Favorite and self.FavoriteRequests[pet.Key] then
            self.FavoriteRequests[pet.Key] = nil
            self.FavoritedPets = self.FavoritedPets + 1
        end
    end
end

function PT:NextFavoritePet()
    for _, pet in ipairs(self:InventoryPets()) do
        if not pet.Favorite and not self.FavoriteRequests[pet.Key] and self:MatchesFavorite(pet) then return pet end
    end
end

function PT:FavoritePet(token, key)
    if not self:Valid(token) or not self.Options.AutoFavorites or self.FavoriteRequests[key] then return false end
    local pet
    for _, c in ipairs(self:InventoryPets()) do if c.Key == key then pet = c break end end
    if not pet or pet.Favorite or not self:MatchesFavorite(pet) then return false end
    self.FavoriteRequests[key] = true
    local ok, sent = pcall(self.Fire, self, "FavoritePet", key)
    if not ok or not sent then
        self.FavoriteRequests[key] = nil
        self.SellStatus = "Favorite request failed"
        return false
    end
    local confirmed = self:WaitFor(function()
        for _, owned in ipairs(self:PetList()) do if owned.Key == key and owned.Favorite then return true end end
        return false
    end, 3, token)
    self:UpdateFavoriteRequests()
    if not self:Valid(token) then return false end
    self.SellStatus = confirmed and ("Favorited " .. pet.Name) or "Waiting for favorite confirmation"
    return confirmed
end

function PT:FindSellPet(key)
    for _, pet in ipairs(self:InventorySellPets()) do if pet.Key == key then return pet end end
end

function PT:SellOptionReady(npc)
    local data = self.SellDialogue
    if not data or data.Model ~= npc then return false end
    local offered = false
    for _, option in ipairs(data.Options or {}) do
        if option.Text == "I would like to sell this" then offered = true break end
    end
    if not offered then return false end
    local options = LocalPlayer.PlayerGui:FindFirstChild("Options")
    local button = options and options:FindFirstChild("I would like to sell this")
    return button and button:IsA("GuiButton") and button.Visible and button.Active and options.Enabled
end

function PT:OpenSellDialogue(npc, prompt, token, manual)
    if self:SellOptionReady(npc) then return true end
    if type(fireproximityprompt) ~= "function" then return false end
    if not self:WaitFor(function() return prompt.Parent and prompt.Enabled end, 4, token) then return false end
    if not self:Valid(token) or (not manual and not self.Options.AutoSell) then return false end
    local revision = self.SellDialogueRevision or 0
    if not pcall(fireproximityprompt, prompt) then return false end
    return self:WaitFor(function()
        return (self.SellDialogueRevision or 0) > revision and self:SellOptionReady(npc)
    end, 5, token)
end

function PT:StopSelling(message)
    self.Options.AutoSell = false
    self.SellStatus = message
    self.Status = message
    if self.Job == "Selling inventory pet" or self.Job == "Selling all inventory pets" then self:CancelJob() end
    self:ControlRefresh()
end

function PT:SellPet(token, key, manual)
    local function active() return self:Valid(token) and (manual or self.Options.AutoSell) end
    if not active() then return false end
    local pet = self:FindSellPet(key)
    if not pet then return false end
    local npc, vendorRoot, prompt = self:SellVendor()
    if not npc or not vendorRoot or not prompt or not self.SellAPI then
        self:StopSelling("Sell vendor is unavailable")
        return false
    end
    local _, _, root = self:Character()
    if not root then return false end
    self.SellStatus = "Selling " .. pet.Name
    local range = math.max(5, math.min(18, prompt.MaxActivationDistance - 3))
    if (root.Position - vendorRoot.Position).Magnitude > range then
        self.SellStatus = "Flying to Richie"
        if not self:MoveTo(vendorRoot.Position + vendorRoot.CFrame.LookVector * 8, token, 12) then return false end
    end
    if not active() then return false end
    pet = self:FindSellPet(key)
    if not pet then return false end
    if not self:Equip(pet.Tool) then return false end
    task.wait(0.2)
    if not active() then return false end
    if not self:OpenSellDialogue(npc, prompt, token, manual) then
        if active() then self:StopSelling("Could not open Richie's sell dialogue") end
        return false
    end
    if not active() then return false end
    local current = self:FindSellPet(key)
    local character, _, currentRoot = self:Character()
    if not current or current.Tool ~= pet.Tool or pet.Tool.Parent ~= character then return false end
    if not currentRoot or (currentRoot.Position - vendorRoot.Position).Magnitude > prompt.MaxActivationDistance then return false end
    if not self:SellOptionReady(npc) then return false end
    if not pcall(self.SellAPI.SelectOption, "I would like to sell this") then
        self:StopSelling("Sale request failed. Selling stopped.")
        return false
    end
    local confirmed = self:WaitFor(function()
        if pet.Tool.Parent or self:Tool(nil, key) then return false end
        for _, owned in ipairs(self:PetList()) do if owned.Key == key then return false end end
        return true
    end, 5, token)
    if not active() then return false end
    if not confirmed then self:StopSelling("Sale was not confirmed. Selling stopped.") return false end
    self.SoldPets = self.SoldPets + 1
    self.SellStatus = "Sold " .. pet.Name
    self.Status = self.SellStatus
    return true
end

function PT:SellAll(token)
    local pets = self:InventorySellPets()
    if #pets == 0 then self.SellStatus = "No inventory pets available to sell" return end
    local sold = 0
    for _, pet in ipairs(pets) do
        if not self:Valid(token) then return end
        if self:FindSellPet(pet.Key) then
            if not self:SellPet(token, pet.Key, true) then
                if not self:Valid(token) or self:FindSellPet(pet.Key) then return end
            else
                sold = sold + 1
                task.wait(0.2)
            end
        end
    end
    if self:Valid(token) then
        self.SellStatus = "Sell All complete: " .. sold .. " sold"
        self.Status = self.SellStatus
    end
end

--------------------------------------------------------------------
-- Init (async so a missing game module never blocks the hub)
--------------------------------------------------------------------
function PT:Init()
    local RS = ReplicatedStorage
    self.Remotes = RS:WaitForChild("Remotes", 15):WaitForChild("Game", 15)
    self.Saved = LocalPlayer:WaitForChild("SavedData", 15)
    self.ActiveEggs = RS:WaitForChild("ServerData", 15):WaitForChild("ActiveEggs", 15)
    self.Data = {}
    for _, name in ipairs({ "Eggs", "Pets", "General", "Mutations" }) do
        self.Data[name] = require(RS.GameData:WaitForChild(name, 10))
    end
    self.Services = {}
    for _, name in ipairs({ "PetAging", "DayNight" }) do
        self.Services[name] = require(RS.GameServices:WaitForChild(name, 10))
    end
    pcall(function() self.Renderer = require(LocalPlayer.PlayerScripts.Game.Pets.PetRenderer) end)

    -- Pet names for favorite filter (default: every type allowed, no rarity selected => nothing auto-favorited)
    self.PetNames = {}
    for name, data in pairs(self.Data.Pets) do
        if type(data) == "table" and data.Rarity then
            self.PetNames[#self.PetNames + 1] = name
            self.FavTypes[name] = true
        end
    end
    table.sort(self.PetNames)

    -- Food (optional)
    local okFood = pcall(function()
        self.Data.Foods = require(RS.GameData:WaitForChild("Foods", 10))
        self.Data.Shop = require(RS.GameData:WaitForChild("Shop", 10))
        self.FoodNames = {}
        for name, definition in pairs(self.Data.Shop.Food) do
            if type(definition) == "table" and self.Data.Foods[name] then table.insert(self.FoodNames, name) end
        end
        table.sort(self.FoodNames, function(a, b) return self.Data.Shop.Food[a].Price < self.Data.Shop.Food[b].Price end)
    end)
    self.FoodReady = okFood and self.FoodNames ~= nil
    if not self.FoodReady then self.FoodNames = {} self.FoodStatus = "Food data unavailable" end

    -- Sell dialogue (optional)
    pcall(function()
        local dialogue = RS:FindFirstChild("Dialogue")
        local modules = dialogue and dialogue:FindFirstChild("Modules")
        local module = modules and modules:FindFirstChild("DialogueModule")
        local remotes = dialogue and dialogue:FindFirstChild("Remotes")
        if not module or not remotes then return end
        local api = require(module)
        if type(api) ~= "table" or type(api.SelectOption) ~= "function" then return end
        self.SellAPI = api
        self.SellDialogueRevision = 0
        for _, name in ipairs({ "DialogueSend", "DialogueUpdate" }) do
            local remote = remotes:FindFirstChild(name)
            if remote then
                table.insert(Connections, remote.OnClientEvent:Connect(function(data)
                    self.SellDialogue = type(data) == "table" and data or nil
                    self.SellDialogueRevision = self.SellDialogueRevision + 1
                end))
            end
        end
    end)
    if not self.SellAPI then self.SellStatus = "Sell dialogue unavailable (Sell disabled)" end
    self.Ready = true

    -- Event-driven ESP refresh: new/removed active eggs appear/disappear immediately.
    table.insert(Connections, self.ActiveEggs.ChildAdded:Connect(function()
        if self.Alive and self.Options.ESP then
            task.defer(function() pcall(function() self:UpdateESP() end) end)
        end
    end))
    table.insert(Connections, self.ActiveEggs.ChildRemoved:Connect(function()
        if self.Alive and self.Options.ESP then
            task.defer(function() pcall(function() self:UpdateESP() end) end)
        end
    end))
    self.Status = "Ready"
end

-- Eggs (used by ESP+)
function PT:EggList()
    local out = {}
    local _, _, root = self:Character()
    local o = self.Options
    local collected = "," .. tostring(LocalPlayer:GetAttribute("CollectedEggs") or "") .. ","
    for _, object in ipairs(self.ActiveEggs:GetChildren()) do
        local name = object:GetAttribute("Egg")
        local data = name and self.Data.Eggs[name]
        local pos = object:GetAttribute("Position")
        local private = object:GetAttribute("PrivateTo")
        if type(data) == "table" and typeof(pos) == "Vector3" and (not private or private == LocalPlayer.UserId)
            and not string.find(collected, "," .. object.Name .. ",", 1, true) then
            local rawWeight = object:GetAttribute("Weight") or 1
            local mutation = object:GetAttribute("Mutation")
            local spawnM = object:GetAttribute("SpawnMutation")
            local kg = rawWeight
            pcall(function() kg = self.Data.General.ShownEggKG(rawWeight) end)
            local label = (mutation and mutation ~= "" and mutation) or "None"
            if spawnM and spawnM ~= "" and spawnM ~= mutation then
                label = label == "None" and spawnM or (label .. " + " .. spawnM)
            end
            local row = {
                ID = object.Name, Object = object, Name = name, Position = pos,
                Distance = root and (root.Position - pos).Magnitude or math.huge,
                Rarity = data.Rarity or "Common", KG = kg, Luck = data.Luck or 0, MutationLabel = label,
            }
            if self.ESPRarities[row.Rarity] == true and row.Luck >= o.ESPMinLuck
                and (not o.ESPMutatedOnly or label ~= "None") and row.Distance <= o.ESPMaxDistance then
                table.insert(out, row)
            end
        end
    end
    table.sort(out, function(a, b)
        if a.Distance == b.Distance then return a.ID < b.ID end
        return a.Distance < b.Distance
    end)
    return out
end

--------------------------------------------------------------------
-- Options / scheduler
--------------------------------------------------------------------
local JOB_FOR_OPTION = {
    AutoBest = "Placing best pets", AutoFeed = "Auto feeding pet",
    AutoSell = "Selling inventory pet", AutoFavorites = "Adding pet to favorites",
}

function PT:ControlRefresh()
    for _, fn in ipairs(self.Redraws) do pcall(fn) end
    if self.RefreshOwnedPetLabels then pcall(function() self:RefreshOwnedPetLabels() end) end
end

function PT:ClearESP()
    for id, m in pairs(self.Markers) do
        pcall(function() m.Text:Destroy() m.Box:Destroy() m.Line:Destroy() end)
        self.Markers[id] = nil
    end
end

function PT:SetOption(key, value)
    self.Options[key] = value
    if value == false then
        if JOB_FOR_OPTION[key] and self.Job == JOB_FOR_OPTION[key] then self:CancelJob() end
        if key == "AutoBuyFood" and self.Job and string.sub(self.Job, 1, 7) == "Buying " then self:CancelJob() end
    end
    if key == "ESP" and not value then self:ClearESP() end
    if string.sub(key, 1, 3) == "ESP" and self.Ready then
        task.defer(function() pcall(function() self:UpdateESP() end) end)
    end
    if key == "AutoSell" then self.SellStatus = value and "Waiting for inventory pets" or "Auto Sell stopped" end
    if key == "AutoFavorites" then self.SellStatus = value and "Auto Favorites enabled" or "Auto Favorites stopped" end
    self:ControlRefresh()
end

function PT:StopAll()
    self:CancelJob()
    for _, key in ipairs({ "AutoBest", "AutoBuyFood", "AutoFeed", "AutoSell", "AutoFavorites" }) do self:SetOption(key, false) end
    self.Status = "Pet automation stopped"
end

-- Start a manual action and tell the user why if it can't start.
function PT:Run(name, fn)
    if not self.Ready then self:Notify("Pet tools are still loading or unavailable") return end
    if self.Job then self:Notify("Busy: " .. tostring(self.Job)) return end
    if self:Blocked() then self:Notify("Volcano/claim route is running; try again shortly") return end
    self:StartJob(name, fn)
end

function PT:Tick()
    self:UpdateFavoriteRequests()
    if self.Job or not self:Character() or self:Blocked() then return end
    local o = self.Options
    if o.AutoFavorites and self:Ready1("FavoritePets", 0.5) then
        local pet = self:NextFavoritePet()
        if pet then self:StartJob("Adding pet to favorites", function(t) self:FavoritePet(t, pet.Key) end) return end
    end
    if o.AutoBest and self:Ready1("Best", 5) then
        self:StartJob("Placing best pets", function(t) self:PlaceBest(t) end)
        return
    end
    if o.AutoSell and self.SellAPI and self:Ready1("SellPets", 1) then
        local pet = self:InventorySellPets()[1]
        if pet then self:StartJob("Selling inventory pet", function(t) self:SellPet(t, pet.Key, false) end) return end
        self.SellStatus = "Waiting for inventory pets"
    end
    if o.AutoFeed and self.FoodReady and self:Ready1("FoodFeed", 3) then
        local key = self:NextFoodPet()
        if key then
            self:StartJob("Auto feeding pet", function(t)
                self.LastAutoFedPet = key
                self:FeedPet(t, true, key)
            end)
            return
        end
    end
    if o.AutoBuyFood and self.FoodReady and self:Ready1("FoodShop", 0.5) then
        local name = self:NextFoodPurchase()
        if name then
            local amount = math.clamp(self:FoodStock(name) or 1, 1, 5)
            self:StartJob("Buying " .. name, function(t) self:BuyFood(t, name, amount, true) end)
            return
        end
    end
end

--------------------------------------------------------------------
-- Egg ESP+ (GUI based, works on every executor, no Drawing API needed)
--------------------------------------------------------------------
local espGui = Instance.new("ScreenGui")
espGui.Name = "PetTools_ESP_GUI"
espGui.ResetOnSpawn = false
espGui.IgnoreGuiInset = true
espGui.DisplayOrder = 997
espGui.Parent = PlayerGui

function PT:UpdateESP()
    local o = self.Options
    if not o.ESP then return end
    local keep = {}
    for i, egg in ipairs(self:EggList()) do
        if i > o.ESPCount then break end
        keep[egg.ID] = true
        local color = self.RarityColors[egg.Rarity] or Color3.new(1, 1, 1)
        local m = self.Markers[egg.ID]
        if not m then
            local text = Instance.new("TextLabel")
            text.BackgroundTransparency = 1
            text.Size = UDim2.fromOffset(220, 90)
            text.AnchorPoint = Vector2.new(0.5, 1)
            text.Font = Enum.Font.GothamBold
            text.TextStrokeTransparency = 0
            text.TextYAlignment = Enum.TextYAlignment.Bottom
            text.Visible = false
            text.Parent = espGui
            local box = Instance.new("Frame")
            box.BackgroundTransparency = 1
            box.BorderSizePixel = 0
            box.AnchorPoint = Vector2.new(0.5, 0.5)
            box.Visible = false
            box.Parent = espGui
            local stroke = Instance.new("UIStroke")
            stroke.Thickness = 1
            stroke.Parent = box
            local line = Instance.new("Frame")
            line.BorderSizePixel = 0
            line.AnchorPoint = Vector2.new(0.5, 0.5)
            line.Visible = false
            line.Parent = espGui
            m = { Text = text, Box = box, Stroke = stroke, Line = line }
            self.Markers[egg.ID] = m
        end
        m.Egg = egg
        m.Text.TextColor3 = color
        m.Text.TextSize = o.ESPSize
        m.Stroke.Color = color
        m.Line.BackgroundColor3 = color
    end
    for id, m in pairs(self.Markers) do
        if not keep[id] then
            pcall(function() m.Text:Destroy() m.Box:Destroy() m.Line:Destroy() end)
            self.Markers[id] = nil
        end
    end
end

function PT:RenderESP()
    if not next(self.Markers) then return end
    local camera = workspace.CurrentCamera
    local _, _, root = self:Character()
    local o = self.Options
    for _, m in pairs(self.Markers) do
        local egg = m.Egg
        local visible = false
        if o.ESP and camera and root and egg and egg.Object.Parent == self.ActiveEggs then
            local distance = (root.Position - egg.Position).Magnitude
            local pt, onScreen = camera:WorldToViewportPoint(egg.Position + Vector3.new(0, 4, 0))
            visible = onScreen and pt.Z > 0 and distance <= o.ESPMaxDistance
            if visible then
                local lines = {}
                if o.ESPName then lines[#lines + 1] = egg.Name end
                if o.ESPRarity then lines[#lines + 1] = egg.Rarity end
                if o.ESPDistance then lines[#lines + 1] = string.format("%d studs", distance) end
                if o.ESPWeight then lines[#lines + 1] = self:Format(egg.KG) .. " kg" end
                if o.ESPMutation then lines[#lines + 1] = "Mutation: " .. egg.MutationLabel end
                if o.ESPLuck then lines[#lines + 1] = "Luck: " .. self:Format(egg.Luck) .. "x" end
                m.Text.Text = table.concat(lines, "\n")
                m.Text.Position = UDim2.fromOffset(pt.X, pt.Y)
                local c = camera:WorldToViewportPoint(egg.Position + Vector3.new(0, 1.5, 0))
                local size = math.clamp(2600 / math.max(pt.Z, 1), 8, 90)
                m.Box.Position = UDim2.fromOffset(c.X, c.Y)
                m.Box.Size = UDim2.fromOffset(size, size)
                local from = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y - 12)
                local to = Vector2.new(c.X, c.Y)
                local delta = to - from
                m.Line.Position = UDim2.fromOffset((from.X + to.X) / 2, (from.Y + to.Y) / 2)
                m.Line.Size = UDim2.fromOffset(math.max(1, delta.Magnitude), 1)
                m.Line.Rotation = math.deg(math.atan2(delta.Y, delta.X))
            end
        end
        m.Text.Visible = visible
        m.Box.Visible = visible and o.ESPBoxes
        m.Line.Visible = visible and o.ESPTracers
    end
end

table.insert(Connections, RunService.RenderStepped:Connect(function()
    if PT.Alive and PT.Ready and PT.Options.ESP then pcall(function() PT:RenderESP() end) end
end))

--------------------------------------------------------------------
-- UI builders
--------------------------------------------------------------------
local function mk(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    o.Parent = parent
    return o
end

local BTN_TEXT = UserInputService.TouchEnabled and 12 or 11

local function bHeader(parent, order, text)
    return mk("TextLabel", {
        Size = UDim2.new(1, -8, 0, 18), BackgroundTransparency = 1, Font = Enum.Font.GothamBold,
        Text = text, TextColor3 = Color3.fromRGB(150, 185, 255), TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = order,
    }, parent)
end

local function bLabel(parent, order, text, height)
    local l = mk("TextLabel", {
        Size = UDim2.new(1, -8, 0, height or 30), BackgroundColor3 = THEME.Panel, BorderSizePixel = 0,
        Font = Enum.Font.GothamMedium, Text = text, TextColor3 = Color3.fromRGB(220, 220, 235),
        TextSize = 11, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = order,
    }, parent)
    mk("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingTop = UDim.new(0, 4) }, l)
    round(l, 6)
    return l
end

local function bButton(parent, order, text, callback)
    local b = mk("TextButton", {
        Size = UDim2.new(1, -8, 0, 34), BackgroundColor3 = THEME.Button, BorderSizePixel = 0,
        Font = Enum.Font.GothamBold, Text = text, TextColor3 = Color3.new(1, 1, 1),
        TextSize = BTN_TEXT, LayoutOrder = order,
    }, parent)
    round(b, 7)
    if callback then b.Activated:Connect(callback) end
    return b
end

-- Button that shows a live count, e.g. "Choose foods to buy (2)".
local function bCountButton(parent, order, base, countFn, callback)
    local b = bButton(parent, order, base, callback)
    local function draw() b.Text = base .. " (" .. tostring(countFn()) .. ")" end
    table.insert(PT.Redraws, draw)
    draw()
    return b
end

-- Button that needs a second tap within 5s.
local function bConfirmButton(parent, order, text, warn, action)
    local b, armedAt = nil, 0
    b = bButton(parent, order, text, function()
        if armedAt ~= 0 and os.clock() - armedAt < 5 then
            armedAt = 0
            b.Text = text
            action()
            return
        end
        armedAt = os.clock()
        b.Text = warn
        b.BackgroundColor3 = Color3.fromRGB(170, 80, 40)
        task.delay(5.1, function()
            if b.Parent and armedAt ~= 0 and os.clock() - armedAt >= 5 then
                armedAt = 0
                b.Text = text
                b.BackgroundColor3 = THEME.Button
            end
        end)
    end)
    local orig = action
    action = function() b.BackgroundColor3 = THEME.Button orig() end
    return b
end

local function bToggle(parent, order, label, get, set, confirmMsg)
    local b = bButton(parent, order, "", nil)
    b.Size = UDim2.new(1, -8, 0, 38)
    b.Text = ""

    mk("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(1, -78, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = label,
        TextColor3 = Color3.fromRGB(235, 235, 245),
        TextSize = BTN_TEXT,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, b)

    -- Same sliding switch used by the Main tab.
    local track = mk("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.fromOffset(48, 24),
        BorderSizePixel = 0,
    }, b)
    round(track, 12)

    local knob = mk("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(18, 18),
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.fromRGB(245, 245, 250),
    }, track)
    round(knob, 9)

    local armedAt = 0
    local firstDraw = true
    local function draw(forceInstant)
        local on = get() == true
        local trackColor = on and Color3.fromRGB(65, 190, 105) or Color3.fromRGB(75, 75, 90)
        local knobPos = on and UDim2.new(1, -12, 0.5, 0) or UDim2.new(0, 12, 0.5, 0)
        if firstDraw or forceInstant then
            track.BackgroundColor3 = trackColor
            knob.Position = knobPos
            firstDraw = false
        else
            TweenService:Create(track, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = trackColor
            }):Play()
            TweenService:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = knobPos
            }):Play()
        end
    end

    table.insert(PT.Redraws, function() draw(true) end)
    draw(true)

    b.Activated:Connect(function()
        local on = get() == true
        if not on and confirmMsg then
            if os.clock() - armedAt > 6 then
                armedAt = os.clock()
                track.BackgroundColor3 = Color3.fromRGB(200, 120, 40)
                PT:Notify(confirmMsg)
                task.delay(6, function()
                    if track.Parent then draw(true) end
                end)
                return
            end
            armedAt = 0
        end

        set(not on)
        draw(false)

        -- ESP changes should be visible immediately, not on the 0.5s scanner.
        if PT.Ready and string.sub(label, 1, 3) ~= "Auto" then
            task.defer(function()
                pcall(function() PT:UpdateESP() end)
            end)
        end
    end)

    return b
end

local function bInput(parent, order, label, get, set)
    local row = mk("Frame", { Size = UDim2.new(1, -8, 0, 32), BackgroundColor3 = THEME.Button, BorderSizePixel = 0, LayoutOrder = order }, parent)
    round(row, 7)
    mk("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -100, 1, 0),
        Font = Enum.Font.GothamBold, Text = label, TextColor3 = Color3.fromRGB(235, 235, 245),
        TextSize = BTN_TEXT, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
    }, row)
    local box = mk("TextBox", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.fromOffset(80, 22),
        BackgroundColor3 = THEME.Panel, BorderSizePixel = 0, Font = Enum.Font.GothamMedium,
        Text = tostring(get()), TextColor3 = Color3.new(1, 1, 1), TextSize = 11, ClearTextOnFocus = false,
    }, row)
    round(box, 5)
    local function draw() box.Text = tostring(get()) end
    table.insert(PT.Redraws, draw)
    box.FocusLost:Connect(function()
        local n = tonumber(box.Text)
        if n then set(n) end
        draw()
    end)
    return box
end

--------------------------------------------------------------------
-- Multi-select picker (search + all/none), overlays the hub content area
--------------------------------------------------------------------
local Picker
local function buildPicker()
    local f = mk("Frame", {
        Position = UDim2.fromOffset(10, 80), Size = UDim2.new(1, -20, 1, -90),
        BackgroundColor3 = THEME.Bg, BorderSizePixel = 0, Visible = false, ZIndex = 50,
    }, Main)
    round(f, 8)
    mk("UIStroke", { Color = THEME.Accent, Thickness = 1 }, f)
    local title = mk("TextLabel", {
        Position = UDim2.fromOffset(8, 4), Size = UDim2.new(1, -16, 0, 20), BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold, Text = "", TextColor3 = Color3.new(1, 1, 1), TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 52,
    }, f)
    local search = mk("TextBox", {
        Position = UDim2.fromOffset(8, 28), Size = UDim2.new(1, -16, 0, 24), BackgroundColor3 = THEME.Panel,
        BorderSizePixel = 0, Font = Enum.Font.GothamMedium, PlaceholderText = "Search...", Text = "",
        TextColor3 = Color3.new(1, 1, 1), TextSize = 11, ClearTextOnFocus = false, ZIndex = 52,
    }, f)
    round(search, 5)
    local list = mk("ScrollingFrame", {
        Position = UDim2.fromOffset(8, 58), Size = UDim2.new(1, -16, 1, -98), BackgroundTransparency = 1,
        BorderSizePixel = 0, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
        ScrollBarThickness = 4, ZIndex = 52,
    }, f)
    mk("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, list)
    local function footer(text, x, w)
        local b = mk("TextButton", {
            AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(x, x == 0 and 8 or 3, 1, -6),
            Size = UDim2.new(w, -6, 0, 28), BackgroundColor3 = THEME.Button, BorderSizePixel = 0,
            Font = Enum.Font.GothamBold, Text = text, TextColor3 = Color3.new(1, 1, 1), TextSize = 11, ZIndex = 53,
        }, f)
        round(b, 6)
        return b
    end
    local allBtn, noneBtn, doneBtn = footer("All", 0, 0.33), footer("None", 0.33, 0.33), footer("Done", 0.66, 0.34)
    Picker = { Frame = f, Title = title, Search = search, List = list, All = allBtn, None = noneBtn, Done = doneBtn }
end

function PT:OpenPicker(titleText, items, selected, onChange)
    if not Picker then buildPicker() end
    local P = Picker

    if P.Conns then
        for _, c in ipairs(P.Conns) do pcall(function() c:Disconnect() end) end
    end
    P.Conns = {}

    for _, child in ipairs(P.List:GetChildren()) do
        if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
            child:Destroy()
        end
    end

    P.Title.Text = titleText
    P.Search.Text = ""
    P.Frame.Visible = true

    local rows = {}
    local lastTap = {}

    local function clearRows()
        for _, r in ipairs(rows) do
            if r.Button and r.Button.Parent then r.Button:Destroy() end
        end
        table.clear(rows)
    end

    local function redrawRow(row, instant)
        if not row or not row.Item or not row.Track or not row.Knob then return end
        local on = selected[row.Item.id] == true
        local trackColor = on and Color3.fromRGB(65, 190, 105) or Color3.fromRGB(75, 75, 90)
        local knobPos = on and UDim2.new(1, -10, 0.5, 0) or UDim2.new(0, 10, 0.5, 0)

        if instant then
            row.Track.BackgroundColor3 = trackColor
            row.Knob.Position = knobPos
        else
            TweenService:Create(row.Track, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = trackColor
            }):Play()
            TweenService:Create(row.Knob, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = knobPos
            }):Play()
        end
    end

    local function toggleItem(row)
        if not row or not row.Item then return end
        local id = row.Item.id
        local now = os.clock()

        -- Delta/mobile can occasionally emit two activation events for one tap.
        -- Ignore the duplicate so an OFF tap cannot instantly turn itself back ON.
        if lastTap[id] and now - lastTap[id] < 0.22 then return end
        lastTap[id] = now

        if selected[id] == true then
            selected[id] = nil
        else
            selected[id] = true
        end

        redrawRow(row, false)
        if onChange then pcall(onChange) end
    end

    local function rebuild()
        clearRows()
        local q = string.lower(P.Search.Text or "")

        for i, item in ipairs(items) do
            if q == "" or string.find(string.lower(item.label), q, 1, true) then
                local b = mk("TextButton", {
                    Size = UDim2.new(1, -6, 0, 34),
                    BackgroundColor3 = THEME.Button,
                    BorderSizePixel = 0,
                    Text = "",
                    AutoButtonColor = false,
                    LayoutOrder = i,
                    ZIndex = 53,
                }, P.List)
                round(b, 7)

                local name = mk("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(10, 0),
                    Size = UDim2.new(1, -70, 1, 0),
                    Font = Enum.Font.GothamMedium,
                    Text = item.label,
                    TextColor3 = Color3.fromRGB(235, 235, 245),
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = 54,
                }, b)

                local track = mk("Frame", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -8, 0.5, 0),
                    Size = UDim2.fromOffset(42, 22),
                    BorderSizePixel = 0,
                    ZIndex = 54,
                }, b)
                round(track, 11)

                local knob = mk("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Size = UDim2.fromOffset(16, 16),
                    BorderSizePixel = 0,
                    BackgroundColor3 = Color3.fromRGB(245, 245, 250),
                    ZIndex = 55,
                }, track)
                round(knob, 8)

                local row = {Button = b, Item = item, Track = track, Knob = knob, Label = name}
                rows[#rows + 1] = row
                redrawRow(row, true)

                -- One handler on the entire row. The visual switch itself is deliberately
                -- non-clickable so a single tap cannot be handled twice.
                b.Activated:Connect(function()
                    toggleItem(row)
                end)
            end
        end

        if #rows == 0 then
            local empty = mk("TextLabel", {
                Size = UDim2.new(1, -6, 0, 30),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamMedium,
                Text = #items == 0 and "Nothing to choose from yet" or "No matches",
                TextColor3 = Color3.fromRGB(180, 180, 200),
                TextSize = 11,
                LayoutOrder = 1,
                ZIndex = 53,
            }, P.List)
            rows[#rows + 1] = {Button = empty}
        end
    end

    local function applyAll(value)
        for _, item in ipairs(items) do
            selected[item.id] = value and true or nil
        end
        for _, row in ipairs(rows) do
            if row.Item then redrawRow(row, false) end
        end
        if onChange then pcall(onChange) end
    end

    rebuild()

    P.Conns = {
        P.Search:GetPropertyChangedSignal("Text"):Connect(rebuild),
        P.All.Activated:Connect(function() applyAll(true) end),
        P.None.Activated:Connect(function() applyAll(false) end),
        P.Done.Activated:Connect(function()
            P.Search:ReleaseFocus()
            P.Frame.Visible = false
            if onChange then pcall(onChange) end
        end),
    }
end

local function petItems()
    local items = {}
    if not PT.Ready then return items end
    for _, pet in ipairs(PT:PetList()) do
        items[#items + 1] = {
            id = pet.Key,
            label = string.format("%s | %s | age %s | %s", pet.Name, tostring(pet.Rarity or "?"), tostring(pet.Age), pet.Placed and "placed" or "bag"),
        }
    end
    return items
end

local function foodItems()
    local items = {}
    for _, name in ipairs(PT.FoodNames or {}) do
        local price = PT.Data.Shop.Food[name] and PT.Data.Shop.Food[name].Price
        items[#items + 1] = { id = name, label = name .. (price and ("  ($" .. PT:Format(price) .. ")") or "") }
    end
    return items
end

local function rarityItems()
    local items = {}
    for _, r in ipairs(PT.RarityNames) do items[#items + 1] = { id = r, label = r } end
    return items
end

local function petTypeItems()
    local items = {}
    for _, n in ipairs(PT.PetNames or {}) do items[#items + 1] = { id = n, label = n } end
    return items
end

--------------------------------------------------------------------
-- Pets tab layout
--------------------------------------------------------------------
local PetsScroll = mk("ScrollingFrame", {
    Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
    AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ScrollBarThickness = 4,
}, PanelPets)
mk("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, PetsScroll)
local n = 0
local function ord() n = n + 1 return n end

PT.StatusLabel = bLabel(PetsScroll, ord(), "Loading pet tools...", 44)
PT.StatusLabel.Font = Enum.Font.GothamBold

local function opt(key) return function() return PT.Options[key] end end
local function setOpt(key) return function(v) PT:SetOption(key, v) end end
local function needReady(fn) return function() if PT.Ready then fn() else PT:Notify("Pet tools are still loading or unavailable") end end end


-- Misc shortcut: same AutoBest state as the Pets tab.
-- This continuously keeps the best pets placed using the current Income/Speed metric.


-- 10. Best pets
bHeader(PetsScroll, ord(), " Best Pets")
bToggle(PetsScroll, ord(), "Auto Place Best Pets", opt("AutoBest"), setOpt("AutoBest"))
local metricBtn = bButton(PetsScroll, ord(), "", function()
    PT.Options.BestMetric = PT.Options.BestMetric == "Income" and "Speed" or "Income"
    PT:ControlRefresh()
end)
table.insert(PT.Redraws, function() metricBtn.Text = "Rank pets by: " .. PT.Options.BestMetric end)
bButton(PetsScroll, ord(), "Place Best Pets Now", needReady(function()
    PT:Run("Placing best pets", function(t) PT:PlaceBest(t) end)
end))
bInput(PetsScroll, ord(), "Flight speed (studs/s)", function() return PT.Options.TweenSpeed end,
    function(v) PT.Options.TweenSpeed = math.clamp(math.floor(v), 40, 350) end)

-- 11. Food
bHeader(PetsScroll, ord(), " Food")
bToggle(PetsScroll, ord(), "Auto Buy Food", opt("AutoBuyFood"), setOpt("AutoBuyFood"))
bToggle(PetsScroll, ord(), "Auto Feed Pets", opt("AutoFeed"), setOpt("AutoFeed"))
bCountButton(PetsScroll, ord(), "Foods to buy", function() return PT:Count(PT.FoodBuyItems) end, needReady(function()
    PT:OpenPicker("Foods to buy", foodItems(), PT.FoodBuyItems, function() PT:ControlRefresh() end)
end))
bCountButton(PetsScroll, ord(), "Foods to feed", function() return PT:Count(PT.FoodFeedItems) end, needReady(function()
    PT:OpenPicker("Foods to feed", foodItems(), PT.FoodFeedItems, function() PT:ControlRefresh() end)
end))
bCountButton(PetsScroll, ord(), "Pets to feed", function() return PT:Count(PT.FoodFeedPets) end, needReady(function()
    PT:OpenPicker("Pets to feed", petItems(), PT.FoodFeedPets, function() PT:ControlRefresh() end)
end))
bInput(PetsScroll, ord(), "Manual feed portions per pet", function() return PT.Options.ManualFeedCount end,
    function(v) PT.Options.ManualFeedCount = math.clamp(math.floor(v), 1, 1000) end)
bButton(PetsScroll, ord(), "Buy Chosen Foods Now", needReady(function()
    PT:Run("Buying selected foods", function(t) PT:BuySelectedFoods(t) end)
end))
bButton(PetsScroll, ord(), "Feed Chosen Pets Now", needReady(function()
    PT:Run("Feeding selected pets", function(t) PT:FeedSelectedPets(t, PT.Options.ManualFeedCount) end)
end))
PT.FoodLabel = bLabel(PetsScroll, ord(), PT.FoodStatus, 30)

-- 12. Sell + favorites
bHeader(PetsScroll, ord(), " Sell & Favorites")
bToggle(PetsScroll, ord(), "Auto Favorites", opt("AutoFavorites"), setOpt("AutoFavorites"))
bCountButton(PetsScroll, ord(), "Favorite: rarities", function() return PT:Count(PT.FavRarities) end, needReady(function()
    PT:OpenPicker("Auto-favorite these rarities", rarityItems(), PT.FavRarities, function() PT:ControlRefresh() end)
end))
bCountButton(PetsScroll, ord(), "Favorite: pet types", function() return PT:Count(PT.FavTypes) end, needReady(function()
    PT:OpenPicker("Auto-favorite these pet types", petTypeItems(), PT.FavTypes, function() PT:ControlRefresh() end)
end))
bToggle(PetsScroll, ord(), "Auto Sell Inventory Pets", opt("AutoSell"), setOpt("AutoSell"),
    "Auto Sell sells EVERY non-favorited pet in your backpack. Tap again to confirm.")
bConfirmButton(PetsScroll, ord(), "Sell All Inventory Pets", "TAP AGAIN: sells all non-favorited bag pets", needReady(function()
    PT:Run("Selling all inventory pets", function(t) PT:SellAll(t) end)
end))
PT.SellLabel = bLabel(PetsScroll, ord(), PT.SellStatus, 30)
bLabel(PetsScroll, ord(), "Safety: pets matching your favorite rarity + type rules are never sold, even if Auto Favorites is off. Placed pets are never sold.", 44)

bButton(PetsScroll, ord(), "STOP ALL PET AUTOMATION", function() PT:StopAll() end).BackgroundColor3 = Color3.fromRGB(150, 55, 55)

-- Owned pets stays at the very bottom of the Pets tab.
-- Live owned-pet display (placed + inventory)
bHeader(PetsScroll, ord(), " Owned Pets")
PT.PlacedPetsLabel = bLabel(PetsScroll, ord(), "Placed Pets: loading...", 54)
PT.InventoryPetsLabel = bLabel(PetsScroll, ord(), "Inventory Pets: loading...", 54)

function PT:RefreshOwnedPetLabels()
    if not self.PlacedPetsLabel or not self.InventoryPetsLabel then return end

    local placed, inventory = {}, {}

    for _, pet in ipairs(self:PetList()) do
        local mutation = pet.Mutation and pet.Mutation ~= "" and (" [" .. tostring(pet.Mutation) .. "]") or ""
        local income = self:Format(pet.Income or 0)
        local speed = self:Format(pet.Speed or 0)
        local status = pet.Placed and "Placed" or "Inventory"

        local entry = string.format(
            "%s%s | $%s/s | %s speed | %s",
            tostring(pet.Name),
            mutation,
            income,
            speed,
            status
        )

        if pet.Placed then
            placed[#placed + 1] = {Text = entry, Income = pet.Income or 0, Speed = pet.Speed or 0}
        else
            inventory[#inventory + 1] = {Text = entry, Income = pet.Income or 0, Speed = pet.Speed or 0}
        end
    end

    local function sortPets(a, b)
        if a.Income == b.Income then return a.Speed > b.Speed end
        return a.Income > b.Income
    end
    table.sort(placed, sortPets)
    table.sort(inventory, sortPets)

    local function textFor(title, list)
        if #list == 0 then return title .. " (0)\nNone" end

        local lines = {title .. " (" .. tostring(#list) .. ")"}
        for i = 1, math.min(#list, 10) do
            lines[#lines + 1] = list[i].Text
        end
        if #list > 10 then
            lines[#lines + 1] = "+" .. tostring(#list - 10) .. " more"
        end
        return table.concat(lines, "\n")
    end

    self.PlacedPetsLabel.Text = textFor("Placed Pets", placed)
    self.InventoryPetsLabel.Text = textFor("Inventory Pets", inventory)

    -- Give the labels enough room for multiple stat rows.
    local placedRows = math.min(#placed, 10) + 1 + (#placed > 10 and 1 or 0)
    local inventoryRows = math.min(#inventory, 10) + 1 + (#inventory > 10 and 1 or 0)
    self.PlacedPetsLabel.Size = UDim2.new(1, -8, 0, math.max(44, placedRows * 28))
    self.InventoryPetsLabel.Size = UDim2.new(1, -8, 0, math.max(44, inventoryRows * 28))
end


-- 13. ESP+ section, appended to the bottom of the existing ESP tab
do
    local espScroll = PanelESP:FindFirstChildOfClass("ScrollingFrame")
    if espScroll then
        local e = 1000
        local function eo() e = e + 1 return e end
        bHeader(espScroll, eo(), " Egg ESP+ (all active eggs on the map)")
        bToggle(espScroll, eo(), "Egg ESP+", opt("ESP"), setOpt("ESP"))
        local labels = { {"ESPName","Show name"},{"ESPRarity","Show rarity"},{"ESPDistance","Show distance"},
            {"ESPWeight","Show weight"},{"ESPMutation","Show mutation"},{"ESPLuck","Show luck"},
            {"ESPBoxes","Show boxes"},{"ESPTracers","Show tracers"},{"ESPMutatedOnly","Mutated eggs only"} }
        for _, entry in ipairs(labels) do bToggle(espScroll, eo(), entry[2], opt(entry[1]), setOpt(entry[1])) end
        bCountButton(espScroll, eo(), "Rarities to show", function() return PT:Count(PT.ESPRarities) end, function()
            PT:OpenPicker("Egg ESP+ rarities", rarityItems(), PT.ESPRarities, function() PT:ControlRefresh(); if PT.Ready then pcall(function() PT:UpdateESP() end) end end)
        end)
        bInput(espScroll, eo(), "Max distance (studs)", function() return PT.Options.ESPMaxDistance end,
            function(v) PT.Options.ESPMaxDistance = math.clamp(math.floor(v), 50, 20000) end)
        bInput(espScroll, eo(), "Max eggs shown", function() return PT.Options.ESPCount end,
            function(v) PT.Options.ESPCount = math.clamp(math.floor(v), 1, 100) end)
        bInput(espScroll, eo(), "Min luck", function() return PT.Options.ESPMinLuck end,
            function(v) PT.Options.ESPMinLuck = math.max(0, v) end)
        bInput(espScroll, eo(), "Text size", function() return PT.Options.ESPSize end,
            function(v) PT.Options.ESPSize = math.clamp(math.floor(v), 8, 28) end)
    end
end

PT:ControlRefresh()

-- Settings: runtime error viewer
do
    local errorHeader = Instance.new("TextLabel")
    errorHeader.Size = UDim2.new(1, -8, 0, 18)
    errorHeader.BackgroundTransparency = 1
    errorHeader.Font = Enum.Font.GothamBold
    errorHeader.Text = " Script Errors"
    errorHeader.TextColor3 = Color3.fromRGB(255, 150, 150)
    errorHeader.TextSize = 11
    errorHeader.TextXAlignment = Enum.TextXAlignment.Left
    errorHeader.LayoutOrder = 90000
    errorHeader.Parent = SettingsScroll

    local errorBox = Instance.new("TextLabel")
    errorBox.Size = UDim2.new(1, -8, 0, 72)
    errorBox.BackgroundColor3 = THEME.Panel
    errorBox.BorderSizePixel = 0
    errorBox.Font = Enum.Font.Code
    errorBox.TextSize = 10
    errorBox.TextColor3 = Color3.fromRGB(235, 220, 220)
    errorBox.TextWrapped = true
    errorBox.TextXAlignment = Enum.TextXAlignment.Left
    errorBox.TextYAlignment = Enum.TextYAlignment.Top
    errorBox.LayoutOrder = 90001
    errorBox.Parent = SettingsScroll
    round(errorBox, 6)
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 8)
    pad.PaddingRight = UDim.new(0, 8)
    pad.PaddingTop = UDim.new(0, 6)
    pad.Parent = errorBox

    local clearErrors = Instance.new("TextButton")
    clearErrors.Size = UDim2.new(1, -8, 0, 30)
    clearErrors.BackgroundColor3 = THEME.Button
    clearErrors.BorderSizePixel = 0
    clearErrors.Font = Enum.Font.GothamBold
    clearErrors.Text = "Clear Errors"
    clearErrors.TextColor3 = Color3.new(1, 1, 1)
    clearErrors.TextSize = 11
    clearErrors.LayoutOrder = 90002
    clearErrors.Parent = SettingsScroll
    round(clearErrors, 6)

    local function refreshErrors()
        local errors = PT.Errors or {}
        if #errors == 0 then
            errorBox.Text = "No script errors detected."
            return
        end
        local lines = {}
        for i = math.max(1, #errors - 5), #errors do
            lines[#lines + 1] = "• " .. tostring(errors[i])
        end
        errorBox.Text = table.concat(lines, "\n")
    end

    clearErrors.Activated:Connect(function()
        table.clear(PT.Errors)
        refreshErrors()
    end)

    task.spawn(function()
        while Running and errorBox.Parent do
            refreshErrors()
            task.wait(1)
        end
    end)
end


--------------------------------------------------------------------
-- Status refresh + main loop
--------------------------------------------------------------------
function PT:RefreshStatus()
    if not self.StatusLabel or not self.StatusLabel.Parent then return end
    self.StatusLabel.Text = string.format("%s\nBest placed: %d | Fed: %d | Bought: %d | Sold: %d | Favorited: %d",
        tostring(self.Status), self.Placed, self.FoodFed, self.FoodBought, self.SoldPets, self.FavoritedPets)
    if self.FoodLabel then self.FoodLabel.Text = tostring(self.FoodStatus) end
    if self.SellLabel then self.SellLabel.Text = tostring(self.SellStatus) end
end

task.spawn(function()
    local ok, err = pcall(function() PT:Init() end)
    if not ok then
        PT.Status = "Pet tools unavailable in this game/server"
        warn("[PetTools] init failed: " .. tostring(err))
    end
end)

task.spawn(function()
    local lastESP = 0
    while PT.Alive and Running do
        task.wait(0.1)
        if PT.Ready then
            local ok, err = pcall(function() PT:Tick() end)
            if not ok then PT:Err("Tick", err) end
            if os.clock() - lastESP >= 0.1 then
                lastESP = os.clock()
                pcall(function() PT:UpdateESP() end)
            end
        end
        pcall(function() PT:RefreshStatus() end)
    end
end)

Env.PetToolsUnload = function()
    PT.Alive = false
    pcall(function() PT:CancelJob() end)
    pcall(function() PT:ClearESP() end)
    pcall(function() espGui:Destroy() end)
    if Env.PetToolsUnload then Env.PetToolsUnload = nil end
end
end


--====================================================
-- MINIMIZE & DRAG SYSTEM
--====================================================

local function minimize()
    IsMinimized = true
    if not Bubble:GetAttribute("HasPosition") then
        Bubble.Position = UDim2.new(1, -64, 0.5, -25)
        Bubble:SetAttribute("HasPosition", true)
    end
    Main.Visible = false
    Bubble.Visible = true
end

local function restore()
    IsMinimized = false
    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    Main.Position = UDim2.fromScale(0.5, 0.5)
    Bubble.Visible = false
    Main.Visible = true
end

MinButton.MouseButton1Click:Connect(minimize)

local function makeDraggable(handle, target, onTap)
    local dragging = false
    local dragStart
    local startPosition
    local moved = 0

    table.insert(Connections, handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            moved = 0
            dragStart = input.Position
            startPosition = target.Position
        end
    end))

    table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
        if dragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then
            local delta = input.Position - dragStart
            moved = math.max(moved, delta.Magnitude)
            target.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end))

    table.insert(Connections, UserInputService.InputEnded:Connect(function(input)
        if dragging and (
            input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
        ) then
            dragging = false
            if onTap and moved < 8 then onTap() end
        end
    end))
end

makeDraggable(TitleBar, Main)
makeDraggable(Bubble, Bubble, restore)

--====================================================
-- SHUTDOWN
--====================================================

local function shutdown()
    Running = false
    do
        local e = getgenv and getgenv() or _G
        if e.PetToolsUnload then pcall(e.PetToolsUnload) end
    end
    for _, conn in pairs(Connections) do
        if conn then pcall(function() conn:Disconnect() end) end
    end
    for _, data in pairs(ESPs) do
        if data.Gui then pcall(function() data.Gui:Destroy() end) end
        if data.Highlight then pcall(function() data.Highlight:Destroy() end) end
    end
    if ScreenGui then ScreenGui:Destroy() end
end

Close.MouseButton1Click:Connect(shutdown)
