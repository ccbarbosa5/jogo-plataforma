class_name LojaIlo
extends Area2D
## Loja do Mercador Ilo na run (GD-05 §2.2): por enquanto vende só o "Aprimoramento de Arma"
## (90 Créditos, no máximo 1 por loja). Encoste na banca e aperte Interagir para comprar.
## Os outros itens da loja (cura, upgrades, reroll) entram com o gerador de salas.

signal comprou(jogador: Jogador, item: StringName)

const ITEM_APRIMORAMENTO: StringName = &"aprimoramento_de_arma"

@export var preco_aprimoramento: int = 90
@export var limite_aprimoramento: int = 1

var vendidos: Dictionary = {}
var _cliente: Jogador
var _icone: Texture2D = FolhaSprite.carregar("res://assets/sprites/ui/arvore/ponto_aprimoramento.png")
var _aviso: String = ""
var _timer_aviso: float = 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = Camadas.JOGADOR
	if get_child_count() == 0:
		var forma := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(40, 32)
		forma.shape = r
		forma.position = Vector2(0, -16)
		add_child(forma)
	body_entered.connect(_ao_entrar)
	body_exited.connect(_ao_sair)


func restantes(item: StringName = ITEM_APRIMORAMENTO) -> int:
	return limite_aprimoramento - int(vendidos.get(item, 0))


func pode_comprar(jogador: Jogador, item: StringName = ITEM_APRIMORAMENTO) -> bool:
	return restantes(item) > 0 and jogador.creditos >= preco_aprimoramento


## Compra o Aprimoramento: desconta os Créditos e dá +1 ponto (a tela da árvore abre).
func comprar(jogador: Jogador, item: StringName = ITEM_APRIMORAMENTO) -> bool:
	if restantes(item) <= 0:
		_avisar("Esgotado.")
		return false
	if jogador.creditos < preco_aprimoramento:
		_avisar("Créditos insuficientes.")
		Dialogos.tocar("loja_sem_creditos")
		return false
	jogador.creditos -= preco_aprimoramento
	vendidos[item] = int(vendidos.get(item, 0)) + 1
	Dialogos.tocar("loja_compra_upgrade")
	jogador.ganhar_aprimoramento(1)
	comprou.emit(jogador, item)
	return true


func _ao_entrar(corpo: Node2D) -> void:
	var jogador := corpo as Jogador
	if jogador == null:
		return
	_cliente = jogador
	if not jogador.interagiu.is_connected(_ao_interagir):
		jogador.interagiu.connect(_ao_interagir)


func _ao_sair(corpo: Node2D) -> void:
	if corpo == _cliente:
		if _cliente.interagiu.is_connected(_ao_interagir):
			_cliente.interagiu.disconnect(_ao_interagir)
		_cliente = null


func _ao_interagir(jogador: Jogador) -> void:
	comprar.call_deferred(jogador)


func _avisar(texto: String) -> void:
	_aviso = texto
	_timer_aviso = 1.5


func _process(delta: float) -> void:
	_timer_aviso = maxf(_timer_aviso - delta, 0.0)
	queue_redraw()


func _draw() -> void:
	# Banca provisória do Ilo (latão) com o item em cima.
	draw_rect(Rect2(-20, -16, 40, 16), Color("7a6a48"))
	draw_rect(Rect2(-20, -16, 40, 16), Color("d9b26a"), false, 1.0)
	var fonte: Font = Fontes.pequena()
	var tam: int = Fontes.TAMANHO_PEQUENA
	if restantes() > 0:
		if _icone != null:
			draw_texture(_icone, Vector2(-6, -30))
		var cor: Color = Color("eceff4") if _cliente == null or _cliente.creditos >= preco_aprimoramento else Color("ff8a6a")
		draw_string(fonte, Vector2(-40, -34), "Aprimoramento de Arma", HORIZONTAL_ALIGNMENT_CENTER, 80, tam, cor)
		draw_string(fonte, Vector2(-40, -6), "%d Créditos" % preco_aprimoramento, HORIZONTAL_ALIGNMENT_CENTER, 80, tam, Color("1a1c22"))
		if _cliente != null:
			draw_string(fonte, Vector2(-40, -44), "E: comprar", HORIZONTAL_ALIGNMENT_CENTER, 80, tam, Color("a7adba"))
	else:
		draw_string(fonte, Vector2(-40, -6), "Esgotado", HORIZONTAL_ALIGNMENT_CENTER, 80, tam, Color("1a1c22"))
	if _timer_aviso > 0.0:
		draw_string(fonte, Vector2(-50, -54), _aviso, HORIZONTAL_ALIGNMENT_CENTER, 100, tam, Color("ff8a6a"))
