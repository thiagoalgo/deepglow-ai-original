# Deepglow — Game Design Document (v0.2)

> Documento vivo. Nomes técnicos (ids, classes, chaves de tradução) ficam em inglês;
> todo texto exibido ao jogador existe em `localization/translations.csv` (en + pt_BR).

## 1. Visão geral

- **Gênero:** incremental com coleta ativa (clicar), organizado em **fases com timer**.
- **Fantasia:** sobreviver e prosperar numa floresta noturna e bioluminescente: derrubar árvores,
  colher frutas, beber de nascentes, minerar, pescar, caçar e, no fim, alcançar os cristais
  luminosos das profundezas ("Deepglow").
- **Duração-alvo:** **no mínimo 3 horas** de jogo para completar a árvore de evolução.
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
A raridade aparece no card (moldura/brilho na cor da raridade).

### 3.2 Fontes (valores iniciais para o protótipo — serão ajustados pelo simulador)

| Camada | Fonte (id) | Raridade | Cliques | Rende | Ferramenta (cursor) |
|---|---|---|---|---|---|
| 0 | Pinheiro (`tree_pine`) | comum | 3 | 2 madeira | machado (`axe`) |
| 0 | Carvalho (`tree_oak`) | incomum | 7 | 6 madeira | machado |
| 0 | Árvore luminosa (`tree_glow`) | rara | 12 | 12 madeira + 1 seiva luminosa | machado |
| 0 | Arbusto de frutas (`berry_bush`) | comum | 2 | 2 fruta | mão (`hand`) |
| 0 | Macieira (`fruit_tree`) | incomum | 5 | 5 fruta | mão |
| 0 | Poça (`puddle`) | comum | 1 | 1 água | copo (`cup`) |
| 0 | Nascente (`spring`) | incomum | 4 | 5 água | copo |
| 1 | Pedra solta (`rock_small`) | comum | 4 | 2 pedra | picareta (`pickaxe`) |
| 1 | Rocha (`rock_large`) | incomum | 9 | 6 pedra | picareta |
| 1 | Lago raso (`pond`) | incomum | 6 | 2 peixe | vara (`fishing_rod`) |
| 2 | Javali (`boar`) | rara | 10 | 3 carne no osso | lança (`spear`) |
| 2 | Fogueira (`campfire`) | — | 3 | carne → carne assada | (estrutura, cozinha) |
| 3+ | Veio de cobre/ferro/ouro (`ore_*`) | incomum → rara | 10–18 | minérios | picareta melhor |
| 3+ | Cristal (`crystal_*`) | rara/épica | 15–25 | cristais | picareta de cristal |

## 4. Interação: cursor contextual (decidido)

- Ao passar o mouse sobre uma fonte, o **cursor vira a ferramenta correspondente**
  (machado na árvore, picareta na rocha, copo na nascente…). Não existe menu de ferramentas.
- Se a ferramenta ainda não foi desbloqueada, o cursor mostra um **cadeado** e o clique não coleta.
- Cada clique mostra progresso no card (barra de "vida" ou rachaduras), tremida, partículas e som.
  Ao esgotar: número flutuante (`+6 madeira`) e o card fica vazio até a próxima fase.

## 5. Fome e sede (decidido)

- Duas barras, **fome** e **sede**, esvaziam durante a fase.
- Coletar comida/bebida enche a barra correspondente (além de guardar o recurso no inventário).
- Barra vazia **não mata**: deixa a coleta mais lenta (ex.: cada clique conta 0,5). Isso cria o
  dilema "coletar madeira agora ou beber água primeiro" sem punição dura.
- Melhorias podem reduzir o consumo (cantil, cesta).

## 6. Gerador de fases (fases dinâmicas)

As fases **não são fixas**: são montadas a partir do progresso atual para manter o tempo justo e
impedir progressão absurda.

1. **Capacidade do jogador:** `capacidade = duração_da_fase × cliques_por_segundo_efetivos`.
   Os cliques por segundo são uma média móvel medida nas últimas fases (limitada entre um mínimo e
   um máximo, para não punir nem premiar demais), já descontando o tempo de mover o mouse.
2. **Orçamento de cliques:** `orçamento = capacidade × aperto`, com `aperto` entre **1,00 e 1,15**
   (a fase quase sempre tem um pouco mais de trabalho do que dá para fazer; às vezes sobra).
3. **Sorteio das fontes:** entre as fontes desbloqueadas, sorteia por peso de raridade e soma o custo
   em cliques (já com o desconto das ferramentas) até atingir o orçamento ou encher o tabuleiro.
   Garante um mínimo de comida e água para as barras de fome/sede.
4. **Posição:** distribui as fontes pelas casas (vizinhanças temáticas: água perto de água, árvores em
   grupos) para ficar bonito e legível.
5. **Semente:** cada fase tem uma *seed* registrada, para reproduzir e depurar.

Consequência: melhorar ferramentas não deixa a fase trivial, porque o gerador coloca fontes mais
raras/duras. O ganho aparece como **recursos melhores**, não como fases vazias.

## 7. Árvore de evolução

Aberta entre as fases. Cada nó tem custo (um ou vários recursos), pré-requisitos e efeito.

| Tipo de nó | Exemplos |
|---|---|
| Desbloqueio | picareta (libera rochas), vara de pesca, lança, fogueira |
| Ferramenta melhor | machado de pedra: −1 clique nas árvores; machado de ferro: −2 |
| Tempo | +5 s por fase (poucos níveis, caros) |
| Raridade | "olho treinado": aumenta o peso de fontes raras |
| Rendimento | +1 madeira por árvore; chance de coleta dupla |
| Sobrevivência | cantil (sede cai mais devagar), cesta (fruta enche mais a fome) |
| Automação (incremental) | lenhador: coleta 1 madeira a cada N s durante a fase |

Custos crescem de forma geométrica por nível. A árvore completa terá ~50–70 nós.

## 8. Balanceamento e duração

- Todos os números ficam em dados (`.tres`), nunca no código.
- **Ritmo:** fase de ~45–60 s + ~20–30 s entre fases ⇒ ~75–90 s por ciclo ⇒ 3 h ≈ **120–145 fases**.
- **Marcos-alvo:** 1ª melhoria após 1–2 fases; camada 1 por volta de 20–30 min; 1ª automação
  por volta de 45 min; camada 2 perto de 1h15; cristais na reta final (2h30+).
- **Simulador** (`tools/balance/`): simula um jogador (cliques/s configurável, estratégia de compra
  gananciosa) usando o mesmo gerador de fases e os mesmos dados do jogo, e informa o tempo até
  cada marco e o total para completar a árvore.
- **Critério de aceite:** com um jogador "médio" simulado, completar a árvore leva **≥ 3 h**; um
  jogador "rápido" não pode passar de ~30% mais rápido.

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
| M2 — Simulador | script de balanceamento + meta de 3 h verificada |
| M3 — Camadas 1–2 | rochas, lago, javali, fogueira |
| M4 — Arte | sprites definitivos no Pixellab (fontes por raridade + cursores + ícones) |
| M5 — Save | salvar/carregar progresso |
| M6 — Sensação | partículas, sons, ciclo dia-noite, luzes bioluminescentes |

## 11. Decisões

| # | Decisão | Status |
|---|---|---|
| D0 | Ferramenta pelo cursor contextual (sem menu) | decidido |
| D1 | Fome/sede em barras; vazia = coleta mais lenta, sem morte | decidido |
| D2 | Sem derrota | decidido |
| D3 | Todas as fontes aparecem no início da fase; tempo justo; fases geradas pelo progresso | decidido |
| D4 | Timer + ciclo dia-noite visual | decidido |
| D5 | Duração mínima de 3 h para completar a árvore | decidido |
| D6 | Fome/sede vazia: fator exato de lentidão | aberto (simulador) |
| D7 | Estruturas (fogueira) ocupam casa do tabuleiro ou ficam fora dele? | aberto |
