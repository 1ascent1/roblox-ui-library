local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local tweenInfo = TweenInfo.new(0.20, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

local ui = {}
local utility = {}

-- Theme system
local themes = {
	preset = {
		accent = Color3.fromRGB(50, 100, 255),
		light_contrast = Color3.fromRGB(30, 30, 30),
		dark_contrast = Color3.fromRGB(20, 20, 20),
		outline = Color3.fromRGB(40, 40, 40),
		textcolor = Color3.fromRGB(255, 255, 255)
	},
	utility = {
		accent = {},
		light_contrast = {},
		dark_contrast = {},
		outline = {},
		textcolor = {}
	}
}

local theme = themes.preset
theme.textsize = 13


function ui:Themify(instance, themeKey, property)
	if not themes.utility[themeKey] then
		themes.utility[themeKey] = {}
	end

	-- Store the instance and property to update
	table.insert(themes.utility[themeKey], {
		instance = instance,
		property = property
	})

	-- Set initial color
	instance[property] = theme[themeKey]
end

function ui:UpdateTheme(themeKey, newColor)
	-- Update the theme preset
	themes.preset[themeKey] = newColor
	theme[themeKey] = newColor

	-- Update all instances using this theme color
	if themes.utility[themeKey] then
		for _, data in pairs(themes.utility[themeKey]) do
			if data.instance and data.instance.Parent then
				-- Use tween for smooth color transitions
				utility:tween(data.instance, {[data.property] = newColor})
			end
		end
	end
end

-- Utility Functions
do
	function utility:create(class, props)
		local instance = Instance.new(class)
		for prop, value in pairs(props) do
			instance[prop] = value
		end
		return instance
	end

	function utility:tween(instance, properties)
		local tween = TweenService:Create(instance, tweenInfo, properties)
		tween:Play()
		return tween
	end
end

-- Main window class
local Window = {}
Window.__index = Window

-- Ui Functions
do
	function Window.new(props)
		local self = setmetatable({}, Window)

		self.props = props or {}
		self.tabs = {}
		self.currentTab = nil

		-- Store minimum size
		self.minSize = props.size or Vector2.new(450, 350)

		-- Create the main window GUI
		self.gui =
			utility:create(
				"ScreenGui",
				{
					Name = "\0",
					ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
					Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
				}
			)

		self.mainFrame =
			utility:create(
				"Frame",
				{
					Name = "Main",
					BackgroundColor3 = theme.light_contrast,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Size = UDim2.new(0, self.minSize.X, 0, self.minSize.Y),
					Position = UDim2.new(0.5, 0, 0.5, 0),
					BorderColor3 = theme.accent,
					Parent = self.gui
				}
			)

		-- Theme the main frame
		ui:Themify(self.mainFrame, "light_contrast", "BackgroundColor3")
		ui:Themify(self.mainFrame, "accent", "BorderColor3")

		-- Change anchor point to top-left so resizing behaves naturally
		self.mainFrame.AnchorPoint = Vector2.new(0, 0)

		-- Set position initially so window is centered on screen (you do this once)
		local screenSize = game:GetService("Workspace").CurrentCamera.ViewportSize
		local initialX = (screenSize.X - self.minSize.X) / 2
		local initialY = (screenSize.Y - self.minSize.Y) / 2
		self.mainFrame.Position = UDim2.new(0, initialX, 0, initialY)
		self.mainFrame.Size = UDim2.new(0, self.minSize.X, 0, self.minSize.Y)

		-- Tab holder
		self.tabHolder =
			utility:create(
				"Frame",
				{
					Name = "TabHolder",
					BackgroundColor3 = theme.dark_contrast,
					Size = UDim2.new(1, -20, 0, 25),
					Position = UDim2.new(0, 10, 0, 10),
					BorderColor3 = theme.outline,
					Parent = self.mainFrame
				}
			)

		ui:Themify(self.tabHolder, "dark_contrast", "BackgroundColor3")
		ui:Themify(self.tabHolder, "outline", "BorderColor3")

		self.tabLayout =
			utility:create(
				"UIListLayout",
				{
					Name = "TabLayout",
					HorizontalFlex = Enum.UIFlexAlignment.Fill,
					SortOrder = Enum.SortOrder.LayoutOrder,
					FillDirection = Enum.FillDirection.Horizontal,
					Parent = self.tabHolder
				}
			)

		-- Content holder
		self.contentHolder =
			utility:create(
				"Frame",
				{
					Name = "ContentHolder",
					BorderSizePixel = 0,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -20, 1, -56),
					Position = UDim2.new(0, 10, 0, 46),
					ZIndex = 0,
					Parent = self.mainFrame
				}
			)

		-- Left frame for content
		self.leftFrame =
			utility:create(
				"Frame",
				{
					Name = "Left",
					BorderSizePixel = 0,
					BackgroundTransparency = 1,
					ZIndex = 0,
					Size = UDim2.new(0.5, -5, 1, 0),
					Parent = self.contentHolder
				}
			)

		self.leftLayout =
			utility:create(
				"UIListLayout",
				{
					Name = "LeftLayout",
					VerticalFlex = Enum.UIFlexAlignment.Fill,
					Padding = UDim.new(0, 10),
					SortOrder = Enum.SortOrder.LayoutOrder,
					Parent = self.leftFrame
				}
			)

		-- Right frame for content
		self.rightFrame =
			utility:create(
				"Frame",
				{
					Name = "Right",
					BorderSizePixel = 0,
					BackgroundTransparency = 1,
					Size = UDim2.new(0.5, -5, 1, 0),
					ZIndex = 0,
					Position = UDim2.new(0.5, 5, 0, 0),
					Parent = self.contentHolder
				}
			)

		self.rightLayout =
			utility:create(
				"UIListLayout",
				{
					Name = "RightLayout",
					VerticalFlex = Enum.UIFlexAlignment.Fill,
					Padding = UDim.new(0, 10),
					SortOrder = Enum.SortOrder.LayoutOrder,
					Parent = self.rightFrame
				}
			)

		-- Toggle key functionality
		local toggleKey = Enum.KeyCode.RightShift
		local userInputService = game:GetService("UserInputService")

		local function toggleUI()
			self.gui.Enabled = not self.gui.Enabled
		end

		userInputService.InputBegan:Connect(
			function(input, gameProcessed)
				if not gameProcessed and input.KeyCode == toggleKey then
					toggleUI()
				end
			end
		)

		function self:SetToggleKey(keyCode)
			toggleKey = keyCode
		end

		-- Create invisible resize handle in bottom-right corner
		self.resizeHandle =
			utility:create(
				"Frame",
				{
					Name = "ResizeHandle",
					BackgroundTransparency = 1,
					Size = UDim2.new(0, 25, 0, 25),
					Position = UDim2.new(1, -25, 1, -25),
					Parent = self.mainFrame
				}
			)

		-- Dragging and resizing state
		self.dragData = {
			dragging = false,
			dragStart = nil,
			startPos = nil
		}

		self.resizeData = {
			resizing = false,
			resizeStart = Vector2.new(0, 0),
			startSize = UDim2.new(0, 0, 0, 0)
		}

		-- Resizing functionality
		function self:_setupResizing()
			local frame = self.mainFrame
			local resizeHandle = self.resizeHandle

			local function startResize(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					self.resizeData.resizing = true
					self.resizeData.resizeStart = input.Position
					self.resizeData.startSize = frame.Size
				end
			end

			local function updateResize(input)
				if self.resizeData.resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
					local delta = input.Position - self.resizeData.resizeStart
					local newWidth = math.max(self.minSize.X, self.resizeData.startSize.X.Offset + delta.X)
					local newHeight = math.max(self.minSize.Y, self.resizeData.startSize.Y.Offset + delta.Y)

					utility:tween(frame, {Size = UDim2.new(0, newWidth, 0, newHeight)})
				end
			end

			local function endResize(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					self.resizeData.resizing = false
				end
			end

			-- Connect resize events
			resizeHandle.InputBegan:Connect(startResize)
			userInputService.InputChanged:Connect(updateResize)
			userInputService.InputEnded:Connect(endResize)
		end

		-- Dragging functionality
		function self:_setupDragging()
			local frame = self.mainFrame
			local resizeHandle = self.resizeHandle

			local function startDrag(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 and not self.resizeData.resizing then
					self.dragData.dragging = true
					self.dragData.dragStart = input.Position
					self.dragData.startPos = frame.Position
				end
			end

			local function updateDrag(input)
				if self.dragData.dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
					local delta = input.Position - self.dragData.dragStart
					-- Remove utility:tween and set position directly
					frame.Position = UDim2.new(
						self.dragData.startPos.X.Scale,
						self.dragData.startPos.X.Offset + delta.X,
						self.dragData.startPos.Y.Scale,
						self.dragData.startPos.Y.Offset + delta.Y
					)
				end
			end

			local function endDrag(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					self.dragData.dragging = false
				end
			end

			frame.InputBegan:Connect(
				function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						local mousePos = userInputService:GetMouseLocation()
						local handlePos = resizeHandle.AbsolutePosition
						local handleSize = resizeHandle.AbsoluteSize

						-- If clicking inside resize handle, do not drag
						if
							mousePos.X >= handlePos.X and mousePos.X <= handlePos.X + handleSize.X and
							mousePos.Y >= handlePos.Y and
							mousePos.Y <= handlePos.Y + handleSize.Y
						then
							return
						end

						startDrag(input)
					end
				end
			)
			userInputService.InputChanged:Connect(updateDrag)
			userInputService.InputEnded:Connect(endDrag)
		end

		-- Initialize dragging and resizing handlers
		self:_setupResizing()
		self:_setupDragging()

		return self
	end

	function Window:Tab(name)
		local tab = {}
		tab.name = name
		tab.sections = {}
		tab.window = self

		-- Create tab button
		tab.button =
			utility:create(
				"TextButton",
				{
					Name = "TabButton",
					TextSize = theme.textsize,
					TextColor3 = theme.textcolor,
					BackgroundColor3 = theme.dark_contrast,
					FontFace = Font.new("rbxasset://fonts/families/Zekton.json"),
					Size = UDim2.new(0, 100, 1, 0),
					BorderColor3 = theme.outline,
					Text = name,
					AutoButtonColor = false,
					Parent = self.tabHolder
				}
			)

		-- Theme the tab button
		ui:Themify(tab.button, "textcolor", "TextColor3")
		ui:Themify(tab.button, "dark_contrast", "BackgroundColor3")
		ui:Themify(tab.button, "outline", "BorderColor3")

		-- Add hover effect with tween
		tab.button.MouseEnter:Connect(
			function()
				utility:tween(tab.button, {TextColor3 = Color3.fromRGB(220, 220, 220)})
			end
		)

		tab.button.MouseLeave:Connect(
			function()
				if self.currentTab ~= tab then
					utility:tween(tab.button, {TextColor3 = theme.textcolor})
				end
			end
		)

		tab.leftContent =
			utility:create(
				"Frame",
				{
					Name = "LeftContent",
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					Visible = false,
					ZIndex = 0,
					Parent = self.leftFrame
				}
			)

		utility:create(
			"UIListLayout",
			{
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 10),
				Parent = tab.leftContent
			}
		)

		-- Right content with layout (same structure)
		tab.rightContent =
			utility:create(
				"Frame",
				{
					Name = "RightContent",
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					Visible = false,
					ZIndex = 0,
					Parent = self.rightFrame
				}
			)

		utility:create(
			"UIListLayout",
			{
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 10),
				Parent = tab.rightContent
			}
		)

		-- Set up click event
		tab.button.MouseButton1Click:Connect(
			function()
				self:SwitchTab(tab)
			end
		)

		-- Add to window's tabs
		table.insert(self.tabs, tab)

		-- If this is the first tab, make it active
		if #self.tabs == 1 then
			self:SwitchTab(tab)
		end

		-- Add methods to tab
		function tab:Section(name, side)
			local section = {}
			section.name = name
			section.tab = self
			section.side = side or "left" -- Default to left side

			-- Determine parent frame based on side
			local parentFrame = (side == "right") and self.rightContent or self.leftContent

			-- Create section frame
			section.frame =
				utility:create(
					"Frame",
					{
						Name = "Section",
						BackgroundColor3 = theme.dark_contrast,
						Size = UDim2.new(1, 0, 0, 0),
						AutomaticSize = Enum.AutomaticSize.Y,
						BorderColor3 = theme.outline,
						ZIndex = -1,
						Parent = parentFrame
					}
				)

			-- Theme the section
			ui:Themify(section.frame, "dark_contrast", "BackgroundColor3")
			ui:Themify(section.frame, "outline", "BorderColor3")

			-- Title
			section.title =
				utility:create(
					"TextLabel",
					{
						Name = "ATitle",
						BorderSizePixel = 0,
						TextSize = theme.textsize,
						TextStrokeColor3 = theme.textcolor,
						TextColor3 = theme.textcolor,
						BackgroundTransparency = 1,
						Size = UDim2.new(1, 0, 0, 1),
						FontFace = Font.new("rbxasset://fonts/families/Zekton.json"),
						Text = name,
						ZIndex = -1,
						Parent = section.frame
					}
				)

			-- Theme the title
			ui:Themify(section.title, "textcolor", "TextColor3")
			ui:Themify(section.title, "textcolor", "TextStrokeColor3")

			local padding =
				utility:create(
					"UIPadding",
					{
						PaddingBottom = UDim.new(0, 5),
						Parent = section.title
					}
				)

			-- Layout
			section.layout =
				utility:create(
					"UIListLayout",
					{
						Padding = UDim.new(0, 7),
						SortOrder = Enum.SortOrder.LayoutOrder,
						Parent = section.frame
					}
				)

			section.layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(
				function()
					utility:tween(
						section.frame,
						{
							Size = UDim2.new(1, 0, 0, section.layout.AbsoluteContentSize.Y + 10)
						}
					)
				end
			)

			function section:Toggle(props)
				local toggle = {}
				toggle.state = props.default or false
				toggle.callback = props.callback or function()
				end

				-- Create toggle button
				toggle.button =
					utility:create(
						"TextButton",
						{
							Name = "ToggleButton",
							TextSize = 14,
							AutoButtonColor = false,
							TextColor3 = Color3.fromRGB(0, 0, 0),
							BackgroundTransparency = 1,
							Size = UDim2.new(1, 0, 0, 13),
							Text = "",
							ZIndex = 0,
							Parent = section.frame
						}
					)

				-- Toggle frame
				toggle.frame =
					utility:create(
						"Frame",
						{
							Name = "Toggle",
							BackgroundColor3 = toggle.state and theme.accent or theme.dark_contrast,
							Size = UDim2.new(0, 10, 0, 10),
							Position = UDim2.new(0, 8, 0, 3),
							BorderColor3 = theme.outline,
							ZIndex = 0,
							Parent = toggle.button
						}
					)

				-- Theme the toggle
				ui:Themify(toggle.frame, "outline", "BorderColor3")

				-- Title
				toggle.title =
					utility:create(
						"TextLabel",
						{
							Name = "ToggleTitle",
							TextSize = theme.textsize,
							TextXAlignment = Enum.TextXAlignment.Left,
							TextColor3 = Color3.fromRGB(255, 255, 255),
							BackgroundTransparency = 1,
							Size = UDim2.new(1, 0, 1, 0),
							FontFace = Font.new("rbxasset://fonts/families/Zekton.json"),
							Text = props.title or "Toggle",
							Position = UDim2.new(0, 26, 0, 1),
							ZIndex = 0,
							Parent = toggle.button
						}
					)

				-- Theme the toggle title
				ui:Themify(toggle.title, "textcolor", "TextColor3")

				-- Hover effects with tween
				toggle.button.MouseEnter:Connect(
					function()
						utility:tween(toggle.title, {TextColor3 = Color3.fromRGB(220, 220, 220)})
					end
				)

				toggle.button.MouseLeave:Connect(
					function()
						utility:tween(toggle.title, {TextColor3 = theme.textcolor})
					end
				)

				-- Click event with tween
				toggle.button.MouseButton1Click:Connect(
					function()
						toggle.state = not toggle.state
						utility:tween(
							toggle.frame,
							{
								BackgroundColor3 = toggle.state and theme.accent or theme.dark_contrast
							}
						)
						toggle.callback(toggle.state)
					end
				)

				-- Add Colorpicker method to the toggle
				function toggle:Colorpicker(colorProps)
					local colorpicker = {}
					colorpicker.color = colorProps.default or Color3.fromRGB(255, 255, 255)
					colorpicker.callback = colorProps.callback or function()
					end
					colorpicker.open = false

					-- Create color preview next to toggle
					toggle.colorPreview =
						utility:create(
							"TextButton",
							{
								Name = "ColorPreview",
								AutoButtonColor = false,
								BackgroundColor3 = colorpicker.color,
								Size = UDim2.new(0, 10, 0, 10),
								Position = UDim2.new(1, -20, 0.5, -3),
								BorderColor3 = theme.outline,
								ZIndex = 0,
								Text = "",
								Parent = toggle.button
							}
						)

					-- Theme the color preview
					ui:Themify(toggle.colorPreview, "outline", "BorderColor3")

					-- Color picker window
					colorpicker.window =
						utility:create(
							"Frame",
							{
								Name = "ColorWindow",
								Visible = false,
								BackgroundColor3 = theme.dark_contrast,
								Size = UDim2.new(0, 150, 0, 133),
								Position = UDim2.new(0, 0, 0, 15),
								BorderColor3 = theme.outline,
								ZIndex = 100,
								Parent = toggle.button
							}
						)

					-- Theme the color picker window
					ui:Themify(colorpicker.window, "dark_contrast", "BackgroundColor3")
					ui:Themify(colorpicker.window, "outline", "BorderColor3")

					-- Saturation/brightness picker
					colorpicker.sat =
						utility:create(
							"ImageButton",
							{
								Name = "Sat",
								AutoButtonColor = false,
								BackgroundColor3 = Color3.fromHSV(0, 1, 1),
								Image = "rbxassetid://13882904626",
								Size = UDim2.new(0, 123, 0, 123),
								BorderColor3 = Color3.fromRGB(28, 28, 28),
								Position = UDim2.new(0, 5, 0, 5),
								Parent = colorpicker.window
							}
						)

					-- Hue picker
					colorpicker.hue =
						utility:create(
							"ImageButton",
							{
								Name = "Hue",
								AutoButtonColor = false,
								BackgroundColor3 = Color3.fromRGB(255, 255, 255),
								Image = "rbxassetid://13882976736",
								Size = UDim2.new(0, 10, 0, 123),
								BorderColor3 = Color3.fromRGB(28, 28, 28),
								Position = UDim2.new(1, -15, 0, 5),
								Parent = colorpicker.window
							}
						)

					-- Current color indicators
					colorpicker.satIndicator =
						utility:create(
							"Frame",
							{
								Name = "Indicator",
								BackgroundColor3 = Color3.fromRGB(255, 255, 255),
								BorderColor3 = Color3.fromRGB(0, 0, 0),
								BorderSizePixel = 1,
								Size = UDim2.new(0, 5, 0, 5),
								Position = UDim2.new(0, 0, 0, 0),
								Parent = colorpicker.sat
							}
						)

					colorpicker.hueIndicator =
						utility:create(
							"Frame",
							{
								Name = "Indicator",
								BackgroundColor3 = Color3.fromRGB(255, 255, 255),
								BorderColor3 = Color3.fromRGB(0, 0, 0),
								BorderSizePixel = 1,
								Size = UDim2.new(1, 0, 0, 2),
								Position = UDim2.new(0, 0, 0, 0),
								Parent = colorpicker.hue
							}
						)

					-- Initialize positions
					local h, s, v = colorpicker.color:ToHSV()
					colorpicker.satIndicator.Position = UDim2.new(s, 0, 1 - v, 0)
					colorpicker.hueIndicator.Position = UDim2.new(0, 0, 1 - h, 0)
					colorpicker.sat.BackgroundColor3 = Color3.fromHSV(h, 1, 1)

					-- Color update function
					local function updateColor(h, s, v)
						colorpicker.color = Color3.fromHSV(h, s, v)
						utility:tween(toggle.colorPreview, {BackgroundColor3 = colorpicker.color})
						utility:tween(colorpicker.sat, {BackgroundColor3 = Color3.fromHSV(h, 1, 1)})
						colorpicker.callback(colorpicker.color)
					end

					-- Input handlers
					local function updateFromHue(input)
						local y =
							math.clamp(
								input.Position.Y - colorpicker.hue.AbsolutePosition.Y,
								0,
								colorpicker.hue.AbsoluteSize.Y
							)
						local h = 1 - (y / colorpicker.hue.AbsoluteSize.Y)
						local _, s, v = colorpicker.color:ToHSV()
						utility:tween(colorpicker.hueIndicator, {Position = UDim2.new(0, 0, 0, y)})
						updateColor(h, s, v)
					end

					local function updateFromSat(input)
						local x =
							math.clamp(
								input.Position.X - colorpicker.sat.AbsolutePosition.X,
								0,
								colorpicker.sat.AbsoluteSize.X
							)
						local y =
							math.clamp(
								input.Position.Y - colorpicker.sat.AbsolutePosition.Y,
								0,
								colorpicker.sat.AbsoluteSize.Y
							)
						local h = 1 - (colorpicker.hueIndicator.Position.Y.Offset / colorpicker.hue.AbsoluteSize.Y)
						local s = x / colorpicker.sat.AbsoluteSize.X
						local v = 1 - (y / colorpicker.sat.AbsoluteSize.Y)
						utility:tween(colorpicker.satIndicator, {Position = UDim2.new(0, x, 0, y)})
						updateColor(h, s, v)
					end

					-- Hue interaction
					colorpicker.hue.InputBegan:Connect(
						function(input)
							if input.UserInputType == Enum.UserInputType.MouseButton1 then
								updateFromHue(input)

								local connection
								connection =
									game:GetService("UserInputService").InputChanged:Connect(
										function(input)
											if input.UserInputType == Enum.UserInputType.MouseMovement then
												updateFromHue(input)
											end
										end
									)

								game:GetService("UserInputService").InputEnded:Once(
									function(input)
										if input.UserInputType == Enum.UserInputType.MouseButton1 then
											connection:Disconnect()
										end
									end
								)
							end
						end
					)

					-- Saturation interaction
					colorpicker.sat.InputBegan:Connect(
						function(input)
							if input.UserInputType == Enum.UserInputType.MouseButton1 then
								updateFromSat(input)

								local connection
								connection =
									game:GetService("UserInputService").InputChanged:Connect(
										function(input)
											if input.UserInputType == Enum.UserInputType.MouseMovement then
												updateFromSat(input)
											end
										end
									)

								game:GetService("UserInputService").InputEnded:Once(
									function(input)
										if input.UserInputType == Enum.UserInputType.MouseButton1 then
											connection:Disconnect()
										end
									end
								)
							end
						end
					)

					-- Toggle colorpicker visibility
					function colorpicker:Toggle()
						colorpicker.open = not colorpicker.open
						colorpicker.window.Visible = colorpicker.open

						-- Close other colorpickers
						for _, child in pairs(section.frame:GetDescendants()) do
							if child:IsA("Frame") and child.Name == "ColorWindow" and child ~= colorpicker.window then
								child.Visible = false
							end
						end
					end

					toggle.colorPreview.MouseButton1Click:Connect(
						function()
							colorpicker:Toggle()
						end
					)

					return toggle -- Return toggle for chaining
				end

				return toggle
			end

			function section:Button(props)
				local button = {}
				button.callback = props.callback or function()
				end

				-- Create button
				button.frame =
					utility:create(
						"TextButton",
						{
							Name = "Button",
							TextSize = theme.textsize,
							TextColor3 = Color3.fromRGB(255, 255, 255),
							BackgroundColor3 = theme.dark_contrast,
							FontFace = Font.new("rbxasset://fonts/families/Zekton.json"),
							Size = UDim2.new(1, -16, 0, 15),
							BorderColor3 = theme.outline,
							Text = props.title or "Button",
							Parent = section.frame
						}
					)

				-- Theme the button
				ui:Themify(button.frame, "textcolor", "TextColor3")
				ui:Themify(button.frame, "dark_contrast", "BackgroundColor3")
				ui:Themify(button.frame, "outline", "BorderColor3")

				-- Click animation
				button.frame.MouseButton1Down:Connect(
					function()
						utility:tween(
							button.frame,
							{
								BackgroundColor3 = theme.outline,
								TextColor3 = Color3.fromRGB(220, 220, 220)
							}
						)
					end
				)

				button.frame.MouseButton1Up:Connect(
					function()
						utility:tween(
							button.frame,
							{
								BackgroundColor3 = theme.dark_contrast,
								TextColor3 = theme.textcolor
							}
						)
						button.callback()
					end
				)

				-- Hover effects with tween
				button.frame.MouseEnter:Connect(
					function()
						utility:tween(
							button.frame,
							{
								BackgroundColor3 = theme.outline,
								TextColor3 = Color3.fromRGB(220, 220, 220)
							}
						)
					end
				)

				button.frame.MouseLeave:Connect(
					function()
						utility:tween(
							button.frame,
							{
								BackgroundColor3 = theme.dark_contrast,
								TextColor3 = theme.textcolor
							}
						)
					end
				)

				return button
			end

			function section:Slider(props)
				local slider = {}
				slider.value = props.default or props.min or 0
				slider.min = props.min or 0
				slider.max = props.max or 100
				slider.callback = props.callback or function()
				end
				slider.precise = props.precise or false
				slider.suffix = props.suffix or "%"

				-- Create slider container
				slider.container =
					utility:create(
						"Frame",
						{
							Name = "Slider",
							BackgroundTransparency = 1,
							Size = UDim2.new(1, 0, 0, 25),
							Parent = section.frame
						}
					)

				-- Title
				slider.title =
					utility:create(
						"TextLabel",
						{
							Name = "SlideTitle",
							TextSize = theme.textsize,
							TextXAlignment = Enum.TextXAlignment.Left,
							TextColor3 = Color3.fromRGB(255, 255, 255),
							BackgroundTransparency = 1,
							Size = UDim2.new(1, 0, 0, 10),
							FontFace = Font.new("rbxasset://fonts/families/Zekton.json"),
							Text = props.title or "Slider",
							Position = UDim2.new(0, 8, 0, 0),
							Parent = slider.container
						}
					)

				-- Theme the slider title
				ui:Themify(slider.title, "textcolor", "TextColor3")

				-- Value display
				slider.valueLabel =
					utility:create(
						"TextLabel",
						{
							Name = "SliderValue",
							TextSize = theme.textsize,
							TextXAlignment = Enum.TextXAlignment.Right,
							TextColor3 = Color3.fromRGB(255, 255, 255),
							BackgroundTransparency = 1,
							Size = UDim2.new(1, -30, 0, 10),
							FontFace = Font.new("rbxasset://fonts/families/Zekton.json"),
							Text = tostring(slider.value) .. slider.suffix,
							Position = UDim2.new(0, 24, 0, 0),
							Parent = slider.container
						}
					)

				-- Theme the value label
				ui:Themify(slider.valueLabel, "textcolor", "TextColor3")

				-- Slider track
				slider.track =
					utility:create(
						"TextButton",
						{
							Name = "SliderTrack",
							AutoButtonColor = false,
							BackgroundColor3 = theme.dark_contrast,
							Size = UDim2.new(1, -16, 0, 8),
							BorderColor3 = theme.outline,
							Text = "",
							Position = UDim2.new(0, 8, 0, 16),
							Parent = slider.container
						}
					)

				-- Theme the slider track
				ui:Themify(slider.track, "dark_contrast", "BackgroundColor3")
				ui:Themify(slider.track, "outline", "BorderColor3")

				-- Slider fill
				slider.fill =
					utility:create(
						"Frame",
						{
							Name = "SliderFill",
							BorderSizePixel = 0,
							BackgroundColor3 = theme.accent,
							Size = UDim2.new((slider.value - slider.min) / (slider.max - slider.min), 0, 1, 0),
							Parent = slider.track
						}
					)

				-- Theme the slider fill
				ui:Themify(slider.fill, "accent", "BackgroundColor3")

				slider.track.MouseEnter:Connect(function()
					local lighterAccent = theme.accent:Lerp(Color3.new(1, 1, 1), 0.25)
					utility:tween(slider.fill, {BackgroundColor3 = lighterAccent})
				end)

				slider.track.MouseLeave:Connect(
					function()
						utility:tween(slider.fill, {BackgroundColor3 = theme.accent})
					end
				)

				local connection

				local function updateSlider(input)
					local absoluteX = input.Position.X
					local trackStart = slider.track.AbsolutePosition.X
					local trackEnd = trackStart + slider.track.AbsoluteSize.X
					local trackWidth = trackEnd - trackStart

					local clampedX = math.clamp(absoluteX, trackStart - 10, trackEnd + 10)
					local relativeX = clampedX - trackStart
					local xScale = math.clamp(relativeX / trackWidth, 0, 1)

					local value
					if slider.precise then
						value = math.floor((slider.min + (slider.max - slider.min) * xScale) * 100) / 100
					else
						value = math.floor(slider.min + (slider.max - slider.min) * xScale)
					end

					slider.value = value
					utility:tween(slider.fill, {Size = UDim2.new(xScale, 0, 1, 0)})
					slider.valueLabel.Text = tostring(slider.value) .. slider.suffix
					slider.callback(slider.value)
				end

				-- Track input handling
				slider.track.InputBegan:Connect(
					function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							updateSlider(input)

							-- Disconnect previous connection if exists
							if connection then
								connection:Disconnect()
							end

							connection =
								game:GetService("UserInputService").InputChanged:Connect(
									function(input)
										if input.UserInputType == Enum.UserInputType.MouseMovement then
											updateSlider(input)
										end
									end
								)
						end
					end
				)

				-- Handle input ended
				game:GetService("UserInputService").InputEnded:Connect(
					function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 and connection then
							connection:Disconnect()
							connection = nil
						end
					end
				)

				-- Thumb input handling (optional)
				slider.fill.InputBegan:Connect(
					function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							updateSlider(input)

							if connection then
								connection:Disconnect()
							end

							connection =
								game:GetService("UserInputService").InputChanged:Connect(
									function(input)
										if input.UserInputType == Enum.UserInputType.MouseMovement then
											updateSlider(input)
										end
									end
								)
						end
					end
				)

				return slider
			end

			function section:Dropdown(props)
				local dropdown = {}
				dropdown.options = props.options or {}
				dropdown.callback = props.callback or function()
				end
				dropdown.selected = props.default or props.options[1] or "Option"
				dropdown.open = false

				-- Create dropdown container
				dropdown.container =
					utility:create(
						"Frame",
						{
							Name = "Dropdown",
							BackgroundTransparency = 1,
							Size = UDim2.new(1, 0, 0, 34),
							ZIndex = 15,
							Parent = section.frame
						}
					)

				-- Title
				dropdown.title =
					utility:create(
						"TextLabel",
						{
							Name = "Title",
							TextSize = theme.textsize,
							TextXAlignment = Enum.TextXAlignment.Left,
							TextColor3 = Color3.fromRGB(255, 255, 255),
							BackgroundTransparency = 1,
							Size = UDim2.new(1, 0, 0, 10),
							FontFace = Font.new("rbxasset://fonts/families/Zekton.json"),
							Text = props.title or "Dropdown",
							Position = UDim2.new(0, 8, 0, 0),
							ZIndex = 15,
							Parent = dropdown.container
						}
					)

				-- Theme the dropdown title
				ui:Themify(dropdown.title, "textcolor", "TextColor3")

				-- Dropdown button
				dropdown.button =
					utility:create(
						"TextButton",
						{
							Name = "Dropdown",
							TextSize = theme.textsize,
							AutoButtonColor = false,
							TextColor3 = Color3.fromRGB(255, 255, 255),
							BackgroundColor3 = theme.dark_contrast,
							FontFace = Font.new("rbxasset://fonts/families/Zekton.json"),
							Size = UDim2.new(1, -16, 0, 15),
							BorderColor3 = theme.outline,
							Text = "",
							Position = UDim2.new(0, 8, 0, 16),
							ZIndex = 15,
							Parent = dropdown.container
						}
					)

				-- Theme the dropdown button
				ui:Themify(dropdown.button, "textcolor", "TextColor3")
				ui:Themify(dropdown.button, "dark_contrast", "BackgroundColor3")
				ui:Themify(dropdown.button, "outline", "BorderColor3")

				-- Selected value display
				dropdown.valueLabel =
					utility:create(
						"TextLabel",
						{
							Name = "Value",
							TextSize = theme.textsize,
							TextXAlignment = Enum.TextXAlignment.Left,
							TextColor3 = Color3.fromRGB(255, 255, 255),
							BackgroundTransparency = 1,
							Size = UDim2.new(1, -10, 1, 0),
							FontFace = Font.new("rbxasset://fonts/families/Zekton.json"),
							Text = dropdown.selected,
							Position = UDim2.new(0, 2, 0, 0),
							ZIndex = 15,
							Parent = dropdown.button
						}
					)

				-- Theme the value label
				ui:Themify(dropdown.valueLabel, "textcolor", "TextColor3")

				-- Dropdown icon
				dropdown.icon =
					utility:create(
						"TextLabel",
						{
							Name = "Icon",
							BorderSizePixel = 0,
							TextSize = theme.textsize,
							TextXAlignment = Enum.TextXAlignment.Right,
							TextColor3 = Color3.fromRGB(255, 255, 255),
							BackgroundTransparency = 1,
							Size = UDim2.new(1, 0, 1, 0),
							FontFace = Font.new("rbxasset://fonts/families/Zekton.json"),
							Text = "-",
							Position = UDim2.new(0, -4, 0, 0),
							Parent = dropdown.button
						}
					)

				-- Theme the dropdown icon
				ui:Themify(dropdown.icon, "textcolor", "TextColor3")

				-- Dropdown content (options)
				dropdown.content =
					utility:create(
						"Frame",
						{
							Name = "Content",
							Visible = false,
							BackgroundColor3 = theme.dark_contrast,
							Size = UDim2.new(1, 0, 0, 0),
							Position = UDim2.new(0, 0, 0, 18),
							BorderColor3 = theme.outline,
							ZIndex = 15,
							Parent = dropdown.button
						}
					)

				-- Theme the dropdown content
				ui:Themify(dropdown.content, "dark_contrast", "BackgroundColor3")
				ui:Themify(dropdown.content, "outline", "BorderColor3")

				utility:create(
					"UIListLayout",
					{
						SortOrder = Enum.SortOrder.LayoutOrder,
						Parent = dropdown.content
					}
				)

				-- Create options
				dropdown.optionButtons = {} -- Store option buttons for highlighting
				for _, option in pairs(dropdown.options) do
					local optionButton =
						utility:create(
							"TextButton",
							{
								Name = "Option",
								BorderSizePixel = 0,
								TextSize = 14,
								AutoButtonColor = false,
								TextColor3 = Color3.fromRGB(0, 0, 0),
								BackgroundColor3 = theme.dark_contrast,
								BackgroundTransparency = 1,
								Size = UDim2.new(1, 0, 0, 15),
								Text = "",
								ZIndex = 15,
								Parent = dropdown.content
							}
						)

					local optionLabel =
						utility:create(
							"TextLabel",
							{
								Name = "OptionName",
								BorderSizePixel = 0,
								TextSize = theme.textsize,
								TextXAlignment = Enum.TextXAlignment.Left,
								TextColor3 = Color3.fromRGB(255, 255, 255),
								BackgroundTransparency = 1,
								Size = UDim2.new(1, 0, 1, 0),
								FontFace = Font.new("rbxasset://fonts/families/Zekton.json"),
								Text = option,
								Position = UDim2.new(0, 2, 0, 0),
								ZIndex = 15,
								Parent = optionButton
							}
						)

					-- Theme the option label
					ui:Themify(optionLabel, "textcolor", "TextColor3")

					-- Highlight if this is the selected option
					if option == dropdown.selected then
						optionLabel.TextColor3 = theme.accent
					end

					-- Hover effects with tween
					optionButton.MouseEnter:Connect(
						function()
							utility:tween(optionLabel, {TextColor3 = theme.accent})
						end
					)

					optionButton.MouseLeave:Connect(
						function()
							-- Return to normal color if not selected
							if option ~= dropdown.selected then
								utility:tween(optionLabel, {TextColor3 = theme.textcolor})
							end
						end
					)

					optionButton.MouseButton1Click:Connect(
						function()
							-- Reset all option colors
							for _, btn in pairs(dropdown.optionButtons) do
								local lbl = btn:FindFirstChild("OptionName")
								if lbl then
									utility:tween(lbl, {TextColor3 = theme.textcolor})
								end
							end

							-- Set the selected option color
							utility:tween(optionLabel, {TextColor3 = theme.accent})

							dropdown.selected = option
							dropdown.valueLabel.Text = option
							dropdown.callback(option)
							dropdown:Toggle()
						end
					)

					table.insert(dropdown.optionButtons, optionButton)
				end

				-- Dropdown toggle with smooth animation
				function dropdown:Toggle()
					dropdown.open = not dropdown.open
					dropdown.content.Visible = dropdown.open
					dropdown.icon.Text = dropdown.open and "+" or "-"

					if dropdown.open then
						utility:tween(
							dropdown.content,
							{
								Size = UDim2.new(1, 0, 0, #dropdown.options * 15)
							}
						)

						-- Close other dropdowns
						for _, child in pairs(section.frame:GetChildren()) do
							if child:IsA("Frame") and child.Name == "Dropdown" then
								local otherDropdown = child:FindFirstChild("Dropdown")
								if otherDropdown and otherDropdown ~= dropdown.button then
									local content = otherDropdown:FindFirstChild("Content")
									if content and content.Visible then
										content.Visible = false
										otherDropdown:FindFirstChild("Icon").Text = "-"
									end
								end
							end
						end
					else
						utility:tween(
							dropdown.content,
							{
								Size = UDim2.new(1, 0, 0, 0)
							}
						)
					end
				end

				-- Button hover effects
				dropdown.button.MouseEnter:Connect(
					function()
						utility:tween(dropdown.button, {BackgroundColor3 = theme.outline})
					end
				)

				dropdown.button.MouseLeave:Connect(
					function()
						utility:tween(dropdown.button, {BackgroundColor3 = theme.dark_contrast})
					end
				)

				dropdown.button.MouseButton1Click:Connect(
					function()
						dropdown:Toggle()
					end
				)

				return dropdown
			end

			function section:MultiDropdown(props)
				local multidropdown = {}
				multidropdown.options = props.options or {}
				multidropdown.callback = props.callback or function()
				end
				multidropdown.selected = props.default or {}
				multidropdown.open = false
				multidropdown.maxShown = props.maxShown or 3 -- Max options shown in display text

				-- Create dropdown container
				multidropdown.container =
					utility:create(
						"Frame",
						{
							Name = "MultiDropdown",
							BackgroundTransparency = 1,
							Size = UDim2.new(1, 0, 0, 34),
							ZIndex = 4,
							Parent = section.frame
						}
					)

				-- Title
				multidropdown.title =
					utility:create(
						"TextLabel",
						{
							Name = "Title",
							TextSize = theme.textsize,
							TextXAlignment = Enum.TextXAlignment.Left,
							TextColor3 = Color3.fromRGB(255, 255, 255),
							BackgroundTransparency = 1,
							Size = UDim2.new(1, 0, 0, 10),
							FontFace = Font.new("rbxasset://fonts/families/Zekton.json"),
							Text = props.title or "Multi Dropdown",
							Position = UDim2.new(0, 8, 0, 0),
							ZIndex = 4,
							Parent = multidropdown.container
						}
					)

				-- Theme the multidropdown title
				ui:Themify(multidropdown.title, "textcolor", "TextColor3")

				-- Dropdown button
				multidropdown.button =
					utility:create(
						"TextButton",
						{
							Name = "MultiDropdown",
							TextSize = theme.textsize,
							AutoButtonColor = false,
							TextColor3 = Color3.fromRGB(255, 255, 255),
							BackgroundColor3 = theme.dark_contrast,
							FontFace = Font.new("rbxasset://fonts/families/Zekton.json"),
							Size = UDim2.new(1, -16, 0, 15),
							BorderColor3 = theme.outline,
							Text = "",
							Position = UDim2.new(0, 8, 0, 16),
							ZIndex = 4,
							Parent = multidropdown.container
						}
					)

				-- Theme the multidropdown button
				ui:Themify(multidropdown.button, "textcolor", "TextColor3")
				ui:Themify(multidropdown.button, "dark_contrast", "BackgroundColor3")
				ui:Themify(multidropdown.button, "outline", "BorderColor3")

				-- Selected value display
				multidropdown.valueLabel =
					utility:create(
						"TextLabel",
						{
							Name = "Value",
							TextSize = theme.textsize,
							TextXAlignment = Enum.TextXAlignment.Left,
							TextColor3 = Color3.fromRGB(255, 255, 255),
							BackgroundTransparency = 1,
							Size = UDim2.new(1, -10, 1, 0),
							FontFace = Font.new("rbxasset://fonts/families/Zekton.json"),
							Text = "None",
							Position = UDim2.new(0, 2, 0, 0),
							ZIndex = 4,
							Parent = multidropdown.button
						}
					)

				-- Theme the value label
				ui:Themify(multidropdown.valueLabel, "textcolor", "TextColor3")

				-- Update the display text
				local function updateDisplay()
					local selectedCount = #multidropdown.selected
					if selectedCount == 0 then
						multidropdown.valueLabel.Text = "None"
					else
						local displayText = ""
						local shown = 0

						for i, option in pairs(multidropdown.selected) do
							if shown < multidropdown.maxShown then
								if shown > 0 then
									displayText = displayText .. ", "
								end
								displayText = displayText .. option
								shown = shown + 1
							else
								displayText = displayText .. ", +" .. (selectedCount - shown)
								break
							end
						end

						multidropdown.valueLabel.Text = displayText
					end
				end

				-- Initial update
				updateDisplay()

				-- Dropdown icon
				multidropdown.icon =
					utility:create(
						"TextLabel",
						{
							Name = "Icon",
							BorderSizePixel = 0,
							TextSize = theme.textsize,
							TextXAlignment = Enum.TextXAlignment.Right,
							TextColor3 = Color3.fromRGB(255, 255, 255),
							BackgroundTransparency = 1,
							Size = UDim2.new(1, 0, 1, 0),
							FontFace = Font.new("rbxasset://fonts/families/Zekton.json"),
							Text = "-",
							Position = UDim2.new(0, -4, 0, 0),
							Parent = multidropdown.button
						}
					)

				-- Theme the icon
				ui:Themify(multidropdown.icon, "textcolor", "TextColor3")

				-- Dropdown content (options)
				multidropdown.content =
					utility:create(
						"Frame",
						{
							Name = "Content",
							Visible = false,
							BackgroundColor3 = theme.dark_contrast,
							Size = UDim2.new(1, 0, 0, 0),
							Position = UDim2.new(0, 0, 0, 18),
							BorderColor3 = theme.outline	,
							ZIndex = 2,
							Parent = multidropdown.button
						}
					)

				-- Theme the content
				ui:Themify(multidropdown.content, "dark_contrast", "BackgroundColor3")
				ui:Themify(multidropdown.content, "outline", "BorderColor3")

				utility:create(
					"UIListLayout",
					{
						SortOrder = Enum.SortOrder.LayoutOrder,
						Parent = multidropdown.content
					}
				)

				-- Create options
				multidropdown.optionButtons = {} -- Store option buttons for highlighting
				for _, option in pairs(multidropdown.options) do
					local optionButton =
						utility:create(
							"TextButton",
							{
								Name = "Option",
								BorderSizePixel = 0,
								TextSize = 14,
								AutoButtonColor = false,
								TextColor3 = Color3.fromRGB(0, 0, 0),
								BackgroundColor3 = theme.dark_contrast,
								BackgroundTransparency = 1,
								Size = UDim2.new(1, 0, 0, 15),
								Text = "",
								ZIndex = 2,
								Parent = multidropdown.content
							}
						)

					local optionLabel =
						utility:create(
							"TextLabel",
							{
								Name = "OptionName",
								BorderSizePixel = 0,
								TextSize = theme.textsize,
								TextXAlignment = Enum.TextXAlignment.Left,
								TextColor3 = Color3.fromRGB(255, 255, 255),
								BackgroundTransparency = 1,
								Size = UDim2.new(1, 0, 1, 0),
								FontFace = Font.new("rbxasset://fonts/families/Zekton.json"),
								Text = option,
								Position = UDim2.new(0, 2, 0, 0),
								ZIndex = 2,
								Parent = optionButton
							}
						)

					-- Theme the option label
					ui:Themify(optionLabel, "textcolor", "TextColor3")

					-- Set initial state if this option is selected
					if table.find(multidropdown.selected, option) then
						optionLabel.TextColor3 = theme.accent
					end

					-- Hover effects with tween
					optionButton.MouseEnter:Connect(
						function()
							if table.find(multidropdown.selected, option) then
								utility:tween(optionLabel, {TextColor3 = theme.accent})
							else
								utility:tween(optionLabel, {TextColor3 = Color3.fromRGB(220, 220, 220)})
							end
						end
					)

					optionButton.MouseLeave:Connect(
						function()
							if table.find(multidropdown.selected, option) then
								utility:tween(optionLabel, {TextColor3 = theme.accent})
							else
								utility:tween(optionLabel, {TextColor3 = theme.textcolor})
							end
						end
					)

					optionButton.MouseButton1Click:Connect(
						function()
							local index = table.find(multidropdown.selected, option)

							if index then
								-- Remove from selected
								table.remove(multidropdown.selected, index)
								utility:tween(optionLabel, {TextColor3 = theme.textcolor})
							else
								-- Add to selected
								table.insert(multidropdown.selected, option)
								utility:tween(optionLabel, {TextColor3 = theme.accent})
							end

							updateDisplay()
							multidropdown.callback(multidropdown.selected)
						end
					)

					table.insert(multidropdown.optionButtons, optionButton)
				end

				-- Dropdown toggle with smooth animation
				function multidropdown:Toggle()
					multidropdown.open = not multidropdown.open
					multidropdown.content.Visible = multidropdown.open
					multidropdown.icon.Text = multidropdown.open and "+" or "-"

					if multidropdown.open then
						utility:tween(
							multidropdown.content,
							{
								Size = UDim2.new(1, 0, 0, #multidropdown.options * 15)
							}
						)

						-- Close other dropdowns
						for _, child in pairs(section.frame:GetChildren()) do
							if child:IsA("Frame") and (child.Name == "MultiDropdown" or child.Name == "Dropdown") then
								local otherDropdown =
									child:FindFirstChild("MultiDropdown") or child:FindFirstChild("Dropdown")
								if otherDropdown and otherDropdown ~= multidropdown.button then
									local content = otherDropdown:FindFirstChild("Content")
									if content and content.Visible then
										content.Visible = false
										otherDropdown:FindFirstChild("Icon").Text = "-"
									end
								end
							end
						end
					else
						utility:tween(
							multidropdown.content,
							{
								Size = UDim2.new(1, 0, 0, 0)
							}
						)
					end
				end

				-- Button hover effects
				multidropdown.button.MouseEnter:Connect(
					function()
						utility:tween(multidropdown.button, {BackgroundColor3 = theme.outline})
					end
				)

				multidropdown.button.MouseLeave:Connect(
					function()
						utility:tween(multidropdown.button, {BackgroundColor3 = theme.dark_contrast})
					end
				)

				multidropdown.button.MouseButton1Click:Connect(
					function()
						multidropdown:Toggle()
					end
				)

				-- Method to set selected options programmatically
				function multidropdown:SetSelected(options)
					multidropdown.selected = options or {}

					-- Update option colors
					for _, button in pairs(multidropdown.optionButtons) do
						local option = button:FindFirstChild("OptionName").Text
						local optionLabel = button:FindFirstChild("OptionName")

						if table.find(multidropdown.selected, option) then
							utility:tween(optionLabel, {TextColor3 = theme.accent})
						else
							utility:tween(optionLabel, {TextColor3 = theme.textcolor})
						end
					end

					updateDisplay()
				end

				-- Method to clear all selections
				function multidropdown:Clear()
					self:SetSelected({})
				end

				return multidropdown
			end

			function section:Colorpicker(props)
				local colorpicker = {}
				colorpicker.color = props.default or Color3.fromRGB(255, 255, 255)
				colorpicker.callback = props.callback or function()
				end
				colorpicker.open = false

				-- Create colorpicker button
				colorpicker.button =
					utility:create(
						"TextButton",
						{
							Name = "Colorpicker",
							TextSize = 14,
							AutoButtonColor = false,
							TextColor3 = Color3.fromRGB(0, 0, 0),
							BackgroundTransparency = 1,
							Size = UDim2.new(1, 0, 0, 10),
							Text = "",
							ZIndex = -1,
							Parent = section.frame
						}
					)

				-- Title
				colorpicker.title =
					utility:create(
						"TextLabel",
						{
							Name = "ColorpickerTitle",
							TextSize = theme.textsize,
							TextXAlignment = Enum.TextXAlignment.Left,
							TextColor3 = Color3.fromRGB(255, 255, 255),
							BackgroundTransparency = 1,
							Size = UDim2.new(1, 0, 1, 0),
							FontFace = Font.new("rbxasset://fonts/families/Zekton.json"),
							Text = props.title or "Color",
							Position = UDim2.new(0, 8, 0, 2),
							ZIndex = -1,
							Parent = colorpicker.button
						}
					)

				-- Theme the title
				ui:Themify(colorpicker.title, "textcolor", "TextColor3")

				-- Color icon
				colorpicker.icon =
					utility:create(
						"TextButton",
						{
							Name = "Icon",
							AutoButtonColor = false,
							BackgroundColor3 = colorpicker.color,
							Size = UDim2.new(0, 10, 0, 10),
							BorderColor3 = theme.outline,
							Text = "",
							Position = UDim2.new(1, -20, 0, 4),
							ZIndex = -1,
							Parent = colorpicker.button
						}
					)

				-- Theme the icon border
				ui:Themify(colorpicker.icon, "outline", "BorderColor3")

				-- Color picker window
				colorpicker.window =
					utility:create(
						"Frame",
						{
							Name = "Window",
							Visible = false,
							BackgroundColor3 = theme.dark_contrast,
							Size = UDim2.new(0, 150, 0, 133),
							Position = UDim2.new(0, -125, 0, 20),
							BorderColor3 = theme.outline,
							ZIndex = 255,
							Parent = colorpicker.icon
						}
					)

				-- Theme the window
				ui:Themify(colorpicker.window, "dark_contrast", "BackgroundColor3")
				ui:Themify(colorpicker.window, "outline", "BorderColor3")

				-- Saturation/brightness picker
				colorpicker.sat =
					utility:create(
						"ImageButton",
						{
							Name = "Sat",
							AutoButtonColor = false,
							BackgroundColor3 = Color3.fromHSV(0, 1, 1),
							Image = "rbxassetid://13882904626",
							Size = UDim2.new(0, 123, 0, 123),
							BorderColor3 = Color3.fromRGB(28, 28, 28),
							Position = UDim2.new(0, 5, 0, 5),
							ZIndex = 255,
							Parent = colorpicker.window
						}
					)

				-- Hue picker
				colorpicker.hue =
					utility:create(
						"ImageButton",
						{
							Name = "Hue",
							AutoButtonColor = false,
							BackgroundColor3 = Color3.fromRGB(255, 255, 255),
							Image = "rbxassetid://13882976736",
							Size = UDim2.new(0, 10, 0, 123),
							BorderColor3 = Color3.fromRGB(28, 28, 28),
							Position = UDim2.new(1, -15, 0, 5),
							ZIndex = 255,
							Parent = colorpicker.window
						}
					)

				-- Current color indicator for saturation
				colorpicker.satIndicator =
					utility:create(
						"Frame",
						{
							Name = "Indicator",
							BackgroundColor3 = Color3.fromRGB(255, 255, 255),
							BorderColor3 = Color3.fromRGB(0, 0, 0),
							BorderSizePixel = 1,
							Size = UDim2.new(0, 5, 0, 5),
							Position = UDim2.new(0, 0, 0, 0),
							ZIndex = 255,
							Parent = colorpicker.sat
						}
					)

				-- Current color indicator for hue
				colorpicker.hueIndicator =
					utility:create(
						"Frame",
						{
							Name = "Indicator",
							BackgroundColor3 = Color3.fromRGB(255, 255, 255),
							BorderColor3 = Color3.fromRGB(0, 0, 0),
							BorderSizePixel = 1,
							Size = UDim2.new(1, 0, 0, 2),
							Position = UDim2.new(0, 0, 0, 0),
							ZIndex = 255,
							Parent = colorpicker.hue
						}
					)

				-- Initialize with current color
				local h, s, v = colorpicker.color:ToHSV()
				colorpicker.satIndicator.Position =
					UDim2.new(0, s * colorpicker.sat.AbsoluteSize.X, 0, (1 - v) * colorpicker.sat.AbsoluteSize.Y)
				colorpicker.hueIndicator.Position = UDim2.new(0, 0, 0, (1 - h) * colorpicker.hue.AbsoluteSize.Y)
				colorpicker.sat.BackgroundColor3 = Color3.fromHSV(h, 1, 1)

				-- Color picker logic
				local function updateColor(h, s, v)
					colorpicker.color = Color3.fromHSV(h, s, v)
					utility:tween(colorpicker.icon, {BackgroundColor3 = colorpicker.color})
					utility:tween(colorpicker.sat, {BackgroundColor3 = Color3.fromHSV(h, 1, 1)})
					colorpicker.callback(colorpicker.color)
				end

				local function updateFromHue(input)
					if not colorpicker.open then
						return
					end

					local y =
						math.clamp(
							input.Position.Y - colorpicker.hue.AbsolutePosition.Y,
							0,
							colorpicker.hue.AbsoluteSize.Y
						)
					local h = 1 - (y / colorpicker.hue.AbsoluteSize.Y)
					local _, s, v = colorpicker.color:ToHSV()

					-- Update immediately without tween for smoother dragging
					colorpicker.hueIndicator.Position = UDim2.new(0, 0, 0, y)
					updateColor(h, s, v)
				end

				local function updateFromSat(input)
					if not colorpicker.open then
						return
					end

					local x =
						math.clamp(
							input.Position.X - colorpicker.sat.AbsolutePosition.X,
							0,
							colorpicker.sat.AbsoluteSize.X
						)
					local y =
						math.clamp(
							input.Position.Y - colorpicker.sat.AbsolutePosition.Y,
							0,
							colorpicker.sat.AbsoluteSize.Y
						)
					local h = 1 - (colorpicker.hueIndicator.Position.Y.Offset / colorpicker.hue.AbsoluteSize.Y)
					local s = x / colorpicker.sat.AbsoluteSize.X
					local v = 1 - (y / colorpicker.sat.AbsoluteSize.Y)

					-- Update immediately without tween for smoother dragging
					colorpicker.satIndicator.Position = UDim2.new(0, x, 0, y)
					updateColor(h, s, v)
				end

				-- Hue picker interaction
				colorpicker.hue.InputBegan:Connect(
					function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							updateFromHue(input)

							local connection
							connection =
								game:GetService("UserInputService").InputChanged:Connect(
									function(input)
										if input.UserInputType == Enum.UserInputType.MouseMovement then
											updateFromHue(input)
										end
									end
								)

							local release
							release =
								game:GetService("UserInputService").InputEnded:Connect(
									function(input)
										if input.UserInputType == Enum.UserInputType.MouseButton1 then
											connection:Disconnect()
											release:Disconnect()
										end
									end
								)
						end
					end
				)

				-- Saturation picker interaction
				colorpicker.sat.InputBegan:Connect(
					function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							updateFromSat(input)

							local connection
							connection =
								game:GetService("UserInputService").InputChanged:Connect(
									function(input)
										if input.UserInputType == Enum.UserInputType.MouseMovement then
											updateFromSat(input)
										end
									end
								)

							local release
							release =
								game:GetService("UserInputService").InputEnded:Connect(
									function(input)
										if input.UserInputType == Enum.UserInputType.MouseButton1 then
											connection:Disconnect()
											release:Disconnect()
										end
									end
								)
						end
					end
				)

				function colorpicker:Toggle()
					colorpicker.open = not colorpicker.open
					colorpicker.window.Visible = colorpicker.open

					if colorpicker.open then
						-- Close other colorpickers
						for _, child in pairs(section.frame:GetChildren()) do
							if child:IsA("TextButton") and child.Name == "Colorpicker" then
								local icon = child:FindFirstChild("Icon")
								if icon and icon ~= colorpicker.icon then
									local window = icon:FindFirstChild("Window")
									if window and window.Visible then
										window.Visible = false
									end
								end
							end
						end
					end
				end

				colorpicker.icon.MouseButton1Click:Connect(
					function()
						colorpicker:Toggle()
					end
				)

				return colorpicker
			end

			return section
		end

		return tab
	end

	function Window:SwitchTab(tab)
		if self.currentTab then
			utility:tween(self.currentTab.button, {TextColor3 = theme.textcolor})
			self.currentTab.leftContent.Visible = false
			self.currentTab.rightContent.Visible = false
		end

		self.currentTab = tab
		utility:tween(tab.button, {TextColor3 = theme.accent})
		tab.leftContent.Visible = true
		tab.rightContent.Visible = true
	end

	function ui:Window(props)
		return Window.new(props)
	end
end

-- Create theme settings tab
local window = ui:Window({title = "Main Window", size = Vector2.new(480, 380)})

local tab1 = window:Tab("Main")
local tab2 = window:Tab("Settings")

local leftSection = tab1:Section("Main Options") do
	leftSection:Toggle({title = "Toggle", default = false, callback = function(state) print("Toggle state:", state) end})
	leftSection:Slider({title = "Slider", min = 0, max = 100, default = 75, suffix = "%", callback = function(value) print("Slider value:", value) end})
	leftSection:Dropdown({title = "Dropdown", options = {"1", "2", "3", "4"}, default = "1", callback = function(option) print("Selected:", option) end})
	leftSection:MultiDropdown({title = "Multi Dropdown", options = {"1", "2", "3", "4"}, callback = function(selected) print("Selected:", table.concat(selected, ", ")) end})
	leftSection:Colorpicker({title = "Colorpicker", default = theme.accent, callback = function(color) print("Selected color:", color) end})
	leftSection:Toggle({title = "Toggle Colorpicker", default = true, callback = function(state) print("Feature enabled:", state) end}):Colorpicker({default = Color3.fromRGB(255, 0, 0), callback = function(color) print("Color changed to:", color) end})
end

local rightSection = tab1:Section("Visuals", "right") do
	rightSection:Slider({title = "Slider", min = 0, max = 100, default = 75, suffix = "%", callback = function(value) print("Slider value:", value) end})
	rightSection:Slider({title = "Slider", min = 0, max = 100, default = 75, suffix = "%", callback = function(value) print("Slider value:", value) end})
end

local sigma = tab1:Section("Visuals") do
	sigma:Slider({title = "Slider", min = 0, max = 100, default = 75, suffix = "%", callback = function(value) print("Slider value:", value) end})
	sigma:Slider({title = "Slider", min = 0, max = 100, default = 75, suffix = "%", callback = function(value) print("Slider value:", value) end})
	sigma:MultiDropdown({title = "Multi Select", options = {"Option 1", "Option 2", "Option 3", "Option 4"}, callback = function(selected) print("Selected:", table.concat(selected, ", ")) end})
end

local themeSettings = tab2:Section("Theme") do
	themeSettings:Colorpicker({
		title = "Accent Color",
		default = theme.accent,
		callback = function(color)
			ui:UpdateTheme("accent", color)
		end
	})

	themeSettings:Colorpicker({
		title = "Light Contrast",
		default = theme.light_contrast,
		callback = function(color)
			ui:UpdateTheme("light_contrast", color)
		end
	})

	themeSettings:Colorpicker({
		title = "Dark Contrast",
		default = theme.dark_contrast,
		callback = function(color)
			ui:UpdateTheme("dark_contrast", color)
		end
	})

	themeSettings:Colorpicker({
		title = "Outline Color",
		default = theme.outline,
		callback = function(color)
			ui:UpdateTheme("outline", color)
		end
	})

	themeSettings:Colorpicker({
		title = "Text Color",
		default = theme.textcolor,
		callback = function(color)
			ui:UpdateTheme("textcolor", color)
		end
	})
end

return ui
