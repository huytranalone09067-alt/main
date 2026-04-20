local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteEvent = ReplicatedStorage.Events.Remote.ShotTarget
local SoundService = game:GetService("SoundService")

local targetTeamName = "Red"  -- Initial target team
local cooldown = 0  -- Cooldown in seconds between shots
local bulletSpeed = 49.5  -- Speed of the bullet in studs/second
local minPredictionDistance = 0  -- Minimum distance for prediction in studs
local maxPredictionDistance = 10  -- Maximum distance for prediction in studs
local lastShotTime = 0  -- Variable to track the last time a shot was fired

-- Function to animate notification
local function animateNotification(notification)
    local endPos = UDim2.new(0.5, -100, 0.4, -50) -- Adjusted position
    
    local tweenInfo = TweenInfo.new(
        1, -- Duration
        Enum.EasingStyle.Elastic, -- Easing style
        Enum.EasingDirection.Out, -- Easing direction
        0, -- Repeat count (0 means play once)
        false, -- Reverses after finishing
        0 -- Delay
    )
    
    local tween = game:GetService("TweenService"):Create(notification, tweenInfo, {Position = endPos})
    
    tween:Play()
    
    wait(2) -- Adjust the duration the notification is displayed
    
    tween:Destroy()
end

-- Function to display a notification
local function displayNotification(message)
    local notification = Instance.new("ScreenGui")
    notification.Name = "Notification"

    local textLabel = Instance.new("TextLabel")
    textLabel.Parent = notification
    textLabel.Size = UDim2.new(0, 200, 0, 50)
    textLabel.Position = UDim2.new(0.5, -100, 0.55, -50) -- Adjusted position
    textLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.Text = message
    textLabel.TextSize = 20
    textLabel.Font = Enum.Font.SourceSans
    textLabel.TextColor3 = Color3.fromRGB(0, 0, 0)

    notification.Parent = game.Players.LocalPlayer.PlayerGui

    -- Animate notification
    animateNotification(textLabel)

    -- Fade out and destroy the notification after the animation finishes
    wait(2)
    for transparency = 0, 1, 0.1 do
        textLabel.BackgroundTransparency = transparency
        wait(0.1)
    end
    notification:Destroy()
end

-- Function to play a sound
local function playSound(soundId, delay)
    delay = delay or 0
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://" .. soundId
    sound.Parent = SoundService
    sound:Play()
    wait(delay)
    sound:Destroy()
end

-- Play sound with delay
spawn(function()
    playSound(2865227271, 0.5)
    wait(0.5)
    playSound(1676318332)
end)

local function findClosestPlayer()
    local players = game.Players:GetPlayers()
    local closestPlayer = nil
    local shortestDistance = math.huge
    
    -- Get the equipped tool
    local tool = player.Character:FindFirstChildOfClass("Tool")
    
    if tool then
        local toolHandle = tool:FindFirstChild("Handle")
        if toolHandle then
            -- Use the position of the tool handle as the shooter's position
            local shooterPosition = toolHandle.Position
            
            for _, plyr in ipairs(players) do
                if plyr ~= player and plyr.Team and plyr.Team.Name == targetTeamName and plyr.Character and plyr.Character:FindFirstChild("Humanoid") and plyr.Character.Humanoid.Health > 0 then
                    local targetPosition = plyr.Character.HumanoidRootPart.Position
                    
                    -- Calculate horizontal distance
                    local horizontalDistance = (targetPosition - shooterPosition).magnitude
                    
                    -- Calculate vertical distance
                    local heightDifference = math.abs(targetPosition.Y - shooterPosition.Y)
                    
                    -- Calculate total distance considering both horizontal and vertical distances
                    local totalDistance = (horizontalDistance^1 + heightDifference^2)^0.5
                    
                    if totalDistance < shortestDistance then
                        closestPlayer = plyr
                        shortestDistance = totalDistance
                    end
                end
            end
        else
            print("Tool does not have a handle.")
        end
    else
        print("No tool equipped.")
    end
    
    return closestPlayer, shortestDistance
end

local function predictPosition(targetPosition, targetVelocity)
    local shooterPosition = player.Character.HumanoidRootPart.Position
    local distanceToTarget = (targetPosition - shooterPosition).magnitude
    
    -- Adjust prediction based on distance
    local predictionDistance = math.clamp(distanceToTarget, minPredictionDistance, maxPredictionDistance)
    local timeToImpact = predictionDistance / bulletSpeed
    
    -- Predict the future position of the target based on their current position and velocity
    return targetPosition + targetVelocity * timeToImpact
end

local function fireRemoteEvent(targetPlayer)
    if targetPlayer then
        local currentTime = os.time()
        if currentTime - lastShotTime >= cooldown then
            local targetPosition = targetPlayer.Character.HumanoidRootPart.Position
            local targetVelocity = targetPlayer.Character.HumanoidRootPart.Velocity
            
            local predictedPosition = predictPosition(targetPosition, targetVelocity)
            
            local args = {
                [1] = predictedPosition,
                [2] = "Sniper"
            }
            RemoteEvent:FireServer(unpack(args))
            
            -- Activate the equipped tool
            local tool = player.Character:FindFirstChildOfClass("Tool")
            if tool then
                tool:Activate()
            end
            
            lastShotTime = currentTime
        end
    else
        print("No valid players found on the specified team nearby.")
    end
end

local function toggleTargetTeam()
    if targetTeamName == "Red" then
        targetTeamName = "Blue"
    else
        targetTeamName = "Red"
    end
    displayNotification("Now targeting " .. targetTeamName .. " team.")
end

-- Create a ScreenGui to hold the buttons
local gui = Instance.new("ScreenGui")
gui.Parent = game:GetService("CoreGui")

-- Create a TextButton for toggling between red and blue teams
local teamToggleButton = Instance.new("TextButton")
teamToggleButton.Parent = gui
teamToggleButton.Position = UDim2.new(0.7, 0, 0.1, 0)
teamToggleButton.Size = UDim2.new(0, 200, 0, 50)
teamToggleButton.Text = "Toggle Target Team"
teamToggleButton.MouseButton1Click:Connect(toggleTargetTeam)

-- Create a TextButton to target the closest player
local targetButton = Instance.new("TextButton")
targetButton.Parent = gui
targetButton.Position = UDim2.new(0.7, 0, 0.25, 0)
targetButton.Size = UDim2.new(0, 200, 0, 50)
targetButton.Text = "Target Closest Player"
targetButton.MouseButton1Click:Connect(function()
    fireRemoteEvent(findClosestPlayer())
end)
