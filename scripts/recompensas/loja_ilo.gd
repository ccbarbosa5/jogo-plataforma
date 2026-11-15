class_name LojaIlo
extends Interagivel
## Uma banca da loja do Mercador Ilo na run (GD-02 §6.5). Cada banca vende um item; a sala de
## loja põe três lado a lado (cura, dádiva Kharn, dádiva Vesh). Chegue perto e aperte E (ou clique);
## encostar não compra (D-066).
## GD-07: o "Aprimoramento de Arma" saiu da loja (as Gambiarras vêm ao limpar as salas).

signal comprou(jogador: Jogador, item: StringName)

## item -> [nome, preço, limite por loja]
const ITENS: Dictionary = {
	&"cura": ["Cura (1 bloco)", 40, 2],
	&"dadiva_kharn": ["Dádiva Kharn", 80, 1],
	&"dadiva_vesh": ["Dádiva Vesh", 80, 1],
}

@export var item: StringName = &"cura"

## O que cada item faz (aparece perto da banca, D-066).
const EFEITOS: Dictionary = {
	&"cura": "Cura 1 bloco de vida",
	&"dadiva_kharn": "Escolha 1 de 3 dádivas Kharn",
	&"dadiva_vesh": "Escolha 1 de 3 dádivas Vesh",
}

var vendidos: int = 0
var _aviso: String = ""
var _timer_aviso: float = 0.0


func nome_item() -> String:
	return ITENS[item][0]


func preco() -> int:
	return ITENS[item][1]


func restantes() -> int:
	return int(ITENS[item][2]) - vendidos


func pode_comprar(jogador: Jogador) -> bool:
	return restantes() > 0 and jogador.creditos >= preco()


## Desconta os Créditos e entrega o item. A dádiva abre a tela de oferta da facção.
func comprar(jogador: Jogador) -> bool:
	if restantes() <= 0:
		_avisar("Esgotado.")
		return false
	if jogador.creditos < preco():
		_avisar("Créditos insuficientes.")
		Dialogos.tocar("loja_sem_creditos")
		return false
	if item == &"cura" and jogador.vida.atual >= jogador.vida.maxima:
		_avisar("Vida cheia.")
		return false
	jogador.creditos -= preco()
	vendidos += 1
	match item:
		&"cura":
			jogador.vida.curar(1)
		&"dadiva_kharn", &"dadiva_vesh":
			Dialogos.tocar("loja_compra_upgrade")
			var run := get_tree().get_first_node_in_group(&"run_ato")
			if run != null and run.has_method("abrir_dadiva"):
				run.abrir_dadiva(jogador, "kharn" if item == &"dadiva_kharn" else "vesh")
	comprou.emit(jogador, item)
	return true


func _ready() -> void:
	tamanho_area = Vector2(40, 32)
	super()


func titulo() -> String:
	return "%s · %d Créditos" % [nome_item(), preco()]


func descricao() -> String:
	return EFEITOS.get(item, "")


func texto_tecla() -> String:
	return "E: comprar"


func pode_interagir() -> bool:
	return restantes() > 0


func interagir(jogador: Jogador) -> void:
	comprar(jogador)


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
		draw_string(fonte, Vector2(-40, -6), "%d Créditos" % preco(), HORIZONTAL_ALIGNMENT_CENTER, 80, tam, Color("1a1c22"))
		if e_a_vez():
			desenhar_dica(-20)
		else:
			var cor: Color = Color("eceff4") if not esta_perto() or jogador_perto.creditos >= preco() else Color("ff8a6a")
			draw_string(fonte, Vector2(-40, -34), nome_item(), HORIZONTAL_ALIGNMENT_CENTER, 80, tam, cor)
	else:
		draw_string(fonte, Vector2(-40, -6), "Esgotado", HORIZONTAL_ALIGNMENT_CENTER, 80, tam, Color("1a1c22"))
	if _timer_aviso > 0.0:
		draw_string(fonte, Vector2(-50, -54), _aviso, HORIZONTAL_ALIGNMENT_CENTER, 100, tam, Color("ff8a6a"))
