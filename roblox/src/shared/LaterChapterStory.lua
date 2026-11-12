local LaterChapterStory = {}

LaterChapterStory.Chapters = {
	[4] = {
		Title="A Cidade Vazia", Theme="street", Location="Avenida Norte",
		Prologue={"A cabine da Avenida Norte ainda recebe energia do ramal 11.","A lista oficial diz que todos os moradores embarcaram.","As marcas no meio-fio contam outra historia: nenhum onibus parou aqui."},
		Objectives={[0]="Atenda a cabine de emergencia.",[1]="Recolha o livro de transporte e o registro da cabine.",[2]="Roteie a chamada pela sequencia indicada nos tres avisos.",[3]="Registre o destino real dos onibus no posto de evacuacao.",[4]="A chamada aponta para a antiga Central Municipal.",[5]="Capitulo concluido."},
		Clues={
			{title="QUADRO DE LINHAS",text="A linha 11 foi desviada para a Avenida Norte as 02:41. O campo de passageiros foi preenchido antes da chegada do primeiro onibus."},
			{title="REGISTRO DA CABINE",text="A cabine recebeu uma chamada as 03:17. A voz do atendente pede para confirmar tres pontos da rota: terminal, retorno, garagem."},
			{title="TALAO DE EMBARQUE",text="Onze bilhetes foram impressos, mas nenhum foi validado. No verso, a mesma letra escreveu: 'Nao houve embarque. A ordem veio da Central.'"},
		},
		PuzzleOrder={"A","B","C"}, CoopStep=2,
		StepLabels={A={Action="Terminal",Object="Rota 1"},B={Action="Retorno",Object="Rota 2"},C={Action="Garagem",Object="Rota 3"}},
		Completion={title="CAPITULO 4 • A CIDADE VAZIA",text="Os bilhetes nunca foram usados. A ordem de marcar a evacuacao veio da Central Municipal antes de qualquer onibus chegar. A linha registrada no talão aponta para a sala de despacho."},
	},
	[5] = {
		Title="Central de Chamadas", Theme="callcenter", Location="Central Municipal",
		Prologue={"A Central foi lacrada depois da evacuacao.","Onze chamadas continuam na mesa, cada uma com um horario diferente.","A gravacao mais recente tem a voz de um operador que afirma estar sozinho."},
		Objectives={[0]="Examine os rolos e o quadro de despacho.",[1]="Encontre as tres fichas que ainda tem horario legivel.",[2]="Reordene as chamadas na mesa de gravacao.",[3]="Reproduza a fita integral e registre a origem do despacho.",[4]="A ordem da evacuacao foi emitida daqui, antes do primeiro chamado.",[5]="Capitulo concluido."},
		Clues={
			{title="FICHA DE DESPACHO A",text="02:41 — ramal 11 — solicitada ambulancia para o Distrito 11. A linha estava muda durante 19 segundos antes da resposta."},
			{title="FICHA DE DESPACHO B",text="03:02 — ordem interna: preparar retirada total. Campo de autorizacao sem assinatura; carimbo aplicado 15 minutos depois."},
			{title="FICHA DE DESPACHO C",text="03:17 — chamada recebida da sala de operacao, que estava vazia segundo o controle de acesso."},
		},
		PuzzleOrder={"A","C","B"}, CoopStep=0,
		StepLabels={A={Action="02:41",Object="Rolo 1"},B={Action="03:02",Object="Rolo 2"},C={Action="03:17",Object="Rolo 3"}},
		Completion={title="CAPITULO 5 • CENTRAL DE CHAMADAS",text="A ordem de retirada foi registrada antes de qualquer pedido de ajuda. A fita original foi levada ao Arquivo Municipal; a copia da Central foi editada. O numero de custodia termina em 0317."},
	},
	[6] = {
		Title="Arquivo 03:17", Theme="archive", Location="Arquivo Municipal",
		Prologue={"O arquivo guarda o original que a Central diz ter destruido.","As estantes foram reorganizadas depois do fechamento.","Algumas caixas tem poeira por cima e marcas recentes por baixo."},
		Objectives={[0]="Localize a sala de consulta e procure o registro de custodia.",[1]="Leia a folha de saida, o carimbo e a ficha de transferencia.",[2]="Classifique os documentos pela ordem correta.",[3]="Abra o armario de custodia e recolha a fita original.",[4]="O manifesto nao confirma a evacuacao; ele registra uma transferencia sem destino.",[5]="Capitulo concluido."},
		Clues={
			{title="FOLHA DE SAIDA",text="A lista foi impressa as 03:17. O campo 'saida confirmada' esta marcado, mas o livro de portaria nao registra veiculos no perimetro."},
			{title="CARIMBO DE CUSTODIA",text="A matriz do carimbo foi usada antes da folha existir. O lote do carimbo pertence ao turno seguinte."},
			{title="FICHA DE TRANSFERENCIA",text="Destino apagado. Quantidade: onze volumes. Responsavel: R. Vale. Um segundo carimbo aponta para a Linha de Servico."},
		},
		PuzzleOrder={"B","C","A"}, CoopStep=0,
		StepLabels={A={Action="Impressao",Object="Etapa 1"},B={Action="Carimbo",Object="Etapa 2"},C={Action="Custodia",Object="Etapa 3"}},
		Completion={title="CAPITULO 6 • ARQUIVO 03:17",text="A fita original nao contem uma lista de passageiros. Contem onze ramais ativos e um pedido para manter a Linha de Servico ligada. O nome R. Vale aparece novamente na subestacao."},
	},
	[7] = {
		Title="Linha de Servico", Theme="tunnel", Location="Subestacao Auxiliar",
		Prologue={"A Linha de Servico passa por baixo do perimetro evacuado.","A bateria de emergencia foi removida do suporte e deixada no tunel.","A porta atras de voces nao vai continuar aberta por muito tempo."},
		Objectives={[0]="Encontre o suporte e as duas alcas da bateria pesada.",[1]="Levante a bateria em dupla e leve-a ao receptaculo.",[2]="Restaure os tres trechos do circuito na ordem do diagrama.",[3]="Abra a passagem de retorno e recupere o registro da subestacao.",[4]="O consumo da linha coincide com a ala de triagem.",[5]="Capitulo concluido."},
		Clues={
			{title="DIAGRAMA DE CABOS",text="Trecho 1 alimenta a ala de triagem. Trecho 2 retorna ao repetidor. Trecho 3 foi ligado depois da evacuacao por alguem que conhecia o circuito."},
			{title="ETIQUETA DA BATERIA",text="Bateria de chumbo, 86 kg. Transporte com duas pessoas. A alca esquerda esta travada."},
			{title="ORDEM DA SUBESTACAO",text="Manter ativo ate receber confirmacao da triagem. Assinatura: R. Vale. A hora foi escrita por cima: 03:17."},
		},
		PuzzleOrder={"A","C","B"}, CoopStep=2, RequiresBattery=true,
		StepLabels={A={Action="TRECHO 1",Object="Distribuicao"},B={Action="TRECHO 2",Object="Retorno"},C={Action="TRECHO 3",Object="Repetidor"}},
		Completion={title="CAPITULO 7 • LINHA DE SERVICO",text="A bateria manteve um circuito vivo sob o bairro. O ramal vai para o abrigo de triagem. A ultima mensagem da subestacao pede para conferir as pulseiras antes de desligar qualquer coisa."},
	},
	[8] = {
		Title="Ala de Triagem", Theme="triage", Location="Ginasio Aurora",
		Prologue={"O ginasio foi convertido em abrigo na noite da evacuacao.","As camas estao arrumadas, mas nenhuma tem marcas de uso.","No balcao, as pulseiras foram contadas onze vezes."},
		Objectives={[0]="Compare o mapa das camas com as pulseiras.",[1]="Procure a ficha da enfermaria e a lista de entrada.",[2]="Ligue a luz da ala e confira as tres estacoes de suprimentos.",[3]="Registre quem foi atendido e quem nunca chegou.",[4]="O endereco de transferencia leva ao Bloco 11.",[5]="Capitulo concluido."},
		Clues={
			{title="MAPA DAS CAMAS",text="Onze camas foram reservadas. A equipe marcou os leitos como ocupados, mas a contagem de cobertores permaneceu zero."},
			{title="FICHA DA ENFERMARIA",text="Nenhum paciente registrado. A linha de observacao foi preenchida com a mesma frase: 'aguardando transporte'."},
			{title="LISTA DE ENTRADA",text="A lista tem onze nomes, todos recebidos as 03:17. A assinatura do recebedor e R. Vale; o endereco e Bloco 11, apartamento 11."},
		},
		PuzzleOrder={"B","A","C"}, CoopStep=2,
		StepLabels={A={Action="PULSEIRAS",Object="Estacao 1"},B={Action="FICHAS",Object="Estacao 2"},C={Action="SUPRIMENTOS",Object="Estacao 3"}},
		Completion={title="CAPITULO 8 • ALA DE TRIAGEM",text="Nenhum morador chegou ao abrigo. A lista foi preenchida como se o grupo tivesse sido recebido e transferido. O proximo endereco e um bloco residencial sem registro de ocupacao."},
	},
	[9] = {
		Title="Bloco de Transferencia", Theme="apartments", Location="Bloco 11",
		Prologue={"O Bloco 11 consta como destino da transferencia.","Os apartamentos estao mobiliados; as caixas tem etiquetas com nomes diferentes.","Todas as fechaduras foram trocadas na mesma noite."},
		Objectives={[0]="Investigue os tres apartamentos com etiquetas de transferencia.",[1]="Combine as fichas de morador com os objetos deixados para tras.",[2]="Abra a fechadura cooperativa da sala de recebimento.",[3]="Examine o livro de entrada e registre a divergencia.",[4]="O Bloco nunca recebeu moradores; as caixas foram preparadas como cenario.",[5]="Capitulo concluido."},
		Clues={
			{title="ETIQUETA 11-A",text="Nome: Elisa Moura. Conteudo: uma chave de casa, duas fotografias e um cartao de onibus sem validacao."},
			{title="ETIQUETA 11-B",text="Nome: Davi Nunes. Conteudo: um relogio parado as 03:17 e uma ficha de abrigo em branco."},
			{title="LIVRO DE ENTRADA",text="Nenhuma chave foi entregue. Todos os apartamentos aparecem ocupados antes da data oficial de transferencia."},
		},
		PuzzleOrder={"C","B","A"}, CoopStep=1,
		StepLabels={A={Action="11-A",Object="Fechadura"},B={Action="11-B",Object="Trava"},C={Action="RECEPCAO",Object="Registro"}},
		Completion={title="CAPITULO 9 • BLOCO DE TRANSFERENCIA",text="As caixas nunca foram entregues a moradores. Os nomes foram retirados de uma lista de chamadas, nao de um cadastro habitacional. O mesmo endereco aparece no relatorio do repetidor principal."},
	},
	[10] = {
		Title="03:17", Theme="relay", Location="Camara do Repetidor",
		Prologue={"A camara esta ligada desde a noite da evacuacao.","Tres valvulas controlam o retorno, mas uma delas esta quente.","O gravador recomenda uma sequencia diferente a cada repeticao."},
		Objectives={[0]="Inspecione valvulas, relés e o gravador central.",[1]="Reconstitua a sequencia anotada no registro de manutencao.",[2]="Acione os tres controles na ordem: distribuicao, retorno, sincronismo.",[3]="Recupere a transmissao que atravessou a evacuacao.",[4]="A voz pede que alguem mantenha a linha aberta para servir de testemunha.",[5]="Capitulo concluido."},
		Clues={
			{title="REGISTRO DAS VALVULAS",text="Distribuicao primeiro. Retorno segundo. Sincronismo por ultimo. Se o retorno fechar antes da distribuicao, o circuito grava o som do proprio operador."},
			{title="RELE 03",text="O rele foi trocado no dia seguinte ao fechamento do distrito. A peca retirada tem uma etiqueta com a data de hoje."},
			{title="FITA DE SINCRONISMO",text="A mesma chamada aparece em onze ramais. Em cada copia, a voz esta mais perto do microfone, embora os aparelhos estejam em locais diferentes."},
		},
		PuzzleOrder={"A","B","C"}, CoopStep=2,
		StepLabels={A={Action="DISTRIBUICAO",Object="Valvula 1"},B={Action="RETORNO",Object="Valvula 2"},C={Action="SINCRONISMO",Object="Valvula 3"}},
		Completion={title="CAPITULO 10 • 03:17",text="O circuito repete chamadas, mas nao as cria. A origem esta no transmissor municipal. A pessoa que alterou os registros conhece a voz que aparece nas fitas."},
	},
	[11] = {
		Title="A Testemunha", Theme="radio", Location="Torre Municipal",
		Prologue={"A torre foi desativada, mas a antena ainda transmite.","A sala de gravacao guarda o rolo integral e um microfone ligado.","Uma pessoa responde pelo radio usando o nome R. Vale."},
		Objectives={[0]="Encontre o rolo integral e o painel de transmissao.",[1]="Compare a fita fisica com o sinal ao vivo.",[2]="Sincronize o gravador e mantenha a transmissao protegida em dupla.",[3]="Ouça o depoimento completo e registre a identidade da testemunha.",[4]="R. Vale afirma que recebeu uma chamada de dentro do distrito.",[5]="Capitulo concluido."},
		Clues={
			{title="ROLO INTEGRAL",text="A fita tem onze canais separados. O canal 11 contem uma pessoa pedindo ajuda; os outros dez repetem a resposta do operador."},
			{title="SINAL AO VIVO",text="A voz identifica R. Vale como operadora da noite da evacuacao. Ela diz que a ordem chegou pelo canal de emergencia, sem origem registrada."},
			{title="ANOTACAO DA TESTEMUNHA",text="A operadora escreveu: 'Eu mudei o relatorio porque a voz usou meu nome. Nao sei se veio da linha ou de dentro da sala.'"},
		},
		PuzzleOrder={"B","C","A"}, CoopStep=2,
		StepLabels={A={Action="FITA",Object="Gravador"},B={Action="ANTENA",Object="Sinal ao vivo"},C={Action="MESA",Object="Transmissao"}},
		Completion={title="CAPITULO 11 • A TESTEMUNHA",text="R. Vale confirma que adulterou a ordem de saida, mas nega ter criado a chamada. A fita original registra um detalhe que ela nao contou: uma segunda respiração no microfone, antes de qualquer voz."},
	},
	[12] = {
		Title="A Ultima Chamada", Theme="aurora", Location="Edificio Aurora",
		Prologue={"A equipe retorna ao Aurora, onde tudo comecou.","O repetidor principal espera no antigo quarto de manutencao.","A chamada pede dois nomes; a testemunha diz para nao responder."},
		Objectives={[0]="Volte ao corredor do 304 e localize a caixa do repetidor.",[1]="Use as provas reunidas para abrir o painel final.",[2]="Feche o circuito em dupla enquanto o Ouvinte percorre o andar.",[3]="Escolha: transmita a prova ou corte a linha.",[4]="A decisao altera o destino da chamada e o epilogo.",[5]="Campanha concluida."},
		Clues={
			{title="FIO DO 304",text="O fio novo atras do espelho nao alimentava o apartamento. Ele levava a uma caixa instalada no dia da evacuacao."},
			{title="REGISTRO DE R. VALE",text="A testemunha escreveu que a chamada pedia dois nomes. O formulario de despacho foi alterado depois que ela respondeu."},
			{title="ULTIMA TRANSCRICAO",text="A fita contem o primeiro chamado e o ultimo ao mesmo tempo. A voz do outro lado diz: 'Nao desliguem. Ainda falta alguem atender.'"},
		},
		PuzzleOrder={"C","A","B"}, CoopStep=2, FinalChoice=true,
		StepLabels={A={Action="ABRIR PAINEL",Object="Repetidor"},B={Action="RETORNO",Object="Circuito"},C={Action="SINCRONIZAR",Object="Linha"}},
		Endings={
			Transmit={title="FINAL • A PROVA",text="A equipe transmite a fita integral para os canais de emergencia. O Distrito 11 deixa de ser um rumor: onze chamadas, onze registros falsos e uma voz que ainda responde. A ultima transmissao termina com o indicativo de voces."},
			Cut={title="FINAL • LINHA CORTADA",text="A equipe corta o repetidor e interrompe o retorno. O silencio dura ate o amanhecer. No relatorio, os nomes dos tecnicos aparecem como a ultima chamada recebida, mas sem horario de encerramento."},
		},
		Completion={title="CAMPANHA CONCLUIDA",text="A ultima chamada foi atendida. O que aconteceu com o Distrito 11 agora depende da decisao da equipe."},
	},
}

function LaterChapterStory.Get(chapterId)
	return LaterChapterStory.Chapters[chapterId]
end

return LaterChapterStory