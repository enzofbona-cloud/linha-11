local TweenService = game:GetService("TweenService")

local Chapter2Map = {}
local BASE_X = 160
local world
local prompts = {}
local lights = {}
local jacks = {}
local door
local doorClosedCFrame
local doorPrompt
local doorOpen = false

local COLORS = {
	wall = Color3.fromRGB(105, 96, 83),
	wallDark = Color3.fromRGB(52, 51, 47),
	floor = Color3.fromRGB(54, 47, 40),
	wood = Color3.fromRGB(78, 54, 40),
	woodLight = Color3.fromRGB(112, 82, 58),
	fabric = Color3.fromRGB(68, 64, 59),
	metal = Color3.fromRGB(61, 67, 67),
	amber = Color3.fromRGB(240, 176, 94),
}

local function pos(x, y, z)
	return Vector3.new(BASE_X + x, y, z)
end

local function part(parent, name, size, position, color, material, transparency, canCollide, shape)
	local item = Instance.new("Part")
	item.Name = name
	item.Size = size
	item.Position = position
	item.Anchored = true
	item.CanCollide = canCollide ~= false
	item.CanTouch = false
	item.CanQuery = true
	item.CastShadow = true
	item.TopSurface = Enum.SurfaceType.Smooth
	item.BottomSurface = Enum.SurfaceType.Smooth
	item.Color = color or COLORS.wall
	item.Material = material or Enum.Material.Concrete
	item.Transparency = transparency or 0
	if shape then item.Shape = shape end
	item.Parent = parent
	return item
end

local function prompt(host, name, actionId, actionText, objectText, hold)
	local item = Instance.new("ProximityPrompt")
	item.Name = name
	item.ActionText = actionText
	item.ObjectText = objectText
	item.KeyboardKeyCode = Enum.KeyCode.E
	item.GamepadKeyCode = Enum.KeyCode.ButtonX
	item.HoldDuration = hold or 0.35
	item.MaxActivationDistance = 8
	item.RequiresLineOfSight = false
	item:SetAttribute("ActionId", actionId)
	item.Parent = host
	table.insert(prompts, item)
	return item
end

local function anchor(parent, name, x, y, z, actionId, actionText, objectText, hold)
	local host = part(parent, name, Vector3.new(0.8, 0.8, 0.8), pos(x, y, z), Color3.new(0, 0, 0), Enum.Material.SmoothPlastic, 1, false)
	host.CanQuery = false
	prompt(host, "Interagir", actionId, actionText, objectText, hold)
	return host
end

local function wallX(parent, name, x, z, length)
	return part(parent, name, Vector3.new(0.5, 10.2, length), pos(x, 5.1, z), COLORS.wall, Enum.Material.Plaster)
end

local function wallZ(parent, name, x, z, length)
	return part(parent, name, Vector3.new(length, 10.2, 0.5), pos(x, 5.1, z), COLORS.wall, Enum.Material.Plaster)
end

local function light(parent, name, x, z)
	local fixture = part(parent, name .. "_Base", Vector3.new(1.8, 0.18, 0.65), pos(x, 10, z), COLORS.metal, Enum.Material.Metal)
	local bulb = part(parent, name .. "_Difusor", Vector3.new(1.35, 0.08, 0.42), pos(x, 9.86, z), Color3.fromRGB(30, 30, 28), Enum.Material.Glass, 0.05, false)
	local point = Instance.new("PointLight")
	point.Name = "Luz_" .. name
	point.Color = COLORS.amber
	point.Brightness = 0
	point.Range = 17
	point.Shadows = false
	point.Parent = bulb
	table.insert(lights, { point = point, bulb = bulb, fixture = fixture })
end

local function document(parent, name, title, body, x, z, actionId, surfaceY)
	local paperY = surfaceY or 2.48
	local paper = part(parent, name, Vector3.new(2, 0.1, 1.45), pos(x, paperY, z), Color3.fromRGB(191, 178, 151), Enum.Material.SmoothPlastic)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "PapelImpresso"
	gui.Face = Enum.NormalId.Top
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 65
	gui.Parent = paper
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundColor3 = Color3.fromRGB(188, 174, 146)
	text.BackgroundTransparency = 0.05
	text.TextColor3 = Color3.fromRGB(38, 32, 26)
	text.Font = Enum.Font.Garamond
	text.TextScaled = true
	text.TextWrapped = true
	text.Text = title .. "\n" .. body
	text.Parent = gui
	anchor(parent, "Ler_" .. name, x, paperY + 0.72, z, actionId, "Examinar", title, 0.25)
end

local function counter(parent, name, x, z, width)
	part(parent, name .. "_Base", Vector3.new(width, 2.2, 2), pos(x, 1.1, z), COLORS.wood, Enum.Material.WoodPlanks)
	part(parent, name .. "_Tampo", Vector3.new(width + 0.12, 0.18, 2.15), pos(x, 2.28, z), Color3.fromRGB(125, 112, 94), Enum.Material.Marble)
end

local function addJack(parent, side, x, z)
	part(parent, "Tomada_" .. side, Vector3.new(0.9, 1.1, 0.12), pos(x, 3.1, z), COLORS.wallDark, Enum.Material.Metal)
	local bulb = part(parent, "Indicador_" .. side, Vector3.new(0.23, 0.23, 0.12), pos(x, 3.5, z - 0.08), Color3.fromRGB(44, 39, 34), Enum.Material.Glass, 0, false, Enum.PartType.Ball)
	local lightPart = Instance.new("PointLight")
	lightPart.Name = "Retorno_" .. side
	lightPart.Color = Color3.fromRGB(170, 44, 36)
	lightPart.Brightness = 0
	lightPart.Range = 4
	lightPart.Shadows = false
	lightPart.Parent = bulb
	jacks[side] = { bulb = bulb, light = lightPart }
	anchor(parent, "Ponto_" .. side, x, 3.3, z - 0.5, "C2_Jack" .. side, "Conectar", side == "A" and "Tomada da cozinha" or "Retorno da lavanderia", 0.6)
end

local function buildWorld()
	local oldWorld = workspace:FindFirstChild("Linha11Chapter2World")
	if oldWorld then oldWorld:Destroy() end
	world = Instance.new("Model")
	world.Name = "Linha11Chapter2World"
	world.Parent = workspace
	prompts = {}
	lights = {}
	jacks = {}

	part(world, "Corredor_Piso", Vector3.new(110, 0.6, 12), pos(55, -0.35, 0), COLORS.floor, Enum.Material.WoodPlanks)
	part(world, "Corredor_Teto", Vector3.new(110, 0.5, 12), pos(55, 11.9, 0), COLORS.wallDark, Enum.Material.Concrete)
	part(world, "Corredor_Parede_Norte", Vector3.new(110, 12, 0.55), pos(55, 6, -6), COLORS.wall, Enum.Material.Plaster)
	part(world, "Corredor_Parede_Sul_Esq", Vector3.new(51, 12, 0.55), pos(25.5, 6, 6), COLORS.wall, Enum.Material.Plaster)
	part(world, "Corredor_Parede_Sul_Dir", Vector3.new(53, 12, 0.55), pos(83.5, 6, 6), COLORS.wall, Enum.Material.Plaster)
	part(world, "Corredor_Parede_Oeste", Vector3.new(0.8, 16, 12), pos(0, 7.5, 0), COLORS.wallDark, Enum.Material.Concrete)
	part(world, "Corredor_Parede_Leste", Vector3.new(0.8, 16, 12), pos(110, 7.5, 0), COLORS.wallDark, Enum.Material.Concrete)
	for index, x in ipairs({ 16, 40, 64, 88 }) do light(world, "Corredor_" .. index, x, 0) end

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "InicioCapitulo02"
	spawn.Size = Vector3.new(4, 0.6, 4)
	spawn.Position = pos(4, 0.1, 0)
	spawn.Anchored = true
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = world

	local apt = Instance.new("Model")
	apt.Name = "Apartamento_304_Interior"
	apt.Parent = world
	part(apt, "Piso_304", Vector3.new(40, 0.45, 20), pos(54, 0.02, 16), COLORS.floor, Enum.Material.WoodPlanks)
	part(apt, "Teto_304", Vector3.new(40, 0.5, 20), pos(54, 10.45, 16), COLORS.wallDark, Enum.Material.Concrete)
	part(apt, "Parede_Oeste", Vector3.new(0.55, 11, 20), pos(34, 5.5, 16), COLORS.wall, Enum.Material.Plaster)
	part(apt, "Parede_Leste", Vector3.new(0.55, 11, 20), pos(74, 5.5, 16), COLORS.wall, Enum.Material.Plaster)
	part(apt, "Parede_Fundo", Vector3.new(40, 11, 0.55), pos(54, 5.5, 26), COLORS.wall, Enum.Material.Plaster)
	part(apt, "Parede_Frontal_Esq", Vector3.new(17, 11, 0.55), pos(42.5, 5.5, 6), COLORS.wall, Enum.Material.Plaster)
	part(apt, "Parede_Frontal_Dir", Vector3.new(17, 11, 0.55), pos(65.5, 5.5, 6), COLORS.wall, Enum.Material.Plaster)
	door = part(apt, "Porta_304_C2", Vector3.new(5.5, 8.6, 0.42), pos(54, 4.3, 6), COLORS.wood, Enum.Material.WoodPlanks)
	part(apt, "Batente_304_Esq", Vector3.new(0.35, 9, 0.75), pos(51.25, 4.5, 6), COLORS.woodLight, Enum.Material.Wood)
	part(apt, "Batente_304_Dir", Vector3.new(0.35, 9, 0.75), pos(56.75, 4.5, 6), COLORS.woodLight, Enum.Material.Wood)
	part(apt, "Batente_304_Topo", Vector3.new(5.85, 0.35, 0.75), pos(54, 8.95, 6), COLORS.woodLight, Enum.Material.Wood)
	part(apt, "Macaneta_304_C2", Vector3.new(0.16, 0.16, 0.18), pos(55.9, 4.3, 5.72), Color3.fromRGB(145, 111, 70), Enum.Material.Metal, 0, false, Enum.PartType.Ball)
	doorClosedCFrame = door.CFrame
	doorPrompt = prompt(door, "Abrir_304_C2", "C2_Door304", "Fechar", "Porta do apartamento 304", 0.2)
	doorPrompt.MaxActivationDistance = 9
	local sign = part(world, "Placa_304_Corredor", Vector3.new(3.2, 0.85, 0.12), pos(54, 8.4, 5.65), COLORS.wood, Enum.Material.Wood)
	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Front
	signGui.PixelsPerStud = 45
	signGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	signGui.Parent = sign
	local signText = Instance.new("TextLabel")
	signText.Size = UDim2.fromScale(1, 1)
	signText.BackgroundTransparency = 1
	signText.Text = "304  •  AURORA"
	signText.TextColor3 = Color3.fromRGB(224, 211, 188)
	signText.Font = Enum.Font.Garamond
	signText.TextScaled = true
	signText.Parent = signGui

	-- Divisórias criam sala, eixo de circulação, cozinha, lavanderia, quarto e banheiro.
	wallX(apt, "Parede_Sala_A", 52, 9.5, 7)
	wallX(apt, "Parede_Sala_B", 52, 22.5, 7)
	wallX(apt, "Parede_Ala_A", 56, 7, 2)
	wallX(apt, "Parede_Ala_B", 56, 14.5, 5)
	wallX(apt, "Parede_Ala_C", 56, 23.5, 5)
	wallZ(apt, "Divisoria_Frente_A", 58, 16, 4)
	wallZ(apt, "Divisoria_Frente_B", 70.5, 16, 7)
	wallX(apt, "Divisoria_Servico_A", 66, 7, 2)
	wallX(apt, "Divisoria_Servico_B", 66, 14.5, 5)
	wallX(apt, "Divisoria_Servico_C", 66, 23.5, 5)

	-- Sala de estar: sofá, mesa do telefone, estante e fotografia pessoal.
	part(apt, "Tapete_Sala", Vector3.new(11, 0.06, 7), pos(43, 0.29, 13), Color3.fromRGB(72, 57, 46), Enum.Material.Fabric, 0.04, false)
	local sofa = part(apt, "Sofa_304", Vector3.new(7.8, 2.15, 2.65), pos(40.5, 1.35, 15), Color3.fromRGB(63, 59, 54), Enum.Material.Fabric)
	part(apt, "Encosto_Sofa", Vector3.new(7.8, 2.5, 0.55), sofa.Position + Vector3.new(0, 0.9, 1.15), Color3.fromRGB(52, 48, 44), Enum.Material.Fabric)
	for _, x in ipairs({ 36.8, 44.2 }) do part(apt, "Braco_Sofa", Vector3.new(0.52, 1.65, 2.65), pos(x, 1.5, 15), COLORS.fabric, Enum.Material.Fabric) end
	for _, x in ipairs({ 38.3, 40.5, 42.7 }) do part(apt, "Almofada_Sofa", Vector3.new(1.8, 0.35, 1.85), pos(x, 2.6, 14.8), Color3.fromRGB(83, 74, 63), Enum.Material.Fabric, 0, false) end
	local tableTop = part(apt, "Mesa_Telefone", Vector3.new(4.4, 0.2, 2.8), pos(46.2, 2.15, 11), COLORS.wood, Enum.Material.WoodPlanks)
	for _, offset in ipairs({ Vector3.new(-1.8, -1.05, -1), Vector3.new(1.8, -1.05, -1), Vector3.new(-1.8, -1.05, 1), Vector3.new(1.8, -1.05, 1) }) do
		part(apt, "Perna_Mesa_Telefone", Vector3.new(0.2, 2.1, 0.2), tableTop.Position + offset, COLORS.wood, Enum.Material.Wood)
	end
	part(apt, "Telefone_304", Vector3.new(1.2, 0.5, 0.85), pos(46.2, 2.5, 11), COLORS.wallDark, Enum.Material.SmoothPlastic)
	part(apt, "Disco_Telefone", Vector3.new(0.72, 0.08, 0.72), pos(46.2, 2.78, 11), Color3.fromRGB(119, 103, 82), Enum.Material.SmoothPlastic, 0, false, Enum.PartType.Cylinder)
	anchor(apt, "Atender_Telefone_304", 46.2, 3.15, 11, "C2_Phone", "Examinar", "Telefone 304", 0.6)
	part(apt, "Caderno_Equipe", Vector3.new(1.2, 0.14, 0.9), pos(48.2, 2.35, 11.5), Color3.fromRGB(71, 57, 44), Enum.Material.Fabric)
	anchor(apt, "Confirmar_Registro_304", 48.2, 3.05, 11.5, "C2_Report", "Registrar", "Caderno de campo", 0.5)
	part(apt, "Estante_Sala", Vector3.new(0.45, 6.5, 6), pos(37, 3.25, 22), COLORS.wood, Enum.Material.WoodPlanks)
	for index = 1, 5 do part(apt, "Prateleira_Sala", Vector3.new(2.8, 0.18, 5.7), pos(38.5, 0.9 + index * 1.05, 22), COLORS.woodLight, Enum.Material.Wood) end
	part(apt, "Aparador_Fotografia", Vector3.new(2.7, 2.3, 1.7), pos(46, 1.15, 18.8), COLORS.wood, Enum.Material.WoodPlanks)
	part(apt, "Tampo_Aparador_Fotografia", Vector3.new(2.85, 0.16, 1.85), pos(46, 2.38, 18.8), COLORS.woodLight, Enum.Material.Wood)
	document(apt, "Fotografia_304_C2", "FOTOGRAFIA", "A moradora e o interfone.", 46, 18.8, "C2_Photo", 2.5)

	-- Cozinha: bancada, geladeira, pia, fogão e a chave de serviço.
	part(apt, "Piso_Cozinha", Vector3.new(10, 0.07, 9), pos(61, 0.3, 10.5), Color3.fromRGB(91, 84, 75), Enum.Material.Marble, 0.02, false)
	counter(apt, "Bancada_Cozinha", 61, 7.8, 8)
	part(apt, "Armarios_Superiores_Cozinha", Vector3.new(8, 2.4, 0.8), pos(61, 7.4, 6.9), COLORS.wood, Enum.Material.WoodPlanks)
	part(apt, "Geladeira_304", Vector3.new(2.7, 6.4, 2.8), pos(58, 3.2, 12.6), Color3.fromRGB(110, 112, 108), Enum.Material.Metal)
	part(apt, "Puxador_Geladeira", Vector3.new(0.12, 2.5, 0.15), pos(59.25, 3.5, 11.15), Color3.fromRGB(174, 165, 147), Enum.Material.Metal, 0, false)
	part(apt, "Cuba_Pia", Vector3.new(2, 0.16, 1), pos(59, 2.4, 7.7), Color3.fromRGB(89, 96, 96), Enum.Material.Metal, 0, false)
	part(apt, "Fogao_304", Vector3.new(2.2, 0.22, 1.7), pos(63.4, 2.4, 7.7), COLORS.metal, Enum.Material.Metal)
	for _, x in ipairs({ 62.8, 64 }) do for _, z in ipairs({ 7.2, 8.2 }) do part(apt, "Queimador_Fogao", Vector3.new(0.65, 0.12, 0.65), pos(x, 2.57, z), Color3.fromRGB(32, 32, 30), Enum.Material.Metal, 0, false, Enum.PartType.Cylinder) end end
	local cup = part(apt, "Copo_Cozinha", Vector3.new(0.42, 0.65, 0.42), pos(62, 2.72, 8), Color3.fromRGB(116, 105, 87), Enum.Material.SmoothPlastic, 0, false, Enum.PartType.Cylinder)
	prompt(cup, "Examinar_Copo", "C2_KitchenObject", "Examinar", "Copo com marca de batom", 0.25)
	part(apt, "Gaveteiro_Cozinha", Vector3.new(3.2, 2.1, 1.6), pos(62, 1.05, 10.5), COLORS.wood, Enum.Material.WoodPlanks)
	local drawer = part(apt, "Frente_Gaveta_Chave", Vector3.new(2.7, 0.55, 0.14), pos(62, 1.65, 9.66), COLORS.woodLight, Enum.Material.Wood)
	part(apt, "Puxador_Gaveta_Chave", Vector3.new(0.48, 0.1, 0.12), pos(62, 1.65, 9.55), Color3.fromRGB(147, 112, 71), Enum.Material.Metal, 0, false)
	part(apt, "Chave_Servico_304", Vector3.new(0.95, 0.14, 0.16), pos(62.5, 2.25, 9.45), Color3.fromRGB(170, 132, 72), Enum.Material.Metal, 0, false)
	anchor(apt, "Gaveta_Chave_304", 62, 2.4, 9.2, "C2_ServiceKey", "Abrir gaveta", "Chave de serviço", 0.55)
	addJack(apt, "A", 63.5, 13.4)

	-- Quarto: cama, criado-mudo, guarda-roupa e planta dobrada.
	part(apt, "Tapete_Quarto", Vector3.new(7.5, 0.06, 6.5), pos(60.5, 0.29, 21.5), Color3.fromRGB(77, 66, 56), Enum.Material.Fabric, 0.05, false)
	part(apt, "Estrado_Cama_304", Vector3.new(5.5, 1.1, 7.2), pos(58.5, 0.82, 22.2), COLORS.wood, Enum.Material.WoodPlanks)
	part(apt, "Colchao_Cama_304", Vector3.new(5.3, 0.68, 7), pos(58.5, 1.7, 22.2), Color3.fromRGB(155, 148, 132), Enum.Material.Fabric)
	part(apt, "Cobertor_Cama_304", Vector3.new(5.35, 0.22, 4.5), pos(58.5, 2.12, 21.1), Color3.fromRGB(89, 91, 86), Enum.Material.Fabric, 0, false)
	part(apt, "Cabeceira_Cama_304", Vector3.new(5.7, 2.4, 0.35), pos(58.5, 1.6, 25.5), COLORS.wood, Enum.Material.Wood)
	part(apt, "Criado_Mudo_304", Vector3.new(2, 2.1, 1.8), pos(63.6, 1.05, 24), COLORS.wood, Enum.Material.WoodPlanks)
	part(apt, "GuardaRoupa_304", Vector3.new(2.5, 7.4, 3.2), pos(63.2, 3.7, 18.4), COLORS.wood, Enum.Material.WoodPlanks)
	document(apt, "Planta_Circuito_304", "PLANTA", "Cozinha + serviço = retorno.", 61, 19, "C2_Wiring", 2.12)

	-- Banheiro: louça, cuba, espelho manchado e origem aparente do tom.
	part(apt, "Piso_Banheiro", Vector3.new(8, 0.07, 9), pos(70, 0.3, 21), Color3.fromRGB(102, 98, 90), Enum.Material.Marble, 0.03, false)
	local vanity = part(apt, "Gabinete_Banheiro", Vector3.new(3.8, 2, 1.8), pos(70.2, 1, 17.8), COLORS.wood, Enum.Material.WoodPlanks)
	part(apt, "Cuba_Banheiro", Vector3.new(2.3, 0.28, 1.4), vanity.Position + Vector3.new(0, 1.15, -0.1), Color3.fromRGB(163, 158, 145), Enum.Material.Marble, 0, false)
	part(apt, "Espelho_Manchado", Vector3.new(3.5, 3.2, 0.12), pos(70.2, 5, 17.05), Color3.fromRGB(93, 103, 103), Enum.Material.Glass, 0.18, false)
	part(apt, "Sanitario_304", Vector3.new(1.6, 2.1, 2.3), pos(68.2, 1.05, 23), Color3.fromRGB(155, 151, 140), Enum.Material.Marble)
	part(apt, "Caixa_Sanitario", Vector3.new(1.7, 1.4, 0.75), pos(68.2, 2.7, 24.1), Color3.fromRGB(155, 151, 140), Enum.Material.Marble)
	part(apt, "Base_Chuveiro", Vector3.new(3.1, 0.25, 3.2), pos(72, 0.48, 23), Color3.fromRGB(111, 108, 99), Enum.Material.Marble)
	part(apt, "Cortina_Chuveiro", Vector3.new(0.08, 7.2, 3), pos(70.4, 4.1, 23), Color3.fromRGB(105, 102, 94), Enum.Material.Fabric, 0.2, false)
	anchor(apt, "Derivacao_Espelho", 71.8, 3.2, 17.6, "C2_Trace", "Seguir sinal", "Atrás do espelho", 0.7)

	-- Lavanderia: máquina, prateleira de limpeza e quadro de derivação.
	part(apt, "Piso_Lavanderia", Vector3.new(8, 0.07, 9), pos(70, 0.3, 10.5), Color3.fromRGB(90, 87, 80), Enum.Material.Marble, 0.03, false)
	local washer = part(apt, "Lavadora_304", Vector3.new(3.2, 4.7, 3), pos(71.4, 2.65, 8.1), Color3.fromRGB(91, 97, 97), Enum.Material.Metal)
	part(apt, "Aro_Lavadora", Vector3.new(1.75, 1.75, 0.14), washer.Position + Vector3.new(0, 0.15, -1.58), Color3.fromRGB(54, 61, 63), Enum.Material.Glass, 0.1, false, Enum.PartType.Cylinder)
	part(apt, "Prateleira_Lavanderia", Vector3.new(0.35, 6.8, 5.2), pos(73, 3.4, 12.8), COLORS.metal, Enum.Material.CorrodedMetal)
	for index = 1, 3 do part(apt, "Prateleira_Limpeza", Vector3.new(2.2, 0.18, 4.7), pos(71.9, 1 + index * 1.65, 12.8), COLORS.wood, Enum.Material.WoodPlanks) end
	part(apt, "Quadro_Derivacao_304", Vector3.new(2, 3.2, 0.32), pos(68.7, 4.3, 14.8), COLORS.metal, Enum.Material.CorrodedMetal)
	part(apt, "Visor_Quadro_304", Vector3.new(1.2, 0.75, 0.12), pos(68.7, 4.55, 14.58), Color3.fromRGB(25, 27, 27), Enum.Material.Glass)
	anchor(apt, "Ativar_Derivacao_304", 68.7, 3.8, 14, "C2_Breaker", "Restaurar circuito", "Quadro de derivação", 0.8)
	addJack(apt, "B", 71.5, 13.4)

	for _, room in ipairs({ { "Sala", 43, 11.5 }, { "Cozinha", 61, 11.5 }, { "Lavanderia", 70, 11.5 }, { "Quarto", 61, 23 }, { "Banheiro", 70, 23 } }) do
		light(apt, "Luz_" .. room[1], room[2], room[3])
	end

	doorOpen = false
	Chapter2Map.SetPower(false)
	Chapter2Map.SetDoor(true)
	return world, spawn
end

function Chapter2Map.Build()
	return buildWorld()
end

function Chapter2Map.GetPrompts()
	return prompts
end

function Chapter2Map.SetPower(enabled)
	for _, record in ipairs(lights) do
		record.point.Brightness = enabled and 1.2 or 0
		record.point.Range = enabled and 17 or 0
		record.bulb.Color = enabled and COLORS.amber or Color3.fromRGB(30, 30, 28)
		record.bulb.Material = enabled and Enum.Material.Neon or Enum.Material.Glass
	end
	if world then world:SetAttribute("PowerOn", enabled) end
end

function Chapter2Map.SetJack(side, enabled)
	local record = jacks[side]
	if not record then return false end
	record.bulb.Color = enabled and Color3.fromRGB(153, 81, 53) or Color3.fromRGB(44, 39, 34)
	record.light.Brightness = enabled and 0.55 or 0
	return true
end

function Chapter2Map.SetDoor(open)
	if not door then return false end
	doorOpen = open
	if doorPrompt then doorPrompt.ActionText = open and "Fechar" or "Abrir" end
	door.CanCollide = not open
	door.Transparency = open and 1 or 0
	local target = doorClosedCFrame * CFrame.Angles(0, math.rad(open and 82 or 0), 0)
	TweenService:Create(door, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = target }):Play()
	return true
end

function Chapter2Map.GetDoorState()
	return doorOpen
end

return Chapter2Map
