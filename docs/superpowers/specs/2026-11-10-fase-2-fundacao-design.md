# LINHA 11 — Fase 2: Fundação do Projeto (especificação)

Data: 2026-11-10
Estado: aguardando revisão do dono do projeto

## 1. Objetivo

Ao fim da Fase 2 deve existir um ciclo completo e comprovado:

1. Eu altero o projeto e envio para a branch `development`.
2. O GitHub Actions testa e compila a versão Web sozinho.
3. Se tudo passar, a página de testes é atualizada.
4. O dono do projeto abre sempre o mesmo endereço no navegador e vê a versão nova.

A Fase 2 **não** entrega jogabilidade. Entrega a esteira que todas as fases
seguintes usarão.

## 2. Intenção e restrições do projeto (resumo aprovado na Fase 1)

Dito pelo dono do projeto:

- Jogo comercial pago de terror cooperativo em primeira pessoa, dois jogadores online, campanha de 2 a 3 horas, lançamento na Steam.
- Visual 3D semirrealista, sem aparência de massinha ou desenho animado.
- Deve ser leve e rodar no maior número possível de PCs.
- Tamanho instalado de no máximo cerca de 20 GB.
- Código versionado no GitHub; versão jogável no navegador atualizada automaticamente.
- Uma compilação quebrada nunca substitui a última versão Web funcional.

Decidido na Fase 1 e aprovado:

- Motor: Godot 4 com GDScript.
- Um único projeto; PC usa o renderizador Forward+, Web usa Compatibility (WebGL2).
- Multiplayer com host autoritativo; transporte Steam no PC e WebRTC no navegador.

Suposições minhas, ainda **não confirmadas** pelo dono do projeto:

- Pasta local em `C:\Dev\linha-11` (fora do OneDrive).
- Instalação do Godot feita por mim via winget.
- Modelo de hospedagem da seção 4.

## 3. Requisitos mínimos adotados como meta

| | Mínimo (30 FPS, Muito Baixa, 720p) | Recomendado (60 FPS, Média, 1080p) |
|---|---|---|
| Processador | Dual-core de cerca de 2015 | Quad-core |
| Memória | 8 GB | 16 GB |
| Vídeo | Integrado (Intel HD 620 ou equivalente) | GTX 1050 Ti ou equivalente |
| Sistema | Windows 10 64 bits | Windows 10/11 |

Tamanho instalado: meta de 5 a 10 GB, teto absoluto de 20 GB.

Essas metas só serão consideradas atingidas depois de medidas em teste.
A Fase 2 apenas instala o contador de FPS que permitirá medi-las.

## 4. Hospedagem

Dois repositórios no GitHub:

| Repositório | Visibilidade | Conteúdo |
|---|---|---|
| `linha-11` | **Privado** | Código-fonte, cenas, assets, documentação, workflows |
| `linha-11-web` | **Público** | Somente os arquivos já compilados da versão Web, servidos pelo GitHub Pages |

Motivos:

- GitHub Pages gratuito exige repositório público. Separando, o código e os
  assets originais do jogo pago ficam privados e só o build compilado é público
  (o que aconteceria em qualquer hospedagem Web).
- Não exige conta nem custo em outro serviço.
- Cloudflare Pages, sugerido antes, foi descartado: tem limite de 25 MiB por
  arquivo, e o executável Web do Godot costuma ultrapassar isso. O GitHub Pages
  aceita até 100 MB por arquivo e 1 GB por site.

O endereço real terá a forma `https://<usuario>.github.io/linha-11-web/` e só
será informado depois de criado e aberto com sucesso.

Estrutura do site publicado:

```
/            página de testes (landing)
/dev/        build experimental, vindo da branch development
/stable/     build estável, vindo da branch main
```

Cada canal traz o próprio `version.json` (`/dev/version.json`,
`/stable/version.json`) com versão, commit e data, para que um canal nunca
reescreva os dados do outro.

Credencial: uma chave de deploy SSH exclusiva do repositório `linha-11-web`,
com permissão de escrita só nele. A parte privada fica em GitHub Secrets do
repositório `linha-11`; nunca entra no código nem na conversa.

## 5. Estrutura do repositório `linha-11`

```
project.godot
export_presets.cfg          presets "Web" e "Windows Desktop"
.gitignore                  .godot/, build/, *.tmp, credenciais
.gitattributes              Git LFS para imagens, modelos e áudio
README.md
docs/                       documentação e especificações
game/
  core/                     autoloads: versão, configurações
  scenes/boot/              cena inicial de verificação
  ui/                       HUD de depuração (FPS, versão)
tests/                      testes automatizados (GUT)
addons/gut/                 framework de testes
web/
  landing/                  página de testes (HTML/CSS/JS estáticos)
.github/workflows/
  web-dev.yml               development -> /dev/
  web-stable.yml            main -> /stable/
tools/                      scripts de build e verificação
```

Branches: `main` (estável), `development` (contínua), `feature/*` quando útil.
Commits no padrão `feat:`, `fix:`, `perf:`, `docs:`, `ci:`, `test:`.

## 6. Projeto Godot

- Versão fixada: **Godot 4.7.2 estável** (a que o winget oferece hoje). A mesma
  versão é usada no PC e no CI, declarada em um único arquivo lido por ambos.
- Renderizador: Forward+ no desktop, Compatibility na Web (override por
  plataforma em `project.godot`).
- Export Web **sem threads**, porque o GitHub Pages não envia os cabeçalhos que
  o modo com threads exige.
- Conteúdo jogável da Fase 2, de propósito mínimo:
  - Cena de boot com uma sala 3D simples iluminada e uma câmera fixa.
  - Texto com o nome do jogo, versão, commit e data do build.
  - Contador de FPS.
- Autoload `BuildInfo`: lê versão, commit e data de um arquivo gerado no build.
  Fora do CI mostra `dev-local`.

Não entram na Fase 2: movimentação, multiplayer, inventário, áudio, menus
reais, Steam. Tudo isso é Fase 3 em diante.

## 7. Workflows do GitHub Actions

`web-dev.yml`, disparado por push em `development`:

1. Baixa o código (com LFS).
2. Baixa o Godot 4.7.2 headless e os templates de export, com cache.
3. Importa o projeto e roda os testes. Falha interrompe tudo.
4. Gera o arquivo de informações do build (versão, commit, data).
5. Exporta o preset Web para `build/web/`.
6. Verifica o build: existem `index.html`, `.wasm` e `.pck`; nenhum arquivo
   passa de 100 MB; o total fica abaixo de 1 GB.
7. **Somente se os passos anteriores passaram:** publica `build/web/` em `/dev/`
   do repositório `linha-11-web` (incluindo o `version.json` do canal) e atualiza a landing.

`web-stable.yml`: igual, disparado por push em `main`, publicando em `/stable/`.

Como a publicação é o último passo e cada canal só substitui a própria pasta,
um build quebrado mantém no ar a última versão funcional, e o canal
experimental nunca sobrescreve o estável.

Quando um build falha, o `version.json` no ar não muda. A landing mostra o
estado do último workflow por meio do selo (badge) do GitHub Actions; como o
repositório de código é privado, se o selo não puder ser exibido publicamente,
a landing mostrará apenas "último build publicado" com data e commit, e essa
limitação será informada.

## 8. Página de testes (landing)

Página estática, visual escuro coerente com o jogo, contendo:

- Nome do projeto e aviso de versão experimental.
- Para cada canal (experimental e estável): versão, commit, data da última
  atualização e botão para iniciar.
- Estado da compilação.
- Controles (na Fase 2: nenhum; a lista cresce com o jogo).
- Lista de funcionalidades disponíveis e de funcionalidades só de PC.

Os dados vêm do `version.json`, então a página não precisa ser reescrita a cada
build.

## 9. Testes e verificação

Automatizados (rodam no CI e localmente):

- `BuildInfo` devolve `dev-local` sem arquivo de build e os valores certos com ele.
- A cena de boot carrega sem erros em modo headless.
- O script de verificação do build rejeita build sem `.wasm`, com arquivo acima
  de 100 MB ou com total acima de 1 GB.

Manuais, feitos por mim no navegador real, com evidência:

- Abrir o endereço real, iniciar o canal experimental, ver a sala 3D
  renderizada, sem erros no console.
- Conferir que versão e commit exibidos batem com o commit enviado.
- **Teste do ciclo:** fazer uma alteração visível, enviar, esperar o Actions e
  confirmar a mudança no mesmo endereço.
- **Teste de proteção:** enviar de propósito um commit com teste falhando para
  uma branch de ensaio ligada ao mesmo workflow e confirmar que o site não mudou.

## 10. Critérios de conclusão da Fase 2

- Repositórios `linha-11` (privado) e `linha-11-web` (público) existem, com
  `main` e `development`.
- Push em `development` publica sozinho em `/dev/`; push em `main`, em `/stable/`.
- O endereço real abre, a cena 3D aparece no navegador e mostra o commit correto.
- Um build com falha comprovadamente não altera o site.
- Nenhuma credencial no repositório.
- README explica como abrir o projeto, rodar os testes e como a publicação funciona.

## 11. Dependências externas e custos

| Dependência | Uso | Custo |
|---|---|---|
| GitHub (conta gratuita) | Repositórios, Actions, Pages | Gratuito dentro das cotas |
| GitHub Actions em repositório privado | Compilação | 2.000 minutos/mês gratuitos; cada build deve levar poucos minutos |
| Git LFS | Assets grandes | Cota gratuita limitada; pode gerar custo quando os assets crescerem (Fase 3 em diante). Será reavaliado antes de adicionar assets pesados |
| Godot 4.7.2 | Motor | Gratuito, licença MIT |
| GUT | Testes | Gratuito; compatibilidade com 4.7.2 será confirmada na instalação. Se não for compatível, os testes usam scripts headless simples do próprio Godot |

Servidor de sinalização do multiplayer Web, GodotSteam e taxa da Steam
(US$ 100 por jogo) pertencem a fases posteriores.

## 12. Ações que só o dono do projeto pode fazer

- Concluir `gh auth login` (pendente: o terminal está aguardando a tecla Enter
  e a digitação do código no navegador).
- Confirmar as três suposições da seção 2.
