extends CanvasLayer
## Autoload "Pausa": menu de pausa (D-054), aberto com Esc ou Start durante o jogo.
## O menu inicial (D-053) também usa as telas de Opções e Controles daqui.
## Telas: principal (Continuar, Controles, Opções, Voltar à nave, Sair do jogo), Controles (ver e
## trocar as teclas; salvo pelo Config), Opções (volume, tela cheia, acessibilidade) e a
## confirmação de abandonar a run. Visual da ART (assets/sprites/ui/menus/, mockups v06 e v07):
## painel e botões em nine-patch, seletor animado e texto nítido (D-056).
## Só abre com um jogador na cena e quando nada mais pausou o jogo (diálogo, ofertas, listas).

signal abriu
signal fechou

enum Tela { FECHADA, PRINCIPAL, CONTROLES, OPCOES, CONFIRMAR_SAIDA }

const COR_TEXTO: Color = EstiloMenu.COR_TEXTO
const COR_FOCO: Color = EstiloMenu.COR_FOCO
const COR_DESATIVADO: Color = EstiloMenu.COR_DESATIVADO
const COR_DICA: Color = EstiloMenu.COR_DICA
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
var _botoes: Array[Button] = []
var _botoes_teclas: Dictionary = {}
## Botões da coluna "Controle" (gamepad), por ação.
var _botoes_controle: Dictionary = {}
## A captura em andamento é de um botão do controle (e não de tecla).
var capturando_controle: bool = false
## Aberto pelo menu inicial (só Opções e Controles, sem pausar nada).
var _no_titulo: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 50
	_fundo = ColorRect.new()
	_fundo.color = COR_ESCURECER
	_fundo.size = TELA_JOGO
	_fundo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_fundo)
	_painel = EstiloMenu.painel()
	add_child(_painel)
	_conteudo = Control.new()
	_conteudo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_painel.add_child(_conteudo)
	_seletor = EstiloMenu.seletor()
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


## Menu inicial (D-053): abre direto nas Opções, com o botão de Controles; não pausa nada.
func abrir_opcoes_do_titulo() -> void:
	if esta_aberto():
		return
	_no_titulo = true
	visible = true
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	_mostrar(Tela.OPCOES)
	abriu.emit()


func fechar() -> void:
	if not esta_aberto():
		return
	esperando_acao = &""
	tela = Tela.FECHADA
	visible = false
	_limpar()
	if _no_titulo:
		_no_titulo = false
	else:
		get_tree().paused = false
		if not get_tree().get_nodes_in_group("jogadores").is_empty():
			Input.set_default_cursor_shape(Input.CURSOR_CROSS)  # mira com o mouse (D-052)
	fechou.emit()


## Esc / B: volta uma tela (na principal, fecha).
func voltar() -> void:
	match tela:
		Tela.PRINCIPAL:
			fechar()
		Tela.CONTROLES:
			_mostrar(Tela.OPCOES if _no_titulo else Tela.PRINCIPAL)
		Tela.OPCOES:
			if _no_titulo:
				fechar()
			else:
				_mostrar(Tela.PRINCIPAL)
		Tela.CONFIRMAR_SAIDA:
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


## Botão do controle (gamepad) de uma ação, na tela de Controles.
func botao_do_controle(acao: StringName) -> Button:
	return _botoes_controle.get(acao, null)


## A run atual pode ser abandonada (fora da nave).
func pode_voltar_a_nave() -> bool:
	var cena: Node = get_tree().current_scene
	return cena != null and not (cena is NaveEco)


## Na nave a pausa leva de volta ao menu inicial (D-054).
func pode_voltar_ao_menu() -> bool:
	return get_tree().current_scene is NaveEco


func pode_sair_do_jogo() -> bool:
	return not OS.has_feature("web")


# --- Entrada ---

func _input(evento: InputEvent) -> void:
	if esperando_acao == &"":
		return
	var tecla: bool = evento is InputEventKey and evento.pressed and not evento.echo
	if tecla and (evento as InputEventKey).physical_keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_terminar_captura("")
		return
	if capturando_controle:
		if Config.serve_para_controle(evento):
			get_viewport().set_input_as_handled()
			receber_botao(evento)
		elif tecla or (evento is InputEventMouseButton and evento.pressed):
			get_viewport().set_input_as_handled()  # esperando o controle: o resto é ignorado
		return
	var pressionou: bool = tecla or (evento is InputEventMouseButton and evento.pressed)
	if not pressionou:
		return
	get_viewport().set_input_as_handled()
	receber_tecla(evento)


## Recebe o botão novo do controle para a ação que está esperando.
func receber_botao(evento: InputEvent) -> void:
	if esperando_acao == &"":
		return
	var resultado: StringName = Config.trocar_botao(esperando_acao, evento)
	if resultado == &"reservada":
		_terminar_captura("Esse botão é reservado.")
	elif resultado != &"":
		_terminar_captura("Trocou com %s." % Config.NOMES_ACOES.get(resultado, String(resultado)))
	else:
		_terminar_captura("")


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
	var mostrar: bool = foco != null and _botoes.has(foco) and tela != Tela.CONTROLES
	EstiloMenu.posicionar_seletor(_seletor, foco if mostrar else null)


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
	_botoes_controle.clear()


func _montar_principal() -> void:
	var itens: Array = [["Continuar", fechar], ["Controles", _mostrar.bind(Tela.CONTROLES)],
			["Opções", _mostrar.bind(Tela.OPCOES)]]
	if pode_voltar_a_nave():
		itens.append(["Voltar à nave", _mostrar.bind(Tela.CONFIRMAR_SAIDA)])
	elif pode_voltar_ao_menu():
		itens.append(["Voltar ao menu", _voltar_ao_menu])
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
	var largura: float = 380.0
	var acoes: Array[StringName] = Config.ACOES_TROCAVEIS
	var linhas: int = acoes.size() + 2
	var altura: float = 40.0 + linhas * 14.0 + 40.0
	_posicionar_painel(Vector2(largura, altura))
	_titulo("CONTROLES", largura, 6.0)
	_rotulo("Teclado e mouse", Rect2(150.0, 24.0, 104.0, 9.0), Fontes.TAMANHO_PEQUENA, COR_DICA, true)
	_rotulo("Controle", Rect2(260.0, 24.0, 100.0, 9.0), Fontes.TAMANHO_PEQUENA, COR_DICA, true)
	var y: float = 36.0
	for acao in acoes:
		_rotulo(Config.NOMES_ACOES[acao], Rect2(18.0, y, 130.0, 11.0), Fontes.TAMANHO_TEXTO, COR_TEXTO)
		var b: Button = _botao(Config.texto_da_acao(acao), Rect2(150.0, y, 104.0, 11.0),
				_comecar_captura.bind(acao), Fontes.TAMANHO_TEXTO)
		_botoes_teclas[acao] = b
		if Config.ACOES_CONTROLE.has(acao):
			var c: Button = _botao(Config.texto_do_controle(acao), Rect2(260.0, y, 100.0, 11.0),
					_comecar_captura_controle.bind(acao), Fontes.TAMANHO_TEXTO)
			_botoes_controle[acao] = c
		else:
			_rotulo("Analógico", Rect2(260.0, y, 100.0, 11.0), Fontes.TAMANHO_TEXTO, COR_DESATIVADO, true)
		y += 14.0
	for fixo in [["Mirar", "Mouse", "Analógico dir."], ["Pausa", "Esc", "Start"]]:
		_rotulo(fixo[0], Rect2(18.0, y, 130.0, 11.0), Fontes.TAMANHO_TEXTO, COR_DESATIVADO)
		_rotulo(fixo[1], Rect2(150.0, y, 104.0, 11.0), Fontes.TAMANHO_TEXTO, COR_DESATIVADO, true)
		_rotulo(fixo[2], Rect2(260.0, y, 100.0, 11.0), Fontes.TAMANHO_TEXTO, COR_DESATIVADO, true)
		y += 14.0
	y += 4.0
	_botao("Restaurar padrão", Rect2(92.0, y, 94.0, 12.0), _restaurar_teclas, Fontes.TAMANHO_TEXTO)
	_botao("Voltar", Rect2(194.0, y, 94.0, 12.0), voltar, Fontes.TAMANHO_TEXTO)
	var dica: Label = _rotulo("Enter, clique ou A: trocar · Esc: voltar", Rect2(0.0, y + 16.0, largura, 9.0),
			Fontes.TAMANHO_PEQUENA, COR_DICA, true)
	dica.name = "Dica"


func _montar_opcoes() -> void:
	var largura: float = 240.0
	var linhas: int = 8 if _no_titulo else 6
	_posicionar_painel(Vector2(largura, 34.0 + linhas * 20.0))
	_titulo("OPÇÕES", largura, 8.0)
	var itens: Array = [[_texto_volume(), _ajustar_volume], [_texto_tela_cheia(), _ajustar_tela_cheia],
			[_texto_mira(), _ajustar_mira], [_texto_tiro(), _ajustar_tiro], [_texto_numeros(), _ajustar_numeros]]
	var y: float = 28.0
	for item in itens:
		var b: Button = _botao(item[0], Rect2(20.0, y, largura - 40.0, 15.0), (item[1] as Callable).bind(1))
		b.set_meta("ajuste", item[1])  # setas esquerda/direita mudam o valor
		y += 20.0
	if _no_titulo:  # no menu inicial não existe a tela principal da pausa
		_botao("Controles", Rect2(20.0, y, largura - 40.0, 15.0), _mostrar.bind(Tela.CONTROLES))
		y += 20.0
		_botao("Ver abertura", Rect2(20.0, y, largura - 40.0, 15.0), _ver_abertura)  # D-073B
		y += 20.0
	_botao("Voltar", Rect2(20.0, y, largura - 40.0, 15.0), voltar)


func _montar_confirmacao() -> void:
	var largura: float = 220.0
	_posicionar_painel(Vector2(largura, 92.0))
	_titulo("ABANDONAR A RUN?", largura, 8.0)
	_rotulo("Núcleos e Dados ficam. O resto da run se perde.", Rect2(0.0, 30.0, largura, 10.0),
			Fontes.TAMANHO_TEXTO, COR_TEXTO, true)
	_botao("Cancelar", Rect2(14.0, 54.0, 92.0, 16.0), _mostrar.bind(Tela.PRINCIPAL))
	_botao("Abandonar", Rect2(114.0, 54.0, 92.0, 16.0), _abandonar_run)


# --- Ações ---

## D-073B: "Ver abertura" nas Opções do menu inicial: toca de novo e volta ao menu.
func _ver_abertura() -> void:
	fechar()
	Ciclo.ir_para_abertura(true)


## O botão pode ter saído da tela até o foco ser aplicado (ex.: troca de tela no mesmo frame).
func _focar(botao: Variant) -> void:
	if not is_instance_valid(botao):
		return
	var b := botao as Button
	if b != null and b.is_inside_tree():
		b.grab_focus()


func _comecar_captura(acao: StringName) -> void:
	esperando_acao = acao
	capturando_controle = false
	aviso = ""
	var b: Button = _botoes_teclas.get(acao)
	if b != null:
		b.text = "Aperte uma tecla…"
		b.add_theme_color_override("font_color", COR_FOCO)


func _comecar_captura_controle(acao: StringName) -> void:
	esperando_acao = acao
	capturando_controle = true
	aviso = ""
	var b: Button = _botoes_controle.get(acao)
	if b != null:
		b.text = "Aperte um botão…"
		b.add_theme_color_override("font_color", COR_FOCO)


func _terminar_captura(mensagem: String) -> void:
	var era_controle: bool = capturando_controle
	esperando_acao = &""
	capturando_controle = false
	var foco: StringName = &""
	var mapa: Dictionary = _botoes_controle if era_controle else _botoes_teclas
	for acao: StringName in mapa:
		if mapa[acao].has_focus():
			foco = acao
	_mostrar(Tela.CONTROLES)
	aviso = mensagem
	if not mensagem.is_empty():
		var dica := _conteudo.get_node_or_null("Dica") as Label
		if dica != null:
			dica.text = mensagem
	var mapa_novo: Dictionary = _botoes_controle if era_controle else _botoes_teclas
	if foco != &"" and mapa_novo.has(foco):
		_focar.call_deferred(mapa_novo[foco])


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


func _ajustar_numeros(_direcao: int) -> void:
	Config.definir_numeros_dano(not Config.numeros_dano)
	_atualizar_texto_foco(_texto_numeros())


func _texto_numeros() -> String:
	return "Números de dano: %s" % ("Ligados" if Config.numeros_dano else "Desligados")


func _texto_tiro() -> String:
	return "Tiro automático: %s" % ("Ligado" if Config.tiro_automatico else "Desligado")


func _voltar_ao_menu() -> void:
	fechar()
	Progresso.salvar()
	Ciclo.ir_para_titulo()


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
	EstiloMenu.titulo(_conteudo, texto, largura, y)


func _rotulo(texto: String, ret: Rect2, tamanho: int, cor: Color, centro: bool = false) -> Label:
	return EstiloMenu.rotulo(_conteudo, texto, ret, tamanho, cor, centro)


func _botao(texto: String, ret: Rect2, acao: Callable, tamanho: int = Fontes.TAMANHO_BOTAO) -> Button:
	var b: Button = EstiloMenu.botao(_conteudo, texto, ret, acao, tamanho)
	_botoes.append(b)
	return b
