class_name EntradaJogador
extends RefCounted
## Comandos de UM jogador em um frame.
## O Jogador nunca lê o Input direto: lê daqui. Isso permite trocar a fonte
## (teclado/gamepad, segundo jogador no co-op, testes automáticos, replays).
## A classe base não lê nada; os testes preenchem os campos à mão.

## x: -1 esquerda, 1 direita. y: -1 cima, 1 baixo.
var direcao: Vector2i = Vector2i.ZERO
var pular_segurado: bool = false
var pular_pressionado: bool = false
var atirar_segurado: bool = false
var atirar_pressionado: bool = false
var dash_pressionado: bool = false
var travar_mira_segurado: bool = false
var granada_pressionada: bool = false
var chamado_pressionado: bool = false
## Habilidade própria do personagem (Ryker: Grilhão).
var ferramenta_pressionada: bool = false
var interagir_pressionado: bool = false
## Mira livre em 360° (D-052). O Jogador usa, nesta ordem:
##  1. mira_analogica (analógico direito), se não for zero;
##  2. ponto_mira (posição do mouse no mundo), se mira_por_ponto;
##  3. as 8 direções de `direcao` (teclado sem mouse, testes antigos).
var mira_analogica: Vector2 = Vector2.ZERO
var mira_por_ponto: bool = false
var ponto_mira: Vector2 = Vector2.ZERO


## Chamado pelo Jogador no começo de cada frame de física.
func atualizar() -> void:
	pass


## Chamado pelo Jogador no fim de cada frame: "pressionado" vale só por um frame.
func fim_do_frame() -> void:
	pular_pressionado = false
	atirar_pressionado = false
	dash_pressionado = false
	granada_pressionada = false
	chamado_pressionado = false
	ferramenta_pressionada = false
	interagir_pressionado = false
