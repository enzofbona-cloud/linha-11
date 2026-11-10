# LINHA 11 — A Última Chamada

Jogo cooperativo de terror em primeira pessoa para dois jogadores, em desenvolvimento.
Versão comercial planejada para PC/Steam; versão Web usada para testes rápidos.

**Estado atual: Fase 3 (protótipo), em andamento.** Está jogável a primeira parte do Capítulo 1:
menu, movimentação em primeira pessoa, lanterna, portas, inventário, documentos, puzzle do
fusível, fechadura com senha, o Ouvinte (inimigo que reage a som), furtividade e áudio gerado
por código. Ainda não há multiplayer, combate, crafting, saúde, salvamento nem configurações
gráficas. A história completa está em `docs/historia.md`.

## Endereço de testes

- Página de testes: https://enzofbona-cloud.github.io/linha-11-web/
- Experimental (branch `development`): https://enzofbona-cloud.github.io/linha-11-web/dev/
- Estável (branch `main`): ainda não publicado.

## Tecnologia

| Item | Escolha |
|---|---|
| Motor | Godot 4.7.2 (versão fixada em `.godot-version`) |
| Linguagem | GDScript |
| Renderizador | Forward+ no PC, Compatibility (WebGL2) no navegador |
| Testes do jogo | GUT 9.7.1 (`addons/gut`) |
| Testes das ferramentas | Node (`node --test`) |
| CI e publicação | GitHub Actions + GitHub Pages |

## Como abrir o projeto

1. Instale o Godot 4.7.2: `winget install --id GodotEngine.GodotEngine --version 4.7.2 --exact`
2. Abra o Godot, clique em **Importar** e escolha o arquivo `project.godot` desta pasta.
3. Aperte F5 para rodar.

## Como rodar os testes

```bash
GODOT="/caminho/para/Godot_v4.7.2-stable_win64_console.exe" tools/test.sh
```

## Como testar a versão Web no próprio computador

Requer os templates de export do Godot 4.7.2 instalados (no editor: Editor →
Gerenciar modelos de exportação).

```bash
GODOT="/caminho/para/godot" tools/build-site.sh dev
node tools/serve.mjs build/site 4173
```

Depois abra `http://localhost:4173`.

## Como a publicação funciona

Há dois repositórios:

- `linha-11` (privado): código, cenas, assets e documentação.
- `linha-11-web` (público): somente os arquivos compilados, servidos pelo GitHub Pages.

| Branch | Workflow | Publica em |
|---|---|---|
| `development` | `web-dev.yml` | `/dev/` (experimental) |
| `main` | `web-stable.yml` | `/stable/` (estável) |
| `ci-ensaio/**` | `web-dev.yml` | nada (só testa e compila) |

Cada workflow roda os testes, exporta a versão Web, verifica o build e só então
publica. Se qualquer passo falhar, a versão que já está no ar não é alterada.

A publicação usa uma chave de deploy guardada no segredo `WEB_DEPLOY_KEY` do
repositório privado. Nenhuma credencial fica no código.

## Tamanho do build Web (medido em 2026-11-10)

| Arquivo | Tamanho |
|---|---|
| `index.wasm` (motor) | 37,7 MB |
| `index.pck` (conteúdo do jogo, com texturas 1K) | 26,0 MB |
| Total | 64,0 MB |

Limites do GitHub Pages: 100 MB por arquivo e 1 GB por site. O script
`tools/verify-web-build.mjs` barra builds que passem disso.

## Estrutura

```
assets/textures/     texturas PBR (CC0, ver LICENCAS.md)
game/core/           autoloads (BuildInfo, GameInput)
game/player/         jogador em primeira pessoa
game/interact/       portas, itens, telefone
game/world/          peças para montar cenários
game/scenes/         cenas (boot, protótipo)
game/ui/             menus e HUD
tests/               testes GUT
tools/               scripts de build, verificação e teste
web/landing/         página de testes
.github/             workflows e action de build
docs/superpowers/    especificações e planos de cada fase
```

## Metas de desempenho (ainda não medidas)

| | Mínimo | Recomendado |
|---|---|---|
| Alvo | 30 FPS, Muito Baixa, 720p | 60 FPS, Média, 1080p |
| Vídeo | Integrado (Intel HD 620) | GTX 1050 Ti |
| Memória | 8 GB | 16 GB |

Tamanho instalado: meta de 5 a 10 GB, teto de 20 GB.

## Dependências externas e custos

- GitHub (conta gratuita): repositórios, Actions (2.000 min/mês em repositório privado) e Pages.
- Git LFS: cota gratuita limitada; a reavaliar quando entrarem assets pesados.
- Godot e GUT: gratuitos, licença MIT.
