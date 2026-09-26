# Deepglow — Game Design Document (v0.1, rascunho)

> Documento vivo. Nomes técnicos (ids, classes, chaves de tradução) ficam em inglês;
> todo texto exibido ao jogador existe em `localization/translations.csv` (en + pt_BR).

## 1. Visão geral

- **Gênero:** incremental com coleta ativa (clicar), organizado em **fases com timer**.
- **Fantasia:** sobreviver e prosperar numa floresta noturna e bioluminescente: derrubar árvores,
  colher frutas, beber de nascentes, minerar, pescar, caçar e, no fim, alcançar os cristais
  luminosos das profundezas ("Deepglow").
- **Plataforma inicial:** desktop (mouse). Teclado/gamepad depois (cursor andando casa a casa).
- **Idiomas:** inglês e português (Brasil), escolhidos na tela inicial.

## 2. Loop principal

```
┌─> FASE (timer) ──> RESUMO ──> ÁRVORE DE EVOLUÇÃO ──┐
└────────────────────────────────────────────────────┘
```

1. **Fase:** o tabuleiro 8x8 funciona como uma grade de *cards*. Neles surgem **fontes de recurso**.
   O jogador clica nas fontes para coletar até o timer acabar.
2. **Resumo:** o que foi coletado na fase (e recordes).
3. **Árvore de evolução:** gastar recursos em melhorias/desbloqueios. Depois, próxima fase.

Duração inicial proposta da fase: **45 s** (aumenta com melhorias).

## 3. Fontes e recursos

Cada **fonte** tem: ferramenta exigida, *vida* (cliques para esgotar), rendimento por clique
e/ou ao esgotar, tempo para renascer e peso de aparecimento no tabuleiro.

| Camada | Fonte (id) | Recurso (id) | Ação / ferramenta (cursor) | Observação |
|---|---|---|---|---|
| 0 | Árvore (`tree`) | Madeira (`wood`) | cortar / machado (`axe`) | recurso inicial |
| 0 | Árvore frutífera (`fruit_tree`) | Fruta (`fruit`) | colher / mão (`hand`) | comida |
| 0 | Nascente (`spring`) | Água (`water`) | beber / copo (`cup`) | bebida |
| 1 | Rocha (`rock`) | Pedra (`stone`) | minerar / picareta (`pickaxe`) | desbloqueio |
| 1 | Lago (`pond`) | Peixe (`fish`) | pescar / vara (`fishing_rod`) | comida melhor |
| 2 | Javali (`boar`) | Carne no osso (`meat`) | caçar / lança (`spear`) | comida ótima |
| 2 | Fogueira (`campfire`) | Carne assada (`cooked_meat`) | cozinhar (carne + madeira) | primeira transformação |
| 3+ | Veio de minério (`ore_vein`) | Minérios (`copper`, `iron`, `gold`) | picareta melhor | |
| 3+ | Cristal (`crystal`) | Cristais (`crystal_violet`, `crystal_teal`) | picareta de cristal | tema "Deepglow" |

Os valores (vida, rendimento, tempos) serão definidos no balanceamento (seção 7).

## 4. Interação: cursor contextual (proposta — confirmar)

- Ao passar o mouse sobre uma fonte, o **cursor vira a ferramenta correspondente**
  (machado na árvore, picareta na rocha, copo na nascente…). Não existe menu de ferramentas.
- Se a ferramenta ainda não foi desbloqueada, o cursor mostra um **cadeado** e o clique não coleta.
- Feedback de clique: tremida no card, partículas, número flutuante (`+1 madeira`), som.
- Motivo: menos cliques de interface, mais ritmo, cabe em 320x180. Um menu só faria sentido se as
  ferramentas tivessem escolhas conflitantes, o que não é o caso agora.

## 5. Árvore de evolução

Aberta entre as fases. Cada nó tem custo (um ou vários recursos), pré-requisitos e efeito.

| Tipo de nó | Exemplos |
|---|---|
| Desbloqueio | picareta (libera rochas), vara de pesca (libera lagos), lança, fogueira |
| Ferramenta melhor | machado de pedra: −1 clique por árvore |
| Tempo | +10 s por fase |
| Tabuleiro | mais fontes simultâneas; renascimento mais rápido; tabuleiro maior (futuro) |
| Rendimento | +1 madeira por árvore; chance de coleta dupla |
| Automação (incremental) | lenhador: coleta 1 madeira a cada N s sozinho; balde: água automática |

Primeira árvore (esboço para o protótipo):

```
Machado de pedra (madeira) ──> Picareta (madeira + pedra?) ──> ...
Cesta (madeira + fruta) ─────> +1 fruta por colheita
Tempo +10 s (fruta + água)
Lenhador (madeira alta)       [primeira automação]
```

## 6. Decisões em aberto

| # | Pergunta | Opções | Recomendação atual |
|---|---|---|---|
| D1 | Comer/beber é necessidade ou só recurso? | (a) barras de fome/sede que esvaziam na fase e reduzem a velocidade se zerarem; (b) meta de comida/água no fim da fase; (c) só moeda da evolução | (a) — dá motivo para comer/beber durante a ação, sem punição dura |
| D2 | O jogo pode ser perdido? | sem derrota (incremental clássico) / runs com recomeço (roguelite com evolução permanente) | sem derrota |
| D3 | Como os recursos surgem? | aleatório em casas vazias / cards virados para revelar / mapa fixo por fase | aleatório com pesos, fontes renascem |
| D0 | Ferramenta automática pelo cursor ou menu de ferramentas? | cursor contextual / menu | cursor contextual (seção 4) |
| D4 | O que marca a passagem de fase? | só timer / timer + ciclo dia-noite visual | timer + ciclo visual (combina com a bioluminescência) |

## 7. Balanceamento

- Todos os números ficam em dados (`.tres`), nunca no código.
- Um **script simulador** (`tools/balance/`) calcula recursos por fase a partir de cliques por
  segundo estimados, fontes ativas e melhorias compradas.
- Metas iniciais: a 1ª melhoria sai após 1–2 fases; a 1ª automação por volta da fase 5–8;
  cada fase deve render algo "comprável" (evitar fases sem recompensa).

## 8. Modelo de dados (técnico)

| Resource (`class_name`) | Papel | Pasta |
|---|---|---|
| `ResourceType` | recurso coletável (id, ícone, categoria: material/comida/bebida) | `data/resources/` |
| `SourceType` | fonte no tabuleiro (ferramenta, vida, rendimento, respawn, peso) | `data/sources/` |
| `ToolType` | ferramenta/cursor (id, ícone, desbloqueada por) | `data/tools/` |
| `UpgradeNode` | nó da árvore (custo, pré-requisitos, efeitos) | `data/upgrades/` |
| `PhaseConfig` | duração, limite de fontes, tabela de aparecimento | `data/phases/` |

Estado em tempo de execução: `Inventory` (quantidades), `ProgressionState` (melhorias
compradas, desbloqueios) — classes puras, testáveis e serializáveis (save).
Os estados atuais da `StateMachine` passam a ser: `Setup` → `Phase` → `PhaseSummary` → `Upgrade`.

## 9. Roadmap

| Etapa | Entrega |
|---|---|
| M1 — Protótipo do loop | madeira, fruta e água; timer; cursor contextual; HUD de recursos; tela de evolução com ~5 nós; arte provisória |
| M2 — Simulador | script de balanceamento + ajuste das primeiras fases |
| M3 — Camadas 1–2 | rocha, lago, javali, fogueira |
| M4 — Arte | sprites definitivos no Pixellab (~10 fontes + cursores + ícones de recurso) |
| M5 — Save | salvar/carregar progresso |
| M6 — Sensação | partículas, sons, ciclo dia-noite, luzes bioluminescentes |
