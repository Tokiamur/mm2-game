-- TESTING
        local player = game.Players.LocalPlayer
        local TweenService = game:GetService("TweenService")
        local UserInputService = game:GetService("UserInputService")
        local RunService = game:GetService("RunService")

        shared.MM2LocalTradeState = shared.MM2LocalTradeState or {
            Weapons = {},
            Pets = {},
            Misc = {},
        }
        shared.MM2LocalTradeOwned = shared.MM2LocalTradeState
        shared.MM2LocalTradeSlots = shared.MM2LocalTradeSlots or {}
        shared.MM2LocalTradeTheirState = shared.MM2LocalTradeTheirState or {
            Weapons = {},
            Pets = {},
            Misc = {},
        }
        shared.MM2LocalTradeTheirSlots = shared.MM2LocalTradeTheirSlots or {}

        local previewFrame
        local previewList
        local previewCountLabel
        local previewEmptyLabel
        local localTradeSlotConnections = {}
        local localTradeInventoryConnections = {}
        local localRequestButtonConnections = {}
        local settingsKeybindCapture = nil
        local selectedItem
        local getOwnedCount
        local setMainTab
        local acceptLocalTradeRequest

        local function refreshLocalTradePreview()
            if shared.MM2RefreshTradeInventory then
                pcall(shared.MM2RefreshTradeInventory)
            end
        end

        -- Shared state and helpers


        local COLORS = {
            BG          = Color3.fromRGB(8, 8, 8),
            Panel       = Color3.fromRGB(14, 14, 14),
            Card        = Color3.fromRGB(22, 22, 22),
            CardHover   = Color3.fromRGB(38, 38, 38),
            CardSel     = Color3.fromRGB(32, 32, 32),
            Neon        = Color3.fromRGB(230, 230, 230),
            NeonBright  = Color3.fromRGB(255, 255, 255),
            NeonDark    = Color3.fromRGB(140, 140, 140),
            NeonGlow    = Color3.fromRGB(255, 255, 255),
            NeonCyan    = Color3.fromRGB(180, 180, 180),
            Success     = Color3.fromRGB(200, 200, 200),
            Error       = Color3.fromRGB(255, 80, 80),
            Text        = Color3.fromRGB(245, 245, 245),
            TextSub     = Color3.fromRGB(160, 160, 160),
            TextDim     = Color3.fromRGB(90, 90, 90),
            Border      = Color3.fromRGB(55, 55, 55),
        }

        -- UI helpers


        local function tween(obj, t, props, style, dir)
            style = style or Enum.EasingStyle.Quart
            dir   = dir   or Enum.EasingDirection.Out
            return TweenService:Create(obj, TweenInfo.new(t, style, dir), props)
        end

        local outerGlow

        local function makeDraggable(handle, frame)
            local dragging, dragStart, startPos = false, nil, nil
            handle.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                    dragging = true; dragStart = inp.Position; startPos = frame.Position
                    inp.Changed:Connect(function()
                        if inp.UserInputState == Enum.UserInputState.End then dragging = false end
                    end)
                end
            end)
            UserInputService.InputChanged:Connect(function(inp)
                if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
                    local d = inp.Position - dragStart
                    local newX = startPos.X.Offset + d.X
                    local newY = startPos.Y.Offset + d.Y
                    frame.Position = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
                    if outerGlow then
                        outerGlow.Position = UDim2.new(startPos.X.Scale, newX - 22, startPos.Y.Scale, newY - 22)
                    end
                end
            end)
        end

        local function addRipple(button)
            button.MouseButton1Click:Connect(function()
                local ripple = Instance.new("Frame")
                ripple.Size = UDim2.new(0, 0, 0, 0)
                ripple.Position = UDim2.new(0.5, 0, 0.5, 0)
                ripple.AnchorPoint = Vector2.new(0.5, 0.5)
                ripple.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                ripple.BackgroundTransparency = 0.7
                ripple.ZIndex = button.ZIndex + 1
                ripple.Parent = button
                Instance.new("UICorner", ripple).CornerRadius = UDim.new(1, 0)
                tween(ripple, 0.55, {Size = UDim2.new(2.2, 0, 2.2, 0), BackgroundTransparency = 1}, Enum.EasingStyle.Quad):Play()
                game:GetService("Debris"):AddItem(ripple, 0.6)
            end)
        end

        -- Loader GUI


        local loaderGui = Instance.new("ScreenGui")
        loaderGui.Name = "MM2Loader"
        loaderGui.ResetOnSpawn = false
        loaderGui.IgnoreGuiInset = true
        loaderGui.DisplayOrder = 9999
        loaderGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        loaderGui.Parent = player:WaitForChild("PlayerGui")

        local loaderFrame = Instance.new("Frame")
        loaderFrame.Size = UDim2.new(1, 0, 1, 0)
        loaderFrame.Position = UDim2.new(0, 0, 0, 0)
        loaderFrame.BackgroundColor3 = Color3.fromRGB(4, 4, 4)
        loaderFrame.BorderSizePixel = 0
        loaderFrame.ZIndex = 1
        loaderFrame.Parent = loaderGui

        local gridLines = Instance.new("Frame")
        gridLines.Size = UDim2.new(1, 0, 1, 0)
        gridLines.BackgroundTransparency = 1
        gridLines.ZIndex = 2
        gridLines.Parent = loaderFrame

        for col = 0, 14 do
            local line = Instance.new("Frame")
            line.Size = UDim2.new(0, 1, 1, 0)
            line.Position = UDim2.new(col / 14, 0, 0, 0)
            line.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
            line.BackgroundTransparency = 0.85
            line.BorderSizePixel = 0
            line.ZIndex = 2
            line.Parent = gridLines
        end
        for row = 0, 10 do
            local line = Instance.new("Frame")
            line.Size = UDim2.new(1, 0, 0, 1)
            line.Position = UDim2.new(0, 0, row / 10, 0)
            line.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
            line.BackgroundTransparency = 0.85
            line.BorderSizePixel = 0
            line.ZIndex = 2
            line.Parent = gridLines
        end

        local bgGlow = Instance.new("Frame")
        bgGlow.Size = UDim2.new(0, 500, 0, 500)
        bgGlow.Position = UDim2.new(0.5, -250, 0.5, -250)
        bgGlow.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
        bgGlow.BackgroundTransparency = 0.96
        bgGlow.BorderSizePixel = 0
        bgGlow.ZIndex = 2
        bgGlow.Parent = loaderFrame
        Instance.new("UICorner", bgGlow).CornerRadius = UDim.new(1, 0)

        local loaderCenter = Instance.new("Frame")
        loaderCenter.Size = UDim2.new(0, 320, 0, 250)
        loaderCenter.Position = UDim2.new(0.5, -160, 0.5, -125)
        loaderCenter.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
        loaderCenter.BorderSizePixel = 0
        loaderCenter.ZIndex = 3
        loaderCenter.Parent = loaderFrame
        Instance.new("UICorner", loaderCenter).CornerRadius = UDim.new(0, 20)
        local loaderStroke = Instance.new("UIStroke", loaderCenter)
        loaderStroke.Color = Color3.fromRGB(180, 180, 180)
        loaderStroke.Thickness = 1.5
        loaderStroke.Transparency = 0.3

        local cardGlow = Instance.new("Frame")
        cardGlow.Size = UDim2.new(0, 360, 0, 290)
        cardGlow.Position = UDim2.new(0.5, -180, 0.5, -145)
        cardGlow.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
        cardGlow.BackgroundTransparency = 0.92
        cardGlow.BorderSizePixel = 0
        cardGlow.ZIndex = 2
        cardGlow.Parent = loaderFrame
        Instance.new("UICorner", cardGlow).CornerRadius = UDim.new(0, 28)

        local loaderIconBG = Instance.new("Frame")
        loaderIconBG.Size = UDim2.new(0, 76, 0, 76)
        loaderIconBG.Position = UDim2.new(0.5, -38, 0, 24)
        loaderIconBG.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
        loaderIconBG.BackgroundTransparency = 0.1
        loaderIconBG.BorderSizePixel = 0
        loaderIconBG.ZIndex = 4
        loaderIconBG.Parent = loaderCenter
        Instance.new("UICorner", loaderIconBG).CornerRadius = UDim.new(0, 18)
        local loaderIconStroke = Instance.new("UIStroke", loaderIconBG)
        loaderIconStroke.Color = Color3.fromRGB(255, 255, 255)
        loaderIconStroke.Thickness = 2
        local iconGrad = Instance.new("UIGradient", loaderIconBG)
        iconGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 80, 80)),
        })
        iconGrad.Rotation = 135

        local loaderIconLabel = Instance.new("TextLabel")
        loaderIconLabel.Size = UDim2.new(1, 0, 1, 0)
        loaderIconLabel.BackgroundTransparency = 1
        loaderIconLabel.Text = "MM2"
        loaderIconLabel.TextColor3 = Color3.fromRGB(10, 10, 10)
        loaderIconLabel.Font = Enum.Font.GothamBold
        loaderIconLabel.TextSize = 22
        loaderIconLabel.ZIndex = 5
        loaderIconLabel.Parent = loaderIconBG

        local loaderTitle = Instance.new("TextLabel")
        loaderTitle.Size = UDim2.new(1, -20, 0, 28)
        loaderTitle.Position = UDim2.new(0, 10, 0, 114)
        loaderTitle.BackgroundTransparency = 1
        loaderTitle.Text = "ITEM SPAWNER"
        loaderTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
        loaderTitle.Font = Enum.Font.GothamBold
        loaderTitle.TextSize = 22
        loaderTitle.ZIndex = 4
        loaderTitle.Parent = loaderCenter

        local loaderSub = Instance.new("TextLabel")
        loaderSub.Size = UDim2.new(1, -20, 0, 18)
        loaderSub.Position = UDim2.new(0, 10, 0, 145)
        loaderSub.BackgroundTransparency = 1
        loaderSub.Text = "Murder Mystery 2"
        loaderSub.TextColor3 = COLORS.TextSub
        loaderSub.Font = Enum.Font.Gotham
        loaderSub.TextSize = 12
        loaderSub.ZIndex = 4
        loaderSub.Parent = loaderCenter

        local loaderTrackBG = Instance.new("Frame")
        loaderTrackBG.Size = UDim2.new(1, -40, 0, 7)
        loaderTrackBG.Position = UDim2.new(0, 20, 0, 182)
        loaderTrackBG.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        loaderTrackBG.BorderSizePixel = 0
        loaderTrackBG.ZIndex = 4
        loaderTrackBG.Parent = loaderCenter
        Instance.new("UICorner", loaderTrackBG).CornerRadius = UDim.new(1, 0)

        local loaderFill = Instance.new("Frame")
        loaderFill.Size = UDim2.new(0, 0, 1, 0)
        loaderFill.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
        loaderFill.BorderSizePixel = 0
        loaderFill.ZIndex = 5
        loaderFill.Parent = loaderTrackBG
        Instance.new("UICorner", loaderFill).CornerRadius = UDim.new(1, 0)
        local fillGrad = Instance.new("UIGradient", loaderFill)
        fillGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 160, 160)),
        })

        local glider = Instance.new("Frame")
        glider.Size = UDim2.new(0, 13, 0, 13)
        glider.AnchorPoint = Vector2.new(0.5, 0.5)
        glider.Position = UDim2.new(1, 0, 0.5, 0)
        glider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        glider.BorderSizePixel = 0
        glider.ZIndex = 6
        glider.Parent = loaderFill
        Instance.new("UICorner", glider).CornerRadius = UDim.new(1, 0)

        local loaderStatus = Instance.new("TextLabel")
        loaderStatus.Size = UDim2.new(1, -80, 0, 16)
        loaderStatus.Position = UDim2.new(0, 20, 0, 202)
        loaderStatus.BackgroundTransparency = 1
        loaderStatus.Text = "Initializing..."
        loaderStatus.TextColor3 = COLORS.TextDim
        loaderStatus.Font = Enum.Font.Gotham
        loaderStatus.TextSize = 11
        loaderStatus.TextXAlignment = Enum.TextXAlignment.Left
        loaderStatus.ZIndex = 4
        loaderStatus.Parent = loaderCenter

        local loaderPct = Instance.new("TextLabel")
        loaderPct.Size = UDim2.new(0, 55, 0, 16)
        loaderPct.Position = UDim2.new(1, -65, 0, 202)
        loaderPct.BackgroundTransparency = 1
        loaderPct.Text = "0%"
        loaderPct.TextColor3 = Color3.fromRGB(220, 220, 220)
        loaderPct.Font = Enum.Font.GothamBold
        loaderPct.TextSize = 11
        loaderPct.TextXAlignment = Enum.TextXAlignment.Right
        loaderPct.ZIndex = 4
        loaderPct.Parent = loaderCenter

        task.spawn(function()
            while loaderGui.Parent and loaderFrame.Visible do
                tween(loaderIconBG, 0.9, {BackgroundTransparency = 0}, Enum.EasingStyle.Sine):Play()
                task.wait(0.9)
                tween(loaderIconBG, 0.9, {BackgroundTransparency = 0.25}, Enum.EasingStyle.Sine):Play()
                task.wait(0.9)
            end
        end)
        task.spawn(function()
            while loaderGui.Parent and loaderFrame.Visible do
                iconGrad.Rotation = (iconGrad.Rotation + 1.5) % 360
                task.wait(0.03)
            end
        end)
        task.spawn(function()
            local t = 0
            while loaderGui.Parent and loaderFrame.Visible do
                t += 0.04
                bgGlow.BackgroundTransparency = 0.96 + math.sin(t) * 0.02
                cardGlow.BackgroundTransparency = 0.92 + math.sin(t * 1.3) * 0.03
                task.wait(0.05)
            end
        end)

        -- Main GUI


        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "MM2Spawner"
        screenGui.ResetOnSpawn = false
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        screenGui.DisplayOrder = 100
        screenGui.Parent = player:WaitForChild("PlayerGui")

        outerGlow = Instance.new("Frame")
        outerGlow.Size = UDim2.new(0, 404, 0, 534)
        outerGlow.Position = UDim2.new(0.5, -202, 0.5, -267)
        outerGlow.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
        outerGlow.BackgroundTransparency = 0.92
        outerGlow.BorderSizePixel = 0
        outerGlow.ZIndex = 1
        outerGlow.Visible = false
        outerGlow.Parent = screenGui
        Instance.new("UICorner", outerGlow).CornerRadius = UDim.new(0, 28)

        local mainFrame = Instance.new("Frame")
        mainFrame.Size = UDim2.new(0, 360, 0, 490)
        mainFrame.Position = UDim2.new(0.5, -180, 0.5, -245)
        mainFrame.BackgroundColor3 = COLORS.BG
        mainFrame.BorderSizePixel = 0
        mainFrame.ClipsDescendants = true
        mainFrame.Visible = false
        mainFrame.ZIndex = 2
        mainFrame.Parent = screenGui
        Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 18)

        local mainBorder = Instance.new("UIStroke", mainFrame)
        mainBorder.Color = Color3.fromRGB(180, 180, 180)
        mainBorder.Thickness = 1.5
        mainBorder.Transparency = 0.3

        local baseMainSize = Vector2.new(360, 490)
        local baseGlowSize = Vector2.new(404, 534)
        local guiScale = math.clamp(tonumber(shared.MM2GuiScale) or 1, 1, 1.35)

        local function getScaledGuiMetrics(scale)
            scale = math.clamp(tonumber(scale) or 1, 1, 1.35)
            local mainW = math.floor(baseMainSize.X * scale + 0.5)
            local mainH = math.floor(baseMainSize.Y * scale + 0.5)
            local glowW = math.floor(baseGlowSize.X * scale + 0.5)
            local glowH = math.floor(baseGlowSize.Y * scale + 0.5)
            return mainW, mainH, glowW, glowH
        end

        local function applyGuiScale(scale)
            guiScale = math.clamp(tonumber(scale) or guiScale or 1, 1, 1.35)
            shared.MM2GuiScale = guiScale

            local mainW, mainH, glowW, glowH = getScaledGuiMetrics(guiScale)
            mainFrame.Size = UDim2.new(0, mainW, 0, mainH)
            mainFrame.Position = UDim2.new(0.5, -math.floor(mainW / 2), 0.5, -math.floor(mainH / 2))
            outerGlow.Size = UDim2.new(0, glowW, 0, glowH)
            outerGlow.Position = UDim2.new(0.5, -math.floor(glowW / 2), 0.5, -math.floor(glowH / 2))
        end

        shared.MM2ApplyGuiScale = applyGuiScale
        applyGuiScale(guiScale)

        local function makeOrb(parent, x, y, size, color, transp)
            local orb = Instance.new("Frame")
            orb.Size = UDim2.new(0, size, 0, size)
            orb.Position = UDim2.new(0, x, 0, y)
            orb.BackgroundColor3 = color
            orb.BackgroundTransparency = transp
            orb.BorderSizePixel = 0
            orb.ZIndex = 2
            orb.Parent = parent
            Instance.new("UICorner", orb).CornerRadius = UDim.new(1, 0)
            return orb
        end
        local orb1 = makeOrb(mainFrame, -70, -70, 200, Color3.fromRGB(180, 180, 180), 0.94)
        local orb2 = makeOrb(mainFrame, 210, 310, 150, Color3.fromRGB(140, 140, 140), 0.95)
        local orb3 = makeOrb(mainFrame, 290, -50, 110, Color3.fromRGB(220, 220, 220), 0.96)

        -- Header and title bar
        local header = Instance.new("Frame")
        header.Size = UDim2.new(1, 0, 0, 70)
        header.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
        header.BorderSizePixel = 0
        header.ZIndex = 5
        header.Parent = mainFrame
        Instance.new("UICorner", header).CornerRadius = UDim.new(0, 18)
        Instance.new("UIGradient", header).Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(24, 24, 24)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 10)),
        })

        local headerFix = Instance.new("Frame")
        headerFix.Size = UDim2.new(1, 0, 0, 18)
        headerFix.Position = UDim2.new(0, 0, 1, -18)
        headerFix.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
        headerFix.BorderSizePixel = 0
        headerFix.ZIndex = 5
        headerFix.Parent = header

        local neonLine = Instance.new("Frame")
        neonLine.Size = UDim2.new(0, 50, 0, 2)
        neonLine.Position = UDim2.new(0, 18, 0, 0)
        neonLine.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
        neonLine.BorderSizePixel = 0
        neonLine.ZIndex = 6
        neonLine.Parent = header
        Instance.new("UICorner", neonLine).CornerRadius = UDim.new(0, 2)
        local neonLineGrad = Instance.new("UIGradient", neonLine)
        neonLineGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(140, 140, 140)),
        })

        local neonLine2 = Instance.new("Frame")
        neonLine2.Size = UDim2.new(0, 18, 0, 2)
        neonLine2.Position = UDim2.new(0, 76, 0, 0)
        neonLine2.BackgroundColor3 = Color3.fromRGB(160, 160, 160)
        neonLine2.BackgroundTransparency = 0.4
        neonLine2.BorderSizePixel = 0
        neonLine2.ZIndex = 6
        neonLine2.Parent = header
        Instance.new("UICorner", neonLine2).CornerRadius = UDim.new(0, 2)

        local iconBox = Instance.new("Frame")
        iconBox.Size = UDim2.new(0, 42, 0, 42)
        iconBox.Position = UDim2.new(0, 14, 0.5, -21)
        iconBox.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
        iconBox.BorderSizePixel = 0
        iconBox.ZIndex = 6
        iconBox.Parent = header
        Instance.new("UICorner", iconBox).CornerRadius = UDim.new(0, 10)
        local iconGradient = Instance.new("UIGradient", iconBox)
        iconGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 80, 80)),
        })
        iconGradient.Rotation = 135
        local iconStroke2 = Instance.new("UIStroke", iconBox)
        iconStroke2.Color = Color3.fromRGB(255, 255, 255)
        iconStroke2.Thickness = 1.5
        iconStroke2.Transparency = 0.4

        local iconLabel = Instance.new("TextLabel")
        iconLabel.Size = UDim2.new(1, 0, 1, 0)
        iconLabel.BackgroundTransparency = 1
        iconLabel.Text = "MM2"
        iconLabel.TextColor3 = Color3.fromRGB(10, 10, 10)
        iconLabel.Font = Enum.Font.GothamBold
        iconLabel.TextSize = 12
        iconLabel.ZIndex = 7
        iconLabel.Parent = iconBox

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(0, 220, 0, 24)
        title.Position = UDim2.new(0, 66, 0, 12)
        title.BackgroundTransparency = 1
        title.Text = "ITEM SPAWNER"
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.Font = Enum.Font.GothamBold
        title.TextSize = 17
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.ZIndex = 6
        title.Parent = header

        local subtitle = Instance.new("TextLabel")
        subtitle.Size = UDim2.new(0, 220, 0, 16)
        subtitle.Position = UDim2.new(0, 66, 0, 38)
        subtitle.BackgroundTransparency = 1
        subtitle.Text = "Murder Mystery 2"
        subtitle.TextColor3 = COLORS.TextSub
        subtitle.Font = Enum.Font.Gotham
        subtitle.TextSize = 11
        subtitle.TextXAlignment = Enum.TextXAlignment.Left
        subtitle.ZIndex = 6
        subtitle.Parent = header

        local closeBtn = Instance.new("TextButton")
        closeBtn.Size = UDim2.new(0, 30, 0, 30)
        closeBtn.Position = UDim2.new(1, -32, 0.5, -15)
        closeBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
        closeBtn.BackgroundTransparency = 0.2
        closeBtn.Text = "X"
        closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.TextSize = 13
        closeBtn.BorderSizePixel = 0
        closeBtn.AutoButtonColor = false
        closeBtn.ZIndex = 7
        closeBtn.Parent = header
        Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
        local closeBtnStroke = Instance.new("UIStroke", closeBtn)
        closeBtnStroke.Color = COLORS.Error
        closeBtnStroke.Thickness = 1
        closeBtnStroke.Transparency = 0.5

        closeBtn.MouseEnter:Connect(function()
            tween(closeBtn, 0.15, {BackgroundTransparency = 0, Size = UDim2.new(0, 32, 0, 32), Position = UDim2.new(1, -33, 0.5, -16)}):Play()
            tween(closeBtnStroke, 0.15, {Transparency = 0}):Play()
        end)
        closeBtn.MouseLeave:Connect(function()
            tween(closeBtn, 0.15, {BackgroundTransparency = 0.2, Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(1, -32, 0.5, -15)}):Play()
            tween(closeBtnStroke, 0.15, {Transparency = 0.5}):Play()
        end)
        addRipple(closeBtn)
        makeDraggable(header, mainFrame)

        -- Search bar
        local searchOuter = Instance.new("Frame")
        searchOuter.Size = UDim2.new(1, -28, 0, 42)
        searchOuter.Position = UDim2.new(0, 14, 0, 82)
        searchOuter.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
        searchOuter.BackgroundTransparency = 0.85
        searchOuter.BorderSizePixel = 0
        searchOuter.ZIndex = 4
        searchOuter.Parent = mainFrame
        Instance.new("UICorner", searchOuter).CornerRadius = UDim.new(0, 12)

        local searchInner = Instance.new("Frame")
        searchInner.Size = UDim2.new(1, -2, 1, -2)
        searchInner.Position = UDim2.new(0, 1, 0, 1)
        searchInner.BackgroundColor3 = COLORS.Card
        searchInner.BorderSizePixel = 0
        searchInner.ZIndex = 4
        searchInner.Parent = searchOuter
        Instance.new("UICorner", searchInner).CornerRadius = UDim.new(0, 11)

        local searchIconLbl = Instance.new("TextLabel")
        searchIconLbl.Size = UDim2.new(0, 32, 1, 0)
        searchIconLbl.Position = UDim2.new(0, 0, 0, 0)
        searchIconLbl.BackgroundTransparency = 1
        searchIconLbl.Text = "Q"
        searchIconLbl.TextColor3 = COLORS.TextDim
        searchIconLbl.Font = Enum.Font.GothamBold
        searchIconLbl.TextSize = 14
        searchIconLbl.ZIndex = 5
        searchIconLbl.Parent = searchInner

        local searchBox = Instance.new("TextBox")
        searchBox.Size = UDim2.new(1, -38, 1, 0)
        searchBox.Position = UDim2.new(0, 30, 0, 0)
        searchBox.BackgroundTransparency = 1
        searchBox.Text = ""
        searchBox.PlaceholderText = "Search weapons..."
        searchBox.PlaceholderColor3 = COLORS.TextDim
        searchBox.TextColor3 = COLORS.Text
        searchBox.Font = Enum.Font.Gotham
        searchBox.TextSize = 13
        searchBox.TextXAlignment = Enum.TextXAlignment.Left
        searchBox.ClearTextOnFocus = false
        searchBox.ZIndex = 5
        searchBox.Parent = searchInner

        searchBox.Focused:Connect(function()
            tween(searchOuter, 0.2, {BackgroundTransparency = 0.6}):Play()
            tween(searchIconLbl, 0.2, {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
        end)
        searchBox.FocusLost:Connect(function()
            tween(searchOuter, 0.2, {BackgroundTransparency = 0.85}):Play()
            tween(searchIconLbl, 0.2, {TextColor3 = COLORS.TextDim}):Play()
        end)

        -- Search and item list
        local countLabel = Instance.new("TextLabel")
        countLabel.Size = UDim2.new(1, -28, 0, 16)
        countLabel.Position = UDim2.new(0, 14, 0, 130)
        countLabel.BackgroundTransparency = 1
        countLabel.Text = "All items"
        countLabel.TextColor3 = COLORS.TextDim
        countLabel.Font = Enum.Font.Gotham
        countLabel.TextSize = 11
        countLabel.TextXAlignment = Enum.TextXAlignment.Left
        countLabel.ZIndex = 4
        countLabel.Parent = mainFrame

        -- Item list
        local scrollFrame = Instance.new("ScrollingFrame")
        scrollFrame.Size = UDim2.new(1, -28, 0, 248)
        scrollFrame.Position = UDim2.new(0, 14, 0, 150)
        scrollFrame.BackgroundColor3 = COLORS.Panel
        scrollFrame.BorderSizePixel = 0
        scrollFrame.ScrollBarThickness = 4
        scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(180, 180, 180)
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        scrollFrame.ClipsDescendants = true
        scrollFrame.ZIndex = 4
        scrollFrame.Parent = mainFrame
        Instance.new("UICorner", scrollFrame).CornerRadius = UDim.new(0, 12)
        local scrollStroke = Instance.new("UIStroke", scrollFrame)
        scrollStroke.Color = COLORS.Border
        scrollStroke.Thickness = 1
        scrollStroke.Transparency = 0.4

        local listLayout = Instance.new("UIListLayout", scrollFrame)
        listLayout.Padding = UDim.new(0, 4)
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder

        local listPad = Instance.new("UIPadding", scrollFrame)
        listPad.PaddingTop    = UDim.new(0, 6)
        listPad.PaddingBottom = UDim.new(0, 6)
        listPad.PaddingLeft   = UDim.new(0, 6)
        listPad.PaddingRight  = UDim.new(0, 10)

        -- Spawn action button
        local spawnBtn = Instance.new("TextButton")
        spawnBtn.Size = UDim2.new(1, -28, 0, 48)
        spawnBtn.Position = UDim2.new(0, 14, 0, 412)
        spawnBtn.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
        spawnBtn.Text = ""
        spawnBtn.AutoButtonColor = false
        spawnBtn.BorderSizePixel = 0
        spawnBtn.ClipsDescendants = true
        spawnBtn.ZIndex = 5
        spawnBtn.Parent = mainFrame
        Instance.new("UICorner", spawnBtn).CornerRadius = UDim.new(0, 13)
        local spawnGrad = Instance.new("UIGradient", spawnBtn)
        spawnGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(110, 110, 110)),
        })
        spawnGrad.Rotation = 135
        local spawnBtnStroke = Instance.new("UIStroke", spawnBtn)
        spawnBtnStroke.Color = Color3.fromRGB(255, 255, 255)
        spawnBtnStroke.Thickness = 1.5
        spawnBtnStroke.Transparency = 0.4

        local shimmer = Instance.new("Frame")
        shimmer.Size = UDim2.new(0.35, 0, 2, 0)
        shimmer.Position = UDim2.new(-0.5, 0, -0.5, 0)
        shimmer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        shimmer.BackgroundTransparency = 0.82
        shimmer.Rotation = 20
        shimmer.BorderSizePixel = 0
        shimmer.ZIndex = 6
        shimmer.Parent = spawnBtn

        local spawnIconLbl = Instance.new("TextLabel")
        spawnIconLbl.Size = UDim2.new(0, 26, 1, 0)
        spawnIconLbl.Position = UDim2.new(0.5, -65, 0, 0)
        spawnIconLbl.BackgroundTransparency = 1
        spawnIconLbl.Text = "+"
        spawnIconLbl.TextColor3 = Color3.fromRGB(10, 10, 10)
        spawnIconLbl.Font = Enum.Font.GothamBold
        spawnIconLbl.TextSize = 22
        spawnIconLbl.ZIndex = 7
        spawnIconLbl.Parent = spawnBtn

        local spawnTextLbl = Instance.new("TextLabel")
        spawnTextLbl.Size = UDim2.new(0, 120, 1, 0)
        spawnTextLbl.Position = UDim2.new(0.5, -30, 0, 0)
        spawnTextLbl.BackgroundTransparency = 1
        spawnTextLbl.Text = "SPAWN ITEM"
        spawnTextLbl.TextColor3 = Color3.fromRGB(10, 10, 10)
        spawnTextLbl.Font = Enum.Font.GothamBold
        spawnTextLbl.TextSize = 14
        spawnTextLbl.TextXAlignment = Enum.TextXAlignment.Left
        spawnTextLbl.ZIndex = 7
        spawnTextLbl.Parent = spawnBtn

        addRipple(spawnBtn)

        task.spawn(function()
            while screenGui.Parent do
                tween(shimmer, 0, {Position = UDim2.new(-0.5, 0, -0.5, 0)}):Play()
                task.wait(2.8)
                tween(shimmer, 0.6, {Position = UDim2.new(1.3, 0, -0.5, 0)}, Enum.EasingStyle.Quad):Play()
                task.wait(0.7)
            end
        end)

        spawnBtn.MouseEnter:Connect(function()
            tween(spawnBtn, 0.2, {Size = UDim2.new(1, -24, 0, 50), Position = UDim2.new(0, 12, 0, 411)}):Play()
            tween(spawnGrad, 0.2, {Rotation = 115}):Play()
            tween(spawnBtnStroke, 0.2, {Transparency = 0}):Play()
        end)
        spawnBtn.MouseLeave:Connect(function()
            tween(spawnBtn, 0.2, {Size = UDim2.new(1, -28, 0, 48), Position = UDim2.new(0, 14, 0, 412)}):Play()
            tween(spawnGrad, 0.2, {Rotation = 135}):Play()
            tween(spawnBtnStroke, 0.2, {Transparency = 0.4}):Play()
        end)

        -- Spawn action button
        local ownedAddBtn = Instance.new("TextButton")
        ownedAddBtn.Size = UDim2.new(0, 114, 0, 24)
        ownedAddBtn.Position = UDim2.new(1, -132, 0, 424)
        ownedAddBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
        ownedAddBtn.Text = "ADD OWNED"
        ownedAddBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        ownedAddBtn.Font = Enum.Font.GothamBold
        ownedAddBtn.TextSize = 10
        ownedAddBtn.BorderSizePixel = 0
        ownedAddBtn.AutoButtonColor = false
        ownedAddBtn.ZIndex = 6
        ownedAddBtn.Parent = mainFrame
        Instance.new("UICorner", ownedAddBtn).CornerRadius = UDim.new(0, 8)
        local ownedAddStroke = Instance.new("UIStroke", ownedAddBtn)
        ownedAddStroke.Color = Color3.fromRGB(200, 200, 200)
        ownedAddStroke.Thickness = 1
        ownedAddStroke.Transparency = 0.45

        ownedAddBtn.MouseEnter:Connect(function()
            tween(ownedAddBtn, 0.15, {BackgroundColor3 = Color3.fromRGB(36, 36, 36), Size = UDim2.new(0, 118, 0, 26), Position = UDim2.new(1, -134, 0, 423)}):Play()
            tween(ownedAddStroke, 0.15, {Transparency = 0.15}):Play()
        end)
        ownedAddBtn.MouseLeave:Connect(function()
            tween(ownedAddBtn, 0.15, {BackgroundColor3 = Color3.fromRGB(24, 24, 24), Size = UDim2.new(0, 114, 0, 24), Position = UDim2.new(1, -132, 0, 424)}):Play()
            tween(ownedAddStroke, 0.15, {Transparency = 0.45}):Play()
        end)
        ownedAddBtn.MouseButton1Click:Connect(function()
            if not selectedItem then
                showToast("Select an item first!", true)
                return
            end
            local itemName = selectedItem.custom
            local originalName = selectedItem.original
            if getOwnedCount(originalName) <= 0 then
                showToast("You do not own this item.", true)
                return
            end
            local ok = OfferOwnedItemLocal(itemName, "Weapons")
            if ok then
                showToast(itemName .. " offered locally!")
            else
                showToast("Local trade slots are full.", true)
            end
        end)
        local progressBG = Instance.new("Frame")
        progressBG.Size = UDim2.new(1, -28, 0, 48)
        progressBG.Position = UDim2.new(0, 14, 0, 412)
        progressBG.BackgroundColor3 = COLORS.Card
        progressBG.BorderSizePixel = 0
        progressBG.Visible = false
        progressBG.ZIndex = 5
        progressBG.Parent = mainFrame
        Instance.new("UICorner", progressBG).CornerRadius = UDim.new(0, 13)
        local progStroke = Instance.new("UIStroke", progressBG)
        progStroke.Color = COLORS.Border
        progStroke.Thickness = 1
        progStroke.Transparency = 0.3

        local progressLabel = Instance.new("TextLabel")
        progressLabel.Size = UDim2.new(1, -16, 0, 20)
        progressLabel.Position = UDim2.new(0, 10, 0, 5)
        progressLabel.BackgroundTransparency = 1
        progressLabel.Text = "Spawning..."
        progressLabel.TextColor3 = COLORS.Text
        progressLabel.Font = Enum.Font.Gotham
        progressLabel.TextSize = 12
        progressLabel.TextXAlignment = Enum.TextXAlignment.Left
        progressLabel.ZIndex = 6
        progressLabel.Parent = progressBG

        local progressTrack = Instance.new("Frame")
        progressTrack.Size = UDim2.new(1, -20, 0, 7)
        progressTrack.Position = UDim2.new(0, 10, 0, 30)
        progressTrack.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        progressTrack.BorderSizePixel = 0
        progressTrack.ZIndex = 6
        progressTrack.Parent = progressBG
        Instance.new("UICorner", progressTrack).CornerRadius = UDim.new(1, 0)

        local progressFill = Instance.new("Frame")
        progressFill.Size = UDim2.new(0, 0, 1, 0)
        progressFill.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
        progressFill.BorderSizePixel = 0
        progressFill.ZIndex = 7
        progressFill.Parent = progressTrack
        Instance.new("UICorner", progressFill).CornerRadius = UDim.new(1, 0)
        local progFillGrad = Instance.new("UIGradient", progressFill)
        progFillGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(140, 140, 140)),
        })

        -- Toast notification
        local toast = Instance.new("Frame")
        toast.Size = UDim2.new(0, 260, 0, 44)
        toast.Position = UDim2.new(0.5, -130, 1, 10)
        toast.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
        toast.BorderSizePixel = 0
        toast.ZIndex = 50
        toast.Parent = screenGui
        Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 12)
        local toastStroke = Instance.new("UIStroke", toast)
        toastStroke.Color = Color3.fromRGB(200, 200, 200)
        toastStroke.Thickness = 1.5
        toastStroke.Transparency = 0.2

        local toastDot = Instance.new("Frame")
        toastDot.Size = UDim2.new(0, 8, 0, 8)
        toastDot.Position = UDim2.new(0, 14, 0.5, -4)
        toastDot.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
        toastDot.BorderSizePixel = 0
        toastDot.ZIndex = 51
        toastDot.Parent = toast
        Instance.new("UICorner", toastDot).CornerRadius = UDim.new(1, 0)

        local toastText = Instance.new("TextLabel")
        toastText.Size = UDim2.new(1, -32, 1, 0)
        toastText.Position = UDim2.new(0, 30, 0, 0)
        toastText.BackgroundTransparency = 1
        toastText.Text = "Item added!"
        toastText.TextColor3 = COLORS.Text
        toastText.Font = Enum.Font.GothamBold
        toastText.TextSize = 13
        toastText.TextXAlignment = Enum.TextXAlignment.Left
        toastText.ZIndex = 51
        toastText.Parent = toast

        local function showToast(msg, isError)
            toastText.Text = msg
            local col = isError and COLORS.Error or Color3.fromRGB(200, 200, 200)
            toastStroke.Color = col
            toastDot.BackgroundColor3 = col
            tween(toast, 0.4, {Position = UDim2.new(0.5, -130, 1, -58)}, Enum.EasingStyle.Back):Play()
            task.delay(2.2, function()
                tween(toast, 0.3, {Position = UDim2.new(0.5, -130, 1, 10)}):Play()
            end)
        end

        -- Item catalog


        local items = {
            {original = "Harvester",           custom = "Harvester"},
            {original = "Gingerscope",         custom = "Gingerscope"},
            {original = "Snowcannon",          custom = "Snowcannon"},
            {original = "Bauble",              custom = "Bauble"},
            {original = "BaubleChroma",        custom = "BaubleChroma"},
            {original = "Icepiercer",          custom = "Icepiercer"},
            {original = "TreeGun2023",         custom = "Evergun"},
            {original = "TreeKnife2023",       custom = "Evergreen"},
            {original = "TreeGun2023Chroma",   custom = "Chroma Evergun"},
            {original = "TreeKnife2023Chroma", custom = "Chroma Evergreen"},
            {original = "Bloom",               custom = "Bloom"},
            {original = "Flora",               custom = "Flora"},
            {original = "TravelerAxe",         custom = "Traveler Axe"},
            {original = "TravelerGun",         custom = "Traveler Gun"},
            {original = "TravelerAxeChroma",   custom = "Chroma Traveler Axe"},
            {original = "TravelerGunChroma",   custom = "Chroma Traveler Gun"},
            {original = "Celestial",           custom = "Celestial"},
            {original = "Constellation",       custom = "Constellation"},
            {original = "ConstellationChroma", custom = "Chroma Constellation"},
            {original = "BaubleChroma",        custom = "Chroma Bauble"},
            {original = "Candy",               custom = "Candy"},
            {original = "Sugar",               custom = "Sugar"},
            {original = "Darksword",           custom = "Darksword"},
            {original = "Darkshot",            custom = "Darkshot"},
            {original = "VampireAxe",          custom = "Vampire Axe"},
            {original = "VampireGun",          custom = "Vampire Gun"},
            {original = "SwirlyAxe",           custom = "Swirly Axe"},
            {original = "SwirlyGun",           custom = "Swirly Gun"},
            {original = "Flowerwood",          custom = "Flowerwood"},
            {original = "FlowerwoodGun",       custom = "Flowerwood Gun"},
            {original = "VampireGunChroma",    custom = "Chroma Vampire Gun"},
            {original = "WatergunChroma",      custom = "Chroma Watergun"},
            {original = "Turkey2023",          custom = "Turkey"},
            {original = "Sakura_K",            custom = "Sakura"},
            {original = "Blossom_G",           custom = "Blossom"},
            {original = "Makeshift",           custom = "Makeshift"},
            {original = "Sorry",               custom = "Corrupt"},
            {original = "HeartWand",           custom = "HeartWand"},
        }

        shared.MM2ItemCatalog = items
        shared.MM2LocalTradeState = shared.MM2LocalTradeState or {
            Weapons = {},
            Pets = {},
            Misc = {},
        }

        local function getCatalogItem(name)
            local target = tostring(name or ""):lower()
            for _, item in ipairs(items) do
                if item.original:lower() == target or item.custom:lower() == target then
                    return item
                end
            end
        end

        local function getProfileDataTable()
            local ok, pd = pcall(function()
                return require(game:GetService("ReplicatedStorage").Modules.ProfileData)
            end)
            if ok and pd then
                return pd
            end
        end

        local function getOwnedFromTable(owned, key)
            if not owned then
                return 0
            end
            local value = owned[key]
            if type(value) == "number" then
                return value
            end
            if type(value) == "string" then
                return tonumber(value) or 0
            end
            return value ~= nil and 1 or 0
        end

        getOwnedCount = function(originalName)
            local pd = getProfileDataTable()
            if not pd or not pd.Weapons or not pd.Weapons.Owned then
                return 0
            end
            return getOwnedFromTable(pd.Weapons.Owned, originalName)
        end

        local function getTradeOwnedCount(category, itemName)
            local pd = getProfileDataTable()
            if not pd or not category then
                return 0
            end
            local bucket = pd[category]
            if not bucket or not bucket.Owned then
                return 0
            end
            return getOwnedFromTable(bucket.Owned, itemName)
        end

        local getItemTypeLabel

        local function getTradeBadgeInfo(category, displayName)
            if category == "Pets" then
                return "PET", Color3.fromRGB(255, 212, 140)
            elseif category == "Materials" then
                return "MAT", Color3.fromRGB(180, 220, 255)
            elseif category == "Emotes" then
                return "EMT", Color3.fromRGB(210, 170, 255)
            end
            return getItemTypeLabel(displayName)
        end

        local tradeRarities

        local function getTradeRarities()
            if tradeRarities then
                return tradeRarities
            end

            local syncObj = game:GetService("ReplicatedStorage"):WaitForChild("Database"):WaitForChild("Sync")
            local ok, sync = pcall(require, syncObj)
            tradeRarities = (sync and sync.Rarities) or {
                Common = {Sort = 1},
                Uncommon = {Sort = 2},
                Rare = {Sort = 3},
                Legendary = {Sort = 4},
                Godly = {Sort = 5},
                Ancient = {Sort = 6},
                Vintage = {Sort = 7},
                Unique = {Sort = 8},
            }
            return tradeRarities
        end

        local function getTradeRaritySort(itemData)
            local rarities = getTradeRarities()
            local rarityName = tostring(itemData and itemData.Rarity or "Common")
            local rarityInfo = rarities and rarities[rarityName]
            local sortValue = rarityInfo and rarityInfo.Sort
            if type(sortValue) == "number" then
                return sortValue
            end
            return 999
        end

        local function compareTradeInventoryEntries(a, b)
            local categoryOrder = {
                Weapons = 1,
                Pets = 2,
                Materials = 3,
                Emotes = 4,
                Misc = 5,
            }

            local aCategory = categoryOrder[a.Category] or 99
            local bCategory = categoryOrder[b.Category] or 99
            if aCategory ~= bCategory then
                return aCategory < bCategory
            end

            if a.Category == "Weapons" then
                if a.ItemId == "DefaultKnife" then
                    return true
                end
                if b.ItemId == "DefaultKnife" then
                    return false
                end
                if b.ItemId == "DefaultGun" then
                    return false
                end
                if a.ItemId == "DefaultGun" and b.ItemId ~= "DefaultKnife" then
                    return true
                end
            end

            local aRarity = getTradeRaritySort(a.Catalog)
            local bRarity = getTradeRaritySort(b.Catalog)
            if aRarity ~= bRarity then
                return aRarity < bRarity
            end

            local aGroup = a.Catalog and a.Catalog.SortGroup
            local bGroup = b.Catalog and b.Catalog.SortGroup
            if aGroup ~= nil or bGroup ~= nil then
                if aGroup ~= nil and bGroup == nil then
                    return true
                end
                if bGroup ~= nil and aGroup == nil then
                    return false
                end
                if aGroup ~= bGroup then
                    return aGroup < bGroup
                end

                local aWithin = a.Catalog and a.Catalog.SortWithinGroup or 0
                local bWithin = b.Catalog and b.Catalog.SortWithinGroup or 0
                if aWithin ~= bWithin then
                    return aWithin < bWithin
                end
            end

            return tostring(a.DisplayName) < tostring(b.DisplayName)
        end

        local function applyLocalTradeInventoryOfferState(tradeInventory)
            tradeInventory = tradeInventory or shared.MM2TradeInventory
            if not tradeInventory or not tradeInventory.Data then
                return
            end

            local offeredCounts = {}
            for _, slot in ipairs(shared.MM2LocalTradeSlots) do
                offeredCounts[slot.ItemType] = offeredCounts[slot.ItemType] or {}
                offeredCounts[slot.ItemType][slot.Key] = (offeredCounts[slot.ItemType][slot.Key] or 0) + (tonumber(slot.Amount) or 0)
            end

            for category, buckets in pairs(tradeInventory.Data) do
                local categoryOffers = offeredCounts[category] or {}
                for _, bucket in pairs(buckets) do
                    for itemId, itemData in pairs(bucket) do
                        local frame = itemData and itemData.Frame
                        if frame then
                            local baseAmount = tonumber(itemData.BaseAmount or itemData.Amount) or 0
                            local offered = tonumber(categoryOffers[itemId]) or 0
                            local remaining = math.max(baseAmount - offered, 0)

                            itemData.Amount = remaining
                            frame.Visible = remaining > 0

                            local container = frame:FindFirstChild("Container")
                            local amountLabel = container and container:FindFirstChild("Amount")
                            if amountLabel and amountLabel:IsA("TextLabel") then
                                amountLabel.Text = remaining > 1 and ("x" .. remaining) or ""
                            end
                        end
                    end
                end
            end
        end

        local function collectTradeInventoryEntries()
            local pd = getProfileDataTable()
            local entries = {}
            if not pd then
                return entries
            end

            local function pushCategory(category, owned)
                if not owned then
                    return
                end

                for itemId, amount in pairs(owned) do
                    local count = tonumber(amount) or 0
                    if count > 0 then
                        local catalog = getCatalogItem(itemId)
                        local displayName = catalog and (catalog.custom or catalog.original) or tostring(itemId)
                        table.insert(entries, {
                            ItemId = itemId,
                            DisplayName = displayName,
                            Category = category,
                            Count = count,
                            Catalog = catalog,
                        })
                    end
                end
            end

            pushCategory("Weapons", pd.Weapons and pd.Weapons.Owned)
            pushCategory("Pets", pd.Pets and pd.Pets.Owned)

            table.sort(entries, compareTradeInventoryEntries)

            return entries
        end

        local function safeChild(parent, name)
            if not parent then return nil end
            return parent:FindFirstChild(name)
        end

        local function getTradeGui()
            local pg = player:FindFirstChild("PlayerGui")
            return pg and pg:FindFirstChild("TradeGUI") or nil
        end

        local function getTradeOfferContainer(side)
            side = side or "YourOffer"
            local gui = getTradeGui()
            if not gui then return nil end
            local container = safeChild(gui, "Container")
            container = safeChild(container, "Trade")
            if side == "TheirOffer" then
                container = safeChild(container, "TheirOffer") or safeChild(container, "OtherOffer") or safeChild(container, "OpponentOffer")
            else
                container = safeChild(container, side)
            end
            container = safeChild(container, "Container")
            return container
        end

        local function getTradeTheirOfferContainer()
            return getTradeOfferContainer("TheirOffer")
        end

        local function rebuildLocalTradeCountsInto(state, slots)
            state.Weapons = {}
            state.Pets = {}
            state.Misc = {}

            for _, slot in ipairs(slots) do
                state[slot.ItemType] = state[slot.ItemType] or {}
                state[slot.ItemType][slot.Key] = slot.Amount
            end
        end

        local function rebuildLocalTradeCounts()
            rebuildLocalTradeCountsInto(shared.MM2LocalTradeState, shared.MM2LocalTradeSlots)
        end

        local function rebuildLocalTradeTheirCounts()
            rebuildLocalTradeCountsInto(shared.MM2LocalTradeTheirState, shared.MM2LocalTradeTheirSlots)
        end

        local function getSyncAndItemModule()
            local rep = game:GetService("ReplicatedStorage")
            local db = rep:FindFirstChild("Database")
            local modules = rep:FindFirstChild("Modules")
            local syncObj = db and db:FindFirstChild("Sync")
            local itemObj = modules and modules:FindFirstChild("ItemModule")
            if not syncObj or not itemObj then
                return nil, nil
            end
            local syncOk, sync = pcall(require, syncObj)
            local itemOk, itemModule = pcall(require, itemObj)
            if not syncOk or not itemOk then
                return nil, nil
            end
            return sync, itemModule
        end

        local function displayLocalSlot(slotFrame, itemName, itemType, amount, removeFn)
            local sync, itemModule = getSyncAndItemModule()
            if not sync or not itemModule then
                return false
            end

            local itemData = sync[itemType] and sync[itemType][itemName]
            if not itemData then
                return false
            end

            pcall(function()
                itemModule.DisplayItem(slotFrame, itemData)
            end)

            local oldConn = localTradeSlotConnections[slotFrame]
            if oldConn then
                oldConn:Disconnect()
                localTradeSlotConnections[slotFrame] = nil
            end

            local container = slotFrame:FindFirstChild("Container")
            if container then
                local amountLabel = container:FindFirstChild("Amount")
                if amountLabel and amountLabel:IsA("TextLabel") then
                    amountLabel.Text = amount and amount > 1 and ("x" .. amount) or ""
                end
                local actionButton = container:FindFirstChild("ActionButton")
                if actionButton and actionButton:IsA("GuiButton") then
                    actionButton.Visible = true
                end
                local gradient = container:FindFirstChild("Gradient")
                if gradient then
                    gradient.Visible = true
                end
                local icon = container:FindFirstChild("Icon")
                if icon and icon:IsA("ImageLabel") then
                    icon.Visible = true
                end

                local actionButton = container:FindFirstChild("ActionButton")
                if actionButton and actionButton:IsA("GuiButton") then
                    localTradeSlotConnections[slotFrame] = actionButton.MouseButton1Click:Connect(function()
                        if removeFn then
                            removeFn(itemName, itemType)
                        end
                    end)
                end
            end
            slotFrame.Visible = true
            return true
        end

        local function refreshLocalTradeGui()
            local offerContainer = getTradeOfferContainer("YourOffer")
            if not offerContainer then
                return
            end

            for i = 1, 4 do
                local slot = offerContainer:FindFirstChild("NewItem" .. i)
                if slot then
                    local data = shared.MM2LocalTradeSlots[i]
                    if data then
                        local ok = displayLocalSlot(slot, data.Key, data.ItemType, data.Amount, RemoveItemLocal)
                        if not ok then
                            slot.Visible = false
                            local oldConn = localTradeSlotConnections[slot]
                            if oldConn then
                                oldConn:Disconnect()
                                localTradeSlotConnections[slot] = nil
                            end
                        end
                    else
                        slot.Visible = false
                        local oldConn = localTradeSlotConnections[slot]
                        if oldConn then
                            oldConn:Disconnect()
                            localTradeSlotConnections[slot] = nil
                        end
                    end
                end
            end
        end

        local function refreshLocalTradeTheirGui()
            local offerContainer = getTradeTheirOfferContainer()
            if not offerContainer then
                return
            end

            for i = 1, 4 do
                local slot = offerContainer:FindFirstChild("NewItem" .. i)
                if slot then
                    local data = shared.MM2LocalTradeTheirSlots[i]
                    if data then
                        local ok = displayLocalSlot(slot, data.Key, data.ItemType, data.Amount, RemoveItemLocalTheir)
                        if not ok then
                            slot.Visible = false
                            local oldConn = localTradeSlotConnections[slot]
                            if oldConn then
                                oldConn:Disconnect()
                                localTradeSlotConnections[slot] = nil
                            end
                        end
                    else
                        slot.Visible = false
                        local oldConn = localTradeSlotConnections[slot]
                        if oldConn then
                            oldConn:Disconnect()
                            localTradeSlotConnections[slot] = nil
                        end
                    end
                end
            end
        end

        local refreshLocalTradeInventoryGui

        refreshLocalTradeInventoryGui = function()
            local trade = getTradeGui()
            if not trade then
                return
            end

            local container = safeChild(trade, "Container")
            local itemsRoot = safeChild(container, "Items")
            if not itemsRoot then
                return
            end

            local inventoryOk, inventoryModule = pcall(require, game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("InventoryModule"))
            if not inventoryOk or not inventoryModule then
                return
            end

            for card, conn in pairs(localTradeInventoryConnections) do
                if conn then
                    pcall(function()
                        conn:Disconnect()
                    end)
                end
                localTradeInventoryConnections[card] = nil
            end

            local profileData = getProfileDataTable()
            if not profileData then
                return
            end

            local main = safeChild(itemsRoot, "Main")
            if not main then
                return
            end

            for _, category in ipairs({ "Weapons", "Pets" }) do
                local categoryFrame = safeChild(main, category)
                local itemsFrame = safeChild(categoryFrame, "Items")
                local holder = safeChild(itemsFrame, "Container")
                local current = safeChild(holder, "Current")
                local currentContainer = safeChild(current, "Container")
                if currentContainer then
                    for _, child in ipairs(currentContainer:GetChildren()) do
                        child:Destroy()
                    end
                end
            end

            local tradeInventory = inventoryModule.GenerateInventory(itemsRoot, profileData, "Trading")
            shared.MM2TradeInventory = tradeInventory

            for _, categoryData in pairs(tradeInventory.Data or {}) do
                for _, bucket in pairs(categoryData) do
                    for _, itemData in pairs(bucket) do
                        itemData.BaseAmount = tonumber(itemData.Amount) or 0
                    end
                end
            end

            applyLocalTradeInventoryOfferState(tradeInventory)

            local function hookButtons(category)
                local categoryData = tradeInventory and tradeInventory.Data and tradeInventory.Data[category]
                if not categoryData then
                    return
                end

                for _, bucket in pairs(categoryData) do
                    for itemId, itemData in pairs(bucket) do
                        local frame = itemData and itemData.Frame
                        local containerFrame = frame and frame:FindFirstChild("Container")
                        local actionButton = containerFrame and containerFrame:FindFirstChild("ActionButton")
                        if frame and actionButton and actionButton:IsA("GuiButton") then
                            local oldConn = localTradeInventoryConnections[frame]
                            if oldConn then
                                pcall(function()
                                    oldConn:Disconnect()
                                end)
                            end
                            localTradeInventoryConnections[frame] = actionButton.MouseButton1Click:Connect(function()
                                OfferOwnedItemLocal(itemId, category)
                            end)
                        end
                    end
                end
            end

            hookButtons("Weapons")
            hookButtons("Pets")
        end

        shared.MM2RefreshTradeOffers = function()
            refreshLocalTradeGui()
            refreshLocalTradeTheirGui()
        end

        local function resolveTradeBucket(category)
            category = category or "Weapons"
            shared.MM2LocalTradeState[category] = shared.MM2LocalTradeState[category] or {}
            return shared.MM2LocalTradeState[category]
        end

        local function addTradeSlot(slots, itemName, category)
            local item = getCatalogItem(itemName)
            local key = item and item.original or itemName
            local itemType = category or (item and item.category) or "Weapons"
            local slot

            for _, existing in ipairs(slots) do
                if existing.Key == key and existing.ItemType == itemType then
                    slot = existing
                    break
                end
            end

            if slot then
                slot.Amount += 1
            elseif #slots < 4 then
                table.insert(slots, {
                    Key = key,
                    ItemType = itemType,
                    Amount = 1,
                })
            else
                return false
            end

            return true
        end

        local function removeTradeSlot(slots, itemName, category)
            local item = getCatalogItem(itemName)
            local key = item and item.original or itemName
            local itemType = category or (item and item.category) or "Weapons"

            for index, existing in ipairs(slots) do
                if existing.Key == key and existing.ItemType == itemType then
                    existing.Amount -= 1
                    if existing.Amount <= 0 then
                        table.remove(slots, index)
                    end
                    return true
                end
            end

            return false
        end

        function OfferItemLocal(itemName, category)
            local ok = addTradeSlot(shared.MM2LocalTradeSlots, itemName, category)
            if not ok then
                return false
            end

            rebuildLocalTradeCounts()
            applyLocalTradeInventoryOfferState()
            refreshLocalTradeGui()
            return true
        end

        function OfferOwnedItemLocal(itemName, category)
            local item = getCatalogItem(itemName)
            local key = item and item.original or itemName
            if getOwnedCount(key) <= 0 then
                return false, "not_owned"
            end
            return OfferItemLocal(key, category or (item and item.category) or "Weapons")
        end

        function RemoveItemLocal(itemName, category)
            local ok = removeTradeSlot(shared.MM2LocalTradeSlots, itemName, category)
            if not ok then
                return false
            end

            rebuildLocalTradeCounts()
            applyLocalTradeInventoryOfferState()
            refreshLocalTradeGui()
            return true
        end

        function OfferItemLocalTheir(itemName, category)
            if category == nil and not getCatalogItem(itemName) then
                return false, "unknown_item"
            end

            local ok = addTradeSlot(shared.MM2LocalTradeTheirSlots, itemName, category)
            if not ok then
                return false
            end

            rebuildLocalTradeTheirCounts()
            refreshLocalTradeTheirGui()
            return true
        end

        function RemoveItemLocalTheir(itemName, category)
            local ok = removeTradeSlot(shared.MM2LocalTradeTheirSlots, itemName, category)
            if not ok then
                return false
            end

            rebuildLocalTradeTheirCounts()
            refreshLocalTradeTheirGui()
            return true
        end

        function ClearLocalTradeTheir(category)
            if category then
                for i = #shared.MM2LocalTradeTheirSlots, 1, -1 do
                    if shared.MM2LocalTradeTheirSlots[i].ItemType == category then
                        table.remove(shared.MM2LocalTradeTheirSlots, i)
                    end
                end
            else
                table.clear(shared.MM2LocalTradeTheirSlots)
            end
            rebuildLocalTradeTheirCounts()
            refreshLocalTradeTheirGui()
        end

        function ClearLocalTrade(category)
            if category then
                for i = #shared.MM2LocalTradeSlots, 1, -1 do
                    if shared.MM2LocalTradeSlots[i].ItemType == category then
                        table.remove(shared.MM2LocalTradeSlots, i)
                    end
                end
            else
                table.clear(shared.MM2LocalTradeSlots)
            end
            rebuildLocalTradeCounts()
            applyLocalTradeInventoryOfferState()
            refreshLocalTradeGui()
        end

        task.spawn(function()
            local pg = player:WaitForChild("PlayerGui")
            local function scheduleRefresh()
                task.defer(function()
                    task.wait(0.15)
                    refreshLocalTradeGui()
                    refreshLocalTradeTheirGui()
                end)
            end

            if pg:FindFirstChild("TradeGUI") then
                scheduleRefresh()
            end

            pg.ChildAdded:Connect(function(child)
                if child.Name == "TradeGUI" then
                    scheduleRefresh()
                end
            end)
        end)

        getItemTypeLabel = function(name)
            name = tostring(name or "")
            if name:find("Chroma") then
                return "CHR", Color3.fromRGB(255, 255, 255)
            end
            local lower = name:lower()
            if lower:find("gun") or lower:find("cannon") or lower:find("scope") or lower:find("shot") then
                return "GUN", Color3.fromRGB(200, 200, 200)
            end
            return "KNF", Color3.fromRGB(160, 160, 160)
        end

        selectedItem = nil
        local itemButtons  = {}

        local function getPreviewItemLabel(originalName)
            for _, item in ipairs(items) do
                if item.original == originalName then
                    return item.custom, getItemTypeLabel(item.custom)
                end
            end
            return originalName, getItemTypeLabel(originalName)
        end

        for i, item in ipairs(items) do
            local row = Instance.new("TextButton")
            row.Size = UDim2.new(1, 0, 0, 36)
            row.BackgroundColor3 = COLORS.Card
            row.Text = ""
            row.AutoButtonColor = false
            row.BorderSizePixel = 0
            row.LayoutOrder = i
            row.ClipsDescendants = true
            row.ZIndex = 5
            row.Parent = scrollFrame
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

            local rowStroke = Instance.new("UIStroke", row)
            rowStroke.Color = Color3.fromRGB(180, 180, 180)
            rowStroke.Thickness = 1
            rowStroke.Transparency = 1

            local indicator = Instance.new("Frame")
            indicator.Size = UDim2.new(0, 3, 0.65, 0)
            indicator.Position = UDim2.new(0, 0, 0.175, 0)
            indicator.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
            indicator.BackgroundTransparency = 1
            indicator.BorderSizePixel = 0
            indicator.ZIndex = 6
            indicator.Parent = row
            Instance.new("UICorner", indicator).CornerRadius = UDim.new(0, 2)

            local typeLabel, typeColor = getItemTypeLabel(item.custom)
            local badge = Instance.new("TextLabel")
            badge.Size = UDim2.new(0, 32, 0, 18)
            badge.Position = UDim2.new(0, 7, 0.5, -9)
            badge.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            badge.BackgroundTransparency = 0.3
            badge.Text = typeLabel
            badge.TextColor3 = typeColor
            badge.Font = Enum.Font.GothamBold
            badge.TextSize = 9
            badge.ZIndex = 6
            badge.Parent = row
            Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 4)
            local badgeStroke = Instance.new("UIStroke", badge)
            badgeStroke.Color = typeColor
            badgeStroke.Thickness = 1
            badgeStroke.Transparency = 0.6

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -120, 1, 0)
            label.Position = UDim2.new(0, 46, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = item.custom
            label.TextColor3 = COLORS.TextSub
            label.Font = Enum.Font.Gotham
            label.TextSize = 13
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.ZIndex = 6
            label.Parent = row

            local selTag = Instance.new("Frame")
            selTag.Size = UDim2.new(0, 62, 0, 20)
            selTag.Position = UDim2.new(1, -68, 0.5, -10)
            selTag.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
            selTag.BackgroundTransparency = 1
            selTag.BorderSizePixel = 0
            selTag.ZIndex = 6
            selTag.Parent = row
            Instance.new("UICorner", selTag).CornerRadius = UDim.new(0, 5)
            local selTagStroke = Instance.new("UIStroke", selTag)
            selTagStroke.Color = Color3.fromRGB(200, 200, 200)
            selTagStroke.Thickness = 1
            selTagStroke.Transparency = 1

            local selTagText = Instance.new("TextLabel")
            selTagText.Size = UDim2.new(1, 0, 1, 0)
            selTagText.BackgroundTransparency = 1
            selTagText.Text = "ACTIVE"
            selTagText.TextColor3 = Color3.fromRGB(255, 255, 255)
            selTagText.Font = Enum.Font.GothamBold
            selTagText.TextSize = 9
            selTagText.TextTransparency = 1
            selTagText.ZIndex = 7
            selTagText.Parent = selTag

            row.MouseEnter:Connect(function()
                if selectedItem ~= item then
                    tween(row,       0.15, {BackgroundColor3 = COLORS.CardHover}):Play()
                    tween(label,     0.15, {TextColor3 = COLORS.Text}):Play()
                    tween(indicator, 0.15, {BackgroundTransparency = 0.6}):Play()
                    tween(badgeStroke, 0.15, {Transparency = 0.3}):Play()
                end
            end)
            row.MouseLeave:Connect(function()
                if selectedItem ~= item then
                    tween(row,       0.15, {BackgroundColor3 = COLORS.Card}):Play()
                    tween(label,     0.15, {TextColor3 = COLORS.TextSub}):Play()
                    tween(indicator, 0.15, {BackgroundTransparency = 1}):Play()
                    tween(badgeStroke, 0.15, {Transparency = 0.6}):Play()
                end
            end)

            row.MouseButton1Click:Connect(function()
                if selectedItem then
                    for _, d in ipairs(itemButtons) do
                        if d.item == selectedItem then
                            tween(d.row,        0.2, {BackgroundColor3 = COLORS.Card}):Play()
                            tween(d.stroke,     0.2, {Transparency = 1}):Play()
                            tween(d.label,      0.2, {TextColor3 = COLORS.TextSub}):Play()
                            tween(d.indicator,  0.2, {BackgroundTransparency = 1}):Play()
                            tween(d.selTag,     0.2, {BackgroundTransparency = 1}):Play()
                            tween(d.selStroke,  0.2, {Transparency = 1}):Play()
                            tween(d.selTagText, 0.2, {TextTransparency = 1}):Play()
                        end
                    end
                end

                selectedItem = item

                tween(row,        0.2, {BackgroundColor3 = Color3.fromRGB(35, 35, 35)}):Play()
                tween(rowStroke,  0.2, {Transparency = 0.55}):Play()
                tween(label,      0.2, {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
                tween(indicator,  0.2, {BackgroundTransparency = 0}):Play()
                tween(selTag,     0.2, {BackgroundTransparency = 0.75}):Play()
                tween(selTagStroke, 0.2, {Transparency = 0.3}):Play()
                tween(selTagText, 0.2, {TextTransparency = 0}):Play()
            end)

            table.insert(itemButtons, {
                row = row, label = label, badge = badge,
                indicator = indicator,
                selTag = selTag, selStroke = selTagStroke, selTagText = selTagText,
                stroke = rowStroke, item = item
            })
        end

        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #items * 40 + 12)

        local function filterItems(text)
            text = text:lower()
            local visible = 0
            for _, d in ipairs(itemButtons) do
                local show = text == "" or d.item.custom:lower():find(text, 1, true)
                d.row.Visible = show
                if show then
                    visible += 1
                    d.row.LayoutOrder = visible
                end
            end
            scrollFrame.CanvasSize = UDim2.new(0, 0, 0, visible * 40 + 12)
            countLabel.Text = visible == #items
                and ("All items  |  " .. #items .. " total")
                or  (visible .. " of " .. #items .. " found")
        end

        searchBox:GetPropertyChangedSignal("Text"):Connect(function()
            filterItems(searchBox.Text)
        end)

        -- Weapon visual data


        local WeaponVisuals = {
            Harvester = {
                ItemType  = "Gun",
                MeshId    = "rbxassetid://7775027413",
                TextureId = "rbxassetid://7775245551",
                Scale     = Vector3.new(0.060, 0.060, 0.060),
                Rotation  = Vector3.new(0, -40, 90),
            },
            Gingerscope = {
                ItemType  = "Gun",
                MeshId    = "rbxassetid://15374602183",
                TextureId = "rbxassetid://15409041564",
                Scale     = Vector3.new(0.085, 0.085, 0.085),
                Rotation  = Vector3.new(-40, 0, 0),
            },
            Snowcannon = {
                ItemType  = "Gun",
                MeshId    = "rbxassetid://99836890880541",
                TextureId = "rbxassetid://122392330922281",
                Scale     = Vector3.new(0.060, 0.060, 0.060),
                Rotation  = Vector3.new(-40, 0, 0),
            },
            Bauble = {
            ItemType  = "Gun",
            MeshId    = "rbxassetid://107813118898769",
            TextureId = "rbxassetid://137012201908941",
            Scale     = Vector3.new(0.060, 0.060, 0.060),
            Rotation  = Vector3.new(-40, 0, 0),
            },
            BaubleChroma = {
                ItemType   = "Gun",
                MeshId     = "rbxassetid://107813118898769",
                TextureId  = "rbxassetid://137012201908941",
                Scale      = Vector3.new(0.060, 0.060, 0.060),
                Rotation   = Vector3.new(-40, 0, 0),
                Material   = Enum.Material.Neon,
                Color      = Color3.fromRGB(255, 255, 255),
                DecalId    = "rbxassetid://129391884956433",
                DecalFace  = Enum.NormalId.Front,
                DecalName  = "ChromaDecal",
                Chroma     = true,
            },
            TreeGun2023 = {
            ItemType  = "Gun",
            MeshId    = "rbxassetid://15408863676",
            TextureId = "",
            Scale     = Vector3.new(0.085, 0.085, 0.085),
            Rotation  = Vector3.new(-40, 0, 0),
            },
            TravelerAxe = {
                ItemType  = "Knife",
                MeshId    = "rbxassetid://15057341638",
                TextureId = "rbxassetid://15057460725",
                Scale     = Vector3.new(0.085, 0.085, 0.085),
                Rotation  = Vector3.new(0, 0, 0),
            },
            HeartWand = {
                ItemType  = "Knife",
                MeshId    = "rbxassetid://77738838473091",
                TextureId = "rbxassetid://76246633927299",
                Scale     = Vector3.new(0.085, 0.085, 0.085),
                Rotation  = Vector3.new(0, 0, 0),
            },
            Turkey2023 = {
                ItemType  = "Knife",
                MeshId    = "rbxassetid://15414904040",
                TextureId = "rbxassetid://15414905407",
                Scale     = Vector3.new(0.060, 0.060, 0.060),
                Rotation  = Vector3.new(0, 0, 0),
            },

        }

        local vs = { Gun = {active=nil,def=nil}, Knife = {active=nil,def=nil} }
        local activeChroma = {Gun=nil, Knife=nil}
        local watcherPaused = false

        local function getMyDisplay(itemType)
            local char = player.Character
            if not char then return nil end
            local WD = game.Workspace:FindFirstChild("WeaponDisplays")
            if not WD then return nil end
            local name = itemType == "Gun" and "GunDisplay" or "KnifeDisplay"
            for _, d in pairs(WD:GetChildren()) do
                if d.Name == name then
                    local rc = d:FindFirstChildOfClass("RigidConstraint")
                    if rc and rc.Attachment0 and rc.Attachment0:IsDescendantOf(char) then return d end
                end
            end
        end

        local function getDisplayParts(display)
            local parts = {}
            if display:IsA("BasePart") then
                table.insert(parts, display)
            end
            for _, obj in ipairs(display:GetDescendants()) do
                if obj:IsA("BasePart") then
                    table.insert(parts, obj)
                end
            end
            return parts
        end

        local function writeMesh(display, itemType, meshId, textureId, scale, rotation, material, color, defAttCFrame, decalId, decalFace, decalName)
            local parts = getDisplayParts(display)
            if #parts == 0 and display:IsA("BasePart") then
                table.insert(parts, display)
            end

            for _, part in ipairs(parts) do
        -- Apply mesh texture and material
                if part:IsA("MeshPart") then
                    pcall(function() part.MeshId = meshId end)
                    pcall(function() part.TextureID = textureId end)
                else
                    local sm = part:FindFirstChildOfClass("SpecialMesh")
                    if sm then
                        sm.MeshId = meshId; sm.TextureId = textureId
                        sm.Offset = Vector3.new(0,0,0); sm.VertexColor = Vector3.new(1,1,1)
                        if scale then sm.Scale = scale end
                    end
                end

        -- Apply material first, then color for neon parts
                if material then
                    pcall(function() part.Material = material end)
                end
                if color then
                    pcall(function() part.Color = color end)
                end

                if decalId and decalName then
                    local decal = part:FindFirstChild(decalName)
                    if not decal then
                        decal = Instance.new("Decal")
                        decal.Name = decalName
                        decal.Parent = part
                    end
                    decal.Texture = decalId
                    decal.Face = decalFace or Enum.NormalId.Front
                end
            end

            local att = display:FindFirstChildOfClass("Attachment")
            if not att then
                for _, descendant in ipairs(display:GetDescendants()) do
                    if descendant:IsA("Attachment") then
                        att = descendant
                        break
                    end
                end
            end
            if att then
                local pos = att.CFrame.Position
                local baseRot = (defAttCFrame and defAttCFrame.AttRotation) or (att.CFrame - pos)
                if rotation then
                    att.CFrame = CFrame.new(pos) * baseRot * CFrame.Angles(math.rad(rotation.X), math.rad(rotation.Y), math.rad(rotation.Z))
                else
                    att.CFrame = CFrame.new(pos) * baseRot
                end
            end
        end

        local function captureDefault(display, itemType)
            if vs[itemType].def then return end
            local def = {}
            local att = display:FindFirstChildOfClass("Attachment")
            if not att then
                for _, descendant in ipairs(display:GetDescendants()) do
                    if descendant:IsA("Attachment") then
                        att = descendant
                        break
                    end
                end
            end
            def.AttRotation = att and (att.CFrame - att.CFrame.Position) or nil

            local parts = getDisplayParts(display)
            local targetPart = parts[1]
            if not targetPart and display:IsA("BasePart") then
                targetPart = display
            end

            if targetPart and targetPart:IsA("MeshPart") then
                local ok1, mid = pcall(function() return targetPart.MeshId end)
                local ok2, tid = pcall(function() return targetPart.TextureID end)
                def.MeshId = (ok1 and mid) or ""; def.TextureId = (ok2 and tid) or ""; def.Scale = nil
            else
                local sm
                if targetPart then sm = targetPart:FindFirstChildOfClass("SpecialMesh") end
                if not sm then
                    for _, part in ipairs(parts) do
                        sm = part:FindFirstChildOfClass("SpecialMesh")
                        if sm then break end
                    end
                end
                if sm then def.MeshId = sm.MeshId; def.TextureId = sm.TextureId; def.Scale = sm.Scale
                else def.MeshId = ""; def.TextureId = "" end
            end

            if targetPart and targetPart:IsA("BasePart") then
                local ok3, mat = pcall(function() return targetPart.Material end)
                local ok4, col = pcall(function() return targetPart.Color end)
                def.Material = (ok3 and mat) or Enum.Material.Plastic
                def.Color = (ok4 and col) or Color3.new(1,1,1)
            else
                def.Material = Enum.Material.Plastic
                def.Color = Color3.new(1,1,1)
            end
            vs[itemType].def = def
        end

        local function applyVisual(weaponName)
            local data = WeaponVisuals[weaponName]
            if not data then return false end
            local itype = data.ItemType
            local display = getMyDisplay(itype)
            if not display then return false end
            captureDefault(display, itype)
            writeMesh(display, itype, data.MeshId, data.TextureId, data.Scale, data.Rotation, data.Material, data.Color, vs[itype].def, data.DecalId, data.DecalFace, data.DecalName)
            if data.Chroma then activeChroma[itype] = display else activeChroma[itype] = nil end
            vs[itype].active = weaponName
            return true
        end

        task.spawn(function()
            while true do
                task.wait(0.06)
                for itype, display in pairs(activeChroma) do
                    if display and display.Parent then
                        local hue = (tick() * 0.18) % 1
                        local color = Color3.fromHSV(hue, 1, 1)
                        for _, part in ipairs(getDisplayParts(display)) do
                            pcall(function()
                                part.Material = Enum.Material.Neon
                                part.Color = color
                            end)
                        end
                    end
                end
            end
        end)

        local function resetToDefault(itemType, defSnap)
            if not defSnap or defSnap.MeshId == "" then vs[itemType].active = nil; activeChroma[itemType] = nil; return false end
            local display = getMyDisplay(itemType)
            if not display then return false end
            writeMesh(display, itemType, defSnap.MeshId, defSnap.TextureId, defSnap.Scale, nil, defSnap.Material, defSnap.Color, defSnap, nil, nil, nil)
            for _, part in ipairs(getDisplayParts(display)) do
                for _, decal in ipairs(part:GetChildren()) do
                    if decal:IsA("Decal") and decal.Name == "ChromaDecal" then decal:Destroy() end
                end
            end
            vs[itemType].active = nil
            activeChroma[itemType] = nil
            return true
        end

        local function getProfileEquipped(itemType)
            local ok, pd = pcall(function() return require(game:GetService("ReplicatedStorage").Modules.ProfileData) end)
            if not ok or not pd then return nil end
            local eq = pd.Weapons and pd.Weapons.Equipped
            return eq and eq[itemType] or nil
        end

        local function onDisplayAdded(display)
            local itemType
            if display.Name == "GunDisplay" then itemType = "Gun"
            elseif display.Name == "KnifeDisplay" then itemType = "Knife"
            else return end
            for i = 1, 15 do
                task.wait(0.2)
                local char = player.Character
                if not char then return end
                local rc = display:FindFirstChildOfClass("RigidConstraint")
                if rc and rc.Attachment0 and rc.Attachment0:IsDescendantOf(char) then break end
                if i == 15 then return end
            end
            vs[itemType].active = nil; vs[itemType].def = nil
            local name = getProfileEquipped(itemType)
            if name and WeaponVisuals[name] then task.wait(0.15); applyVisual(name) end
        end

        task.spawn(function()
            local WD = game.Workspace:WaitForChild("WeaponDisplays", 10)
            if not WD then return end
            for _, d in pairs(WD:GetChildren()) do task.spawn(onDisplayAdded, d) end
            WD.ChildAdded:Connect(function(d) task.spawn(onDisplayAdded, d) end)
            WD.ChildRemoved:Connect(function(d)
                local itype = d.Name == "GunDisplay" and "Gun" or (d.Name == "KnifeDisplay" and "Knife" or nil)
                if itype then vs[itype].active = nil; vs[itype].def = nil end
            end)
        end)

        task.spawn(function()
            local last = {Gun=nil,Knife=nil}
            local ok0, pd0 = pcall(function() return require(game:GetService("ReplicatedStorage").Modules.ProfileData) end)
            if ok0 and pd0 and pd0.Weapons and pd0.Weapons.Equipped then
                last.Gun = pd0.Weapons.Equipped.Gun; last.Knife = pd0.Weapons.Equipped.Knife
            end
            local pending = {}
            while true do
                task.wait(0.3)
                if watcherPaused then continue end
                local ok, pd = pcall(function() return require(game:GetService("ReplicatedStorage").Modules.ProfileData) end)
                if not ok or not pd then continue end
                local eq = pd.Weapons and pd.Weapons.Equipped
                if not eq then continue end
                for _, itype in ipairs({"Gun","Knife"}) do
                    local cur = eq[itype]
                    if cur ~= last[itype] then
                        local prev = last[itype]; last[itype] = cur
                        if cur and WeaponVisuals[cur] then
                            pending[itype] = {action="apply",name=cur,attempts=0}
                        elseif prev and WeaponVisuals[prev] then
                            pending[itype] = {action="reset",defSnap=vs[itype].def,attempts=0}
                        end
                    end
                end
                for itype, job in pairs(pending) do
                    if job.action == "apply" then
                        if applyVisual(job.name) then pending[itype]=nil
                        else job.attempts+=1; if job.attempts>=20 then pending[itype]=nil end end
                    elseif job.action == "reset" then
                        if resetToDefault(itype,job.defSnap) then pending[itype]=nil
                        else job.attempts+=1; if job.attempts>=20 then pending[itype]=nil end end
                    end
                end
            end
        end)

        -- Spawn logic

        -- РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’
        local function spawnItem(name)
            local PlayerData = require(game:GetService("ReplicatedStorage").Modules.ProfileData)
            local PlayerWeapons = PlayerData.Weapons
            local originalName = name
            for _, item in ipairs(items) do
                if item.custom == name then originalName = item.original; break end
            end

            if not PlayerWeapons.Owned[originalName] then
                PlayerWeapons.Owned[originalName] = 1
            else
                PlayerWeapons.Owned[originalName] += 1
            end
            PlayerData.Weapons = PlayerWeapons

            local Remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
            if Remotes then
                local inv = Remotes:FindFirstChild("Inventory")
                if inv then
                    local ce = inv:FindFirstChild("ChangeInventoryItem")
                    if ce then pcall(function() ce:FireServer(originalName, "Add") end) end
                    local dc = inv:FindFirstChild("InventoryDataChanged")
                    if dc then pcall(function() dc:Fire() end) end
                end
            end
        end

        local function showProgress(itemName)
            spawnBtn.Visible = false
            progressBG.Visible = true
            local totalTime = 3
            local startTime = tick()
            while tick() - startTime < totalTime do
                local p = (tick() - startTime) / totalTime
                progressLabel.Text = "Adding:  " .. itemName
                tween(progressFill, 0.08, {Size = UDim2.new(p, 0, 1, 0)}):Play()
                task.wait(0.05)
            end
            tween(progressFill, 0.2, {Size = UDim2.new(1,0,1,0), BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
            progressLabel.Text = "Done!"
            task.wait(0.9)
            progressFill.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
            progressFill.Size = UDim2.new(0,0,1,0)
            progressBG.Visible = false
            spawnBtn.Visible = true
        end

        spawnBtn.MouseButton1Click:Connect(function()
            if not selectedItem then
                local orig = searchOuter.Position
                for i = 1, 4 do
                    tween(searchOuter, 0.05, {Position = UDim2.new(orig.X.Scale, orig.X.Offset+8, orig.Y.Scale, orig.Y.Offset)}):Play()
                    task.wait(0.055)
                    tween(searchOuter, 0.05, {Position = UDim2.new(orig.X.Scale, orig.X.Offset-8, orig.Y.Scale, orig.Y.Offset)}):Play()
                    task.wait(0.055)
                end
                tween(searchOuter, 0.05, {Position = orig}):Play()
                showToast("Select an item first!", true)
                return
            end
            local capturedItem = selectedItem
            task.spawn(function() showProgress(capturedItem.custom) end)
            watcherPaused = true
            spawnItem(capturedItem.custom)
            showToast(capturedItem.custom .. " added!")
            task.delay(4, function() watcherPaused = false end)
        end)

        -- Open and close GUI


        local isOpen = false

        local function openGUI()
            isOpen = true
            mainFrame.Visible = true
            outerGlow.Visible = true
            local mainW, mainH, glowW, glowH = getScaledGuiMetrics(guiScale)
            mainFrame.Size = UDim2.new(0, mainW, 0, 0)
            mainFrame.Position = UDim2.new(0.5, -math.floor(mainW / 2), 0.5, 0)
            outerGlow.Size = UDim2.new(0, glowW, 0, glowH)
            outerGlow.Position = UDim2.new(0.5, -math.floor(glowW / 2), 0.5, -math.floor(glowH / 2))
            outerGlow.BackgroundTransparency = 1
            tween(mainFrame, 0.5, {Size = UDim2.new(0, mainW, 0, mainH), Position = UDim2.new(0.5, -math.floor(mainW / 2), 0.5, -math.floor(mainH / 2))}, Enum.EasingStyle.Back):Play()
            tween(outerGlow, 0.6, {BackgroundTransparency = 0.92}):Play()
        end

        local function closeGUI()
            isOpen = false
            local mainW = getScaledGuiMetrics(guiScale)
            tween(mainFrame, 0.3, {Size = UDim2.new(0, mainW, 0, 0), Position = UDim2.new(0.5, -math.floor(mainW / 2), 0.5, 0)}, Enum.EasingStyle.Back, Enum.EasingDirection.In):Play()
            tween(outerGlow, 0.3, {BackgroundTransparency = 1}):Play()
            task.delay(0.35, function()
                mainFrame.Visible = false
                outerGlow.Visible = false
            end)
        end

        closeBtn.MouseButton1Click:Connect(closeGUI)

        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Size = UDim2.new(0, 46, 0, 46)
        toggleBtn.Position = UDim2.new(1, -58, 1, -58)
        toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
        toggleBtn.Text = "MM2"
        toggleBtn.TextColor3 = Color3.fromRGB(10, 10, 10)
        toggleBtn.Font = Enum.Font.GothamBold
        toggleBtn.TextSize = 11
        toggleBtn.BorderSizePixel = 0
        toggleBtn.AutoButtonColor = false
        toggleBtn.ZIndex = 10
        toggleBtn.Parent = screenGui
        Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 13)
        local toggleGrad = Instance.new("UIGradient", toggleBtn)
        toggleGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 100, 100)),
        })
        toggleGrad.Rotation = 135
        local toggleStroke = Instance.new("UIStroke", toggleBtn)
        toggleStroke.Color = Color3.fromRGB(255, 255, 255)
        toggleStroke.Thickness = 1.5
        toggleStroke.Transparency = 0.3

        toggleBtn.MouseEnter:Connect(function()
            tween(toggleBtn, 0.15, {Size = UDim2.new(0,50,0,50), Position = UDim2.new(1,-60,1,-60)}):Play()
            tween(toggleGrad, 0.15, {Rotation = 115}):Play()
        end)
        toggleBtn.MouseLeave:Connect(function()
            tween(toggleBtn, 0.15, {Size = UDim2.new(0,46,0,46), Position = UDim2.new(1,-58,1,-58)}):Play()
            tween(toggleGrad, 0.15, {Rotation = 135}):Play()
        end)
        toggleBtn.MouseButton1Click:Connect(function()
            if isOpen then closeGUI() else openGUI() end
        end)
        local previewBtn = Instance.new("TextButton")
        previewBtn.Size = UDim2.new(0, 46, 0, 46)
        previewBtn.Position = UDim2.new(1, -58, 1, -110)
        previewBtn.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
        previewBtn.Text = "TRD"
        previewBtn.TextColor3 = Color3.fromRGB(10, 10, 10)
        previewBtn.Font = Enum.Font.GothamBold
        previewBtn.TextSize = 11
        previewBtn.BorderSizePixel = 0
        previewBtn.AutoButtonColor = false
        previewBtn.ZIndex = 10
        previewBtn.Parent = screenGui
        Instance.new("UICorner", previewBtn).CornerRadius = UDim.new(0, 13)
        local previewGrad = Instance.new("UIGradient", previewBtn)
        previewGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 100, 100)),
        })
        previewGrad.Rotation = 135
        local previewStroke = Instance.new("UIStroke", previewBtn)
        previewStroke.Color = Color3.fromRGB(255, 255, 255)
        previewStroke.Thickness = 1.5
        previewStroke.Transparency = 0.3

        previewBtn.MouseEnter:Connect(function()
            tween(previewBtn, 0.15, {Size = UDim2.new(0,50,0,50), Position = UDim2.new(1,-60,1,-112)}):Play()
            tween(previewGrad, 0.15, {Rotation = 115}):Play()
        end)
        previewBtn.MouseLeave:Connect(function()
            tween(previewBtn, 0.15, {Size = UDim2.new(0,46,0,46), Position = UDim2.new(1,-58,1,-110)}):Play()
            tween(previewGrad, 0.15, {Rotation = 135}):Play()
        end)

        previewFrame = Instance.new("Frame")
        previewFrame.Size = UDim2.new(0, 320, 0, 330)
        previewFrame.Position = UDim2.new(1, -350, 0.5, -165)
        previewFrame.BackgroundColor3 = COLORS.BG
        previewFrame.BorderSizePixel = 0
        previewFrame.ClipsDescendants = true
        previewFrame.Visible = false
        previewFrame.ZIndex = 20
        previewFrame.Parent = screenGui
        Instance.new("UICorner", previewFrame).CornerRadius = UDim.new(0, 18)
        local previewBorder = Instance.new("UIStroke", previewFrame)
        previewBorder.Color = Color3.fromRGB(180, 180, 180)
        previewBorder.Thickness = 1.5
        previewBorder.Transparency = 0.35

        local previewHeader = Instance.new("Frame")
        previewHeader.Size = UDim2.new(1, 0, 0, 56)
        previewHeader.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
        previewHeader.BorderSizePixel = 0
        previewHeader.ZIndex = 21
        previewHeader.Parent = previewFrame
        Instance.new("UICorner", previewHeader).CornerRadius = UDim.new(0, 18)

        local previewHeaderFix = Instance.new("Frame")
        previewHeaderFix.Size = UDim2.new(1, 0, 0, 18)
        previewHeaderFix.Position = UDim2.new(0, 0, 1, -18)
        previewHeaderFix.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
        previewHeaderFix.BorderSizePixel = 0
        previewHeaderFix.ZIndex = 21
        previewHeaderFix.Parent = previewHeader

        local previewTitle = Instance.new("TextLabel")
        previewTitle.Size = UDim2.new(0, 220, 0, 20)
        previewTitle.Position = UDim2.new(0, 16, 0, 10)
        previewTitle.BackgroundTransparency = 1
        previewTitle.Text = "LOCAL TRADE PREVIEW"
        previewTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
        previewTitle.Font = Enum.Font.GothamBold
        previewTitle.TextSize = 15
        previewTitle.TextXAlignment = Enum.TextXAlignment.Left
        previewTitle.ZIndex = 22
        previewTitle.Parent = previewHeader

        local previewClose = Instance.new("TextButton")
        previewClose.Size = UDim2.new(0, 26, 0, 26)
        previewClose.Position = UDim2.new(1, -38, 0.5, -13)
        previewClose.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
        previewClose.BackgroundTransparency = 0.2
        previewClose.Text = "X"
        previewClose.TextColor3 = Color3.fromRGB(255, 255, 255)
        previewClose.Font = Enum.Font.GothamBold
        previewClose.TextSize = 11
        previewClose.BorderSizePixel = 0
        previewClose.AutoButtonColor = false
        previewClose.ZIndex = 22
        previewClose.Parent = previewHeader
        Instance.new("UICorner", previewClose).CornerRadius = UDim.new(0, 7)
        local previewCloseStroke = Instance.new("UIStroke", previewClose)
        previewCloseStroke.Color = COLORS.Error
        previewCloseStroke.Thickness = 1
        previewCloseStroke.Transparency = 0.5

        previewCountLabel = Instance.new("TextLabel")
        previewCountLabel.Size = UDim2.new(1, -24, 0, 18)
        previewCountLabel.Position = UDim2.new(0, 12, 0, 62)
        previewCountLabel.BackgroundTransparency = 1
        previewCountLabel.Text = "No local items yet"
        previewCountLabel.TextColor3 = COLORS.TextSub
        previewCountLabel.Font = Enum.Font.GothamBold
        previewCountLabel.TextSize = 11
        previewCountLabel.TextXAlignment = Enum.TextXAlignment.Left
        previewCountLabel.ZIndex = 21
        previewCountLabel.Parent = previewFrame

        previewList = Instance.new("ScrollingFrame")
        previewList.Size = UDim2.new(1, -24, 1, -100)
        previewList.Position = UDim2.new(0, 12, 0, 86)
        previewList.BackgroundColor3 = COLORS.Panel
        previewList.BorderSizePixel = 0
        previewList.ScrollBarThickness = 4
        previewList.ScrollBarImageColor3 = Color3.fromRGB(180, 180, 180)
        previewList.CanvasSize = UDim2.new(0, 0, 0, 0)
        previewList.ClipsDescendants = true
        previewList.ZIndex = 21
        previewList.Parent = previewFrame
        Instance.new("UICorner", previewList).CornerRadius = UDim.new(0, 12)
        local previewListStroke = Instance.new("UIStroke", previewList)
        previewListStroke.Color = COLORS.Border
        previewListStroke.Thickness = 1
        previewListStroke.Transparency = 0.4

        local previewLayout = Instance.new("UIListLayout", previewList)
        previewLayout.Padding = UDim.new(0, 4)
        previewLayout.SortOrder = Enum.SortOrder.LayoutOrder

        local previewPad = Instance.new("UIPadding", previewList)
        previewPad.PaddingTop = UDim.new(0, 6)
        previewPad.PaddingBottom = UDim.new(0, 6)
        previewPad.PaddingLeft = UDim.new(0, 6)
        previewPad.PaddingRight = UDim.new(0, 10)

        previewEmptyLabel = Instance.new("TextLabel")
        previewEmptyLabel.Size = UDim2.new(1, -24, 0, 24)
        previewEmptyLabel.Position = UDim2.new(0, 12, 0, 126)
        previewEmptyLabel.BackgroundTransparency = 1
        previewEmptyLabel.Text = "Spawn something to see it here."
        previewEmptyLabel.TextColor3 = COLORS.TextDim
        previewEmptyLabel.Font = Enum.Font.Gotham
        previewEmptyLabel.TextSize = 11
        previewEmptyLabel.ZIndex = 21
        previewEmptyLabel.Parent = previewFrame

        local function rebuildLocalTradePreview()
            if not previewList or not previewCountLabel then
                return
            end

            for _, child in ipairs(previewList:GetChildren()) do
                if child:IsA("Frame") then
                    child:Destroy()
                end
            end

            local entries = 0
            local total = 0

            for _, item in ipairs(items) do
                local count = shared.MM2LocalTradeState.Weapons[item.original] or 0
                if count > 0 then
                    entries += 1
                    total += count

                    local row = Instance.new("Frame")
                    row.Size = UDim2.new(1, 0, 0, 34)
                    row.BackgroundColor3 = COLORS.Card
                    row.BorderSizePixel = 0
                    row.ZIndex = 22
                    row.Parent = previewList
                    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
                    local rowStroke = Instance.new("UIStroke", row)
                    rowStroke.Color = Color3.fromRGB(180, 180, 180)
                    rowStroke.Thickness = 1
                    rowStroke.Transparency = 0.8

                    local typeLabel, typeColor = getItemTypeLabel(item.custom)
                    local badge = Instance.new("TextLabel")
                    badge.Size = UDim2.new(0, 32, 0, 18)
                    badge.Position = UDim2.new(0, 8, 0.5, -9)
                    badge.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                    badge.BackgroundTransparency = 0.2
                    badge.Text = typeLabel
                    badge.TextColor3 = typeColor
                    badge.Font = Enum.Font.GothamBold
                    badge.TextSize = 9
                    badge.ZIndex = 23
                    badge.Parent = row
                    Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 4)
                    local badgeStroke = Instance.new("UIStroke", badge)
                    badgeStroke.Color = typeColor
                    badgeStroke.Thickness = 1
                    badgeStroke.Transparency = 0.65

                    local nameLabel = Instance.new("TextLabel")
                    nameLabel.Size = UDim2.new(1, -120, 1, 0)
                    nameLabel.Position = UDim2.new(0, 48, 0, 0)
                    nameLabel.BackgroundTransparency = 1
                    nameLabel.Text = item.custom
                    nameLabel.TextColor3 = COLORS.Text
                    nameLabel.Font = Enum.Font.Gotham
                    nameLabel.TextSize = 12
                    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                    nameLabel.ZIndex = 23
                    nameLabel.Parent = row

                    local countLabel = Instance.new("TextLabel")
                    countLabel.Size = UDim2.new(0, 42, 0, 18)
                    countLabel.Position = UDim2.new(1, -50, 0.5, -9)
                    countLabel.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
                    countLabel.BackgroundTransparency = 0.15
                    countLabel.Text = "x" .. count
                    countLabel.TextColor3 = Color3.fromRGB(10, 10, 10)
                    countLabel.Font = Enum.Font.GothamBold
                    countLabel.TextSize = 11
                    countLabel.ZIndex = 23
                    countLabel.Parent = row
                    Instance.new("UICorner", countLabel).CornerRadius = UDim.new(0, 5)
                end
            end

            previewCountLabel.Text = entries == 0
                and "No local items yet"
                or (entries .. " item types  |  " .. total .. " copies")
            previewEmptyLabel.Visible = entries == 0
            previewList.CanvasSize = UDim2.new(0, 0, 0, entries * 38 + 8)
        end

        shared.MM2RefreshTradeInventory = function()
            rebuildLocalTradePreview()
            if shared.MM2RefreshTradeInventoryTrade then
                pcall(shared.MM2RefreshTradeInventoryTrade)
            end
            if refreshLocalTradeInventoryGui then
                pcall(refreshLocalTradeInventoryGui)
            end
        end
        shared.MM2RefreshTradeInventory()

        previewClose.MouseButton1Click:Connect(function()
            previewFrame.Visible = false
        end)

        previewBtn.MouseButton1Click:Connect(function()
            previewFrame.Visible = not previewFrame.Visible
            if previewFrame.Visible then
                rebuildLocalTradePreview()
            end
        end)

        makeDraggable(previewHeader, previewFrame)
        local tradePage = Instance.new("Frame")
        tradePage.Name = "TradePage"
        tradePage.Size = UDim2.new(1, -28, 1, -96)
        tradePage.Position = UDim2.new(0, 14, 0, 82)
        tradePage.BackgroundColor3 = COLORS.Panel
        tradePage.BorderSizePixel = 0
        tradePage.Visible = false
        tradePage.ZIndex = 4
        tradePage.Parent = mainFrame
        Instance.new("UICorner", tradePage).CornerRadius = UDim.new(0, 12)
        local tradeStroke = Instance.new("UIStroke", tradePage)
        tradeStroke.Color = COLORS.Border
        tradeStroke.Thickness = 1
        tradeStroke.Transparency = 0.35

        local tradeContent = Instance.new("Frame")
        tradeContent.Name = "TradeContent"
        tradeContent.Size = UDim2.new(1, 0, 1, 0)
        tradeContent.BackgroundTransparency = 1
        tradeContent.BorderSizePixel = 0
        tradeContent.ZIndex = 5
        tradeContent.Parent = tradePage

        local tradeTitle = Instance.new("TextLabel")
        tradeTitle.Size = UDim2.new(1, -24, 0, 26)
        tradeTitle.Position = UDim2.new(0, 12, 0, 14)
        tradeTitle.BackgroundTransparency = 1
        tradeTitle.Text = "Trade"
        tradeTitle.TextColor3 = COLORS.Text
        tradeTitle.Font = Enum.Font.GothamBold
        tradeTitle.TextSize = 18
        tradeTitle.TextXAlignment = Enum.TextXAlignment.Left
        tradeTitle.ZIndex = 6
        tradeTitle.Parent = tradeContent

        local tradeHint = Instance.new("TextLabel")
        tradeHint.Size = UDim2.new(1, -24, 0, 40)
        tradeHint.Position = UDim2.new(0, 12, 0, 46)
        tradeHint.BackgroundTransparency = 1
        tradeHint.Text = "Second script will be placed here."
        tradeHint.TextColor3 = COLORS.TextSub
        tradeHint.Font = Enum.Font.Gotham
        tradeHint.TextSize = 12
        tradeHint.TextWrapped = true
        tradeHint.TextXAlignment = Enum.TextXAlignment.Left
        tradeHint.TextYAlignment = Enum.TextYAlignment.Top
        tradeHint.ZIndex = 6
        tradeHint.Parent = tradeContent

        shared.MM2TradeRoot = tradeContent
        tradeHint.Visible = false

        local settingsPage = Instance.new("Frame")
        settingsPage.Name = "SettingsPage"
        settingsPage.Size = UDim2.new(1, -28, 1, -96)
        settingsPage.Position = UDim2.new(0, 14, 0, 82)
        settingsPage.BackgroundColor3 = COLORS.Panel
        settingsPage.BorderSizePixel = 0
        settingsPage.Visible = false
        settingsPage.ZIndex = 4
        settingsPage.Parent = mainFrame
        Instance.new("UICorner", settingsPage).CornerRadius = UDim.new(0, 12)
        local settingsStroke = Instance.new("UIStroke", settingsPage)
        settingsStroke.Color = COLORS.Border
        settingsStroke.Thickness = 1
        settingsStroke.Transparency = 0.35

        local settingsContent = Instance.new("Frame")
        settingsContent.Name = "SettingsContent"
        settingsContent.Size = UDim2.new(1, 0, 1, 0)
        settingsContent.BackgroundTransparency = 1
        settingsContent.BorderSizePixel = 0
        settingsContent.ZIndex = 5
        settingsContent.Parent = settingsPage

        do
            local T = shared.MM2Trade or {}
            shared.MM2Trade = T

            T.Config = T.Config or {
                PARTNER_NAME = "endeavor3313",
                AUTO_ACCEPT_DELAY = 0.2,
                AUTO_CONFIRM_DELAY = 0.3,
                TRADE_REQUEST_TIMEOUT = 30,
                REQUEST_KEYBIND = Enum.KeyCode.F6,
                RICH_ITEMS_KEYBIND = Enum.KeyCode.F7,
            }

            T.State = T.State or {
                activeTradeRequests = {},
                currentTradeRequest = nil,
                tradeActive = false,
                tradePartner = nil,
                lastOffer = nil,
            }

            T.UI = T.UI or {}
            local ui = T.UI
            local cfg = T.Config
            local state = T.State

            local randomNames = {
                "xXProGamer420Xx", "NeonShadow99", "CrimsonVoid", "PhantomKnight",
                "SilentHunter88", "VortexNinja", "ScarletRaven", "EchoSpecter",
                "NovaNyx", "ThunderStrike", "VenomBlade", "FrostWolf",
                "InfernoFury", "CyberPulse", "AbyssWalker", "SolarFlare",
                "LunaEclipse", "VoidStalker", "PyroclasM", "NightWraith",
                "EmberSoul", "IcePhantom", "ObsidianEdge", "ZenithAbyss",
            }

            local tradeModule = nil
            local tradeGUI = nil
            local tradeRemote = nil
            local tradeSelectedInventoryItem = nil

            local function log(message, level)
                level = level or "INFO"
                local prefix = string.format("[MM2 TRADE] [%s]", level)
                if level == "ERROR" then
                    warn(prefix .. " " .. message)
                elseif level == "SUCCESS" then
                    print(prefix .. " " .. message)
                else
                    print(prefix .. " " .. message)
                end
            end

            local function getRandomName()
                return randomNames[math.random(1, #randomNames)]
            end

            local function setStatus(text, isError)
                if ui.MessageText then
                    ui.MessageText.Text = text
                    ui.MessageText.TextColor3 = isError and COLORS.Error or COLORS.TextSub
                end
            end

            local function waitForTradeModule()
                local success, result = xpcall(function()
                    return require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("TradeModule"))
                end, function(err)
                    log("Error loading TradeModule: " .. tostring(err), "ERROR")
                end)
                return success and result or nil
            end

            local function waitForTradeGUI()
                local pg = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui")
                local gui = pg:FindFirstChild("TradeGUI")
                if gui then
                    return gui
                end

                local starterGui = game:GetService("StarterGui")
                local template = starterGui:FindFirstChild("TradeGUI")
                if template then
                    local clone = template:Clone()
                    clone.Name = "TradeGUI"
                    pcall(function()
                        clone.ResetOnSpawn = false
                    end)
                    clone.Parent = pg
                    return clone
                end

                return nil
            end

            local function getTradeRemote()
                return game:GetService("ReplicatedStorage"):FindFirstChild("Trade")
            end

            local function openRealTradeGUI()
                tradeGUI = tradeGUI or waitForTradeGUI()
                if not tradeGUI or not tradeGUI:FindFirstChild("Container") then
                    return warn("[MM2 TRADE] TradeGUI.Container not found")
                end

                if tradeGUI:IsA("ScreenGui") then
                    tradeGUI.Enabled = true
                end
                if tradeGUI:FindFirstChild("BG") then
                    tradeGUI.BG.Visible = true
                end
                local container = tradeGUI.Container
                container.Visible = true
                if container:FindFirstChild("Items") then
                    container.Items.Visible = true
                end
                if container:FindFirstChild("Trade") then
                    container.Trade.Visible = true
                end
                if tradeGUI:FindFirstChild("ClickBlocker") then
                    tradeGUI.ClickBlocker.Visible = false
                end

                if tradeModule and tradeModule.UpdateTradeInventory then
                    pcall(function()
                        tradeModule.UpdateTradeInventory()
                    end)
                end

                if refreshLocalTradeInventoryGui then
                    pcall(refreshLocalTradeInventoryGui)
                end
                refreshLocalTradeGui()
                refreshLocalTradeTheirGui()
                setStatus("Trade GUI opened.")
                log("TradeGUI opened successfully!", "SUCCESS")
                return true
            end

            local function updateTradePartnerDisplay(partnerName)
                partnerName = tostring(partnerName or state.tradePartner or (state.currentTradeRequest and state.currentTradeRequest.partner) or "")
                if partnerName == "" then
                    return
                end

                tradeGUI = tradeGUI or waitForTradeGUI()
                if not tradeGUI then
                    return
                end

                local container = safeChild(tradeGUI, "Container")
                local tradeContainer = safeChild(container, "Trade")
                if not tradeContainer then
                    return
                end

                local theirOffer = safeChild(tradeContainer, "TheirOffer") or safeChild(tradeContainer, "OtherOffer") or safeChild(tradeContainer, "OpponentOffer")
                if theirOffer then
                    local title = safeChild(theirOffer, "Title")
                    if title and title:IsA("TextLabel") then
                        title.Text = "THEIR OFFER"
                    end

                    local username = safeChild(theirOffer, "Username")
                    if username and username:IsA("TextLabel") then
                        username.Text = "(" .. partnerName .. ")"
                    end
                end
            end

            local function disconnectLocalRequestButtonConnections()
                for key, conn in pairs(localRequestButtonConnections) do
                    if conn then
                        pcall(function()
                            conn:Disconnect()
                        end)
                    end
                    localRequestButtonConnections[key] = nil
                end
            end

            local function bindLocalRequestAccept()
                if not tradeModule or not tradeModule.GUI then
                    return
                end

                local requestFrame = tradeModule.GUI.RequestFrame
                local receivingRequest = requestFrame and requestFrame.ReceivingRequest
                local acceptButton = receivingRequest and receivingRequest.Accept
                if not (acceptButton and acceptButton:IsA("GuiButton")) then
                    return
                end

                if localRequestButtonConnections.Accept then
                    pcall(function()
                        localRequestButtonConnections.Accept:Disconnect()
                    end)
                    localRequestButtonConnections.Accept = nil
                end

                localRequestButtonConnections.Accept = acceptButton.MouseButton1Click:Connect(function()
                    if state.currentTradeRequest then
                        acceptLocalTradeRequest()
                    else
                        setStatus("No active local Trade Request.", true)
                    end
                end)
            end

            local function openLocalTradeGUI()
                tradeGUI = tradeGUI or waitForTradeGUI()
                if not tradeGUI then
                    return warn("[MM2 TRADE] Local TradeGUI not found")
                end

                if tradeGUI:IsA("ScreenGui") then
                    tradeGUI.Enabled = true
                end
                if tradeGUI:FindFirstChild("BG") then
                    tradeGUI.BG.Visible = true
                end
                if tradeGUI:FindFirstChild("ClickBlocker") then
                    tradeGUI.ClickBlocker.Visible = false
                end
                local container = tradeGUI:FindFirstChild("Container")
                if container then
                    container.Visible = true
                    if container:FindFirstChild("Items") then
                        container.Items.Visible = true
                    end
                    if container:FindFirstChild("Trade") then
                        container.Trade.Visible = true
                    end
                end

                setMainTab("Trade")
                if tradePage then
                    tradePage.Visible = true
                end
                if settingsPage then
                    settingsPage.Visible = false
                end
                if previewFrame then
                    previewFrame.Visible = false
                end
                updateTradePartnerDisplay()
                if refreshLocalTradeInventoryGui then
                    pcall(refreshLocalTradeInventoryGui)
                end
                refreshLocalTradeGui()
                refreshLocalTradeTheirGui()
                setStatus("Local Trade tab opened.")
                return true
            end

            acceptLocalTradeRequest = function()
                if not state.currentTradeRequest then
                    return warn("[MM2 TRADE] No active local Trade Request")
                end

                local partnerName = tostring(state.currentTradeRequest.partner)
                setStatus("Accepting local request from " .. partnerName .. "...")

                local requestFrame = tradeModule and tradeModule.GUI and tradeModule.GUI.RequestFrame
                if requestFrame then
                    requestFrame.Visible = false
                end

                if _G.NewTradeRequest then
                    pcall(_G.NewTradeRequest, false)
                end

                state.tradeActive = true
                state.tradePartner = partnerName
                state.currentTradeRequest = nil

                updateTradePartnerDisplay(partnerName)
                openRealTradeGUI()

                log("Local trade opened for: " .. partnerName, "SUCCESS")
                return true
            end

            local function autoAcceptTradeRequest()
                if state.currentTradeRequest then
                    setStatus("Accepting local request from " .. tostring(state.currentTradeRequest.partner) .. "...")
                    return acceptLocalTradeRequest()
                end

                return warn("[MM2 TRADE] No active local Trade Request")
            end

            local function autoConfirmTrade()
                if not state.tradeActive then
                    return warn("[MM2 TRADE] No active trade")
                end

                setStatus("Confirming trade with " .. tostring(state.tradePartner) .. "...")
                task.wait(cfg.AUTO_CONFIRM_DELAY)

                if tradeRemote and tradeRemote:FindFirstChild("AcceptTrade") then
                    tradeRemote.AcceptTrade:FireServer(game.PlaceId * 3, state.lastOffer)
                    log("AcceptTrade fired to server", "SUCCESS")
                end

                state.tradeActive = false
                state.tradePartner = nil
                setStatus("Trade confirmed.", false)
                return true
            end

            local function handleLocalTradeRequest(senderName)
                if not tradeModule or not tradeGUI then
                    return warn("[MM2 TRADE] Trade system not initialized")
                end

                state.currentTradeRequest = {
                    partner = senderName,
                    timestamp = tick(),
                }

                if tradeModule.UpdateTradeRequestWindow then
                    tradeModule.UpdateTradeRequestWindow("ReceivingRequest", {
                        Sender = { Name = senderName }
                    })
                    log("Trade Request UI updated for: " .. senderName, "SUCCESS")
                end
                disconnectLocalRequestButtonConnections()
                bindLocalRequestAccept()

                setStatus("Simulated request from " .. tostring(senderName) .. ".")
                return true
            end

            local function simulateTradeRequest(senderName)
                return handleLocalTradeRequest(senderName)
            end

            local function hookTradeEvents()
                if not tradeRemote then
                    return
                end

                local startTrade = tradeRemote:FindFirstChild("StartTrade")
                if startTrade then
                    startTrade.OnClientEvent:Connect(function(tradeState, partnerName)
                        log("StartTrade event received from: " .. tostring(partnerName), "INFO")
                        state.tradeActive = true
                        state.tradePartner = partnerName
                        state.currentTradeRequest = nil
                        state.lastOffer = tradeState and tradeState.LastOffer or nil

                        updateTradePartnerDisplay(partnerName)
                        task.wait(0.3)
                        openRealTradeGUI()

                        task.wait(0.2)
                        if tradeModule and tradeModule.UpdateTradeInventory then
                            pcall(function()
                                tradeModule.UpdateTradeInventory()
                            end)
                        end
                        if tradeModule and tradeModule.ConnectTabButtons then
                            pcall(function()
                                tradeModule.ConnectTabButtons()
                            end)
                        end
                        if tradeModule and tradeModule.ConnectOfferButtons then
                            pcall(function()
                                tradeModule.ConnectOfferButtons()
                            end)
                        end

                        setStatus("Trade active with " .. tostring(partnerName) .. ".")
                        log("Trade UI fully initialized!", "SUCCESS")
                    end)
                end

                local updateTrade = tradeRemote:FindFirstChild("UpdateTrade")
                if updateTrade then
                    updateTrade.OnClientEvent:Connect(function(tradeState)
                        if tradeState then
                            state.lastOffer = tradeState.LastOffer
                        end
                    end)
                end

                local declineTrade = tradeRemote:FindFirstChild("DeclineTrade")
                if declineTrade then
                    declineTrade.OnClientEvent:Connect(function()
                        log("Trade declined", "INFO")
                        state.tradeActive = false
                        state.tradePartner = nil
                        state.currentTradeRequest = nil
                        setStatus("Trade declined.", true)
                    end)
                end

                local acceptTrade = tradeRemote:FindFirstChild("AcceptTrade")
                if acceptTrade then
                    acceptTrade.OnClientEvent:Connect(function(success)
                        if success then
                            log("Trade completed successfully!", "SUCCESS")
                            setStatus("Trade completed.")
                        end
                        state.tradeActive = false
                        state.tradePartner = nil
                        state.currentTradeRequest = nil
                    end)
                end
            end

            local function createCard(height)
                local card = Instance.new("Frame")
                card.Size = UDim2.new(1, 0, 0, height)
                card.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
                card.BorderSizePixel = 0
                card.ZIndex = 5
                card.Parent = ui.Panel
                Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)
                local stroke = Instance.new("UIStroke", card)
                stroke.Color = COLORS.Border
                stroke.Thickness = 1
                stroke.Transparency = 0.45
                return card
            end

            local function makeButton(parent, text, sizeX, bg, fg)
                local button = Instance.new("TextButton")
                button.Size = UDim2.new(0, sizeX, 0, 28)
                button.BackgroundColor3 = bg
                button.BorderSizePixel = 0
                button.Text = text
                button.TextColor3 = fg
                button.Font = Enum.Font.GothamBold
                button.TextSize = 11
                button.AutoButtonColor = false
                button.ZIndex = 7
                button.Parent = parent
                Instance.new("UICorner", button).CornerRadius = UDim.new(0, 9)
                local stroke = Instance.new("UIStroke", button)
                stroke.Color = Color3.fromRGB(255, 255, 255)
                stroke.Thickness = 1
                stroke.Transparency = 0.45

                button.MouseEnter:Connect(function()
                    local hoverBg = bg:Lerp(Color3.fromRGB(255, 255, 255), 0.08)
                    TweenService:Create(button, TweenInfo.new(0.12), {BackgroundColor3 = hoverBg}):Play()
                    TweenService:Create(stroke, TweenInfo.new(0.12), {Transparency = 0.15}):Play()
                end)
                button.MouseLeave:Connect(function()
                    TweenService:Create(button, TweenInfo.new(0.12), {BackgroundColor3 = bg}):Play()
                    TweenService:Create(stroke, TweenInfo.new(0.12), {Transparency = 0.45}):Play()
                end)

                return button
            end

            local function buildTradeTheirOfferCard()
                local theirOfferCard = createCard(120)
                theirOfferCard.LayoutOrder = 3

                local theirOfferTitle = Instance.new("TextLabel")
                theirOfferTitle.Size = UDim2.new(1, -28, 0, 18)
                theirOfferTitle.Position = UDim2.new(0, 14, 0, 12)
                theirOfferTitle.BackgroundTransparency = 1
                theirOfferTitle.Text = "Weapon"
                theirOfferTitle.TextColor3 = COLORS.Text
                theirOfferTitle.Font = Enum.Font.GothamBold
                theirOfferTitle.TextSize = 13
                theirOfferTitle.TextXAlignment = Enum.TextXAlignment.Left
                theirOfferTitle.Parent = theirOfferCard

                local theirOfferInput = Instance.new("TextBox")
                theirOfferInput.Size = UDim2.new(1, -28, 0, 32)
                theirOfferInput.Position = UDim2.new(0, 14, 0, 34)
                theirOfferInput.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
                theirOfferInput.BorderSizePixel = 0
                theirOfferInput.Text = ""
                theirOfferInput.PlaceholderText = "Enter weapon name"
                theirOfferInput.PlaceholderColor3 = COLORS.TextDim
                theirOfferInput.TextColor3 = COLORS.Text
                theirOfferInput.Font = Enum.Font.Gotham
                theirOfferInput.TextSize = 12
                theirOfferInput.ClearTextOnFocus = false
                theirOfferInput.Parent = theirOfferCard
                Instance.new("UICorner", theirOfferInput).CornerRadius = UDim.new(0, 9)
                local theirInputStroke = Instance.new("UIStroke", theirOfferInput)
                theirInputStroke.Color = COLORS.Border
                theirInputStroke.Thickness = 1
                theirInputStroke.Transparency = 0.35

                local addTheirBtn = makeButton(theirOfferCard, "ADD WEAPON", 108, Color3.fromRGB(200, 200, 200), Color3.fromRGB(10, 10, 10))
                addTheirBtn.Position = UDim2.new(0, 14, 0, 74)

                local infoLabel = Instance.new("TextLabel")
                infoLabel.Size = UDim2.new(1, -28, 0, 14)
                infoLabel.Position = UDim2.new(0, 14, 1, -18)
                infoLabel.BackgroundTransparency = 1
                infoLabel.Text = "Type a weapon name and press ADD."
                infoLabel.TextColor3 = COLORS.TextDim
                infoLabel.Font = Enum.Font.Gotham
                infoLabel.TextSize = 10
                infoLabel.TextXAlignment = Enum.TextXAlignment.Left
                infoLabel.Parent = theirOfferCard

                local function rebuildTheirOfferCard()
                    -- Intentionally minimal: the field and button stay visible after add.
                end

                shared.MM2RefreshTradeTheirOfferUI = rebuildTheirOfferCard
                rebuildTheirOfferCard()

                addTheirBtn.MouseButton1Click:Connect(function()
                    local raw = (theirOfferInput.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")
                    if raw == "" then
                        setStatus("Enter a weapon name first!", true)
                        return
                    end

                    local catalog = getCatalogItem(raw)
                    local category = catalog and catalog.category or "Weapons"
                    local ok, reason = OfferItemLocalTheir(raw, category)
                    if ok then
                        setStatus("Added to Their Offer: " .. raw)
                    else
                        setStatus(reason == "unknown_item" and "Item not found in catalog." or "Could not add item to Their Offer.", true)
                    end
                end)
            end

            local function buildSettingsPage()
                local oldPanel = ui.Panel
                ui.Panel = settingsContent

                local settingsCard = createCard(198)
                settingsCard.LayoutOrder = 1
                ui.Panel = oldPanel

                local settingsTitle = Instance.new("TextLabel")
                settingsTitle.Size = UDim2.new(1, -28, 0, 18)
                settingsTitle.Position = UDim2.new(0, 14, 0, 12)
                settingsTitle.BackgroundTransparency = 1
                settingsTitle.Text = "Settings"
                settingsTitle.TextColor3 = COLORS.Text
                settingsTitle.Font = Enum.Font.GothamBold
                settingsTitle.TextSize = 13
                settingsTitle.TextXAlignment = Enum.TextXAlignment.Left
                settingsTitle.Parent = settingsCard

                local settingsSub = Instance.new("TextLabel")
                settingsSub.Size = UDim2.new(1, -28, 0, 28)
                settingsSub.Position = UDim2.new(0, 14, 0, 34)
                settingsSub.BackgroundTransparency = 1
                settingsSub.Text = "Adjust the GUI size so Trade and Spawner fit better on screen."
                settingsSub.TextColor3 = COLORS.TextSub
                settingsSub.Font = Enum.Font.Gotham
                settingsSub.TextSize = 11
                settingsSub.TextWrapped = true
                settingsSub.TextXAlignment = Enum.TextXAlignment.Left
                settingsSub.Parent = settingsCard

                local sizeValue = Instance.new("TextLabel")
                sizeValue.Size = UDim2.new(1, -28, 0, 18)
                sizeValue.Position = UDim2.new(0, 14, 0, 68)
                sizeValue.BackgroundTransparency = 1
                sizeValue.TextColor3 = COLORS.Text
                sizeValue.Font = Enum.Font.GothamBold
                sizeValue.TextSize = 12
                sizeValue.TextXAlignment = Enum.TextXAlignment.Left
                sizeValue.Parent = settingsCard

                local sizeTrack = Instance.new("Frame")
                sizeTrack.Size = UDim2.new(1, -28, 0, 12)
                sizeTrack.Position = UDim2.new(0, 14, 0, 96)
                sizeTrack.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
                sizeTrack.BorderSizePixel = 0
                sizeTrack.Active = true
                sizeTrack.Parent = settingsCard
                Instance.new("UICorner", sizeTrack).CornerRadius = UDim.new(1, 0)
                local sizeTrackStroke = Instance.new("UIStroke", sizeTrack)
                sizeTrackStroke.Color = COLORS.Border
                sizeTrackStroke.Thickness = 1
                sizeTrackStroke.Transparency = 0.35

                local sizeFill = Instance.new("Frame")
                sizeFill.Size = UDim2.new(0.5, 0, 1, 0)
                sizeFill.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
                sizeFill.BorderSizePixel = 0
                sizeFill.Parent = sizeTrack
                Instance.new("UICorner", sizeFill).CornerRadius = UDim.new(1, 0)

                local sizeKnob = Instance.new("Frame")
                sizeKnob.Size = UDim2.new(0, 16, 0, 16)
                sizeKnob.Position = UDim2.new(0.5, -8, 0.5, -8)
                sizeKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                sizeKnob.BorderSizePixel = 0
                sizeKnob.Parent = sizeTrack
                Instance.new("UICorner", sizeKnob).CornerRadius = UDim.new(1, 0)
                local sizeKnobStroke = Instance.new("UIStroke", sizeKnob)
                sizeKnobStroke.Color = Color3.fromRGB(20, 20, 20)
                sizeKnobStroke.Thickness = 1
                sizeKnobStroke.Transparency = 0.15

                local presetRow = Instance.new("Frame")
                presetRow.Size = UDim2.new(1, -28, 0, 28)
                presetRow.Position = UDim2.new(0, 14, 0, 124)
                presetRow.BackgroundTransparency = 1
                presetRow.Parent = settingsCard

                local presetLayout = Instance.new("UIListLayout", presetRow)
                presetLayout.FillDirection = Enum.FillDirection.Horizontal
                presetLayout.Padding = UDim.new(0, 8)
                presetLayout.SortOrder = Enum.SortOrder.LayoutOrder

                local smallBtn = makeButton(presetRow, "100%", 56, Color3.fromRGB(24, 24, 24), COLORS.Text)
                local normalBtn = makeButton(presetRow, "112%", 56, Color3.fromRGB(200, 200, 200), Color3.fromRGB(10, 10, 10))
                local largeBtn = makeButton(presetRow, "125%", 56, Color3.fromRGB(24, 24, 24), COLORS.Text)
                local hugeBtn = makeButton(presetRow, "135%", 56, Color3.fromRGB(24, 24, 24), COLORS.Text)

                local minScale = 1
                local maxScale = 1.35
                local dragging = false

                local function updateSettingsUi()
                    local mainW, mainH = getScaledGuiMetrics(guiScale)
                    local pct = math.floor(guiScale * 100 + 0.5)
                    local alpha = (guiScale - minScale) / (maxScale - minScale)
                    if alpha < 0 then alpha = 0 end
                    if alpha > 1 then alpha = 1 end

                    sizeValue.Text = string.format("Window Size: %d%%  |  %dx%d", pct, mainW, mainH)
                    sizeFill.Size = UDim2.new(alpha, 0, 1, 0)
                    sizeKnob.Position = UDim2.new(alpha, -8, 0.5, -8)
                end

                local function setScale(value)
                    value = math.clamp(tonumber(value) or guiScale, minScale, maxScale)
                    applyGuiScale(value)
                    updateSettingsUi()
                end

                local function scaleFromInput(inputX)
                    local left = sizeTrack.AbsolutePosition.X
                    local width = sizeTrack.AbsoluteSize.X
                    if width <= 0 then
                        return
                    end

                    local alpha = (inputX - left) / width
                    setScale(minScale + (maxScale - minScale) * alpha)
                end

                sizeTrack.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        scaleFromInput(input.Position.X)
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        scaleFromInput(input.Position.X)
                    end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                    end
                end)

                smallBtn.MouseButton1Click:Connect(function()
                    setScale(1)
                end)
                normalBtn.MouseButton1Click:Connect(function()
                    setScale(1.12)
                end)
                largeBtn.MouseButton1Click:Connect(function()
                    setScale(1.25)
                end)
                hugeBtn.MouseButton1Click:Connect(function()
                    setScale(1.35)
                end)

                local keybindCard = createCard(164)
                keybindCard.LayoutOrder = 2

                local keybindTitle = Instance.new("TextLabel")
                keybindTitle.Size = UDim2.new(1, -28, 0, 18)
                keybindTitle.Position = UDim2.new(0, 14, 0, 12)
                keybindTitle.BackgroundTransparency = 1
                keybindTitle.Text = "Keybinds"
                keybindTitle.TextColor3 = COLORS.Text
                keybindTitle.Font = Enum.Font.GothamBold
                keybindTitle.TextSize = 13
                keybindTitle.TextXAlignment = Enum.TextXAlignment.Left
                keybindTitle.Parent = keybindCard

                local keybindSub = Instance.new("TextLabel")
                keybindSub.Size = UDim2.new(1, -28, 0, 28)
                keybindSub.Position = UDim2.new(0, 14, 0, 34)
                keybindSub.BackgroundTransparency = 1
                keybindSub.Text = "F6 sends a local TradeRequest to a server player. F7 adds rich items from your inventory."
                keybindSub.TextColor3 = COLORS.TextSub
                keybindSub.Font = Enum.Font.Gotham
                keybindSub.TextSize = 11
                keybindSub.TextWrapped = true
                keybindSub.TextXAlignment = Enum.TextXAlignment.Left
                keybindSub.Parent = keybindCard

                local keybindRows = Instance.new("Frame")
                keybindRows.Size = UDim2.new(1, -28, 0, 56)
                keybindRows.Position = UDim2.new(0, 14, 0, 70)
                keybindRows.BackgroundTransparency = 1
                keybindRows.Parent = keybindCard

                local keybindLayout = Instance.new("UIListLayout", keybindRows)
                keybindLayout.Padding = UDim.new(0, 8)
                keybindLayout.SortOrder = Enum.SortOrder.LayoutOrder

                local function makeKeyRow(labelText)
                    local row = Instance.new("Frame")
                    row.Size = UDim2.new(1, 0, 0, 24)
                    row.BackgroundTransparency = 1
                    row.Parent = keybindRows

                    local lbl = Instance.new("TextLabel")
                    lbl.Size = UDim2.new(1, -78, 1, 0)
                    lbl.BackgroundTransparency = 1
                    lbl.Text = labelText
                    lbl.TextColor3 = COLORS.Text
                    lbl.Font = Enum.Font.GothamMedium
                    lbl.TextSize = 12
                    lbl.TextXAlignment = Enum.TextXAlignment.Left
                    lbl.Parent = row

                    local btn = makeButton(row, "F6", 72, Color3.fromRGB(200, 200, 200), Color3.fromRGB(10, 10, 10))
                    btn.Size = UDim2.new(0, 72, 1, 0)
                    btn.Position = UDim2.new(1, -72, 0, 0)
                    return btn
                end

                local requestKeyBtn = makeKeyRow("Send local request")
                local richKeyBtn = makeKeyRow("Add rich items")

                local keybindStatus = Instance.new("TextLabel")
                keybindStatus.Size = UDim2.new(1, -28, 0, 18)
                keybindStatus.Position = UDim2.new(0, 14, 0, 130)
                keybindStatus.BackgroundTransparency = 1
                keybindStatus.Text = ""
                keybindStatus.TextColor3 = COLORS.TextSub
                keybindStatus.Font = Enum.Font.Gotham
                keybindStatus.TextSize = 11
                keybindStatus.TextXAlignment = Enum.TextXAlignment.Left
                keybindStatus.Parent = keybindCard

                local richPreset = {
                    "Gingerscope",
                    "BaubleChroma",
                    "Harvester",
                    "ConstellationChroma",
                    "Constellation",
                    "Icepiercer",
                    "TravelerGunChroma",
                    "TravelerAxeChroma",
                    "TreeGun2023Chroma",
                    "TreeKnife2023Chroma",
                    "WatergunChroma",
                    "UFOKnifeChroma",
                    "RaygunChroma",
                    "SunsetGunChroma",
                    "SnowstormChroma",
                    "SunsetKnifeChroma",
                    "SnowDaggerChroma",
                    "TreatChroma",
                    "BlizzardChroma",
                    "HeartWandChroma",
                    "SweetChroma",    
                    "TreeGun2023Chroma",
                    "TreeKnife2023Chroma",
                        
                }

                local function keyName(keyCode)
                    if typeof(keyCode) == "EnumItem" and keyCode.EnumType == Enum.KeyCode then
                        return keyCode.Name
                    end
                    return "None"
                end

                local function updateKeybindUi()
                    requestKeyBtn.Text = keyName(cfg.REQUEST_KEYBIND)
                    richKeyBtn.Text = keyName(cfg.RICH_ITEMS_KEYBIND)

                    if settingsKeybindCapture == "Request" then
                        keybindStatus.Text = "Press a key for request bind..."
                    elseif settingsKeybindCapture == "Rich" then
                        keybindStatus.Text = "Press a key for rich-items bind..."
                    else
                        keybindStatus.Text = "Click a key button to rebind it."
                    end
                end

                local function resolveRequestTarget()
                    local wanted = tostring(cfg.PARTNER_NAME or ""):match("^%s*(.-)%s*$")
                    local players = game:GetService("Players"):GetPlayers()

                    if wanted ~= "" then
                        for _, plr in ipairs(players) do
                            if plr ~= player and plr.Name:lower() == wanted:lower() then
                                return plr.Name
                            end
                        end
                        for _, plr in ipairs(players) do
                            if plr ~= player and plr.DisplayName and plr.DisplayName:lower() == wanted:lower() then
                                return plr.Name
                            end
                        end
                    end

                    for _, plr in ipairs(players) do
                        if plr ~= player then
                            return plr.Name
                        end
                    end
                    return nil
                end

                local function triggerRequestKeybind()
                    local target = resolveRequestTarget()
                    if not target then
                        setStatus("No other players found.", true)
                        keybindStatus.Text = "No server player found."
                        return
                    end

                    cfg.PARTNER_NAME = target
                    if ui.PartnerInput then
                        ui.PartnerInput.Text = target
                    end

                    simulateTradeRequest(target)
                    keybindStatus.Text = "Sent local request to " .. target
                end

                local function triggerRichItemsKeybind()
                    local added = 0
                    for _, itemName in ipairs(richPreset) do
                        local item = getCatalogItem(itemName)
                        if item then
                            local ok = OfferOwnedItemLocal(item.original, item.category or "Weapons")
                            if ok then
                                added += 1
                            end
                        end
                    end

                    if added > 0 then
                        keybindStatus.Text = "Added " .. tostring(added) .. " rich items."
                    else
                        keybindStatus.Text = "No rich items owned."
                    end
                endо

                requestKeyBtn.MouseButton1Click:Connect(function()
                    settingsKeybindCapture = "Request"
                    updateKeybindUi()
                end)

                richKeyBtn.MouseButton1Click:Connect(function()
                    settingsKeybindCapture = "Rich"
                    updateKeybindUi()
                end)

                if not ui.SettingsKeybindInputConnection then
                    ui.SettingsKeybindInputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                        if input.UserInputType ~= Enum.UserInputType.Keyboard then
                            return
                        end

                        if settingsKeybindCapture then
                            if input.KeyCode ~= Enum.KeyCode.Unknown then
                                if settingsKeybindCapture == "Request" then
                                    cfg.REQUEST_KEYBIND = input.KeyCode
                                elseif settingsKeybindCapture == "Rich" then
                                    cfg.RICH_ITEMS_KEYBIND = input.KeyCode
                                end
                                settingsKeybindCapture = nil
                                updateKeybindUi()
                            end
                            return
                        end

                        if gameProcessed then
                            return
                        end

                        if input.KeyCode == cfg.REQUEST_KEYBIND then
                            triggerRequestKeybind()
                        elseif input.KeyCode == cfg.RICH_ITEMS_KEYBIND then
                            triggerRichItemsKeybind()
                        end
                    end)
                end

                updateSettingsUi()
            end

            local panel = Instance.new("ScrollingFrame")
            panel.Name = "TradePanel"
            panel.Size = UDim2.new(1, -24, 1, -64)
            panel.Position = UDim2.new(0, 12, 0, 54)
            panel.BackgroundTransparency = 1
            panel.BorderSizePixel = 0
            panel.ScrollBarThickness = 4
            panel.ScrollBarImageColor3 = Color3.fromRGB(180, 180, 180)
            panel.CanvasSize = UDim2.new(0, 0, 0, 0)
            panel.ScrollingDirection = Enum.ScrollingDirection.Y
            panel.ZIndex = 5
            panel.Parent = tradeContent
            ui.Panel = panel

            local panelPad = Instance.new("UIPadding", panel)
            panelPad.PaddingTop = UDim.new(0, 10)
            panelPad.PaddingBottom = UDim.new(0, 10)
            panelPad.PaddingLeft = UDim.new(0, 10)
            panelPad.PaddingRight = UDim.new(0, 10)

            local panelLayout = Instance.new("UIListLayout", panel)
            panelLayout.Padding = UDim.new(0, 10)
            panelLayout.SortOrder = Enum.SortOrder.LayoutOrder
            panelLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                panel.CanvasSize = UDim2.new(0, 0, 0, panelLayout.AbsoluteContentSize.Y + 16)
            end)
            task.defer(function()
                panel.CanvasSize = UDim2.new(0, 0, 0, panelLayout.AbsoluteContentSize.Y + 16)
            end)

            local function buildTradeOverviewAndControls()
                local statusCard = createCard(62)
                statusCard.LayoutOrder = 1
                statusCard.Visible = false

                local statusText = Instance.new("TextLabel")
                statusText.Size = UDim2.new(1, -28, 0, 16)
                statusText.Position = UDim2.new(0, 14, 0, 18)
                statusText.BackgroundTransparency = 1
                statusText.Text = "Idle"
                statusText.TextColor3 = COLORS.Text
                statusText.Font = Enum.Font.Gotham
                statusText.TextSize = 11
                statusText.TextXAlignment = Enum.TextXAlignment.Left
                statusText.Parent = statusCard
                ui.StatusText = statusText

                local statusPill = Instance.new("TextLabel")
                statusPill.Size = UDim2.new(0, 76, 0, 20)
                statusPill.Position = UDim2.new(1, -90, 0, 16)
                statusPill.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
                statusPill.BorderSizePixel = 0
                statusPill.Text = "READY"
                statusPill.TextColor3 = Color3.fromRGB(255, 255, 255)
                statusPill.Font = Enum.Font.GothamBold
                statusPill.TextSize = 10
                statusPill.Parent = statusCard
                Instance.new("UICorner", statusPill).CornerRadius = UDim.new(0, 8)
                local statusStroke = Instance.new("UIStroke", statusPill)
                statusStroke.Color = Color3.fromRGB(200, 200, 200)
                statusStroke.Thickness = 1
                statusStroke.Transparency = 0.35
                ui.StatusPill = statusPill

                local requestCard = createCard(118)
                requestCard.LayoutOrder = 2

                local requestTitle = Instance.new("TextLabel")
                requestTitle.Size = UDim2.new(1, -28, 0, 18)
                requestTitle.Position = UDim2.new(0, 14, 0, 12)
                requestTitle.BackgroundTransparency = 1
                requestTitle.Text = "Partner"
                requestTitle.TextColor3 = COLORS.Text
                requestTitle.Font = Enum.Font.GothamBold
                requestTitle.TextSize = 13
                requestTitle.TextXAlignment = Enum.TextXAlignment.Left
                requestTitle.Parent = requestCard

                local partnerBox = Instance.new("TextBox")
                partnerBox.Size = UDim2.new(1, -28, 0, 32)
                partnerBox.Position = UDim2.new(0, 14, 0, 34)
                partnerBox.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
                partnerBox.BorderSizePixel = 0
                partnerBox.Text = cfg.PARTNER_NAME
                partnerBox.PlaceholderText = "Enter player name"
                partnerBox.PlaceholderColor3 = COLORS.TextDim
                partnerBox.TextColor3 = COLORS.Text
                partnerBox.Font = Enum.Font.Gotham
                partnerBox.TextSize = 12
                partnerBox.ClearTextOnFocus = false
                partnerBox.Parent = requestCard
                Instance.new("UICorner", partnerBox).CornerRadius = UDim.new(0, 9)
                local partnerStroke = Instance.new("UIStroke", partnerBox)
                partnerStroke.Color = COLORS.Border
                partnerStroke.Thickness = 1
                partnerStroke.Transparency = 0.35
                ui.PartnerInput = partnerBox

                local requestButtons = Instance.new("Frame")
                requestButtons.Size = UDim2.new(1, -28, 0, 28)
                requestButtons.Position = UDim2.new(0, 14, 0, 76)
                requestButtons.BackgroundTransparency = 1
                requestButtons.Parent = requestCard

                local requestLayout = Instance.new("UIListLayout", requestButtons)
                requestLayout.FillDirection = Enum.FillDirection.Horizontal
                requestLayout.Padding = UDim.new(0, 8)
                requestLayout.SortOrder = Enum.SortOrder.LayoutOrder

                local randomBtn = makeButton(requestButtons, "Random Nick", 108, Color3.fromRGB(34, 34, 34), COLORS.Text)
                local simulateBtn = makeButton(requestButtons, "Send Request", 112, Color3.fromRGB(200, 200, 200), Color3.fromRGB(10, 10, 10))

                randomBtn.MouseButton1Click:Connect(function()
                    partnerBox.Text = getRandomName()
                    cfg.PARTNER_NAME = partnerBox.Text
                    setStatus("Random name generated.")
                end)

                simulateBtn.MouseButton1Click:Connect(function()
                    cfg.PARTNER_NAME = partnerBox.Text
                    simulateTradeRequest(cfg.PARTNER_NAME)
                end)
            end

            buildTradeOverviewAndControls()
            buildTradeTheirOfferCard()
            buildSettingsPage()

            RunService.Heartbeat:Connect(function()
                local requestStatus = state.currentTradeRequest and ("Active - " .. tostring(state.currentTradeRequest.partner)) or "None"
                local tradeStatus = state.tradeActive and "Active" or "Inactive"
                local partner = state.tradePartner or "None"

                if ui.StatusText then
                    ui.StatusText.Text = "Request: " .. requestStatus .. " | Trade: " .. tradeStatus .. " | Partner: " .. partner
                end
                if ui.StatusPill then
                    if state.tradeActive then
                        ui.StatusPill.Text = "ACTIVE"
                    elseif state.currentTradeRequest then
                        ui.StatusPill.Text = "REQUEST"
                    else
                        ui.StatusPill.Text = "READY"
                    end
                end
            end)

            local function initTrade()
                pcall(function()
                    setthreadidentity(2)
                end)

                tradeModule = waitForTradeModule()
                if not tradeModule then
                    setStatus("TradeModule not found.", true)
                    return false
                end

                tradeGUI = waitForTradeGUI()
                if not tradeGUI then
                    setStatus("TradeGUI not found.", true)
                    return false
                end

                tradeRemote = getTradeRemote()
                if not tradeRemote then
                    setStatus("Trade remotes not found.", true)
                    return false
                end

                setStatus("Trade system ready.")
                log("System initialized successfully!", "SUCCESS")
                hookTradeEvents()
                return true
            end

            T.GetRandomName = getRandomName
            T.SimulateTradeRequest = simulateTradeRequest
            T.AutoAcceptTradeRequest = autoAcceptTradeRequest
            T.AutoConfirmTrade = autoConfirmTrade
            T.OpenRealTradeGUI = openRealTradeGUI
            T.OpenLocalTradeGUI = openLocalTradeGUI
            T.HandleLocalTradeRequest = handleLocalTradeRequest
            T.OfferItemLocalTheir = OfferItemLocalTheir
            T.ClearLocalTradeTheir = ClearLocalTradeTheir
            T.RefreshTradeOffers = shared.MM2RefreshTradeOffers
            T.OpenTradeTab = function()
                openLocalTradeGUI()
                searchOuter.Visible = false
                countLabel.Visible = false
                scrollFrame.Visible = false
                spawnBtn.Visible = false
                ownedAddBtn.Visible = false
            end

            _G.MM2TradeSimulate = simulateTradeRequest
            _G.MM2TradeAccept = autoAcceptTradeRequest
            _G.MM2TradeConfirm = autoConfirmTrade
            _G.MM2TradeOpenTradeGUI = openRealTradeGUI
            _G.MM2TradeOpenLocalTradeGUI = openLocalTradeGUI
            _G.MM2TradeHandleLocalRequest = handleLocalTradeRequest
            _G.MM2TradeOfferTheir = OfferItemLocalTheir
            _G.MM2TradeClearTheir = ClearLocalTradeTheir
            _G.MM2RefreshTradeOffers = shared.MM2RefreshTradeOffers

            task.spawn(function()
                initTrade()
            end)
        end

        local activeTab = "Spawner"
        local tabButtons = {}

        local function styleTabButton(btn, active)
            if not btn then
                return
            end

            if active then
                btn.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
                btn.TextColor3 = Color3.fromRGB(10, 10, 10)
            else
                btn.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
                btn.TextColor3 = COLORS.Text
            end

            local stroke = btn:FindFirstChildOfClass("UIStroke")
            if stroke then
                stroke.Color = active and Color3.fromRGB(255, 255, 255) or COLORS.Border
                stroke.Transparency = active and 0.25 or 0.45
            end
        end

        setMainTab = function(tabName)
            activeTab = tabName
            local spawnerVisible = tabName == "Spawner"
            local tradeVisible = tabName == "Trade"
            local settingsVisible = tabName == "Settings"

            searchOuter.Visible = spawnerVisible
            countLabel.Visible = spawnerVisible
            scrollFrame.Visible = spawnerVisible
            spawnBtn.Visible = spawnerVisible
            ownedAddBtn.Visible = spawnerVisible
            progressBG.Visible = false
            tradePage.Visible = tradeVisible
            settingsPage.Visible = settingsVisible

            if previewFrame then
                previewFrame.Visible = false
            end

            if tradeVisible then
                if shared.MM2RefreshTradeInventory then
                    pcall(shared.MM2RefreshTradeInventory)
                end
                if shared.MM2RefreshTradeOffers then
                    pcall(shared.MM2RefreshTradeOffers)
                end
            elseif settingsVisible and shared.MM2ApplyGuiScale then
                pcall(shared.MM2ApplyGuiScale, guiScale)
            end

            styleTabButton(tabButtons.Spawner, spawnerVisible)
            styleTabButton(tabButtons.Trade, tradeVisible)
            styleTabButton(tabButtons.Settings, settingsVisible)
        end

        local spawnerTab = Instance.new("TextButton")
        spawnerTab.Size = UDim2.new(0, 74, 0, 24)
        spawnerTab.Position = UDim2.new(0, 102, 0, 38)
        spawnerTab.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
        spawnerTab.Text = "Spawner"
        spawnerTab.TextColor3 = Color3.fromRGB(10, 10, 10)
        spawnerTab.Font = Enum.Font.GothamBold
        spawnerTab.TextSize = 11
        spawnerTab.BorderSizePixel = 0
        spawnerTab.AutoButtonColor = false
        spawnerTab.ZIndex = 7
        spawnerTab.Parent = header
        Instance.new("UICorner", spawnerTab).CornerRadius = UDim.new(0, 8)
        local spawnerTabStroke = Instance.new("UIStroke", spawnerTab)
        spawnerTabStroke.Color = Color3.fromRGB(255, 255, 255)
        spawnerTabStroke.Thickness = 1
        spawnerTabStroke.Transparency = 0.25
        tabButtons.Spawner = spawnerTab

        local tradeTab = Instance.new("TextButton")
        tradeTab.Size = UDim2.new(0, 58, 0, 24)
        tradeTab.Position = UDim2.new(0, 182, 0, 38)
        tradeTab.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
        tradeTab.Text = "Trade"
        tradeTab.TextColor3 = COLORS.Text
        tradeTab.Font = Enum.Font.GothamBold
        tradeTab.TextSize = 11
        tradeTab.BorderSizePixel = 0
        tradeTab.AutoButtonColor = false
        tradeTab.ZIndex = 7
        tradeTab.Parent = header
        Instance.new("UICorner", tradeTab).CornerRadius = UDim.new(0, 8)
        local tradeTabStroke = Instance.new("UIStroke", tradeTab)
        tradeTabStroke.Color = COLORS.Border
        tradeTabStroke.Thickness = 1
        tradeTabStroke.Transparency = 0.45
        tabButtons.Trade = tradeTab

        local settingsTab = Instance.new("TextButton")
        settingsTab.Size = UDim2.new(0, 74, 0, 24)
        settingsTab.Position = UDim2.new(0, 246, 0, 38)
        settingsTab.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
        settingsTab.Text = "Settings"
        settingsTab.TextColor3 = COLORS.Text
        settingsTab.Font = Enum.Font.GothamBold
        settingsTab.TextSize = 10
        settingsTab.BorderSizePixel = 0
        settingsTab.AutoButtonColor = false
        settingsTab.ZIndex = 7
        settingsTab.Parent = header
        Instance.new("UICorner", settingsTab).CornerRadius = UDim.new(0, 8)
        local settingsTabStroke = Instance.new("UIStroke", settingsTab)
        settingsTabStroke.Color = COLORS.Border
        settingsTabStroke.Thickness = 1
        settingsTabStroke.Transparency = 0.45
        tabButtons.Settings = settingsTab

        spawnerTab.MouseButton1Click:Connect(function()
            setMainTab("Spawner")
        end)

        tradeTab.MouseButton1Click:Connect(function()
            setMainTab("Trade")
        end)

        settingsTab.MouseButton1Click:Connect(function()
            setMainTab("Settings")
        end)

        spawnerTab.MouseEnter:Connect(function()
            if activeTab == "Spawner" then
                tween(spawnerTab, 0.12, {Size = UDim2.new(0, 80, 0, 25)}):Play()
            else
                tween(spawnerTab, 0.12, {BackgroundColor3 = Color3.fromRGB(34, 34, 34), Size = UDim2.new(0, 80, 0, 25)}):Play()
            end
        end)
        spawnerTab.MouseLeave:Connect(function()
            tween(spawnerTab, 0.12, {Size = UDim2.new(0, 74, 0, 24)}):Play()
            if activeTab ~= "Spawner" then
                tween(spawnerTab, 0.12, {BackgroundColor3 = Color3.fromRGB(24, 24, 24)}):Play()
            end
        end)

        tradeTab.MouseEnter:Connect(function()
            if activeTab == "Trade" then
                tween(tradeTab, 0.12, {Size = UDim2.new(0, 60, 0, 25)}):Play()
            else
                tween(tradeTab, 0.12, {BackgroundColor3 = Color3.fromRGB(34, 34, 34), Size = UDim2.new(0, 60, 0, 25)}):Play()
            end
        end)
        tradeTab.MouseLeave:Connect(function()
            tween(tradeTab, 0.12, {Size = UDim2.new(0, 58, 0, 24)}):Play()
            if activeTab ~= "Trade" then
                tween(tradeTab, 0.12, {BackgroundColor3 = Color3.fromRGB(24, 24, 24)}):Play()
            end
        end)

        settingsTab.MouseEnter:Connect(function()
            if activeTab == "Settings" then
                tween(settingsTab, 0.12, {Size = UDim2.new(0, 76, 0, 25)}):Play()
            else
                tween(settingsTab, 0.12, {BackgroundColor3 = Color3.fromRGB(34, 34, 34), Size = UDim2.new(0, 76, 0, 25)}):Play()
            end
        end)
        settingsTab.MouseLeave:Connect(function()
            tween(settingsTab, 0.12, {Size = UDim2.new(0, 74, 0, 24)}):Play()
            if activeTab ~= "Settings" then
                tween(settingsTab, 0.12, {BackgroundColor3 = Color3.fromRGB(24, 24, 24)}):Play()
            end
        end)

        setMainTab("Spawner")

        -- Main GUI idle animation


        task.spawn(function()
            local t = 0
            while screenGui.Parent do
                t += 0.03
                orb1.BackgroundTransparency = 0.94 + math.sin(t * 0.8) * 0.03
                orb2.BackgroundTransparency = 0.95 + math.cos(t * 0.6) * 0.03
                orb3.BackgroundTransparency = 0.96 + math.sin(t * 1.1) * 0.02
                if outerGlow.Visible then
                    outerGlow.BackgroundTransparency = 0.92 + math.sin(t * 1.4) * 0.03
                end
                iconGradient.Rotation = (iconGradient.Rotation + 0.4) % 360
                task.wait(0.04)
            end
        end)

        task.spawn(function()
            while screenGui.Parent do
                tween(neonLine, 1.3, {Size = UDim2.new(0, 88, 0, 2)}, Enum.EasingStyle.Sine):Play()
                task.wait(1.3)
                tween(neonLine, 1.3, {Size = UDim2.new(0, 38, 0, 2)}, Enum.EasingStyle.Sine):Play()
                task.wait(1.3)
            end
        end)

        filterItems("")

        -- Loader progress steps


        local loadingSteps = {
            {text = "Loading modules...",      pct = 15},
            {text = "Connecting to server...", pct = 32},
            {text = "Fetching item list...",   pct = 55},
            {text = "Building interface...",   pct = 74},
            {text = "Applying monochrome theme...", pct = 90},
            {text = "Ready!",                  pct = 100},
        }

        task.spawn(function()
            task.wait(0.15)

            for stepIdx, step in ipairs(loadingSteps) do
                local startPct = stepIdx == 1 and 0 or loadingSteps[stepIdx-1].pct
                local endPct   = step.pct
                local duration = stepIdx == #loadingSteps and 0.35 or 0.52

                loaderStatus.Text = step.text

                local t0 = tick()
                while tick() - t0 < duration do
                    local p = (tick() - t0) / duration
                    p = p * p * (3 - 2 * p)
                    local cur = startPct + (endPct - startPct) * p
                    tween(loaderFill, 0.06, {Size = UDim2.new(cur/100, 0, 1, 0)}):Play()
                    loaderPct.Text = math.floor(cur) .. "%"
                    task.wait(0.04)
                end
                tween(loaderFill, 0.08, {Size = UDim2.new(endPct/100, 0, 1, 0)}):Play()
                loaderPct.Text = endPct .. "%"

                if stepIdx < #loadingSteps then task.wait(0.15) end
            end

            task.wait(0.3)

            tween(loaderFill, 0.12, {BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
            task.wait(0.18)

            tween(loaderCenter, 0.35, {
                Size = UDim2.new(0, 320, 0, 0),
                Position = UDim2.new(0.5, -160, 0.5, 0),
            }, Enum.EasingStyle.Back, Enum.EasingDirection.In):Play()
            tween(cardGlow, 0.35, {BackgroundTransparency = 1}):Play()
            tween(bgGlow,   0.35, {BackgroundTransparency = 1}):Play()
            task.wait(0.38)

            tween(loaderFrame, 0.3, {BackgroundTransparency = 1}):Play()
            for _, child in pairs(loaderFrame:GetDescendants()) do
                if child:IsA("Frame") or child:IsA("TextLabel") then
                    pcall(function()
                        tween(child, 0.2, {BackgroundTransparency = 1, TextTransparency = 1}):Play()
                    end)
                end
            end
            task.wait(0.32)

            loaderGui.Enabled = false
            openGUI()
        end)
