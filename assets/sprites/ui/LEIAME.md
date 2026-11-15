# Interface — v0.3 (ART, por código, D-039)

Gerado por `ferramentas/arte/ui_v03.py`. Tela de conferência da árvore: `assets/sprites/conceito/mockup_v03_arvore.png`. **É uma referência de layout:** o texto ali usa uma fonte de bitmap provisória, sem acentos; a fonte final continua pendente (ART-01, §11).

## Molduras da caixa de diálogo (D-032) — `molduras/`
| Arquivo | Para quem |
|---|---|
| `moldura_humana.png` | Ryker e humanos: sucata remendada (chapas, rebites, remendos de canto) |
| `moldura_kharn.png` | Garrak, Tor-Ama, Ur-Kesh: ferro, osso e filete brasa, espinhos nos cantos |
| `moldura_vesh.png` | Sete, a Colmeia: quitina roxa com veios e bolhas de resina âmbar |
| `moldura_ilo.png` | Vossa Margem, Mercador: latão (tons de osso) e janelinhas de vidro |
| `moldura_eco.png` | ECO: anel teal da nave com um fio de luz âmbar |
| `seta_continuar.png` | 2 quadros (9×7), 4 qps: sobe e desce 1 px |

**Como usar no Godot:** `NinePatchRect` com a textura de 48×48, `patch_margin_*` = **12** nos quatro lados e `axis_stretch_horizontal/vertical = TILE`. As bordas têm padrão de período 8, então repetem sem emenda e sem esticar o pixel. A mesma moldura serve para a **placa de nome** (num retângulo menor) e para o **painel da árvore** (a humana: a árvore é gambiarra do Ryker).

## Árvore da arma (D-040, GD-05) — `arvore/`
| Arquivo | Conteúdo |
|---|---|
| `no.png` | Nó comum 20×20, 4 quadros: **0 trancado** (cadeado) · **1 disponível** (aro claro) · **2 comprado** (laranja) · **3 bloqueado** (rachado; não usado nos nós comuns) |
| `no_apice.png` | Ápice 24×24 (losango), mesmos 4 quadros. **Quadro 3 = Ápice trancado porque outro Ápice foi escolhido.** |
| `destaque.png` / `destaque_apice.png` | Contorno branco-ciano que pisca no 1º uso (GD-03 §1.2): 2 quadros, 4 qps, por cima do nó (2 px maior de cada lado) |
| `conector.png` | Liga um nó ao próximo do ramo, 4×10, 2 quadros: apagado / aceso (o de cima já comprado) |
| `custo.png` | Custo em rebites, 12×4, 3 quadros: 1, 2, 3 pontos |
| `ponto_aprimoramento.png` | 12×12: a porca de sucata = 1 Ponto de Aprimoramento (contador da tela e loja Ilo) |

Layout sugerido (ver o mockup): ícone da arma + nome + assinatura no topo; pontos disponíveis no canto direito; 3 ramos em colunas com o nome em cima; nós de cima para baixo (1 → 2 → Ápice), custo ao lado e nome embaixo; uma linha de ajuda embaixo. O jogo fica pausado e escurecido atrás.

## Portas — `portas/`
`porta_aprimoramento_de_arma.png` (24×24): ícone da recompensa "Aprimoramento de Arma" em cima da porta (GD-03): chave inglesa, cano e a porca.

## HUD (ART-01 §11, D-043) — `hud/`
| Arquivo | Uso |
|---|---|
| `elo_vida.png` | 11×8, 2 quadros: elo cheio / elo quebrado. 4 elos lado a lado, 2 px de espaço |
| `barra_embalo_fundo.png` / `_cheia.png` / `_completa.png` | **Embalo** (Mordida): barrinha laranja de 52×5 logo abaixo dos elos. Num `TextureProgressBar`: `texture_under` = fundo, `texture_progress` = cheia; troque o progress pela `_completa` (branco-ciano) quando o Embalo estiver no máximo |
| `barra_chamado_*.png` | Igual, em âmbar, para o Chamado |

## Tela de título (D-053) — `titulo/` · `ferramentas/arte/titulo_menus_v01.py`
| Arquivo | Conteúdo |
|---|---|
| `logo_no_rest_provisorio.png` | Logo **provisório** (224×53): chapa laranja batida, bloco 3D e a corrente partida embaixo. Mostrar **×2** na arte (×8 em 1080p). O definitivo vem do pacote de prompt 09 (ChatGPT). |
| `fundo_titulo_ceu.png` | 480×270, fixo: céu de Varrek, estrelas e o anel quebrado dos Antigos |
| `fundo_titulo_longe.png` | 960×270, mesas distantes; rolar devagar (≈4 px/s), repete sem emenda |
| `fundo_titulo_arena.png` | 960×270, a arena em ruínas com correntes penduradas; rolar mais rápido (≈10 px/s) |
| `brasa.png` | 3 quadros 3×3: partícula de brasa (`CPUParticles2D`, sobe devagar, 20–30 na tela) |

**Versão definitiva (pacote 09, IA):** `logo_no_rest.png` (259×66, variação 3 de 3; mostrar **×1** na arte = ×4 em 1080p, centralizado, topo em y ≈ 22) e `fundo_titulo_ia.png` (480×270, parado; centro escuro para os botões). Use estes no lugar do logo provisório e das 3 camadas; as **brasas** continuam por cima, e as camadas por código ficam como reserva. Layout: `conceito/mockup_v05_titulo.png`.

**Fundo animado simples:** `ParallaxBackground` com as 3 camadas (`motion_mirroring` = 960 nas duas que rolam) + brasas. Logo no alto, centralizado; botões no centro, embaixo dele; versão pequena no canto de baixo à esquerda. Ver `conceito/mockup_v05_titulo.png`.

## Menus (D-053, D-054) — `menus/`
| Arquivo | Conteúdo |
|---|---|
| `botao.png` | 4 quadros 16×16: **normal · foco · pressionado · desativado**. Nine-patch, margem **4**. Use como `StyleBoxTexture` dos estados do `Button` (normal, hover/focus, pressed, disabled). |
| `painel.png` | 32×32, margem **8**: painel do menu de pausa, de Controles e de Opções. |
| `seletor.png` | 2 quadros 6×9 (4 qps): seta ao lado do botão em foco. |

**Escala (D-056):** a arte é ampliada **×4** (Nearest) e o texto é nativo, com a Atkinson Hyperlegible (`assets/fonts/atkinson_hyperlegible/`). Cores do texto: `#fff6ea` normal, `#ffe0b8` em foco, `#7d7886` desativado. Telas: `mockup_v06_pausa.png` (pausa) e `mockup_v07_controles.png` (Controles: ação à esquerda, tecla num botão à direita, "Aperte uma tecla…" ao trocar).

## Placa de nome legível (D-057) — `menus/placa_<grupo>.png`
Nine-patch 16×16, margem **4**: fundo escuro e liso (`#16111c`), filete de 1 px na cor do grupo. Altura **19 px de arte (76 px em 1080p)**; largura = nome + 30 px de cada lado. Nome em **Atkinson Bold 46**, `#fff6ea` (ECO: `#ffe7b0`). Fica sobre o canto de cima da caixa, do lado de quem fala.

| Arquivo | Para quem | Filete |
|---|---|---|
| `placa_humano.png` | Ryker | laranja `#c4652e` |
| `placa_kharn.png` | Garrak, Tor-Ama, Ur-Kesh | brasa `#ff5a2e` |
| `placa_vesh.png` | Sete, a Colmeia | quitina clara `#7d4c90` |
| `placa_ilo.png` | Vossa Margem, Mercador | azul-pálido `#b8d4e0` |
| `placa_eco.png` | ECO | âmbar `#ffc95c` |

Conferência: `conceito/mockup_v08_dialogo_1080p.png` e `conceito/amostra_placas_1080p.png`. Substitui a placa com moldura e fonte ×2 da D-046.

## Árvores da D-058 (ART-3) — `arvore/` · `ferramentas/arte/ui_arvores_v01.py`
Substituem as peças da árvore de arma antiga (`no.png`, `no_apice.png`, `destaque*.png`, `conector.png`, `custo.png`, `ponto_aprimoramento.png`, que ficam sem uso).

| Arquivo | Conteúdo |
|---|---|
| `no_v2.png` | 5 quadros 16×16, nine-patch margem **4**: **bloqueado · disponível · comprado · Ápice disponível · Ápice comprado**. Use como `StyleBoxTexture` do botão do nó. |
| `no_foco.png` | 16×16, margem 4, centro vazio: contorno de foco por cima de qualquer estado. |
| `conector_v2.png` | 2 quadros 4×4 (apagado, aceso): ligação vertical entre nós; repete na vertical. Aceso quando o nó de cima foi comprado. |
| `ramos.png` | 8 ícones 12×12, nesta ordem: **mordida, bramido, granada, grilhão, dash, corpo, movimento, fortuna** (cabeçalho de cada ramo). |
| `icone_ponto.png` | 7×7: ponto da árvore de Combate (custo do nó = quantos losangos). |
| `icone_nucleo.png` | 7×9: Núcleo (preço na árvore Passiva e saldo no topo). |
| `pip_nivel.png` | 2 quadros 5×5 (vazio, cheio): níveis de um nó da Passiva. |

**Árvore de Combate** (`conceito/mockup_v09_arvore_combate.png`): moldura humana na tela toda; título; linha com nível, pontos livres e Ápices (x de 2); 5 colunas de 84 px (iguais às do `tela_arvore_combate.gd`), nós de 84×22 com o nome em cima e o custo em losangos embaixo; ramo da arma não levada todo apagado, com "arma não levada"; painel de baixo com o nó em foco (nome + efeito) e as teclas.
Cores do texto: claro `#fff6ea`; apagado `#7d7886`; dica `#a7a1ae`; nome no Ápice comprado em escuro `#16111c` (fundo brasa).

**Árvore Passiva** (`conceito/mockup_v10_arvore_passiva.png`): 3 colunas (Corpo, Movimento, Fortuna) de 140 px, nós de 140×34 com nome, efeito, níveis em `pip_nivel` e o preço do próximo nível em Núcleos (ou "completo").

## Gambiarras (ART-3) — `gambiarras/`
| Arquivo | Conteúdo |
|---|---|
| `carta.png` | 3 quadros 32×32, nine-patch margem **10**: **Comum** (metal), **Rara** (azul), **Épica** (laranja, brasa nos cantos). A faixa de cima (6 px) leva a gema e o nome da raridade. |
| `carta_foco.png` | 32×32, margem 10: contorno de foco (a carta em foco também sobe 4 px). |
| `raridade.png` | 3 quadros 12×12: **1, 2 e 3 losangos** para C, R e É (lê sem depender da cor). |

Layout (`conceito/mockup_v11_gambiarras.png`, com as medidas do `tela_gambiarras.gd`: cartas de 132×124, espaço de 12, y = 70): gema + "COMUM / RARA / ÉPICA" na faixa; ícone da arma ×2; nome (32 px em 1080p); efeito (26 px, até 3 linhas); embaixo "1 de 3" (acumulável), "novo" ou "única". Botão "Recalibrar (n)" embaixo das cartas. Cores do nome da raridade: `#c9c3cf`, `#9fd0ff`, `#f2a65a`.
