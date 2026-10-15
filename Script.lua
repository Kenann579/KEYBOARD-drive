local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "CarKeys"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 100
gui.Parent = player:WaitForChild("PlayerGui")

-- Other scripts can listen to this: event.Event:Connect(function(key, down) end)
local event = Instance.new("BindableEvent")
event.Name = "VirtualKey"
event.Parent = gui

local state = {}
local buttons = {}
local ACCENT = Color3.fromRGB(0, 220, 255)
local BASE = Color3.fromRGB(18, 20, 30)

local function setKey(name, down)
	if state[name] == down then return end
	state[name] = down
	gui:SetAttribute(name, down)
	event:Fire(name, down)
	local b = buttons[name]
	if b then
		b.BackgroundColor3 = down and ACCENT or BASE
		b.TextColor3 = down and BASE or ACCENT
	end
end

-- Panel
local panel = Instance.new("Frame")
panel.Size = UDim2.fromScale(1, 1)
panel.BackgroundTransparency = 1
panel.Parent = gui

local SIZE = 64
local GAP = 10
local STEP = SIZE + GAP

local function makeKey(name, anchor, pos)
	local b = Instance.new("TextButton")
	b.Name = name
	b.Text = name
	b.Font = Enum.Font.GothamBold
	b.TextSize = 24
	b.TextColor3 = ACCENT
	b.BackgroundColor3 = BASE
	b.BackgroundTransparency = 0.15
	b.AutoButtonColor = false
	b.Active = true
	b.Size = UDim2.fromOffset(SIZE, SIZE)
	b.AnchorPoint = anchor
	b.Position = pos
	b.Parent = panel

	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 14)
	local stroke = Instance.new("UIStroke")
	stroke.Color = ACCENT
	stroke.Thickness = 2
	stroke.Parent = b

	buttons[name] = b

	b.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1 then
			setKey(name, true)
			local conn
			conn = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					conn:Disconnect()
					setKey(name, false)
				end
			end)
		end
	end)
end

local L, R = Vector2.new(0, 1), Vector2.new(1, 1)

-- Left side: steering + Q/E
makeKey("A", L, UDim2.new(0, 20, 1, -20))
makeKey("D", L, UDim2.new(0, 20 + STEP, 1, -20))
makeKey("Q", L, UDim2.new(0, 20, 1, -20 - STEP))
makeKey("E", L, UDim2.new(0, 20 + STEP, 1, -20 - STEP))

-- Right side: gas/brake + Z X C
makeKey("S", R, UDim2.new(1, -20, 1, -20))
makeKey("W", R, UDim2.new(1, -20, 1, -20 - STEP))
makeKey("C", R, UDim2.new(1, -20 - STEP, 1, -20))
makeKey("X", R, UDim2.new(1, -20 - STEP * 2, 1, -20))
makeKey("Z", R, UDim2.new(1, -20 - STEP * 3, 1, -20))

-- M toggle button (tap = toggle, drag = move)
local m = Instance.new("TextButton")
m.Name = "M"
m.Text = "M"
m.Font = Enum.Font.GothamBold
m.TextSize = 22
m.TextColor3 = ACCENT
m.BackgroundColor3 = BASE
m.BackgroundTransparency = 0.15
m.AutoButtonColor = false
m.Active = true
m.Size = UDim2.fromOffset(52, 52)
m.Position = UDim2.fromOffset(20, 90)
m.Parent = gui
Instance.new("UICorner", m).CornerRadius = UDim.new(1, 0)
local ms = Instance.new("UIStroke")
ms.Color = ACCENT
ms.Thickness = 2
ms.Parent = m

local function setVisible(v)
	panel.Visible = v
	if not v then
		for name in pairs(buttons) do setKey(name, false) end
	end
end

local dragInput, startInputPos, startBtnPos, moved
m.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragInput = input
		startInputPos = input.Position
		startBtnPos = m.AbsolutePosition
		moved = false
		local conn
		conn = input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				conn:Disconnect()
				if dragInput == input then
					dragInput = nil
					if not moved then setVisible(not panel.Visible) end
				end
			end
		end)
	end
end)

UIS.InputChanged:Connect(function(input)
	if not dragInput then return end
	local isDrag = input == dragInput
		or (dragInput.UserInputType == Enum.UserInputType.MouseButton1
			and input.UserInputType == Enum.UserInputType.MouseMovement)
	if not isDrag then return end

	local d = input.Position - startInputPos
	if d.Magnitude > 10 then moved = true end
	if moved then
		local screen = gui.AbsoluteSize
		local x = math.clamp(startBtnPos.X + d.X, 0, screen.X - m.AbsoluteSize.X)
		local y = math.clamp(startBtnPos.Y + d.Y, 0, screen.Y - m.AbsoluteSize.Y)
		m.Position = UDim2.fromOffset(x, y)
	end
end)

-- Drives VehicleSeat cars (only overrides while a key is held)
RunService:BindToRenderStep("CarKeysDrive", Enum.RenderPriority.Last.Value, function()
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local seat = hum and hum.SeatPart
	if seat and seat:IsA("VehicleSeat") then
		local t = (state.W and 1 or 0) - (state.S and 1 or 0)
		local s = (state.D and 1 or 0) - (state.A and 1 or 0)
		if t ~= 0 then seat.ThrottleFloat = t end
		if s ~= 0 then seat.SteerFloat = s end
	end
end)
