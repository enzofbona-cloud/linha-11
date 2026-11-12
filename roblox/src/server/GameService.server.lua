local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")

local Story = require(ReplicatedStorage.Shared.Story)
local Chapter2Story = require(ReplicatedStorage.Shared.Chapter2Story)
local Chapter3Story = require(ReplicatedStorage.Shared.Chapter3Story)
local LaterChapterStory = require(ReplicatedStorage.Shared.LaterChapterStory)
local MonetizationConfig = require(ReplicatedStorage.Shared.MonetizationConfig)
local MapBuilder = require(script.Parent.MapBuilder)
local Chapter2Map = require(script.Parent.Chapter2Map)
local Chapter3Map = require(script.Parent.Chapter3Map)
local LaterChapterMap = require(script.Parent.LaterChapterMap)
local ListenerAI = require(script.Parent.ListenerAI)

local remote = ReplicatedStorage:FindFirstChild("Linha11Remote")
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "Linha11Remote"
	remote.Parent = ReplicatedStorage
end

local world, spawnPoint = MapBuilder.Build()
MapBuilder.SetPower(false)
local chapter2World, chapter2Spawn = Chapter2Map.Build()
local chapter3World, chapter3Spawn = Chapter3Map.Build()
local laterWorlds, laterSpawns, laterPrompts = LaterChapterMap.BuildAll()

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
local chapter2Mission = {
	started = false,
	phone = false,
	photo = false,
	serviceKey = false,
	wiring = false,
	power = false,
	jacks = { A = nil, B = nil },
	jacksConnected = false,
	traced = false,
	complete = false,
	stage = 0,
}
local chapter3Mission = {
	started=false, phone=false, log=false, route=false, controlKey=false,
	switches={A=nil,B=nil}, power=false, elevatorOpened=false, recorder=false, complete=false, stage=0,
}
local laterMissions, laterAis = {}, {}
for chapterId=4,12 do
	laterMissions[chapterId]={started=false,found={},puzzleStep=0,lastPuzzlePlayer=nil,puzzleComplete=false,complete=false,choice=nil,batteryLift={A=nil,B=nil},batteryRaised=false,batteryMoved=false}
end
local ensureLaterAI
local activeChapterId = nil
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
	if activeChapterId and activeChapterId >= 4 then
		local m=laterMissions[activeChapterId]
		local foundCount=0
		for _,found in pairs(m.found) do if found then foundCount+=1 end end
		return {chapterId=activeChapterId,stage=m.stage,objective=LaterChapterStory.Get(activeChapterId).Objectives[m.stage],foundCount=foundCount,puzzleStep=m.puzzleStep,puzzleComplete=m.puzzleComplete,batteryRaised=m.batteryRaised,batteryMoved=m.batteryMoved,choice=m.choice,complete=m.complete}
	end
	if activeChapterId == 3 then
		return {chapterId=3,stage=chapter3Mission.stage,objective=Chapter3Story.GetObjective(chapter3Mission.stage),phone=chapter3Mission.phone,log=chapter3Mission.log,route=chapter3Mission.route,controlKey=chapter3Mission.controlKey,breakerA=chapter3Mission.switches.A~=nil,breakerB=chapter3Mission.switches.B~=nil,power=chapter3Mission.power,elevatorOpened=chapter3Mission.elevatorOpened,recorder=chapter3Mission.recorder,complete=chapter3Mission.complete}
	end
	if activeChapterId == 2 then
		return {
			chapterId = 2,
			stage = chapter2Mission.stage,
			objective = Chapter2Story.GetObjective(chapter2Mission.stage),
			phone = chapter2Mission.phone,
			photo = chapter2Mission.photo,
			serviceKey = chapter2Mission.serviceKey,
			wiring = chapter2Mission.wiring,
			power = chapter2Mission.power,
			jackA = chapter2Mission.jacks.A ~= nil,
			jackB = chapter2Mission.jacks.B ~= nil,
			jacksConnected = chapter2Mission.jacksConnected,
			traced = chapter2Mission.traced,
			complete = chapter2Mission.complete,
		}
	end
	return {
		chapterId = 1,
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
	if activeChapterId and activeChapterId >= 4 then
		local m=laterMissions[activeChapterId]
		local foundCount=0
		for _,found in pairs(m.found) do if found then foundCount+=1 end end
		if not m.started then m.stage=0
		elseif foundCount<3 then m.stage=1
		elseif not m.puzzleComplete then m.stage=m.puzzleStep>0 and 3 or 2
		elseif not m.complete then m.stage=4
		else m.stage=5 end
		return
	end
	if activeChapterId == 3 then
		if not chapter3Mission.started then chapter3Mission.stage=0
		elseif not chapter3Mission.phone then chapter3Mission.stage=1
		elseif not (chapter3Mission.log and chapter3Mission.route and chapter3Mission.controlKey) then chapter3Mission.stage=2
		elseif not chapter3Mission.power then chapter3Mission.stage=3
		elseif not chapter3Mission.recorder then chapter3Mission.stage=4
		elseif not chapter3Mission.complete then chapter3Mission.stage=5
		else chapter3Mission.stage=6 end
		return
	end
	if activeChapterId == 2 then
		if not chapter2Mission.started then
			chapter2Mission.stage = 0
		elseif not chapter2Mission.phone then
			chapter2Mission.stage = 1
		elseif not (chapter2Mission.photo and chapter2Mission.serviceKey and chapter2Mission.wiring) then
			chapter2Mission.stage = 2
		elseif not chapter2Mission.power then
			chapter2Mission.stage = 3
		elseif not chapter2Mission.jacksConnected then
			chapter2Mission.stage = 4
		elseif not chapter2Mission.traced then
			chapter2Mission.stage = 5
		elseif not chapter2Mission.complete then
			chapter2Mission.stage = 6
		else
			chapter2Mission.stage = 7
		end
		return
	end
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

local function teleportToStart(player, requestedSpawn)
	local character = player.Character
	if not character then
		return
	end
	local chapter=player:GetAttribute("Linha11Chapter")
	local laterSpawn=chapter and chapter>=4 and laterSpawns[chapter] or nil
	local defaultSpawn=chapter==2 and chapter2Spawn or (chapter==3 and chapter3Spawn or (laterSpawn or spawnPoint))
	local start=requestedSpawn or defaultSpawn
	local playerPosition = start.Position + Vector3.new(0, 3.4, 0)
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

local function startPlayer(player, requestedChapterId)
	local chapterId = typeof(requestedChapterId) == "number" and math.floor(requestedChapterId) or 1
	if chapterId < 1 or chapterId > 12 then
		tell(player, "Esse capítulo ainda está em desenvolvimento.", "info")
		return
	end
	if activeChapterId and activeChapterId ~= chapterId then
		tell(player, "A sessão já começou em outro capítulo. Escolham o mesmo capítulo para jogar juntos.", "error")
		return
	end
	activeChapterId = chapterId
	if chapterId>=4 then ensureLaterAI(chapterId); laterMissions[chapterId].started=true
	elseif chapterId==2 then chapter2Mission.started=true
	elseif chapterId==3 then chapter3Mission.started=true
	else mission.started=true end
	player:SetAttribute("Linha11Chapter", chapterId)
	player:SetAttribute("Linha11Started", true)
	player:SetAttribute("Linha11Hidden", false)
	player:SetAttribute("Linha11IntroPending", true)
	updateStage()
	local character = player.Character
	if character then
		local laterSpawn=chapterId>=4 and laterSpawns[chapterId] or nil
		local chapterSpawn=chapterId==2 and chapter2Spawn or (chapterId==3 and chapter3Spawn or (laterSpawn or spawnPoint))
		teleportToStart(player,chapterSpawn)
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0
		end
	end
	send(player, "StartGame", {
		chapterId = chapterId,
		chapterTitle=chapterId==2 and Chapter2Story.Title or (chapterId==3 and Chapter3Story.Title or (chapterId>=4 and LaterChapterStory.Get(chapterId).Title or "Distrito 11 • Andar 3")),
		prologue=chapterId==2 and Chapter2Story.Prologue or (chapterId==3 and Chapter3Story.Prologue or (chapterId>=4 and LaterChapterStory.Get(chapterId).Prologue or Story.Prologue)),
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
local ai2 = ListenerAI.new(chapter2World, function()
	return Players:GetPlayers()
end, handleCatch, {
	minX = 162,
	maxX = 268,
	pingMinX = 154,
	pingMaxX = 276,
	startX = 164,
	z = 0,
})
local ai3=ListenerAI.new(chapter3World,function() return Players:GetPlayers() end,handleCatch,
	{minX=303,maxX=404,pingMinX=292,pingMaxX=410,startX=397,z=0})
ensureLaterAI=function(chapterId)
	if not laterAis[chapterId] then
		laterAis[chapterId]=ListenerAI.new(laterWorlds[chapterId],function() return Players:GetPlayers() end,handleCatch,LaterChapterMap.GetAIConfig(chapterId))
	end
	return laterAis[chapterId]
end

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
		startPlayer(player, value)
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

local function showChapter2Document(player, clueKey)
	local clue = Chapter2Story.Clues[clueKey]
	if clue then
		send(player, "Document", { title = clue.title, text = clue.text })
	end
end

local function handleChapter2Prompt(player, prompt, id)
	if activeChapterId ~= 2 or player:GetAttribute("Linha11Chapter") ~= 2 then
		return
	end
	local now = os.clock()
	if id == "C2_Door304" then
		Chapter2Map.SetDoor(not Chapter2Map.GetDoorState())
	elseif id == "C2_Phone" then
		if not chapter2Mission.phone then
			chapter2Mission.phone = true
			showChapter2Document(player, "Phone")
			tellAll("A bobina está quente. O Ouvinte ainda não apareceu, mas algo arrasta um móvel no andar de cima.", "scare")
			publishState()
		else
			showChapter2Document(player, "Phone")
		end
	elseif id == "C2_Photo" then
		chapter2Mission.photo = true
		showChapter2Document(player, "Photo")
		publishState()
	elseif id == "C2_ServiceKey" then
		if not chapter2Mission.serviceKey then
			chapter2Mission.serviceKey = true
			showChapter2Document(player, "ServiceKey")
			tellAll("A chave do quadro de derivação foi encontrada na cozinha.", "success")
			publishState()
		else
			tell(player, "A chave já está com a equipe.", "info")
		end
	elseif id == "C2_Wiring" then
		chapter2Mission.wiring = true
		showChapter2Document(player, "Wiring")
		publishState()
	elseif id == "C2_KitchenObject" then
		tell(player, "A borda do copo está limpa. Alguém esteve aqui depois do fechamento.", "story")
	elseif id == "C2_Breaker" then
		if not (chapter2Mission.photo and chapter2Mission.serviceKey and chapter2Mission.wiring) then
			tell(player, "Compare a fotografia, a chave e a planta antes de mexer no quadro.", "objective")
		elseif not chapter2Mission.power then
			chapter2Mission.power = true
			Chapter2Map.SetPower(true)
			ai2:Wake()
			ai2:Ping(prompt.Parent.Position, 105)
			tellAll("O circuito acende. Do poço de serviço vem uma respiração longa, logo acima de vocês.", "scare")
			publishState()
		else
			tell(player, "A derivação está energizada.", "info")
		end
	elseif id == "C2_JackA" or id == "C2_JackB" then
		if not chapter2Mission.power then
			tell(player, "O quadro de derivação ainda está desligado.", "objective")
			return
		end
		if chapter2Mission.jacksConnected then
			tell(player, "O circuito já está fechado. Sigam o sinal até o banheiro.", "info")
			return
		end
		local side = id == "C2_JackA" and "A" or "B"
		local other = side == "A" and "B" or "A"
		local otherJack = chapter2Mission.jacks[other]
		if otherJack and now - otherJack.time > 12 then
			chapter2Mission.jacks.A = nil
			chapter2Mission.jacks.B = nil
			Chapter2Map.SetJack("A", false)
			Chapter2Map.SetJack("B", false)
			tellAll("O retorno caiu. Tentem fechar os dois pontos com poucos segundos de diferença.", "error")
			publishState()
			return
		end
		if chapter2Mission.jacks[side] then
			tell(player, "Esse ponto já está conectado. Ativem o outro lado.", "info")
			return
		end
		local activeCount = #startedPlayers()
		if activeCount >= 2 and otherJack and otherJack.player == player then
			tell(player, "O outro ponto precisa ser acionado pelo parceiro.", "objective")
			return
		end
		chapter2Mission.jacks[side] = { player = player, time = now }
		Chapter2Map.SetJack(side, true)
		if otherJack and now - math.min(otherJack.time, now) <= 12 then
			chapter2Mission.jacksConnected = true
			tellAll("Os dois pontos fecharam o circuito. O tom está atrás do espelho do banheiro.", "success")
		else
			tellAll("Ponto conectado. O parceiro precisa fechar o retorno em até 12 segundos.", "objective")
		end
		publishState()
	elseif id == "C2_Trace" then
		if not chapter2Mission.jacksConnected then
			tell(player, "O espelho vibra, mas o sinal ainda não chegou. Fechem os dois pontos do circuito.", "objective")
		elseif not chapter2Mission.traced then
			chapter2Mission.traced = true
			showChapter2Document(player, "Signal")
			tellAll("O fio sobe para a escadaria B. Registrem a descoberta no caderno da sala.", "success")
			publishState()
		else
			showChapter2Document(player, "Signal")
		end
	elseif id == "C2_Report" then
		if not chapter2Mission.traced then
			tell(player, "Primeiro descubram para onde sobe o sinal.", "objective")
		elseif not chapter2Mission.complete then
			chapter2Mission.complete = true
			publishState()
			broadcast("ChapterComplete", Chapter2Story.Completion)
		else
			tell(player, "O registro já foi confirmado.", "info")
		end
	end
end

local function showChapter3Document(player,key)
	local clue=Chapter3Story.Clues[key]
	if clue then send(player,"Document",{title=clue.title,text=clue.text}) end
end
local function handleChapter3Prompt(player,prompt,id)
	if activeChapterId~=3 or player:GetAttribute("Linha11Chapter")~=3 then return end
	local now=os.clock()
	if id=="C3_Phone" then
		chapter3Mission.phone=true; showChapter3Document(player,"Phone")
		tellAll("O ramal toca sem cabo. No corredor, alguma coisa responde com tres batidas.","scare")
	elseif id=="C3_Log" then chapter3Mission.log=true; showChapter3Document(player,"Log")
	elseif id=="C3_Route" then chapter3Mission.route=true; showChapter3Document(player,"Route")
	elseif id=="C3_Key" then
		if not(chapter3Mission.log and chapter3Mission.route) then tell(player,"Compare o livro do elevador e o aviso de manutencao.","objective")
		else chapter3Mission.controlKey=true; Chapter3Map.SetTechDoorOpen(true); showChapter3Document(player,"Key"); tellAll("A porta da sala tecnica sobe. Do elevador vem um unico toque.","success") end
	elseif id=="C3_BreakerA" or id=="C3_BreakerB" then
		if not(chapter3Mission.log and chapter3Mission.route and chapter3Mission.controlKey) then tell(player,"Faltam a chave e os registros para identificar o retorno.","objective"); return end
		if chapter3Mission.power then tell(player,"O retorno A/B ja esta fechado.","info"); return end
		local side=id=="C3_BreakerA" and "A" or "B"; local other=side=="A" and "B" or "A"
		local otherSwitch=chapter3Mission.switches[other]
		if otherSwitch and now-otherSwitch.time>12 then
			chapter3Mission.switches.A=nil; chapter3Mission.switches.B=nil
			Chapter3Map.SetBreaker("A",false); Chapter3Map.SetBreaker("B",false)
			tellAll("O retorno caiu. Fechem os dois disjuntores com poucos segundos de diferenca.","error"); publishState(); return
		end
		if chapter3Mission.switches[side] then tell(player,"Esse disjuntor ja foi acionado.","info"); return end
		if otherSwitch and #startedPlayers()>=2 and otherSwitch.player==player then tell(player,"O outro lado precisa do parceiro.","objective"); return end
		chapter3Mission.switches[side]={player=player,time=now}; Chapter3Map.SetBreaker(side,true); ai3:Ping(prompt.Parent.Position,95)
		if otherSwitch and now-otherSwitch.time<=12 then
			chapter3Mission.power=true; Chapter3Map.SetPower(true); ai3:Wake(); ai3:Ping(prompt.Parent.Position,110)
			tellAll("As luzes voltam. O elevador abre por dentro, embora o cabo ainda esteja solto.","scare")
		else tellAll("Um disjuntor travou. O parceiro precisa fechar o outro em ate 12 segundos.","objective") end
	elseif id=="C3_ElevatorCall" then
		if not chapter3Mission.power then tell(player,"O painel nao responde. Fechem juntos A e B.","objective")
		else chapter3Mission.elevatorOpened=true; Chapter3Map.SetElevatorOpen(true); tellAll("A cabine esta vazia; um gravador continua girando no chao.","story") end
	elseif id=="C3_Recorder" then
		if not chapter3Mission.elevatorOpened then tell(player,"O gravador esta alem das portas fechadas.","objective")
		else chapter3Mission.recorder=true; showChapter3Document(player,"Recorder"); tellAll("A fita repete o indicativo da equipe, gravado antes do despacho.","scare") end
	elseif id=="C3_Report" then
		if not chapter3Mission.recorder then tell(player,"Levem o gravador ao patamar e registrem a descoberta.","objective")
		else chapter3Mission.complete=true; publishState(); broadcast("ChapterComplete",Chapter3Story.Completion) end
	end
	publishState()
end

local function handleLaterChapterPrompt(player,prompt,id)
	local chapterText,action=string.match(id,"^C(%d+)_(.+)$")
	local chapterId=tonumber(chapterText)
	if not chapterId or chapterId<4 or chapterId>12 or activeChapterId~=chapterId or player:GetAttribute("Linha11Chapter")~=chapterId then return end
	local m= laterMissions[chapterId]
	local info=LaterChapterStory.Get(chapterId)
	local now=os.clock()
	local foundCount=0
	for _,found in pairs(m.found) do if found then foundCount+=1 end end
	local clueNumber=tonumber(string.match(action,"^Clue(%d+)$"))
	if clueNumber then
		if clueNumber>=1 and clueNumber<=#info.Clues then
			m.found[clueNumber]=true
			local clue=info.Clues[clueNumber]
			send(player,"Document",{title=clue.title,text=clue.text})
			if foundCount==0 then tellAll("A primeira pista liga o local ao ramal 11.","story") end
		end
	elseif chapterId==7 and (action=="LiftA" or action=="LiftB") then
		if foundCount<3 then tell(player,"Leiam o diagrama, a etiqueta e a ordem da subestacao antes de mover a bateria.","objective")
		elseif m.batteryRaised then tell(player,"A bateria ja foi levantada pela equipe.","info")
		else
			local side=action=="LiftA" and "A" or "B"; local other=side=="A" and "B" or "A"
			local otherLift=m.batteryLift[other]
			if otherLift and now-otherLift.time>12 then m.batteryLift.A=nil; m.batteryLift.B=nil; tellAll("A bateria volta ao suporte. Tentem levantar as duas alcas juntas.","error")
			elseif otherLift and #startedPlayers()>=2 and otherLift.player==player then tell(player,"A segunda alca precisa do parceiro.","objective")
			else
				m.batteryLift[side]={player=player,time=now}
				if otherLift and now-otherLift.time<=12 then
					m.batteryRaised=true; LaterChapterMap.MoveBattery(7)
					tellAll("A equipe levanta a bateria pesada e a desliza ate o receptaculo. Um dos cabos se parte no tunel.","scare")
					local monster=laterAis[7]; if monster then monster:Wake(); monster:Ping(prompt.Parent.Position,100) end
				else tellAll("Uma alca esta presa. O parceiro precisa segurar a outra em ate 12 segundos.","objective") end
			end
		end
	elseif chapterId==7 and action=="BatterySocket" then
		if not m.batteryRaised then tell(player,"A bateria ainda esta presa ao suporte.","objective")
		else m.batteryMoved=true; tellAll("A bateria encaixa no receptaculo. O painel dos tres trechos acende.","success") end
	elseif string.match(action,"^Step[A-C]$") then
		if foundCount<3 then tell(player,"Encontrem as tres pistas antes de mexer nos controles.","objective")
		elseif chapterId==7 and not m.batteryMoved then tell(player,"Levem a bateria ao receptaculo antes de fechar os trechos.","objective")
		elseif m.puzzleComplete then tell(player,"A sequencia ja foi confirmada. Sigam para o registro final.","info")
		else
			local step=string.sub(action,5)
			local expected=info.PuzzleOrder[m.puzzleStep+1]
			local nextIndex=m.puzzleStep+1
			if step~=expected then
				m.puzzleStep=0; m.lastPuzzlePlayer=nil
				tellAll("O mecanismo rejeita a ordem. Leiam a sequencia nas pistas e recomecem.","error")
				local monster=laterAis[chapterId]; if monster then monster:Wake(); monster:Ping(prompt.Parent.Position,95) end
			elseif info.CoopStep and info.CoopStep>0 and nextIndex==info.CoopStep and #startedPlayers()>=2 and m.lastPuzzlePlayer==player then
				tell(player,"Esta etapa exige que o parceiro assuma o outro controle.","objective")
			else
				m.puzzleStep=nextIndex; m.lastPuzzlePlayer=player
				local monster=laterAis[chapterId]; if monster then monster:Wake(); monster:Ping(prompt.Parent.Position,85) end
				if m.puzzleStep>=#info.PuzzleOrder then
					m.puzzleComplete=true
					tellAll("A sequencia fecha. Um sinal atravessa o ambiente e o registro final fica acessivel.","success")
					if monster then monster:Ping(prompt.Parent.Position,110) end
				else tellAll("Controle aceito. A proxima etapa do circuito esta ativa.","objective") end
			end
		end
	elseif action=="Report" then
		if not m.puzzleComplete then tell(player,"Concluam o mecanismo antes de registrar a descoberta.","objective")
		elseif chapterId==12 then tell(player,"Escolham transmitir a prova ou cortar a linha nos controles do repetidor.","objective")
		elseif not m.complete then
			m.complete=true
			broadcast("ChapterComplete",info.Completion)
		else tell(player,"Este capitulo ja foi registrado.","info") end
	elseif chapterId==12 and (action=="Transmit" or action=="Cut") then
		if not m.puzzleComplete then tell(player,"Fechem o circuito antes de decidir o destino da chamada.","objective")
		elseif not m.complete then
			local key=action=="Transmit" and "Transmit" or "Cut"
			m.choice=key; m.complete=true
			broadcast("ChapterComplete",info.Endings[key])
		else tell(player,"A decisao da equipe ja foi tomada.","info") end
	end
	publishState()
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
	if string.sub(id,1,3)=="C2_" then handleChapter2Prompt(player,prompt,id); return
	elseif string.sub(id,1,3)=="C3_" then handleChapter3Prompt(player,prompt,id); return
	elseif string.match(id,"^C%d+_") then handleLaterChapterPrompt(player,prompt,id); return end

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

local function connectPromptList(list)
	for _,prompt in ipairs(list) do prompt.Triggered:Connect(function(player) handlePrompt(player,prompt) end) end
end
connectPromptList(MapBuilder.GetPrompts())
connectPromptList(Chapter2Map.GetPrompts())
connectPromptList(Chapter3Map.GetPrompts())
connectPromptList(laterPrompts)

RunService.Heartbeat:Connect(function()
	local now = os.clock()
	for _, player in ipairs(startedPlayers()) do
		if not player:GetAttribute("Linha11Hidden") then
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if root and humanoid and humanoid.WalkSpeed >= 20 and root.AssemblyLinearVelocity.Magnitude > 13 and now - (noiseCooldowns[player] or 0) > 1.8 then
				noiseCooldowns[player] = now
				ai:Ping(root.Position, 75); ai2:Ping(root.Position, 75); ai3:Ping(root.Position, 75)
				local chapterId=player:GetAttribute("Linha11Chapter"); local laterAI=laterAis[chapterId]
				if laterAI then laterAI:Ping(root.Position,75) end
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



