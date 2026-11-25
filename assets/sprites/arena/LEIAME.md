# Arena (D-077, ART-02, pacote 11)

| Arquivo | Tamanho | Uso |
|---|---|---|
| `varrek_chao.png` | 640×384 | fundo inteiro da arena de Varrek, desenhado em (0, 0). Borda de casco de ~24 px = parede (`margem_parede` no `data/arena/arena.json`). Gerado do 11A por `ferramentas/arte/arena_chao.py` (só cores escuras de cenário). |
| `varrek_destrocos.png` | 5 quadros 56×32, origem embaixo no centro (28, 32) | obstáculos: 0 casco curvo · 1 motor · 2 placas · 3 contêiner · 4 antena. **Provisório:** tratado direto do 11B por `tratar_ia.py --separar --altura 26 --quadro 56x32`; a ART redesenha por código depois (D-047). Colisão: faixa de baixo, 40×14. |

Personagens e inimigos usam os sprites de lado que já existem (ART-02 §1), com sombra desenhada pelo jogo.
