class_name CaixaDialogo
extends CanvasLayer
## Mostra falas na tela (visual provisório até ART).
## - modo "conversa": pausa o jogo; avança com Interagir, Pular ou Atirar.
## - modo "rapida": aparece por cima sem pausar e some sozinha (falas curtas durante a run).

signal terminou(id_cena: String)

## Segundos por caractere no modo rápido (com um mínimo).
@export var segundos_por_caractere: float = 0.05
@export var minimo_rapida: float = 1.8

@onready var painel: Panel = $Painel
@onready var nome: Label = $Painel/Nome
@onready var texto: Label = $Painel/Texto
@onready var direcao: Label = $Painel/Direcao

var _id_cena: String = ""
var _falas: Array[Dictionary] = []
var _indice: int = 0
var _modo: String = "conversa"
var _banco: BancoDialogos
var _timer: float = 0.0
var _pausou: bool = false


func _ready() -> void:
	add_to_group("caixa_dialogo")
	process_mode = Node.PROCESS_MODE_ALWAYS
	painel.visible = false


func esta_ativa() -> bool:
	return painel.visible


func fala_atual() -> Dictionary:
	return _falas[_indice] if _indice < _falas.size() else {}


func mostrar(id_cena: String, falas: Array[Dictionary], modo: String, banco: BancoDialogos) -> void:
	if esta_ativa():
		_encerrar()
	_id_cena = id_cena
	_falas = falas
	_indice = 0
	_modo = modo
	_banco = banco
	if _modo == "conversa" and not get_tree().paused:
		get_tree().paused = true
		_pausou = true
	_posicionar()
	painel.visible = true
	_exibir()


## Conversa: caixa larga embaixo (o jogo está pausado).
## Rápida: faixa no topo, ao lado do HUD, para não cobrir o combate (pilar 1).
func _posicionar() -> void:
	var tela: Vector2 = get_viewport().get_visible_rect().size
	painel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	if _modo == "rapida":
		painel.position = Vector2(132.0, 4.0)
		painel.size = Vector2(tela.x - 136.0, 44.0)
	else:
		painel.position = Vector2(12.0, tela.y - 78.0)
		painel.size = Vector2(tela.x - 24.0, 60.0)
	texto.size.x = painel.size.x - 16.0
	direcao.size.x = painel.size.x - 16.0
	direcao.position.y = 46.0 if _modo == "conversa" else 32.0


func avancar() -> void:
	if not esta_ativa():
		return
	_indice += 1
	if _indice >= _falas.size():
		_encerrar()
	else:
		_exibir()


func _exibir() -> void:
	var fala: Dictionary = _falas[_indice]
	var falante: String = fala.get("falante", "")
	nome.text = _banco.nome_do_falante(falante) if not falante.is_empty() else ""
	nome.modulate = _banco.cor_do_falante(falante)
	texto.text = fala.get("texto", "")
	var dir: String = fala.get("direcao", "")
	direcao.text = "[%s]" % dir if not dir.is_empty() else ""
	_timer = maxf(minimo_rapida, texto.text.length() * segundos_por_caractere)


func _process(delta: float) -> void:
	if not esta_ativa():
		return
	if _modo == "rapida":
		_timer -= delta
		if _timer <= 0.0:
			avancar()
	elif Input.is_action_just_pressed("interagir") or Input.is_action_just_pressed("pular") \
			or Input.is_action_just_pressed("atirar"):
		avancar()


func _encerrar() -> void:
	painel.visible = false
	if _pausou:
		get_tree().paused = false
		_pausou = false
	var id: String = _id_cena
	_falas = []
	terminou.emit(id)
