class_name TelaGambiarras
extends CanvasLayer
## Escolha de Gambiarra (GD-07 §5.1): 3 cartas, 1 clique, sem tempo-limite e com o jogo
## pausado. Recalibrar (árvore Passiva) troca as 3 cartas, gastando 1 reroll da run.
## Visual provisório no estilo dos menus (EstiloMenu) até a ART entregar a tela (ART-3).

signal fechou(escolhida: ModificadorArma)

const TELA: Vector2 = Vector2(480, 270)
const TAMANHO_CARTA: Vector2 = Vector2(132, 124)
const ESPACO: float = 12.0
const Y_CARTAS: float = 70.0
const CORES_RARIDADE: Array[Color] = [Color("c9c3cf"), Color("7fb6ff"), Color("f2a65a")]
const COR_ESCURECER: Color = Color(0.03, 0.02, 0.05, 0.7)

var jogador: Jogador
var opcoes: Array[ModificadorArma] = []
## Sorteia de novo as opções (Recalibrar). Recebe nada, devolve Array[ModificadorArma].
var ao_recalibrar: Callable

var _raiz: Control
var _cartas: Array[Button] = []
var _botao_recalibrar: Button
var _seletor: TextureRect
var _aberta: bool = false
var _pausou: bool = false
var _titulo_atual: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 40
	visible = false


func esta_aberta() -> bool:
	return _aberta


## Abre com as opções já sorteadas. Devolve false se não houver opção.
func abrir(j: Jogador, lista: Array[ModificadorArma], titulo: String = "GAMBIARRA") -> bool:
	if lista.is_empty() or _aberta:
		return false
	jogador = j
	opcoes = lista
	_aberta = true
	_pausou = not get_tree().paused
	get_tree().paused = true
	visible = true
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	_montar(titulo)
	return true


func escolher(indice: int) -> void:
	if not _aberta or indice < 0 or indice >= opcoes.size():
		return
	var m: ModificadorArma = opcoes[indice]
	if jogador != null and jogador.arma_equipada != null:
		jogador.arma_equipada.adicionar(m)
		jogador.controle_arma.reiniciar_carregador()
	_fechar()
	fechou.emit(m)


## Troca as 3 cartas gastando 1 reroll. Devolve false sem rerolls.
func recalibrar() -> bool:
	if not _aberta or jogador == null or jogador.rerolls <= 0 or not ao_recalibrar.is_valid():
		return false
	var novas: Array[ModificadorArma] = []
	novas.assign(ao_recalibrar.call())
	if novas.is_empty():
		return false
	jogador.rerolls -= 1
	opcoes = novas
	_montar(_titulo_atual)
	return true


func textos_das_cartas() -> Array[String]:
	var lista: Array[String] = []
	for m in opcoes:
		lista.append(m.nome)
	return lista


func _fechar() -> void:
	_aberta = false
	visible = false
	if _raiz != null:
		_raiz.queue_free()
		_raiz = null
	_cartas.clear()
	if _pausou:
		get_tree().paused = false
	if jogador != null and jogador.entrada is EntradaLocal:
		Input.set_default_cursor_shape(Input.CURSOR_CROSS)


func _montar(titulo: String) -> void:
	_titulo_atual = titulo
	if _raiz != null:
		_raiz.queue_free()
	_cartas.clear()
	_raiz = Control.new()
	_raiz.size = TELA
	_raiz.theme = EstiloMenu.tema()
	add_child(_raiz)
	var fundo := ColorRect.new()
	fundo.color = COR_ESCURECER
	fundo.mouse_filter = Control.MOUSE_FILTER_STOP
	_raiz.add_child(fundo)
	fundo.size = TELA
	var nome_arma: String = jogador.arma_equipada.nome() if jogador != null and jogador.arma_equipada != null else ""
	EstiloMenu.titulo(_raiz, titulo, TELA.x, 30.0)
	EstiloMenu.rotulo(_raiz, "Melhoria da %s só nesta run" % nome_arma, Rect2(0, 48, TELA.x, 10),
			Fontes.TAMANHO_TEXTO, EstiloMenu.COR_DICA, true)
	var largura: float = opcoes.size() * TAMANHO_CARTA.x + (opcoes.size() - 1) * ESPACO
	var x: float = roundf((TELA.x - largura) * 0.5)
	for i in opcoes.size():
		_cartas.append(_carta(opcoes[i], Rect2(Vector2(x, Y_CARTAS), TAMANHO_CARTA), i))
		x += TAMANHO_CARTA.x + ESPACO
	_botao_recalibrar = null
	if jogador != null and jogador.rerolls > 0 and ao_recalibrar.is_valid():
		_botao_recalibrar = EstiloMenu.botao(_raiz, "Recalibrar (%d)" % jogador.rerolls,
				Rect2(roundf((TELA.x - 110) * 0.5), 206, 110, 14), func() -> void: recalibrar(), Fontes.TAMANHO_TEXTO)
	_seletor = EstiloMenu.seletor()
	_raiz.add_child(_seletor)
	if not _cartas.is_empty():
		_focar.call_deferred(_cartas[0])


func _carta(m: ModificadorArma, ret: Rect2, indice: int) -> Button:
	var b: Button = EstiloMenu.botao(_raiz, "", ret, escolher.bind(indice))
	b.name = "Carta%d" % indice
	var cor: Color = CORES_RARIDADE[m.raridade]
	var nome: Label = EstiloMenu.rotulo(b, m.nome, Rect2(6, 8, ret.size.x - 12, 14), Fontes.TAMANHO_BOTAO,
			EstiloMenu.COR_TEXTO, true)
	nome.clip_text = true
	nome.add_theme_font_override("font", Fontes.placa())
	EstiloMenu.rotulo(b, BancoGambiarras.NOMES_RARIDADE[m.raridade], Rect2(6, 26, ret.size.x - 12, 9),
			Fontes.TAMANHO_PEQUENA, cor, true)
	var desc: Label = EstiloMenu.rotulo(b, m.descricao, Rect2(8, 40, ret.size.x - 16, 66),
			Fontes.TAMANHO_PEQUENA, EstiloMenu.COR_TEXTO, true, true)
	desc.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	if m.maximo > 1 and jogador != null:
		var tem: int = jogador.arma_equipada.acumulos(m.id)
		EstiloMenu.rotulo(b, "%d/%d" % [tem + 1, m.maximo], Rect2(6, ret.size.y - 14, ret.size.x - 12, 9),
				Fontes.TAMANHO_PEQUENA, EstiloMenu.COR_DICA, true)
	# Faixa da raridade no topo da carta.
	var faixa := ColorRect.new()
	faixa.color = cor
	faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(faixa)
	faixa.position = Vector2(4, 3)
	faixa.size = Vector2(ret.size.x - 8, 2)
	return b


func _process(_delta: float) -> void:
	if not _aberta or _seletor == null:
		return
	var foco := get_viewport().gui_get_focus_owner() as Button
	var mostrar: bool = foco != null and (_cartas.has(foco) or foco == _botao_recalibrar)
	EstiloMenu.posicionar_seletor(_seletor, foco if mostrar else null)


func _focar(botao: Variant) -> void:
	if not is_instance_valid(botao):
		return
	var b := botao as Button
	if b != null and b.is_visible_in_tree():
		b.grab_focus()
