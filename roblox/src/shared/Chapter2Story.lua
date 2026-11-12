local Chapter2Story = {}

Chapter2Story.Title = "Apartamento 304"
Chapter2Story.Prologue = {
	"A fita 11 termina com um telefone tocando dentro do apartamento 304.",
	"A central confirma que a linha do prédio continua recebendo corrente pela bateria de emergência.",
	"Entrem no 304, localizem a derivação e registrem de onde vem o sinal.",
	"Fiquem próximos. O corredor ainda está ligado ao circuito ECO.",
}

Chapter2Story.Clues = {
	Phone = { title = "LINHA SEM TOM", text = "O telefone está desligado da tomada, mas a bobina ainda está morna. O fio não segue para a rua: ele desaparece dentro da parede." },
	Photo = { title = "FOTOGRAFIA • 03:17", text = "A moradora do 304 aparece ao lado de uma caixa de interfone. No verso: ‘A voz vem do andar de cima, mesmo quando o prédio está vazio.’" },
	ServiceKey = { title = "CHAVE DE SERVIÇO", text = "A chave abre o pequeno quadro de derivação da área de serviço. Há marcas recentes de uso apesar dos dezessete anos de abandono." },
	Wiring = { title = "PLANTA DO CIRCUITO DOMÉSTICO", text = "Dois pontos precisam fechar o circuito ao mesmo tempo: a tomada da cozinha e o retorno da área de serviço. O traço termina atrás do espelho do banheiro." },
	Signal = { title = "REGISTRO DO SINAL", text = "O tom não vem da central. Ele sobe pelo poço de serviço e termina na caixa telefônica da escadaria B. Há uma nova etiqueta presa ao cabo: 03:17." },
}

Chapter2Story.Objectives = {
	[0] = "Entre no apartamento 304 e examine o telefone.",
	[1] = "Investigue a fotografia, encontre a chave de serviço e leia a planta do circuito.",
	[2] = "Use a chave e a planta para reativar o quadro da área de serviço.",
	[3] = "Fechem juntos os dois pontos do circuito: cozinha e lavanderia.",
	[4] = "Siga o sinal até o espelho do banheiro e registre a origem.",
	[5] = "Volte ao telefone e confirme o registro da chamada.",
	[6] = "Capítulo concluído. A derivação segue para a escadaria B.",
}

function Chapter2Story.GetObjective(stage: number): string
	return Chapter2Story.Objectives[stage] or Chapter2Story.Objectives[6]
end

Chapter2Story.Completion = {
	title = "CAPÍTULO 2 • A DERIVAÇÃO",
	text = "O sinal subiu pelo poço de serviço até a escadaria B. Atrás do espelho havia um fio novo, ligado a uma caixa que não aparece na planta do prédio. Antes de a equipe conseguir cortá-lo, o telefone tocou outra vez — desta vez, no corredor.",
}

return Chapter2Story
