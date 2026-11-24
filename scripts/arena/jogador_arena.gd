class_name JogadorArena
extends Node2D
## O Ryker visto de cima (GD-09 §4): anda em 8 direções, tem dash e carrega até 6 armas que
## atiram sozinhas. Protótipo: desenhado com formas simples até a arte do ART-9.

signal vida_mudou(vida: int, vida_max: int)
signal morreu

const COR: Color = Color("e07a3a")
const COR_CONTORNO: Color = Color("fff6ea")

var vida_max: int
var vida: int
var velocidade: float
var raio: float
var ima: float
var invencivel_duracao: float
var dash_distancia: float
var dash_duracao: float
var dash_recarga: float
## Retângulo onde o Ryker pode andar (a arena define).
var limites: Rect2 = Rect2(0, 0, 640, 384)
var inventario: InventarioArmas
## Os testes desligam a entrada do teclado.
var ler_entrada: bool = true
## Direção pedida neste frame (a entrada ou os testes escrevem aqui).
var direcao: Vector2 = Vector2.ZERO
var morto: bool = false

var _invencivel: float = 0.0
var _dash_tempo: float = 0.0
var _dash_espera: float = 0.0
var _dash_direcao: Vector2 = Vector2.RIGHT
var _armas: Node2D


func _ready() -> void:
	var r: Dictionary = ConfigArena.secao("ryker")
	vida_max = int(r["vida_max"])
	vida = vida_max
	velocidade = float(r["velocidade"])
	raio = float(r["raio"])
	ima = float(r["ima"])
	invencivel_duracao = float(r["invencivel"])
	dash_distancia = float(r["dash_distancia"])
	dash_duracao = float(r["dash_duracao"])
	dash_recarga = float(r["dash_recarga"])
	inventario = InventarioArmas.new(int(r["slots"]))
	_armas = Node2D.new()
	_armas.name = "Armas"
	add_child(_armas)
	adicionar_arma(String(r["arma_inicial"]), 1)


func _physics_process(delta: float) -> void:
	if morto:
		return
	_invencivel = maxf(_invencivel - delta, 0.0)
	_dash_espera = maxf(_dash_espera - delta, 0.0)
	if ler_entrada:
		direcao = Input.get_vector("mover_esquerda", "mover_direita", "mirar_cima", "mirar_baixo")
		if Input.is_action_just_pressed("dash"):
			dar_dash()
	if direcao != Vector2.ZERO:
		_dash_direcao = direcao.normalized()
	var passo: Vector2 = direcao.limit_length(1.0) * velocidade * delta
	if _dash_tempo > 0.0:
		_dash_tempo -= delta
		passo = _dash_direcao * (dash_distancia / dash_duracao) * delta
	position = (position + passo).clamp(limites.position, limites.end)
	queue_redraw()


func dar_dash() -> bool:
	if _dash_espera > 0.0 or morto:
		return false
	_dash_tempo = dash_duracao
	_dash_espera = dash_recarga
	return true


func esta_em_dash() -> bool:
	return _dash_tempo > 0.0


func levar_dano(dano: int) -> bool:
	if morto or _invencivel > 0.0 or esta_em_dash():
		return false
	vida = maxi(vida - dano, 0)
	_invencivel = invencivel_duracao
	NumerosDano.mostrar(self, dano, NumerosDano.Tipo.JOGADOR)
	vida_mudou.emit(vida, vida_max)
	if vida == 0:
		morto = true
		morreu.emit()
	return true


## Põe uma arma no inventário (ou funde) e refaz os nós das armas.
func adicionar_arma(id: String, nivel: int) -> bool:
	if not inventario.adicionar(id, nivel):
		return false
	_refazer_armas()
	return true


func armas() -> Array[ArmaArena]:
	var lista: Array[ArmaArena] = []
	for a in _armas.get_children():
		lista.append(a as ArmaArena)
	return lista


func _refazer_armas() -> void:
	for a in _armas.get_children():
		_armas.remove_child(a)
		a.queue_free()
	var n: int = inventario.armas.size()
	for i in n:
		var item: Dictionary = inventario.armas[i]
		var arma := ArmaArena.new()
		arma.configurar(String(item["id"]), int(item["nivel"]))
		# Pontos de saída em volta do Ryker, espaçados por igual (GD-09 §5.1).
		arma.position = Vector2.RIGHT.rotated(TAU * i / n) * 14.0
		_armas.add_child(arma)


func _draw() -> void:
	var piscando: bool = _invencivel > 0.0 and int(_invencivel * 20.0) % 2 == 0
	if piscando:
		return
	draw_circle(Vector2.ZERO, raio + 1.0, COR_CONTORNO)
	draw_circle(Vector2.ZERO, raio, COR)
