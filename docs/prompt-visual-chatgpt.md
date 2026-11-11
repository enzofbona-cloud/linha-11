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

## Ordem sugerida

1. Capítulo 1, apartamento 302: cama, criado-mudo, guarda-roupa, abajur.
2. Capítulo 1, apartamento 303: mesa, cadeira, estante de metal, caixas de papelão.
3. Objetos de interação: fusível, chave, quadro de força, teclado da fechadura, telefone do 304, papéis.
4. Corredor: banco, luminárias de teto, extintor, placas com os números das portas.
5. Capítulo 2: sofá, mesas, aparador, guarda-roupa, cristaleira, molduras das fotos, relógio de parede, os três telefones e o gravador.
6. Detalhes de abandono: sujeira, papéis no chão, uma cadeira tombada, cortinas.

Faça o commit e publique ao fim de cada item, para o dono do projeto ir vendo.

## Opcional, se sobrar tempo: o Ouvinte em 3D

Hoje o monstro é uma imagem plana (`assets/characters/listener_v2.png`) animada por shader. O ideal é um modelo 3D com esqueleto e animações de **parado, andando devagar e perseguindo**, com até 15.000 triângulos e a mesma aparência da imagem: humanoide magro, alto, braços compridos, cabeça pendida, roupa rasgada. **Não troque o monstro no jogo.** Apenas entregue o `.glb` em `assets/models/characters/listener.glb` com a licença registrada, e avise. O outro agente faz a integração.

## Ao terminar

Escreva um resumo com: o que foi trocado, a lista de modelos e licenças, o tamanho final do build Web, o resultado dos testes, o último commit enviado e qualquer coisa que tenha ficado pela metade.
