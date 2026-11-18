-- Joga a campanha inteira (capítulos 1 a 12) pelo caminho principal, com um
-- jogador usando a interface real, e confere as regras de dupla, reinício e saída.
local UI = "Linha11Interface/"

local function closeDoc(player)
	local doc = T.gui(player, UI .. "Documento")
	-- o texto de fim de capítulo fica aberto: fechá-lo é voltar ao menu
	if doc and doc.Visible and not string.find(T.gui(player, UI .. "Documento/Fechar").Text, "MENU", 1, true) then
		T.click(player, UI .. "Documento/Fechar")
	end
end

-- Como um jogador faria: se o Ouvinte está em cima do objeto, espera longe do corredor até ele sair.
local function waitForCreatureToLeave(player, id)
	local prompt = T.findPrompt(id)
	if not prompt then return end
	local area = prompt
	while area.Parent and area.Parent ~= E.workspace do area = area.Parent end
	local creature = area:FindFirstChild("Ouvinte")
	if not creature then return end
	local target = prompt.Parent.Position
	for _ = 1, 60 do
		if not creature:GetAttribute("Awake") or math.abs(creature:GetPivot().Position.X - target.X) > 14 then return end
		T.moveTo(player, E.Vector3.new(target.X, 3, target.Z + (target.Z >= 0 and 14 or -14)))
		SIM.advance(2)
	end
	T.fail("o Ouvinte ficou mais de 2 minutos parado em cima de " .. id)
end

local function use(player, id)
	waitForCreatureToLeave(player, id)
	local ok = T.use(player, id)
	closeDoc(player)
	return ok
end

local function skipIntro(player)
	T.check(T.gui(player, UI .. "Intro").Visible == true, "a intro do capítulo não apareceu")
	T.click(player, UI .. "Intro/Pular")
	T.check(player:GetAttribute("Linha11IntroPending") == false, "a intro não liberou o jogador")
	T.check(player.Character.Humanoid.WalkSpeed == 16, "jogador continua parado depois da intro")
	T.check(T.gui(player, UI .. "HUD").Visible == true, "o painel de objetivo não apareceu")
end

local function expectChapter(player, chapterId)
	local start = T.lastEvent(player, "StartGame")
	T.check(start ~= nil and start.chapterId == chapterId, "o servidor não iniciou o capítulo " .. chapterId .. ": " .. T.lastMessage(player))
	T.check(player:GetAttribute("Linha11Chapter") == chapterId, "jogador não está marcado no capítulo " .. chapterId)
end

local function expectObjective(player, fragment)
	local objective = T.state(player).objective or "(vazio)"
	T.check(string.find(objective, fragment, 1, true) ~= nil, "objetivo errado; esperava conter '" .. fragment .. "', veio: " .. objective)
end

-- Fecha o texto final apertando "próximo capítulo" e confere a chegada no seguinte.
local function nextChapter(player, fromChapter)
	local final = T.lastEvent(player, fromChapter == 1 and "Ending" or "ChapterComplete")
	T.check(final ~= nil, "o texto de fim do capítulo " .. fromChapter .. " não chegou: " .. T.lastMessage(player))
	if fromChapter < 12 then
		T.check(final ~= nil and final.nextChapterId == fromChapter + 1, "o fim do capítulo " .. fromChapter .. " não aponta o próximo")
		T.check(T.gui(player, UI .. "Documento/Proximo").Visible == true, "botão de próximo capítulo não apareceu")
		T.clearInbox(player)
		T.click(player, UI .. "Documento/Proximo")
		expectChapter(player, fromChapter + 1)
		skipIntro(player)
	end
end

local LATER = {
	[4] = { "A", "B", "C" }, [5] = { "A", "B", "C" }, [6] = { "B", "C", "A" }, [7] = { "A", "C", "B" }, [8] = { "B", "A", "C" },
	[9] = { "C", "B", "A" }, [10] = { "A", "B", "C" }, [11] = { "B", "C", "A" }, [12] = { "C", "A", "B" },
}

local function playChapter1(p)
	expectObjective(p, "chave")
	for _, id in ipairs({ "StorageKey", "FuseDrawer", "Clue03", "Clue1", "Clue7", "Breaker", "Keypad" }) do use(p, id) end
	T.check(T.gui(p, UI .. "Teclado").Visible == true, "teclado da senha não abriu: " .. T.lastMessage(p))
	for _, key in ipairs({ "Tecla0", "Tecla3", "Tecla1", "Tecla7", "Confirmar" }) do T.click(p, UI .. "Teclado/Numeros/" .. key) end
	T.check(T.state(p).archiveOpen == true, "senha 0317 não abriu o arquivo: " .. T.lastMessage(p))
	for _, id in ipairs({ "ArchiveTape", "Phone", "Crowbar", "Door_Repetidor", "RelayA", "RelayB", "EndingConsole" }) do use(p, id) end
	T.check(T.gui(p, UI .. "Finais") ~= nil and T.gui(p, UI .. "Finais").Visible, "painel de finais não abriu: " .. T.lastMessage(p))
	T.click(p, UI .. "Finais/Transmitir")
end

local function playChapter2(p)
	expectObjective(p, "telefone")
	use(p, "C2_Phone")
	expectObjective(p, "fotografia")
	for _, id in ipairs({ "C2_Photo", "C2_ServiceKey", "C2_Wiring" }) do use(p, id) end
	expectObjective(p, "quadro")
	use(p, "C2_Breaker")
	T.check(T.state(p).power == true, "quadro do 304 não ligou: " .. T.lastMessage(p))
	use(p, "C2_JackA"); use(p, "C2_JackB")
	T.check(T.state(p).jacksConnected == true, "os dois pontos não fecharam o circuito: " .. T.lastMessage(p))
	use(p, "C2_Trace")
	expectObjective(p, "registro")
	use(p, "C2_Report")
end

local function playChapter3(p)
	expectObjective(p, "telefone")
	for _, id in ipairs({ "C3_Phone", "C3_Log", "C3_Route", "C3_Key" }) do use(p, id) end
	T.check(T.state(p).controlKey == true, "chave técnica não foi liberada: " .. T.lastMessage(p))
	use(p, "C3_BreakerA"); use(p, "C3_BreakerB")
	T.check(T.state(p).power == true, "disjuntores não ligaram a energia: " .. T.lastMessage(p))
	for _, id in ipairs({ "C3_ElevatorCall", "C3_Recorder", "C3_Report" }) do use(p, id) end
end

local function playLater(p, chapterId)
	local prefix = "C" .. chapterId .. "_"
	expectObjective(p, "registros")
	for index = 1, 3 do use(p, prefix .. "Clue" .. index) end
	T.check(T.state(p).foundCount == 3, "as três pistas não foram contadas")
	if chapterId == 7 then
		use(p, prefix .. "LiftA"); use(p, prefix .. "LiftB")
		T.check(T.state(p).batteryRaised == true, "a bateria não foi levantada: " .. T.lastMessage(p))
		use(p, prefix .. "BatterySocket")
		T.check(T.state(p).batteryMoved == true, "a bateria não encaixou: " .. T.lastMessage(p))
	end
	for index, step in ipairs(LATER[chapterId]) do
		use(p, prefix .. "Step" .. step)
		T.check(T.state(p).puzzleStep == index, "etapa " .. step .. " não foi aceita: " .. T.lastMessage(p))
	end
	T.check(T.state(p).puzzleComplete == true, "a sequência não fechou: " .. T.lastMessage(p))
	if chapterId == 12 then
		use(p, prefix .. "Report")
		T.check(T.state(p).complete ~= true, "o capítulo 12 terminou sem a escolha final")
		use(p, prefix .. "Cut")
	else
		use(p, prefix .. "Report")
	end
	T.check(T.state(p).complete == true, "o capítulo não foi concluído: " .. T.lastMessage(p))
end

-- ------------------------------------------------------------ 1. campanha solo
T.startServer()
local ana = T.addPlayer("Ana")
T.startClient(ana)

T.context = "cap 1: "
T.click(ana, UI .. "FundoMenu/MenuPrincipal/Comecar")
expectChapter(ana, 1)
skipIntro(ana)
playChapter1(ana)
nextChapter(ana, 1)
T.context = "cap 2: "
playChapter2(ana)
nextChapter(ana, 2)
T.context = "cap 3: "
playChapter3(ana)
nextChapter(ana, 3)
for chapterId = 4, 12 do
	T.context = "cap " .. chapterId .. ": "
	playLater(ana, chapterId)
	nextChapter(ana, chapterId)
end
T.context = "fim da campanha: "
T.check(ana:GetAttribute("Linha11Progress") == 12, "progresso salvo deveria ser 12, está " .. tostring(ana:GetAttribute("Linha11Progress")))
T.check(SIM.datastore["u_" .. ana.UserId] == 12, "o progresso não foi gravado no armazenamento")
T.check(T.gui(ana, UI .. "Documento/Proximo").Visible == false, "o último capítulo não deveria oferecer próximo")
T.click(ana, UI .. "Documento/Fechar")
T.check(ana:GetAttribute("Linha11Started") == false, "voltar ao menu não tirou o jogador da sessão")
T.check(T.gui(ana, UI .. "FundoMenu/MenuPrincipal").Visible == true, "o menu não voltou depois do final")

-- ------------------------------------------------------------ 2. rejogar um capítulo já usado
T.context = "rejogar cap 1: "
T.clearInbox(ana)
T.send(ana, "Start", 1)
expectChapter(ana, 1)
T.click(ana, UI .. "Intro/Pular")
T.check(T.state(ana).key == false and T.state(ana).archiveOpen == false, "o capítulo 1 não voltou ao estado inicial")
use(ana, "Keypad")
T.check(T.gui(ana, UI .. "Teclado").Visible ~= true, "teclado abriu sem energia num capítulo reiniciado")
playChapter1(ana)
T.check(T.lastEvent(ana, "Ending") ~= nil, "não deu para terminar o capítulo 1 pela segunda vez: " .. T.lastMessage(ana))
T.click(ana, UI .. "Documento/Fechar")

-- ------------------------------------------------------------ 3. dupla
T.context = "dupla cap 2: "
local bia = T.addPlayer("Bia")
T.clearInbox(ana)
T.send(ana, "Start", 2)
T.send(ana, "Ready")
T.send(bia, "Start", 5) -- pede outro capítulo: tem de cair no da equipe
T.send(bia, "Ready")
T.check(bia:GetAttribute("Linha11Chapter") == 2, "o segundo jogador não entrou no capítulo da equipe")
for _, id in ipairs({ "C2_Phone", "C2_Photo", "C2_ServiceKey", "C2_Wiring", "C2_Breaker" }) do use(ana, id) end
T.moveTo(bia, ana.Character.HumanoidRootPart.Position)
use(ana, "C2_JackA")
use(ana, "C2_JackB")
T.check(T.state(ana).jacksConnected ~= true, "com o parceiro ao lado, um jogador só fechou os dois pontos")
use(bia, "C2_JackB")
T.check(T.state(ana).jacksConnected == true, "a dupla não conseguiu fechar o circuito: " .. T.lastMessage(bia))

T.context = "dupla, tempo esgotado: "
-- capítulo 3: um lado, espera mais de 12 s, o outro lado derruba; depois refaz certo
T.send(ana, "Leave"); T.send(bia, "Leave")
T.send(ana, "Start", 3); T.send(ana, "Ready"); T.send(bia, "Start", 3); T.send(bia, "Ready")
for _, id in ipairs({ "C3_Phone", "C3_Log", "C3_Route", "C3_Key" }) do use(ana, id) end
use(ana, "C3_BreakerA")
SIM.advance(14)
use(bia, "C3_BreakerB")
T.check(T.state(ana).power ~= true, "os disjuntores ligaram mesmo passados mais de 12 segundos")
use(ana, "C3_BreakerA"); use(bia, "C3_BreakerB")
T.check(T.state(ana).power == true, "depois do tempo esgotado não deu para tentar de novo: " .. T.lastMessage(bia))

T.context = "parceiro longe: "
-- capítulo 4 exige troca de jogador na etapa 2; com o parceiro longe, um só pode seguir
T.send(ana, "Leave"); T.send(bia, "Leave")
T.send(ana, "Start", 4); T.send(ana, "Ready"); T.send(bia, "Start", 4); T.send(bia, "Ready")
for index = 1, 3 do use(ana, "C4_Clue" .. index) end
T.moveTo(bia, ana.Character.HumanoidRootPart.Position)
use(ana, "C4_StepA"); use(ana, "C4_StepB")
T.check(T.state(ana).puzzleStep == 1, "etapa de dupla foi aceita do mesmo jogador com o parceiro ao lado")
T.moveTo(bia, E.Vector3.new(-5000, 0, 0))
use(ana, "C4_StepB"); use(ana, "C4_StepC")
T.check(T.state(ana).puzzleComplete == true, "com o parceiro longe o jogador ficou travado: " .. T.lastMessage(ana))
use(ana, "C4_Report")
T.check(T.lastEvent(bia, "ChapterComplete") ~= nil, "o parceiro não recebeu o fim do capítulo")
T.clearInbox(ana); T.clearInbox(bia)
T.send(bia, "NextChapter")
T.check(ana:GetAttribute("Linha11Chapter") == 5 and bia:GetAttribute("Linha11Chapter") == 5, "avançar não levou a equipe inteira para o capítulo 5")

-- ------------------------------------------------------------ 4. criatura, esconderijo e saída
T.context = "ouvinte: "
T.send(ana, "Leave"); T.send(bia, "Leave")
T.send(ana, "Start", 1); T.send(ana, "Ready")
for _, id in ipairs({ "StorageKey", "FuseDrawer", "Clue03", "Clue1", "Clue7", "Breaker", "Keypad" }) do use(ana, id) end
T.send(ana, "Code", "0317")
use(ana, "ArchiveTape"); use(ana, "Phone")
local creature = E.workspace:FindFirstChild("Linha11World"):FindFirstChild("Ouvinte")
T.check(creature ~= nil and creature:GetAttribute("Awake") == true, "o Ouvinte não acordou com a chamada")
T.clearInbox(ana)
T.moveTo(ana, E.Vector3.new(30, 3, 0))
ana.Character.HumanoidRootPart.AssemblyLinearVelocity = E.Vector3.new(20, 0, 0)
T.send(ana, "Sprint", true)
SIM.advance(25)
T.check(T.lastEvent(ana, "Caught") ~= nil, "correndo no corredor por 25 s, o Ouvinte não pegou o jogador")
T.check(ana.Character.Humanoid.Health < 100, "ser pego não tirou vida")
T.send(ana, "Sprint", false)
ana.Character.HumanoidRootPart.AssemblyLinearVelocity = E.Vector3.new(0, 0, 0)
use(ana, "Hide_304")
T.check(ana:GetAttribute("Linha11Hidden") == true, "o guarda-roupa não escondeu o jogador")
T.clearInbox(ana)
T.moveTo(ana, creature:GetPivot().Position)
SIM.advance(22)
T.check(T.lastEvent(ana, "Caught") == nil, "o Ouvinte pegou um jogador escondido")
T.spawnCharacter(ana)
SIM.advance(1)
T.check(ana:GetAttribute("Linha11Hidden") == false, "renascer não tirou o jogador do esconderijo")

T.context = "saída: "
T.removePlayer(ana)
T.clearInbox(bia)
T.send(bia, "Start", 6); T.send(bia, "Ready")
T.check(bia:GetAttribute("Linha11Chapter") == 6, "depois que a equipe saiu, o servidor continuou preso no capítulo antigo")
T.finish()
