# Deepglow — Game Design Document (v0.8)

> Documento vivo. Nomes técnicos (ids, classes, chaves de tradução) ficam em inglês;
> todo texto exibido ao jogador existe em `localization/translations.csv` (en + pt_BR).

## 1. Visão geral

- **Gênero:** incremental com coleta ativa (clicar), organizado em **fases com timer**.
- **Fantasia:** sobreviver e prosperar numa floresta noturna e bioluminescente: derrubar árvores,
  colher frutas, beber de nascentes, minerar, pescar, caçar e, no fim, alcançar os cristais
  luminosos das profundezas ("Deepglow").
- **Duração-alvo:** ~**2h10** para o jogador médio do simulador completar a árvore (revisto em set/2026, D5: a primeira partida real do dono levou quase 6 h com a meta antiga de 3h30).
- **Sem derrota:** o jogador sempre progride, só mais rápido ou mais devagar.
- **Plataforma inicial:** desktop (mouse). Teclado/gamepad depois (cursor andando casa a casa).
- **Idiomas:** inglês e português (Brasil), escolhidos na tela inicial.

## 2. Loop principal

```
┌─> MONTAR FASE ──> FASE (timer) ──> RESUMO ──> ÁRVORE DE EVOLUÇÃO ──┐
└────────────────────────────────────────────────────────────────────┘
```

1. **Montar fase:** o gerador de fases (seção 6) escolhe as fontes de acordo com o progresso atual.
2. **Fase:** **todas as fontes já aparecem no tabuleiro no início**. O jogador clica para coletar.
   O tempo é **justo**: dá para coletar tudo jogando bem, mas às vezes não dá.
3. **Resumo:** o que foi coletado, o que ficou para trás, recordes.
4. **Árvore de evolução:** gastar recursos em melhorias/desbloqueios.

A passagem de fase tem um **ciclo dia-noite visual** (anoitecer = fim do timer), que combina com a
bioluminescência.

## 3. Fontes, raridade e cliques

Cada **fonte** tem: ferramenta exigida, **raridade**, **cliques para coletar** (vida), rendimento
e peso de aparecimento. Uma mesma família (ex.: árvores) tem **variações** que exigem mais cliques e
rendem mais. Ferramentas melhores reduzem os cliques (mínimo 1).

### 3.1 Raridades

| Raridade (id) | Peso base | Uso |
|---|---|---|
| Comum (`common`) | 60 | a base de toda fase |
| Incomum (`uncommon`) | 25 | variações mais duras e rentáveis |
| Rara (`rare`) | 12 | poucas por fase; recompensa alta |
| Épica (`epic`) | 3 | eventual; recurso especial |

Os pesos são o ponto de partida; o gerador ainda filtra por desbloqueios e pelo orçamento de cliques.

**A raridade não é exibida no tabuleiro** (decidido): ela existe só nos dados, para o gerador
controlar a frequência de cada fonte. Quem comunica o valor é o próprio sprite (o carvalho é maior
que o pinheiro, a árvore luminosa brilha); o jogador aprende pela experiência.

### 3.2 Fontes (camadas 0–4 implementadas; valores em `data/sources/`)

| Camada | Fonte (id) | Raridade | Cliques | Rende | Ferramenta (cursor) |
|---|---|---|---|---|---|
| 0 | Pinheiro (`tree_pine`) | comum | 3 | 2 madeira | machado (`axe`) |
| 0 | Carvalho (`tree_oak`) | incomum | 7 | 6 madeira | machado |
| 0 | Árvore luminosa (`tree_glow`) | rara | 12 | 12 madeira + 1 seiva luminosa | machado |
| 0 | Arbusto de frutas (`berry_bush`) | comum | 2 | 2 fruta | mão (`hand`) |
| 0 | Macieira (`fruit_tree`) | incomum | 5 | 5 fruta | mão |
| 0 | Poça (`puddle`) | comum | 1 | 1 água | copo (`cup`) |
| 0 | Nascente (`spring`) | incomum | 4 | 5 água | copo |
| 1 | Lago (`pond`) | incomum | 6 | 3 peixe | vara (`fishing_rod`) |
| 2 | Pedra solta (`rock_small`) | comum | 4 | 2 pedra | picareta (`pickaxe`) |
| 2 | Rocha (`rock_large`) | incomum | 9 | 6 pedra | picareta |
| 2 | Cristal Violeta (`crystal_violet`) | incomum | 12 | 3 cristal | picareta de cristal (`crystal_pick`) |
| 2 | Cristal Deepglow (`crystal_teal`) | rara | 16 | 6 cristal | picareta de cristal |
| 3 | Veio de Cobre (`copper_vein`) | comum | 8 | 3 cobre | picareta reforçada (`ore_pick`) |
| 3 | Veio de Ferro (`iron_vein`) | incomum | 12 | 4 ferro | picareta reforçada |
| 3 | Veio de Ouro (`gold_vein`) | rara | 16 | 4 ouro | picareta reforçada |
| 4 | Javali (`boar`) | rara | 10 | 4 carne | lança (`spear`) |

A camada acompanha o bioma em que a ferramenta é liberada (§7.2): 1 Pântano, 2 Cavernas de
Cristal, 3 Bosque de Cinzas, 4 Vale Lunar Congelado.

## 4. Interação: cursor contextual (decidido)

- Ao passar o mouse sobre uma fonte, o **cursor vira a ferramenta correspondente**
  (machado na árvore, picareta na rocha, copo na nascente…). Não existe menu de ferramentas.
- Se a ferramenta ainda não foi desbloqueada, o cursor mostra um **cadeado** e o clique não coleta.
- Cada clique mostra progresso no card (barra de "vida" ou rachaduras), tremida, partículas e som.
  Ao esgotar: número flutuante (`+6 madeira`) e o card fica vazio até a próxima fase.

## 5. Fome e sede (decidido)

- Duas barras, **fome** e **sede**, esvaziam durante a fase.
- Coletar comida/bebida enche a barra correspondente (além de guardar o recurso no inventário).
- Barra vazia **não mata**; cada barra tem a sua punição, que faz sentido sozinha (D6, revisto
  em set/2026):
  - **Fome vazia → golpes fracos:** cada clique conta 0,5 (sem energia, sem força).
  - **Sede vazia → rende metade:** cada **material** coletado rende metade (mínimo 1); comida e
    bebida não são reduzidas, para o jogador sempre conseguir se recuperar.
  - As duas vazias somam as duas punições (golpes fracos e materiais pela metade).
  Isso cria o dilema "coletar madeira agora ou beber água primeiro" sem punição dura.
- A punição é **visível**: a barra vazia pisca com a moldura rosa, o ícone treme quando ela zera
  e o rótulo troca para "Fome: golpes fracos" / "Sede: rende metade"; o primeiro golpe fraco
  mostra "Fraco!" e o primeiro material reduzido mostra "Com sede!" (o "+N" fica rosa); golpes
  fracos soltam menos lascas, soam mais graves e vibram menos; o resumo da fase diz quantos
  segundos o jogador passou com fome/sede e o efeito.
- Valores (simulador, D6): fome cai 4%/s e sede 4,5%/s (barras cheias duram ~22–25 s). Um jogador
  atento quase nunca zera; um jogador descuidado (só madeira) passa ~10% do tempo com barra vazia e
  perde ~4% de ritmo — a pressão existe, mas não pune demais.
- Melhorias podem reduzir o consumo (cantil, cesta).

## 6. Gerador de fases (fases dinâmicas)

As fases **não são fixas**: são montadas a partir do progresso atual para manter o tempo justo e
impedir progressão absurda.

1. **Conteúdo da fase (igual para todos):** `orçamento = duração_base × cps_de_referência` (em
   "cliques-equivalentes": cliques + deslocamento do mouse). Depende só do progresso (a melhoria de
   tempo aumenta a duração base), nunca da velocidade do jogador.
2. **Sorteio das fontes:** entre as fontes desbloqueadas, sorteia por peso de raridade e soma o custo
   em cliques (já com o desconto das ferramentas) até atingir o orçamento ou encher o tabuleiro
   (75% das casas). Garante um mínimo de comida e água (3 + 3). Quando fontes baratas encheriam o
   tabuleiro antes do orçamento, o sorteio **favorece fontes mais caras/raras** (`cheap_source_penalty`).
   **Demanda (D10):** o peso também considera o que o jogador ainda precisa — soma o custo de todas as
   evoluções que faltam, desconta o inventário, e multiplica o peso das fontes desses recursos por até
   `1 + demand_boost` (6; o recurso mais em falta recebe o máximo). Recursos que nenhuma evolução pede
   mais ficam raros (`surplus_weight` 0,15); comida e água nunca perdem valor (fome/sede).
3. **Timer ajustado ao jogador:** `timer = trabalho_da_fase / (cps_medido × aperto)`, com `aperto`
   sorteado entre **0,95 e 1,10** (acima de 1 falta um pouco de tempo; abaixo sobra). O cps medido é
   uma média móvel das últimas fases (limitada entre 2 e 5), já contando o deslocamento do mouse.
   Assim **toda fase é justa para qualquer jogador**: quem clica mais rápido ganha só tempo
   (timer menor), não mais recursos por fase — não existe efeito bola de neve.
4. **Posição:** distribui as fontes pelas casas (vizinhanças temáticas: água perto de água, árvores em
   grupos) para ficar bonito e legível.
5. **Semente:** cada fase tem uma *seed* registrada, para reproduzir e depurar.

Consequência: melhorar ferramentas não deixa a fase trivial, porque o gerador coloca fontes mais
raras/duras. O ganho aparece como **recursos melhores**, não como fases vazias.

Valores atuais em `data/phases/default_rules.tres` (ajustados pelo simulador, seção 8).

## 7. Árvore de evolução

Aberta entre as fases. Cada nó tem custo (um ou vários recursos), pré-requisitos e efeito.

| Tipo de nó | Exemplos |
|---|---|
| Desbloqueio | picareta (libera rochas), vara de pesca, lança |
| Ferramenta melhor | machado de pedra: −1 clique nas árvores; machado de ferro: −2 |
| Tempo | +5 s por fase (poucos níveis, caros) |
| Raridade | "olho treinado": aumenta o peso de fontes raras |
| Rendimento | +1 madeira por árvore; chance de coleta dupla |
| Sobrevivência | cantil (sede cai mais devagar), cesta (fruta enche mais a fome) |
| Automação (incremental) | lenhador: coleta 1 madeira a cada N s durante a fase |

Custos crescem de forma geométrica por nível. A árvore completa terá ~50–70 nós.

### 7.0 Nós atuais (6 biomas, 29 nós)

| Linha | Nós (coluna) | Bioma (portão) |
|---|---|---|
| 0 | Machado Afiado (1) · Cesta (3) · Cantil (5) | Bosque Noturno (início) |
| 1 | Olho de Lenhador (0) · Olhar Atento (2) · Dias Longos (3) | |
| 2 | **Vara de Pesca** (4) | Pântano Luminescente (10) |
| 3 | Refeições Fartas (3) · Isca (4) · Mãos Firmes (5) | |
| 4 | **Picareta** (1) | Cavernas de Cristal (18) |
| 5 | Picareta Afiada (0) · **Picareta de Cristal** (1) · Olho de Pedreiro (2) | |
| 6 | Fio de Cristal (0) · Sintonia (1) · escolha: Mestre Pedreiro (3) **ou** Mestre Pescador (4) | |
| 7 | **Picareta Reforçada** (0) | Bosque de Cinzas (31) |
| 8 | Picareta Temperada (0) · Faro de Cobre (1) · Faro de Ferro (2) · Cantil de Cobre (3) | |
| 9 | escolha: Febre do Ouro (1) **ou** Foco Profundo (2) | |
| 10 | **Lança** (3) | Vale Lunar Congelado (41) |
| 11 | Lança Afiada (2) · Instinto de Caçador (4) | |
| 12 | **Coração de Deepglow** (3) — nó final | Ruínas Submersas (53) |

A interface mostra no HUD e no topo da árvore apenas os recursos já descobertos (coletados ao
menos uma vez) e usa números compactos (1.2k) para caber em 640x360.

### 7.1 Estrutura (decidido)

A árvore é **desenhada como árvore** (referência estrutural: árvores de talentos em grade), não
como lista:

- **Grade:** cada nó tem uma posição (`grid_position`: coluna, linha); a linha 0 fica no topo.
- **Conexões:** linhas ligam cada pré-requisito ao nó dependente.
- **Níveis:** cada nó mostra `nível/máximo` (ex.: 1/3).
- **Nós de escolha:** nós com o mesmo `choice_group` são exclusivos — comprar um bloqueia os outros.
- **Portões = biomas:** cada bioma (§7.2) exige um total de níveis investidos na árvore para
  liberar as suas linhas; a divisória mostra o nome do bioma e os pontos ("Pântano Luminescente ·
  10 necessários"). Um nó ainda pode ter `required_points` próprio (vale o maior).
- **Estados visuais:** bloqueado, disponível, comprável, parcialmente comprado, completo.

### 7.2 Biomas (decidido, set/2026)

A jornada da "História de Deepglow" atravessa seis biomas, um por etapa da árvore. Alcançar os
pontos de um bioma troca o fundo das fases (arte do bioma convertida para a paleta) e a primeira
fase nele mostra o aviso "Novo bioma". O conteúdo de cada etapa combina com o lugar:

| Bioma | Pontos | O que se coleta de novo | Tema |
|---|---|---|---|
| Bosque Noturno | 0 | madeira, fruta, água | a floresta de onde você parte |
| Pântano Luminescente | 10 | peixe (vara) | águas paradas cheias de peixe |
| Cavernas de Cristal | 18 | pedra (picareta) e cristais (picareta de cristal) | mineração na caverna |
| Bosque de Cinzas | 31 | cobre, ferro, ouro (picareta reforçada) | o fogo expôs os veios de metal |
| Vale Lunar Congelado | 41 | carne (lança, javali) | caça na neve |
| Ruínas Submersas | 53 | — | o Coração de Deepglow |

Dados: `data/biomes/*.tres` (`Biome`: id, fundo, pontos, primeira linha da árvore), em ordem em
`GameDatabase.biomes`. O bioma atual é derivado dos níveis comprados (não vai no save): chega-se a
um bioma com os pontos do portão **e** ao menos um nível comprado nas linhas do bioma anterior —
assim não dá para "pular" um bioma só maximizando os nós anteriores (ex.: chegar às Ruínas sem a
lança). Fundos:
`tools/art/concept_background.py <arte> <saída> --lab` (+ `--warm-boost 2.2` no Bosque de Cinzas).

**Tela (M2.5):** a árvore ocupa a área principal (com rolagem quando crescer) e um painel lateral
mostra nome, nível, descrição, custo e o motivo do bloqueio (pré-requisito, pontos ou escolha já
feita). Passar o mouse/foco num nó mostra os detalhes; clicar no nó selecionado (ou em "Comprar")
compra um nível. Cores da moldura: cinza = bloqueado, azul = disponível sem recursos, turquesa =
pode comprar, âmbar = parcialmente comprado, amarelo = completo.

## 8. Balanceamento e duração

- Todos os números ficam em dados (`.tres`), nunca no código.
- **Ritmo:** fase de ~45–60 s + ~15–30 s entre fases ⇒ ~2h10 ≈ **110 fases** no jogo completo.
- **Marcos-alvo:** 1ª melhoria após 1–2 fases; camada 0 completa (conteúdo do M1) em ~25–35 min;
  camada 1 por volta de 20–30 min; 1ª automação ~45 min; camada 2 ~1h15; cristais 2h30+.

### 8.1 Simulador (M2)

`tools/balance/` — escrito em **GDScript** e roda o **código real do jogo** (`ProgressionState`,
`PhaseGenerator`, `Inventory`, `Needs`) com os dados reais (`data/game_database.tres`), então nunca
diverge do jogo. Um jogador simulado:

- tem uma velocidade fixa (cliques-equivalentes/s) e um tempo fixo entre fases (15 s);
- na fase, escolhe a fonte com melhor rendimento por clique, mas come/bebe quando uma barra fica
  abaixo de 35% (perfil "descuidado" ignora as barras e prioriza madeira);
- entre fases, compra sempre a melhoria disponível mais barata (guloso), até não poder mais.

```bash
godot --headless --path . -s res://tools/balance/simulate.gd -- --runs 30 --target-minutes 25
```

Relatório em `tools/balance/reports/latest.md` (não versionado). Perfis padrão: lento 2,2 · médio
3,0 · rápido 4,5 cliques/s.

**Critérios de aceite** (o script sai com erro se algum falhar):

| Critério | Meta |
|---|---|
| Médio completa a árvore | em todas as execuções |
| Duração do médio | ≥ alvo (`--target-minutes`: 25 no M1, 120 no jogo completo; padrão 120) |
| 1ª melhoria | até a fase 2 |
| Fases justas | 15–60% das fases totalmente limpas |
| Rápido vs médio | no máximo 40% mais rápido **e** mesmo nº de fases (±10%) — sem bola de neve |
| Fim do jogo útil | ≥ 50% do que o médio coleta no último quarto ainda serve para alguma evolução |

### 8.2 Resultado atual (biomas + gerador com demanda; 29 nós, 12 execuções por perfil)

Antes da demanda, no último quarto do jogo só **11%** do que se coletava ainda servia (sobravam
madeira, pedra e frutas; faltavam cobre, ouro e cristal) e o médio levava ~3h30 no simulador — na
primeira partida real, quase 6 h. Agora a meta é ~2h10 no simulador, e os custos sobem de forma
**gradual** pela linha da árvore: `custo × (1 + 0,4 × linha/10)` — linha 0 igual a antes, a última
linha +40% (arredondados).

Na realocação por biomas (set/2026) os custos de cada nó passaram a usar os recursos do seu bioma
e foram reajustados no simulador.

| Perfil | Minutos (médio) | Fases | Fases limpas | Barra vazia | Coleta útil (último quarto) |
|---|---|---|---|---|---|
| Lento (2,2) | 183,1 | 119 | 17% | 15,1% | 49% |
| Médio (3,0) | **132,0** (~2h10) | 111 | 28% | 6,8% | 55% |
| Rápido (4,5) | 92,9 | 106 | 45% | 0,6% | 63% |

Marcos do jogador médio (minutos), por bioma: Pântano (vara) ~14 · Cavernas (picareta) ~33,
picareta de cristal ~44 · Bosque de Cinzas (minérios) ~67 · Vale Lunar (lança) ~112 · Coração
de Deepglow (fim) ~128.

Critério "rápido ≤ 40% mais rápido que o médio": fica no limite (40–42% conforme as execuções;
já estava em 40% antes da realocação) — aceito por ora.

Comando: `--runs 12` (alvo padrão 120 min; leva ~1–2 min; o jogo completo tem ~110 fases por execução).

## 9. Modelo de dados (técnico)

| Resource (`class_name`) | Papel | Pasta |
|---|---|---|
| `ResourceType` | recurso coletável (id, ícone, categoria: material/comida/bebida) | `data/resources/` |
| `Rarity` | raridade (id, peso base, cor) | `data/rarities/` |
| `SourceType` | fonte no tabuleiro (família, raridade, ferramenta, cliques, rendimento, camada) | `data/sources/` |
| `ToolType` | ferramenta/cursor (id, ícone, redução de cliques, desbloqueada por) | `data/tools/` |
| `UpgradeNode` | nó da árvore (custo por nível, pré-requisitos, efeitos) | `data/upgrades/` |
| `PhaseRules` | duração base, faixa de aperto, limites de CPS, mínimos de comida/água | `data/phases/` |

Estado em tempo de execução (classes puras, testáveis e salváveis): `Inventory`,
`ProgressionState` (melhorias, desbloqueios, CPS medido), `Needs` (fome/sede) e `PhaseGenerator`
(entrada: progresso + seed; saída: `PhasePlan` com fontes e posições). Todo o banco de dados fica em
`data/game_database.tres` (`GameDatabase`). O simulador em Python e o jogo devem usar a **mesma
fórmula**; o gerador fica isolado para permitir testes.
Estados da `StateMachine`: `Setup` → `PhaseBuild` → `Phase` → `PhaseSummary` → `Upgrade`.

## 10. Roadmap

| Etapa | Entrega |
|---|---|
| M1 — Protótipo do loop ✅ | madeira, fruta e água (com variações de raridade); gerador de fases; timer; cursor contextual; fome/sede; HUD; tela de evolução com ~5 nós; arte provisória |
| M2 — Simulador ✅ | script de balanceamento + meta de 3 h verificada |
| M2.5 — Árvore desenhada ✅ | tela da árvore em grade com conexões, níveis, escolhas e portões |
| M3 — Camadas 1–2 ✅ | rochas, lago, javali |
| M3.5 — Camadas 3+ ✅ | minérios (cobre, ferro, ouro), cristais e o nó final; meta de 3 h atingida |
| M4 — Arte ✅ | sprites definitivos no Pixellab (fontes por raridade + cursores + ícones) |
| M5 — Save ✅ | salvar/carregar progresso (autosave entre fases e a cada compra; menu inicial com Continuar/Novo jogo) |
| M6 — Sensação ✅ | áudio sintetizado (efeitos por material, música techno em camadas com "rush" nos últimos 10 s, ambiente noturno), partículas em pixel e ciclo anoitecer → noite profunda |
| M7 — Publicação ✅ (técnico) | presets de export (Windows, macOS, Linux) + script de build; jogo completo por teclado/controle; camada Steam opcional e conquistas. Publicação na Steam/Apple, assinatura do macOS, arte da loja e teste no Steam Deck ficaram como melhoria futura (`docs/publishing.md` §6) |

## 11. Decisões

| # | Decisão | Status |
|---|---|---|
| D0 | Ferramenta pelo cursor contextual (sem menu) | decidido |
| D1 | Fome/sede em barras; vazia = punição própria de cada barra (D6), sem morte | decidido |
| D2 | Sem derrota | decidido |
| D3 | Todas as fontes aparecem no início da fase; tempo justo; fases geradas pelo progresso | decidido |
| D4 | Timer + ciclo dia-noite visual: cada fase vai do anoitecer (40%) à noite profunda (75%) — o cenário escurece em degraus da paleta (o tabuleiro não escurece; halos nos itens foram testados e rejeitados) | decidido (M6) |
| D5 | ~2h10 no simulador (jogador médio) para completar a árvore — revisto em set/2026 (era 3 h; a partida real levou ~6 h) | decidido |
| D6 | Fome vazia: cada clique vale 0,5; sede vazia: materiais rendem metade (comida/bebida não); drenagem 4%/s e 4,5%/s; punição sempre visível no HUD | decidido (revisto set/2026) |
| D7 | Sem estruturas nem transformação de recursos: fogueira removida; carne do javali é comida e recurso | decidido |
| D8 | Raridade não é exibida no tabuleiro; o sprite comunica o valor | decidido |
| D9 | Árvore de evolução desenhada em grade (conexões, níveis, escolhas, portões) | decidido |
| D10 | Gerador ciente da demanda: fontes dos recursos que faltam aparecem mais, as inúteis ficam raras; custos sobem gradualmente pela árvore (+0% no topo, +40% na última linha) | decidido (simulador) |
| D11 | Seis biomas, um por etapa da árvore: o portão de pontos troca o fundo e o conteúdo de cada etapa combina com o bioma (§7.2) | decidido (set/2026) |
