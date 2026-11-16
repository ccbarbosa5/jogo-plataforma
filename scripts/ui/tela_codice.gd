class_name TelaCodice
extends CanvasLayer
## Tela do Códice na nave (D-060): lista de entradas à esquerda, texto à direita.
## Entradas ainda não encontradas aparecem como "???". Mouse sempre, Esc sempre volta (D-065).

signal fechou

const PAINEL: Rect2 = Rect2(40, 14, 400, 242)
const LINHA: float = 17.0
const TOPO_LINHAS: float = 46.0
const LINHAS_VISIVEIS: int = 11
const LARGURA_LISTA: float = 124.0
const COR_TEXTO: Color = Color("eceff4")
const COR_APAGADO: Color = Color("6b6f7a")
const COR_TITULO: Color = Color("4fb0a6")
const OCULTO: String = "???"
const TEXTO_OCULTO: String = "Ainda não encontrado."

var entrada: EntradaJogador
var progresso: DadosProgresso
var entradas: Array[Dictionary] = []
var selecionada: int = 0
var primeira: int = 0
var escurecer: ColorRect
var painel: MolduraDialogo
var desenho: Control
var _aberta: bool = false
var _pausou: bool = false
var _anterior: Vector2i = Vector2i.ZERO
var _trava: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 9
	escurecer = ColorRect.new()
	escurecer.color = Color(0.03, 0.02, 0.05, 0.7)
	escurecer.size = Vector2(480, 270)
	escurecer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(escurecer)
	painel = MolduraDialogo.new()
	painel.position = PAINEL.position
	painel.size = PAINEL.size
	painel.mostrar_seta = false
	painel.moldura = "eco"
	add_child(painel)
	desenho = Control.new()
	desenho.size = Vector2(480, 270)
	desenho.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desenho.draw.connect(_desenhar)
	add_child(desenho)
	_mostrar(false)


func esta_aberta() -> bool:
	return _aberta


func abrir(progresso_: DadosProgresso) -> void:
	progresso = progresso_
	entradas = Codice.entradas(progresso)
	selecionada = 0
	primeira = 0
	_aberta = true
	_trava = 0.2
	_mostrar(true)
	if not get_tree().paused:
		get_tree().paused = true
		_pausou = true


func fechar() -> void:
	if not _aberta:
		return
	_aberta = false
	_mostrar(false)
	if _pausou:
		get_tree().paused = false
		_pausou = false
	fechou.emit()


func _mostrar(sim: bool) -> void:
	escurecer.visible = sim
	painel.visible = sim
	desenho.visible = sim


## Nome que aparece na lista ("???" enquanto não foi encontrada).
func nome_na_lista(i: int) -> String:
	return entradas[i]["nome"] if entradas[i]["liberada"] else OCULTO


## Texto do lado direito para a entrada selecionada.
func texto_da_selecionada() -> String:
	if entradas.is_empty():
		return ""
	var e: Dictionary = entradas[selecionada]
	if not e["liberada"]:
		return TEXTO_OCULTO
	var t: String = e["texto"]
	if not String(e["extra"]).is_empty():
		t += "\n\n" + e["extra"]
	return t


func retangulo_da_linha(i: int) -> Rect2:
	var k: int = i - primeira
	if k < 0 or k >= LINHAS_VISIVEIS:
		return Rect2()
	return Rect2(PAINEL.position.x + 12, TOPO_LINHAS + k * LINHA, LARGURA_LISTA, LINHA - 2)


func linha_no_ponto(ponto: Vector2) -> int:
	for i in range(primeira, mini(primeira + LINHAS_VISIVEIS, entradas.size())):
		if retangulo_da_linha(i).has_point(ponto):
			return i
	return -1


func selecionar(i: int) -> void:
	if entradas.is_empty():
		return
	selecionada = clampi(i, 0, entradas.size() - 1)
	if selecionada < primeira:
		primeira = selecionada
	elif selecionada >= primeira + LINHAS_VISIVEIS:
		primeira = selecionada - LINHAS_VISIVEIS + 1


func rolar(passos: int) -> void:
	primeira = clampi(primeira + passos, 0, maxi(entradas.size() - LINHAS_VISIVEIS, 0))
	selecionada = clampi(selecionada, primeira, mini(primeira + LINHAS_VISIVEIS, entradas.size()) - 1)


func _input(evento: InputEvent) -> void:
	if not _aberta:
		return
	if evento.is_action_pressed("ui_cancel") or evento.is_action_pressed("pausa"):
		fechar()
		get_viewport().set_input_as_handled()
		return
	var movimento := evento as InputEventMouseMotion
	if movimento != null:
		var i: int = linha_no_ponto(movimento.position)
		if i >= 0:
			selecionada = i
		return
	var botao := evento as InputEventMouseButton
	if botao == null or not botao.pressed:
		return
	match botao.button_index:
		MOUSE_BUTTON_WHEEL_UP:
			rolar(-1)
		MOUSE_BUTTON_WHEEL_DOWN:
			rolar(1)
		MOUSE_BUTTON_LEFT:
			var i: int = linha_no_ponto(botao.position)
			if i >= 0:
				selecionada = i
			elif not PAINEL.has_point(botao.position) and _trava <= 0.0:
				fechar()  # clique fora do painel volta
		_:
			return
	get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not _aberta:
		return
	_trava = maxf(_trava - delta, 0.0)
	desenho.queue_redraw()
	if entrada == null:
		return
	entrada.atualizar()
	var d: Vector2i = entrada.direcao
	var sair: bool = entrada.pular_pressionado
	entrada.fim_do_frame()
	var novo: int = d.y if d != _anterior else 0
	_anterior = d
	if _trava > 0.0:
		return
	if novo != 0 and not entradas.is_empty():
		selecionar(wrapi(selecionada + novo, 0, entradas.size()))
	if sair:
		fechar()


func _desenhar() -> void:
	var c: Control = desenho
	var f: Font = Fontes.texto()
	var x0: float = PAINEL.position.x + 14
	c.draw_string(Fontes.placa(), Vector2(x0, 34), "CÓDICE", HORIZONTAL_ALIGNMENT_LEFT, -1, Fontes.TAMANHO_BOTAO, COR_TITULO)
	var achadas: int = 0
	for e in entradas:
		if e["liberada"]:
			achadas += 1
	c.draw_string(f, Vector2(PAINEL.end.x - 214, 33), "%d de %d entradas" % [achadas, entradas.size()],
			HORIZONTAL_ALIGNMENT_RIGHT, 200, Fontes.TAMANHO_PEQUENA, COR_TEXTO)
	for i in range(primeira, mini(primeira + LINHAS_VISIVEIS, entradas.size())):
		var r: Rect2 = retangulo_da_linha(i)
		if i == selecionada:
			c.draw_rect(r, Color(1, 1, 1, 0.07))
			c.draw_rect(r, COR_TITULO, false, 1.0)
		c.draw_string(f, Vector2(r.position.x + 5, r.position.y + 10), nome_na_lista(i), HORIZONTAL_ALIGNMENT_LEFT,
				r.size.x - 10, Fontes.TAMANHO_TEXTO, COR_TEXTO if entradas[i]["liberada"] else COR_APAGADO)
	if primeira > 0:
		c.draw_string(f, Vector2(x0 + LARGURA_LISTA - 12, TOPO_LINHAS - 3), "▲", HORIZONTAL_ALIGNMENT_LEFT, -1, Fontes.TAMANHO_PEQUENA, COR_TITULO)
	if primeira + LINHAS_VISIVEIS < entradas.size():
		c.draw_string(f, Vector2(x0 + LARGURA_LISTA - 12, TOPO_LINHAS + LINHAS_VISIVEIS * LINHA + 4), "▼", HORIZONTAL_ALIGNMENT_LEFT, -1, Fontes.TAMANHO_PEQUENA, COR_TITULO)
	# Lado direito: a entrada selecionada.
	var xd: float = PAINEL.position.x + 12 + LARGURA_LISTA + 12
	var largura: float = PAINEL.end.x - 14 - xd
	c.draw_line(Vector2(xd - 6, TOPO_LINHAS), Vector2(xd - 6, PAINEL.end.y - 26), Color(COR_TITULO, 0.35), 1.0)
	if not entradas.is_empty():
		var e: Dictionary = entradas[selecionada]
		var liberada: bool = e["liberada"]
		c.draw_string(Fontes.placa(), Vector2(xd, TOPO_LINHAS + 10), String(e["nome"]).to_upper() if liberada else OCULTO,
				HORIZONTAL_ALIGNMENT_LEFT, largura, Fontes.TAMANHO_BOTAO, COR_TEXTO if liberada else COR_APAGADO)
		c.draw_string(f, Vector2(xd, TOPO_LINHAS + 21), "%s · %s" % [e["grupo"], e["titulo"]] if liberada else String(e["grupo"]),
				HORIZONTAL_ALIGNMENT_LEFT, largura, Fontes.TAMANHO_PEQUENA, COR_TITULO)
		c.draw_multiline_string(f, Vector2(xd, TOPO_LINHAS + 38), texto_da_selecionada(), HORIZONTAL_ALIGNMENT_LEFT, largura,
				Fontes.TAMANHO_TEXTO, -1, Color("c9ced8") if liberada else COR_APAGADO)
		if not String(e["aviso"]).is_empty():
			c.draw_string(f, Vector2(xd, PAINEL.end.y - 32), e["aviso"], HORIZONTAL_ALIGNMENT_LEFT, largura, Fontes.TAMANHO_PEQUENA, COR_APAGADO)
	c.draw_string(f, Vector2(x0, PAINEL.end.y - 15), "Mouse ou setas: escolher · Roda: rolar · Esc: voltar",
			HORIZONTAL_ALIGNMENT_LEFT, -1, Fontes.TAMANHO_PEQUENA, COR_APAGADO)
