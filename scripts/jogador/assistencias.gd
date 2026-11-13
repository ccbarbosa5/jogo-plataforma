class_name Assistencias
extends Resource
## Opções de acessibilidade de mira e tiro (GD-01, seção 3.1; D-017).
## São por jogador (cada um no co-op tem as suas) e não reduzem recompensas.
## O menu de opções entra na Fase 2; no protótipo, F2/F3 trocam os modos.

enum ModoMira { DESLIGADA, ASSISTIDA, TOTAL }

@export var modo_mira: ModoMira = ModoMira.DESLIGADA
@export var tiro_automatico: bool = false
## Alcance da mira automática em tiles (1 tela = 30 × 16,875 tiles).
@export var alcance: Vector2 = Vector2(30.0, 16.875)
## O alvo só troca se outro inimigo estiver a menos desta fração da distância atual (0,6 = 40% mais perto).
@export var fator_troca_alvo: float = 0.6
