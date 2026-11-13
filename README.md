# No Rest

Shooter de plataforma 2D no estilo **Metal Slug**, com estrutura roguelike inspirada em **Hades**.

Uma guerra espacial entre várias raças alienígenas, e você é um humano tentando sobreviver no meio dela.
O jogo é dividido em **atos**, e cada ato se passa em um **planeta** com várias fases. Cada missão começa com o protagonista caindo em uma **cápsula de pouso**. Quando ele morre, a **nave-base** o teleporta de volta para tentar de novo. Durante a run, as **raças** oferecem armas e upgrades, como os deuses do Hades.

## Como rodar
1. Instale o [Godot 4](https://godotengine.org/download) (versão padrão, não precisa da .NET).
2. No Godot, clique em **Importar**, selecione o arquivo `project.godot` desta pasta e abra o projeto.
3. Aperte **F5** para jogar (abre a sala de teste da Fase 1).

## Controles (protótipo)
| Ação | Teclado | Gamepad |
|---|---|---|
| Mover / mirar | A D (W cima, S agachar/baixo) ou setas | Analógico esquerdo ou D-pad |
| Pular (baixo + pular desce da plataforma) | Espaço | A |
| Atirar | J | X |
| Dash | Shift ou L | B |
| Travar mira | Segurar I | RB |
| Grilhão (Ferramenta do Ryker) | O | LB |
| Mira automática (desligada / assistida / total) | F2 | — |
| Tiro automático | F3 | — |
| Reiniciar a sala | R | Back |

Os atalhos F2/F3 são provisórios até existir o menu de opções.

## Estrutura
| Pasta | Conteúdo |
|---|---|
| `scenes/` | Cenas do Godot (`.tscn`) e dados de balanceamento (`.tres`) |
| `scripts/` | Código GDScript (`.gd`), com as mesmas subpastas de `scenes/` |
| `tests/` | Testes automáticos (rodam em todo PR) |
| `assets/sprites/` | Arte |
| `assets/audio/` | Música e efeitos sonoros |
| `assets/fonts/` | Fontes |
| `docs/` | Documentos técnicos e de design que precisam acompanhar o código |

## Configuração técnica
- Engine: Godot 4, renderizador *Compatibility* (roda em PCs mais fracos e permite exportar para web/itch.io)
- Resolução interna: 480×270 (pixel art), escalada em números inteiros até 1080p/4K
- Filtro de textura: *Nearest*, para o pixel art ficar nítido

## Organização do estúdio
O desenvolvimento é dividido em departamentos (Game Design, Narrativa, Arte, Áudio, Programação, Testes e Marketing). A visão e as decisões oficiais ficam no documento `00-DIRETORIA/CENTRAL.md` do projeto no Claude. O fluxo de trabalho no repositório está descrito em `CLAUDE.md`.
