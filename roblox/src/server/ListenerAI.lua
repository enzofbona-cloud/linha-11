local RunService = game:GetService("RunService")

local ListenerAI = {}
ListenerAI.__index = ListenerAI

local function makeBodyPart(model, name, size, cf, color, material, transparency, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cf
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Transparency = transparency or 0
	if shape then
		part.Shape = shape
	end
	part.Parent = model
	return part
end

function ListenerAI.new(parent, playerProvider, onCatch)
	local self = setmetatable({}, ListenerAI)
	self.Parent = parent
	self.PlayerProvider = playerProvider
	self.OnCatch = onCatch
	self.Awake = false
	self.LastNoiseAt = 0
	self.LastNoiseX = 0
	self.Position = Vector3.new(-46, 0, 0)
	self.PatrolDirection = 1
	self.CatchCooldown = {}
	self.Clock = 0

	local model = Instance.new("Model")
	model.Name = "Ouvinte"
	model.Parent = parent
	self.Model = model

	local root = makeBodyPart(model, "Base", Vector3.new(0.2, 0.2, 0.2), CFrame.new(0, 0, 0), Color3.new(0, 0, 0), Enum.Material.SmoothPlastic, 1)
	model.PrimaryPart = root
	local charcoal = Color3.fromRGB(12, 13, 14)
	local coat = Color3.fromRGB(22, 23, 22)
	local dim = Color3.fromRGB(34, 31, 28)
	local function limb(name, size, x, y, z, color, material, shape)
		local part = makeBodyPart(model, name, size, CFrame.new(x, y, z), color or charcoal, material or Enum.Material.SmoothPlastic, 0, shape)
		return part, CFrame.new(x, y, z)
	end

	local animated = {}
	local function register(part, base, phase, amount)
		table.insert(animated, { part = part, base = base, phase = phase, amount = amount })
	end

	limb("Torso", Vector3.new(1.65, 4.1, 1.05), 0, 7.0, 0, coat, Enum.Material.Fabric)
	limb("Peito_afundado", Vector3.new(1.2, 1.7, 0.3), 0, 8.0, -0.63, charcoal, Enum.Material.Slate)
	local neck, neckBase = limb("Pescoço_longo", Vector3.new(0.48, 2.5, 0.52), 0, 10.1, -0.02, charcoal, Enum.Material.SmoothPlastic)
	register(neck, neckBase, 0.7, 0.04)
	local head, headBase = limb("Cabeça_sem_rosto", Vector3.new(1.15, 1.65, 1.0), 0.04, 11.85, -0.12, dim, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	register(head, headBase * CFrame.Angles(0, 0, math.rad(-19)), 0.2, 0.07)
	limb("Capuz_sombra", Vector3.new(1.5, 1.8, 1.2), 0.04, 12.0, 0.32, charcoal, Enum.Material.Fabric, Enum.PartType.Ball)
	local veil, veilBase = limb("Véu_escuro", Vector3.new(0.92, 1.25, 0.08), 0.04, 11.75, -0.68, Color3.fromRGB(5, 6, 7), Enum.Material.Glass)
	veil.Transparency = 0.14
	register(veil, veilBase * CFrame.Angles(0, 0, math.rad(-15)), 0.5, 0.035)

	for _, side in ipairs({ -1, 1 }) do
		local shoulder, shoulderBase = limb("Ombro", Vector3.new(0.8, 1.1, 0.9), side * 0.9, 8.8, 0, coat, Enum.Material.Fabric, Enum.PartType.Ball)
		register(shoulder, shoulderBase, side == -1 and 0 or math.pi, 0.12)
		local arm, armBase = limb("Braço_comprido", Vector3.new(0.34, 5.8, 0.38), side * 1.15, 5.3, -0.02, charcoal)
		register(arm, armBase, side == -1 and 0 or math.pi, 0.22)
		limb("Mão", Vector3.new(0.47, 0.75, 0.35), side * 1.17, 2.15, -0.11, dim, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		local leg, legBase = limb("Perna_fina", Vector3.new(0.48, 4.7, 0.57), side * 0.42, 2.45, 0.04, coat, Enum.Material.Fabric)
		register(leg, legBase, side == -1 and math.pi or 0, 0.18)
		limb("Pé", Vector3.new(0.5, 0.42, 0.95), side * 0.42, 0.22, -0.14, charcoal)
	end
	for i = 1, 5 do
		local strip, stripBase = limb("Tira_de_tecido", Vector3.new(0.24, 4.5 + (i % 2), 0.16), (i - 3) * 0.34, 5.6, 0.62, i % 2 == 0 and dim or coat, Enum.Material.Fabric)
		register(strip, stripBase, i * 0.8, 0.055)
	end
	for _, side in ipairs({ -1, 1 }) do
		local shard = Instance.new("WedgePart")
		shard.Name = "Ponta_do_manto"
		shard.Size = Vector3.new(0.55, 3.2, 0.4)
		shard.CFrame = CFrame.new(side * 0.72, 3.4, 0.55) * CFrame.Angles(0, 0, math.rad(side * -8))
		shard.Anchored = true
		shard.CanCollide = false
		shard.CanTouch = false
		shard.CanQuery = false
		shard.CastShadow = true
		shard.Color = charcoal
		shard.Material = Enum.Material.Fabric
		shard.Parent = model
		register(shard, CFrame.new(side * 0.72, 3.4, 0.55) * CFrame.Angles(0, 0, math.rad(side * -8)), side, 0.08)
	end

	self.AnimatedParts = animated
	self.Model:PivotTo(CFrame.new(self.Position))
	self.Connection = RunService.Heartbeat:Connect(function(dt)
		self:Step(dt)
	end)
	return self
end

function ListenerAI:Wake()
	if self.Awake then
		return
	end
	self.Awake = true
	self.LastNoiseAt = os.clock()
	self.LastNoiseX = self.Position.X
	self.Model:SetAttribute("Awake", true)
end

function ListenerAI:Ping(position, strength)
	if not self.Awake or typeof(position) ~= "Vector3" then
		return
	end
	if math.abs(position.Z) > 28 or position.X < -57 or position.X > 57 then
		return
	end
	local distance = math.abs(position.X - self.Position.X)
	if distance <= (strength or 75) then
		self.LastNoiseAt = os.clock()
		self.LastNoiseX = position.X
	end
end

function ListenerAI:Step(dt)
	if not self.Awake or not self.Model.Parent then
		return
	end
	self.Clock += dt
	local now = os.clock()
	local targetX
	local isHunting = now - self.LastNoiseAt < 10
	if isHunting then
		targetX = self.LastNoiseX
	else
		targetX = self.Position.X + self.PatrolDirection * dt * 3.0
		if targetX > 48 then
			self.PatrolDirection = -1
		elseif targetX < -48 then
			self.PatrolDirection = 1
		end
	end

	local speed = isHunting and 7.4 or 2.7
	local delta = targetX - self.Position.X
	local step = math.clamp(delta, -speed * dt, speed * dt)
	local nextX = math.clamp(self.Position.X + step, -51, 51)
	local facing = nextX >= self.Position.X and 1 or -1
	self.Position = Vector3.new(nextX, 0, 0)
	local bodyCFrame = CFrame.lookAt(self.Position + Vector3.new(0, 0.05, 0), self.Position + Vector3.new(facing, 0.05, 0))
	self.Model:PivotTo(bodyCFrame)
	local gait = isHunting and 1.0 or 0.25
	for _, record in ipairs(self.AnimatedParts) do
		local swing = math.sin(self.Clock * (isHunting and 7.2 or 2.7) + record.phase) * record.amount * gait
		record.part.CFrame = bodyCFrame * record.base * CFrame.Angles(swing, 0, 0)
	end

	local players = self.PlayerProvider()
	for _, player in ipairs(players) do
		if player:GetAttribute("Linha11Started") and not player:GetAttribute("Linha11Hidden") then
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if root and humanoid and humanoid.Health > 0 and math.abs(root.Position.Z) < 4.5 and math.abs(root.Position.X - self.Position.X) < 4.7 then
				if now - (self.CatchCooldown[player] or 0) > 18 then
					self.CatchCooldown[player] = now
					self.OnCatch(player)
				end
			end
		end
	end
end

function ListenerAI:Destroy()
	if self.Connection then
		self.Connection:Disconnect()
		self.Connection = nil
	end
	if self.Model then
		self.Model:Destroy()
	end
end

return ListenerAI

