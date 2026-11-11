# LINHA 11 — A Última Chamada

## Direção atual: Roblox

O jogo está sendo reconstruído como uma experiência cooperativa no Roblox. A missão atual, a história e a configuração do lugar ficam em roblox/. O projeto Godot anterior continua preservado no histórico e nos diretórios antigos; ele não é mais a versão ativa.

### Abrir para testar

Arquivo de lugar para Roblox Studio: roblox/LINHA11_Roblox.rbxlx.

No Studio, abra esse arquivo e pressione **Play**. Para testar cooperação, use **Test → 2 Players → Start**. O lugar cria o mapa quando a sessão começa. Depois de publicado no Roblox, convide um amigo pela própria plataforma.

O Roblox Studio não está instalado neste ambiente, então o arquivo foi gerado pelo Rojo e os scripts foram compilados com Luau; a execução dentro do Studio ainda precisa ser confirmada. Esta experiência não pode ser testada no navegador por GitHub Pages, e ainda não foi publicada na conta Roblox. Não há link público de jogo para fornecer neste momento.

### História

Dois técnicos são enviados ao Edifício Aurora antes da demolição para recuperar a fita do circuito ECO. Dezessete anos antes, às 03:17, onze chamadas de emergência ficaram sobrepostas durante uma queda de energia. A cidade registrou uma evacuação sem assinaturas; os registros físicos foram escondidos. O Ouvinte repete trechos dessas chamadas, segue ruídos e pode ser evitado em salas e armários.

A missão tem começo, descoberta, cooperação nas alavancas e dois finais. O roteiro canônico está em roblox/docs/historia-e-missao.md.

### Controles

- WASD e mouse: mover e olhar.
- E: interagir, abrir portas, ler e esconder-se.
- F: lanterna, que começa ligada.
- Shift: correr; correr atrai o Ouvinte.
- Celular e controle: controles padrão do Roblox, prompts e botões na tela.

### Monetização

A entrada e toda a história são gratuitas. A loja prepara dois passes cosméticos opcionais: uma cor âmbar para a lanterna e um distintivo visual. Eles não dão vantagem de jogo. Os IDs estão zerados e a compra fica desativada até a experiência e os passes serem publicados no Creator Hub; o prompt do Roblox exibirá o preço oficial depois disso. Não há loot boxes, checkout externo ou cobrança para avançar na história.

O Creator Hub permite cobrar acesso único em Robux, mas isso fecharia o jogo para quem não puder ou não quiser pagar. Para uma experiência que pode ser jogada por menores, mantive a entrada gratuita e os cosméticos opcionais. A hospedagem do multiplayer não tem mensalidade separada. Para liberar a experiência pública a todas as idades, o Roblox exige idade verificada, 2FA e, atualmente, dois meses de Roblox Plus/Premium ou uma taxa única reembolsável de 1.000 Robux, além da avaliação. O Roblox oferece controles parentais de gastos.

### Gerar o arquivo do Studio

Com Rojo 7.7.1 e Luau 0.746 em build/rojo/rojo.exe e build/luau/luau-compile.exe, execute:

    .\roblox\tools\build-place.ps1

Isso compila os arquivos Luau e gera o .rbxlx. O workflow **Roblox place** faz a mesma validação a cada alteração em roblox/ na branch development e guarda o lugar como artefato do GitHub Actions. Esse workflow não publica automaticamente uma experiência Roblox na conta.

### O que já existe e o que falta

Existe um andar completo em blocos Roblox nativos, com apartamentos 301, 302, 303, 304, 305, zeladoria e repetidor; portas, documentos, senha 0317, fusível, energia, esconderijos, perseguição por ruído, alavancas cooperativas, menu, lanterna, dois finais e loja cosmética.

Ainda faltam o teste de execução no Studio, publicação na conta Roblox, salvamento entre servidores, áudio enviado ao Roblox, malhas e animações finais e capítulos adicionais. O Ouvinte atual é uma silhueta 3D procedural; o arquivo GLB enviado ainda não foi convertido/importado para o Studio.

O endereço antigo de GitHub Pages ainda corresponde à build Godot legada e não é um endereço para jogar esta versão Roblox.
