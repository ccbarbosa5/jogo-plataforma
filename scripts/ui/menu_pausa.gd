extends CanvasLayer
## Autoload "Pausa": menu de pausa (D-054), aberto com Esc ou Start durante o jogo.
## Telas: principal (Continuar, Controles, Opções, Voltar à nave, Sair do jogo), Controles (ver e
## trocar as teclas; salvo pelo Config), Opções (volume, tela cheia, acessibilidade) e a
## confirmação de abandonar a run. Visual da ART (assets/sprites/ui/menus/, mockups v06 e v07):
## painel e botões em nine-patch, seletor animado e texto nítido (D-056).
## Só abre com um jogador na cena e quando nada mais pausou o jogo (diálogo, ofertas, listas).

signal abriu
signal fechou

enum Tela { FECHADA, PRINCIPAL, CONTROLES, OPCOES, CONFIRMAR_SAIDA }

const PASTA: String = "res://assets/sprites/ui/menus/"
const COR_TEXTO: Color = Color("fff6ea")
const COR_FOCO: Color = Color("ffe0b8")
const COR_DESATIVADO: Color = Color("7d7886")
const COR_DICA: Color = Color("a7a1ae")
const COR_ESCURECER: Color = Color(0.03, 0.02, 0.05, 0.62)
const TELA_JOGO: Vector2 = Vector2(480, 270)
## Passo do volume nas Opções.
const PASSO_VOLUME: float = 0.1

var tela: Tela = Tela.FECHADA
## Ação esperando uma tecla nova na tela de Controles (&"" = nenhuma).
var esperando_acao: StringName = &""
## Mensagem curta na tela de Controles (ex.: tecla reservada, troca com outra ação).
var aviso: String = ""

var _fundo: ColorRect
var _painel: NinePatchRect
var _conteudo: Control
var _seletor: TextureRect
var _seletor_atlas: AtlasTexture
var _tema: Theme
var _botoes: Array[Button] = []
var _botoes_teclas: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 50
	_tema = _criar_tema()
	_fundo = ColorRect.new()
	_fundo.color = COR_ESCURECER
	_fundo.size = TELA_JOGO
	_fundo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_fundo)
	_painel = NinePatchRect.new()
	_painel.texture = FolhaSprite.carregar(PASTA + "painel.png")
	for lado in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		_painel.set_patch_margin(lado, 8)
	_painel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_painel.theme = _tema
	add_child(_painel)
	_conteudo = Control.new()
	_conteudo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_painel.add_child(_conteudo)
	_seletor_atlas = AtlasTexture.new()
	_seletor_atlas.atlas = FolhaSprite.carregar(PASTA + "seletor.png")
	_seletor_atlas.region = Rect2(0, 0, 6, 9)
	_seletor = TextureRect.new()
	_seletor.texture = _seletor_atlas
	_seletor.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_seletor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_seletor)
	visible = false


func esta_aberto() -> bool:
	return tela != Tela.FECHADA


## Abre se há um jogador na cena e nada mais pausou o jogo.
func pode_abrir() -> bool:
	return not esta_aberto() and not get_tree().paused \
			and not get_tree().get_nodes_in_group("jogadores").is_empty()


func abrir() -> bool:
	if not pode_abrir():
		return false
	get_tree().paused = true
	visible = true
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	_mostrar(Tela.PRINCIPAL)
	abriu.emit()
	return true


func fechar() -> void:
	if not esta_aberto():
		return
	esperando_acao = &""
	tela = Tela.FECHADA
	visible = false
	_limpar()
	get_tree().paused = false
	if not get_tree().get_nodes_in_group("jogadores").is_empty():
		Input.set_default_cursor_shape(Input.CURSOR_CROSS)  # mira com o mouse (D-052)
	fechou.emit()


## Esc / B: volta uma tela (na principal, fecha).
func voltar() -> void:
	match tela:
		Tela.PRINCIPAL:
			fechar()
		Tela.CONTROLES, Tela.OPCOES, Tela.CONFIRMAR_SAIDA:
			_mostrar(Tela.PRINCIPAL)


## Textos dos botões da tela atual (testes e navegação).
func textos_dos_botoes() -> Array[String]:
	var lista: Array[String] = []
	for b in _botoes:
		lista.append(b.text)
	return lista


## Aperta o botão da tela atual que tem esse texto (ou começa com ele).
func ativar(texto: String) -> bool:
	for b in _botoes:
		if b.text == texto or b.text.begins_with(texto):
			if b.disabled:
				return false
			b.pressed.emit()
			return true
	return false


## Botão da tecla de uma ação, na tela de Controles.
func botao_da_acao(acao: StringName) -> Button:
	return _botoes_teclas.get(acao, null)


## A run atual pode ser abandonada (fora da nave).
func pode_voltar_a_nave() -> bool:
	var cena: Node = get_tree().current_scene
	return cena != null and not (cena is NaveEco)


func pode_sair_do_jogo() -> bool:
	return not OS.has_feature("web")


# --- Entrada ---

func _input(evento: InputEvent) -> void:
	if esperando_acao == &"":
		return
	var pressionou: bool = (evento is InputEventKey and evento.pressed and not evento.echo) \
			or (evento is InputEventMouseButton and evento.pressed)
	if not pressionou:
		return
	get_viewport().set_input_as_handled()
	if evento is InputEventKey and (evento as InputEventKey).physical_keycode == KEY_ESCAPE:
		_terminar_captura("")
		return
	receber_tecla(evento)


## Recebe a tecla nova para a ação que está esperando (a tela de Controles chama; os testes também).
func receber_tecla(evento: InputEvent) -> void:
	if esperando_acao == &"":
		return
	var acao: StringName = esperando_acao
	var resultado: StringName = Config.trocar_tecla(acao, evento)
	if resultado == &"reservada":
		_terminar_captura("Essa tecla é reservada.")
	elif resultado != &"":
		_terminar_captura("Trocou com %s." % Config.NOMES_ACOES.get(resultado, String(resultado)))
	else:
		_terminar_captura("")


func _unhandled_input(evento: InputEvent) -> void:
	if not esta_aberto():
		if evento.is_action_pressed("pausa") and abrir():
			get_viewport().set_input_as_handled()
		return
	if evento.is_action_pressed("pausa") or evento.is_action_pressed("ui_cancel"):
		voltar()
		get_viewport().set_input_as_handled()
	elif tela == Tela.OPCOES and (evento.is_action_pressed("ui_left") or evento.is_action_pressed("ui_right")):
		var foco: Control = get_viewport().gui_get_focus_owner()
		if foco != null and foco.has_meta("ajuste"):
			var direcao: int = -1 if evento.is_action_pressed("ui_left") else 1
			(foco.get_meta("ajuste") as Callable).call(direcao)
			get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if not esta_aberto():
		return
	var foco := get_viewport().gui_get_focus_owner() as Button
	_seletor.visible = foco != null and _botoes.has(foco) and tela != Tela.CONTROLES
	if _seletor.visible:
		_seletor.position = foco.global_position + Vector2(-10.0, (foco.size.y - 9.0) * 0.5)
		_seletor_atlas.region = Rect2(6 * (int(Time.get_ticks_msec() / 250) % 2), 0, 6, 9)


# --- Telas ---

func _mostrar(nova: Tela) -> void:
	esperando_acao = &""
	aviso = ""
	tela = nova
	_limpar()
	match tela:
		Tela.PRINCIPAL:
			_montar_principal()
		Tela.CONTROLES:
			_montar_controles()
		Tela.OPCOES:
			_montar_opcoes()
		Tela.CONFIRMAR_SAIDA:
			_montar_confirmacao()
	if not _botoes.is_empty():
		_focar.call_deferred(_botoes[0])


func _limpar() -> void:
	for filho in _conteudo.get_children():
		filho.queue_free()
		_conteudo.remove_child(filho)
	_botoes.clear()
	_botoes_teclas.clear()


func _montar_principal() -> void:
	var itens: Array = [["Continuar", fechar], ["Controles", _mostrar.bind(Tela.CONTROLES)],
			["Opções", _mostrar.bind(Tela.OPCOES)]]
	if pode_voltar_a_nave():
		itens.append(["Voltar à nave", _mostrar.bind(Tela.CONFIRMAR_SAIDA)])
	if pode_sair_do_jogo():
		itens.append(["Sair do jogo", func() -> void: get_tree().quit()])
	var largura: float = 158.0
	var altura: float = 34.0 + itens.size() * 22.0
	_posicionar_painel(Vector2(largura, altura))
	_titulo("PAUSA", largura, 8.0)
	var y: float = 28.0
	for item in itens:
		_botao(item[0], Rect2(20.0, y, 118.0, 16.0), item[1])
		y += 22.0


func _montar_controles() -> void:
	var largura: float = 298.0
	var acoes: Array[StringName] = Config.ACOES_TROCAVEIS
	var linhas: int = acoes.size() + 2
	var altura: float = 30.0 + linhas * 14.0 + 40.0
	_posicionar_painel(Vector2(largura, altura))
	_titulo("CONTROLES", largura, 6.0)
	var y: float = 26.0
	for acao in acoes:
		_rotulo(Config.NOMES_ACOES[acao], Rect2(24.0, y, 150.0, 11.0), Fontes.TAMANHO_TEXTO, COR_TEXTO)
		var b: Button = _botao(Config.texto_da_acao(acao), Rect2(180.0, y, 94.0, 11.0),
				_comecar_captura.bind(acao), Fontes.TAMANHO_TEXTO)
		_botoes_teclas[acao] = b
		y += 14.0
	for fixo in [["Mirar", "Mouse"], ["Pausa", "Esc"]]:
		_rotulo(fixo[0], Rect2(24.0, y, 150.0, 11.0), Fontes.TAMANHO_TEXTO, COR_DESATIVADO)
		_rotulo(fixo[1], Rect2(180.0, y, 94.0, 11.0), Fontes.TAMANHO_TEXTO, COR_DESATIVADO, true)
		y += 14.0
	y += 4.0
	_botao("Restaurar padrão", Rect2(52.0, y, 94.0, 12.0), _restaurar_teclas, Fontes.TAMANHO_TEXTO)
	_botao("Voltar", Rect2(152.0, y, 94.0, 12.0), _mostrar.bind(Tela.PRINCIPAL), Fontes.TAMANHO_TEXTO)
	var dica: Label = _rotulo("Enter ou clique: trocar · Esc: voltar", Rect2(0.0, y + 16.0, largura, 9.0),
			Fontes.TAMANHO_PEQUENA, COR_DICA, true)
	dica.name = "Dica"


func _montar_opcoes() -> void:
	var largura: float = 240.0
	_posicionar_painel(Vector2(largura, 34.0 + 5 * 20.0))
	_titulo("OPÇÕES", largura, 8.0)
	var itens: Array = [[_texto_volume(), _ajustar_volume], [_texto_tela_cheia(), _ajustar_tela_cheia],
			[_texto_mira(), _ajustar_mira], [_texto_tiro(), _ajustar_tiro]]
	var y: float = 28.0
	for item in itens:
		var b: Button = _botao(item[0], Rect2(20.0, y, largura - 40.0, 15.0), (item[1] as Callable).bind(1))
		b.set_meta("ajuste", item[1])  # setas esquerda/direita mudam o valor
		y += 20.0
	_botao("Voltar", Rect2(20.0, y, largura - 40.0, 15.0), _mostrar.bind(Tela.PRINCIPAL))


func _montar_confirmacao() -> void:
	var largura: float = 220.0
	_posicionar_painel(Vector2(largura, 92.0))
	_titulo("ABANDONAR A RUN?", largura, 8.0)
	_rotulo("Núcleos e Dados ficam. O resto da run se perde.", Rect2(0.0, 30.0, largura, 10.0),
			Fontes.TAMANHO_TEXTO, COR_TEXTO, true)
	_botao("Cancelar", Rect2(14.0, 54.0, 92.0, 16.0), _mostrar.bind(Tela.PRINCIPAL))
	_botao("Abandonar", Rect2(114.0, 54.0, 92.0, 16.0), _abandonar_run)


# --- Ações ---

## O botão pode ter saído da tela até o foco ser aplicado (ex.: troca de tela no mesmo frame).
func _focar(botao: Variant) -> void:
	if not is_instance_valid(botao):
		return
	var b := botao as Button
	if b != null and b.is_inside_tree():
		b.grab_focus()


func _comecar_captura(acao: StringName) -> void:
	esperando_acao = acao
	aviso = ""
	var b: Button = _botoes_teclas.get(acao)
	if b != null:
		b.text = "Aperte uma tecla…"
		b.add_theme_color_override("font_color", COR_FOCO)


func _terminar_captura(mensagem: String) -> void:
	esperando_acao = &""
	var foco: StringName = &""
	for acao: StringName in _botoes_teclas:
		if _botoes_teclas[acao].has_focus():
			foco = acao
	_mostrar(Tela.CONTROLES)
	aviso = mensagem
	if not mensagem.is_empty():
		var dica := _conteudo.get_node_or_null("Dica") as Label
		if dica != null:
			dica.text = mensagem
	if foco != &"" and _botoes_teclas.has(foco):
		_focar.call_deferred(_botoes_teclas[foco])


func _restaurar_teclas() -> void:
	Config.restaurar_teclas()
	_mostrar(Tela.CONTROLES)


func _ajustar_volume(direcao: int) -> void:
	var novo: float = snappedf(Config.volume + direcao * PASSO_VOLUME, 0.01)
	if novo > 1.0 + 0.001:
		novo = 0.0  # Enter no 100% dá a volta
	Config.definir_volume(clampf(novo, 0.0, 1.0))
	_atualizar_texto_foco(_texto_volume())


func _ajustar_tela_cheia(_direcao: int) -> void:
	Config.definir_tela_cheia(not Config.tela_cheia)
	_atualizar_texto_foco(_texto_tela_cheia())


func _ajustar_mira(direcao: int) -> void:
	Config.definir_modo_mira(Config.modo_mira + direcao)
	_atualizar_texto_foco(_texto_mira())


func _ajustar_tiro(_direcao: int) -> void:
	Config.definir_tiro_automatico(not Config.tiro_automatico)
	_atualizar_texto_foco(_texto_tiro())


func _atualizar_texto_foco(texto: String) -> void:
	# O botão da opção é o que começa com o mesmo rótulo.
	var rotulo: String = texto.split(":")[0]
	for b in _botoes:
		if b.text.begins_with(rotulo):
			b.text = texto


func _texto_volume() -> String:
	return "Volume: %d%%" % roundi(Config.volume * 100.0)


func _texto_tela_cheia() -> String:
	return "Tela cheia: %s" % ("Sim" if Config.tela_cheia else "Não")


func _texto_mira() -> String:
	return "Mira automática: %s" % Config.NOMES_MIRA[Config.modo_mira]


func _texto_tiro() -> String:
	return "Tiro automático: %s" % ("Ligado" if Config.tiro_automatico else "Desligado")


func _abandonar_run() -> void:
	fechar()
	Progresso.salvar()  # Núcleos e Dados ficam (GD-01 §8)
	Ciclo.voltar_para_nave("desistiu")


# --- Montagem ---

func _posicionar_painel(tamanho: Vector2) -> void:
	_painel.size = tamanho
	_painel.position = ((TELA_JOGO - tamanho) * 0.5).round()
	_conteudo.size = tamanho


func _titulo(texto: String, largura: float, y: float) -> void:
	var r: Label = _rotulo(texto, Rect2(0.0, y, largura, 16.0), Fontes.TAMANHO_TITULO, COR_FOCO, true)
	r.add_theme_font_override("font", Fontes.placa())


func _rotulo(texto: String, ret: Rect2, tamanho: int, cor: Color, centro: bool = false) -> Label:
	var r := Label.new()
	r.text = texto
	r.position = ret.position
	r.size = ret.size
	r.add_theme_font_override("font", Fontes.texto())
	r.add_theme_font_size_override("font_size", tamanho)
	r.add_theme_color_override("font_color", cor)
	r.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if centro:
		r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_conteudo.add_child(r)
	r.size = ret.size
	return r


func _botao(texto: String, ret: Rect2, acao: Callable, tamanho: int = Fontes.TAMANHO_BOTAO) -> Button:
	var b := Button.new()
	b.text = texto
	b.position = ret.position
	b.size = ret.size
	b.custom_minimum_size = ret.size
	b.add_theme_font_size_override("font_size", tamanho)
	b.clip_text = true
	b.focus_mode = Control.FOCUS_ALL
	b.pressed.connect(acao)
	b.mouse_entered.connect(b.grab_focus)
	_conteudo.add_child(b)
	b.size = ret.size  # depois de entrar na árvore, com o tema já aplicado
	_botoes.append(b)
	return b


func _criar_tema() -> Theme:
	var t := Theme.new()
	var folha: Texture2D = FolhaSprite.carregar(PASTA + "botao.png")
	var estados: Dictionary = {"normal": 0, "hover": 1, "focus": 1, "pressed": 2, "disabled": 3}
	for estado: String in estados:
		var estilo := StyleBoxTexture.new()
		if folha != null:
			var quadro := AtlasTexture.new()
			quadro.atlas = folha
			quadro.region = Rect2(16 * estados[estado], 0, 16, 16)
			estilo.texture = quadro
		estilo.texture_margin_left = 4
		estilo.texture_margin_top = 4
		estilo.texture_margin_right = 4
		estilo.texture_margin_bottom = 4
		# Margem interna pequena: o texto nítido é menor que a moldura em pixels.
		estilo.content_margin_left = 3
		estilo.content_margin_right = 3
		estilo.content_margin_top = 0
		estilo.content_margin_bottom = 0
		estilo.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
		estilo.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
		t.set_stylebox(estado, "Button", estilo)
	t.set_font("font", "Button", Fontes.placa())
	t.set_font_size("font_size", "Button", Fontes.TAMANHO_BOTAO)
	t.set_color("font_color", "Button", COR_TEXTO)
	t.set_color("font_hover_color", "Button", COR_FOCO)
	t.set_color("font_focus_color", "Button", COR_FOCO)
	t.set_color("font_pressed_color", "Button", COR_FOCO)
	t.set_color("font_hover_pressed_color", "Button", COR_FOCO)
	t.set_color("font_disabled_color", "Button", COR_DESATIVADO)
	return t
