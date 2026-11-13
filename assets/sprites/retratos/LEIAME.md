# Retratos de diálogo (D-032, D-044) — IA + tratamento (D-039)

Cada arquivo é uma folha com **4 quadros de 144×208**, um por expressão, **todos virados para a direita**. O personagem à direita da caixa usa `flip_h` (D-032). O corte de baixo (cintura) não tem contorno: ele fica atrás da borda da caixa de diálogo.

| Arquivo | Quadro 0 (padrão) | 1 | 2 | 3 |
|---|---|---|---|---|
| `ryker/ryker_retratos.png` | neutro | deboche | raiva | abalado |
| `eco/eco_retratos.png` | acolhedora | sorriso | preocupada | distante |

Os nomes das expressões são os da NAR-01, seção 0 (coluna "Expr." dos diálogos). Sugestão: um `SpriteFrames` por personagem, com uma animação por expressão.

**Animação sutil (próxima entrega da ART):** 2 quadros extras de piscar por expressão. Até lá, respiração pelo código (subir e descer 1 px a cada ~2 s). Na ECO, o cintilar e as partículas subindo também são do código, por cima do PNG.
