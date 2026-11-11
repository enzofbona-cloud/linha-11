# Capítulo 1 — reforma (ambientação do capítulo 2 + mais etapas)

Pedido do usuário em 2026-11-11. Decisões já tomadas com ele; não reabrir.

## O que ele pediu

1. O capítulo 2 (`game/scenes/chapter2/apartment_304.gd`, commit `b77a310`) é o padrão visual
   aprovado ("ficou muito melhor"). O capítulo 1 deve ser refeito nesse estilo, e todos os
   capítulos futuros também. Pode mudar o formato e a quantidade de cômodos.
2. O capítulo 1 termina em menos de 30 segundos. Tem de ficar mais longo e um pouco mais
   difícil: "relativamente fácil", nada impossível, mas com mais coisas para fazer.
   Alvo: 5 a 8 minutos na primeira vez.
3. Aprovou três ideias (abaixo). Recusou a quarta: **o Ouvinte só aparece no finalzinho**,
   como hoje (depois de pegar a chave do 304, ao sair do 303 para o corredor).
4. Não gosta de chiado/ruído branco. Passos baixos. No navegador, nunca usar Ctrl ou Alt.

## Estilo a copiar do capítulo 2

- Corredor central estreito (2 m) com plafons (`LevelKit.ceiling_light`), rodapé, batentes,
  passadeira (tapete comprido) e quadros nas paredes.
- Cômodos de tamanho real (4 a 5 m de lado), cada um com função clara e móveis agrupados:
  sofá de frente para a TV com mesa de centro no tapete; cama com criado-mudo de cada lado;
  mesa de jantar com cadeiras em volta; escrivaninha com cadeira; estantes encostadas.
- Papel de parede (`_wallpaper_material`), luz quente de abajur em cada cômodo habitado,
  um cômodo sem luz para contraste.
- Piso e teto em pedaços por cômodo (limite de 8 luzes por objeto no navegador).
- Ajudantes prontos no capítulo 2 para reaproveitar (vale movê-los para `LevelKit`):
  `_solid`, `_prop`, `_table`, `_chair`, `_nightstand`, `_cabinet`, `_wardrobe`, `_shelf`,
  `_bed`, `_window`, `_tv`, `_rug`, `_hall_wall`.
- Modelos têm a frente em +z; `Shelf_01` tem a origem nas costas. Tamanhos:
  `godot --headless --path . -s tools/model_sizes.gd`.
- Conferir sempre por captura: `tools/screenshot.gd` (cap. 1) e `tools/screenshot_chapter2.gd`,
  rodando sem `--headless`. Yaw 90 olha para -x; yaw -90 para +x.

## Novo andar (sugestão de planta; pode ajustar)

Corredor x de -1,2 a 1,2, do z = 0 (início) até a porta do 304 no fundo (por volta de z = -22).

| Lado | Cômodo | Papel na história |
|---|---|---|
| Esquerda, início | Zeladoria (pequena) | Trava elétrica: só abre com energia. Tem o pé de cabra. |
| Esquerda, meio | Apto 301 (dona Marta): sala + quarto | Chave pequena da gaveta, dentro de um móvel revistável. 1º pedaço da senha. |
| Esquerda, fundo | Apto 302: quarto + saleta | Diário. Fusível na gaveta trancada da penteadeira. 2º pedaço da senha. |
| Direita, início | Apto 305: sala + cozinha | Porta pregada com tábua: precisa do pé de cabra. 3º pedaço da senha. |
| Direita, meio | Apto 303 (síndico) | Fechadura de senha. Transcrição e chave do 304. Ponto de retorno. |
| Fundo | Apto 304 | Telefone. Fim do capítulo. |

## Sequência nova

1. Começa no escuro com a lanterna. Objetivo: restabelecer a energia. O quadro de força está
   sem fusível.
2. **302:** o diário diz que o fusível reserva está na gaveta da penteadeira e que a chave da
   gaveta ficou com a dona Marta, do 301. A gaveta responde "Trancada. Fechadura pequena."
3. **301:** revistar móveis (gavetas, guarda-roupa, caixa de costura). A maioria está vazia ou
   tem só um texto de ambiente; uma tem a **chave pequena**. Aqui também está o 1º bilhete
   rasgado da senha.
4. Volta ao 302, abre a gaveta, pega o **fusível**, coloca no quadro. A energia volta, o
   telefone do 304 começa a tocar, o teclado do 303 liga e a **zeladoria destrava**.
5. **Zeladoria:** pega o **pé de cabra**.
6. **305:** arranca a tábua da porta com o pé de cabra (faz barulho, mas o Ouvinte ainda não
   existe). Dentro, o 3º bilhete. O 2º bilhete está no 302 (aparece só com a luz acesa, ou
   dentro de outro móvel revistável).
7. **Senha em partes:** a senha continua 0317 (a hora em que os relógios pararam). Os três
   bilhetes rasgados dão "03", "1" e "7" e dizem a posição de cada um. O diário deixa de
   entregar a hora inteira: fala só que "é a hora em que os relógios pararam", e os relógios
   parados nos cômodos servem de confirmação para quem observar.
8. **303:** digita 0317, entra, lê a transcrição, pega a chave do 304. A luz cai.
9. **Final (igual a hoje):** ao sair do 303 o Ouvinte nasce na ponta distante do corredor e
   vem andando e rosnando. Chegar ao 304 agachado ou devagar, atender o telefone.

O HUD deve atualizar o objetivo a cada etapa, e o inventário mostrar chave pequena, fusível,
pé de cabra e os bilhetes encontrados (ex.: "Senha: 0 3 _ 7").

## Mecânicas novas

- **`Searchable`** (`game/interact/searchable.gd`, já criado e testado): móvel revistável.
  `[E] Revistar`; pode estar trancado por um item (`locked_key`), pode conter um item
  (`item_id`, `item_name`) ou só um texto (`empty_text`). Emite `opened` e `item_found`.
- **Barricada** (a fazer): tábua na porta do 305; exige `pe_de_cabra`; ao remover, libera a
  `Door` (`sealed = false`), toca rangido e chama `player.make_noise`.
- **Trava elétrica** (a fazer): porta da zeladoria com `sealed = true` até `set_power(true)`.
- **Bilhetes de senha** (a fazer): `Readable` que, ao ser lido, registra o pedaço no
  inventário/HUD.

## Regras do projeto

- Antes de editar: `git status`, `git log`, e conferir se `codex.exe` está mexendo no repositório.
- Testes: `GODOT=... tools/test.sh` (84 testes Godot + 21 Node passando no commit de partida).
  Os testes do capítulo 1 usam posições fixas (`tests/test_chapter1.gd`, `tests/test_gameplay.gd`,
  `tools/e2e/web-smoke.mjs` anda 4 m para a frente a partir do início): atualizar junto.
- Build e teste real: `tools/build-site.sh dev` e `node tools/e2e/web-smoke.mjs build/site --headful`.
- Publicar: commit na branch `development` e `git push`; conferir o Actions e o
  `version.json` do link público antes de dizer que está no ar.
- Build Web hoje com 107 MB; teto combinado 150 MB.
