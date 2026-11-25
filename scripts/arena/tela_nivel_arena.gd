class_name TelaNivelArena
extends CanvasLayer
## Tela de nível (GD-09 §6.2): no fim da onda, para cada nível ganho, 4 atributos sorteados e o
## jogador escolhe 1 (clique ou E, D-066). Trocar as cartas custa Sucata (2, depois +2 a cada vez).

signal terminou

const NOMES_RARIDADE: Array[String] = ["Comum", "Rara", "Épica", "Lendária"]
## Cores de raridade/nível (ART-02 §4).
const CORES_RARIDADE: Array[Color] = [Color("9d9175"), Color("6a8fc4"), Color("9a5ec4"), Color("c43a3a")]
const TELA: Vector2 = Vector2(480, 270)

var arena: ArenaJogo
## Cada carta: {"id": String, "raridade": int (0..3), "valor": float}
var cartas: Array[Dictionary] = []
var rerolls: int = 0
var rng := RandomNumberGenerator.new()

var _dados: Dictionary = ConfigArena.secao("nivel")
var _botoes: Array[Button] = []
var _botao_reroll: Button
var _rotulo: Label


func _ready() -> void:
	layer = 21
	process_mode = Node.PROCESS_MODE_ALWAYS
	_montar()
	visible = false


func abrir() -> void:
	rerolls = 0
	sortear()
	visible = true
	_botoes[0].grab_focus.call_deferred()


func custo_reroll() -> int:
	return int(_dados["reroll_inicial"]) + int(_dados["reroll_aumento"]) * rerolls


## Chance de cada raridade: as melhores sobem um pouco a cada nível e com a Sorte.
func chances(nivel: int, sorte: float) -> Array[float]:
	var base: Array = _dados["raridade"]
	var extra: float = float(_dados["melhora_por_nivel"]) * (nivel - 1) + sorte
	var lista: Array[float] = [float(base[0]), float(base[1]), float(base[2]), float(base[3])]
	lista[1] += extra * 0.6
	lista[2] += extra * 0.3
	lista[3] = minf(lista[3] + extra * 0.1, float(_dados["lendaria_maxima"]))
	lista[0] = maxf(lista[0] - extra, 20.0)
	return lista


func sortear() -> void:
	cartas.clear()
	var ids: Array = ConfigArena.secao("atributos").keys()
	var j := arena.jogador
	var pesos := PackedFloat32Array(chances(j.nivel, j.atributos.valor("sorte")))
	while cartas.size() < int(_dados["cartas"]) and not ids.is_empty():
		var id: String = ids.pop_at(rng.randi() % ids.size())
		var r: int = rng.rand_weighted(pesos)
		cartas.append({"id": id, "raridade": r, "valor": float(ConfigArena.secao("atributos")[id]["valores"][r])})
	_atualizar()


func escolher(i: int) -> void:
	if i < 0 or i >= cartas.size():
		return
	var c: Dictionary = cartas[i]
	arena.jogador.aplicar_efeitos({c["id"]: c["valor"]})
	arena.jogador.niveis_pendentes = maxi(arena.jogador.niveis_pendentes - 1, 0)
	if arena.jogador.niveis_pendentes > 0:
		sortear()
	else:
		visible = false
		terminou.emit()


func rerolar() -> bool:
	var custo: int = custo_reroll()
	if arena.sucata < custo:
		return false
	arena.gastar_sucata(custo)
	rerolls += 1
	sortear()
	return true


static func texto_da_carta(c: Dictionary) -> String:
	var d: Dictionary = ConfigArena.secao("atributos")[c["id"]]
	return "%s\n%s\n%s" % [d["nome"], String(d["formato"]) % int(c["valor"]), NOMES_RARIDADE[int(c["raridade"])]]


func _montar() -> void:
	var raiz := Control.new()
	raiz.size = TELA
	raiz.theme = EstiloMenu.tema()
	add_child(raiz)
	var fundo := ColorRect.new()
	fundo.color = Color(0.03, 0.02, 0.05, 0.8)
	fundo.size = TELA
	raiz.add_child(fundo)
	var titulo := Label.new()
	titulo.text = "SUBIU DE NÍVEL"
	titulo.add_theme_font_override("font", Fontes.placa())
	titulo.add_theme_font_size_override("font_size", Fontes.TAMANHO_TITULO)
	titulo.position = Vector2(20, 16)
	raiz.add_child(titulo)
	_rotulo = Label.new()
	_rotulo.add_theme_font_size_override("font_size", Fontes.TAMANHO_TEXTO)
	_rotulo.position = Vector2(20, 36)
	raiz.add_child(_rotulo)
	for i in int(_dados["cartas"]):
		_botoes.append(EstiloMenu.botao(raiz, "", Rect2(20 + i * 112, 70, 104, 60), func() -> void: escolher(i), Fontes.TAMANHO_TEXTO))
	_botao_reroll = EstiloMenu.botao(raiz, "", Rect2(20, 220, 140, 16), func() -> void: rerolar())


func _atualizar() -> void:
	var j := arena.jogador
	_rotulo.text = "Nível %d    Sucata: %d    Escolha 1 atributo (faltam %d)" % [j.nivel, arena.sucata, j.niveis_pendentes]
	for i in _botoes.size():
		var b: Button = _botoes[i]
		b.visible = i < cartas.size()
		if b.visible:
			b.text = texto_da_carta(cartas[i])
			b.add_theme_color_override("font_color", CORES_RARIDADE[int(cartas[i]["raridade"])])
	_botao_reroll.text = "Trocar cartas (%d)" % custo_reroll()
	_botao_reroll.disabled = arena.sucata < custo_reroll()
