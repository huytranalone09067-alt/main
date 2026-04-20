local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Remotes = ReplicatedStorage:FindFirstChild("RemotesFolder") or ReplicatedStorage
local identifyexec = identifyexecutor and identifyexecutor() or "Unknown Client"

-- ==============================================================================
-- BỘ TẢI GIAO DIỆN AN TOÀN (SAFE LOADER)
-- ==============================================================================
local function NotifyError(msg)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Lỗi Tải UI",
            Text = msg,
            Duration = 10
        })
    end)
    warn("[LonelyX-Hub] " .. msg)
end

local success, FluentLoader = pcall(function()
    return loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))
end)

if not success or not FluentLoader then
    NotifyError("Không thể lấy dữ liệu từ GitHub. Kiểm tra lại mạng hoặc Executor!")
    return
end

local Fluent = FluentLoader()
if type(Fluent) ~= "table" then
    NotifyError("Thư viện Fluent tải thất bại (Trả về Nil). Executor của bạn có thể không hỗ trợ!")
    return
end

local Options = Fluent.Options
local HasDrawing = type(Drawing) ~= "nil"

-- ==============================================================================
-- BIẾN TOÀN CỤC & TRẠNG THÁI
-- ==============================================================================
local ScriptConnections = {}
local activeESPs = {}
local rainbowColor = Color3.new(1, 1, 1)
local freecamOn = false
local freecamSpeed = 1.5
local camCFrame = Camera.CFrame
local tpWalkOn = false
local tpWalkSpeed = 0.5

-- Vòng lặp màu Rainbow an toàn
task.spawn(function()
    while task.wait() do
        local tickTime = tick() % 5 / 5
        rainbowColor = Color3.fromHSV(tickTime, 1, 1)
    end
end)

-- ==============================================================================
-- KHỞI TẠO GIAO DIỆN
-- ==============================================================================
local Window = Fluent:CreateWindow({
    Title = "LonelyX-Hub",
    SubTitle = "Ultimate Full Edition",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 520),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightShift
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    Player = Window:AddTab({ Title = "Player", Icon = "user" }),
    Visuals = Window:AddTab({ Title = "Visuals", Icon = "image" }),
    ESP = Window:AddTab({ Title = "ESP", Icon = "eye" }),
    Demo = Window:AddTab({ Title = "Auto & Demo", Icon = "box" }),
    Support = Window:AddTab({ Title = "Support", Icon = "help-circle" }),
    TheMine = Window:AddTab({ Title = "The Mine", Icon = "map" }),
    Settings = Window:AddTab({ Title = "UI Settings", Icon = "settings" })
}

--------------------------------------------------------------------------------
-- MAIN TAB
--------------------------------------------------------------------------------
Tabs.Main:AddSection("Information")

local InfoParagraph = Tabs.Main:AddParagraph({
    Title = "Thông tin Hub",
    Content = "Đang tải dữ liệu..."
})

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local timeStr = os.date("%H:%M:%S - %d/%m/%Y")
            local currentRoom = LocalPlayer:GetAttribute("CurrentRoom") or 0
            local nextRoom = currentRoom + 1
            InfoParagraph:SetDesc(string.format(
                "Phát triển bởi: LonelyX\nDựa trên: CDoors\nThời gian: %s\nClient: %s\n\nCửa hiện tại: %04d | Cửa tiếp theo: %04d", 
                timeStr, 
                identifyexec,
                currentRoom,
                nextRoom
            ))
        end)
    end
end)

Tabs.Main:AddSection("Anti-Entities")

local function ToggleRemote(name, state)
    pcall(function()
        local remote = Remotes:FindFirstChild(name) or _G[name .. "_Storage"]
        if state then
            if remote then
                _G[name .. "_Storage"] = remote
                remote.Parent = nil
            end
        else
            local storage = _G[name .. "_Storage"]
            if storage then storage.Parent = Remotes end
        end
    end)
end

Tabs.Main:AddToggle("AntiA90", { Title = "Anti A-90", Default = false, Callback = function(v) ToggleRemote("A90", v) end })
Tabs.Main:AddToggle("AntiDread", { Title = "Anti Dread", Default = false, Callback = function(v) ToggleRemote("Dread", v) end })
Tabs.Main:AddToggle("AntiScreech", { Title = "Anti Screech", Default = false, Callback = function(v) ToggleRemote("Screech", v) end })
Tabs.Main:AddToggle("AntiGiggle", { Title = "Anti Giggle", Default = false, Callback = function(v) ToggleRemote("Giggle", v) end })
Tabs.Main:AddToggle("AntiHaste", { Title = "Anti Haste", Default = false, Callback = function(v) ToggleRemote("Haste", v) end })

--------------------------------------------------------------------------------
-- PLAYER TAB
--------------------------------------------------------------------------------
Tabs.Player:AddSection("Movement")

Tabs.Player:AddToggle("ToggleJump", {
    Title = "Toggle Jump",
    Default = false,
    Callback = function(Value)
        pcall(function()
            local char = workspace:FindFirstChild(LocalPlayer.Name)
            if char then char:SetAttribute("CanJump", Value) end
        end)
    end
})

Tabs.Player:AddToggle("ToggleSlide", {
    Title = "Toggle Slide",
    Default = false,
    Callback = function(Value)
        pcall(function()
            local char = workspace:FindFirstChild(LocalPlayer.Name)
            if char then char:SetAttribute("CanSlide", Value) end
        end)
    end
})

Tabs.Player:AddSection("TPWalk")

Tabs.Player:AddToggle("TPWalk", {
    Title = "Enable TPWalk",
    Default = false,
    Callback = function(Value) tpWalkOn = Value end
})

Tabs.Player:AddSlider("TPWalkSpeed", {
    Title = "TPWalk Speed",
    Default = 0.5, Min = 0.1, Max = 5, Rounding = 1,
    Callback = function(Value) tpWalkSpeed = Value end
})

Tabs.Player:AddSection("Freecam")

local FreecamToggle = Tabs.Player:AddToggle("Freecam", {
    Title = "Enable Freecam",
    Default = false,
    Callback = function(Value)
        freecamOn = Value
        pcall(function()
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if Value then
                if root then root.Anchored = true end 
                camCFrame = Camera.CFrame
                Camera.CameraType = Enum.CameraType.Scriptable
            else
                if root then root.Anchored = false end
                Camera.CameraType = Enum.CameraType.Custom
                if char and char:FindFirstChild("Humanoid") then
                    Camera.CameraSubject = char.Humanoid
                end
            end
        end)
    end
})

Tabs.Player:AddKeybind("FreecamBind", {
    Title = "Freecam Keybind", Mode = "Toggle", Default = "F",
    Callback = function() Options.Freecam:SetValue(not Options.Freecam.Value) end
})

Tabs.Player:AddSlider("FreecamSpeed", {
    Title = "Freecam Speed", Default = 1.5, Min = 0.1, Max = 5, Rounding = 1,
    Callback = function(Value) freecamSpeed = Value end
})

Tabs.Player:AddSection("Interaction")

Tabs.Player:AddToggle("InstaInteract", {
    Title = "Insta-Interact (No Hold)",
    Default = false,
    Callback = function(Value)
        if Value then
            for _, prompt in pairs(workspace:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") then prompt.HoldDuration = 0 end
            end
        end
    end
})

workspace.DescendantAdded:Connect(function(desc)
    pcall(function()
        if Options.InstaInteract and Options.InstaInteract.Value and desc:IsA("ProximityPrompt") then
            desc.HoldDuration = 0
        end
    end)
end)

Tabs.Player:AddSection("Economy")
Tabs.Player:AddSlider("GoldSlider", { Title = "Gold Amount", Default = 50, Min = 1, Max = 1000, Rounding = 0 })
Tabs.Player:AddButton({
    Title = "Add Gold (Visual)",
    Callback = function()
        pcall(function()
            local goldObj = LocalPlayer:FindFirstChild("Gold")
            if goldObj then goldObj.Value = goldObj.Value + Options.GoldSlider.Value end
        end)
    end
})

--------------------------------------------------------------------------------
-- VISUALS TAB
--------------------------------------------------------------------------------
Tabs.Visuals:AddSection("World")
Tabs.Visuals:AddToggle("Fullbright", {
    Title = "Fullbright",
    Default = false,
    Callback = function(Value)
        Lighting.ClockTime = Value and 12 or 14
        Lighting.GlobalShadows = not Value
        if Options.BrightnessSlider then
            Lighting.Brightness = Value and Options.BrightnessSlider.Value or 1
        end
    end
})

Tabs.Visuals:AddSlider("BrightnessSlider", {
    Title = "Fullbright Intensity", Default = 2, Min = 1, Max = 10, Rounding = 1,
    Callback = function(Value)
        if Options.Fullbright and Options.Fullbright.Value then Lighting.Brightness = Value end
    end
})

Tabs.Visuals:AddSection("Camera Settings")
Tabs.Visuals:AddToggle("ThirdPerson", {
    Title = "Third Person View", Default = false,
    Callback = function(Value)
        pcall(function()
            if Value then
                LocalPlayer.CameraMode = Enum.CameraMode.Classic
                LocalPlayer.CameraMaxZoomDistance = 15
                LocalPlayer.CameraMinZoomDistance = 10
            else
                LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
                LocalPlayer.CameraMaxZoomDistance = 0.5
                LocalPlayer.CameraMinZoomDistance = 0.5
            end
        end)
    end
})

table.insert(ScriptConnections, RunService.RenderStepped:Connect(function()
    if Options.ThirdPerson and Options.ThirdPerson.Value then
        pcall(function()
            LocalPlayer.CameraMode = Enum.CameraMode.Classic
            LocalPlayer.CameraMaxZoomDistance = 15
            LocalPlayer.CameraMinZoomDistance = 10
        end)
    end
end))

Tabs.Visuals:AddSection("Effects")
Tabs.Visuals:AddToggle("NoCameraShake", { 
    Title = "No Camera Shake", Default = false, 
    Callback = function(v) 
        local list = {"CamShake", "CamShakeClient", "CamShakeRelative", "CamShakeRelativeClient"}
        for _, name in pairs(list) do ToggleRemote(name, v) end
    end 
})

--------------------------------------------------------------------------------
-- ESP TAB
--------------------------------------------------------------------------------
Tabs.ESP:AddSection("ESP Toggles")
Tabs.ESP:AddToggle("DoorESP", { Title = "Door ESP (Cửa hiện tại & +1)", Default = false })
Tabs.ESP:AddColorpicker("FillColor", { Title = "Door Color", Default = Color3.fromRGB(0, 255, 0) })
Tabs.ESP:AddToggle("EntityESP", { Title = "Entity Highlight", Default = false })
Tabs.ESP:AddColorpicker("EntityColor", { Title = "Entity Color", Default = Color3.fromRGB(255, 0, 0) })
Tabs.ESP:AddToggle("ObjESP", { Title = "Objective ESP (Key/Lever)", Default = false })
Tabs.ESP:AddColorpicker("ObjColor", { Title = "Objective Color", Default = Color3.fromRGB(0, 0, 255) })
Tabs.ESP:AddToggle("GoldPileESP", { Title = "Gold Highlight", Default = false })
Tabs.ESP:AddColorpicker("GoldColor", { Title = "Gold Color", Default = Color3.fromRGB(255, 225, 0) })
Tabs.ESP:AddToggle("ItemESP", { Title = "Item Highlight", Default = false })
Tabs.ESP:AddColorpicker("ItemColor", { Title = "Item Color", Default = Color3.fromRGB(0, 255, 255) })
Tabs.ESP:AddToggle("HidingESP", { Title = "Hiding ESP", Default = false })
Tabs.ESP:AddColorpicker("HideCol", { Title = "Hiding Color", Default = Color3.fromRGB(100, 100, 100) })

Tabs.ESP:AddSection("Visual Settings")
local TracerToggle = Tabs.ESP:AddToggle("ShowTracers", { Title = "Enable Tracers (Đường kẻ)", Default = false })
if not HasDrawing then
    TracerToggle:SetValue(false)
    TracerToggle:Lock()
    Tabs.ESP:AddParagraph({Title = "Cảnh báo API", Content = "Executor của bạn không hỗ trợ Drawing API. Tính năng Tracers đã bị khóa."})
end

Tabs.ESP:AddToggle("RainbowESP", { Title = "Rainbow ESP", Default = false })
Tabs.ESP:AddToggle("NotifyEntity", { Title = "Notify Entity Spawn", Default = false })
Tabs.ESP:AddToggle("EnableText", { Title = "Enable Text (Name & Dist)", Default = false })
Tabs.ESP:AddSlider("TextSize", { Title = "Text Size", Default = 20, Min = 10, Max = 40, Rounding = 0 })
Tabs.ESP:AddSlider("MaxDistance", { Title = "Max ESP Distance", Default = 1500, Min = 50, Max = 5000, Rounding = 0 })

--------------------------------------------------------------------------------
-- AUTO & DEMO TAB
--------------------------------------------------------------------------------
Tabs.Demo:AddSection("Auto Collect & Loot Settings")
Tabs.Demo:AddToggle("AutoLootMaster", { Title = "Kích hoạt Auto Loot (Gần là nhặt)", Default = false })

local LootSelection = { Gold = true, Keys = true, Books = true, Items = false, Levers = true }
Tabs.Demo:AddToggle("LootGold", { Title = "Tự nhặt Vàng", Default = true, Callback = function(v) LootSelection.Gold = v end })
Tabs.Demo:AddToggle("LootKeys", { Title = "Tự nhặt Chìa khóa", Default = true, Callback = function(v) LootSelection.Keys = v end })
Tabs.Demo:AddToggle("LootSpecial", { Title = "Tự nhặt Sách/Gợi ý", Default = true, Callback = function(v) LootSelection.Books = v end })
Tabs.Demo:AddToggle("LootLevers", { Title = "Tự gạt Cần gạt", Default = true, Callback = function(v) LootSelection.Levers = v end })
Tabs.Demo:AddToggle("LootItems", { Title = "Tự nhặt Item khác", Default = false, Callback = function(v) LootSelection.Items = v end })

Tabs.Demo:AddSection("Auto Interaction")
Tabs.Demo:AddToggle("AutoOpenDoor", { 
    Title = "Auto Unlock Door", Default = false,
    Description = "Tự động mở khóa khi cầm chìa và đứng gần."
})

--------------------------------------------------------------------------------
-- HÀM CHUNG ESP & LOGIC
--------------------------------------------------------------------------------
local EntityNames = {"Rush", "Ambush", "Seek", "Eyes", "Screech", "Halt", "A-60", "A-120", "GiggleCeiling", "Giggle", "Dread", "MonumentEntity", "SallyMoving", "JeffTheKiller", "GloombatSwarm", "Grumble", "FigureRig", "Figure"}
local ObjList = {"ChestBox", "LockedChest", "Chest", "LibraryHintPaper", "LiveHintBook", "KeyObtain", "LeverForGate", "LiveBreakerPolePickup", "ElectricalKeyObtain", "Key"}
local ItemList = {"Lighter", "AK-47", "AlarmClock", "Aloe", "Bandage", "Battery", "BreakerPole", "Candle", "Crucifix", "ElectricalKey", "Flashlight", "G36C", "Generator", "HotelKey", "Keycard", "Level5Keycard", "Lockpick", "Potion", "SkeletonKey", "Vitamins", "GoldPile"}
local HSList = {"Locker_Large", "Toolshed", "Wardrobe", "Bed", "Backdoor_Wardrobe", "Rooms_Locker", "CircularVent"}

local function Cleanup(obj, data)
    pcall(function()
        if data.Highlight then data.Highlight:Destroy() end
        if data.Bill then data.Bill:Destroy() end
        if data.Tracer and HasDrawing then data.Tracer:Remove() end
    end)
    activeESPs[obj] = nil
end

local function IsEntity(name)
    for _, ent in pairs(EntityNames) do
        if string.find(name, ent) then return ent end
    end
    return nil
end

local function CreateESP(obj, name, type, roomNum)
    if activeESPs[obj] then return end
    local attachObj = obj
    if obj:IsA("Model") then
        attachObj = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart") or obj
    end
    activeESPs[obj] = { Name = name, Type = type, Attach = attachObj, RoomNum = roomNum }
end

-- Hàm kích hoạt Prompt an toàn (Hỗ trợ nhiều Executor hơn)
local function SafeFirePrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return end
    pcall(function()
        if fireproximityprompt then
            fireproximityprompt(prompt)
        else
            prompt:InputHoldBegin()
            task.wait(prompt.HoldDuration + 0.05)
            prompt:InputHoldEnd()
        end
    end)
end

--------------------------------------------------------------------------------
-- THREAD: AUTO LOOT & AUTO DOOR LOGIC
--------------------------------------------------------------------------------
task.spawn(function()
    while task.wait(0.1) do
        pcall(function()
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not root then return end

            local currentRoomNum = LocalPlayer:GetAttribute("CurrentRoom") or 0
            local rooms = workspace:FindFirstChild("CurrentRooms")
            if not rooms then return end

            local targetRooms = {rooms:FindFirstChild(tostring(currentRoomNum)), rooms:FindFirstChild(tostring(currentRoomNum + 1))}

            for _, room in pairs(targetRooms) do
                if not room then continue end

                -- Auto Unlock Door
                if Options.AutoOpenDoor and Options.AutoOpenDoor.Value then
                    local door = room:FindFirstChild("Door")
                    if door and door:FindFirstChild("Lock") then
                        local prompt = door.Lock:FindFirstChildOfClass("ProximityPrompt")
                        if prompt and prompt.Enabled then
                            local dist = (root.Position - door.Lock.Position).Magnitude
                            if dist < 12 then
                                local tool = char:FindFirstChildOfClass("Tool")
                                if tool and (tool.Name:find("Key") or tool.Name:find("Chìa")) then
                                    SafeFirePrompt(prompt)
                                end
                            end
                        end
                    end
                end

                -- Auto Loot Master
                if Options.AutoLootMaster and Options.AutoLootMaster.Value then
                    for _, prompt in pairs(room:GetDescendants()) do
                        if prompt:IsA("ProximityPrompt") and prompt.Enabled then
                            local parent = prompt.Parent
                            if parent and parent:IsA("BasePart") then
                                local dist = (root.Position - parent.Position).Magnitude
                                if dist <= (prompt.MaxActivationDistance + 4) then
                                    local n = parent.Name
                                    local shouldLoot = false
                                    
                                    if LootSelection.Gold and n == "GoldPile" then shouldLoot = true
                                    elseif LootSelection.Keys and (n:find("Key") or n == "KeyObtain") then shouldLoot = true
                                    elseif LootSelection.Books and (n:find("Book") or n:find("Paper")) then shouldLoot = true
                                    elseif LootSelection.Levers and n:find("Lever") then shouldLoot = true
                                    elseif LootSelection.Items and (parent:IsA("Tool") or (parent.Parent and parent.Parent:IsA("Tool"))) then shouldLoot = true end

                                    if shouldLoot then
                                        SafeFirePrompt(prompt)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
end)

--------------------------------------------------------------------------------
-- ENTITY THREADS
--------------------------------------------------------------------------------
workspace.ChildAdded:Connect(function(child)
    task.wait(0.1)
    pcall(function()
        local entName = IsEntity(child.Name)
        if entName then 
            local cleanName = entName:gsub("Moving", ""):gsub("Rig", ""):gsub("TheKiller", "")
            CreateESP(child, cleanName, "Entity", -1) 
            
            if Options.NotifyEntity and Options.NotifyEntity.Value and not string.find(cleanName, "Figure") then
                Fluent:Notify({ Title = " Cảnh báo Entity", Content = cleanName .. " vừa xuất hiện!", Duration = 4 })
            end
        end
    end)
end)

workspace.ChildRemoved:Connect(function(child)
    pcall(function()
        local entName = IsEntity(child.Name)
        if entName then
            local cleanName = entName:gsub("Moving", ""):gsub("Rig", ""):gsub("TheKiller", "")
            if Options.NotifyEntity and Options.NotifyEntity.Value and not string.find(cleanName, "Figure") then
                Fluent:Notify({ Title = " An toàn", Content = cleanName .. " đã đi qua/biến mất!", Duration = 4 })
            end
        end
    end)
end)

--------------------------------------------------------------------------------
-- QUÉT VẬT THỂ ESP THƯỜNG XUYÊN
--------------------------------------------------------------------------------
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            if not Options.DoorESP then return end -- Kiểm tra ui load xong chưa
            
            local rooms = workspace:FindFirstChild("CurrentRooms")
            local currentRoomNum = LocalPlayer:GetAttribute("CurrentRoom") or 0

            if rooms then
                for _, room in pairs(rooms:GetChildren()) do
                    local roomNum = tonumber(room.Name)
                    if roomNum and roomNum >= currentRoomNum then
                        for _, child in pairs(room:GetDescendants()) do
                            local n = child.Name
                            
                            if Options.DoorESP.Value and n == "Door" and child:IsA("Model") then
                                if roomNum == currentRoomNum or roomNum == currentRoomNum + 1 then
                                    local isLocked = child:FindFirstChild("Lock") ~= nil
                                    local isRealDoor = child:FindFirstChild("Sign") or child:FindFirstChild("Hidden") or isLocked
                                    if isRealDoor then
                                        local prefix = (roomNum == currentRoomNum) and " Cửa Tiếp Theo" or " Cửa +1"
                                        if isLocked then prefix = " [Khóa] " .. prefix end
                                        CreateESP(child, prefix .. " [" .. (roomNum + 1) .. "]", "Door", roomNum)
                                    end
                                end
                            elseif Options.ObjESP.Value and (n:find("Chest") or table.find(ObjList, n)) then
                                local d = (n == "KeyObtain" and "Key") or (n == "LeverForGate" and "Lever") or (n:find("Locked") and "Locked Chest") or (n:find("Chest") and "Chest") or n
                                CreateESP(child, d, "Objective", roomNum)
                            elseif Options.GoldPileESP.Value and n == "GoldPile" then
                                CreateESP(child, "Gold", "Gold", roomNum)
                            elseif Options.ItemESP.Value and (table.find(ItemList, n) or child:IsA("Tool")) then
                                CreateESP(child, n, "Item", roomNum)
                            elseif Options.HidingESP.Value and table.find(HSList, n) then
                                CreateESP(child, n, "Hiding", roomNum)
                            end 

                            if Options.AnchorESP and Options.AnchorESP.Value and (n:find("Terminal") or n:find("Anchor")) then
                                CreateESP(child, "📡 " .. n, "Objective", roomNum)
                            elseif Options.BatteryFinder and Options.BatteryFinder.Value and n:find("Battery") then
                                CreateESP(child, "Battery", "Item", roomNum)
                            elseif Options.OxygenKeeper and Options.OxygenKeeper.Value and n == "AirPocket" then
                                CreateESP(child, "🫧 Air Pocket", "Objective", roomNum)
                            end
                        end
                    end
                end
            end
            
            for _, ent in pairs(workspace:GetChildren()) do
                local entName = IsEntity(ent.Name)
                if entName then 
                    CreateESP(ent, entName:gsub("Moving", ""):gsub("Rig", ""):gsub("TheKiller", ""), "Entity", -1) 
                end
            end
        end)
    end
end)

--------------------------------------------------------------------------------
-- GLOBAL RENDER LOOP
--------------------------------------------------------------------------------
table.insert(ScriptConnections, RunService.RenderStepped:Connect(function()
    pcall(function()
        if not Options.DoorESP then return end -- Check Initialization

        local currentRoomNum = LocalPlayer:GetAttribute("CurrentRoom") or 0
        local char = LocalPlayer.Character
        local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Collision"))
        if not root then return end

        if tpWalkOn and char then
            local hum = char:FindFirstChild("Humanoid")
            if hum and hum.MoveDirection.Magnitude > 0 then
                root.CFrame = root.CFrame + (hum.MoveDirection * tpWalkSpeed)
            end
        end

        if freecamOn then
            local look = Camera.CFrame.LookVector
            local right = Camera.CFrame.RightVector
            local vec = Vector3.new()
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then vec = vec + look end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then vec = vec - look end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then vec = vec - right end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then vec = vec + right end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vec = vec + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then vec = vec - Vector3.new(0, 1, 0) end
            camCFrame = camCFrame + (vec * freecamSpeed)
            Camera.CFrame = camCFrame
        end

        for obj, data in pairs(activeESPs) do
            local isEnabled = (data.Type == "Door" and Options.DoorESP.Value) or
                              (data.Type == "Objective" and Options.ObjESP.Value) or
                              (data.Type == "Entity" and Options.EntityESP.Value) or
                              (data.Type == "Gold" and Options.GoldPileESP.Value) or
                              (data.Type == "Item" and Options.ItemESP.Value) or
                              (data.Type == "Hiding" and Options.HidingESP.Value)

            if not obj or not obj.Parent or not isEnabled or (data.RoomNum ~= -1 and data.RoomNum < currentRoomNum) then 
                Cleanup(obj, data) 
                continue 
            end

            local targetPos = (data.Attach:IsA("Model") and data.Attach:GetPivot().Position) or (data.Attach:IsA("BasePart") and data.Attach.Position)
            if not targetPos then continue end
            
            local dist = (root.Position - targetPos).Magnitude
            if dist > Options.MaxDistance.Value then
                if data.Highlight then data.Highlight.Enabled = false end
                if data.Bill then data.Bill.Enabled = false end
                if data.Tracer and HasDrawing then data.Tracer.Visible = false end
                continue 
            end

            local screenPos, onScreen = Camera:WorldToViewportPoint(targetPos)
            
            local finalColor = Options.ObjColor.Value
            if Options.RainbowESP and Options.RainbowESP.Value then
                finalColor = rainbowColor
            else
                if data.Type == "Door" then finalColor = Options.FillColor.Value
                elseif data.Type == "Entity" then finalColor = Options.EntityColor.Value
                elseif data.Type == "Item" then finalColor = Options.ItemColor.Value
                elseif data.Type == "Gold" then finalColor = Options.GoldColor.Value
                elseif data.Type == "Hiding" then finalColor = Options.HideCol.Value end
            end

            if onScreen then
                if not data.Highlight then 
                    data.Highlight = Instance.new("Highlight", obj)
                    data.Highlight.FillTransparency = 0.5
                    data.Highlight.OutlineTransparency = 0
                end
                data.Highlight.Enabled = true
                data.Highlight.FillColor = finalColor
                data.Highlight.OutlineColor = finalColor

                if not data.Bill then
                    data.Bill = Instance.new("BillboardGui", obj)
                    data.Bill.AlwaysOnTop = true
                    data.Bill.Size = UDim2.new(0, 100, 0, 40)
                    local txt = Instance.new("TextLabel", data.Bill)
                    txt.BackgroundTransparency = 1
                    txt.Size = UDim2.new(1, 0, 1, 0)
                    txt.Font = Enum.Font.SourceSansBold
                    txt.TextStrokeTransparency = 0
                    txt.Name = "L"
                end
                data.Bill.Enabled = Options.EnableText.Value
                local lbl = data.Bill.L
                lbl.TextColor3 = finalColor
                lbl.TextSize = Options.TextSize.Value
                lbl.Text = data.Name .. "\n[" .. math.floor(dist) .. "m]"

                if HasDrawing and Options.ShowTracers and Options.ShowTracers.Value then
                    if not data.Tracer then
                        data.Tracer = Drawing.new("Line")
                        data.Tracer.Thickness = 1.5
                        data.Tracer.Transparency = 1
                    end
                    data.Tracer.Visible = true
                    data.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    data.Tracer.To = Vector2.new(screenPos.X, screenPos.Y)
                    data.Tracer.Color = finalColor
                else
                    if data.Tracer and HasDrawing then data.Tracer.Visible = false end
                end
            else
                if data.Highlight then data.Highlight.Enabled = false end
                if data.Bill then data.Bill.Enabled = false end
                if data.Tracer and HasDrawing then data.Tracer.Visible = false end
            end
        end
    end)
end))

--------------------------------------------------------------------------------
-- SUPPORT TAB
--------------------------------------------------------------------------------
local SupportSection = Tabs.Support:AddSection("Script Utilities")

SupportSection:AddButton({
    Title = "Infinite Yield", Description = "Chạy Admin Script",
    Callback = function() loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))() end
})

SupportSection:AddButton({
    Title = "Dark Dex", Description = "Trình thám hiểm Explorer",
    Callback = function() loadstring(game:HttpGet("https://obj.wearedevs.net/2/scripts/Dex%20Explorer.lua"))() end
})

--------------------------------------------------------------------------------
-- THE MINE TAB
--------------------------------------------------------------------------------
Tabs.TheMine:AddSection("Cửa 150 (Grumble & Anchor)")
Tabs.TheMine:AddToggle("AnchorESP", { Title = "Anchor/Terminal ESP", Default = false })
Tabs.TheMine:AddToggle("AutoMinigame", { Title = "Auto-solve Minigame", Default = false })
Tabs.TheMine:AddToggle("GrumbleTracker", { Title = "Grumble ESP & Tracer", Default = false })

Tabs.TheMine:AddSection("Thực Thể (Entities)")
Tabs.TheMine:AddToggle("AutoGiggleSnatch", { Title = "Auto-Remove Giggle", Default = false })
Tabs.TheMine:AddToggle("GloomBatAura", { Title = "Gloom Bat Aura", Default = false })

Tabs.TheMine:AddSection("Vật Phẩm")
Tabs.TheMine:AddToggle("BatteryFinder", { Title = "Battery Finder", Default = false })
Tabs.TheMine:AddToggle("OxygenKeeper", { Title = "Oxygen Keeper", Default = false })

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local char = LocalPlayer.Character
            if not char then return end
            if Options.AutoGiggleSnatch and Options.AutoGiggleSnatch.Value and char:FindFirstChild("Giggle") then
                Remotes.GiggleStruggle:FireServer()
            end
            if Options.AutoMinigame and Options.AutoMinigame.Value then
                Remotes.TerminalMinigame:FireServer(true)
            end
        end)
    end
end)

--------------------------------------------------------------------------------
-- SETTINGS TAB
--------------------------------------------------------------------------------
Tabs.Settings:AddSection("Keybinds")
Tabs.Settings:AddParagraph({ Title = "Toggle UI", Content = "Bấm phím Right Shift (Shift Phải) để ẩn/hiện UI." })

Tabs.Settings:AddSection("Themes")
Tabs.Settings:AddDropdown("ThemeDropdown", {
    Title = "Change Theme", Values = {"Dark", "Light", "Darker", "Aqua", "Amethyst", "Rose", "Liquid Glass"}, Default = "Dark",
    Callback = function(Value)
        pcall(function()
            if Value == "Liquid Glass" then
                Fluent:SetTheme("Dark") Window:ToggleAcrylic(true)
            else
                Fluent:SetTheme(Value) Window:ToggleAcrylic(false)
            end
        end)
    end
})

Tabs.Settings:AddSection("Options")
Tabs.Settings:AddButton({
    Title = "Unload Script (Tắt an toàn)",
    Callback = function()
        pcall(function()
            for _, conn in ipairs(ScriptConnections) do
                if conn then conn:Disconnect() end
            end
            
            freecamOn = false
            tpWalkOn = false
            
            if Options.InstaInteract then Options.InstaInteract:SetValue(false) end
            if Options.ThirdPerson then Options.ThirdPerson:SetValue(false) end
            
            LocalPlayer.CameraMode = Enum.CameraMode.Custom
            LocalPlayer.CameraMaxZoomDistance = 400
            LocalPlayer.CameraMinZoomDistance = 0.5
            
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then Camera.CameraSubject = char.Humanoid end
            if char and char:FindFirstChild("HumanoidRootPart") then char.HumanoidRootPart.Anchored = false end
            
            for obj, data in pairs(activeESPs) do Cleanup(obj, data) end
            Window:Destroy()
        end)
    end
})

Fluent:Notify({ Title = "LonelyX-Hub", Content = "Script Ultimate Edition Loaded! Have fun!", Duration = 5 })
