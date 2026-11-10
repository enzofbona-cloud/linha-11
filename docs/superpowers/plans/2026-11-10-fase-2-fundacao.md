# Fase 2 — Fundação do Projeto: Plano de Implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Um push em `development` testa, compila a versão Web do projeto Godot e publica sozinho em um endereço fixo do GitHub Pages, sem nunca substituir um build bom por um quebrado.

**Architecture:** Projeto Godot único em repositório privado `linha-11`. O GitHub Actions exporta o preset Web e envia só os arquivos compilados para o repositório público `linha-11-web` (branch `gh-pages`), em `/dev/` ou `/stable/`. Uma landing estática na raiz lê um `version.json` por canal.

**Tech Stack:** Godot 4.7.2 (GDScript), GUT (testes Godot), Node 20+ (scripts de build e seus testes com `node --test`), GitHub Actions, GitHub Pages, `peaceiris/actions-gh-pages@v4`.

**Spec:** `docs/superpowers/specs/2026-11-10-fase-2-fundacao-design.md`

## Global Constraints

- Versão do Godot: `4.7.2-stable`, declarada só em `.godot-version` e lida pelo CI.
- Versão do jogo: `0.1.0` em `project.godot` (`application/config/version`).
- Renderizador: `forward_plus` no desktop, `gl_compatibility` na Web.
- Export Web sem threads (`variant/thread_support=false`).
- Limites do build Web: nenhum arquivo acima de 100 MB (104857600 bytes); total abaixo de 1 GB (1073741824 bytes).
- Publicação é sempre o último passo do workflow e só roda na branch do canal.
- Nenhuma credencial em arquivo versionado nem em mensagem de conversa.
- Commits no padrão `feat:`, `fix:`, `perf:`, `docs:`, `ci:`, `test:`.
- Textos visíveis ao jogador em português do Brasil.
- `main` só recebe código que passou em `development`.

Desvios conscientes em relação à spec (atualizar a spec na Task 1):

- `version.json` fica dentro de cada canal (`/dev/version.json`, `/stable/version.json`) em vez de um arquivo único na raiz, para que um canal nunca reescreva dados do outro.
- `web/shell.html` não será criado; o shell HTML padrão do Godot basta nesta fase.

## Review Focus

1. `build_info.json` ausente ou com JSON inválido → o jogo abre mostrando `dev-local`, sem travar (teste na Task 1).
2. Canal estável ainda não publicado (`/stable/version.json` devolve 404) → a landing mostra "ainda não publicado" e desabilita o botão, sem erro visível (teste na Task 4).
3. Pasta de build inexistente ou vazia passada ao verificador → falha com mensagem clara, não exceção crua (teste na Task 3).
4. Dois workflows publicando ao mesmo tempo → fila única via `concurrency`, sem perda de pasta (verificação na Task 5).
5. Navegador sem WebGL2 → o shell padrão do Godot mostra aviso; confirmar manualmente que a landing lista o requisito (Task 4).

---

### Task 0: Pré-requisitos da máquina

**Files:** nenhum arquivo do projeto.

- [ ] **Step 1:** Confirmar login. Run: `gh auth status`. Expected: `Logged in to github.com account <login>`. Se falhar, parar e pedir ao dono do projeto que conclua `gh auth login`.
- [ ] **Step 2:** Instalar Godot. Run: `winget install --id GodotEngine.GodotEngine --version 4.7.2 --exact`. Localizar o executável de console e registrar o caminho em uma variável de ambiente de usuário `GODOT`. Expected: `& $env:GODOT --version` imprime `4.7.2.stable...`.
- [ ] **Step 3:** Identidade Git local do repositório (não global): `user.name` = login do GitHub; `user.email` = `<id>+<login>@users.noreply.github.com`, obtidos de `gh api user`.
- [ ] **Step 4:** Commit dos documentos já existentes em `main`: `docs: adiciona especificação e plano da fase 2`. Criar a branch `development` a partir dela e trabalhar nela daqui em diante.

### Task 1: Esqueleto do projeto, BuildInfo e testes

**Files:**
- Create: `.godot-version`, `.gitignore`, `.gitattributes`, `project.godot`, `game/core/build_info.gd`, `tests/test_build_info.gd`, `addons/gut/` (GUT compatível com 4.7.2)
- Modify: spec (desvios listados acima)

**Interfaces:**
- Produces: autoload `BuildInfo` com propriedades `version: String`, `commit: String`, `date: String`, `channel: String`; e `static func read_file(path: String) -> Dictionary` que devolve sempre as quatro chaves.
- Arquivo de dados: `res://build_info.json` com `{"version","commit","date","channel"}`; ignorado pelo Git.
- Comando de teste (usado por todas as tasks e pelo CI): `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`

- [ ] **Step 1:** Criar `.godot-version` (`4.7.2-stable`), `.gitignore` (`.godot/`, `build/`, `build_info.json`, `*.tmp`, `*.pem`, `*.key`, `.env*`) e `.gitattributes` com LFS para `*.png *.jpg *.exr *.hdr *.glb *.gltf *.bin *.fbx *.wav *.ogg *.mp3`. Rodar `git lfs install --local`.
- [ ] **Step 2:** Criar `project.godot`: nome `LINHA 11 — A Última Chamada`, versão `0.1.0`, renderizadores das Global Constraints, autoload `BuildInfo`. Instalar o GUT em `addons/gut/`. Se nenhuma versão do GUT funcionar no 4.7.2, parar e reportar (a spec prevê trocar por scripts headless simples).
- [ ] **Step 3: Testes que falham** em `tests/test_build_info.gd`:

```gdscript
func test_arquivo_ausente_devolve_dev_local():
    var d = BuildInfo.read_file("res://nao_existe.json")
    assert_eq(d.version, "dev-local")
    assert_eq(d.commit, "dev-local")
    assert_eq(d.channel, "local")

func test_json_invalido_devolve_dev_local():
    # grava "{isto nao e json" em user://ruim.json
    assert_eq(BuildInfo.read_file("user://ruim.json").version, "dev-local")

func test_arquivo_valido_devolve_valores():
    # grava {"version":"0.1.0","commit":"abc1234","date":"2026-11-10T12:00:00Z","channel":"dev"} em user://ok.json
    var d = BuildInfo.read_file("user://ok.json")
    assert_eq(d.version, "0.1.0")
    assert_eq(d.commit, "abc1234")
    assert_eq(d.date, "2026-11-10T12:00:00Z")
    assert_eq(d.channel, "dev")

func test_chave_faltando_usa_padrao():
    # grava {"version":"0.1.0"} em user://parcial.json
    assert_eq(BuildInfo.read_file("user://parcial.json").commit, "dev-local")
```

- [ ] **Step 4:** Rodar o comando de teste. Expected: falha porque `BuildInfo` não existe.
- [ ] **Step 5:** Implementar `game/core/build_info.gd`; `_ready()` preenche as propriedades com `read_file("res://build_info.json")`.
- [ ] **Step 6:** Rodar o comando de teste. Expected: 4 passando, 0 falhando.
- [ ] **Step 7:** Commit: `feat: cria projeto Godot com BuildInfo e testes`.

### Task 2: Cena de boot e HUD de depuração

**Files:**
- Create: `game/scenes/boot/boot.tscn`, `game/scenes/boot/boot.gd`, `game/ui/debug_hud.tscn`, `game/ui/debug_hud.gd`, `tests/test_boot_scene.gd`
- Modify: `project.godot` (cena principal = `boot.tscn`)

**Interfaces:**
- Consumes: `BuildInfo.version/commit/date/channel`.
- Produces: `debug_hud.gd` com `func build_text() -> String` devolvendo `"LINHA 11 v<version> · <commit> · <date>"`; nós `%BuildLabel` e `%FpsLabel`.

- [ ] **Step 1: Testes que falham:**

```gdscript
func test_boot_carrega_e_instancia():
    var cena = load("res://game/scenes/boot/boot.tscn")
    assert_not_null(cena)
    var inst = cena.instantiate()
    add_child_autofree(inst)
    assert_not_null(inst.get_node_or_null("Camera3D"))
    assert_not_null(inst.find_child("BuildLabel", true, false))
    assert_not_null(inst.find_child("FpsLabel", true, false))

func test_texto_do_build_contem_versao_e_commit():
    var hud = load("res://game/ui/debug_hud.tscn").instantiate()
    add_child_autofree(hud)
    assert_string_contains(hud.build_text(), BuildInfo.version)
    assert_string_contains(hud.build_text(), BuildInfo.commit)
```

- [ ] **Step 2:** Rodar testes. Expected: falham por arquivo inexistente.
- [ ] **Step 3:** Construir `boot.tscn`: sala fechada simples (piso, paredes, teto) com materiais PBR básicos de concreto escuro, uma `OmniLight3D` quente fraca, `WorldEnvironment` escuro, `Camera3D` fixa, e o HUD instanciado. O HUD atualiza o FPS a cada 0,5 s com `Engine.get_frames_per_second()`. Nada que exija Forward+ (precisa renderizar em Compatibility).
- [ ] **Step 4:** Rodar testes. Expected: 6 passando.
- [ ] **Step 5:** Abrir o jogo no desktop (`godot --path .`) e confirmar visualmente sala, texto `dev-local` e FPS.
- [ ] **Step 6:** Commit: `feat: adiciona cena de boot e HUD de depuração`.

### Task 3: Export Web e verificador de build

**Files:**
- Create: `export_presets.cfg`, `tools/verify-web-build.mjs`, `tools/verify-web-build.test.mjs`, `tools/write-build-info.mjs`, `tools/write-build-info.test.mjs`

**Interfaces:**
- Produces:
  - Preset `Web`, saída `build/web/index.html`, sem threads. Comando: `godot --headless --export-release "Web" build/web/index.html`.
  - `verifyBuild(dir: string): {ok: boolean, errors: string[]}`; CLI `node tools/verify-web-build.mjs <dir>` sai com 0 ou 1 e imprime cada erro.
  - `buildInfo({version, commit, date, channel}): object`; CLI `node tools/write-build-info.mjs --channel <dev|stable> --commit <sha> --out <arquivo>...` lê a versão de `project.godot`, usa os 7 primeiros caracteres do commit e a data UTC em ISO 8601, e grava o mesmo JSON em cada `--out`.

- [ ] **Step 1: Testes que falham** (`node --test tools/`), usando pastas temporárias:
  - build com `index.html`, `index.wasm`, `index.pck` → `ok === true`.
  - sem `.wasm` → `ok === false`, erro contém `.wasm`. Idem `.pck` e `index.html`.
  - arquivo de 104857601 bytes (arquivo esparso) → erro contém o nome do arquivo.
  - total acima de 1073741824 bytes (limites injetáveis por parâmetro opcional para o teste não criar 1 GB) → erro contém `total`.
  - pasta inexistente → `ok === false`, erro contém `não encontrada`, sem lançar exceção.
  - pasta vazia → `ok === false`.
  - `buildInfo` com commit `abcdef1234567` → `commit === "abcdef1"`; canal fora de `dev|stable` → lança erro.
- [ ] **Step 2:** Rodar. Expected: falham por módulo inexistente.
- [ ] **Step 3:** Implementar os dois scripts (somente módulos nativos do Node).
- [ ] **Step 4:** Rodar `node --test tools/`. Expected: todos passando.
- [ ] **Step 5:** Criar `export_presets.cfg` com o preset `Web` e instalar os templates de export 4.7.2 localmente.
- [ ] **Step 6:** Exportar localmente e rodar `node tools/verify-web-build.mjs build/web`. Expected: saída 0. Anotar os tamanhos de `.wasm` e `.pck` no README (Task 6).
- [ ] **Step 7:** Servir `build/web` em um servidor local (entrada em `.claude/launch.json`, `npx serve build/web`) e abrir no navegador: a sala renderiza, o HUD aparece, console sem erros. Guardar captura de tela.
- [ ] **Step 8:** Commit: `feat: configura export Web e verificador de build`.

### Task 4: Página de testes (landing)

**Files:**
- Create: `web/landing/index.html`, `web/landing/style.css`, `web/landing/app.js`, `web/landing/app.test.mjs`

**Interfaces:**
- Consumes: `dev/version.json` e `stable/version.json` (formato de `buildInfo`), caminhos relativos.
- Produces: `channelView(data: object|null): {status: string, version: string, commit: string, date: string, playable: boolean}` exportada de `app.js` (função pura, testável sem navegador).

- [ ] **Step 1: Testes que falham:**
  - `channelView(null)` → `playable === false`, `status === "ainda não publicado"`.
  - `channelView({version:"0.1.0",commit:"abc1234",date:"2026-11-10T12:00:00Z",channel:"dev"})` → `playable === true`, `version === "0.1.0"`, data formatada em pt-BR.
  - objeto sem `version` → tratado como `null`.
- [ ] **Step 2:** Rodar. Expected: falham.
- [ ] **Step 3:** Implementar a landing: tema escuro coerente com terror urbano; título, aviso "Versão experimental — pode conter falhas"; um cartão por canal (Experimental → `dev/`, Estável → `stable/`) com versão, commit, última atualização e botão "Jogar"; seção "Controles" (texto "Nesta versão ainda não há controles"); seção "Disponível agora" (cena de teste, contador de FPS) e "Somente na versão PC" (Steam, convites, voz); requisito "navegador com WebGL2". `fetch` com `cache: "no-store"`; qualquer falha de rede vira `channelView(null)`. Usar a skill `frontend-design:frontend-design` para o visual.
- [ ] **Step 4:** Rodar `node --test web/landing/`. Expected: passando.
- [ ] **Step 5:** Montar localmente uma pasta com a landing + `build/web` em `dev/` + um `dev/version.json` gerado; abrir no navegador em largura de celular e desktop; confirmar cartão Experimental jogável e Estável "ainda não publicado". Captura de tela.
- [ ] **Step 6:** Commit: `feat: adiciona página de testes`.

### Task 5: Repositórios, workflows e primeira publicação

**Files:**
- Create: `.github/workflows/web-dev.yml`, `.github/workflows/web-stable.yml`, `.github/actions/build-web/action.yml` (passos comuns)

**Interfaces:**
- Consumes: comando de teste (Task 1), comando de export, `verify-web-build.mjs`, `write-build-info.mjs` (Task 3), `web/landing/` (Task 4).
- Produces: segredo `WEB_DEPLOY_KEY` no repositório `linha-11`; site em `https://<login>.github.io/linha-11-web/`.

- [ ] **Step 1 (ação externa — confirmar com o dono do projeto antes):** criar `linha-11` privado e `linha-11-web` público com `gh repo create`; verificar antes que nenhum dos nomes já existe na conta.
- [ ] **Step 2:** Gerar par de chaves ed25519 na pasta temporária da sessão; `gh repo deploy-key add <pub> --allow-write -R <login>/linha-11-web`; `gh secret set WEB_DEPLOY_KEY -R <login>/linha-11 < <privada>`; apagar os dois arquivos locais. Expected: `gh secret list` mostra `WEB_DEPLOY_KEY`; a chave nunca é impressa.
- [ ] **Step 3:** Escrever a action composta `build-web` (entrada `channel`): checkout com LFS; ler `.godot-version`; baixar com cache `Godot_v<versão>_linux.x86_64.zip` e `Godot_v<versão>_export_templates.tpz` de `github.com/godotengine/godot/releases`; `--import`; testes GUT; `node --test tools/ web/landing/`; `write-build-info` gravando `build_info.json` e `build/web/version.json`; export; `verify-web-build`.
- [ ] **Step 4:** Escrever `web-dev.yml`: gatilho em push para `development` e `ci-ensaio/**`; `concurrency: {group: web-deploy, cancel-in-progress: false}`; roda `build-web` com `channel: dev`; depois, **somente com `if: github.ref == 'refs/heads/development'`**, dois passos `peaceiris/actions-gh-pages@v4` com `deploy_key`, `external_repository`, `publish_branch: gh-pages`: (a) `build/web` → `destination_dir: dev`; (b) `web/landing` → raiz com `keep_files: true`. `web-stable.yml` é igual com gatilho `main`, `channel: stable`, `destination_dir: stable`.
- [ ] **Step 5:** Push de `development`. Acompanhar com `gh run watch`. Expected: workflow verde. Se falhar, ler o log, corrigir a causa e repetir; não prosseguir com workflow vermelho.
- [ ] **Step 6:** Ativar o Pages em `linha-11-web` (branch `gh-pages`, pasta `/`) via `gh api`. Expected: `gh api repos/<login>/linha-11-web/pages` devolve `status: built` e a URL.
- [ ] **Step 7:** Abrir a URL real no navegador: landing carrega; canal Experimental mostra o commit enviado (comparar com `git rev-parse --short HEAD`); "Jogar" abre a sala 3D; console sem erros. Captura de tela.
- [ ] **Step 8:** Commit (já enviado no Step 5 como `ci: adiciona workflows de build e publicação Web`).

### Task 6: Provas do ciclo, README e canal estável

**Files:**
- Create: `README.md`
- Modify: `game/scenes/boot/boot.tscn` (mudança visível para o teste do ciclo)

- [ ] **Step 1: Teste do ciclo.** Mudar algo visível (cor da luz da sala), commit `feat: ajusta iluminação da sala de teste`, push. Expected: workflow verde; a URL mostra o novo commit e a nova cor sem nenhuma ação manual.
- [ ] **Step 2: Teste de proteção.** Criar `ci-ensaio/build-quebrado` com um teste que falha de propósito e fazer push. Expected: workflow vermelho; `dev/version.json` no site continua com o commit do Step 1. Apagar a branch de ensaio local e remota em seguida.
- [ ] **Step 3:** Escrever `README.md`: o que é o projeto; como abrir no Godot 4.7.2; como rodar os testes; como funciona a publicação (dois repositórios, dois canais); endereço real de testes; tamanhos medidos do build; o que existe e o que ainda não existe; dependências e custos.
- [ ] **Step 4:** Commit `docs: adiciona README` e push em `development`. Expected: workflow verde.
- [ ] **Step 5:** Fazer merge fast-forward de `development` em `main` e push. Expected: `web-stable` verde; `/stable/` abre e a landing mostra os dois canais publicados.
- [ ] **Step 6:** Relatório final ao dono do projeto no formato da seção 24 do prompt mestre: o que foi feito, arquivos, testes e resultados, commits, estado do Actions, link real, o que falta.
