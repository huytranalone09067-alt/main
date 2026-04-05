local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Remotes = game:GetService("ReplicatedStorage"):FindFirstChild("RemotesFolder") or game:GetService("ReplicatedStorage")
local identifyexec = identifyexecutor and identifyexecutor() or "Unknown Client"

local Window = Fluent:CreateWindow({
    Title = "Door panel  [  LonelyX-Hub ]",
    SubTitle = "Open Source",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightShift
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    Player = Window:AddTab({ Title = "Player", Icon = "user" }),
    Visuals = Window:AddTab({ Title = "Visuals", Icon = "image" }),
    ESP = Window:AddTab({ Title = "ESP", Icon = "eye" }),
    Demo = Window:AddTab({ Title = "Demo", Icon = "box" }),
    Support = Window:AddTab({ Title = "Support", Icon = "help-circle" }),
    Settings = Window:AddTab({ Title = "UI Settings", Icon = "settings" })
}

local Options = Fluent.Options

--------------------------------------------------------------------------------
-- MAIN TAB
--------------------------------------------------------------------------------
Tabs.Main:AddSection("Information")

local InfoParagraph = Tabs.Main:AddParagraph({
    Title = "Thông tin Hub",
    Content = "Loading..."
})

task.spawn(function()
    while task.wait(1) do
        local timeStr = os.date("%H:%M:%S - %d/%m/%Y")
        local currentRoom = LocalPlayer:GetAttribute("CurrentRoom") or 0
        local nextRoom = currentRoom + 1
        InfoParagraph:SetDesc(string.format(
            "Phát triển bởi: LonelyX\nDựa trên: CDoors\nThời gian: %s\nClient đang sử dụng: %s\n\nCửa hiện tại: %04d | Cửa tiếp theo: %04d", 
            timeStr, 
            identifyexec,
            currentRoom,
            nextRoom
        ))
    end
end)

Tabs.Main:AddSection("Anti-Entities")

local function ToggleRemote(name, state)
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
        local char = workspace:FindFirstChild(LocalPlayer.Name)
        if char then char:SetAttribute("CanJump", Value) end
    end
})

Tabs.Player:AddToggle("ToggleSlide", {
    Title = "Toggle Slide",
    Default = false,
    Callback = function(Value)
        local char = workspace:FindFirstChild(LocalPlayer.Name)
        if char then char:SetAttribute("CanSlide", Value) end
    end
})

Tabs.Player:AddSection("TPWalk")

local tpWalkOn = false
local tpWalkSpeed = 0.5

Tabs.Player:AddToggle("TPWalk", {
    Title = "Enable TPWalk",
    Default = false,
    Callback = function(Value)
        tpWalkOn = Value
    end
})

Tabs.Player:AddSlider("TPWalkSpeed", {
    Title = "TPWalk Speed",
    Default = 0.5,
    Min = 0.1,
    Max = 5,
    Rounding = 1,
    Callback = function(Value)
        tpWalkSpeed = Value
    end
})

RunService.RenderStepped:Connect(function()
    if tpWalkOn and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hum and root and hum.MoveDirection.Magnitude > 0 then
            root.CFrame = root.CFrame + (hum.MoveDirection * tpWalkSpeed)
        end
    end
end)

Tabs.Player:AddSection("Freecam")

local freecamOn = false
local freecamSpeed = 1.5
local camCFrame = Camera.CFrame

local FreecamToggle = Tabs.Player:AddToggle("Freecam", {
    Title = "Enable Freecam",
    Default = false,
    Callback = function(Value)
        freecamOn = Value
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
    end
})

Tabs.Player:AddKeybind("FreecamBind", {
    Title = "Freecam Keybind",
    Mode = "Toggle",
    Default = "F",
    Callback = function()
        Options.Freecam:SetValue(not Options.Freecam.Value)
    end
})

Tabs.Player:AddSlider("FreecamSpeed", {
    Title = "Freecam Speed",
    Default = 1.5,
    Min = 0.1,
    Max = 5,
    Rounding = 1,
    Callback = function(Value)
        freecamSpeed = Value
    end
})

RunService.RenderStepped:Connect(function()
    if freecamOn then
        local look = Camera.CFrame.LookVector
        local right = Camera.CFrame.RightVector
        local up = Camera.CFrame.UpVector
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
end)

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
    if Options.InstaInteract and Options.InstaInteract.Value and desc:IsA("ProximityPrompt") then
        desc.HoldDuration = 0
    end
end)

Tabs.Player:AddSection("Economy")
Tabs.Player:AddSlider("GoldSlider", { Title = "Gold Amount", Default = 50, Min = 1, Max = 1000, Rounding = 0 })
Tabs.Player:AddButton({
    Title = "Add Gold (Visual)",
    Callback = function()
        local goldObj = LocalPlayer:FindFirstChild("Gold")
        if goldObj then goldObj.Value = goldObj.Value + Options.GoldSlider.Value end
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
        Lighting.Brightness = Value and Options.BrightnessSlider.Value or 1
    end
})

Tabs.Visuals:AddSlider("BrightnessSlider", {
    Title = "Fullbright Intensity",
    Default = 2, Min = 1, Max = 10, Rounding = 1,
    Callback = function(Value)
        if Options.Fullbright.Value then Lighting.Brightness = Value end
    end
})

Tabs.Visuals:AddSection("Camera Settings")
Tabs.Visuals:AddToggle("ThirdPerson", {
    Title = "Third Person View",
    Default = false,
    Callback = function(Value)
        if Value then
            LocalPlayer.CameraMode = Enum.CameraMode.Classic
            LocalPlayer.CameraMaxZoomDistance = 15
            LocalPlayer.CameraMinZoomDistance = 10
        else
            LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
            LocalPlayer.CameraMaxZoomDistance = 0.5
            LocalPlayer.CameraMinZoomDistance = 0.5
        end
    end
})

RunService.RenderStepped:Connect(function()
    if Options.ThirdPerson and Options.ThirdPerson.Value then
        LocalPlayer.CameraMode = Enum.CameraMode.Classic
        LocalPlayer.CameraMaxZoomDistance = 15
        LocalPlayer.CameraMinZoomDistance = 10
    end
end)

Tabs.Visuals:AddSection("Effects")
Tabs.Visuals:AddToggle("NoCameraShake", { 
    Title = "No Camera Shake", 
    Default = false, 
    Callback = function(v) 
        local list = {"CamShake", "CamShakeClient", "CamShakeRelative", "CamShakeRelativeClient"}
        for _, name in pairs(list) do ToggleRemote(name, v) end
    end 
})

--------------------------------------------------------------------------------
-- ESP TAB
--------------------------------------------------------------------------------
Tabs.ESP:AddSection("ESP Toggles")

Tabs.ESP:AddToggle("DoorESP", { Title = "Smart Door ESP (Chỉ cửa đúng)", Default = false })
Tabs.ESP:AddColorpicker("FillColor", { Title = "Door Color", Default = Color3.fromRGB(0, 255, 0) })

Tabs.ESP:AddToggle("EntityESP", { Title = "Entity Highlight", Default = false })
Tabs.ESP:AddColorpicker("EntityColor", { Title = "Entity Color", Default = Color3.fromRGB(255, 0, 0) })

Tabs.ESP:AddToggle("ObjESP", { Title = "Objective ESP", Default = false })
Tabs.ESP:AddColorpicker("ObjColor", { Title = "Objective Color", Default = Color3.fromRGB(0, 0, 255) })

Tabs.ESP:AddToggle("GoldPileESP", { Title = "Gold Highlight", Default = false })
Tabs.ESP:AddColorpicker("GoldColor", { Title = "Gold Color", Default = Color3.fromRGB(255, 225, 0) })

Tabs.ESP:AddToggle("ItemESP", { Title = "Item Highlight", Default = false })
Tabs.ESP:AddColorpicker("ItemColor", { Title = "Item Color", Default = Color3.fromRGB(0, 255, 255) })

Tabs.ESP:AddToggle("HidingESP", { Title = "Hiding ESP", Default = false })
Tabs.ESP:AddColorpicker("HideCol", { Title = "Hiding Color", Default = Color3.fromRGB(100, 100, 100) })

Tabs.ESP:AddToggle("BookESP", { Title = "LiveHintBook ESP", Default = false })
Tabs.ESP:AddColorpicker("BookColor", { Title = "Book Color", Default = Color3.fromRGB(255, 0, 255) })

Tabs.ESP:AddSection("ESP Settings")
Tabs.ESP:AddToggle("NotifyEntity", { Title = "Notify Entity", Default = false })
Tabs.ESP:AddToggle("ShowTracers", { Title = "Enable Tracers", Default = false })
Tabs.ESP:AddToggle("RainbowESP", { Title = "Rainbow ESP", Default = false })
Tabs.ESP:AddToggle("EnableText", { Title = "Enable Text", Default = false })
Tabs.ESP:AddSlider("TextSize", { Title = "Text Size", Default = 20, Min = 10, Max = 40, Rounding = 0 })
Tabs.ESP:AddSlider("MaxDistance", { Title = "Max ESP Distance", Default = 1500, Min = 50, Max = 5000, Rounding = 0 })

--------------------------------------------------------------------------------
-- DEMO TAB
--------------------------------------------------------------------------------
Tabs.Demo:AddSection("Auto Collect")
Tabs.Demo:AddToggle("CollectAura", { Title = "Collect Aura (Auto E)", Default = false })
Tabs.Demo:AddDropdown("AuraItems", {
    Title = "Select Items to Auto-Collect",
    Description = "Chọn vật phẩm bạn muốn tự động nhặt",
    Values = {"GoldPile", "KeyObtain", "LiveHintBook", "Lighter", "Lockpick", "Vitamins", "Flashlight", "Battery"},
    Multi = true,
    Default = {"GoldPile"}
})

task.spawn(function()
    while task.wait(0.1) do
        if Options.CollectAura and Options.CollectAura.Value then
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                for _, prompt in pairs(workspace:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") and prompt.Enabled then
                        local parent = prompt.Parent
                        if parent then
                            local itemName = parent.Name
                            local selectedItems = Options.AuraItems.Value
                            
                            local shouldLoot = false
                            if type(selectedItems) == "table" then
                                for k, v in pairs(selectedItems) do
                                    if v and (itemName:find(k) or (parent.Parent and parent.Parent.Name:find(k))) then
                                        shouldLoot = true
                                        break
                                    end
                                end
                            end
                            
                            if shouldLoot then
                                local dist = (root.Position - parent.Position).Magnitude
                                if dist <= prompt.MaxActivationDistance then
                                    local oldHoldDuration = prompt.HoldDuration
                                    prompt.HoldDuration = 0 
                                    fireproximityprompt(prompt)
                                    prompt.HoldDuration = oldHoldDuration
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)


-- Internal ESP Logic
local activeESPs = {}

local EntityNames = {"Rush", "Ambush", "Seek", "Eyes", "Screech", "Halt", "A-60", "A-120", "GiggleCeiling", "MonumentEntity", "SallyMoving", "JeffTheKiller", "GloombatSwarm", "FigureRig"}
local ObjList = {"LibraryHintPaper", "KeyObtain", "LeverForGate", "LiveBreakerPolePickup", "ElectricalKeyObtain"}
local ItemList = {"AK-47","AlarmClock","Aloe","AN-94","Anchors","A-90sStopSign","BackdoorKey","BackdoorLock","Bandage","BandagePack","Battery","BatteryPack","BigBomb","BlueKeycard","BluePrince","Bomb","Bread","BreakerPole","Bulklight","Buddy","Cactus","Candle","CarmelApple","Cheese","ChocolateBar","Citamines","ColtAnaconda","Cookie","Crossbow","Crucifix","DBShotgun","DesertEagle","ElectricalKey","ElectricalRoomFuse","EnergyDrink","ExecutionRoomKey","Flashlight","FreezeGun","Flamethrower","G36C","Generator","GeneratorFuse","GiftLauncher","GlitchFragment","GweenSoda","GuidanceCandy","Headlamp","HealingPad","HolyHandGrenade","HasteLever","Hookshot","HotelKey","HotelLock","IceTripmine","InvincibilityStar","JackoBomb","Keycard","Knockbomb","Landmine","Lantern","LaserPointer","Level5Keycard","LibearyBook","LibearyLock","LibearyPaper","Light_Bulb","Lockpick","Lolipop","MG42","M14","M16A2","M1911","M249","M5K","M4A1","MoonlightCandle","MoonlightFloat","MoonlightSmoothie","Monkey","Nanner","NannerPeel","NestGenerator","NVCS-3000","OrangeKeycard","P90","Paintingoval","Paintingrectanglelyingshortsides","Paintingrectanglelyinglongsides","PaintingSquare","PlantofVirdis","Potion","R870","RedEnergyDrink","Rock","Roto_Door","RubberChicken","SacredHerb","SaltShaker","Shakelight","Shears","SkeletonKey","Smoothie","SmallShieldPotion","SpeedBoostPad","SprayPaint","StarlightBottle","StarlightJug","StarlightVial","Straplight","StrawberryCandy","StrongHerb","StrongerHerb","StrongestHerb","SuperHerb","SweetHerb","ThrowableHatStand","ThrowableNormalCardboardBox","ThrowableOfficeChair","ThrowablePottedPlant","ThrowableRegalChair","ThrowableRegalOttoman","ThrowableStool","ThrowableTrashCan","ThrowableWideCardboardBox","ThrowableWoodenChair","ThrowableWoodenCrate","TipJar","Vitamins"}
local HSList = {"Locker_Large", "Toolshed", "Wardrobe", "Bed", "Backdoor_Wardrobe", "Rooms_Locker", "CircularVent"}

local function Cleanup(obj, data)
    pcall(function()
        if data.Highlight then data.Highlight:Destroy() end
        if data.Box then data.Box:Destroy() end
        if data.Bill then data.Bill:Destroy() end
        if data.Tracer then data.Tracer:Remove() end
    end)
    activeESPs[obj] = nil
end

local function IsEntity(name)
    for _, ent in pairs(EntityNames) do
        if string.find(name, ent) then return ent end
    end
    return nil
end

local function CreateESP(obj, name, type)
    if activeESPs[obj] then return end
    
    local attachObj = obj
    if obj:IsA("Model") and obj.PrimaryPart then 
        attachObj = obj.PrimaryPart 
    end
    
    activeESPs[obj] = { Name = name, Type = type, Attach = attachObj }
end

workspace.ChildAdded:Connect(function(child)
    task.wait(0.1)
    local entName = IsEntity(child.Name)
    if entName then 
        local cleanName = entName:gsub("Moving", ""):gsub("Rig", ""):gsub("TheKiller", "")
        CreateESP(child, cleanName, "Entity") 
        
        if Options.NotifyEntity and Options.NotifyEntity.Value and not string.find(cleanName, "Figure") then
            Fluent:Notify({
                Title = "⚠️ Cảnh báo Entity",
                Content = cleanName .. " vừa xuất hiện!",
                Duration = 4
            })
        end
    end
end)

workspace.ChildRemoved:Connect(function(child)
    local entName = IsEntity(child.Name)
    if entName then
        local cleanName = entName:gsub("Moving", ""):gsub("Rig", ""):gsub("TheKiller", "")
        if Options.NotifyEntity and Options.NotifyEntity.Value and not string.find(cleanName, "Figure") then
            Fluent:Notify({
                Title = "✅ An toàn",
                Content = cleanName .. " đã đi qua/biến mất!",
                Duration = 4
            })
        end
    end
end)

task.spawn(function()
    while true do
        local rooms = workspace:FindFirstChild("CurrentRooms")
        local currentRoomNumber = LocalPlayer:GetAttribute("CurrentRoom") or 0

        if rooms then
            for _, room in pairs(rooms:GetChildren()) do
                local roomNum = tonumber(room.Name)
                
                for _, child in pairs(room:GetDescendants()) do
                    local n = child.Name
                    local entName = IsEntity(n)
                    
                    if Options.EntityESP.Value and entName then
                        CreateESP(child, entName:gsub("Moving", ""):gsub("Rig", ""):gsub("TheKiller", ""), "Entity")
                    elseif Options.ObjESP.Value and table.find(ObjList, n) then
                        local d = (n == "KeyObtain" and "Key") or (n == "LeverForGate" and "Lever") or n
                        CreateESP(child, d, "Objective")
                    elseif Options.BookESP.Value and n == "LiveHintBook" then
                        CreateESP(child, "Book", "BookESP")
                    elseif Options.DoorESP.Value and n == "Door" then
                        if roomNum == currentRoomNumber then
                            CreateESP(child, "Real Door [" .. (currentRoomNumber + 1) .. "]", "Door")
                        end
                    elseif Options.GoldPileESP.Value and n == "GoldPile" then
                        CreateESP(child, "Gold", "Gold")
                    elseif Options.ItemESP.Value and table.find(ItemList, n) then
                        CreateESP(child, n, "Item")
                    elseif Options.HidingESP.Value and table.find(HSList, n) then
                        CreateESP(child, n, "Hiding")
                    end
                end
            end
        end
        
        for _, ent in pairs(workspace:GetChildren()) do
            local entName = IsEntity(ent.Name)
            if entName then 
                CreateESP(ent, entName:gsub("Moving", ""):gsub("Rig", ""):gsub("TheKiller", ""), "Entity") 
            end
        end

        task.wait(1)
    end
end)

local function UpdateESP()
    local rainbow = Color3.fromHSV(tick() % 5 / 5, 1, 1)
    local char = LocalPlayer.Character
    local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Collision"))
    if not root then return end

    local currentRoomNumber = LocalPlayer:GetAttribute("CurrentRoom") or 0

    for obj, data in pairs(activeESPs) do
        if data.Type == "Door" then
            local parentRoom = obj.Parent
            if parentRoom and tonumber(parentRoom.Name) ~= currentRoomNumber then
                Cleanup(obj, data)
                continue
            end
        end

        local isEnabled = (data.Type == "Door" and Options.DoorESP.Value) or
                          (data.Type == "Objective" and Options.ObjESP.Value) or
                          (data.Type == "Entity" and Options.EntityESP.Value) or
                          (data.Type == "Gold" and Options.GoldPileESP.Value) or
                          (data.Type == "Item" and Options.ItemESP.Value) or
                          (data.Type == "Hiding" and Options.HidingESP.Value) or
                          (data.Type == "BookESP" and Options.BookESP.Value)

        if not obj or not obj.Parent or not isEnabled then 
            Cleanup(obj, data) 
            continue 
        end

        local attachObj = data.Attach or obj
        local targetPos = (attachObj:IsA("Model") and attachObj:GetPivot().Position) or (attachObj:IsA("BasePart") and attachObj.Position)
        if not targetPos then continue end
        
        local dist = (root.Position - targetPos).Magnitude
        if dist > Options.MaxDistance.Value then
            if data.Highlight then data.Highlight.Enabled = false end
            if data.Box then data.Box.Visible = false end
            if data.Bill then data.Bill.Enabled = false end
            if data.Tracer then data.Tracer.Visible = false end
            continue 
        end

        local screenPos, onScreen = Camera:WorldToViewportPoint(targetPos)
        if onScreen then
            local color = Options.FillColor.Value
            if data.Type == "Entity" then color = Options.EntityColor.Value 
            elseif data.Type == "Gold" then color = Options.GoldColor.Value
            elseif data.Type == "Item" then color = Options.ItemColor.Value
            elseif data.Type == "Objective" then color = Options.ObjColor.Value 
            elseif data.Type == "Hiding" then color = Options.HideCol.Value 
            elseif data.Type == "BookESP" then color = Options.BookColor.Value end
            
            if Options.RainbowESP.Value then color = rainbow end

            if data.Type == "Door" then
                if not data.Box then
                    data.Box = Instance.new("BoxHandleAdornment", obj); data.Box.AlwaysOnTop = true; data.Box.Adornee = obj; data.Box.ZIndex = 5
                end
                data.Box.Visible = true; 
                if obj:IsA("BasePart") then
                    data.Box.Size = obj.Size
                else
                    data.Box.Size = Vector3.new(4, 7, 1)
                end
                data.Box.Color3 = color; data.Box.Transparency = 0.7
            else
                if not data.Highlight then data.Highlight = Instance.new("Highlight", obj) end
                data.Highlight.Adornee = attachObj 
                data.Highlight.Enabled = true; data.Highlight.FillColor = color; data.Highlight.OutlineColor = color; data.Highlight.FillTransparency = 0.5
            end

            if not data.Bill then
                data.Bill = Instance.new("BillboardGui", obj); data.Bill.AlwaysOnTop = true; data.Bill.Size = UDim2.new(0, 150, 0, 40)
                local txt = Instance.new("TextLabel", data.Bill); txt.BackgroundTransparency = 1; txt.Size = UDim2.new(1, 0, 1, 0); txt.Font = "SourceSansBold"; txt.Name = "L"; txt.TextStrokeTransparency = 0
            end
            data.Bill.Enabled = Options.EnableText.Value
            data.Bill.Adornee = attachObj
            local lbl = data.Bill:FindFirstChild("L")
            if lbl then
                lbl.TextColor3 = color; lbl.TextSize = Options.TextSize.Value
                lbl.Text = data.Name .. "\n[" .. math.floor(dist) .. "]"
            end

            if Options.ShowTracers.Value then
                if not data.Tracer then
                    data.Tracer = Drawing.new("Line")
                    data.Tracer.Thickness = 1.5
                end
                data.Tracer.Visible = true
                data.Tracer.Color = color
                data.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                data.Tracer.To = Vector2.new(screenPos.X, screenPos.Y)
            else
                if data.Tracer then data.Tracer.Visible = false end
            end

        else
            if data.Highlight then data.Highlight.Enabled = false end
            if data.Box then data.Box.Visible = false end
            if data.Bill then data.Bill.Enabled = false end
            if data.Tracer then data.Tracer.Visible = false end
        end
    end
end

local connection = RunService.RenderStepped:Connect(UpdateESP)

--------------------------------------------------------------------------------
-- SUPPORT TAB
--------------------------------------------------------------------------------
local SupportSection = Tabs.Support:AddSection("Script Utilities")

SupportSection:AddButton({
    Title = "Infinite Yield",
    Description = "Chạy Admin Script (Yeld infinity)",
    Callback = function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
    end
})

SupportSection:AddButton({
    Title = "Dark Dex",
    Description = "Trình thám hiểm Explorer chuyên sâu",
    Callback = function()
        loadstring(game:HttpGet("https://obj.wearedevs.net/2/scripts/Dex%20Explorer.lua"))()
    end
})

--------------------------------------------------------------------------------
-- SETTINGS TAB
--------------------------------------------------------------------------------
Tabs.Settings:AddSection("Keybinds")
Tabs.Settings:AddParagraph({
    Title = "Toggle UI",
    Content = "Bấm phím Right Shift (Shift Phải) để ẩn/hiện UI."
})

Tabs.Settings:AddSection("Themes")
Tabs.Settings:AddDropdown("ThemeDropdown", {
    Title = "Change Theme",
    Description = "Select UI Theme",
    Values = {"Dark", "Light", "Darker", "Aqua", "Amethyst", "Rose", "Liquid Glass"},
    Default = "Dark",
    Callback = function(Value)
        if Value == "Liquid Glass" then
            pcall(function()
                Fluent:SetTheme("Dark")
                Window:ToggleAcrylic(true)
            end)
        else
            pcall(function()
                Fluent:SetTheme(Value)
                Window:ToggleAcrylic(false)
            end)
        end
    end
})

Tabs.Settings:AddSection("Options")
Tabs.Settings:AddButton({
    Title = "Unload Script",
    Callback = function()
        connection:Disconnect()
        freecamOn = false
        tpWalkOn = false
        
        if Options.InstaInteract then Options.InstaInteract:SetValue(false) end
        if Options.ThirdPerson then Options.ThirdPerson:SetValue(false) end
        
        LocalPlayer.CameraMode = Enum.CameraMode.Custom
        LocalPlayer.CameraMaxZoomDistance = 400
        LocalPlayer.CameraMinZoomDistance = 0.5
        
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            Camera.CameraSubject = char.Humanoid
        end
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.Anchored = false
        end
        for obj, data in pairs(activeESPs) do Cleanup(obj, data) end
        Window:Destroy()
    end
})