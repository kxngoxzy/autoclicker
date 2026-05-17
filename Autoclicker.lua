--// Siah Auto Clicker
--// Stable full rewrite
--// Mouse Mode + Point Mode + Fast CPS Mode

repeat
	task.wait()
until game:IsLoaded()

--// Services
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer

--// Remove old point GUI if script is re-executed
pcall(function()
	local Old = CoreGui:FindFirstChild("SiahPointGUI")
	if Old then
		Old:Destroy()
	end
end)

--// Load Rayfield
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

--// Main Variables
local Enabled = false
local Mode = "Mouse"
local FastMode = false

local ClickDelay = 0.1
local ReleaseDelay = 0.1

local ToggleObject = nil
local InternalToggleUpdate = false

--// Window
local Window = Rayfield:CreateWindow({
	Name = "Siah Auto Clicker",
	LoadingTitle = "Siah Auto Clicker",
	LoadingSubtitle = "by Siah",
	ConfigurationSaving = {
		Enabled = false,
	},
	Discord = {
		Enabled = false,
	},
	KeySystem = false,
})

local MainTab = Window:CreateTab("Main", 4483362458)

--// Point GUI
local PointGUI = Instance.new("ScreenGui")
PointGUI.Name = "SiahPointGUI"
PointGUI.ResetOnSpawn = false
PointGUI.IgnoreGuiInset = true
PointGUI.Parent = CoreGui

local Point = Instance.new("TextButton")
Point.Name = "ClickPoint"
Point.Parent = PointGUI
Point.Size = UDim2.new(0, 42, 0, 42)
Point.Position = UDim2.new(0.5, -21, 0.5, -21)
Point.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
Point.BorderSizePixel = 0
Point.Text = ""
Point.AutoButtonColor = false
Point.Visible = false
Point.ZIndex = 999999

local PointCorner = Instance.new("UICorner")
PointCorner.CornerRadius = UDim.new(1, 0)
PointCorner.Parent = Point

local PointStroke = Instance.new("UIStroke")
PointStroke.Color = Color3.fromRGB(255, 255, 255)
PointStroke.Thickness = 2
PointStroke.Parent = Point

--// Drag System
local Dragging = false
local DragStart = nil
local StartPosition = nil

Point.InputBegan:Connect(function(Input)
	if Input.UserInputType == Enum.UserInputType.MouseButton1 then
		Dragging = true
		DragStart = Input.Position
		StartPosition = Point.Position
	end
end)

UIS.InputEnded:Connect(function(Input)
	if Input.UserInputType == Enum.UserInputType.MouseButton1 then
		Dragging = false
	end
end)

UIS.InputChanged:Connect(function(Input)
	if Dragging and Input.UserInputType == Enum.UserInputType.MouseMovement then
		local Delta = Input.Position - DragStart

		Point.Position = UDim2.new(
			StartPosition.X.Scale,
			StartPosition.X.Offset + Delta.X,
			StartPosition.Y.Scale,
			StartPosition.Y.Offset + Delta.Y
		)
	end
end)

--// Safe number function
local function SafeNumber(Value, Default)
	local Number = tonumber(Value)

	if Number == nil then
		return Default
	end

	if Number < 0 then
		return 0
	end

	return Number
end

--// Mouse position
local function GetMousePosition()
	local Pos = UIS:GetMouseLocation()
	return Pos.X, Pos.Y
end

--// Point position
local function GetPointPosition()
	local Pos = Point.AbsolutePosition
	local Size = Point.AbsoluteSize

	return Pos.X + (Size.X / 2), Pos.Y + (Size.Y / 2)
end

--// One click
local function SendClick(X, Y)
	X = math.floor(X)
	Y = math.floor(Y)

	VIM:SendMouseButtonEvent(X, Y, 0, true, game, 0)
	task.wait(SafeNumber(ClickDelay, 0.1))
	VIM:SendMouseButtonEvent(X, Y, 0, false, game, 0)
	task.wait(SafeNumber(ReleaseDelay, 0.1))
end

--// Fast click packet
--// True 10,000 CPS is not realistic/stable in Roblox executors.
--// This sends rapid click packets without freezing the UI.
local function SendFastClicks(X, Y)
	X = math.floor(X)
	Y = math.floor(Y)

	for _ = 1, 20 do
		if not Enabled or not FastMode then
			break
		end

		VIM:SendMouseButtonEvent(X, Y, 0, true, game, 0)
		VIM:SendMouseButtonEvent(X, Y, 0, false, game, 0)
	end

	task.wait()
end

--// Main click loop
--// Only one loop exists. This prevents stacked loops and broken toggles.
task.spawn(function()
	while true do
		if Enabled then
			local X, Y

			if Mode == "Point" then
				X, Y = GetPointPosition()
			else
				X, Y = GetMousePosition()
			end

			if FastMode then
				SendFastClicks(X, Y)
			else
				SendClick(X, Y)
			end
		else
			task.wait(0.03)
		end
	end
end)

--// Enable setter
local function SetEnabled(State)
	Enabled = State

	if ToggleObject then
		InternalToggleUpdate = true
		ToggleObject:Set(State)
		task.defer(function()
			InternalToggleUpdate = false
		end)
	end

	Rayfield:Notify({
		Title = "Siah Auto Clicker",
		Content = State and "Enabled" or "Disabled",
		Duration = 1.5,
		Image = 4483362458,
	})
end

--// Keybind system
local EqualsHeld = false
local BackspaceHeld = false
local ComboWasHeld = false

local function CheckCombo()
	if EqualsHeld and BackspaceHeld and not ComboWasHeld then
		ComboWasHeld = true
		SetEnabled(not Enabled)
	end
end

UIS.InputBegan:Connect(function(Input, GameProcessed)
	if GameProcessed then
		return
	end

	if Input.KeyCode == Enum.KeyCode.Equals then
		EqualsHeld = true
		CheckCombo()
	elseif Input.KeyCode == Enum.KeyCode.Backspace then
		BackspaceHeld = true
		CheckCombo()
	end
end)

UIS.InputEnded:Connect(function(Input)
	if Input.KeyCode == Enum.KeyCode.Equals then
		EqualsHeld = false
	elseif Input.KeyCode == Enum.KeyCode.Backspace then
		BackspaceHeld = false
	end

	if not EqualsHeld or not BackspaceHeld then
		ComboWasHeld = false
	end
end)

--// UI Toggle
ToggleObject = MainTab:CreateToggle({
	Name = "Enabled",
	CurrentValue = false,
	Flag = "SiahEnabledToggle",
	Callback = function(Value)
		if InternalToggleUpdate then
			return
		end

		Enabled = Value
	end,
})

--// Fast Mode Toggle
MainTab:CreateToggle({
	Name = "10K CPS Mode",
	CurrentValue = false,
	Flag = "SiahFastModeToggle",
	Callback = function(Value)
		FastMode = Value
	end,
})

--// Mode Dropdown
MainTab:CreateDropdown({
	Name = "Mode",
	Options = { "Mouse", "Point" },
	CurrentOption = { "Mouse" },
	MultipleOptions = false,
	Flag = "SiahModeDropdown",
	Callback = function(Option)
		if typeof(Option) == "table" then
			Mode = Option[1]
		else
			Mode = Option
		end

		Point.Visible = (Mode == "Point")
	end,
})

--// Click Delay Input
MainTab:CreateInput({
	Name = "Click Delay",
	PlaceholderText = "0.1",
	RemoveTextAfterFocusLost = false,
	Flag = "SiahClickDelayInput",
	Callback = function(Text)
		ClickDelay = SafeNumber(Text, 0.1)
	end,
})

--// Release Delay Input
MainTab:CreateInput({
	Name = "Release Delay",
	PlaceholderText = "0.1",
	RemoveTextAfterFocusLost = false,
	Flag = "SiahReleaseDelayInput",
	Callback = function(Text)
		ReleaseDelay = SafeNumber(Text, 0.1)
	end,
})

--// Info
MainTab:CreateParagraph({
	Title = "Controls",
	Content = "Press = + Backspace together to toggle. Point Mode shows the blue draggable circle. Mouse Mode clicks your current cursor position.",
})
