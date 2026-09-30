# Trailer (ferramenta de captura e edição)

Grava gameplay real com o Movie Maker do Godot e monta os trailers com ffmpeg.
Nada disso entra no jogo: `src/dev/` fica fora das exportações de lançamento.

## 1. Capturar

`src/dev/trailer_director.gd` joga sozinho: carrega um save de teste (`src/dev/saves/NN_*.json`),
move o cursor e clica nas fontes, passa pelo resumo e compra melhorias na árvore.
A música do jogo fica muda na captura (entra depois, na edição); os toasts de conquista ficam ocultos.

```bash
export GODOT=/Applications/Godot.app/Contents/MacOS/Godot
for s in 01 02 03 04 05 06; do tools/trailer/capture.sh b$s $s 42 buys=2 cps=8; done
tools/trailer/capture.sh tree 06 14 tree_scroll=8 buys=1
```

Saída: `build/trailer_capture/*.mp4` (git-ignored). **Atenção:** o diretor escreve o save de
teste por cima do slot `user://save.json` — faça backup se tiver uma partida real.

## 2. Montar

Requer Python 3 + Pillow e ffmpeg.

```bash
cd tools/trailer
python3 overlays.py "Wishlist now on Steam" endcard.png   # textos + cartão final (45 s)
python3 overlays.py "Coming soon" endcard_soon.png        # cartão final sem plataforma (30 s)
CAPTURE_DIR=../../build/trailer_capture python3 build.py 45
CAPTURE_DIR=../../build/trailer_capture python3 build.py 30
```

- `build.py 45` → `deepglow_trailer_steam_1080p.mp4` (cita a Steam no fim).
- `build.py 30` → `deepglow_trailer_30s_1080p.mp4` (sem plataforma; 16 compassos = um loop da música).
- Cortes em compassos de `camp_fast.ogg` (128 BPM); a camada `camp_fast_rush.ogg` entra no clímax.
- Os pontos de entrada de cada corte (lista `segs`) dependem das gravações: se regravar,
  confira os tempos com uma folha de contato (`ffmpeg -i x.mp4 -vf fps=1/3,scale=384:216,tile=5x3 ...`).
- Saída: H.264 1080p30, ~5 Mbps, AAC 48 kHz.
