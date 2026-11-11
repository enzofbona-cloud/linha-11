# LINHA 11 — A Última Chamada

Jogo cooperativo de terror em primeira pessoa para dois jogadores, em desenvolvimento.
Versão comercial planejada para PC/Steam; versão Web usada para testes rápidos.

**Estado atual: protótipos jogáveis dos Capítulos 1 e 2, em andamento.** O menu principal usa arte original, permite iniciar os dois capítulos, ajustar o volume e sair; “Continuar” fica desativado até existir salvamento. O Capítulo 1 inclui exploração, lanterna, documentos, fusível, senha em fragmentos, furtividade e o Ouvinte. O Capítulo 2, no Apartamento 304, usa arte original para o papel de parede e a fotografia, gravação legendada de uma discussão futura e puzzle de três telefones. Ainda não há cooperação online, combate, crafting, saúde, salvamento ou configurações gráficas completas. A história está em `docs/historia.md`.

## Ambientes implementados

- Capítulo 1: corredor, Apartamentos 301, 302, 303, 305, zeladoria e acesso ao 304, com móveis agrupados por cômodo, objetos pessoais e mapas PBR envelhecidos. A energia, a gaveta trancada, os três fragmentos da senha e a barricada formam a progressão; o Ouvinte só aparece ao sair do 303.
- Capítulo 2: salas de estar, jantar e quarto do Apartamento 304, com móveis de madeira e tecido, objetos de época, tapetes e iluminação quente de baixo custo.
- O Ouvinte usa o modelo 3D GLB enviado pelo usuário. O arquivo tem uma malha rígida, sem esqueleto; o movimento de corpo inteiro acompanha a passada, e a face recebe um pequeno borrão escuro. Não há animação articulada por ossos.
- Os outros quatro capítulos da campanha ainda não têm cenários jogáveis construídos.

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

## Tamanho do build Web (medido em 2026-11-11)

| Arquivo | Tamanho |
|---|---|
| `index.wasm` (motor) | 37,7 MB |
| `index.pck` (conteúdo do jogo, móveis, mapas PBR e fundo do menu) | 89,7 MB |
| Total | 127,7 MB |

Limites do GitHub Pages: 100 MB por arquivo e 1 GB por site. O script
`tools/verify-web-build.mjs` barra builds que passem disso.

## Estrutura

```
assets/textures/     texturas PBR (CC0, ver LICENCAS.md)
assets/models/       móveis Poly Haven CC0 e objetos originais do jogo
assets/models/characters/ Ouvinte 3D
assets/ui/           fundo original do menu
game/core/           autoloads (BuildInfo, GameInput)
game/player/         jogador em primeira pessoa
game/interact/       portas, itens, telefone
game/world/          peças para montar cenários
game/scenes/         cenas (boot, protótipo, capítulo 2)
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
