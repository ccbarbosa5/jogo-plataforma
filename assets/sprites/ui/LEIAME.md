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
