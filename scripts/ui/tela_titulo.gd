class_name TelaTitulo
extends Control
## Menu inicial (D-053), cena principal do jogo. Visual da ART (mockup v05): fundo da IA,
## logo, brasas subindo e os botões no centro.
## Continuar (só com jogo salvo) · Novo jogo (pede confirmação se for apagar o progresso) ·
## Opções (as telas de Opções e Controles da pausa) · Créditos · Sair (fora da Web).

const PASTA: String = "res://assets/sprites/ui/titulo/"
const ARQUIVO_CREDITOS: String = "res://data/ui/creditos.txt"
const VERSAO: String = "v0.2 · protótipo"
const TELA: Vector2 = Vector2(480, 270)
const TAMANHO_BOTAO: Vector2 = Vector2(99, 16)
const Y_PRIMEIRO_BOTAO: float = 128.0
const ESPACO_BOTOES: float = 22.0

## "" (só os botões), "confirmar_novo" ou "creditos".
var sobreposicao: String = ""
## Progresso usado para Continuar/Novo jogo (os testes trocam).
var progresso: DadosProgresso

var _botoes: Array[Button] = []
var _caixa_botoes: Control
var _painel: NinePatchRect
var _botoes_painel: Array[Button] = []
var _seletor: TextureRect


func _ready() -> void:
	if progresso == null:
		progresso = get_node_or_null("/root/Progresso") as DadosProgresso
	size = TELA
	theme = EstiloMenu.tema()
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	_montar_fundo()
	_caixa_botoes = Control.new()
	_caixa_botoes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_caixa_botoes)
	var versao: Label = EstiloMenu.rotulo(self, VERSAO, Rect2(10, 252, 160, 10), Fontes.TAMANHO_PEQUENA, EstiloMenu.COR_DICA)
	versao.name = "Versao"
	_seletor = EstiloMenu.seletor()
	add_child(_seletor)
	_montar_botoes()
	var pausa: Node = get_node_or_null("/root/Pausa")
	if pausa != null:
		pausa.fechou.connect(_ao_fechar_opcoes)


func textos_dos_botoes() -> Array[String]:
	var lista: Array[String] = []
	for b in (_botoes_painel if not sobreposicao.is_empty() else _botoes):
		lista.append(b.text)
	return lista


## Aperta o botão visível que tem esse texto.
func ativar(texto: String) -> bool:
	for b in (_botoes_painel if not sobreposicao.is_empty() else _botoes):
		if b.text == texto:
			b.pressed.emit()
			return true
	return false


func pode_sair() -> bool:
	return not OS.has_feature("web")


# --- Botões ---

func _montar_botoes() -> void:
	for b in _botoes:
		b.queue_free()
	_botoes.clear()
	var itens: Array = []
	if progresso != null and progresso.tem_jogo_salvo():
		itens.append(["Continuar", _continuar])
	itens.append(["Novo jogo", _novo_jogo])
	itens.append(["Opções", _opcoes])
	itens.append(["Créditos", _mostrar_creditos])
	if pode_sair():
		itens.append(["Sair", func() -> void: get_tree().quit()])
	var y: float = Y_PRIMEIRO_BOTAO
	var x: float = roundf((TELA.x - TAMANHO_BOTAO.x) * 0.5)
	for item in itens:
		_botoes.append(EstiloMenu.botao(_caixa_botoes, item[0], Rect2(Vector2(x, y), TAMANHO_BOTAO), item[1]))
		y += ESPACO_BOTOES
	_focar.call_deferred(_botoes[0])


func _continuar() -> void:
	Ciclo.ir_para_nave_do_titulo()


func _novo_jogo() -> void:
	if progresso != null and progresso.tem_jogo_salvo():
		_abrir_painel("confirmar_novo")
	else:
		_comecar_novo_jogo()


func _comecar_novo_jogo() -> void:
	if progresso != null:
		progresso.apagar()
	# D-073B: a abertura da história toca só no primeiro Novo jogo; depois vai direto à nave.
	if Config.abertura_vista:
		Ciclo.ir_para_nave_do_titulo()
	else:
		Ciclo.ir_para_abertura()


func _opcoes() -> void:
	var pausa: Node = get_node_or_null("/root/Pausa")
	if pausa == null:
		return
	_caixa_botoes.visible = false
	pausa.abrir_opcoes_do_titulo()


func _ao_fechar_opcoes() -> void:
	if not is_inside_tree():
		return
	_caixa_botoes.visible = sobreposicao.is_empty()
	if not _botoes.is_empty() and sobreposicao.is_empty():
		_focar.call_deferred(_botoes[0])


func _mostrar_creditos() -> void:
	_abrir_painel("creditos")


# --- Painéis (confirmação e créditos) ---

func _abrir_painel(qual: String) -> void:
	_fechar_painel()
	sobreposicao = qual
	_caixa_botoes.visible = false
	_painel = EstiloMenu.painel()
	add_child(_painel)
	move_child(_painel, _seletor.get_index())
	var tamanho: Vector2
	match qual:
		"confirmar_novo":
			tamanho = Vector2(240, 96)
			_painel.size = tamanho
			EstiloMenu.titulo(_painel, "NOVO JOGO?", tamanho.x, 8.0)
			EstiloMenu.rotulo(_painel, "Todo o progresso salvo será apagado.", Rect2(0, 32, tamanho.x, 10),
					Fontes.TAMANHO_TEXTO, EstiloMenu.COR_TEXTO, true)
			_botoes_painel.append(EstiloMenu.botao(_painel, "Cancelar", Rect2(14, 58, 100, 16), _fechar_painel))
			_botoes_painel.append(EstiloMenu.botao(_painel, "Apagar e começar", Rect2(126, 58, 100, 16), _comecar_novo_jogo))
		"creditos":
			tamanho = Vector2(320, 176)
			_painel.size = tamanho
			EstiloMenu.titulo(_painel, "CRÉDITOS", tamanho.x, 8.0)
			var texto: Label = EstiloMenu.rotulo(_painel, texto_dos_creditos(), Rect2(18, 28, tamanho.x - 36, 118),
					Fontes.TAMANHO_TEXTO, EstiloMenu.COR_TEXTO, false, true)
			texto.name = "Texto"
			texto.vertical_alignment = VERTICAL_ALIGNMENT_TOP
			_botoes_painel.append(EstiloMenu.botao(_painel, "Voltar", Rect2((tamanho.x - 99) * 0.5, 152, 99, 16), _fechar_painel))
	_painel.position = ((TELA - tamanho) * 0.5).round()
	_focar.call_deferred(_botoes_painel[0])


func _fechar_painel() -> void:
	if _painel != null:
		_painel.queue_free()
		_painel = null
	_botoes_painel.clear()
	var tinha: bool = not sobreposicao.is_empty()
	sobreposicao = ""
	_caixa_botoes.visible = true
	if tinha and not _botoes.is_empty():
		_focar.call_deferred(_botoes[0])


static func texto_dos_creditos() -> String:
	return FileAccess.get_file_as_string(ARQUIVO_CREDITOS).strip_edges()


# --- Entrada e visual ---

func _unhandled_input(evento: InputEvent) -> void:
	if not sobreposicao.is_empty() and (evento.is_action_pressed("ui_cancel") or evento.is_action_pressed("pausa")):
		_fechar_painel()
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	var foco := get_viewport().gui_get_focus_owner() as Button
	var visivel: bool = foco != null and (_botoes.has(foco) or _botoes_painel.has(foco)) and foco.is_visible_in_tree()
	EstiloMenu.posicionar_seletor(_seletor, foco if visivel else null)


func _focar(botao: Variant) -> void:
	if not is_instance_valid(botao):
		return
	var b := botao as Button
	if b != null and b.is_visible_in_tree():
		b.grab_focus()


func _montar_fundo() -> void:
	var fundo := TextureRect.new()
	fundo.name = "Fundo"
	fundo.texture = FolhaSprite.carregar(PASTA + "fundo_titulo_ia.png")
	fundo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fundo)
	fundo.size = TELA
	# Brasas subindo devagar (ART: 20–30 na tela).
	var brasas := CPUParticles2D.new()
	brasas.name = "Brasas"
	brasas.texture = FolhaSprite.carregar(PASTA + "brasa.png")
	var material_brasa := CanvasItemMaterial.new()
	material_brasa.particles_animation = true
	material_brasa.particles_anim_h_frames = 3
	material_brasa.particles_anim_v_frames = 1
	brasas.material = material_brasa
	brasas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	brasas.amount = 26
	brasas.lifetime = 9.0
	brasas.preprocess = 9.0
	brasas.position = Vector2(TELA.x * 0.5, TELA.y + 4.0)
	brasas.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	brasas.emission_rect_extents = Vector2(TELA.x * 0.5, 4.0)
	brasas.direction = Vector2(0, -1)
	brasas.spread = 18.0
	brasas.gravity = Vector2(0, -2)
	brasas.initial_velocity_min = 12.0
	brasas.initial_velocity_max = 26.0
	brasas.anim_offset_max = 1.0
	brasas.color = Color(1, 1, 1, 0.9)
	add_child(brasas)
	var logo := TextureRect.new()
	logo.name = "Logo"
	logo.texture = FolhaSprite.carregar(PASTA + "logo_no_rest.png")
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(logo)
	if logo.texture != null:
		logo.size = logo.texture.get_size()
		logo.position = Vector2(roundf((TELA.x - logo.size.x) * 0.5), 22.0)
