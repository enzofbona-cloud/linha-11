local Story = {}

Story.Title = "LINHA 11 — A ÚLTIMA CHAMADA"
Story.Version = "Roblox Prototype 0.1.0"
Story.Code = "0317"

Story.Prologue = {
	"Às 02:41, uma chamada interrompe o plantão municipal.",
	"Dois técnicos municipais são enviados ao Edifício Aurora, no Distrito 11.",
	"O prédio será demolido ao amanhecer. A central ainda recebe chamadas de um circuito que deveria estar morto há dezessete anos.",
	"Restaure o repetidor do terceiro andar, recupere a fita física do arquivo e desligue o circuito antes das 03:17.",
	"Não atendam chamadas que usem os nomes de vocês.",
}

Story.Clues = {
	Clue03 = {
		title = "REGISTRO DE MANUTENÇÃO",
		text = "03 — Às 03:17, o repetidor ECO voltou a transmitir mesmo sem alimentação. A equipe de evacuação registrou onze chamadas abertas.",
	},
	Clue1 = {
		title = "RECIBO DE EVACUAÇÃO",
		text = "1 — Um único rolo de fita foi retirado do arquivo na noite do fechamento. O livro de saída não informa quem o levou.",
	},
	Clue7 = {
		title = "ANOTAÇÃO DO ZELADOR",
		text = "7 — A linha do apartamento 304 continuou tocando depois que o quadro geral foi desligado. Ninguém admite ter atendido.",
	},
	Tape = {
		title = "FITA 11 • TRANSCRIÇÃO PARCIAL",
		text = "A gravação não prevê o futuro. Ela repete chamadas gravadas no circuito enquanto alguém continua respondendo do outro lado. No fim, uma voz pede que o técnico corte a linha.",
	},
	Phone = {
		title = "CHAMADA RECEBIDA",
		text = "A voz do outro lado repete a ordem de serviço, palavra por palavra. Então diz: “Vocês chegaram juntos. Não saiam separados.”",
	},
	Photo304 = {
		title = "FOTOGRAFIA DO PRÉDIO",
		text = "Uma turma posa diante do Edifício Aurora. Onze rostos foram riscados com tinta escura; no verso, alguém escreveu: “A lista de evacuação está incompleta.”",
	},
	LogPlantao = {
		title = "LIVRO DO PLANTÃO",
		text = "A ordem de serviço veio da prefeitura, mas o circuito 11 não aparece na planta do prédio. A anotação mais recente termina às 03:17.",
	},
}

Story.Objectives = {
	[0] = "Leia a ordem de serviço e entre no terceiro andar.",
	[1] = "Encontre a chave do armário de manutenção no apartamento 305.",
	[2] = "Use a chave para abrir a gaveta de fusíveis no apartamento 301.",
	[3] = "Recolha os três fragmentos da senha nos apartamentos 301, 302 e 305.",
	[4] = "Instale o fusível no quadro do corredor.",
	[5] = "Digite 0317 no teclado do arquivo 303.",
	[6] = "Recupere a fita e verifique o telefone do apartamento 304.",
	[7] = "Encontre o pé de cabra no 304 e abra a sala do repetidor.",
	[8] = "Ative as duas alavancas do repetidor. Fiquem juntos e em silêncio.",
	[9] = "Decidam o destino da última gravação.",
	[10] = "Turno encerrado.",
}

Story.Endings = {
	Transmit = {
		title = "A LINHA FICA ABERTA",
		text = "A fita é enviada à central. As onze chamadas chegam ao público, junto com o relatório que a prefeitura enterrou. O repetidor responde com uma décima segunda chamada — agora de dentro da viatura.",
	},
	Cut = {
		title = "SILÊNCIO NO DISTRITO 11",
		text = "O repetidor é cortado. O prédio fica em silêncio e os dois técnicos deixam o Aurora com a fita. A cidade ainda não conhece a verdade, mas, pela primeira vez em dezessete anos, ninguém atende do outro lado.",
	},
}

function Story.GetObjective(stage: number): string
	return Story.Objectives[stage] or Story.Objectives[10]
end

return Story

