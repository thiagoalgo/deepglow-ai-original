# Deepglow — Notas para lançamento na Steam

Atualizado em 2026-09-29. Arquivo oficial das anotações de lançamento: toda alteração ou nova anotação sobre Steam/lançamento entra aqui (versionado no repositório).

Publicar na Steam ainda não é decisão tomada. A decisão registrada em setembro de 2026 continua valendo: sem Steam, sem Apple, sem assinatura macOS e sem Steam Deck por enquanto. Este documento junta anotações para, se a decisão mudar, não começar do zero.

## Preço e duração

Preço-alvo: **US$ 3,99** (faixa US$ 2,99–4,99), com 10–20% de desconto no lançamento. Se o tempo real passar de 4 horas, US$ 4,99 fica defensável. O preço regional da Steam é automático (Brasil em torno de R$ 10–15).

- **Referência de gênero:** incrementais curtos de 1,5 a 4 horas são comuns e bem aceitos (linha de Nodebuster).
- **Reembolso:** a Steam reembolsa com até 2 horas de jogo. Se o jogo termina antes disso, há risco de terminar e pedir reembolso.
- **Tempo real vs simulador:** o simulador dá média de 2h10, e o jogador rápido até 40% mais veloz (cerca de 80 min). O dono jogou intensamente duas vezes e em 2 horas não chegou à metade. O simulador provavelmente subestima; medir com jogadores de fora antes de fixar o preço.

## Pós-jogo e insígnias

Ideia do dono: cada habilidade maximizada vira uma insígnia colecionável. O jogador **termina** ao alcançar o Coração e **completa 100%** ao reunir todas as insígnias.

- **Só aumenta o tempo de jogo se maximizar for opcional para o final.** Se o Coração exigir a árvore inteira no máximo, as insígnias só registram o que já é obrigatório.
- **Precisa haver jogo depois do Coração**, no mesmo save. Evitar pós-jogo de grind puro; uma recompensa pequena por insígnia (efeito visual, bônus leve) ajuda.
- **Nome:** na Steam, "badge" são as insígnias das cartas colecionáveis. No jogo, usar "insígnia"; no código, algo como `mastery_badge`.
- **Conquistas Steam:** ligar cada insígnia a uma conquista. Hoje são 10; com 29 habilidades, iriam a 39.
- **Caminhos exclusivos liberados no pós-jogo (decisão do dono):** na árvore, algumas escolhas eliminam outras e os nós descartados ficam travados. Depois de alcançar o Coração, esses nós devem ser liberados para compra, permitindo reunir todas as insígnias e platinar o jogo sem começar outro save.
    - Durante a primeira jornada a escolha continua valendo; a exclusividade só cai após o final.
    - Implementação provável: uma flag de jogo concluído no save, consultada pela regra de exclusividade da árvore.
    - Comunicar a liberação ao jogador no fim (por exemplo, junto ao aviso das insígnias), sem voltar ao badge "OR/OU" que foi rejeitado.
- Em aberto: "habilidade completa" = todos os níveis comprados? (confirmar com o dono)

## Demo

Escopo: **Bosque Noturno + Pântano**, terminando no portão das Cavernas de Cristal (18 pontos). Duração-alvo de 20 a 40 minutos.

- Com a introdução narrada, que é o gancho da história.
- Árvore com os biomas seguintes visíveis e travados, para mostrar quanto conteúdo existe.
- Final: banner "Novo bioma" das Cavernas bloqueado, trecho da montagem dos biomas e tela com botão de wishlist (overlay da Steam).
- O save da demo continua no jogo completo.
- Implementação: app de demo separado e gratuito no Steamworks; no Godot, feature tag `demo` num export preset próprio, sem branch.
- Usar a demo também para medir o tempo real de jogadores de fora.
- A demo também exige o questionário de conteúdo de IA.

## Demo no itch.io (ideia em amadurecimento)

Ideia do dono: lançar a demo primeiro no itch.io e divulgar para colher feedback. Objetivo: **feedback e tempo real de jogo**, não vendas nem wishlists (essas vêm da Steam). Encaixa na etapa "teste com jogadores" da timeline.

- **Versão web:** no itch, jogos jogáveis no navegador recebem muito mais cliques que downloads. Godot com GL Compatibility é o renderizador para web; `user://` vira armazenamento do navegador. Testar o áudio (navegador só libera som após um clique; a intro começa depois de "Novo jogo", então deve funcionar).
- **Público:** o itch tem muitos devs, bons para feedback de interface, bugs e ritmo, mas que não representam quem compra incrementais. Divulgar também nas comunidades do gênero (r/incremental_games, Discords de incrementais), conferindo as regras de cada uma sobre IA e autopromoção.
- **Declaração de IA no itch:** campo obrigatório na página do projeto, com subcategorias (gráficos, som, texto, código). Sem declaração, o projeto sai da navegação e só aparece por busca ou link. O itch diz não penalizar quem declara, mas jogadores podem filtrar por "No AI".
- **O que declarar:** gráficos (fundos via Pixellab), som (voz ElevenLabs) e código (escrito com Claude). Declarar menos do que foi usado é o que gera problema.
- **Reduzir atrito:** dizer na página o que é IA e o que é feito à mão (ícones e cursores em mapas ASCII, paleta própria); usar só screenshots do jogo real; separar comentários contra IA do feedback de jogabilidade.
- **Coletar dados:** mostrar o tempo total de jogo na tela final da demo e pôr ali um link para um formulário curto (onde travou, o que achou lento, se compraria). Telemetria automática fica de fora: exige consentimento e política de privacidade.

## Timeline (indicativa, Next Fest de fevereiro de 2027)

| Quando | Etapa |
| --- | --- |
| 1–31 out 2026 | Steamworks: conta, taxa de US$ 100, dados fiscais e bancários |
| 15 out – 30 nov 2026 | Página "Em breve" no ar |
| 1 nov – 15 dez 2026 | Demo e trailer |
| 1–31 dez 2026 | Teste com jogadores de fora (demo web no itch.io, se aprovado) |
| 10 jan 2027 | Inscrição no Next Fest (prazo) |
| 25 jan 2027 | Demo e página enviadas para revisão (prazo para o Press Preview) |
| 8 fev 2027 | Todos os itens obrigatórios enviados (prazo) |
| **22 fev – 1 mar 2027** | **Next Fest** |
| 22 mar – 30 abr 2027 | Lançamento |

Cada jogo só participa de um Next Fest na vida, e precisa de página "Em breve" pública e demo jogável. Alternativa com mais tempo de página no ar: Next Fest de 14 a 21 de junho de 2027, inscrição até 25/abr.

## Página da loja e IA

A página "Em breve" deve ir ao ar o quanto antes: cada semana no ar acumula wishlists.

- **Screenshots e trailer só do jogo real a 640x360**, nunca dos concept arts (têm cara de pixel art de IA).
- Trailer de 30–60 s, só gameplay, começando pelo loop e não pela intro.
- Cápsula principal: se houver orçamento, encomendar de um artista. É onde arte de IA mais pesa.
- Questionário de conteúdo de IA: declarar arte (Pixellab) e voz (ElevenLabs) como geradas antes do lançamento, não em tempo real.
- Steamworks: taxa de US$ 100 por jogo; dados fiscais e bancários podem levar dias para verificar.

## Localização e narração

Idiomas planejados além de en e pt_BR: russo, chinês, japonês, alemão, espanhol, francês e italiano.

| Idioma | Código Godot | Fonte m5x7 cobre? |
| --- | --- | --- |
| Russo | `ru` | Não (cirílico) |
| Chinês simplificado | `zh_CN` | Não (CJK) |
| Japonês | `ja` | Não (CJK) |
| Alemão | `de` | Verificar ä ö ü ß |
| Espanhol | `es` | Verificar ñ ¿ ¡ |
| Francês | `fr` | Verificar œ ç e acentos |
| Italiano | `it` | Provavelmente sim |

- **Fontes:** russo, chinês e japonês precisam de fonte pixel com cirílico e CJK (candidatas a avaliar: Ark Pixel, Fusion Pixel, Cubic 11). Textos CJK ficam mais largos; revisar legendas de 2 linhas e painéis.
- **Tradução:** Claude pode fazer o primeiro rascunho no `translations.csv`, mas página da loja e intro devem ser revisadas por falantes nativos.
- **Narração:** a regra atual continua válida (idioma sem gravação própria usa a voz em inglês com legenda no idioma). Dublar os 7 idiomas é opcional.
- **Gerar via API ElevenLabs:** dá para automatizar com um script `tools/audio/elevenlabs.py`, rodando pelo shell do dispositivo (como o Pixellab), com a chave no `.env`. A saída entra direto no pipeline `voice.py`. Custo: 9 falas por idioma.
- **Vozes:** o modelo multilíngue permite usar Connery em outros idiomas, mas com sotaque. Melhor escolher uma voz nativa por idioma na biblioteca e anotar o voice ID aqui.
- **Revisão de áudio:** Claude não ouve áudio; consegue medir volume, mas pronúncia e entonação precisam de ouvinte nativo.
- **Steam:** marcar por idioma interface, legendas e áudio completo; só marcar áudio onde houver dublagem própria.

## Pendências e perguntas em aberto

- [ ] Decidir se vai publicar na Steam.
- [ ] Definir se o final exige a árvore inteira no máximo ou só alcançar o Coração.
- [ ] Desenhar o pós-jogo e as insígnias em `docs/game-design.md`.
- [ ] Liberar os caminhos exclusivos da árvore após o final (flag de jogo concluído) e avisar o jogador.
- [ ] Medir o tempo real com 3–5 jogadores de fora.
- [ ] Decidir se a demo sai antes no itch.io (versão web) e onde divulgar.
- [ ] Tela final da demo: tempo total de jogo + link para formulário de feedback.
- [ ] Escolher Next Fest de fevereiro ou junho de 2027.
- [ ] Avaliar fontes pixel com cirílico e CJK.
- [ ] Decidir quais idiomas terão narração própria e escolher as vozes.
- [ ] Orçamento para cápsula feita por artista.

## Fontes

- [Steam Next Fest: February 2027 (Steamworks)](https://partner.steamgames.com/doc/marketing/upcoming_events/nextfest/feb_2027)
- [Steam Next Fest (Steamworks)](https://partner.steamgames.com/doc/marketing/upcoming_events/nextfest)
- [Next Fest prep, datas de out/2026, fev e jun/2027 (Steam Page Analyzer)](https://www.steampageanalyzer.com/tools/next-fest-prep)
- [itch.io: Generative AI Disclosure tagging (fórum oficial)](https://itch.io/t/4309690/generative-ai-disclosure-tagging)
- [itch.io passa a exigir declaração de IA (GameSpot)](https://www.gamespot.com/articles/itch-io-now-requires-creators-to-disclose-ai-generated-content/1100-6527920/)
