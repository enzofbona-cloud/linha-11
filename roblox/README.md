# Roblox: LINHA 11 — A Última Chamada

Esta é a reconstrução ativa do jogo como experiência cooperativa do Roblox. A versão Godot permanece no histórico e nos arquivos antigos do repositório; ela não é a experiência atual.

O plano da campanha Roblox, com 12 capítulos e metas de duração, está em [docs/superpowers/plans/2026-11-11-reconstrucao-roblox-12-capitulos.md](../docs/superpowers/plans/2026-11-11-reconstrucao-roblox-12-capitulos.md). A árvore de trabalho local prepara os capítulos 1 e 2 para teste privado; a versão já publicada ainda não foi atualizada com o segundo capítulo. A duração total não foi validada em sessões.

## Teste privado no Roblox

- Página do jogo: [Testar LINHA 11 no Roblox](https://www.roblox.com/games/122255059176252/LINHA-11-A-ltima-Chamada)
- ID da experiência: `10776015621`; ID do lugar inicial: `122255059176252`.
- Publicada em 2026-11-11 como privada. O Creator Hub/Studio confirmou: disponível somente para a conta dona e colaboradores. Nenhum convite foi enviado e o acesso público continua desligado.
- A página de jogo abre para a conta dona. Para jogar, entre na conta Roblox e use o botão azul de iniciar; o Roblox Player precisa estar instalado. O teste em Play Solo no Studio foi confirmado; a abertura do Player pelo navegador ainda não foi verificada.
- Para um segundo jogador testar cooperação, conceda acesso pelo Creator Hub mantendo a experiência privada. Não use a opção de lançamento público.

## Abrir e jogar no Roblox Studio

1. Instale o Roblox Studio e abra roblox/LINHA11_Roblox.rbxlx.
2. No Studio, pressione Play para iniciar um jogador.
3. Para testar cooperação, abra a guia Test, escolha 2 Players e pressione Start.
4. No Creator Hub, ajuste o limite do servidor para dois jogadores antes de publicar.
5. Convide um colaborador pelo Creator Hub se for testar com outra conta; isso mantém o acesso privado.

O mapa é construído pelo servidor quando a sessão começa. O arquivo .rbxlx contém os scripts e a configuração da experiência; ele não é um site para abrir no navegador. GitHub Pages não executa experiências Roblox.

## Controles

- WASD e mouse: mover e olhar.
- E: usar portas, ler documentos, esconder-se e interagir.
- F: lanterna (já começa ligada).
- Shift: correr; correr faz o Ouvinte ouvir e perseguir.
- Celular e controle: movimento padrão do Roblox, botões de ação na tela e prompts compatíveis.

O menu inicial mantém o cursor livre. Ao começar a introdução, a câmera entra em primeira pessoa e o cursor é capturado. Modais de documentos, senha, finais e loja liberam o cursor temporariamente.

## Missão e regras da história

A missão cooperativa do primeiro capítulo está em docs/historia-e-missao.md. O percurso inclui a chave no 305, o fusível na gaveta trancada do 301, três fragmentos da senha nos 301/302/305, o arquivo 303, a fita, o telefone no 304, o Ouvinte e a sala do repetidor. O código é 0317. A história termina em uma escolha entre transmitir a gravação ou cortar a linha.

O capítulo 2 agora tem um mapa separado do apartamento 304, com sala, cozinha, quarto, banheiro, lavanderia, coleta de pistas, derivação elétrica, dois pontos que precisam ser ativados em cooperação, perseguição pelo Ouvinte e uma conclusão que aponta para a escadaria B. Ele é selecionável no menu privado. A compilação Luau/Rojo foi validada; a execução visual e a sessão com dois clientes ainda precisam ser conferidas no Roblox Studio antes de substituir a versão privada publicada.

O estado das pistas, portas, energia, criatura e puzzles é controlado pelo servidor. O segundo jogador precisa acionar a outra alavanca do repetidor; numa sessão solo, a janela de 12 segundos permite testar as duas alavancas com um único jogador. Esconder-se em um guarda-roupa impede o Ouvinte de capturar o jogador.

## Monetização

Há uma loja de passes cosméticos, sem loot boxes nem vantagens de combate:

- Lanterna âmbar: muda somente a cor da luz; não aumenta alcance ou brilho.
- Distintivo Aurora: título visual sobre o personagem.

A campanha, as ferramentas de missão e os dois finais não são pagos. Os IDs dos passes em src/shared/MonetizationConfig.lua estão como 0; compras ficam desativadas até a experiência ser publicada e os passes serem criados no Creator Hub. Depois, substitua os zeros pelos IDs reais. O Roblox mostra o preço oficial no próprio prompt de compra. Não há checkout externo. A documentação atual do Roblox informa que o criador recebe 70% do Robux gasto em compras dentro da experiência; a conversão em dinheiro passa pelo DevEx, com requisitos próprios, incluindo idade mínima de 13 anos e 30.000 Robux ganhos.

O Roblox permite acesso pago único em Robux, mas isso bloquearia a entrada de quem não pagar e reduz a descoberta do jogo. Para este projeto, a escolha é manter a entrada gratuita e usar apenas cosméticos opcionais. A hospedagem dos servidores e o multiplayer não exigem uma mensalidade separada. Para liberar uma experiência pública a usuários de todas as idades, o Roblox atualmente exige verificação de idade, 2FA e assinatura Roblox Plus/Premium ativa por dois meses consecutivos ou uma taxa única reembolsável de 1.000 Robux; a experiência também passa por avaliação. Para acesso público restrito a usuários com verificação de idade a partir de 16 anos, há requisitos diferentes e não se aplica essa taxa de alcance para todas as idades. As regras podem mudar. Para menores de 16 anos, a classificação e o alcance dependem da análise do Roblox. Responsáveis podem configurar limites de gastos.

## Validar e gerar o lugar

Requisitos locais: Rojo 7.7.1 e Luau 0.746. O script procura os binários em build/rojo/rojo.exe e build/luau/luau-compile.exe:

    .\roblox\tools\build-place.ps1

O script compila cada arquivo Luau e gera roblox/LINHA11_Roblox.rbxlx. O workflow Roblox place repete essas verificações a cada push de roblox/** em development e deixa o .rbxlx disponível como artefato do GitHub Actions.

## Limites desta entrega

- Esta pasta contém a primeira reconstrução jogável da missão, não os seis capítulos originais.
- O mapa usa materiais e peças nativas do Roblox para manter o lugar leve; arte de alta qualidade, malhas personalizadas, animações articuladas, voz e efeitos sonoros com IDs publicados ainda precisam de uma etapa de assets no Studio.
- O Ouvinte desta versão é um modelo procedural de silhueta 3D. Ele não usa ainda o arquivo GLB enviado: o modelo precisa ser convertido e importado pelo Studio.
- Não há salvamento entre servidores. O progresso compartilhado existe durante a sessão.
- O .rbxlx foi aberto e testado em Play Solo no Roblox Studio. A sessão publicada pelo Roblox Player, dois clientes simultâneos e a conclusão completa da missão ainda não foram verificados.



## Atualizacao local - 2026-11-11

- Capitulo 2 (Apartamento 304): a arvore local tem o mapa, progressao e puzzle cooperativo. Corrigi a conexao dos eventos dos prompts: antes, os prompts desse mapa nao chegavam ao servidor.
- Capitulo 3 (Sem Sinal): a build local inclui escadaria B, elevador de servico, sala tecnica, documentos de investigacao, puzzle de dois disjuntores em dupla, aparicao do Ouvinte apos religar o circuito e conclusao que encaminha a equipe para a rua.
- Verificacao desta atualizacao: compilacao Luau e geracao Rojo do place. Ainda falta abrir esta build no Roblox Studio, revisar visualmente cada espaco e testar com dois clientes.
- Esta arvore de trabalho ainda nao foi enviada ao Roblox, ao GitHub ou ao branch development. A ultima experiencia privada publicada nao inclui estes capitulos.
## Campanha local completa em prototipo - 2026-11-11

- A selecao local agora habilita os capitulos 1 a 12.
- Os capitulos 4 a 12 ganharam mapas tematicos, tres documentos de historia por missao, sequencias de interacao especificas, objetivos e conclusoes que ligam cada descoberta ao capitulo seguinte.
- O capitulo 7 usa duas alcas para levantar a bateria em conjunto; o capitulo 12 oferece os finais Transmitir a Prova e Cortar a Linha.
- A build local passou no compilador Luau e foi gerada pelo Rojo. Isso confirma sintaxe e montagem do place, nao confirma jogabilidade no Roblox Studio.
- Faltam testes Play Solo e com dois clientes, capturas de cada ambiente, medida de duracao, salvamento persistente, revisao de mobile/desempenho e verificacao dos finais no cliente.
- Nada desta atualizacao foi enviado ao GitHub ou publicado no Roblox. A experiencia privada remota continua na versao anterior.