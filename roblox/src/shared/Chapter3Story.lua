local Chapter3Story = {}
Chapter3Story.Title = "Sem Sinal"
Chapter3Story.Prologue = {
	"A escadaria B cheira a concreto molhado e fio queimado.",
	"O telefone do patamar tocou antes de voces chegarem.",
	"A derivacao do 304 desce para o elevador de servico.",
	"Reconstruam o circuito. Se ouvirem passos, parem de correr.",
}
Chapter3Story.Objectives = {
	[0] = "Atenda ao telefone no patamar da escadaria B.",
	[1] = "Compare o livro do elevador e o aviso de rota; depois procure a chave tecnica.",
	[2] = "Na sala tecnica, fechem os dois disjuntores em ate 12 segundos.",
	[3] = "Abra o elevador de servico e recupere o gravador.",
	[4] = "Volte ao patamar e registre o que o gravador revelou.",
	[5] = "Capitulo concluido. A gravacao aponta para a cabine de emergencia na rua.",
}
function Chapter3Story.GetObjective(stage: number): string
	return Chapter3Story.Objectives[stage] or Chapter3Story.Objectives[5]
end
Chapter3Story.Clues = {
	Phone = { title="TELEFONE DE SERVICO • 02:41", text="A chamada vem do ramal 11, embora o cabo termine numa caixa vazia. Uma pessoa pede para abrir a escadaria; outra responde que a equipe ainda nao chegou." },
	Log = { title="LIVRO DO ELEVADOR", text="O elevador foi isolado na noite da evacuacao. Mesmo assim, o contador registrou uma viagem as 03:17 para um nivel inexistente. A ordem de manutencao: 11-B." },
	Route = { title="AVISO DE MANUTENCAO", text="Fechar os disjuntores A e B com no maximo doze segundos de intervalo. O retorno precisa de duas pessoas nos dois lados do quadro." },
	Key = { title="ETIQUETA DA CHAVE", text="A chave abre a sala tecnica. Se o telefone tocar, nao responda com o seu nome." },
	Recorder = { title="GRAVADOR DO ELEVADOR", text="Uma voz conta dois tecnicos entrando no predio. A outra diz: Ainda nao. Primeiro eles precisam atender. A fita termina com tres toques." },
}
Chapter3Story.Completion = {
	title="CAPITULO 3 • SEM SINAL",
	text="O gravador descreve a chegada da equipe antes de ela acontecer. No verso, alguem anotou a cabine de emergencia da Avenida Norte. Quando o telefone toca de novo, a voz usa o indicativo de voces.",
}
return Chapter3Story