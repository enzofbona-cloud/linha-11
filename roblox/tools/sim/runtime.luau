-- Monta a árvore de scripts como o Rojo monta no lugar, e oferece ajudantes de teste.
local E = SIM.env
local game = E.game
local workspace = E.workspace
local moduleCache, moduleKey = {}, {}
local fakeRequire

local function fakeWarn(...)
	local parts = {}
	for i = 1, select("#", ...) do parts[i] = tostring((select(i, ...))) end
	table.insert(SIM.log, "warn: " .. table.concat(parts, " "))
end

local function callSource(key, inst)
	return SOURCES[key](inst, fakeRequire, E.game, E.workspace, E.Instance, E.Vector3, E.CFrame, E.Color3, E.UDim, E.UDim2,
		E.Vector2, E.TweenInfo, E.ColorSequence, E.ColorSequenceKeypoint, E.NumberSequence, E.NumberSequenceKeypoint,
		E.NumberRange, E.Enum, E.typeof, E.os, E.task, fakeWarn)
end

fakeRequire = function(inst)
	local key = moduleKey[inst]
	if not key then error("require de algo que não é módulo: " .. tostring(inst), 2) end
	if not moduleCache[key] then
		moduleCache[key] = { value = callSource(key, inst) }
	end
	return moduleCache[key].value
end

local function folder(parent, name)
	local item = SIM.newInstance("Folder")
	item.Name = name
	item.Parent = parent
	return item
end

local scriptInstances = {}
local shared = folder(game:GetService("ReplicatedStorage"), "Shared")
local server = folder(game:GetService("ServerScriptService"), "Server")
local starter = folder(game:GetService("StarterPlayer"), "StarterPlayerScripts")
for key in pairs(SOURCES) do
	local dir, name = string.match(key, "^(%w+)/(.+)$")
	local kind, parent = "ModuleScript", shared
	if dir == "server" then parent = server end
	if dir == "client" then parent = starter; kind = "LocalScript" end
	if string.match(name, "%.server$") then kind = "Script"; name = string.gsub(name, "%.server$", "") end
	if string.match(name, "%.client$") then kind = "LocalScript"; name = string.gsub(name, "%.client$", "") end
	local inst = SIM.newInstance(kind)
	inst.Name = name
	inst.Parent = parent
	moduleKey[inst] = key
	scriptInstances[key] = inst
end

local Players = game:GetService("Players")
local T = { failures = {}, checks = 0 }

function T.startServer()
	SIM.runThread(function() callSource("server/GameService.server", scriptInstances["server/GameService.server"]) end)
	SIM.advance(0.2)
end

function T.addPlayer(name)
	local player = SIM.newInstance("Player")
	player.Name = name
	player.UserId = 1000 + #Players:GetPlayers()
	rawset(player, "__inbox", {})
	local playerGui = SIM.newInstance("PlayerGui")
	playerGui.Name = "PlayerGui"
	playerGui.Parent = player
	player.Parent = Players
	T.spawnCharacter(player)
	Players.PlayerAdded:Fire(player)
	SIM.advance(0.2)
	return player
end

function T.spawnCharacter(player)
	local old = player.Character
	if old then old:Destroy() end
	local character = SIM.newInstance("Model")
	character.Name = player.Name
	for _, partName in ipairs({ "HumanoidRootPart", "Head", "Torso" }) do
		local part = SIM.newInstance("Part")
		part.Name = partName
		part.Parent = character
	end
	local humanoid = SIM.newInstance("Humanoid")
	humanoid.Name = "Humanoid"
	humanoid.Parent = character
	character.Parent = workspace
	player.Character = character
	player.CharacterAdded:Fire(character)
	return character
end

function T.removePlayer(player)
	Players.PlayerRemoving:Fire(player)
	if player.Character then player.Character:Destroy() end
	player.Parent = nil
	SIM.advance(0.2)
end

function T.startClient(player)
	SIM.localPlayer = player
	Players.LocalPlayer = player
	SIM.runThread(function() callSource("client/Client.client", scriptInstances["client/Client.client"]) end)
	SIM.advance(1.5)
end

function T.remote() return game:GetService("ReplicatedStorage"):FindFirstChild("Linha11Remote") end

-- Envia uma ação ao servidor em nome de um jogador (como se viesse do cliente dele).
function T.send(player, action, value)
	SIM.advance(0.2)
	T.remote().OnServerEvent:Fire(player, action, value)
	SIM.advance(0.1)
end

function T.gui(player, path)
	local node = player.PlayerGui
	for name in string.gmatch(path, "[^/]+") do
		node = node and node:FindFirstChild(name)
	end
	return node
end

function T.click(player, path)
	local node = T.gui(player, path)
	if not node then
		T.fail("botão não existe: " .. path)
		return false
	end
	SIM.advance(0.2)
	node.Activated:Fire()
	SIM.advance(0.2)
	return true
end

function T.findPrompt(actionId)
	for _, item in ipairs(workspace:GetDescendants()) do
		if rawget(item, "__class") == "ProximityPrompt" and item:GetAttribute("ActionId") == actionId then return item end
	end
	return nil
end

function T.moveTo(player, position)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then root.CFrame = E.CFrame.new(position) end
end

-- Leva o jogador até o objeto e aperta E.
function T.use(player, actionId)
	local prompt = T.findPrompt(actionId)
	if not prompt then
		T.fail("não existe interação '" .. actionId .. "' no mapa")
		return false
	end
	if prompt.Enabled == false then
		T.fail("interação '" .. actionId .. "' está desativada")
		return false
	end
	T.moveTo(player, prompt.Parent.Position)
	SIM.advance(0.3)
	prompt.Triggered:Fire(player)
	SIM.advance(0.2)
	return true
end

function T.events(player, name)
	local out = {}
	for _, event in ipairs(rawget(player, "__inbox")) do
		if event.name == name then table.insert(out, event.data) end
	end
	return out
end

function T.lastEvent(player, name)
	local list = T.events(player, name)
	return list[#list]
end

function T.clearInbox(player) table.clear(rawget(player, "__inbox")) end

function T.lastMessage(player)
	local event = T.lastEvent(player, "Message")
	return event and event.text or "(nenhuma mensagem)"
end

function T.state(player) return T.lastEvent(player, "MissionState") or {} end

function T.fail(text)
	table.insert(T.failures, (T.context or "") .. text)
end

function T.check(condition, text)
	T.checks += 1
	if not condition then T.fail(text) end
	return condition
end

function T.finish()
	for _, line in ipairs(SIM.log) do print(line) end
	for _, err in ipairs(SIM.errors) do print("ERRO DE EXECUCAO: " .. err) end
	for _, failure in ipairs(T.failures) do print("FALHA: " .. failure) end
	print(string.format("RESULTADO: %d verificacoes, %d falhas, %d erros de execucao", T.checks, #T.failures, #SIM.errors))
end
