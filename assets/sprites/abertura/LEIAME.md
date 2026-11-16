# Abertura da história (D-073B) — quadros v0.2 (ART-5): IA nos quadros 1, 4, 8 e 9 e nas naves

Gerado por `ferramentas/arte/abertura_v01.py`, seguindo o roteiro **NAR-07**. Resolução 480×270, **Nearest**. Todos os PNG estão nesta pasta. Montagem de conferência: `assets/sprites/conceito/mockup_v13_abertura.png`.
**v0.2: chegaram as imagens do pacote 10 (IA)**, tratadas por `ferramentas/arte/abertura_ia_v01.py` (originais em `ferramentas/arte/originais_ia/10*`). **Use as versões `_ia` sempre que existirem:**

| Arquivo da IA | Substitui | Tamanho | Observação |
|---|---|---|---|
| `q1_fundo_ia.png` | `q1_fundo` **e** as duas camadas `q1_multidao_*` (a plateia já está desenhada) | 480×540 | o holofote vem do alto à direita; círculo de luz com o centro em (244, 455). Ryker com os pés em (238, 456); Ur-Kesh (`q1_urkesh_caido`, virado para a esquerda) com a base em (310, 456). Paralaxe: a câmera desce; as brasas por cima dão a profundidade. |
| `q4_fundo_ia.png` + `q4_redemoinho_ia.png` | `q4_fundo`, `q4_anel` e `q4_luz` | 480×270 + 190×190 | anel centrado em (240, 135). O redemoinho é um recorte circular da luz: ponha por cima do fundo, centrado em (240, 135), e **gire devagar** (~20°/s) para a luz parecer instável. |
| `q8_fundo_ia.png` | `q8_fundo` e `q8_nave_eco` | **720×360** | pan da janela 480×270 de (0, 0) até (240, 90): revela a nave e desce um pouco até Varrek. O feixe âmbar volta para dentro da nave perto de (360, 180). |
| `q9_fundo_ia.png` | `q9_fundo` | 480×270 | maca no centro; a silhueta (`q9_silhueta`) com o canto em (196, 62), sobre a maca. |
| `nave_ryker_ia.png` | `nave_ryker` | 3 quadros **52×24** | quadro 0 inteira (já com a chama do motor), 1 e 2 rachando (quadro 5). `nave_ryker_chama` pode piscar por cima, atrás do motor. |
| `nave_kharn_ia.png` | `nave_kharn` | 154×57 | perfil para a direita. |

Os arquivos por código continuam na pasta como reserva.

| Quadro (NAR-07) | Duração | Camadas (de trás para a frente) | Câmera / animação |
|---|---|---|---|
| 1 Grande Arena | 6 s | `q1_fundo` (480×540) · `q1_multidao_fundo` · `q1_urkesh_caido` (96×80, pés em y = 524, x ≈ 298) · Ryker (`personagens/ryker/ryker_poses_chave.png`, quadro 0, pés em (220, 524)) · `q1_multidao_frente` | câmera desce de y = 0 a y = 270 (*ease out*). Paralaxe: multidão do fundo a 0,8×, da frente a 1,2×; as duas balançam ±1 px (seno, 2 s). Holofote: `modulate` pisca 1 vez. Brasas: `ui/titulo/brasa.png`. Legenda "GRANDE ARENA DO DOMÍNIO KHARN". |
| 2 O prêmio | 5 s | `q1_fundo` (parte de baixo, escurecida 50%) · `q2_guarda` (2 quadros 40×48, 6 qps; um entra por cada borda, o da direita com `flip_h`) · retrato do Ryker (`retratos/ryker`, neutro → deboche) | zoom lento no retrato (1,0 → 1,25×, Nearest) |
| 3 A fuga | 6 s | `q3_fundo` (0,2×) · `q3_tunel` (1×, repete a cada 480) · Ryker (poses-chave 1 correndo, 2 pulando, 6 lançando a corrente) e guardas · `q3_frente` (1,6×, repete) · no fim, `q3_hangar` + `nave_ryker` | travelling para a direita ~240 px/s. Faíscas da corrente: brasa. A porta fecha: corte para o quadro 4. |
| 4 O Portão | 6 s | `q4_fundo` · `q4_luz` (4 quadros 200×200, 8 qps, centro em (300, 135)) · `q4_anel` · `nave_kharn` (128×44) · `nave_ryker` quadro 0 + `nave_ryker_chama` (2 quadros 8×6, atrás do motor) | zoom out 1,6× → 1,0× centrado no anel. A nave Kharn para antes do anel; a do Ryker acelera para o centro e some. |
| 5 Dentro do Portão | 4 s | `q5_faixas` (960×270, rola para a esquerda cada vez mais rápido, repete) · `nave_ryker` ampliada ×3, quadros 0 → 1 → 2 (rachando) | tremor crescente + zoom in; termina num clarão branco (`ColorRect`), onde entra a fala AB_04 |
| 6 Varrek | 6 s | parallax de Varrek que já existe (`cenarios/varrek/varrek_parallax_0` a `3`) · `q6_destroco_fogo` (2 quadros 20×28, 8 qps, 3 pedaços caindo) · `q6_poeira` (4 quadros 64×32, 10 qps, no impacto) | câmera acompanha a queda de cima para baixo (paralaxe vertical). Legenda "VARREK". |
| 7 Silêncio | 5 s | mesmo fundo do 6 · `q7_fumaca` (2 quadros 16×64, 3 qps) · `q7_feixe_ambar` (2 quadros 64×270, 6 qps; entra de cima com `modulate.a` 0 → 1) · `particula_ambar` (3 quadros 3×3; sobem e somem) | câmera parada |
| 8 Nave Eco | 5 s | `q8_fundo` (960×270: estrelas + curva de Varrek) · `q8_nave_eco` (960×270) | pan de x = 0 a x = 480. O feixe âmbar volta para dentro da nave e as luzes âmbar pulsam 1 vez (`modulate`). |
| 9 Reconstrutor | 5 s | `q9_fundo` · `q9_silhueta` (6 quadros 96×96, 1,2 qps → a última fica; posição (196, 104)) | tela preta 0,5 s → aproxima 1,0 → 1,15× devagar. Ao chegar no quadro 5 da silhueta, entra o diálogo ABER_01. |

**Sem spoiler (D-045, D-073):** a silhueta do quadro 9 é genérica (só luz âmbar, sem detalhe); nada de inseto, colmeia ou figura no Portão. Não acrescentar detalhes a ela.
**Falas:** AB_01 a AB_06 (NAR-07), em modo narração, com o retrato do Ryker. As legendas de lugar usam a fonte do jogo, no canto de baixo à esquerda, por 2 s.

---

# v0.3 — Abertura v2 (D-075, roteiro NAR-07 v2, 12 quadros) · ART-8
Gerado por `ferramentas/arte/abertura_v2.py` (roda depois de `abertura_v01.py` e `abertura_ia_v01.py`). Conferência: `conceito/mockup_v14_abertura_v2.png` (os 12 quadros) e `conceito/mockup_v15_legenda_1080p.png` (legenda).
**Ryker sempre em destaque (D-075):** use `v2_ryker_poses_destaque.png` (as poses-chave com contorno claro de 1 px; quadros de **50×50**, mesma ordem: 0 parado, 1 correndo, 2 pulando, 6 lançando a corrente) em vez de `ryker_poses_chave.png`.

| Quadro v2 | Peças (de trás para a frente) | Câmera / animação |
|---|---|---|
| 1 Galáxia em guerra (NOVO) | `v2_q1_galaxia_fundo` (640×360) · `v2_q1_frotas` (linhas pontilhadas entre as raças) · `v2_q1_simbolos` (3 quadros 60×60: **Kharn, Vesh, Ilo**, centros em (150,110), (470,120), (320,265)) · `v2_q1_clarao` (4 quadros 9×9, 12 qps, batalhas surgindo em pontos aleatórios entre os símbolos) · `v2_q1_humano` (2 quadros 7×7, pisca a 2 qps; centro em (540, 290)) | janela 480×270 aproxima devagar (zoom 1,0 → 1,6) e termina centrada no pontinho humano. Os símbolos pulsam (`modulate`) quando a fala cita as raças. |
| 2 Arena | como a v0.2 (`q1_fundo_ia`, Ur-Kesh, Ryker destacado) | descida mais lenta (todo o quadro) |
| 3 O prêmio | como a v0.2 | zoom lento |
| 4 A fuga | como a v0.2 (Ryker destacado) | travelling mais lento |
| 5 O Portão / 6 Dentro | como a v0.2 | — |
| 7 Varrek | como a v0.2 | para na poeira |
| 8 A luz e a nave (JUNTA 7+8) | `v2_q8_subida` (480×810: Varrek embaixo → céu → espaço) com `q7_feixe_ambar` repetido na vertical, x = 208 · depois `q8_fundo_ia` | a câmera sobe de y = 540 a y = 0 acompanhando o feixe (~3,5 s) e emenda (fade curto de 0,3 s) no pan da nave |
| 9 Reconstrutor | `q9_fundo_ia` · `v2_q9_ryker_formando` (8 quadros 64×64, 1,6 qps; canto em (210, 100); linhas de luz montando o corpo de dentro para fora; o último é o Ryker com brilho âmbar) · `q9_silhueta` quadro 5 com 70% de opacidade em (300, 60), **só observando** | aproxima devagar |
| 10 O trato (NOVO) | `v2_q10_rota` (960×270: Varrek aceso + 3 planetas desconhecidos com "?", ligados por pontilhado) · `v2_q10_nave_eco_mini` no alto · `v2_capsula` quadros 1–2 (8 qps) descendo em cada planeta, em sequência | pan de x = 0 a 480 |
| 11 Morrer = voltar (NOVO) | parallax de Varrek · Roedores e Chacal (sprites do ART-4, `flip_h`) cercando · Ryker destacado lutando → `v2_q11_ryker_vira_luz` (8 quadros 48×80, 10 qps: cai, vira luz âmbar e sobe) → corte para `q9_fundo_ia` com `v2_q9_ryker_formando` (quadros 4–7) e o Ryker de pé (pose 0) | fixa → sobe com a luz → fixa no reconstrutor |
| 12 A cápsula (NOVO) | parallax de Varrek · `v2_capsula` quadros 1–2 caindo em chamas (×2), quadro 3 no chão · `q6_poeira` no impacto | acompanha a queda e treme no impacto |

**Legendas (D-056, D-075):** faixa `v2_legenda_faixa.png` (nine-patch 16×16, margem 4: fundo `#16111c` a 75% e filete laranja à esquerda), ×4 na tela, **64 px de altura em 1080p**, canto de baixo à esquerda com margem de 48 px. Texto em **Open Sans Bold 34 px**, maiúsculas, `#fff6ea`, sombra de 2 px `#16111c`; **o nome novo do quadro sai em laranja `#eba35c`** (KHARN, PORTÃO, VARREK, ECO). Largura = texto + 28 px de cada lado. Entra e sai com fade de 0,3 s; fica 3 s.

**Sem spoiler (D-045):** o símbolo dos Vesh no mapa é **roxo e verde-ácido, nunca âmbar** (o âmbar é da ECO; os dois não podem se ligar). A silhueta do reconstrutor só observa, sem rosto.
