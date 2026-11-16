local LaterChapterStory = {}

LaterChapterStory.Chapters = {
	[4] = {
		Title="A Cidade Vazia", Theme="street", Location="Avenida Norte",
		Prologue={"A cabine da Avenida Norte ainda recebe energia do ramal 11.","A lista oficial diz que todos os moradores embarcaram.","As marcas no meio-fio contam outra história: nenhum ônibus parou aqui."},
		Objectives={[0]="Atenda a cabine de emergência.",[1]="Recolha o livro de transporte e o registro da cabine.",[2]="Roteie a chamada pela sequência indicada nos três avisos.",[3]="Registre o destino real dos ônibus no posto de evacuação.",[4]="A chamada aponta para a antiga Central Municipal.",[5]="Capítulo concluído."},
		Clues={
			{title="QUADRO DE LINHAS",text="A linha 11 foi desviada para a Avenida Norte às 02:41. O campo de passageiros foi preenchido antes da chegada do primeiro ônibus."},
			{title="REGISTRO DA CABINE",text="A cabine recebeu uma chamada às 03:17. A voz do atendente pede para confirmar três pontos da rota: terminal, retorno, garagem."},
			{title="TALÃO DE EMBARQUE",text="Onze bilhetes foram impressos, mas nenhum foi validado. No verso, a mesma letra escreveu: 'Não houve embarque. A ordem veio da Central.'"},
		},
		PuzzleOrder={"A","B","C"}, CoopStep=2,
		StepLabels={A={Action="Terminal",Object="Rota 1"},B={Action="Retorno",Object="Rota 2"},C={Action="Garagem",Object="Rota 3"}},
		Completion={title="CAPÍTULO 4 • A CIDADE VAZIA",text="Os bilhetes nunca foram usados. A ordem de marcar a evacuação veio da Central Municipal antes de qualquer ônibus chegar. A linha registrada no talão aponta para a sala de despacho."},
	},
	[5] = {
		Title="Central de Chamadas", Theme="callcenter", Location="Central Municipal",
		Prologue={"A Central foi lacrada depois da evacuação.","Onze chamadas continuam na mesa, cada uma com um horário diferente.","A gravação mais recente tem a voz de um operador que afirma estar sozinho."},
		Objectives={[0]="Examine os rolos e o quadro de despacho.",[1]="Encontre as três fichas que ainda têm horário legível.",[2]="Reordene as chamadas na mesa de gravação.",[3]="Reproduza a fita integral e registre a origem do despacho.",[4]="A ordem da evacuação foi emitida daqui, antes do primeiro chamado.",[5]="Capítulo concluído."},
		Clues={
			{title="FICHA DE DESPACHO A",text="02:41 — ramal 11 — solicitada ambulância para o Distrito 11. A linha estava muda durante 19 segundos antes da resposta."},
			{title="FICHA DE DESPACHO B",text="03:02 — ordem interna: preparar retirada total. Campo de autorização sem assinatura; carimbo aplicado 15 minutos depois."},
			{title="FICHA DE DESPACHO C",text="03:17 — chamada recebida da sala de operação, que estava vazia segundo o controle de acesso."},
		},
		PuzzleOrder={"A","C","B"}, CoopStep=0,
		StepLabels={A={Action="02:41",Object="Rolo 1"},B={Action="03:02",Object="Rolo 2"},C={Action="03:17",Object="Rolo 3"}},
		Completion={title="CAPÍTULO 5 • CENTRAL DE CHAMADAS",text="A ordem de retirada foi registrada antes de qualquer pedido de ajuda. A fita original foi levada ao Arquivo Municipal; a cópia da Central foi editada. O número de custódia termina em 0317."},
	},
	[6] = {
		Title="Arquivo 03:17", Theme="archive", Location="Arquivo Municipal",
		Prologue={"O arquivo guarda o original que a Central diz ter destruído.","As estantes foram reorganizadas depois do fechamento.","Algumas caixas têm poeira por cima e marcas recentes por baixo."},
		Objectives={[0]="Localize a sala de consulta e procure o registro de custódia.",[1]="Leia a folha de saída, o carimbo e a ficha de transferência.",[2]="Classifique os documentos pela ordem correta.",[3]="Abra o armário de custódia e recolha a fita original.",[4]="O manifesto não confirma a evacuação; ele registra uma transferência sem destino.",[5]="Capítulo concluído."},
		Clues={
			{title="FOLHA DE SAÍDA",text="A lista foi impressa às 03:17. O campo 'saída confirmada' está marcado, mas o livro de portaria não registra veículos no perímetro."},
			{title="CARIMBO DE CUSTÓDIA",text="A matriz do carimbo foi usada antes da folha existir. O lote do carimbo pertence ao turno seguinte."},
			{title="FICHA DE TRANSFERÊNCIA",text="Destino apagado. Quantidade: onze volumes. Responsável: R. Vale. Um segundo carimbo aponta para a Linha de Serviço."},
		},
		PuzzleOrder={"B","C","A"}, CoopStep=0,
		StepLabels={A={Action="Impressao",Object="Etapa 1"},B={Action="Carimbo",Object="Etapa 2"},C={Action="Custodia",Object="Etapa 3"}},
		Completion={title="CAPÍTULO 6 • ARQUIVO 03:17",text="A fita original não contém uma lista de passageiros. Contém onze ramais ativos e um pedido para manter a Linha de Serviço ligada. O nome R. Vale aparece novamente na subestação."},
	},
	[7] = {
		Title="Linha de Serviço", Theme="tunnel", Location="Subestação Auxiliar",
		Prologue={"A Linha de Serviço passa por baixo do perímetro evacuado.","A bateria de emergência foi removida do suporte e deixada no túnel.","A porta atrás de vocês não vai continuar aberta por muito tempo."},
		Objectives={[0]="Encontre o suporte e as duas alças da bateria pesada.",[1]="Levante a bateria em dupla e leve-a ao receptáculo.",[2]="Restaure os três trechos do circuito na ordem do diagrama.",[3]="Abra a passagem de retorno e recupere o registro da subestação.",[4]="O consumo da linha coincide com a ala de triagem.",[5]="Capítulo concluído."},
		Clues={
			{title="DIAGRAMA DE CABOS",text="Trecho 1 alimenta a ala de triagem. Trecho 2 retorna ao repetidor. Trecho 3 foi ligado depois da evacuação por alguém que conhecia o circuito."},
			{title="ETIQUETA DA BATERIA",text="Bateria de chumbo, 86 kg. Transporte com duas pessoas. A alça esquerda está travada."},
			{title="ORDEM DA SUBESTAÇÃO",text="Manter ativo até receber confirmação da triagem. Assinatura: R. Vale. A hora foi escrita por cima: 03:17."},
		},
		PuzzleOrder={"A","C","B"}, CoopStep=2, RequiresBattery=true,
		StepLabels={A={Action="TRECHO 1",Object="Distribuicao"},B={Action="TRECHO 2",Object="Retorno"},C={Action="TRECHO 3",Object="Repetidor"}},
		Completion={title="CAPÍTULO 7 • LINHA DE SERVIÇO",text="A bateria manteve um circuito vivo sob o bairro. O ramal vai para o abrigo de triagem. A última mensagem da subestação pede para conferir as pulseiras antes de desligar qualquer coisa."},
	},
	[8] = {
		Title="Ala de Triagem", Theme="triage", Location="Ginásio Aurora",
		Prologue={"O ginásio foi convertido em abrigo na noite da evacuação.","As camas estão arrumadas, mas nenhuma tem marcas de uso.","No balcão, as pulseiras foram contadas onze vezes."},
		Objectives={[0]="Compare o mapa das camas com as pulseiras.",[1]="Procure a ficha da enfermaria e a lista de entrada.",[2]="Ligue a luz da ala e confira as três estações de suprimentos.",[3]="Registre quem foi atendido e quem nunca chegou.",[4]="O endereço de transferência leva ao Bloco 11.",[5]="Capítulo concluído."},
		Clues={
			{title="MAPA DAS CAMAS",text="Onze camas foram reservadas. A equipe marcou os leitos como ocupados, mas a contagem de cobertores permaneceu zero."},
			{title="FICHA DA ENFERMARIA",text="Nenhum paciente registrado. A linha de observação foi preenchida com a mesma frase: 'aguardando transporte'."},
			{title="LISTA DE ENTRADA",text="A lista tem onze nomes, todos recebidos às 03:17. A assinatura do recebedor é R. Vale; o endereço é Bloco 11, apartamento 11."},
		},
		PuzzleOrder={"B","A","C"}, CoopStep=2,
		StepLabels={A={Action="PULSEIRAS",Object="Estação 1"},B={Action="FICHAS",Object="Estação 2"},C={Action="SUPRIMENTOS",Object="Estação 3"}},
		Completion={title="CAPÍTULO 8 • ALA DE TRIAGEM",text="Nenhum morador chegou ao abrigo. A lista foi preenchida como se o grupo tivesse sido recebido e transferido. O próximo endereço e um bloco residencial sem registro de ocupação."},
	},
	[9] = {
		Title="Bloco de Transferência", Theme="apartments", Location="Bloco 11",
		Prologue={"O Bloco 11 consta como destino da transferência.","Os apartamentos estão mobiliados; as caixas têm etiquetas com nomes diferentes.","Todas as fechaduras foram trocadas na mesma noite."},
		Objectives={[0]="Investigue os três apartamentos com etiquetas de transferência.",[1]="Combine as fichas de morador com os objetos deixados para trás.",[2]="Abra a fechadura cooperativa da sala de recebimento.",[3]="Examine o livro de entrada e registre a divergência.",[4]="O Bloco nunca recebeu moradores; as caixas foram preparadas como cenário.",[5]="Capítulo concluído."},
		Clues={
			{title="ETIQUETA 11-A",text="Nome: Elisa Moura. Conteúdo: uma chave de casa, duas fotografias e um cartão de ônibus sem validação."},
			{title="ETIQUETA 11-B",text="Nome: Davi Nunes. Conteúdo: um relógio parado às 03:17 e uma ficha de abrigo em branco."},
			{title="LIVRO DE ENTRADA",text="Nenhuma chave foi entregue. Todos os apartamentos aparecem ocupados antes da data oficial de transferência."},
		},
		PuzzleOrder={"C","B","A"}, CoopStep=1,
		StepLabels={A={Action="11-A",Object="Fechadura"},B={Action="11-B",Object="Trava"},C={Action="RECEPÇÃO",Object="Registro"}},
		Completion={title="CAPÍTULO 9 • BLOCO DE TRANSFERÊNCIA",text="As caixas nunca foram entregues a moradores. Os nomes foram retirados de uma lista de chamadas, não de um cadastro habitacional. O mesmo endereço aparece no relatório do repetidor principal."},
	},
	[10] = {
		Title="03:17", Theme="relay", Location="Câmara do Repetidor",
		Prologue={"A câmara está ligada desde a noite da evacuação.","Três válvulas controlam o retorno, mas uma delas está quente.","O gravador recomenda uma sequência diferente a cada repetição."},
		Objectives={[0]="Inspecione válvulas, relés e o gravador central.",[1]="Reconstitua a sequência anotada no registro de manutenção.",[2]="Acione os três controles na ordem: distribuição, retorno, sincronismo.",[3]="Recupere a transmissão que atravessou a evacuação.",[4]="A voz pede que alguém mantenha a linha aberta para servir de testemunha.",[5]="Capítulo concluído."},
		Clues={
			{title="REGISTRO DAS VÁLVULAS",text="Distribuição primeiro. Retorno segundo. Sincronismo por último. Se o retorno fechar antes da distribuição, o circuito grava o som do próprio operador."},
			{title="RELÉ 03",text="O relé foi trocado no dia seguinte ao fechamento do distrito. A peça retirada tem uma etiqueta com a data de hoje."},
			{title="FITA DE SINCRONISMO",text="A mesma chamada aparece em onze ramais. Em cada cópia, a voz está mais perto do microfone, embora os aparelhos estejam em locais diferentes."},
		},
		PuzzleOrder={"A","B","C"}, CoopStep=2,
		StepLabels={A={Action="DISTRIBUIÇÃO",Object="Válvula 1"},B={Action="RETORNO",Object="Válvula 2"},C={Action="SINCRONISMO",Object="Válvula 3"}},
		Completion={title="CAPÍTULO 10 • 03:17",text="O circuito repete chamadas, mas não as cria. A origem está no transmissor municipal. A pessoa que alterou os registros conhece a voz que aparece nas fitas."},
	},
	[11] = {
		Title="A Testemunha", Theme="radio", Location="Torre Municipal",
		Prologue={"A torre foi desativada, mas a antena ainda transmite.","A sala de gravação guarda o rolo integral e um microfone ligado.","Uma pessoa responde pelo rádio usando o nome R. Vale."},
		Objectives={[0]="Encontre o rolo integral e o painel de transmissão.",[1]="Compare a fita física com o sinal ao vivo.",[2]="Sincronize o gravador e mantenha a transmissão protegida em dupla.",[3]="Ouça o depoimento completo e registre a identidade da testemunha.",[4]="R. Vale afirma que recebeu uma chamada de dentro do distrito.",[5]="Capítulo concluído."},
		Clues={
			{title="ROLO INTEGRAL",text="A fita tem onze canais separados. O canal 11 contém uma pessoa pedindo ajuda; os outros dez repetem a resposta do operador."},
			{title="SINAL AO VIVO",text="A voz identifica R. Vale como operadora da noite da evacuação. Ela diz que a ordem chegou pelo canal de emergência, sem origem registrada."},
			{title="ANOTAÇÃO DA TESTEMUNHA",text="A operadora escreveu: 'Eu mudei o relatório porque a voz usou meu nome. Não sei se veio da linha ou de dentro da sala.'"},
		},
		PuzzleOrder={"B","C","A"}, CoopStep=2,
		StepLabels={A={Action="FITA",Object="Gravador"},B={Action="ANTENA",Object="Sinal ao vivo"},C={Action="MESA",Object="Transmissao"}},
		Completion={title="CAPÍTULO 11 • A TESTEMUNHA",text="R. Vale confirma que adulterou a ordem de saída, mas nega ter criado a chamada. A fita original registra um detalhe que ela não contou: uma segunda respiração no microfone, antes de qualquer voz."},
	},
	[12] = {
		Title="A Última Chamada", Theme="aurora", Location="Edifício Aurora",
		Prologue={"A equipe retorna ao Aurora, onde tudo começou.","O repetidor principal espera no antigo quarto de manutenção.","A chamada pede dois nomes; a testemunha diz para não responder."},
		Objectives={[0]="Volte ao corredor do 304 e localize a caixa do repetidor.",[1]="Use as provas reunidas para abrir o painel final.",[2]="Feche o circuito em dupla enquanto o Ouvinte percorre o andar.",[3]="Escolha: transmita a prova ou corte a linha.",[4]="A decisão altera o destino da chamada e o epílogo.",[5]="Campanha concluída."},
		Clues={
			{title="FIO DO 304",text="O fio novo atrás do espelho não alimentava o apartamento. Ele levava a uma caixa instalada no dia da evacuação."},
			{title="REGISTRO DE R. VALE",text="A testemunha escreveu que a chamada pedia dois nomes. O formulário de despacho foi alterado depois que ela respondeu."},
			{title="ÚLTIMA TRANSCRIÇÃO",text="A fita contém o primeiro chamado e o último ao mesmo tempo. A voz do outro lado diz: 'Não desliguem. Ainda falta alguém atender.'"},
		},
		PuzzleOrder={"C","A","B"}, CoopStep=2, FinalChoice=true,
		StepLabels={A={Action="ABRIR PAINEL",Object="Repetidor"},B={Action="RETORNO",Object="Circuito"},C={Action="SINCRONIZAR",Object="Linha"}},
		Endings={
			Transmit={title="FINAL • A PROVA",text="A equipe transmite a fita integral para os canais de emergência. O Distrito 11 deixa de ser um rumor: onze chamadas, onze registros falsos e uma voz que ainda responde. A última transmissão termina com o indicativo de vocês."},
			Cut={title="FINAL • LINHA CORTADA",text="A equipe corta o repetidor e interrompe o retorno. O silêncio dura até o amanhecer. No relatório, os nomes dos técnicos aparecem como a última chamada recebida, mas sem horário de encerramento."},
		},
		Completion={title="CAMPANHA CONCLUÍDA",text="A última chamada foi atendida. O que aconteceu com o Distrito 11 agora depende da decisão da equipe."},
	},
}

function LaterChapterStory.Get(chapterId)
	return LaterChapterStory.Chapters[chapterId]
end

return LaterChapterStory