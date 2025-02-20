local contentProvider = game:GetService("ContentProvider")
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")
local starterGui = game:GetService("StarterGui")
local Maid = require(script.Parent:WaitForChild("Maid"))
local Signal = require(script.Parent:WaitForChild("Signal"))

local dropdown = {}
dropdown.__index = dropdown

function dropdown.new(icon, options)
	local self = {}
	setmetatable(self, dropdown)

	local maid = Maid.new()
	self._maid = maid
	self._tempConnections = maid:give(Maid.new())
	self.closed = maid:give(Signal.new())
	self.opened = maid:give(Signal.new())
	self.isOpen = false
	self.icon = icon
	self.dropdownContainer = self.icon.objects.container.Parent.Parent.Dropdown
	self.options = {}
	self.bringBackPlayerlist = false
	self.bringBackChat = false
	self.settings = {
		bindToIcon = false,
		closeWhenClicked = true,
		closeWhenClickedAway = true,
		canHidePlayerlist = true,
		canHideChat = true,
		tweenSpeed = 0.2,
		easingDirection = Enum.EasingDirection.Out,
		easingStyle = Enum.EasingStyle.Quad,
		chatDefaultDisplayOrder = 6,
		backgroundColor = Color3.fromRGB(31, 33, 35),
		textColor = Color3.new(1,1,1),
		imageColor = Color3.new(1,1,1)
	}

	local preload = {}
	for i, option in ipairs(options) do
		option.order = i
		self:createOption(option)
		table.insert(preload, option.container.Icon)
	end
	coroutine.wrap(function()
		contentProvider:PreloadAsync(preload)
	end)()

	local function open(input)
		local position = input and Vector2.new(input.Position.X,input.Position.Y)
		if self.isOpen then self:hide() return end
		self:open(position)
	end
	maid:give(self.icon.objects.button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			open(input)
		end
		input:Destroy()
	end))
	maid:give(self.icon.objects.button.TouchLongPress:Connect(function(_, state)
		if state == Enum.UserInputState.Begin then
			open()
		end
	end))

	self:close()
	self:update()
	return self
end

function dropdown:createOption(option)

	local optionContainer = self._maid:give(Instance.new("Frame"))
	optionContainer.Name = "Option"
	optionContainer.BackgroundColor3 = Color3.new(1,1,1)
	optionContainer.BackgroundTransparency = 1
	optionContainer.BorderSizePixel = 0
	optionContainer.Size = UDim2.new(1,0,0,35)
	optionContainer.Active = true
	optionContainer.Selectable = true
	optionContainer.ZIndex = 11
	optionContainer.Visible = false

	local optionIcon = Instance.new("ImageLabel")
	optionIcon.Name = "Icon"
	optionIcon.Image = option.icon or ""
	optionIcon.ScaleType = Enum.ScaleType.Fit
	optionIcon.BackgroundTransparency = 1
	optionIcon.AnchorPoint = Vector2.new(0.5,0.5)
	optionIcon.Position = UDim2.new(0.1,5,0.5,0)
	optionIcon.Size = UDim2.new(0,25,0,25)
	optionIcon.ZIndex = 12
	optionIcon.Parent = optionContainer

	local optionText = Instance.new("TextLabel")
	optionText.Name = "OptionName"
	optionText.Text = option.name
	optionText.BackgroundTransparency = 1
	optionText.AnchorPoint = Vector2.new(0,0.5)
	optionText.Position = UDim2.new(0.1,25,0.5,0)
	optionText.Size = UDim2.new(0.95,-40,0,25)
	optionText.Font = Enum.Font.GothamSemibold
	optionText.TextScaled = true
	optionText.TextColor3 = Color3.new(1,1,1)
	optionText.ZIndex = 12
	optionText.TextXAlignment = Enum.TextXAlignment.Left
	optionText.Parent = optionContainer

	local uiText = Instance.new("UITextSizeConstraint")
	uiText.MaxTextSize = 18
	uiText.MinTextSize = 8
	uiText.Parent = optionText

	option.container = optionContainer
	option.order = option.order or 1
	option.events = option.events or {}
	table.insert(self.options, option)

	optionContainer.MouseEnter:Connect(function()
		optionContainer.BackgroundTransparency = 0.9
	end)
	optionContainer.MouseLeave:Connect(function()
		optionContainer.BackgroundTransparency = 1
	end)
	optionContainer.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if option.clicked then
				option.clicked()
			end
			if self.settings.closeWhenClicked then
				self:close()
			end
		end
		input:Destroy()
	end)
	optionContainer.TouchTap:Connect(function()
		if option.clicked then
			option.clicked()
		end
		if self.settings.closeWhenClicked then
			self:close()
		end
	end)

	--optionContainer.Parent = script.Temp

	self:update()
	return option
end

function dropdown:removeOption(nameOrIndex)
	local index = tonumber(nameOrIndex)
	if not index then
		local name = tostring(nameOrIndex)
		for i, option in pairs(self.options) do
			if option.name == name then
				index = i
				break
			end
		end
	end
	local option = self.options[index]
	if not option then
		return false
	end
	option.container:Destroy()
	table.remove(self.options, index)
	self:update()
end

function dropdown:update()
	local dropdownContainer = self.dropdownContainer
	if not dropdownContainer then return end
	dropdownContainer.Background.BackgroundColor3 = self.settings.backgroundColor
	dropdownContainer.Background.BottomRoundedRect.ImageColor3 = self.settings.backgroundColor
	dropdownContainer.Background.TopRoundedRect.ImageColor3 = self.settings.backgroundColor
	for _,option in pairs(self.options) do
		option.container.OptionName.TextColor3 = self.settings.textColor
		option.container.Icon.ImageColor3 = self.settings.imageColor
	end

	local isIcon = false
	for _, option in pairs(self.options) do
		if option.container.Icon.Image ~= "" then
			isIcon = true
		end
	end
	if isIcon then
		for _, option in pairs(self.options) do
			option.container.OptionName.Position = UDim2.new(0.1,25,0.5,0)
		end
	else
		for _, option in pairs(self.options) do
			option.container.OptionName.Position = UDim2.new(0,10,0.5,0)
		end
	end
end

local settingActions = {
	["bindToIcon"] = function(self, value)
		if value then
			self._maid.bindToIconSelected = self.icon.selected:Connect(function()
				if not self.isOpen then
					self:open()
				end
			end)
			self._maid.bindToIconDeselected = self.icon.deselected:Connect(function()
				if self.isOpen then
					self:close()
				end
			end)
			self._maid.bindToIconOpened = self.opened:Connect(function()
				self.icon:select()
			end)
			self._maid.bindToIconClosed = self.closed:Connect(function()
				self.icon:deselect()
			end)
		else
			self._maid.bindToIconSelected = nil
			self._maid.bindToIconDeselected = nil
			self._maid.bindToIconOpened = nil
			self._maid.bindToIconClosed = nil
		end
	end
}
function dropdown:set(setting, value)
	if self.settings[setting] ~= nil then
		self.settings[setting] = value
		local settingAction = settingActions[setting]
		if settingAction then
			settingAction(self, value)
		end
	end
end

function dropdown:close()
	if not self.isOpen then
		return
	end
	self.isOpen = false

	self._tempConnections:clean()
	if self.bringBackPlayerlist then
		starterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList,true)
		self.bringBackPlayerlist = false
	end
	local dropdownContainer = self.dropdownContainer
	if self.bringBackChat then
		local chat = dropdownContainer.Parent.Parent:FindFirstChild("Chat")
		if chat then
			chat.DisplayOrder = self.settings.chatDefaultDisplayOrder
		end
	end
	dropdownContainer:TweenSize(
		UDim2.new(0.1,0,0,0),
		self.settings.easingDirection,
		self.settings.easingStyle,
		self.settings.tweenSpeed,
		true,
		function()
			if dropdownContainer.Size == UDim2.new(0.1,0,0,0) then
				dropdownContainer.Visible = false
			end
		end
	)
	self.closed:Fire()
end
dropdown.hide = dropdown.close

local function ToScale(offsetUDim2,viewportSize)
	return UDim2.new(offsetUDim2.X.Offset/viewportSize.X,0,offsetUDim2.Y.Offset/viewportSize.Y,0)
end

function dropdown:open(position)
	if self.isOpen then
		return
	end
	self.isOpen = true

	local dropdownContainer = self.dropdownContainer
	if position then
		dropdownContainer.Position = UDim2.new(0,position.X,0,math.clamp(position.Y+36,36,10000000))
	else
		dropdownContainer.Position = UDim2.new(0,self.icon.objects.container.AbsolutePosition.X,0,self.icon.objects.container.AbsolutePosition.Y+36+32)--topbar offset and icon size
	end

	if workspace.CurrentCamera then
		local viewportSize = workspace.CurrentCamera.ViewportSize
		local newPosition = UDim2.new(
			0,
			math.clamp(dropdownContainer.Position.X.Offset,0,viewportSize.X-dropdownContainer.AbsoluteSize.X-16),
			0,
			math.clamp(dropdownContainer.Position.Y.Offset,40,viewportSize.Y-dropdownContainer.AbsoluteSize.Y)
		)
		dropdownContainer.Position = ToScale(newPosition,viewportSize)
	end

	for _,option in pairs(dropdownContainer:GetChildren()) do
		if option:IsA("Frame") and option.Name == "Option" then
			option.Visible = false
			option.Parent = nil
		end
	end
	local containerSizeY = 8 --for top and bottom rounded rect
	table.sort(self.options, function(a,b) return a.order < b.order end)
	for i, option in ipairs(self.options) do
		option.container.Parent = dropdownContainer
		option.container.Visible = true
		option.container.Position = UDim2.new(0,0,0,4+(35*i)-35)
		containerSizeY = containerSizeY + option.container.Size.Y.Offset
	end

	if self.settings.canHidePlayerlist and self.icon.alignment == "right" and starterGui:GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList) then
		starterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList,false)
		self.bringBackPlayerlist = true
	end

	local chat = dropdownContainer.Parent.Parent:FindFirstChild("Chat")
	if chat and self.settings.canHideChat and dropdownContainer.Parent.DisplayOrder < chat.DisplayOrder then
		chat.DisplayOrder = dropdownContainer.Parent.DisplayOrder-1
		self.bringBackChat = true
	end

	self:update()

	if not userInputService.MouseEnabled and userInputService.TouchEnabled then
		local clickSound = dropdownContainer.Parent:FindFirstChild("ClickSound")
		if clickSound and clickSound.IsLoaded then
			clickSound.TimePosition = 0.1
			clickSound.Volume = 0.5
			clickSound:Play()
		else
			contentProvider:PreloadAsync({clickSound})
		end
	end

	dropdownContainer.Size = UDim2.new(0.1,0,0,0)
	dropdownContainer.Visible = true
	dropdownContainer:TweenSize(
		UDim2.new(0.1,0,0,containerSizeY),
		self.settings.easingDirection,
		self.settings.easingStyle,
		self.settings.tweenSpeed,
		true
	)

	local connection1
	connection1 = self._tempConnections:give(runService.Heartbeat:Connect(function()
		connection1:Disconnect()
		self._tempConnections:give(userInputService.InputBegan:Connect(function(input,gpe)
			if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.MouseButton2
			or input.UserInputType == Enum.UserInputType.MouseWheel
			or input.UserInputType == Enum.UserInputType.MouseButton3
			or input.UserInputType == Enum.UserInputType.Touch
			then
				local isOn = false
				for i,v in pairs(dropdownContainer.Parent.Parent:GetGuiObjectsAtPosition(input.Position.X,input.Position.Y)) do
					if v:IsDescendantOf(dropdownContainer) then
						isOn = true
						break
					end
				end
				if not isOn and self.settings.closeWhenClickedAway then
					if not(self.settings.bindToIcon and self.icon.hovering) then
						self:close()
					end
				end
			end
			input:Destroy()
		end))
	end))

	local connection2
	connection2 = self._tempConnections:give(runService.Heartbeat:Connect(function()
		connection2:Disconnect()
		if userInputService.MouseEnabled and not runService:IsStudio() then
			self._tempConnections:give(userInputService.WindowFocusReleased:Connect(function()
				self:close()
			end))
		end
	end))

	self.opened:Fire()

end
dropdown.show = dropdown.open

function dropdown:destroy()
	self:close()
	self._maid:clean()
end

return dropdown