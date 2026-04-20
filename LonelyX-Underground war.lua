local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "LonelyX",
    SubTitle = " [ underground war 2.0] Upgraded Version",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    Aimbot = Window:AddTab({ Title = "Aimbot", Icon = "crosshairs" }),
    Combat = Window:AddTab({ Title = "Combat", Icon = "swords" }),
    Player = Window:AddTab({ Title = "Player", Icon = "user" }),
    Visual = Window:AddTab({ Title = "Visual", Icon = "eye" }),
    Teleport = Window:AddTab({ Title = "Teleport", Icon = "map-pin" }),
    OtherTools = Window:AddTab({ Title = "Other Tools", Icon = "box" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
    Terminal = Window:AddTab({ Title = "Terminal", Icon = "terminal" }) -- Tab Terminal mới
}

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Camera = workspace.CurrentCamera
local ClientName = identifyexecutor and identifyexecutor() or "Unknown Client"

--------------------------------------------------------------------------------
-- HỆ THỐNG NGÔN NGỮ & TERMINAL LOGS
--------------------------------------------------------------------------------
local CurrentLang = "VIETNAM"
local terminalLogs = {}
local maxLogs = 15

local TerminalParagraph = Tabs.Terminal:AddParagraph({ Title = "Console Output / Tiến trình", Content = "Waiting for events...\n" })

local function logMsg(enMsg, viMsg)
    local msg = (CurrentLang == "VIETNAM") and viMsg or enMsg
    local timeStr = os.date("[%H:%M:%S] ")
    table.insert(terminalLogs, 1, timeStr .. msg) -- Thêm vào đầu danh sách
    if #terminalLogs > maxLogs then
        table.remove(terminalLogs, #terminalLogs)
    end
    if TerminalParagraph then
        TerminalParagraph:SetDesc(table.concat(terminalLogs, "\n"))
    end
end

local function CustomNotify(enTitle, enContent, viTitle, viContent, duration)
    local t = (CurrentLang == "VIETNAM") and viTitle or enTitle
    local c = (CurrentLang == "VIETNAM") and viContent or enContent
    Fluent:Notify({ Title = t, Content = c, Duration = duration or 3 })
end

logMsg("Script loaded successfully.", "Script đã tải thành công.")

--------------------------------------------------------------------------------
-- TAB: MAIN
--------------------------------------------------------------------------------
Tabs.Main:AddParagraph({ Title = "User Name", Content = "Tên: " .. Player.Name .. " | Hiển thị: " .. Player.DisplayName })
Tabs.Main:AddParagraph({ Title = "Client Name", Content = ClientName })

local TimeParagraph = Tabs.Main:AddParagraph({ Title = "Time", Content = os.date("%H:%M:%S - %d/%m/%Y") })
task.spawn(function()
    while task.wait(1) do
        if TimeParagraph then TimeParagraph:SetDesc(os.date("%H:%M:%S - %d/%m/%Y")) end
    end
end)
Tabs.Main:AddParagraph({ Title = "⚠️ Warning Description", Content = "Bản nâng cấp Deep Processing. Vui lòng cân nhắc trước khi sử dụng." })

--------------------------------------------------------------------------------
-- TAB: AIMBOT & NO RELOAD (UPGRADED)
--------------------------------------------------------------------------------
local aimbotEnabled = false
local aimbotToolName = "Sniper"
local bulletSpeed = 800
local noReloadEnabled = false
local aimTargetPart = "Head"

local AimbotToggle = Tabs.Aimbot:AddToggle("AimbotToggle", { 
    Title = "Aimbot Sniper (Silent)", 
    Description = "Tự động ngắm và bắn mục tiêu gần nhất khi cầm súng", 
    Default = false, 
    Callback = function(Value) aimbotEnabled = Value end 
})

Tabs.Aimbot:AddDropdown("AimbotPartDropdown", {
    Title = "Vị trí ngắm (Target Part)",
    Description = "Chọn bộ phận để Aimbot nhắm tới",
    Values = {"Head", "HumanoidRootPart"},
    Multi = false,
    Default = 1,
    Callback = function(Value) aimTargetPart = Value end
})

Tabs.Aimbot:AddKeybind("AimbotKeybind", {
    Title = "Phím tắt bật/tắt Aimbot",
    Mode = "Toggle",
    Default = "Z",
    Callback = function(Value) AimbotToggle:SetValue(Value) end
})

Tabs.Aimbot:AddSlider("BulletSpeedSlider", {
    Title = "Tốc độ đạn (Bullet Speed)",
    Description = "Chỉnh tốc độ đạn để dự đoán mục tiêu chính xác hơn",
    Default = 800,
    Min = 100,
    Max = 3000,
    Rounding = 1,
    Callback = function(Value) bulletSpeed = Value end
})

Tabs.Aimbot:AddToggle("NoReloadToggle", { 
    Title = "No Reload (Deep Scan)", 
    Description = "Xóa thời gian nạp đạn (Can thiệp Value, Attributes & Module)", 
    Default = false, 
    Callback = function(Value) noReloadEnabled = Value end 
})

local function getEquippedSniper()
    if not Player.Character then return end
    for _, tool in ipairs(Player.Character:GetChildren()) do
        if tool:IsA("Tool") and tool.Name == aimbotToolName then return tool end
    end
    return nil
end

local function getClosestSniperTarget()
    if not Player.Character or not Player.Character:FindFirstChild("Head") then return end
    local origin = Player.Character.Head.Position
    local closestPlayer, shortestDistance, aimPosition

    for _, targetPlayer in ipairs(Players:GetPlayers()) do
        if targetPlayer ~= Player and targetPlayer.Team ~= Player.Team and targetPlayer.Team then
            local targetChar = targetPlayer.Character
            local targetNode = targetChar and targetChar:FindFirstChild(aimTargetPart)
            local humanoid = targetChar and targetChar:FindFirstChild("Humanoid")
            local root = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
            
            if targetNode and humanoid and humanoid.Health > 0 and root then
                local distance = (targetNode.Position - origin).Magnitude
                local travelTime = distance / bulletSpeed
                local predictedPosition = targetNode.Position + root.Velocity * travelTime
                local ray = Ray.new(origin, (predictedPosition - origin).Unit * 1000)
                local hit = workspace:FindPartOnRay(ray, Player.Character)
                
                if hit and hit:IsDescendantOf(targetChar) then
                    if not shortestDistance or distance < shortestDistance then
                        shortestDistance = distance
                        closestPlayer = targetChar
                        aimPosition = predictedPosition
                    end
                end
            end
        end
    end
    return aimPosition
end

task.spawn(function()
    local RemoteEventPath = nil
    pcall(function() RemoteEventPath = ReplicatedStorage:WaitForChild("Events", 2):WaitForChild("Remote", 2):WaitForChild("ShotTarget", 2) end)
    while task.wait() do
        if aimbotEnabled then
            if not RemoteEventPath then pcall(function() RemoteEventPath = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Remote"):WaitForChild("ShotTarget") end) end
            local tool = getEquippedSniper()
            if tool and RemoteEventPath then
                local position = getClosestSniperTarget()
                if position then pcall(function() RemoteEventPath:FireServer(position, aimbotToolName) end) end
            end
        end
    end
end)

-- Vòng lặp No Reload (Đã nâng cấp can thiệp sâu)
task.spawn(function()
    while task.wait(0.2) do
        if noReloadEnabled and Player.Character then
            local tool = Player.Character:FindFirstChildOfClass("Tool")
            if tool then
                -- Lớp 1: Can thiệp Values truyền thống
                for _, v in pairs(tool:GetDescendants()) do
                    if v:IsA("NumberValue") or v:IsA("IntValue") then
                        local name = v.Name:lower()
                        if name:match("reload") or name:match("cooldown") or name:match("firerate") or name:match("wait") then
                            v.Value = 0
                        end
                    end
                end
                -- Lớp 2: Can thiệp Attributes
                for name, val in pairs(tool:GetAttributes()) do
                    local lname = name:lower()
                    if type(val) == "number" and (lname:match("reload") or lname:match("cooldown") or lname:match("rate")) then
                        tool:SetAttribute(name, 0)
                    end
                end
                -- Lớp 3: Can thiệp ModuleScript (Settings/GunStates)
                for _, v in pairs(tool:GetDescendants()) do
                    if v:IsA("ModuleScript") and (v.Name:lower():match("setting") or v.Name:lower():match("state") or v.Name:lower():match("config")) then
                        pcall(function()
                            local conf = require(v)
                            if type(conf) == "table" then
                                if conf.ReloadTime then conf.ReloadTime = 0 end
                                if conf.FireRate then conf.FireRate = 0 end
                                if conf.Cooldown then conf.Cooldown = 0 end
                                if conf.WaitTime then conf.WaitTime = 0 end
                            end
                        end)
                    end
                end
            end
        end
    end
end)

--------------------------------------------------------------------------------
-- TAB: COMBAT (KILLAURA & OP REACH UPGRADED)
--------------------------------------------------------------------------------
local killAuraReach = 10
local toolTargetName = "sword"
_G.enemOnly = true
local loop = false
local retry = false

local reachOpEnabled = false
local reachOpRadius = 15
local originalSizes = {}

local function findTool(toolName)
    local strl = toolName:lower()
    for _, v in pairs(Player.Backpack:GetChildren()) do
        if v.Name:lower():match(strl) ~= nil then return v end
    end
    if Player.Character then
        for _, v in pairs(Player.Character:GetChildren()) do
            if v.Name:lower():match(strl) ~= nil then return v end
        end
    end
    return nil
end

local function getTool()
    return findTool(toolTargetName)
end

-- KillAura giữ nguyên nhưng tối ưu logic
local function KillAura()
    loop = true
    repeat
        for i,v in pairs(game.Players:GetPlayers()) do
            pcall(function()
                local isValidTarget = v ~= Player and v.Character and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health > 0 and v.Character:FindFirstChildOfClass("ForceField") == nil
                if _G.enemOnly and v.TeamColor.Name == Player.TeamColor.Name then isValidTarget = false end
                
                if isValidTarget then
                    local Distance = (v.Character.HumanoidRootPart.Position - Player.Character.HumanoidRootPart.Position).magnitude
                    if Distance <= tonumber(killAuraReach) then
                        for _ = 1, 25 do
                            Player.Character.Humanoid.RootPart.CFrame = v.Character.Humanoid.RootPart.CFrame * CFrame.new(-1.6, 0, 1.8)
                            local h = getTool()
                            if h then
                                h.Parent = Player.Character
                                h:Activate()
                                if Player.Character:FindFirstChildOfClass("Tool") and Player.Character:FindFirstChildOfClass("Tool").Name ~= h.Name then
                                    Player.Character:FindFirstChildOfClass("Humanoid"):UnequipTools()
                                end
                            end
                            if v.Character.Humanoid.Health <= 0 then
                                loop = false
                                if retry then
                                    task.wait(1)
                                    KillAura()
                                end
                            end
                        end
                    end 
                end
            end)
        end
        game:GetService("RunService").Heartbeat:Wait()
    until loop == false
end

Tabs.Combat:AddToggle("KillAuraToggle", { Title = "KillAura", Description = "Tự động dịch chuyển ra sau lưng và chém", Default = false, Callback = function(Value)
    if Value then loop = true; retry = true; task.spawn(KillAura) else loop = false; retry = false end
end })

-- Nâng cấp OP Reach: Can thiệp thẳng vào Handle Size
Tabs.Combat:AddToggle("ReachOpToggle", { Title = "Sword Reach OP (Hitbox Expand)", Description = "Mở rộng Hitbox của Handle (Chuẩn xác 100%)", Default = false, Callback = function(Value) 
    reachOpEnabled = Value 
    if not Value and Player.Character then
        local tool = getTool()
        if tool and tool:FindFirstChild("Handle") then
            local handle = tool.Handle
            if originalSizes[tool] then
                handle.Size = originalSizes[tool]
                handle.Transparency = 0
                handle.Massless = false
            end
        end
    end
end })

Tabs.Combat:AddSlider("ReachOpSlider", { Title = "Reach Radius", Description = "Kích thước vùng chém", Default = 15, Min = 5, Max = 50, Rounding = 1, Callback = function(Value) reachOpRadius = Value end })

Tabs.Combat:AddDropdown("KillAuraMode", { Title = "Target Mode (KillAura)", Description = "Chọn mục tiêu", Values = {"Enemies Only", "Others (All)"}, Multi = false, Default = 1, Callback = function(Value)
    if Value == "Enemies Only" then _G.enemOnly = true else _G.enemOnly = false end
end })

Tabs.Combat:AddSlider("KillAuraReach", { Title = "Reach Distance (KillAura)", Description = "Khoảng cách quét mục tiêu (KillAura)", Default = 10, Min = 10, Max = 40, Rounding = 1, Callback = function(Value)
    killAuraReach = tonumber(Value)
end })

Tabs.Combat:AddInput("KillAuraToolInput", { Title = "Melee Tool Name", Default = "sword", Placeholder = "Nhập tên vũ khí...", Numeric = false, Finished = false, Callback = function(Value)
    toolTargetName = Value
end })

RunService.RenderStepped:Connect(function()
    if reachOpEnabled then
        local tool = Player.Character and Player.Character:FindFirstChildOfClass("Tool")
        if tool and tool.Name:lower():match(toolTargetName:lower()) then
            local handle = tool:FindFirstChild("Handle")
            if handle then
                if not originalSizes[tool] then originalSizes[tool] = handle.Size end
                handle.Massless = true
                handle.CanCollide = false
                handle.Size = Vector3.new(reachOpRadius, reachOpRadius, reachOpRadius)
                handle.Transparency = 0.8
                
                -- Kết hợp FireTouchInterest mạnh mẽ
                for _, v in pairs(Players:GetPlayers()) do
                    if v ~= Player and v.Team ~= Player.Team then
                        local targetHRP = v.Character and v.Character:FindFirstChild("HumanoidRootPart")
                        if targetHRP and (targetHRP.Position - handle.Position).Magnitude <= reachOpRadius then
                            pcall(function()
                                firetouchinterest(targetHRP, handle, 0)
                                firetouchinterest(targetHRP, handle, 1)
                            end)
                        end
                    end
                end
            end
        end
    end
end)

--------------------------------------------------------------------------------
-- TAB: PLAYER (ADVANCED MULTI-METHOD ANTICHEAT BYPASS)
--------------------------------------------------------------------------------
Tabs.Player:AddButton({ Title = "Bypass Anticheat", Description = "Vô hiệu hóa Anticheat (Local & External)", Callback = function()
    local targets = {Player.Character, Player.PlayerScripts}
    for _, folder in pairs(targets) do
        if folder then
            for _, v in pairs(folder:GetDescendants()) do
                if v:IsA("LocalScript") and (v.Name:lower():match("anti") or v.Name:lower():match("cheat")) then v.Disabled = true end
            end
        end
    end
    local success, err = pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Roblox-HttpSpy/Random-Silly-stuff/refs/heads/main/UW2-AnticheatBypasser.lua"))() end)
    if success then Fluent:Notify({ Title = "Bypass thành công", Content = "Đã thực thi Anticheat Bypasser từ GitHub", Duration = 5 }) else Fluent:Notify({ Title = "Lỗi", Content = "Không thể tải script bypass bên ngoài", Duration = 5 }) end
end })

Tabs.Player:AddButton({
    Title = "Deep Bypass Anticheat (Advanced Hook)",
    Description = "Hook MetaMethods, chặn Remote báo cáo và fake thông số",
    Callback = function()
        local bypassCount = 0
        -- 1. Tắt các script quét client-side hiện có
        for _, v in pairs(getinstances()) do
            if v:IsA("LocalScript") and (v.Name:lower():match("anti") or v.Name:lower():match("cheat") or v.Name:lower():match("detect")) then 
                pcall(function() v.Disabled = true; bypassCount = bypassCount + 1 end)
            end
        end
        
        -- 2. Hook MetaMethod nhiều lớp
        local success, err = pcall(function()
            local oldNamecall
            oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                local method = getnamecallmethod()
                local args = {...}
                if not checkcaller() then
                    -- Chặn kick/ban cơ bản
                    if method == "Kick" or method == "kick" or method == "Ban" then return nil end
                    -- Chặn gửi log/report lên server
                    if method == "FireServer" or method == "InvokeServer" then
                        local pathStr = tostring(self):lower()
                        local argStr = tostring(args[1]):lower()
                        if pathStr:match("ban") or pathStr:match("kick") or pathStr:match("log") or pathStr:match("report") or pathStr:match("detect") or
                           argStr:match("ban") or argStr:match("kick") or argStr:match("exploit") or argStr:match("hack") then
                            return nil
                        end
                    end
                end
                return oldNamecall(self, ...)
            end)
            
            local oldIndex
            oldIndex = hookmetamethod(game, "__index", function(self, key)
                if not checkcaller() and (key == "WalkSpeed" or key == "JumpPower") then
                    return 16 -- Luôn báo về Server là đang chạy/nhảy bình thường
                end
                return oldIndex(self, key)
            end)

            local oldNewIndex
            oldNewIndex = hookmetamethod(game, "__newindex", function(self, key, value)
                -- Chặn server cố gắng set lại tốc độ của bạn
                if not checkcaller() and self:IsA("Humanoid") and (key == "WalkSpeed" or key == "JumpPower") then
                    return 
                end
                return oldNewIndex(self, key, value)
            end)
        end)
        
        if success then 
            Fluent:Notify({ Title = "Advanced Bypass", Content = "Đã vô hiệu hóa " .. bypassCount .. " AC Scripts và kích hoạt Full Hooks!", Duration = 5 }) 
        else 
            Fluent:Notify({ Title = "Lỗi Executor", Content = "Executor của bạn thiếu hàm hookmetamethod!", Duration = 5 }) 
        end
    end
})

Tabs.Player:AddSlider("SpeedSlider", { Title = "Walk Speed", Default = 16, Min = 16, Max = 250, Rounding = 1, Callback = function(Value) if Player.Character and Player.Character:FindFirstChild("Humanoid") then Player.Character.Humanoid.WalkSpeed = Value end end })
Tabs.Player:AddSlider("JumpSlider", { Title = "Jump Power", Default = 50, Min = 50, Max = 300, Rounding = 1, Callback = function(Value) if Player.Character and Player.Character:FindFirstChild("Humanoid") then Player.Character.Humanoid.UseJumpPower = true; Player.Character.Humanoid.JumpPower = Value end end })

local noclip = false
Tabs.Player:AddToggle("NoclipToggle", { Title = "Noclip", Default = false, Callback = function(Value) noclip = Value end })
RunService.Stepped:Connect(function()
    if noclip and Player.Character then
        for _, part in pairs(Player.Character:GetDescendants()) do if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end end
    end
end)

local flying = false
local flySpeed = 50
local bg, bv
Tabs.Player:AddToggle("FlyToggle", { Title = "Fly", Default = false, Callback = function(Value)
    flying = Value
    local char = Player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart

    if flying then
        bg = Instance.new("BodyGyro", hrp); bg.P = 9e4; bg.maxTorque = Vector3.new(9e9, 9e9, 9e9); bg.cframe = hrp.CFrame
        bv = Instance.new("BodyVelocity", hrp); bv.velocity = Vector3.new(0, 0, 0); bv.maxForce = Vector3.new(9e9, 9e9, 9e9)
        char.Humanoid.PlatformStand = true
    else
        if bg then bg:Destroy() end
        if bv then bv:Destroy() end
        char.Humanoid.PlatformStand = false
    end
end })

RunService.RenderStepped:Connect(function()
    if flying and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
        local cam = workspace.CurrentCamera
        local moveDir = Vector3.new(0, 0, 0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end
        if moveDir.Magnitude > 0 then moveDir = moveDir.Unit end
        if bg and bv then bg.cframe = cam.CFrame; bv.velocity = moveDir * flySpeed end
    end
end)

local isInvisible = false
local originalTransparencies = {}

Tabs.Player:AddToggle("InvisToggle", {
    Title = "Tàng hình (Invisibility)",
    Description = "Làm trong suốt toàn bộ nhân vật của bạn",
    Default = false,
    Callback = function(Value)
        isInvisible = Value
        local char = Player.Character
        if char then
            if isInvisible then
                logMsg("Invisibility Enabled", "Đã bật tàng hình")
                for _, v in pairs(char:GetDescendants()) do
                    if v:IsA("BasePart") or v:IsA("Decal") then
                        if not originalTransparencies[v] then
                            originalTransparencies[v] = v.Transparency
                        end
                        v.Transparency = 1
                    end
                end
            else
                logMsg("Invisibility Disabled", "Đã tắt tàng hình")
                for v, trans in pairs(originalTransparencies) do
                    if v and v.Parent then
                        v.Transparency = trans
                    end
                end
                originalTransparencies = {}
            end
        end
    end
})

-- Vòng lặp giữ tàng hình liên tục (phòng trường hợp game tự reset đồ họa)
RunService.Stepped:Connect(function()
    if isInvisible and Player.Character then
        for _, v in pairs(Player.Character:GetDescendants()) do
            if v:IsA("BasePart") or v:IsA("Decal") then
                v.Transparency = 1
            end
        end
    end
end)

local fakeLagEnabled = false
local fakeLagIntensity = 0.5

Tabs.Player:AddToggle("FakeLagToggle", {
    Title = "Fake Lag (Ping ảo)",
    Description = "Làm bạn di chuyển giật cục trên màn hình người khác (khó bị bắn trúng)",
    Default = false,
    Callback = function(Value)
        fakeLagEnabled = Value
        pcall(function()
            if Value then
                settings().Network.IncomingReplicationLag = fakeLagIntensity
            else
                settings().Network.IncomingReplicationLag = 0
            end
        end)
    end
})

Tabs.Player:AddSlider("FakeLagSlider", {
    Title = "Độ trễ Fake Lag",
    Description = "Càng cao thì càng giật (Tính bằng giây)",
    Default = 0.5,
    Min = 0.1,
    Max = 3.0,
    Rounding = 1,
    Callback = function(Value)
        fakeLagIntensity = Value
        if fakeLagEnabled then
            pcall(function() settings().Network.IncomingReplicationLag = Value end)
        end
    end
})


--------------------------------------------------------------------------------
-- TAB: VISUAL (ESP & TRACER)
--------------------------------------------------------------------------------
local ESPEnabled = false
local TracersEnabled = false

Tabs.Visual:AddToggle("ESPToggle", { Title = "ESP Kẻ địch (Khung)", Default = false, Callback = function(Value) ESPEnabled = Value end })
Tabs.Visual:AddToggle("TracerToggle", { Title = "Tracer Kẻ địch (Đường kẻ)", Default = false, Callback = function(Value) TracersEnabled = Value end })

local function IsEnemy(plr)
    if plr == Player then return false end
    if plr.Team and Player.Team and plr.Team == Player.Team then return false end
    return true
end

local ESP_Boxes = {}
local ESP_Tracers = {}

local function CreateESP(plr)
    local box = Drawing.new("Square"); box.Visible = false; box.Color = Color3.fromRGB(255, 50, 50); box.Thickness = 1.5; box.Transparency = 1; box.Filled = false
    local tracer = Drawing.new("Line"); tracer.Visible = false; tracer.Color = Color3.fromRGB(255, 50, 50); tracer.Thickness = 1.5; tracer.Transparency = 1
    ESP_Boxes[plr] = box
    ESP_Tracers[plr] = tracer
end

local function RemoveESP(plr)
    if ESP_Boxes[plr] then ESP_Boxes[plr]:Remove(); ESP_Boxes[plr] = nil end
    if ESP_Tracers[plr] then ESP_Tracers[plr]:Remove(); ESP_Tracers[plr] = nil end
end

for _, plr in ipairs(Players:GetPlayers()) do if plr ~= Player then CreateESP(plr) end end
Players.PlayerAdded:Connect(function(plr) if plr ~= Player then CreateESP(plr) end end)
Players.PlayerRemoving:Connect(function(plr) RemoveESP(plr) end)

RunService.RenderStepped:Connect(function()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player then
            local box = ESP_Boxes[plr]; local tracer = ESP_Tracers[plr]
            if box and tracer then
                local char = plr.Character
                if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 and IsEnemy(plr) then
                    local hrp = char.HumanoidRootPart
                    local head = char:FindFirstChild("Head")
                    local vector, onScreen = Camera:WorldToViewportPoint(hrp.Position)

                    if onScreen then
                        if ESPEnabled and head then
                            local headPos, _ = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                            local legPos, _ = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                            local height = math.abs(headPos.Y - legPos.Y); local width = height / 2
                            box.Size = Vector2.new(width, height); box.Position = Vector2.new(vector.X - width / 2, vector.Y - height / 2)
                            box.Visible = true
                        else box.Visible = false end

                        if TracersEnabled then
                            tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                            tracer.To = Vector2.new(vector.X, vector.Y)
                            tracer.Visible = true
                        else tracer.Visible = false end
                    else box.Visible = false; tracer.Visible = false end
                else box.Visible = false; tracer.Visible = false end
            end
        end
    end
end)
--------------------------------------------------------------------------------
-- TAB: TELEPORT (DROPDOWN MENU - OPTIMIZED)
--------------------------------------------------------------------------------

local TeleportSettings = {
    Team = "Red",
    Type = "Spawn",
    HoleMode = "Legit" -- "Legit" (Cái đầu tiên) hoặc "Random" (Ngẫu nhiên)
}

-- Hàm tìm đối tượng dựa trên cấu trúc Dex thực tế
local function GetTargetObject()
    local map = workspace:FindFirstChild("Map")
    if not map then return nil end
    local teamFolder = map:FindFirstChild(TeleportSettings.Team)
    if not teamFolder then return nil end

    if TeleportSettings.Type == "Spawn" then
        local spawns = teamFolder:FindFirstChild("Spawns")
        return spawns and spawns:GetChildren()[1]
    elseif TeleportSettings.Type == "Flag" then
        local flag = teamFolder:FindFirstChild("Flag")
        return flag and (flag:FindFirstChild("Handle") or flag)
    elseif TeleportSettings.Type == "Hole" then
        local holes = {}
        for _, v in pairs(teamFolder:GetChildren()) do
            -- Theo Dex: Hole là Model chứa Part "NotDirt"
            if v.Name == "Hole" then
                local part = v:FindFirstChild("NotDirt") or v:FindFirstChildWhichIsA("BasePart")
                if part then table.insert(holes, part) end
            end
        end
        
        if #holes > 0 then
            if TeleportSettings.HoleMode == "Random" then
                return holes[math.random(1, #holes)]
            else
                return holes[1] -- Chế độ Legit lấy cái hố đầu tiên tìm thấy
            end
        end
    end
    return nil
end

-- UI PHẦN DROPDOWN
Tabs.Teleport:AddDropdown("TP_Team", {
    Title = "Chọn Phe (TEAM)",
    Values = {"Red", "Blue"},
    Default = "Red",
    Callback = function(Value) TeleportSettings.Team = Value end
})

Tabs.Teleport:AddDropdown("TP_Type", {
    Title = "Loại địa điểm (TYPE)",
    Values = {"Spawn", "Flag", "Hole"},
    Default = "Spawn",
    Callback = function(Value) TeleportSettings.Type = Value end
})

Tabs.Teleport:AddDropdown("TP_HoleMode", {
    Title = "Chế độ Hố (MODE - Only for Hole)",
    Values = {"Legit", "Random"},
    Default = "Legit",
    Callback = function(Value) TeleportSettings.HoleMode = Value end
})

Tabs.Teleport:AddButton({
    Title = "Thực hiện Dịch chuyển (TELEPORT NOW)",
    Description = "Bấm để dịch chuyển theo cấu hình trên",
    Callback = function()
        local target = GetTargetObject()
        if target and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
            -- Dịch chuyển cao hơn 5 unit để tránh kẹt map
            Player.Character.HumanoidRootPart.CFrame = target.CFrame + Vector3.new(0, 5, 0)
            Fluent:Notify({ Title = "Teleport", Content = "Đã tới " .. TeleportSettings.Type .. " phe " .. TeleportSettings.Team, Duration = 2 })
        else
            Fluent:Notify({ Title = "Lỗi", Content = "Không tìm thấy mục tiêu yêu cầu!", Duration = 3 })
        end
    end
})
--------------------------------------------------------------------------------
-- TAB: OTHER TOOLS (DEX & INFINITE YIELD)
--------------------------------------------------------------------------------
Tabs.OtherTools:AddButton({
    Title = "Mở Dark Dex v4",
    Description = "Explorer mạnh mẽ dùng để soi đường dẫn và cấu trúc game",
    Callback = function()
        local success, err = pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"))()
        end)
        if success then
            logMsg("Loaded Dark Dex v4", "Đã khởi chạy Dark Dex")
            Fluent:Notify({ Title = "Thành công", Content = "Đã tải Dark Dex v4!", Duration = 3 })
        else
            Fluent:Notify({ Title = "Lỗi", Content = "Không thể tải script. Executor có thể không hỗ trợ.", Duration = 4 })
        end
    end
})

Tabs.OtherTools:AddButton({
    Title = "Mở Infinite Yield",
    Description = "Menu Admin Commands xịn nhất mọi thời đại",
    Callback = function()
        local success, err = pcall(function()
            loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
        end)
        if success then
            logMsg("Loaded Infinite Yield", "Đã khởi chạy Infinite Yield")
            Fluent:Notify({ Title = "Thành công", Content = "Đã tải Infinite Yield!", Duration = 3 })
        else
            Fluent:Notify({ Title = "Lỗi", Content = "Không thể tải script. Executor có thể không hỗ trợ.", Duration = 4 })
        end
    end
})

--------------------------------------------------------------------------------
-- TAB: SETTINGS
--------------------------------------------------------------------------------
Tabs.Settings:AddDropdown("LangDropdown", {
    Title = "Language / Ngôn ngữ",
    Description = "Thay đổi ngôn ngữ hiển thị thông báo & Terminal",
    Values = {"VIETNAM", "ENGLISH"},
    Multi = false,
    Default = 1,
    Callback = function(Value)
        CurrentLang = Value
        logMsg("Language changed to " .. Value, "Đã đổi ngôn ngữ sang " .. Value)
    end
})

Tabs.Settings:AddButton({ Title = "Fix Lag", Description = "Giảm tối đa đồ họa để tăng FPS", Callback = function()
    local Lighting = game:GetService("Lighting"); local Terrain = workspace.Terrain
    Terrain.WaterWaveSize = 0; Terrain.WaterWaveSpeed = 0; Terrain.WaterReflectance = 0; Terrain.WaterTransparency = 0
    Lighting.GlobalShadows = false; Lighting.FogEnd = 9e9; settings().Rendering.QualityLevel = "Level01"
    for _, v in pairs(game:GetDescendants()) do
        if v:IsA("BasePart") and not v:IsA("Terrain") then v.Material = Enum.Material.Plastic; v.Reflectance = 0
        elseif v:IsA("Decal") or v:IsA("Texture") then v.Transparency = 1
        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then v.Lifetime = NumberRange.new(0)
        elseif v:IsA("Explosion") then v.BlastPressure = 1; v.BlastRadius = 1
        elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") or v:IsA("Sparkles") then v.Enabled = false end
    end
    for _, e in pairs(Lighting:GetChildren()) do if e:IsA("PostEffect") then e.Enabled = false end end
    Fluent:Notify({ Title = "Fix Lag", Content = "Đã tối ưu hóa đồ họa!", Duration = 3 })
end })

InterfaceManager:SetLibrary(Fluent)
InterfaceManager:SetFolder("FluentScriptHub")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)

SaveManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetFolder("FluentScriptHub/UndergroundWar")
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)
SaveManager:LoadAutoloadConfig()