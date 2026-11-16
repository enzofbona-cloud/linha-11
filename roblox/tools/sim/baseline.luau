-- Roteiro mínimo: um jogador termina o capítulo 1 pelo caminho principal.
T.startServer()
local p1 = T.addPlayer("Ana")
T.startClient(p1)

T.context = "cap 1: "
T.click(p1, "Linha11Interface/FundoMenu/MenuPrincipal/Comecar")
T.check(T.lastEvent(p1, "StartGame") ~= nil, "servidor não respondeu ao botão de iniciar")
T.click(p1, "Linha11Interface/Intro/Pular")
T.check(p1:GetAttribute("Linha11IntroPending") == false, "intro não liberou o jogador")
T.check(p1.Character.Humanoid.WalkSpeed == 16, "jogador continua parado depois da intro")

for _, id in ipairs({ "StorageKey", "FuseDrawer", "Clue03", "Clue1", "Clue7", "Breaker", "Keypad" }) do
	T.use(p1, id)
	local doc = T.gui(p1, "Linha11Interface/Documento")
	if doc and doc.Visible then T.click(p1, "Linha11Interface/Documento/Fechar") end
end
T.check(T.gui(p1, "Linha11Interface/Teclado").Visible == true, "teclado da senha não abriu: " .. T.lastMessage(p1))
for _, key in ipairs({ "Tecla0", "Tecla3", "Tecla1", "Tecla7", "Confirmar" }) do
	T.click(p1, "Linha11Interface/Teclado/Numeros/" .. key)
end
T.check(T.state(p1).archiveOpen == true, "senha 0317 não abriu o arquivo: " .. T.lastMessage(p1))
for _, id in ipairs({ "ArchiveTape", "Phone", "Crowbar", "Door_Repetidor", "RelayA", "RelayB", "EndingConsole" }) do
	T.use(p1, id)
	local doc = T.gui(p1, "Linha11Interface/Documento")
	if doc and doc.Visible then T.click(p1, "Linha11Interface/Documento/Fechar") end
end
T.check(T.gui(p1, "Linha11Interface/Finais") ~= nil, "painel de finais não abriu: " .. T.lastMessage(p1))
T.click(p1, "Linha11Interface/Finais/Transmitir")
T.check(T.lastEvent(p1, "Ending") ~= nil, "final não chegou ao jogador: " .. T.lastMessage(p1))
print("estágio final:", T.state(p1).stage, "| objetivo:", T.state(p1).objective)
T.finish()
