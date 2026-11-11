local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")

local Story = require(ReplicatedStorage.Shared.Story)
local MonetizationConfig = require(ReplicatedStorage.Shared.MonetizationConfig)
local MapBuilder = require(script.Parent.MapBuilder)
local ListenerAI = require(script.Parent.ListenerAI)

local remote = ReplicatedStorage:FindFirstChild("Linha11Remote")
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "Linha11Remote"
	remote.Parent = ReplicatedStorage
end

local world, spawnPoint = MapBuilder.Build()
MapBuilder.SetPower(false)

local mission = {
	started = false,
	key = false,
	fuse = false,
	power = false,
	clues = { Clue03 = false, Clue1 = false, Clue7 = false },
	archiveOpen = false,
	tape = false,
	phone = false,
	crowbar = false,
	relayOpen = false,
	relay = { A = nil, B = nil },
	ending = nil,
	stage = 0,
}
local remoteCooldowns = {}
local noiseCooldowns = {}
local purchaseCooldowns = {}

local function startedPlayers()
	local result = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player:GetAttribute("Linha11Started") then
			table.insert(result, player)
		end
	end
	return result
end

local function makeSnapshot()
	return {
		stage = mission.stage,
		objective = Story.GetObjective(mission.stage),
		power = mission.power,
		key = mission.key,
		fuse = mission.fuse,
		clues = {
			Clue03 = mission.clues.Clue03,
			Clue1 = mission.clues.Clue1,
			Clue7 = mission.clues.Clue7,
		},
		archiveOpen = mission.archiveOpen,
		tape = mission.tape,
		phone = mission.phone,
		crowbar = mission.crowbar,
		relayOpen = mission.relayOpen,
		relayA = mission.relay.A ~= nil,
		relayB = mission.relay.B ~= nil,
		ending = mission.ending,
	}
end

local function send(player, eventName, payload)
	if player and player.Parent == Players then
		remote:FireClient(player, eventName, payload)
	end
end

local function broadcast(eventName, payload)
	for _, player in ipairs(startedPlayers()) do
		remote:FireClient(player, eventName, payload)
	end
end

local function tell(player, text, kind)
	send(player, "Message", { text = text, kind = kind or "story" })
end

local function tellAll(text, kind)
	broadcast("Message", { text = text, kind = kind or "story" })
end

local function updateStage()
	if not mission.started then
		mission.stage = 0
	elseif not mission.key then
		mission.stage = 1
	elseif not mission.fuse then
		mission.stage = 2
	elseif not (mission.clues.Clue03 and mission.clues.Clue1 and mission.clues.Clue7) then
		mission.stage = 3
	elseif not mission.power then
		mission.stage = 4
	elseif not mission.archiveOpen then
		mission.stage = 5
	elseif not mission.tape or not mission.phone then
		mission.stage = 6
	elseif not mission.crowbar or not mission.relayOpen then
		mission.stage = 7
	elseif not (mission.relay.A and mission.relay.B) then
		mission.stage = 8
	elseif not mission.ending then
		mission.stage = 9
	else
		mission.stage = 10
	end
end

local function publishState()
	updateStage()
	broadcast("MissionState", makeSnapshot())
end

local function playerNear(player, position, maxDistance)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return root and (root.Position - position).Magnitude <= maxDistance
end

local function teleportToStart(player)
	local character = player.Character
	if not character then
		return
	end
	local playerPosition = spawnPoint.Position + Vector3.new(0, 3.4, 0)
	character:PivotTo(CFrame.lookAt(playerPosition, playerPosition + Vector3.xAxis))
	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if root then
		root.Anchored = false
	end
	if humanoid then
		humanoid.WalkSpeed = 16
		humanoid.JumpPower = 42
		humanoid.Health = math.max(humanoid.Health, humanoid.MaxHealth * 0.45)
	end
end

local function startPlayer(player)
	mission.started = true
	player:SetAttribute("Linha11Started", true)
	player:SetAttribute("Linha11Hidden", false)
	player:SetAttribute("Linha11IntroPending", true)
	updateStage()
	local character = player.Character
	if character then
		teleportToStart(player)
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0
		end
	end
	send(player, "StartGame", {
		prologue = Story.Prologue,
		state = makeSnapshot(),
	})
	broadcast("MissionState", makeSnapshot())
end

local function setCharacterVisibility(character, hidden)
	for _, item in ipairs(character:GetDescendants()) do
		if item:IsA("BasePart") and item.Name ~= "HumanoidRootPart" then
			if hidden then
				item:SetAttribute("Linha11OriginalTransparency", item.Transparency)
				item.Transparency = 0.88
			else
				local previous = item:GetAttribute("Linha11OriginalTransparency")
				if previous ~= nil then
					item.Transparency = previous
					item:SetAttribute("Linha11OriginalTransparency", nil)
				end
			end
		end
	end
end

local function handleCatch(player)
	if not player:GetAttribute("Linha11Started") or player:GetAttribute("Linha11Hidden") then
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:TakeDamage(28)
	end
	teleportToStart(player)
	send(player, "Caught", { text = "O Ouvinte encontrou você. A equipe recuou para a entrada; a investigação continua." })
end

local ai = ListenerAI.new(world, function()
	return Players:GetPlayers()
end, handleCatch)

local function setPlayerPass(player, passKey, owned)
	if passKey == "AmberLight" then
		player:SetAttribute("Linha11AmberLight", owned)
	elseif passKey == "AuroraBadge" then
		player:SetAttribute("Linha11AuroraBadge", owned)
	end
end

local function applyBadge(player)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if not head then
		return
	end
	local old = head:FindFirstChild("Linha11SupporterBadge")
	if old then
		old:Destroy()
	end
	if not player:GetAttribute("Linha11AuroraBadge") then
		return
	end
	local badge = Instance.new("BillboardGui")
	badge.Name = "Linha11SupporterBadge"
	badge.Size = UDim2.fromOffset(145, 28)
	badge.StudsOffset = Vector3.new(0, 2.3, 0)
	badge.AlwaysOnTop = true
	badge.MaxDistance = 45
	badge.Adornee = head
	badge.Parent = head
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(37, 30, 23)
	label.BackgroundTransparency = 0.18
	label.BorderSizePixel = 0
	label.Text = "APOIADOR AURORA"
	label.TextColor3 = Color3.fromRGB(224, 183, 113)
	label.TextStrokeTransparency = 0.65
	label.Font = Enum.Font.Garamond
	label.TextSize = 15
	label.Parent = badge
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 5)
	corner.Parent = label
end

local function loadPassOwnership(player)
	for key, pass in pairs(MonetizationConfig.Passes) do
		setPlayerPass(player, key, false)
		if pass.id and pass.id > 0 then
			task.spawn(function()
				local ok, owns = pcall(function()
					return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.id)
				end)
				if ok and player.Parent == Players then
					setPlayerPass(player, key, owns == true)
					if key == "AuroraBadge" then
						applyBadge(player)
					end
				end
			end)
		end
	end
end

local function setupPlayer(player)
	if player:GetAttribute("Linha11Initialized") then
		return
	end
	player:SetAttribute("Linha11Initialized", true)
	player:SetAttribute("Linha11Started", false)
	player:SetAttribute("Linha11Hidden", false)
	player:SetAttribute("Linha11IntroPending", false)
	loadPassOwnership(player)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("HumanoidRootPart", 8)
		task.wait(0.15)
		if player:GetAttribute("Linha11Started") then
			teleportToStart(player)
			if player:GetAttribute("Linha11IntroPending") then
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid.WalkSpeed = 0
					humanoid.JumpPower = 0
				end
			end
		end
		applyBadge(player)
	end)
	if player.Character then
		applyBadge(player)
	end
end

Players.PlayerAdded:Connect(setupPlayer)
for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, wasPurchased)
	if not wasPurchased then
		return
	end
	for key, pass in pairs(MonetizationConfig.Passes) do
		if pass.id == passId then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
			end)
			if ok and owns then
				setPlayerPass(player, key, true)
				if key == "AuroraBadge" then
					applyBadge(player)
				end
				send(player, "Message", { text = pass.name .. " liberado. Obrigado por apoiar o projeto; a compra é apenas cosmética.", kind = "success" })
			end
		end
	end
end)

local function openShop(player)
	local items = {}
	for key, pass in pairs(MonetizationConfig.Passes) do
		table.insert(items, {
			key = key,
			name = pass.name,
			description = pass.description,
			enabled = pass.id and pass.id > 0,
			owned = key == "AmberLight" and player:GetAttribute("Linha11AmberLight") or key == "AuroraBadge" and player:GetAttribute("Linha11AuroraBadge") or false,
		})
	end
	send(player, "Shop", { items = items })
end

remote.OnServerEvent:Connect(function(player, action, value)
	if action == "Ready" then
		if player:GetAttribute("Linha11Started") then
			player:SetAttribute("Linha11IntroPending", false)
			local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if humanoid and not player:GetAttribute("Linha11Hidden") then
				humanoid.WalkSpeed = 16
				humanoid.JumpPower = 42
			end
		end
		return
	end

	local now = os.clock()
	if now - (remoteCooldowns[player] or 0) < 0.12 then
		return
	end
	remoteCooldowns[player] = now

	if action == "Start" then
		startPlayer(player)
		return
	end


	if action == "OpenShop" then
		openShop(player)
		return
	end

	if action == "Purchase" then
		local pass = MonetizationConfig.Passes[value]
		if not pass then
			return
		end
		if not pass.id or pass.id < 1 then
			tell(player, "Os cosméticos serão ativados depois que a experiência for publicada e os passes forem criados no Creator Hub.", "info")
			return
		end
		if now - (purchaseCooldowns[player] or 0) < 4 then
			return
		end
		purchaseCooldowns[player] = now
		local ok, err = pcall(function()
			MarketplaceService:PromptGamePassPurchase(player, pass.id)
		end)
		if not ok then
			warn("Falha ao abrir compra de passe:", err)
			tell(player, "Não foi possível abrir a compra agora. Tente novamente mais tarde.", "error")
		end
		return
	end

	if action == "Sprint" then
		if not player:GetAttribute("Linha11Started") or player:GetAttribute("Linha11Hidden") then
			return
		end
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = value == true and 22 or 16
		end
		return
	end

	if action == "Code" then
		if not player:GetAttribute("Linha11Started") or mission.archiveOpen then
			return
		end
		local keypadPosition = MapBuilder.GetPositionForAction("Keypad")
		if not keypadPosition or not playerNear(player, keypadPosition, 13) then
			return
		end
		if not mission.power then
			tell(player, "O teclado está sem energia. Instale o fusível no quadro do corredor.", "objective")
			return
		end
		if not (mission.clues.Clue03 and mission.clues.Clue1 and mission.clues.Clue7) then
			tell(player, "A senha está incompleta. Procure os três registros nos apartamentos 301, 302 e 305.", "objective")
			return
		end
		if typeof(value) ~= "string" or #value > 4 then
			return
		end
		if value == Story.Code then
			mission.archiveOpen = true
			MapBuilder.OpenDoor("303", true)
			tellAll("O arquivo 303 destranca. Uma chamada toca uma vez, do outro lado da porta.", "scare")
			publishState()
		else
			tell(player, "Senha incorreta. Os fragmentos apontam para 03 • 1 • 7.", "error")
		end
		return
	end

	if action == "Ending" then
		if not player:GetAttribute("Linha11Started") or mission.ending then
			return
		end
		local terminal = MapBuilder.GetPositionForAction("EndingConsole")
		if not terminal or not playerNear(player, terminal, 13) then
			return
		end
		if not (mission.relay.A and mission.relay.B) then
			return
		end
		if value ~= "Transmit" and value ~= "Cut" then
			return
		end
		mission.ending = value
		local ending = Story.Endings[value]
		broadcast("Ending", ending)
		publishState()
	end
end)

local function showDocument(player, clueKey)
	local clue = Story.Clues[clueKey]
	if clue then
		send(player, "Document", { title = clue.title, text = clue.text })
	end
end

local function handlePrompt(player, prompt)
	if not player:GetAttribute("Linha11Started") then
		tell(player, "Clique em JOGAR para entrar no turno.", "info")
		return
	end
	if not prompt.Parent or not prompt.Parent:IsA("BasePart") or not playerNear(player, prompt.Parent.Position, math.max(prompt.MaxActivationDistance + 3, 12)) then
		return
	end
	local id = prompt:GetAttribute("ActionId")
	if typeof(id) ~= "string" then
		return
	end

	if string.sub(id, 1, 5) == "Door_" then
		local roomId = string.sub(id, 6)
		if roomId == "303" and not mission.archiveOpen then
			tell(player, "O arquivo está trancado. O teclado fica ao lado da porta.", "objective")
			return
		end
		if roomId == "Repetidor" then
			if not mission.crowbar then
				tell(player, "A porta está emperrada. Encontre uma ferramenta no apartamento 304.", "objective")
				return
			end
			if not mission.relayOpen then
				mission.relayOpen = true
				MapBuilder.OpenDoor("Repetidor", true)
				ai:Ping(prompt.Parent.Position, 95)
				tellAll("O metal rasga no corredor. Algo responde do outro lado do andar.", "scare")
				publishState()
			else
				MapBuilder.OpenDoor("Repetidor", not MapBuilder.GetDoorState("Repetidor"))
			end
			return
		end
		MapBuilder.OpenDoor(roomId, not MapBuilder.GetDoorState(roomId))
		return
	end

	if string.sub(id, 1, 5) == "Hide_" then
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not root or not humanoid then
			return
		end
		local isHidden = player:GetAttribute("Linha11Hidden") == true
		if isHidden then
			player:SetAttribute("Linha11Hidden", false)
			root.Anchored = false
			humanoid.WalkSpeed = 16
			humanoid.JumpPower = 42
			setCharacterVisibility(character, false)
			tell(player, "Você saiu do esconderijo.", "info")
		else
			player:SetAttribute("Linha11Hidden", true)
			root.CFrame = CFrame.new(prompt.Parent.Position + Vector3.new(0, 0.8, 2.8))
			root.Anchored = true
			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0
			setCharacterVisibility(character, true)
			tell(player, "Você está escondido. Use E no guarda-roupa para sair.", "success")
		end
		return
	end

	if id == "StorageKey" then
		if mission.key then
			tell(player, "A chave já está com a equipe.", "info")
		else
			mission.key = true
			tellAll("Chave de manutenção encontrada no 305. A gaveta do 301 pode ser aberta.", "success")
			publishState()
		end
	elseif id == "FuseDrawer" then
		if not mission.key then
			tell(player, "A gaveta está trancada. Procure a chave no apartamento 305.", "objective")
		elseif mission.fuse then
			tell(player, "A gaveta está vazia.", "info")
		else
			mission.fuse = true
			tellAll("Fusível recuperado. O quadro geral fica no corredor.", "success")
			publishState()
		end
	elseif id == "Clue03" or id == "Clue1" or id == "Clue7" then
		if not mission.clues[id] then
			mission.clues[id] = true
			showDocument(player, id)
			local names = { Clue03 = "03", Clue1 = "1", Clue7 = "7" }
			tellAll("Fragmento da senha encontrado: " .. names[id] .. ".", "success")
			publishState()
		else
			showDocument(player, id)
		end
	elseif id == "Breaker" then
		if not mission.fuse then
			tell(player, "O quadro está vazio. Busque um fusível na gaveta do 301.", "objective")
		elseif not mission.power then
			mission.power = true
			MapBuilder.SetPower(true)
			tellAll("A energia volta ao terceiro andar. As luzes revelam marcas de dedos na parede.", "scare")
			publishState()
		else
			tell(player, "O quadro está ligado.", "info")
		end
	elseif id == "Keypad" then
		if not mission.power then
			tell(player, "O teclado está sem energia.", "objective")
		elseif not (mission.clues.Clue03 and mission.clues.Clue1 and mission.clues.Clue7) then
			tell(player, "A senha está incompleta. Procure os três registros.", "objective")
		else
			send(player, "OpenKeypad", { codeLength = 4 })
		end
	elseif id == "ArchiveTape" then
		if not mission.archiveOpen then
			tell(player, "A caixa está trancada atrás da porta 303.", "objective")
		elseif not mission.tape then
			mission.tape = true
			showDocument(player, "Tape")
			tellAll("A fita 11 foi recuperada. O registro menciona a linha telefônica do apartamento 304.", "success")
			publishState()
		else
			showDocument(player, "Tape")
		end
	elseif id == "Phone" then
		if not mission.tape then
			tell(player, "O telefone toca, mas o arquivo ainda é prioridade.", "info")
		elseif not mission.phone then
			mission.phone = true
			ai:Wake()
			ai:Ping(prompt.Parent.Position, 110)
			showDocument(player, "Phone")
			tellAll("A chamada acorda o Ouvinte. Ele reage a corridas e sons fortes; escondam-se nos cômodos.", "scare")
			publishState()
		else
			tell(player, "A linha ficou muda.", "info")
		end
	elseif id == "Crowbar" then
		if not mission.phone then
			tell(player, "A ferramenta está presa sob o armário. O telefone ainda está chamando.", "objective")
		elseif not mission.crowbar then
			mission.crowbar = true
			tellAll("Pé de cabra encontrado. Pode abrir a porta emperrada da sala do repetidor.", "success")
			publishState()
		else
			tell(player, "A equipe já tem o pé de cabra.", "info")
		end
	elseif id == "RelayA" or id == "RelayB" then
		if not mission.relayOpen then
			tell(player, "A sala do repetidor está fechada.", "objective")
		elseif mission.ending then
			tell(player, "A decisão já foi tomada.", "info")
		else
			local side = id == "RelayA" and "A" or "B"
			local other = side == "A" and "B" or "A"
			local now = os.clock()
			local otherLever = mission.relay[other]
			if otherLever and now - otherLever.time > 12 then
				mission.relay.A = nil
				mission.relay.B = nil
				MapBuilder.SetLever("RelayA", false)
				MapBuilder.SetLever("RelayB", false)
				tellAll("O mecanismo voltou à posição inicial. Ativem as alavancas com poucos segundos de diferença.", "error")
				publishState()
				return
			end
			local activeCount = #startedPlayers()
			if activeCount >= 2 and otherLever and otherLever.player == player then
				tell(player, "A outra alavanca precisa ser ativada pelo parceiro.", "objective")
				return
			end
			mission.relay[side] = { player = player, time = now }
			MapBuilder.SetLever(id, true)
			ai:Ping(prompt.Parent.Position, 80)
			if mission.relay.A and mission.relay.B and now - math.min(mission.relay.A.time, mission.relay.B.time) <= 12 then
				tellAll("As duas alavancas travaram. O repetidor está pronto; decidam o que fazer com a fita.", "success")
			else
				tellAll("Uma alavanca foi ativada. A outra precisa ser acionada em até 12 segundos.", "objective")
			end
			publishState()
		end
	elseif id == "EndingConsole" then
		if mission.relay.A and mission.relay.B then
			send(player, "OpenEnding", {
				transmit = Story.Endings.Transmit.title,
				cut = Story.Endings.Cut.title,
			})
		else
			tell(player, "Ativem as duas alavancas primeiro.", "objective")
		end
	elseif id == "Photo304" then
		showDocument(player, "Photo304")
	elseif id == "LogPlantao" then
		showDocument(player, "LogPlantao")
	end
end

for _, prompt in ipairs(MapBuilder.GetPrompts()) do
	prompt.Triggered:Connect(function(player)
		handlePrompt(player, prompt)
	end)
end

RunService.Heartbeat:Connect(function()
	local now = os.clock()
	for _, player in ipairs(startedPlayers()) do
		if not player:GetAttribute("Linha11Hidden") then
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if root and humanoid and humanoid.WalkSpeed >= 20 and root.AssemblyLinearVelocity.Magnitude > 13 and now - (noiseCooldowns[player] or 0) > 1.8 then
				noiseCooldowns[player] = now
				ai:Ping(root.Position, 75)
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	remoteCooldowns[player] = nil
	noiseCooldowns[player] = nil
	purchaseCooldowns[player] = nil
	for _, side in ipairs({ "A", "B" }) do
		if mission.relay[side] and mission.relay[side].player == player then
			mission.relay[side] = nil
		end
	end
end)

updateStage()



