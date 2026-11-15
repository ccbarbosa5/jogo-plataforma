class_name TelaArvoreCombate
extends CanvasLayer
## Árvore de Combate do Ryker (GD-07 §4), no Arsenal com Garrak. Só abre na nave.
## Uma coluna por ramo (Mordida, Bramido, Granada, Grilhão, Dash), nós de cima para baixo.
## Clique (ou Enter) compra o nó; Redistribuir devolve todos os pontos (grátis).
## Visual provisório no estilo dos menus até a ART entregar a tela (ART-3).

signal fechou

const TELA: Vector2 = Vector2(480, 270)
const LARGURA_RAMO: float = 84.0
const ESPACO_RAMOS: float = 6.0
const ALTURA_NO: float = 22.0
const ESPACO_NOS: float = 4.0
const Y_NOS: float = 52.0
const COR_COMPRADO: Color = Color("9fdc8a")
const COR_APICE: Color = Color("f2a65a")
const MOTIVOS: Dictionary = {
	ProgressaoPersonagem.Estado.COMPRADO: "Comprado.",
	ProgressaoPersonagem.Estado.DISPONIVEL: "Clique para comprar.",
	ProgressaoPersonagem.Estado.SEM_PONTOS: "Pontos insuficientes.",
	ProgressaoPersonagem.Estado.TRANCADO: "Compre o nó de cima antes.",
	ProgressaoPersonagem.Estado.LIMITE_APICES: "No máximo 2 Ápices na build.",
}

var progressao: ProgressaoPersonagem
var progresso: DadosProgresso
## Arma levada na próxima run (o ramo da outra arma fica inativo).
var arma_id: String = "mordida"

var _raiz: Control
var _botoes: Dictionary = {}
var _info: Label
var _cabecalho: Label
var _seletor: TextureRect
var _aberta: bool = false
var _pausou: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 40
	visible = false


func esta_aberta() -> bool:
	return _aberta


func abrir(progressao_: ProgressaoPersonagem, progresso_: DadosProgresso, arma: String) -> void:
	if _aberta:
		return
	progressao = progressao_
	progresso = progresso_
	arma_id = arma
	_aberta = true
	_pausou = not get_tree().paused
	get_tree().paused = true
	visible = true
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	_montar()


func fechar() -> void:
	if not _aberta:
		return
	_aberta = false
	visible = false
	if _raiz != null:
		_raiz.queue_free()
		_raiz = null
	_botoes.clear()
	if _pausou:
		get_tree().paused = false
	fechou.emit()


## Compra o nó (se puder) e atualiza a tela.
func comprar(id: StringName) -> bool:
	var ok: bool = progressao.comprar(id, progresso)
	_montar(id)
	if not ok:
		_mostrar_info(id)
	return ok


func redistribuir() -> void:
	progressao.redistribuir(progresso)
	_montar()


func botao_do_no(id: StringName) -> Button:
	return _botoes.get(id, null)


func _montar(foco: StringName = &"") -> void:
	if _raiz != null:
		_raiz.queue_free()
	_botoes.clear()
	_raiz = Control.new()
	_raiz.size = TELA
	_raiz.theme = EstiloMenu.tema()
	add_child(_raiz)
	var fundo: NinePatchRect = EstiloMenu.painel()
	_raiz.add_child(fundo)
	fundo.size = TELA - Vector2(8, 8)
	fundo.position = Vector2(4, 4)
	EstiloMenu.titulo(_raiz, "ÁRVORE DE COMBATE · RYKER", TELA.x, 8.0)
	_cabecalho = EstiloMenu.rotulo(_raiz, _texto_cabecalho(), Rect2(0, 24, TELA.x, 10), Fontes.TAMANHO_TEXTO, EstiloMenu.COR_DICA, true)
	var x: float = roundf((TELA.x - (progressao.ramos.size() * LARGURA_RAMO + (progressao.ramos.size() - 1) * ESPACO_RAMOS)) * 0.5)
	var primeiro: Button = null
	for ramo: Dictionary in progressao.ramos:
		var inativo: bool = ramo.has("arma") and ramo["arma"] != arma_id
		var titulo: String = ramo["nome"] + (" (não equipada)" if inativo else "")
		EstiloMenu.rotulo(_raiz, titulo, Rect2(x, 38, LARGURA_RAMO, 10), Fontes.TAMANHO_PEQUENA,
				EstiloMenu.COR_DESATIVADO if inativo else EstiloMenu.COR_FOCO, true)
		var y: float = Y_NOS
		for no: Dictionary in ramo["nos"]:
			var id := StringName(no["id"])
			var b: Button = EstiloMenu.botao(_raiz, "%s (%d)" % [no["nome"], int(no["custo"])],
					Rect2(x, y, LARGURA_RAMO, ALTURA_NO), comprar.bind(id), Fontes.TAMANHO_PEQUENA)
			_pintar(b, id)
			b.focus_entered.connect(_mostrar_info.bind(id))
			_botoes[id] = b
			if primeiro == null:
				primeiro = b
			y += ALTURA_NO + ESPACO_NOS
		x += LARGURA_RAMO + ESPACO_RAMOS
	_info = EstiloMenu.rotulo(_raiz, "", Rect2(24, 186, TELA.x - 48, 40), Fontes.TAMANHO_TEXTO, EstiloMenu.COR_TEXTO, true, true)
	_info.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	EstiloMenu.botao(_raiz, "Redistribuir", Rect2(130, 238, 104, 16), redistribuir, Fontes.TAMANHO_TEXTO)
	EstiloMenu.botao(_raiz, "Voltar", Rect2(246, 238, 104, 16), fechar, Fontes.TAMANHO_TEXTO)
	_seletor = EstiloMenu.seletor()
	_raiz.add_child(_seletor)
	var focar: Button = _botoes.get(foco, primeiro)
	if focar != null:
		_focar.call_deferred(focar)


func _pintar(b: Button, id: StringName) -> void:
	var estado: ProgressaoPersonagem.Estado = progressao.estado(id, progresso)
	var cor: Color = EstiloMenu.COR_TEXTO
	match estado:
		ProgressaoPersonagem.Estado.COMPRADO:
			cor = COR_COMPRADO
		ProgressaoPersonagem.Estado.DISPONIVEL:
			cor = COR_APICE if progressao.e_apice(id) else EstiloMenu.COR_TEXTO
		_:
			cor = EstiloMenu.COR_DESATIVADO
	b.add_theme_color_override("font_color", cor)
	b.add_theme_color_override("font_focus_color", cor.lightened(0.2))
	b.add_theme_color_override("font_hover_color", cor.lightened(0.2))


func _texto_cabecalho() -> String:
	var xp: Vector2i = progressao.xp_no_nivel(progresso)
	var texto_xp: String = "XP %d/%d" % [xp.x, xp.y] if xp.y > 0 else "nível máximo"
	return "Nível %d · %s · Pontos livres: %d · Ápices: %d/%d" % [progressao.nivel(progresso), texto_xp,
			progressao.pontos_livres(progresso), progressao.apices(progresso), progressao.maximo_apices]


func _mostrar_info(id: StringName) -> void:
	if _info == null or not is_instance_valid(_info):
		return
	var no: Dictionary = progressao.no(id)
	var apice: String = " · Ápice" if progressao.e_apice(id) else ""
	_info.text = "%s%s — %s\n%s" % [no.get("nome", ""), apice, no.get("descricao", ""),
			MOTIVOS[progressao.estado(id, progresso)]]


func _unhandled_input(evento: InputEvent) -> void:
	if _aberta and (evento.is_action_pressed("ui_cancel") or evento.is_action_pressed("pausa")):
		fechar()
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if not _aberta or _seletor == null:
		return
	var foco := get_viewport().gui_get_focus_owner() as Button
	EstiloMenu.posicionar_seletor(_seletor, foco if foco != null and foco.is_visible_in_tree() else null)


func _focar(botao: Variant) -> void:
	if not is_instance_valid(botao):
		return
	var b := botao as Button
	if b != null and b.is_visible_in_tree():
		b.grab_focus()
