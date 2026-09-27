# Publicação (M7)

Guia para gerar os builds do Deepglow e publicar na Steam. O que já está pronto no repositório
está marcado com ✅; o resto depende de contas, pagamentos ou decisões do dono do projeto.

## 1. Builds

- ✅ `export_presets.cfg` (versionado) com três presets: **Windows** (`build/windows/Deepglow.exe`),
  **macOS** (`build/macos/Deepglow.zip`, universal Intel + Apple Silicon) e **Linux**
  (`build/linux/Deepglow.x86_64`). O `.pck` vai embutido no executável. `tests/`, `tools/` e `docs/`
  ficam fora do build.
- ✅ Script: `tools/build/export_all.sh` (todos) ou `tools/build/export_all.sh Linux` (um só).
  ```bash
  GODOT=/Applications/Godot.app/Contents/MacOS/Godot tools/build/export_all.sh
  ```
  A pasta `build/` é ignorada pelo git.
- Pré-requisito (uma vez por versão do Godot): **Editor → Manage Export Templates → Download and
  Install** (templates da 4.7.2, ~1,2 GB).
- ✅ Versão do jogo: `application/config/version` no `project.godot` (hoje `0.7.0`), mostrada no
  canto da tela de título. Suba a versão a cada build enviado para a Steam.
- Testado no ambiente do Claude: os três exports geram sem erros e o build Linux abre o jogo.

### Avisos esperados ao abrir os builds

- **Windows:** sem assinatura de código, o SmartScreen mostra "O Windows protegeu o computador"
  ao abrir o `.exe` baixado fora da Steam (Mais informações → Executar assim mesmo). Opcional:
  certificado de assinatura de código.
- **macOS:** o preset assina *ad hoc* (sem identidade). Fora da Steam, o Gatekeeper bloqueia o app
  baixado da internet (botão direito → Abrir). Para distribuir sem esse aviso é preciso
  assinatura com **Developer ID** + **notarização** (seção 4).

## 2. Controles (Steam Deck / controle)

- ✅ Tabuleiro: setas, WASD, direcional ou analógico esquerdo movem o cursor de célula em célula
  (ações `board_*`, só durante a fase); **A** / Espaço coleta; **B** / Esc cancela.
- ✅ Menus: navegação por foco (`ui_*`) em todas as telas; na tela de evoluções, a primeira direção
  pressionada foca o primeiro nó (a tela continua abrindo sem nada selecionado).
- Resolução do Deck (1280x800): o jogo fica em 2x (1280x720) com faixas pretas de 40 px em cima e
  embaixo — esperado para pixel art com escala inteira.
- Checklist para testar no Deck: jogar uma fase inteira só com o controle; comprar uma evolução;
  abrir Configurações e mudar volume; salvar e continuar; texto legível na tela de 7".

## 3. Steam

### 3.1 Conta e app

1. Criar conta no **Steamworks** e pagar a taxa do Steam Direct (US$ 100 por jogo, recuperável
   após US$ 1.000 em vendas), preencher dados fiscais e bancários.
2. Criar o app e anotar o **App ID**.
3. Colocar o App ID em **Project Settings → deepglow → steam/app_id** (hoje `0`).
   Para testar fora da Steam, crie um `steam_appid.txt` com o número ao lado do executável (esse
   arquivo é ignorado pelo git e nunca vai para o build da loja).

### 3.2 Integração (GodotSteam)

- ✅ Autoload `Platform` (`src/autoload/platform.gd`): se o singleton `Steam` existir, inicializa
  a Steam, roda os callbacks e envia conquistas; sem a extensão, **tudo vira no-op** — o mesmo
  build roda na itch.io, no editor e nos testes.
- Para ativar: instalar a extensão **GodotSteam (GDExtension)** pela Asset Library/Asset Store
  do Godot, na versão compatível com o Godot 4.7.2, e reexportar. Conferir nos logs:
  sem o aviso "Steam is not available".
- As chamadas usadas são `steamInitEx`, `run_callbacks`, `setAchievement` e `storeStats`; se uma
  versão futura do GodotSteam mudar esses nomes, ajustar só o `platform.gd`.

### 3.3 Conquistas

- ✅ Definidas em `data/achievements/*.tres` (tipo `Achievement`, listadas no `GameDatabase`) e
  avaliadas ao entrar na tela de evoluções e após cada compra.
- Cadastrar no Steamworks com **exatamente** estes API names:

| API name | Regra | Nome (en) | Nome (pt-BR) | Descrição (en) | Descrição (pt-BR) |
|---|---|---|---|---|---|
| `ACH_FIRST_NIGHT` | 1 fase jogada | First Night | Primeira Noite | Finish your first phase. | Termine sua primeira fase. |
| `ACH_NIGHT_OWL` | 25 fases | Night Owl | Coruja Noturna | Play 25 phases. | Jogue 25 fases. |
| `ACH_ENDLESS_NIGHT` | 100 fases | Endless Night | Noite Sem Fim | Play 100 phases. | Jogue 100 fases. |
| `ACH_FIRST_UPGRADE` | 1 nível comprado | First Step | Primeiro Passo | Buy your first upgrade. | Compre sua primeira evolução. |
| `ACH_STONECUTTER` | `unlock_pickaxe` | Stonecutter | Cortador de Pedra | Unlock the pickaxe. | Desbloqueie a picareta. |
| `ACH_ANGLER` | `unlock_fishing_rod` | Angler | Pescador | Unlock the fishing rod. | Desbloqueie a vara de pesca. |
| `ACH_HUNTER` | `unlock_spear` | Hunter | Caçador | Unlock the spear. | Desbloqueie a lança. |
| `ACH_MINER` | `unlock_ore_pick` | Miner | Minerador | Unlock the ore pick. | Desbloqueie a picareta de minério. |
| `ACH_CRYSTAL_SEEKER` | `unlock_crystal_pick` | Crystal Seeker | Buscador de Cristais | Unlock the crystal pick. | Desbloqueie a picareta de cristal. |
| `ACH_HEART_OF_DEEPGLOW` | nó final | Heart of Deepglow | Coração de Deepglow | Complete the upgrade tree. | Complete a árvore de evolução. |

- Ícones: 256x256 (versão desbloqueada e bloqueada/cinza) para cada conquista — pendente (arte).

### 3.4 Steam Cloud

Usar **Auto-Cloud** (sem código). O save fica em `user://save.json`, pasta própria `Deepglow`:

| Sistema | Root | Subpasta | Padrão |
|---|---|---|---|
| Windows | `WinAppDataRoaming` | `Deepglow` | `save.json` |
| macOS | `MacAppSupport` | `Deepglow` | `save.json` |
| Linux / Steam Deck | `LinuxXdgDataHome` | `Deepglow` | `save.json` |

Sincronizar só o `save.json` (as configurações de vídeo/áudio do `settings.cfg` são por máquina).
Conferir os nomes dos roots na documentação da Steam Cloud ao configurar.

### 3.5 Envio (SteamPipe)

- Um **depot por sistema** (Windows, macOS, Linux) com o conteúdo de `build/<sistema>/`
  (no macOS, o `.app` descompactado do `.zip`).
- Enviar com o `steamcmd` usando um `app_build_<appid>.vdf` (modelo no SDK da Steam, pasta
  `tools/ContentBuilder`). Primeiro envio numa branch de teste (`beta`), depois promover para
  `default` no Steamworks.
- Launch options: Windows `Deepglow.exe`, macOS `Deepglow.app`, Linux `Deepglow.x86_64`.

## 4. macOS: assinatura e notarização

1. Entrar no **Apple Developer Program** (anual, pago).
2. Criar o certificado **Developer ID Application** e uma chave de API do App Store Connect.
3. No preset macOS: `codesign/codesign` = built-in (rcodesign) ou Xcode, `codesign/identity` com o
   certificado, e `notarization/notarization` com a chave. As credenciais ficam em
   `.godot/export_credentials.cfg` (fora do git), nunca no `export_presets.cfg`.
4. Reexportar; o Godot assina, envia para notarização e grampeia o ticket.

A Valve recomenda enviar builds de macOS assinados e notarizados.

## 5. Página da loja (checklist)

- **Imagens (capsules):** header 920x430, small 462x174, main 1232x706, vertical 748x896,
  library capsule 600x900, library hero 3840x1240, logo 1280x720 (fundo transparente).
  Pendente: arte das capsules e ícone do app definitivo (hoje `icon.svg`, 16x16).
- **Capturas:** pelo menos 5, 1920x1080 (o jogo em 3x = 1920x1080 exato).
- **Trailer:** opcional, recomendado (30–60 s).
- **Divulgação de IA:** a Steam pede declarar conteúdo gerado por IA — neste projeto: sprites das
  fontes feitos com o Pixellab (depois ajustados à paleta) e código/áudio feitos com ajuda de IA.
- **Tags sugeridas:** Incremental, Clicker, Pixel Graphics, Casual, Relaxing, Singleplayer.

### Rascunho de textos

**Descrição curta (en):** Harvest a bioluminescent night forest in short timed phases, spend what
you gather on a hand-drawn upgrade tree, and unlock new tools until you reach the Heart of
Deepglow.

**Descrição curta (pt-BR):** Colete recursos numa floresta noturna bioluminescente em fases curtas
e cronometradas, invista tudo numa árvore de evolução desenhada à mão e desbloqueie novas
ferramentas até alcançar o Coração de Deepglow.

## 6. Pendências do dono do projeto

- [ ] Conta Steamworks, taxa, App ID (→ `deepglow/steam/app_id`).
- [ ] Instalar o GodotSteam e testar conquistas numa branch `beta`.
- [ ] Configurar Auto-Cloud (tabela 3.4) e as conquistas (tabela 3.3).
- [ ] Apple Developer + notarização (se for lançar no macOS).
- [ ] Arte: ícone do app, capsules, ícones das conquistas, capturas e trailer.
- [ ] Testar num Steam Deck (checklist da seção 2).
