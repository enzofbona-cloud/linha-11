--!nocheck
-- Imitação mínima da API do Roblox para rodar os scripts do jogo fora do Studio.
-- Serve para achar erros de execução e travamentos de progresso; não desenha nada.

local realOs = os
local SIM = { clock = 0, timers = {}, errors = {}, log = {} }

local function report(err)
	table.insert(SIM.errors, tostring(err))
end

local function runThread(f, ...)
	local co = coroutine.create(f)
	local ok, err = coroutine.resume(co, ...)
	if not ok then
		report(tostring(err) .. "\n" .. debug.traceback(co))
	end
	return co
end

local function resumeThread(co, ...)
	local ok, err = coroutine.resume(co, ...)
	if not ok then
		report(tostring(err) .. "\n" .. debug.traceback(co))
	end
end

local fakeOs = setmetatable({ clock = function() return SIM.clock end }, { __index = realOs })

local fakeTask = {}
function fakeTask.spawn(f, ...) return runThread(f, ...) end
function fakeTask.defer(f, ...)
	local args = table.pack(...)
	table.insert(SIM.timers, { at = SIM.clock, f = function() f(table.unpack(args, 1, args.n)) end })
end
function fakeTask.delay(t, f, ...)
	local args = table.pack(...)
	table.insert(SIM.timers, { at = SIM.clock + (t or 0), f = function() f(table.unpack(args, 1, args.n)) end })
end
function fakeTask.wait(t)
	t = t or 0.03
	if coroutine.isyieldable() then
		local co = coroutine.running()
		table.insert(SIM.timers, { at = SIM.clock + t, co = co })
		coroutine.yield()
	else
		SIM.advance(t)
	end
	return t
end

-- ---------------------------------------------------------------- tipos de valor
local function valueType(name, mt)
	mt.__vtype = name
	return mt
end

local V3 = valueType("Vector3", {})
V3.__index = function(self, k)
	if k == "Magnitude" then return math.sqrt(self.X * self.X + self.Y * self.Y + self.Z * self.Z) end
	if k == "Unit" then
		local m = self.Magnitude
		if m == 0 then return self end
		return setmetatable({ X = self.X / m, Y = self.Y / m, Z = self.Z / m }, V3)
	end
	return nil
end
local function v3(x, y, z) return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, V3) end
V3.__add = function(a, b) return v3(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
V3.__sub = function(a, b) return v3(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
V3.__unm = function(a) return v3(-a.X, -a.Y, -a.Z) end
V3.__mul = function(a, b)
	if type(a) == "number" then return v3(a * b.X, a * b.Y, a * b.Z) end
	if type(b) == "number" then return v3(a.X * b, a.Y * b, a.Z * b) end
	return v3(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
end
V3.__div = function(a, b)
	if type(b) == "number" then return v3(a.X / b, a.Y / b, a.Z / b) end
	return v3(a.X / b.X, a.Y / b.Y, a.Z / b.Z)
end
V3.__eq = function(a, b) return a.X == b.X and a.Y == b.Y and a.Z == b.Z end
V3.__tostring = function(a) return string.format("(%.2f, %.2f, %.2f)", a.X, a.Y, a.Z) end
local Vector3 = { new = v3, zero = v3(0, 0, 0), one = v3(1, 1, 1), xAxis = v3(1, 0, 0), yAxis = v3(0, 1, 0), zAxis = v3(0, 0, 1) }

-- CFrame: posição + matriz de rotação 3x3 (linhas r1, r2, r3).
local CF = valueType("CFrame", {})
local function cf(p, r) return setmetatable({ p = p, r = r or { 1, 0, 0, 0, 1, 0, 0, 0, 1 } }, CF) end
local function matMul(a, b)
	local o = {}
	for i = 0, 2 do
		for j = 0, 2 do
			o[i * 3 + j + 1] = a[i * 3 + 1] * b[j + 1] + a[i * 3 + 2] * b[3 + j + 1] + a[i * 3 + 3] * b[6 + j + 1]
		end
	end
	return o
end
local function matVec(m, v) return v3(m[1] * v.X + m[2] * v.Y + m[3] * v.Z, m[4] * v.X + m[5] * v.Y + m[6] * v.Z, m[7] * v.X + m[8] * v.Y + m[9] * v.Z) end
CF.__index = function(self, k)
	if k == "Position" then return self.p end
	if k == "X" then return self.p.X elseif k == "Y" then return self.p.Y elseif k == "Z" then return self.p.Z end
	if k == "LookVector" then return v3(-self.r[3], -self.r[6], -self.r[9]) end
	if k == "RightVector" then return v3(self.r[1], self.r[4], self.r[7]) end
	if k == "UpVector" then return v3(self.r[2], self.r[5], self.r[8]) end
	if k == "Rotation" then return cf(v3(0, 0, 0), self.r) end
	return nil
end
CF.__mul = function(a, b)
	if getmetatable(b) == V3 then return matVec(a.r, b) + a.p end
	return cf(matVec(a.r, b.p) + a.p, matMul(a.r, b.r))
end
CF.__add = function(a, b) return cf(a.p + b, a.r) end
CF.__sub = function(a, b) return cf(a.p - b, a.r) end
local CFrame = {}
function CFrame.new(a, b, c)
	if a == nil then return cf(v3(0, 0, 0)) end
	if type(a) == "number" then return cf(v3(a, b, c)) end
	if b ~= nil then return CFrame.lookAt(a, b) end
	return cf(a)
end
function CFrame.lookAt(from, to)
	local look = (to - from)
	if look.Magnitude == 0 then return cf(from) end
	look = look.Unit
	local right = v3(-look.Z, 0, look.X)
	if right.Magnitude == 0 then right = v3(1, 0, 0) else right = right.Unit end
	local up = v3(right.Y * -look.Z - right.Z * -look.Y, right.Z * -look.X - right.X * -look.Z, right.X * -look.Y - right.Y * -look.X)
	return cf(from, { right.X, up.X, -look.X, right.Y, up.Y, -look.Y, right.Z, up.Z, -look.Z })
end
function CFrame.Angles(rx, ry, rz)
	local cx, sx, cy, sy, cz, sz = math.cos(rx), math.sin(rx), math.cos(ry), math.sin(ry), math.cos(rz), math.sin(rz)
	local mx = { 1, 0, 0, 0, cx, -sx, 0, sx, cx }
	local my = { cy, 0, sy, 0, 1, 0, -sy, 0, cy }
	local mz = { cz, -sz, 0, sz, cz, 0, 0, 0, 1 }
	return cf(v3(0, 0, 0), matMul(matMul(mx, my), mz))
end
CFrame.fromEulerAnglesXYZ = CFrame.Angles
CFrame.identity = cf(v3(0, 0, 0))

local function plain(name, fields)
	local mt = valueType(name, {})
	mt.__index = mt
	return function(...)
		local values = table.pack(...)
		local o = {}
		for i, key in ipairs(fields) do o[key] = values[i] end
		return setmetatable(o, mt)
	end
end
local color = plain("Color3", { "R", "G", "B" })
local Color3 = { new = function(r, g, b) return color(r or 0, g or 0, b or 0) end, fromRGB = function(r, g, b) return color(r / 255, g / 255, b / 255) end,
	fromHSV = function(h, s, v) return color(v, v, v) end }
local udim = plain("UDim", { "Scale", "Offset" })
local UDim = { new = function(s, o) return udim(s or 0, o or 0) end }
local udim2 = plain("UDim2", { "X", "Y" })
local UDim2 = {
	new = function(xs, xo, ys, yo) return udim2(udim(xs or 0, xo or 0), udim(ys or 0, yo or 0)) end,
	fromScale = function(x, y) return udim2(udim(x, 0), udim(y, 0)) end,
	fromOffset = function(x, y) return udim2(udim(0, x), udim(0, y)) end,
}
local vec2 = plain("Vector2", { "X", "Y" })
local Vector2 = { new = function(x, y) return vec2(x or 0, y or 0) end, zero = vec2(0, 0) }
local TweenInfo = { new = plain("TweenInfo", { "Time", "EasingStyle", "EasingDirection", "RepeatCount", "Reverses", "DelayTime" }) }
local ColorSequence = { new = plain("ColorSequence", { "Keypoints" }) }
local ColorSequenceKeypoint = { new = plain("ColorSequenceKeypoint", { "Time", "Value" }) }
local NumberSequence = { new = plain("NumberSequence", { "Keypoints" }) }
local NumberSequenceKeypoint = { new = plain("NumberSequenceKeypoint", { "Time", "Value" }) }
local NumberRange = { new = plain("NumberRange", { "Min", "Max" }) }

-- Enum.Qualquer.Coisa devolve sempre o mesmo item para o mesmo nome.
local enumItemMt = valueType("EnumItem", {})
enumItemMt.__index = enumItemMt
enumItemMt.__tostring = function(self) return "Enum." .. self.Path end
local enumCache = {}
local Enum = setmetatable({}, { __index = function(_, family)
	local fam = setmetatable({}, { __index = function(_, item)
		local path = family .. "." .. item
		if not enumCache[path] then enumCache[path] = setmetatable({ Path = path, Name = item, Value = 0 }, enumItemMt) end
		return enumCache[path]
	end })
	return fam
end })

-- ---------------------------------------------------------------- sinais
local Signal = {}
Signal.__index = Signal
local function newSignal() return setmetatable({ handlers = {}, waiting = {} }, Signal) end
function Signal:Connect(f)
	local connection = { Connected = true }
	local entry = { f = f, connection = connection }
	table.insert(self.handlers, entry)
	local handlers = self.handlers
	function connection:Disconnect()
		self.Connected = false
		local i = table.find(handlers, entry)
		if i then table.remove(handlers, i) end
	end
	return connection
end
Signal.Once = Signal.Connect
function Signal:Wait()
	if coroutine.isyieldable() then
		table.insert(self.waiting, coroutine.running())
		return coroutine.yield()
	end
	return nil
end
function Signal:Fire(...)
	for _, entry in ipairs(table.clone(self.handlers)) do
		if entry.connection.Connected then runThread(entry.f, ...) end
	end
	local waiting = self.waiting
	self.waiting = {}
	for _, co in ipairs(waiting) do resumeThread(co, ...) end
end

-- ---------------------------------------------------------------- instâncias
local SIGNALS = {}
for _, name in ipairs({ "Triggered", "Activated", "MouseButton1Click", "Heartbeat", "RenderStepped", "Stepped", "PlayerAdded", "PlayerRemoving",
	"CharacterAdded", "CharacterRemoving", "OnServerEvent", "OnClientEvent", "PromptGamePassPurchaseFinished", "Completed", "InputBegan",
	"InputEnded", "DescendantAdded", "ChildAdded", "Died", "Touched", "Changed", "Ended", "PromptShown", "PromptHidden", "FocusLost",
	"AncestryChanged", "HealthChanged", "Event", "Loaded", "Destroying" }) do
	SIGNALS[name] = true
end
local BASEPARTS = { Part = true, WedgePart = true, SpawnLocation = true, MeshPart = true, TrussPart = true, CornerWedgePart = true }
local GUIOBJECTS = { Frame = true, TextLabel = true, TextButton = true, ScrollingFrame = true, ImageLabel = true, ImageButton = true, TextBox = true }
local LIGHTS = { PointLight = true, SpotLight = true, SurfaceLight = true }

local Inst = { __vtype = "Instance" }
local methods = {}
local services = {}
local game

local function newInstance(class)
	local props = { Name = class, ClassName = class }
	if BASEPARTS[class] then
		props.Transparency = 0; props.Anchored = false; props.CanCollide = true
		props.Size = v3(4, 1, 2); props.CFrame = cf(v3(0, 0, 0)); props.Position = v3(0, 0, 0)
		props.AssemblyLinearVelocity = v3(0, 0, 0)
	elseif GUIOBJECTS[class] then
		props.Visible = true; props.Active = false; props.Text = ""; props.BackgroundTransparency = 0; props.TextTransparency = 0
	elseif class == "Humanoid" then
		props.Health = 100; props.MaxHealth = 100; props.WalkSpeed = 16; props.JumpPower = 50
	elseif class == "ProximityPrompt" then
		props.MaxActivationDistance = 10; props.Enabled = true; props.HoldDuration = 0
	elseif LIGHTS[class] then
		props.Enabled = true; props.Brightness = 1; props.Range = 8
	elseif class == "Sound" then
		props.Volume = 0.5; props.PlaybackSpeed = 1; props.Playing = false; props.IsPlaying = false; props.Looped = false
	elseif class == "ScreenGui" or class == "SurfaceGui" or class == "BillboardGui" then
		props.Enabled = true
	end
	return setmetatable({ __props = props, __children = {}, __attrs = {}, __signals = {}, __class = class }, Inst)
end

Inst.__index = function(self, key)
	local method = methods[key]
	if method then return method end
	local props = rawget(self, "__props")
	local value = props[key]
	if value ~= nil then return value end
	if key == "Parent" then return rawget(self, "__parent") end
	if SIGNALS[key] then
		local signals = rawget(self, "__signals")
		if not signals[key] then signals[key] = newSignal() end
		return signals[key]
	end
	for _, child in ipairs(rawget(self, "__children")) do
		if rawget(child, "__props").Name == key then return child end
	end
	return nil
end
Inst.__newindex = function(self, key, value)
	local props = rawget(self, "__props")
	if key == "Parent" then
		local old = rawget(self, "__parent")
		if old == value then return end
		if rawget(self, "__destroyed") and value ~= nil then error("The Parent property of " .. props.Name .. " is locked (instância destruída)", 2) end
		if old then
			local list = rawget(old, "__children")
			local i = table.find(list, self)
			if i then table.remove(list, i) end
		end
		rawset(self, "__parent", value)
		if value then
			table.insert(rawget(value, "__children"), self)
			local ancestor = value
			while ancestor do
				local signals = rawget(ancestor, "__signals")
				if signals.DescendantAdded then signals.DescendantAdded:Fire(self) end
				ancestor = rawget(ancestor, "__parent")
			end
		end
		return
	end
	if key == "CFrame" then
		if getmetatable(value) ~= CF then error("CFrame esperado em " .. props.Name .. ", veio " .. tostring(value), 2) end
		props.CFrame = value; props.Position = value.p
		return
	end
	if key == "Position" and BASEPARTS[rawget(self, "__class")] then
		if getmetatable(value) ~= V3 then error("Vector3 esperado em " .. props.Name .. ".Position", 2) end
		props.Position = value; props.CFrame = cf(value, props.CFrame and props.CFrame.r)
		return
	end
	props[key] = value
end
Inst.__tostring = function(self) return rawget(self, "__props").Name end

function methods:GetAttribute(name) return rawget(self, "__attrs")[name] end
function methods:SetAttribute(name, value)
	local attrs = rawget(self, "__attrs")
	local changed = attrs[name] ~= value
	attrs[name] = value
	local signal = rawget(self, "__signals")["Attr:" .. name]
	if changed and signal then signal:Fire() end
end
function methods:GetAttributeChangedSignal(name)
	local signals = rawget(self, "__signals")
	local key = "Attr:" .. name
	if not signals[key] then signals[key] = newSignal() end
	return signals[key]
end
function methods:GetAttributes() return table.clone(rawget(self, "__attrs")) end
function methods:GetChildren() return table.clone(rawget(self, "__children")) end
function methods:GetDescendants()
	local out = {}
	local function walk(node)
		for _, child in ipairs(rawget(node, "__children")) do
			table.insert(out, child)
			walk(child)
		end
	end
	walk(self)
	return out
end
function methods:IsA(name)
	local class = rawget(self, "__class")
	if class == name or name == "Instance" then return true end
	if name == "BasePart" or name == "PVInstance" then return BASEPARTS[class] == true end
	if name == "GuiObject" then return GUIOBJECTS[class] == true end
	if name == "Light" then return LIGHTS[class] == true end
	if name == "LuaSourceContainer" then return class == "ModuleScript" or class == "Script" or class == "LocalScript" end
	return false
end
function methods:FindFirstChild(name, recursive)
	for _, child in ipairs(rawget(self, "__children")) do
		if rawget(child, "__props").Name == name then return child end
	end
	if recursive then
		for _, child in ipairs(self:GetDescendants()) do
			if rawget(child, "__props").Name == name then return child end
		end
	end
	return nil
end
function methods:WaitForChild(name) return self:FindFirstChild(name) end
function methods:FindFirstChildOfClass(class)
	for _, child in ipairs(rawget(self, "__children")) do
		if rawget(child, "__class") == class then return child end
	end
	return nil
end
function methods:FindFirstChildWhichIsA(class)
	for _, child in ipairs(rawget(self, "__children")) do
		if child:IsA(class) then return child end
	end
	return nil
end
function methods:FindFirstAncestorOfClass(class)
	local node = rawget(self, "__parent")
	while node do
		if rawget(node, "__class") == class then return node end
		node = rawget(node, "__parent")
	end
	return nil
end
function methods:IsDescendantOf(other)
	local node = rawget(self, "__parent")
	while node do
		if node == other then return true end
		node = rawget(node, "__parent")
	end
	return false
end
function methods:Destroy()
	if rawget(self, "__destroyed") then return end
	for _, child in ipairs(table.clone(rawget(self, "__children"))) do child:Destroy() end
	self.Parent = nil
	rawset(self, "__destroyed", true)
end
function methods:ClearAllChildren()
	for _, child in ipairs(table.clone(rawget(self, "__children"))) do child:Destroy() end
end
function methods:GetPivot()
	local primary = rawget(self, "__props").PrimaryPart or self:FindFirstChild("HumanoidRootPart")
	if primary then return primary.CFrame end
	return rawget(self, "__pivot") or rawget(self, "__props").CFrame or cf(v3(0, 0, 0))
end
function methods:PivotTo(target)
	if getmetatable(target) ~= CF then error("PivotTo espera um CFrame", 2) end
	rawset(self, "__pivot", target)
	local primary = rawget(self, "__props").PrimaryPart or self:FindFirstChild("HumanoidRootPart")
	if primary then primary.CFrame = target end
end
function methods:GetService(name)
	if not services[name] then
		local service = newInstance(name)
		service.Name = name
		rawset(service, "__parent", game)
		table.insert(rawget(game, "__children"), service)
		services[name] = service
	end
	return services[name]
end
function methods:GetPlayers()
	local out = {}
	for _, child in ipairs(rawget(self, "__children")) do
		if rawget(child, "__class") == "Player" then table.insert(out, child) end
	end
	return out
end
function methods:TakeDamage(amount)
	self.Health = math.max(0, self.Health - amount)
	if self.Health <= 0 then self.Died:Fire() end
end
function methods:FireClient(player, eventName, payload)
	if typeof ~= nil and rawget(player, "__class") ~= "Player" then error("FireClient precisa de um Player", 2) end
	local inbox = rawget(player, "__inbox")
	if inbox then table.insert(inbox, { name = eventName, data = payload }) end
	if SIM.localPlayer == player then self.OnClientEvent:Fire(eventName, payload) end
end
function methods:FireAllClients(eventName, payload)
	for _, player in ipairs(services.Players:GetPlayers()) do self:FireClient(player, eventName, payload) end
end
function methods:FireServer(...)
	self.OnServerEvent:Fire(SIM.localPlayer, ...)
end
function methods:Create(target, info, goals)
	if getmetatable(target) ~= Inst then error("TweenService:Create precisa de uma instância", 2) end
	local tween = newInstance("Tween")
	rawset(tween, "__tween", { target = target, goals = goals })
	return tween
end
function methods:Play()
	local tween = rawget(self, "__tween")
	if tween then
		for key, value in pairs(tween.goals) do tween.target[key] = value end
		self.Completed:Fire(Enum.PlaybackState.Completed)
	else
		self.Playing = true; self.IsPlaying = true
	end
end
function methods:Stop() self.Playing = false; self.IsPlaying = false end
function methods:Pause() self.Playing = false; self.IsPlaying = false end
function methods:Cancel() end
SIM.datastore = {}
function methods:GetDataStore(name)
	local store = newInstance("DataStore")
	store.Name = name
	return store
end
function methods:GetAsync(key) return SIM.datastore[key] end
function methods:SetAsync(key, value) SIM.datastore[key] = value end
function methods:UpdateAsync(key, transform)
	local value = transform(SIM.datastore[key])
	if value ~= nil then SIM.datastore[key] = value end
	return value
end
function methods:UserOwnsGamePassAsync() return false end
function methods:PromptGamePassPurchase() end
function methods:BindAction(name, handler) SIM.actions[name] = handler end
function methods:UnbindAction(name) SIM.actions[name] = nil end
function methods:SetTitle() end
function methods:SetPosition() end
function methods:BindToRenderStep(name, _, handler) SIM.renderSteps[name] = handler end
function methods:UnbindFromRenderStep(name) SIM.renderSteps[name] = nil end
function methods:IsStudio() return false end
function methods:IsServer() return true end
function methods:IsClient() return true end
function methods:Clone()
	local copy = newInstance(rawget(self, "__class"))
	for k, v in pairs(rawget(self, "__props")) do rawget(copy, "__props")[k] = v end
	for k, v in pairs(rawget(self, "__attrs")) do rawget(copy, "__attrs")[k] = v end
	for _, child in ipairs(rawget(self, "__children")) do child:Clone().Parent = copy end
	return copy
end
function methods:GetPropertyChangedSignal(name)
	local signals = rawget(self, "__signals")
	local key = "Changed:" .. name
	if not signals[key] then signals[key] = newSignal() end
	return signals[key]
end
function methods:SetCore() end
function methods:SetCoreGuiEnabled() end
function methods:GetMouse() return newInstance("Mouse") end
function methods:LoadCharacter() end
function methods:Kick() end
function methods:GetNetworkOwner() return nil end
function methods:SetNetworkOwner() end

SIM.actions = {}
SIM.renderSteps = {}

game = newInstance("DataModel")
game.Name = "game"
local workspace = game:GetService("Workspace")
workspace.CurrentCamera = newInstance("Camera")
workspace.CurrentCamera.CFrame = cf(v3(0, 5, 0))
workspace.CurrentCamera.Parent = workspace

local Instance = {
	new = function(class, parent)
		if type(class) ~= "string" then error("Instance.new precisa do nome da classe", 2) end
		local item = newInstance(class)
		if parent then item.Parent = parent end
		return item
	end,
}

local function fakeTypeof(value)
	local mt = type(value) == "table" and getmetatable(value)
	if mt and rawget(mt, "__vtype") then return mt.__vtype end
	return type(value)
end

function SIM.advance(seconds)
	local remaining = seconds
	while remaining > 0 do
		local dt = math.min(0.1, remaining)
		remaining -= dt
		SIM.clock += dt
		local due = {}
		for i = #SIM.timers, 1, -1 do
			if SIM.timers[i].at <= SIM.clock then table.insert(due, table.remove(SIM.timers, i)) end
		end
		for i = #due, 1, -1 do
			local timer = due[i]
			if timer.co then resumeThread(timer.co) else runThread(timer.f) end
		end
		local run = services.RunService
		if run then
			local signals = rawget(run, "__signals")
			if signals.Heartbeat then signals.Heartbeat:Fire(dt) end
			if signals.RenderStepped then signals.RenderStepped:Fire(dt) end
		end
		for _, handler in pairs(SIM.renderSteps) do runThread(handler, dt) end
	end
end

SIM.newInstance = newInstance
SIM.game = game
SIM.runThread = runThread
SIM.env = {
	game = game, workspace = workspace, Instance = Instance, Vector3 = Vector3, CFrame = CFrame, Color3 = Color3,
	UDim = UDim, UDim2 = UDim2, Vector2 = Vector2, TweenInfo = TweenInfo, ColorSequence = ColorSequence,
	ColorSequenceKeypoint = ColorSequenceKeypoint, NumberSequence = NumberSequence, NumberSequenceKeypoint = NumberSequenceKeypoint,
	NumberRange = NumberRange, Enum = Enum, typeof = fakeTypeof, os = fakeOs, task = fakeTask,
}
