class_name TelaLista
extends CanvasLayer
## Menu de lista da nave (Arsenal, Vossa Margem, Arquivo da Ponte): título, moeda e uma lista de
## opções com descrição, preço e estado. Setas escolhem; Atirar ou E confirma; Pular fecha.
## D-065: também inteira com o mouse (passar destaca, clique confirma, roda rola a lista) e
## Esc sempre fecha.
## As opções vêm de `fonte` (Callable que devolve Array[Dictionary]) e são refeitas a cada compra:
##   {nome, descricao, direita (texto à direita), pode (bool), acao (Callable)}

signal fechou

const PAINEL: Rect2 = Rect2(40, 14, 400, 242)
const LINHA: float = 30.0
const COR_TEXTO: Color = Color("eceff4")
const COR_APAGADO: Color = Color("6b6f7a")
const TOPO_LINHAS: float = 44.0
## Linhas que cabem no painel (o resto rola).
const LINHAS_VISIVEIS: int = 6

var entrada: EntradaJogador
var titulo: String = ""
var subtitulo: Callable = Callable()
var cor_titulo: Color = Color("e8742c")
var fonte: Callable = Callable()
var opcoes: Array[Dictionary] = []
var selecionada: int = 0
## Primeira linha mostrada (rolagem).
var primeira: int = 0
var mensagem: String = ""
## Fala curta de quem atende (NAR-06), mostrada acima do rodapé.
var fala: Dictionary = {}

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
	add_child(painel)
	desenho = Control.new()
	desenho.size = Vector2(480, 270)
	desenho.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desenho.draw.connect(_desenhar)
	add_child(desenho)
	_mostrar(false)


func esta_aberta() -> bool:
	return _aberta


func abrir(titulo_: String, moldura: String, fonte_: Callable, subtitulo_: Callable = Callable()) -> void:
	titulo = titulo_
	fonte = fonte_
	subtitulo = subtitulo_
	painel.moldura = moldura
	selecionada = 0
	primeira = 0
	mensagem = ""
	fala = {}
	_atualizar()
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


func _atualizar() -> void:
	opcoes.clear()
	for o: Dictionary in fonte.call():
		opcoes.append(o)
	selecionada = clampi(selecionada, 0, maxi(opcoes.size() - 1, 0))
	_mostrar_selecionada()


func _mostrar_selecionada() -> void:
	if selecionada < primeira:
		primeira = selecionada
	elif selecionada >= primeira + LINHAS_VISIVEIS:
		primeira = selecionada - LINHAS_VISIVEIS + 1
	primeira = clampi(primeira, 0, maxi(opcoes.size() - LINHAS_VISIVEIS, 0))


## Retângulo da linha `i` na tela (ou vazio se está fora da rolagem).
func retangulo_da_linha(i: int) -> Rect2:
	var k: int = i - primeira
	if k < 0 or k >= LINHAS_VISIVEIS:
		return Rect2()
	return Rect2(PAINEL.position.x + 12, TOPO_LINHAS + k * LINHA, PAINEL.size.x - 24, LINHA - 3)


func linha_no_ponto(ponto: Vector2) -> int:
	for i in range(primeira, mini(primeira + LINHAS_VISIVEIS, opcoes.size())):
		if retangulo_da_linha(i).has_point(ponto):
			return i
	return -1


func rolar(passos: int) -> void:
	primeira = clampi(primeira + passos, 0, maxi(opcoes.size() - LINHAS_VISIVEIS, 0))
	selecionada = clampi(selecionada, primeira, mini(primeira + LINHAS_VISIVEIS, opcoes.size()) - 1)


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
		if i >= 0 and i != selecionada:
			selecionada = i
			mensagem = ""
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
			if i >= 0 and _trava <= 0.0:
				selecionada = i
				confirmar(i)
		_:
			return
	get_viewport().set_input_as_handled()


## Confirma a opção `i`. Retorna true se a ação aconteceu.
func confirmar(i: int) -> bool:
	if i < 0 or i >= opcoes.size():
		return false
	var o: Dictionary = opcoes[i]
	if not o.get("pode", false):
		mensagem = o.get("motivo", "Indisponível.")
		if o.has("ao_falhar"):
			o["ao_falhar"].call()
		return false
	var ok: bool = o["acao"].call()
	mensagem = o.get("feito", "") if ok else o.get("motivo", "Indisponível.")
	_atualizar()
	return ok


## Mostra a fala curta da cena (se tocar agora). Retorna true se mostrou.
func falar(id_cena: String) -> bool:
	var f: Dictionary = Dialogos.fala_curta(id_cena)
	if f.is_empty():
		return false
	fala = f
	return true


func _mostrar(sim: bool) -> void:
	escurecer.visible = sim
	painel.visible = sim
	desenho.visible = sim


func _process(delta: float) -> void:
	if not _aberta:
		return
	_trava = maxf(_trava - delta, 0.0)
	desenho.queue_redraw()
	if entrada == null:
		return
	entrada.atualizar()
	var d: Vector2i = entrada.direcao
	# O clique do mouse (que também é "atirar") é tratado em _input, na linha sob o cursor.
	var ok: bool = (entrada.atirar_pressionado and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)) \
			or entrada.interagir_pressionado
	var sair: bool = entrada.pular_pressionado
	entrada.fim_do_frame()
	var novo: int = d.y if d != _anterior else 0
	_anterior = d
	if _trava > 0.0:
		return
	if novo != 0 and not opcoes.is_empty():
		selecionada = wrapi(selecionada + novo, 0, opcoes.size())
		mensagem = ""
		_mostrar_selecionada()
	if ok:
		confirmar(selecionada)
	elif sair:
		fechar()


func _desenhar() -> void:
	var c: Control = desenho
	var f: Font = Fontes.texto()
	var p: Font = Fontes.pequena()
	c.draw_string(f, Vector2(PAINEL.position.x + 14, 34), titulo.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, Fontes.TAMANHO_TEXTO, cor_titulo)
	if subtitulo.is_valid():
		c.draw_string(p, Vector2(PAINEL.end.x - 214, 33), subtitulo.call(), HORIZONTAL_ALIGNMENT_RIGHT, 200, Fontes.TAMANHO_PEQUENA, COR_TEXTO)
	for i in range(primeira, mini(primeira + LINHAS_VISIVEIS, opcoes.size())):
		var o: Dictionary = opcoes[i]
		var r: Rect2 = retangulo_da_linha(i)
		var y: float = r.position.y
		if i == selecionada:
			c.draw_rect(r, Color(1, 1, 1, 0.07))
			c.draw_rect(r, cor_titulo, false, 1.0)
		var cor: Color = COR_TEXTO if o.get("pode", false) or o.get("ativo", false) else COR_APAGADO
		c.draw_string(f, Vector2(r.position.x + 6, y + 12), o["nome"], HORIZONTAL_ALIGNMENT_LEFT, -1, Fontes.TAMANHO_TEXTO, cor)
		c.draw_string(p, Vector2(r.position.x + 6, y + 23), o.get("descricao", ""), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 110, Fontes.TAMANHO_PEQUENA, COR_APAGADO if cor == COR_APAGADO else Color("a7adba"))
		c.draw_string(p, Vector2(r.end.x - 104, y + 12), o.get("direita", ""), HORIZONTAL_ALIGNMENT_RIGHT, 100, Fontes.TAMANHO_PEQUENA, cor_titulo if o.get("ativo", false) else cor)
	if not fala.is_empty():
		var y_fala: float = PAINEL.end.y - 27
		var nome: String = String(fala["nome"]).to_upper() + ": "
		c.draw_string(p, Vector2(PAINEL.position.x + 14, y_fala), nome, HORIZONTAL_ALIGNMENT_LEFT, -1, Fontes.TAMANHO_PEQUENA, fala["cor"])
		var largura_nome: float = p.get_string_size(nome, HORIZONTAL_ALIGNMENT_LEFT, -1, Fontes.TAMANHO_PEQUENA).x
		c.draw_string(p, Vector2(PAINEL.position.x + 14 + largura_nome, y_fala), fala["texto"], HORIZONTAL_ALIGNMENT_LEFT,
				PAINEL.size.x - 44 - largura_nome, Fontes.TAMANHO_PEQUENA, COR_TEXTO)
	if primeira > 0:
		c.draw_string(p, Vector2(PAINEL.end.x - 24, TOPO_LINHAS - 2), "▲", HORIZONTAL_ALIGNMENT_LEFT, -1, Fontes.TAMANHO_PEQUENA, cor_titulo)
	if primeira + LINHAS_VISIVEIS < opcoes.size():
		c.draw_string(p, Vector2(PAINEL.end.x - 24, TOPO_LINHAS + LINHAS_VISIVEIS * LINHA + 6), "▼", HORIZONTAL_ALIGNMENT_LEFT, -1, Fontes.TAMANHO_PEQUENA, cor_titulo)
	var rodape: String = mensagem if not mensagem.is_empty() else "Mouse ou setas: escolher · Clique, Atirar ou E: confirmar · Esc: sair"
	c.draw_string(p, Vector2(PAINEL.position.x + 14, PAINEL.end.y - 15), rodape, HORIZONTAL_ALIGNMENT_LEFT, -1, Fontes.TAMANHO_PEQUENA,
			Color("ff8a6a") if not mensagem.is_empty() else COR_APAGADO)
