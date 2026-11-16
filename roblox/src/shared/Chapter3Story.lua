local Chapter3Story = {}
Chapter3Story.Title = "Sem Sinal"
Chapter3Story.Prologue = {
	"A escadaria B cheira a concreto molhado e fio queimado.",
	"O telefone do patamar tocou antes de vocês chegarem.",
	"A derivação do 304 desce para o elevador de serviço.",
	"Reconstruam o circuito. Se ouvirem passos, parem de correr.",
}
Chapter3Story.Objectives = {
	[0] = "Atenda ao telefone no patamar da escadaria B.",
	[1] = "Compare o livro do elevador e o aviso de rota; depois procure a chave técnica.",
	[2] = "Na sala técnica, fechem os dois disjuntores em até 12 segundos.",
	[3] = "Abra o elevador de serviço e recupere o gravador.",
	[4] = "Volte ao patamar e registre o que o gravador revelou.",
	[5] = "Capítulo concluído. A gravação aponta para a cabine de emergência na rua.",
}
function Chapter3Story.GetObjective(stage: number): string
	return Chapter3Story.Objectives[stage] or Chapter3Story.Objectives[5]
end
Chapter3Story.Clues = {
	Phone = { title="TELEFONE DE SERVIÇO • 02:41", text="A chamada vem do ramal 11, embora o cabo termine numa caixa vazia. Uma pessoa pede para abrir a escadaria; outra responde que a equipe ainda não chegou." },
	Log = { title="LIVRO DO ELEVADOR", text="O elevador foi isolado na noite da evacuação. Mesmo assim, o contador registrou uma viagem às 03:17 para um nível inexistente. A ordem de manutenção: 11-B." },
	Route = { title="AVISO DE MANUTENÇÃO", text="Fechar os disjuntores A e B com no máximo doze segundos de intervalo. O retorno precisa de duas pessoas nos dois lados do quadro." },
	Key = { title="ETIQUETA DA CHAVE", text="A chave abre a sala técnica. Se o telefone tocar, não responda com o seu nome." },
	Recorder = { title="GRAVADOR DO ELEVADOR", text="Uma voz conta dois técnicos entrando no prédio. A outra diz: Ainda não. Primeiro eles precisam atender. A fita termina com três toques." },
}
Chapter3Story.Completion = {
	title="CAPÍTULO 3 • SEM SINAL",
	text="O gravador descreve a chegada da equipe antes de ela acontecer. No verso, alguém anotou a cabine de emergência da Avenida Norte. Quando o telefone toca de novo, a voz usa o indicativo de vocês.",
}
return Chapter3Story