# Prompt para o ChatGPT (Codex): parte visual

Copie tudo o que está abaixo da linha e cole no ChatGPT.

---

Você vai trabalhar no jogo **LINHA 11 — A Última Chamada**, um terror cooperativo em primeira pessoa feito em **Godot 4.7.2 com GDScript**. O projeto está em `C:\Dev\linha-11`, branch `development`. Outro agente (Claude) cuida de programação, som, controles e testes. **A sua parte é só a visual.**

## Objetivo

Trocar todos os objetos feitos de blocos por **modelos 3D reais**, com aparência semirrealista, nos dois capítulos jogáveis. Hoje a cama, o armário, o criado-mudo, as mesas, o sofá, o fusível, a chave, o telefone e o quadro de força são caixas com textura. Quero móveis e objetos que pareçam de verdade: uma cama com colchão, travesseiro e estrado; um guarda-roupa com portas e puxadores; um criado-mudo com gaveta; um fusível de vidro com pontas metálicas; uma chave com dentes; um telefone antigo de disco.

Estilo: prédio residencial brasileiro abandonado há 17 anos. Móveis dos anos 80 e 90, gastos, empoeirados, alguns tombados. Nada de aparência de brinquedo, plástico, massinha ou desenho animado.

## Onde estão os objetos hoje

- Capítulo 1: `game/scenes/prototype/prototype.gd`, funções `_build_furniture()`, `_build_items()`, `_build_phone()` e `_table()`.
- Capítulo 2: `game/scenes/chapter2/apartment_304.gd`, funções `_build_furniture()`, `_build_evidence()` e `_table()`.
- Telefones do puzzle: `game/interact/sequence_phone.gd`. Gravador: `game/interact/tape_recorder.gd`.
- As caixas são criadas por `LevelKit.box(...)` em `game/world/level_kit.gd`.

Leia esses arquivos antes de começar.

## Como fazer

1. **Modelos em `.glb`** (glTF binário), salvos em `assets/models/<categoria>/<nome>.glb`. Exemplos de categoria: `furniture`, `props`, `electrical`.
2. Crie em `LevelKit` uma função para instanciar um modelo já com colisão, por exemplo `LevelKit.model(parent, nome, caminho, posição, rotação_y, tamanho_da_colisão)`. A colisão deve ser uma **caixa simples** (`BoxShape3D`), nunca a malha do modelo.
3. Substitua cada chamada de `LevelKit.box` de mobília pela versão com modelo, **mantendo a mesma posição e o mesmo tamanho de colisão**, para o jogador não ficar preso nem atravessar nada.
4. Para objetos que o jogador pega ou usa (fusível, chave, telefone, quadro de força, teclado, documentos), troque só a parte visual (o `MeshInstance3D`). **Não mexa na colisão, no script nem no nome do nó.**

## Limites técnicos obrigatórios

O jogo roda no navegador (WebGL2, renderizador Compatibility) e precisa funcionar em PC fraco, com vídeo integrado.

- No máximo **8.000 triângulos** por móvel grande e **1.500** por objeto pequeno.
- Texturas de no máximo **1024×1024**, em JPG ou PNG. Use cor, normal e rugosidade. Sem texturas 2K ou 4K.
- Um material por modelo sempre que possível.
- Nada de recursos que só existem no Forward+ (SDFGI, luz volumétrica, SSR). Teste sempre com `--rendering-method gl_compatibility`.
- Nenhum arquivo pode passar de **100 MB**. O build Web inteiro hoje tem 69 MB; não deixe passar de **150 MB**.
- Arquivos `.glb`, `.png` e `.jpg` já entram no Git LFS automaticamente (veja `.gitattributes`).

## Licenças

O jogo será vendido na Steam. Use **somente** modelos e texturas com licença que permita uso comercial:

- Preferência: **CC0** (Poly Haven, ambientCG, Kenney, Quaternius quando o estilo servir).
- Aceitável: CC-BY, desde que você registre o autor.
- Proibido: qualquer coisa "somente uso pessoal", "editorial", ou extraída de outros jogos.

Se você gerar um modelo ou imagem com IA, diga isso claramente e confirme que os termos da ferramenta permitem uso comercial.

Registre **cada** arquivo em `assets/models/LICENCAS.md`: nome do arquivo, origem (link), autor e licença. Já existe um exemplo do formato em `assets/textures/LICENCAS.md`.

## O que você NÃO pode mexer

Estes arquivos são do outro agente. Não altere:

- `game/core/play_session.gd` (captura do mouse e pausa)
- `game/player/player.gd`
- `game/audio/` e `assets/audio/`
- `game/enemy/listener.gd` e `game/enemy/listener_puppet.gdshader`
- `game/ui/` (menus, HUD, painéis, controles de toque)
- `tools/e2e/`, `.github/`, `export_presets.cfg`, `project.godot`
- A lógica dos scripts em `game/interact/` (pode trocar só a parte visual)

Não mude a sequência dos capítulos, os textos, as senhas nem as posições das portas.

## Nomes de nós que os testes usam (não renomeie)

Capítulo 1: `Player`, `Door302`, `Door303`, `Door304`, `Keypad303`, `FuseBox`, `Fuse`, `Key304`, `Phone`, `Notice`, `Diary`, `Transcript`.

Capítulo 2: `FamilyPhoto304Image`, `FutureArgumentTape`, `SequencePhone0`, `SequencePhone1`, `SequencePhone2`, `ImpossibleExit`, `PhoneSequence`.

O fusível fica em cima do criado-mudo do 302 e a chave e a transcrição em cima da mesa do 303. Se a altura do móvel novo for diferente, ajuste a posição desses itens para ficarem apoiados na superfície, visíveis e alcançáveis (a distância de interação é 2,2 m).

## Como verificar

O executável do Godot está em:
`C:\Users\enzof\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe`

Antes de qualquer commit:

1. **Importar e rodar os testes** (devem passar os 71 que existem hoje, mais os que você criar):
   ```bash
   GODOT="<caminho acima>" tools/test.sh
   ```
2. **Tirar capturas e olhar o resultado**:
   ```bash
   "<godot>" --path . --rendering-method gl_compatibility --resolution 1280x720 -s tools/screenshot.gd -- build/shots
   "<godot>" --path . --rendering-method gl_compatibility --resolution 1280x720 -s tools/screenshot_chapter2.gd -- build/shots2
   ```
   Abra as imagens e confirme que os móveis aparecem, estão no chão (não flutuando nem enterrados), na escala certa (uma cama de solteiro tem cerca de 1,9 m × 0,9 m; uma porta tem 2,1 m de altura) e com textura.
3. **Compilar a versão Web e conferir o tamanho**:
   ```bash
   GODOT="<godot>" tools/build-site.sh dev
   ```
4. **Teste no navegador real** (precisa passar 12 de 12):
   ```bash
   node tools/e2e/web-smoke.mjs build/site --headful
   ```

Adicione um teste em `tests/` que confirme que cada modelo novo carrega e que os móveis continuam com colisão.

## Commits e publicação

- Trabalhe na branch `development`. Antes de começar, rode `git pull`.
- Commits pequenos, em português, no padrão `art: adiciona modelo da cama do 302`.
- Só faça `git push` depois que os testes passarem. O GitHub Actions publica sozinho em https://enzofbona-cloud.github.io/linha-11-web/dev/
- Depois do push, confirme que o Actions ficou verde com `gh run list -R enzofbona-cloud/linha-11 --limit 1`.
- Não use `git push --force` e não reescreva o histórico.

## Densidade: ambientes cheios, como casas de verdade

Este é o ponto mais importante para o dono do projeto. Hoje cada cômodo tem três ou quatro objetos e parece um depósito vazio. Ele quer **cômodos repletos**, como se uma família tivesse morado ali e saído às pressas no meio da noite: muita mobília, objetos em cima de cada superfície, coisas caídas no chão, roupa largada, louça na pia, quadros tortos.

Regra prática: **nenhuma parede vazia e nenhuma superfície vazia**. Cada cômodo deve ter no mínimo 25 objetos visíveis, somando móveis, objetos de superfície e bagunça de chão.

Conte uma história com a bagunça. As pessoas foram embora de repente:
- prato com comida na mesa e cadeira afastada;
- cama desfeita, com o cobertor arrastado até o chão;
- mala aberta e meio cheia, abandonada;
- televisão ligada na tomada, controle caído;
- brinquedo de criança no meio do caminho;
- telefone fora do gancho, com o fio esticado;
- 17 anos de abandono por cima: poeira, teias, reboco caído, papel de parede descolando, mancha de infiltração, vidro quebrado, folhas secas perto das janelas.

### Lista por ambiente

Estas listas são o mínimo. Acrescente o que fizer sentido.

**Corredor do 3º andar (Capítulo 1)**
- Luminárias de teto reais (calha com lâmpada fluorescente), uma delas pendurada por um fio.
- Extintor na parede e caixa de mangueira de incêndio.
- Placas com os números 302, 303 e 304 nas portas; olho mágico e campainha.
- Banco de madeira, vaso com planta morta, capacho em cada porta.
- Caixa de correio coletiva ou quadro de avisos com papéis antigos.
- Carrinho de feira ou bicicleta infantil encostada.
- Sacos de lixo, jornais velhos, um sapato perdido, cacos de reboco.
- Fiação aparente e um interruptor ao lado de cada porta.
- Rodapé, guarnições das portas e uma janela gradeada no fim do corredor, se couber.

**Apartamento 302 — quarto (Capítulo 1)**
- Cama de solteiro com colchão, lençol, travesseiro e cobertor caindo no chão.
- Criado-mudo com gaveta entreaberta, abajur, despertador parado, copo e cartela de remédio.
- Guarda-roupa de duas portas, uma aberta, com roupas em cabides e caixas em cima.
- Cômoda com espelho, pente, perfume e porta-retratos.
- Cadeira com roupa pendurada, chinelos ao lado da cama, tapete.
- Cortina rasgada e janela; ventilador de pé ou de teto.
- Estante pequena com livros e revistas, alguns caídos.
- Mala aberta no chão, pilha de roupa, sapatos espalhados.
- Crucifixo ou quadro na parede, calendário parado em agosto, tomada com fio.
- **O diário (`Diary`) fica na cama e o fusível (`Fuse`) no criado-mudo: os dois precisam continuar fáceis de ver.**

**Apartamento 303 — sala de trabalho/depósito (Capítulo 1)**
- Mesa de escritório com gavetas, cadeira giratória tombada.
- Máquina de escrever ou computador antigo, luminária de mesa, cinzeiro, caneca, telefone.
- Estante de metal cheia: pastas, caixas de arquivo, rolos de fio, ferramentas, rádio.
- Arquivo de aço com gaveta puxada e papéis espalhados pelo chão.
- Caixas de papelão empilhadas e uma tombada, com o conteúdo derramado.
- Quadro de cortiça com recortes e um mapa do bairro.
- Sofá pequeno ou poltrona, mesinha com revistas, televisão de tubo.
- Escada dobrável, balde, vassoura, lata de tinta.
- **A chave (`Key304`) e a transcrição (`Transcript`) ficam em cima da mesa, visíveis.**

**Apartamento 304 — sala do telefone (fim do Capítulo 1)**
- Mesinha de telefone com o aparelho de disco (`Phone`), lista telefônica e bloco de notas.
- Poltrona com manta, sofá, mesa de centro com xícara e jornal.
- Armário ou estante com televisão, toca-discos, enfeites e porta-retratos.
- Tapete, cortinas pesadas, luminária de pé, relógio de parede parado às 03h17.
- Brinquedos de criança no chão (este era o apartamento de um menino).

**Apartamento 304 por dentro (Capítulo 2)** — é um apartamento que se estende muito além do possível, dividido em três áreas por paredes. Mobílie cada área como um cômodo diferente:
- **Sala de estar:** sofá de três lugares, duas poltronas, mesa de centro, estante com televisão e enfeites, aparador, tapete grande, quadros, cortinas, plantas mortas.
- **Sala de jantar e cozinha:** mesa com seis cadeiras (uma tombada), pratos e talheres postos, cristaleira com louça, geladeira antiga com a porta entreaberta, fogão com panela, pia com louça, armários de parede, botijão de gás, lixeira.
- **Quarto e corredor do fundo:** cama de casal desfeita, dois criados-mudos, guarda-roupa grande, penteadeira com espelho, berço ou cama de criança, baú de brinquedos, varal com roupa.
- Em todas as áreas: molduras reais para as fotografias, relógios parados, papel de parede descolando, rachaduras, objetos repetidos de um jeito estranho (o mesmo porta-retratos aparecendo em três lugares), para reforçar que o lugar não é normal.
- **Os três telefones do puzzle (`SequencePhone0`, `1` e `2`), o gravador (`FutureArgumentTape`) e o rascunho da pista precisam continuar em destaque, cada um com um abajur aceso por perto.**

### Regras para a bagunça não quebrar o jogo

- **O caminho do jogador fica livre.** Deixe pelo menos 0,9 m de passagem entre os móveis e na frente de todas as portas. Bagunça de chão no caminho (papéis, roupa, cacos) **não tem colisão**.
- **O centro do corredor do Capítulo 1 fica totalmente livre**, do começo ao fim, em toda a largura de 1,2 m para cada lado do eixo. O monstro anda por ali em linha reta e não desvia de nada. Encoste a mobília do corredor nas paredes, com no máximo 0,45 m de profundidade.
- Só móveis grandes têm colisão, e sempre em caixa simples. Objetos pequenos em cima de superfícies não têm colisão.
- Nada pode ficar na frente dos itens de interação nem entre o jogador e eles.
- As portas precisam abrir sem bater em móveis: deixe livre o arco de 1 m de cada porta.

### Regras para a densidade não pesar

- **Reaproveite modelos.** O mesmo livro, a mesma caixa e a mesma cadeira podem aparecer dezenas de vezes com rotação e escala diferentes. Carregue cada `.glb` uma vez e instancie.
- Para objetos muito repetidos (livros, papéis, cacos, garrafas), use `MultiMeshInstance3D`.
- Junte objetos pequenos em um atlas de textura compartilhado, para reduzir a quantidade de materiais.
- Orçamento por cena: até **350.000 triângulos** visíveis e **250 materiais diferentes**. Meça e informe os números reais.
- Sombras: só os móveis grandes projetam sombra. Desligue `cast_shadow` na bagunça pequena.
- Meça o FPS antes e depois (o contador fica no canto superior esquerdo). Se cair abaixo de 60 no PC de desenvolvimento, reduza.

## Ordem de trabalho

1. Função `LevelKit.model(...)` e o primeiro cômodo completo, o **302**, como referência de qualidade. Publique e peça a opinião do dono do projeto antes de seguir.
2. Apartamento 303.
3. Objetos de interação: fusível, chave, quadro de força, teclado da fechadura, telefone do 304, papéis.
4. Corredor.
5. Sala do telefone do 304.
6. Capítulo 2, uma área de cada vez.
7. Passada final de abandono: poeira, teias, infiltração, reboco, papel de parede.

Faça o commit e publique ao fim de cada item, para o dono do projeto ir vendo.

## Opcional, se sobrar tempo: o Ouvinte em 3D

Hoje o monstro é uma imagem plana (`assets/characters/listener_v2.png`) animada por shader. O ideal é um modelo 3D com esqueleto e animações de **parado, andando devagar e perseguindo**, com até 15.000 triângulos e a mesma aparência da imagem: humanoide magro, alto, braços compridos, cabeça pendida, roupa rasgada. **Não troque o monstro no jogo.** Apenas entregue o `.glb` em `assets/models/characters/listener.glb` com a licença registrada, e avise. O outro agente faz a integração.

## Ao terminar

Escreva um resumo com: o que foi trocado, a lista de modelos e licenças, o tamanho final do build Web, o resultado dos testes, o último commit enviado e qualquer coisa que tenha ficado pela metade.
