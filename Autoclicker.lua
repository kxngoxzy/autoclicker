--// Siah Auto Clicker
--// VIM ONLY VERSION
--// Mouse Mode + Point Mode + Fast CPS Mode

repeat
	task.wait()
until game:IsLoaded()

--// Services
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

--// Cleanup old point gui
pcall(function()
	local Old = CoreGui:FindFirstChild("Siah_AutoClicker_PointGui")
	if Old then
		Old:Destroy()
	end
end)

--// Load Rayfield
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

--// State
local Enabled = false
local Mode = "Mouse"
local FastMode = false

local ClickDelay = 0.1
local ReleaseDelay = 0.1

local ToggleButton = nil
local UpdatingToggle = false

--// Helpers
local function Num(Value, Default)
	local N = tonumber(Value)

	if N == nil then
		return Default
	end

	if N < 0 then
		return 0
	end

	return N
end

local function Notify(Text)
	pcall(function()
		Rayfield:Notify({
			Title = "Siah Auto Clicker",
			Content = Text,
			Duration = 1.5,
			Image = 4483362458,
		})
	end)
end

--// Rayfield Window
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
local PointGui = Instance.new("ScreenGui")
PointGui.Name = "Siah_AutoClicker_PointGui"
PointGui.ResetOnSpawn = false
PointGui.IgnoreGuiInset = true
PointGui.DisplayOrder = 999999
PointGui.Parent = CoreGui

local Point = Instance.new("TextButton")
Point.Name = "Point"
Point.Parent = PointGui
Point.Size = UDim2.fromOffset(42, 42)
Point.Position = UDim2.new(0.5, -21, 0.5, -21)
Point.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
Point.BorderSizePixel = 0
Point.Text = ""
Point.AutoButtonColor = false
Point.Active = true
Point.Visible = false
Point.ZIndex = 999999

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(1, 0)
Corner.Parent = Point

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(255, 255, 255)
Stroke.Thickness = 2
Stroke.Parent = Point

--// Drag point
local Dragging = false
local DragStart = nil
local StartPos = nil

Point.InputBegan:Connect(function(Input)
	if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
		Dragging = true
		DragStart = Input.Position
		StartPos = Point.Position
	end
end)

UserInputService.InputEnded:Connect(function(Input)
	if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
		Dragging = false
	end
end)

UserInputService.InputChanged:Connect(function(Input)
	if not Dragging then
		return
	end

	if Input.UserInputType ~= Enum.UserInputType.MouseMovement and Input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	local Delta = Input.Position - DragStart

	Point.Position =
		UDim2.new(StartPos.X.Scale, StartPos.X.Offset + Delta.X, StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y)
end)

--// Position helpers
local function GetMouseXY()
	local Pos = UserInputService:GetMouseLocation()
	return Pos.X, Pos.Y
end

local function GetPointXY()
	local Pos = Point.AbsolutePosition
	local Size = Point.AbsoluteSize

	return Pos.X + (Size.X / 2), Pos.Y + (Size.Y / 2)
end

--// VIM click only
local function VIMMouseDown(X, Y)
	VirtualInputManager:SendMouseButtonEvent(math.floor(X), math.floor(Y), 0, true, game, 0)
end

local function VIMMouseUp(X, Y)
	VirtualInputManager:SendMouseButtonEvent(math.floor(X), math.floor(Y), 0, false, game, 0)
end

local function NormalClick(X, Y)
	local WasPointVisible = false

	if Mode == "Point" and Point.Visible then
		WasPointVisible = true
		Point.Visible = false
		RunService.RenderStepped:Wait()
	end

	VIMMouseDown(X, Y)
	task.wait(Num(ClickDelay, 0.1))
	VIMMouseUp(X, Y)
	task.wait(Num(ReleaseDelay, 0.1))

	if WasPointVisible and Mode == "Point" then
		Point.Visible = true
	end
end

local function FastClick(X, Y)
	local WasPointVisible = false

	if Mode == "Point" and Point.Visible then
		WasPointVisible = true
		Point.Visible = false
		RunService.RenderStepped:Wait()
	end

	for _ = 1, 15 do
		if not Enabled or not FastMode then
			break
		end

		VIMMouseDown(X, Y)
		VIMMouseUp(X, Y)
	end

	if WasPointVisible and Mode == "Point" then
		Point.Visible = true
	end

	task.wait()
end

--// Main click loop
local LoopStarted = false

local function StartLoop()
	if LoopStarted then
		return
	end

	LoopStarted = true

	task.spawn(function()
		while true do
			if Enabled then
				local X, Y

				if Mode == "Point" then
					X, Y = GetPointXY()
				else
					X, Y = GetMouseXY()
				end

				if FastMode then
					FastClick(X, Y)
				else
					NormalClick(X, Y)
				end
			else
				task.wait(0.05)
			end
		end
	end)
end

StartLoop()

--// Enable setter
local function SetEnabled(State, FromUI)
	Enabled = State

	if ToggleButton and not FromUI then
		UpdatingToggle = true

		pcall(function()
			ToggleButton:Set(State)
		end)

		task.defer(function()
			UpdatingToggle = false
		end)
	end

	Notify(State and "Enabled" or "Disabled")
end

--// Keybind: = + Backspace
local EqualsDown = false
local BackspaceDown = false
local ComboUsed = false

local function CheckCombo()
	local BothDown = EqualsDown and BackspaceDown

	if BothDown and not ComboUsed then
		ComboUsed = true
		SetEnabled(not Enabled, false)
	elseif not BothDown then
		ComboUsed = false
	end
end

UserInputService.InputBegan:Connect(function(Input, GameProcessed)
	if GameProcessed then
		return
	end

	if Input.KeyCode == Enum.KeyCode.Equals then
		EqualsDown = true
		CheckCombo()
	elseif Input.KeyCode == Enum.KeyCode.Backspace then
		BackspaceDown = true
		CheckCombo()
	end
end)

UserInputService.InputEnded:Connect(function(Input)
	if Input.KeyCode == Enum.KeyCode.Equals then
		EqualsDown = false
		CheckCombo()
	elseif Input.KeyCode == Enum.KeyCode.Backspace then
		BackspaceDown = false
		CheckCombo()
	end
end)

--// UI controls
ToggleButton = MainTab:CreateToggle({
	Name = "Enabled",
	CurrentValue = false,
	Flag = "SiahEnabled",
	Callback = function(Value)
		if UpdatingToggle then
			return
		end

		SetEnabled(Value, true)
	end,
})

MainTab:CreateToggle({
	Name = "10K CPS Mode",
	CurrentValue = false,
	Flag = "SiahFastMode",
	Callback = function(Value)
		FastMode = Value
	end,
})

MainTab:CreateDropdown({
	Name = "Mode",
	Options = { "Mouse", "Point" },
	CurrentOption = { "Mouse" },
	MultipleOptions = false,
	Flag = "SiahMode",
	Callback = function(Option)
		if type(Option) == "table" then
			Mode = Option[1] or "Mouse"
		else
			Mode = Option or "Mouse"
		end

		Point.Visible = (Mode == "Point")
	end,
})

MainTab:CreateInput({
	Name = "Click Delay",
	PlaceholderText = "0.1",
	RemoveTextAfterFocusLost = false,
	Flag = "SiahClickDelay",
	Callback = function(Text)
		ClickDelay = Num(Text, 0.1)
	end,
})

MainTab:CreateInput({
	Name = "Release Delay",
	PlaceholderText = "0.1",
	RemoveTextAfterFocusLost = false,
	Flag = "SiahReleaseDelay",
	Callback = function(Text)
		ReleaseDelay = Num(Text, 0.1)
	end,
})

MainTab:CreateParagraph({
	Title = "Info",
	Content = "This version only uses VirtualInputManager. Press = + Backspace together to toggle.",
})
