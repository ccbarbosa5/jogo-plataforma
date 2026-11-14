class_name VisualRyker
extends Node2D
## Visual do Ryker em duas partes (D-033), seguindo assets/sprites/personagens/ryker/LEIAME.md:
## - Pernas (32×32) trocam pelo movimento.
## - Tronco (48×48) troca pela direção da mira e pela arma; desce junto com o quadril.
## - Corpo inteiro (48×48) substitui os dois no dash e na morte.
## Tudo desenhado olhando para a direita; para a esquerda, flip_h.

const PASTA: String = "res://assets/sprites/personagens/ryker/"
## Deslocamento do tronco (px para baixo) em cada quadro das pernas (LEIAME).
const DESLOCAMENTO: Dictionary = {
	&"parado": [0],
	&"correr": [3, 1, 1, 2, 3, 1, 1, 2],
	&"pulo": [0, 0, 0, 0, 0, 2, 1],
	&"agachado": [10],
	&"agachado_andar": [10, 10, 10, 10, 10, 10],
}
## Direção da mira (com x ≥ 0) -> sufixo da folha de tronco.
const DIRECOES: Dictionary = {
	Vector2i(1, 0): "frente", Vector2i(1, -1): "diag_cima", Vector2i(0, -1): "cima",
	Vector2i(1, 1): "diag_baixo", Vector2i(0, 1): "baixo",
}
## Duração de cada quadro do disparo (LEIAME): Mordida 1/30 s, Bramido 1/20 s.
const TEMPO_QUADRO_TIRO: Dictionary = {&"mordida": 1.0 / 30.0, &"bramido": 1.0 / 20.0}
const TEMPO_POUSO: float = 0.14

var jogador: Jogador
var pernas: FolhaSprite
var tronco: FolhaSprite
var corpo: FolhaSprite

var _tempo_tiro: float = 0.0
var _quadro_tiro: int = 0
var _tempo_pouso: float = 0.0
var _estava_no_chao: bool = true
var _arma_visual: StringName = &""


func _ready() -> void:
	jogador = get_parent() as Jogador
	pernas = _criar_folha("Pernas")
	tronco = _criar_folha("Tronco")
	corpo = _criar_folha("Corpo")
	pernas.registrar(&"parado", FolhaSprite.carregar(PASTA + "ryker_pernas_parado.png"), 1)
	pernas.registrar(&"correr", FolhaSprite.carregar(PASTA + "ryker_pernas_correr.png"), 8, 12.0)
	pernas.registrar(&"pulo", FolhaSprite.carregar(PASTA + "ryker_pernas_pulo.png"), 7)
	pernas.registrar(&"agachado", FolhaSprite.carregar(PASTA + "ryker_pernas_agachado.png"), 1)
	pernas.registrar(&"agachado_andar", FolhaSprite.carregar(PASTA + "ryker_pernas_agachado_andar.png"), 6, 10.0)
	corpo.registrar(&"dash", FolhaSprite.carregar(PASTA + "ryker_dash.png"), 4, 20.0)
	corpo.registrar(&"morte", FolhaSprite.carregar(PASTA + "ryker_morte.png"), 8, 12.0, false)
	for arma: StringName in [&"mordida", &"bramido"]:
		var prefixo: String = "ryker_tronco_" if arma == &"mordida" else "ryker_tronco_bramido_"
		for direcao: Vector2i in DIRECOES:
			var sufixo: String = DIRECOES[direcao]
			tronco.registrar(StringName("%s_%s" % [arma, sufixo]), FolhaSprite.carregar(PASTA + prefixo + sufixo + ".png"), 4)
	corpo.visible = false
	if jogador != null:
		jogador.atirou.connect(func(_p: Projetil) -> void: disparou())


func _criar_folha(nome: String) -> FolhaSprite:
	var f := FolhaSprite.new()
	f.name = nome
	add_child(f)
	return f


## Chamado a cada disparo: quadro 1 (ou 3 no modo especial), depois 2, depois 0.
func disparou(especial: bool = false) -> void:
	_quadro_tiro = 3 if especial else 1
	_tempo_tiro = 0.0


func _process(delta: float) -> void:
	if jogador == null:
		return
	var esquerda: bool = jogador.olhando < 0
	var no_chao: bool = jogador.is_on_floor()
	if no_chao and not _estava_no_chao:
		_tempo_pouso = TEMPO_POUSO
	_estava_no_chao = no_chao
	_tempo_pouso = maxf(_tempo_pouso - delta, 0.0)
	# Corpo inteiro: morte e dash.
	if jogador.esta_morto() or jogador.esta_em_dash():
		corpo.visible = true
		pernas.visible = false
		tronco.visible = false
		corpo.flip_h = esquerda
		corpo.tocar(&"morte" if jogador.esta_morto() else &"dash")
		return
	corpo.visible = false
	pernas.visible = true
	tronco.visible = true
	_atualizar_pernas(no_chao, esquerda)
	_atualizar_tronco(delta, esquerda)


func _atualizar_pernas(no_chao: bool, esquerda: bool) -> void:
	pernas.flip_h = esquerda
	var andando: bool = absf(jogador.velocity.x) > 8.0
	if jogador.agachado:
		pernas.tocar(&"agachado_andar" if andando else &"agachado")
	elif not no_chao:
		pernas.tocar(&"pulo")
		var vy: float = jogador.velocity.y
		var q: int = 0 if vy < -120.0 else (1 if vy < -30.0 else (2 if vy < 60.0 else (3 if vy < 220.0 else 4)))
		pernas.definir_quadro(q)
	elif _tempo_pouso > 0.0:
		pernas.tocar(&"pulo")
		pernas.definir_quadro(5 if _tempo_pouso > TEMPO_POUSO * 0.5 else 6)
	elif andando:
		pernas.tocar(&"correr")
	else:
		pernas.tocar(&"parado")


func _atualizar_tronco(delta: float, esquerda: bool) -> void:
	var arma: StringName = &"mordida"
	if jogador.arma != null and jogador.arma.visual != &"":
		arma = jogador.arma.visual
	_arma_visual = arma
	var mira: Vector2i = jogador.mira
	var chave := Vector2i(absi(mira.x), mira.y)
	if not DIRECOES.has(chave):
		chave = Vector2i(1, 0)
	tronco.tocar(StringName("%s_%s" % [arma, DIRECOES[chave]]))
	tronco.flip_h = mira.x < 0 or (mira.x == 0 and esquerda)
	var lista: Array = DESLOCAMENTO.get(pernas.atual, [0])
	tronco.position.y = lista[mini(pernas.quadro_atual, lista.size() - 1)]
	# Sequência de tiro: 1 (ou 3) → 2 → 0.
	if _quadro_tiro > 0:
		tronco.definir_quadro(_quadro_tiro)
		_tempo_tiro += delta
		if _tempo_tiro >= TEMPO_QUADRO_TIRO.get(arma, 1.0 / 30.0):
			_tempo_tiro = 0.0
			_quadro_tiro = 2 if _quadro_tiro != 2 else 0
	else:
		tronco.definir_quadro(0)
