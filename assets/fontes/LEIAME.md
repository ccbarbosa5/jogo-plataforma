# Fonte do No Rest (D-046) — própria do estúdio, feita por código

Pixel 5×7 com **todos os acentos do português** (á à â ã é ê í ó ô õ ú ç e as maiúsculas), ª º, — – …, aspas curvas, « », e o ASCII inteiro: 156 caracteres. Feita pela ART em `ferramentas/arte/fonte_v01.py`. **Sem licença de terceiros.**

| Arquivo | Uso | Tamanho |
|---|---|---|
| `no_rest_5.fnt` + `.png` | texto da caixa de diálogo, falas rápidas, árvore, HUD | célula de 11 px, linha de 12 px, base em 9 |
| `no_rest_5_x2.fnt` + `.png` | **placa do nome** (D-046) e títulos | a mesma, com pixels dobrados (22 / 24) |

**No Godot 4:** o `.fnt` (BMFont texto) é importado automaticamente como `FontFile`. Use o `font_size` igual ao da fonte (**11** e **22**) para não reescalar, e deixe o filtro de textura em *Nearest* (já é o padrão do projeto). Os glifos são **brancos**: a cor vem de `font_color`.

**Verificação:** `python3 ferramentas/arte/fonte_v01.py --verificar` confere se a fonte cobre os acentos obrigatórios e **todo o texto de `data/dialogos/*.json`**. Hoje: OK. O teste automático da D-046 (pedido ao DEV) pode fazer a mesma conta em GDScript: para cada caractere das falas, `fonte.has_char(codigo)`.
