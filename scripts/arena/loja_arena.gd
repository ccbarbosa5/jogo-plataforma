class_name LojaArena
extends CanvasLayer
## Loja do Ilo entre as ondas (GD-09 §7). Protótipo: só armas, 4 ofertas, reroll e "Pronto".
## Comprar e rerolar gastam a Sucata da arena; a arma vai para o inventário do Ryker.

signal terminou

const NOMES_NIVEL: Array[String] = ["I", "II", "III", "IV"]
const TELA: Vector2 = Vector2(480, 270)

var arena: ArenaJogo
var onda: int = 1
## Cada oferta: {"id": String, "nivel": int, "preco": int, "vendida": bool}
var ofertas: Array[Dictionary] = []
var rerolls: int = 0
var rng := RandomNumberGenerator.new()

var _dados: Dictionary = ConfigArena.secao("loja")
var _raiz: Control
var _rotulo: Label
var _botoes: Array[Button] = []
var _botao_reroll: Button


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_montar()
	visible = false


## Abre a loja depois da onda `onda_` (1, 2, ...).
func abrir(onda_: int) -> void:
	onda = onda_
	rerolls = 0
	sortear_ofertas()
	visible = true
	_atualizar()
	_botoes[0].grab_focus.call_deferred()


func fechar() -> void:
	visible = false
	terminou.emit()


static func preco(nivel: int, onda_: int) -> int:
	var base: Array = ConfigArena.secao("niveis_arma")["preco_base"]
	var aumento: float = float(ConfigArena.secao("loja")["aumento_preco_por_onda"])
	return roundi(float(base[nivel - 1]) * (1.0 + aumento * (onda_ - 1)))


func custo_reroll() -> int:
	return 1 + onda + rerolls


## Chance de cada nível (I..IV) na onda: vai em linha reta da onda 1 à onda 20.
static func chances(onda_: int) -> Array[float]:
	var d: Dictionary = ConfigArena.secao("loja")
	var inicio: Array = d["raridade_onda_1"]
	var fim: Array = d["raridade_onda_20"]
	var t: float = clampf((onda_ - 1) / 19.0, 0.0, 1.0)
	var lista: Array[float] = []
	for i in 4:
		lista.append(lerpf(float(inicio[i]), float(fim[i]), t))
	if onda_ < int(d["lendaria_a_partir_da_onda"]):
		lista[3] = 0.0
	return lista


func sortear_ofertas() -> void:
	ofertas.clear()
	var ids: Array = ConfigArena.secao("armas").keys()
	var pesos: Array[float] = chances(onda)
	for i in int(_dados["ofertas"]):
		var id: String = ids[rng.randi() % ids.size()]
		var nivel: int = rng.rand_weighted(PackedFloat32Array(pesos)) + 1
		ofertas.append({"id": id, "nivel": nivel, "preco": preco(nivel, onda), "vendida": false})


func pode_comprar(i: int) -> bool:
	var o: Dictionary = ofertas[i]
	return not o["vendida"] and arena.sucata >= int(o["preco"]) \
			and arena.jogador.inventario.pode_receber(String(o["id"]), int(o["nivel"]))


func comprar(i: int) -> bool:
	if not pode_comprar(i):
		return false
	var o: Dictionary = ofertas[i]
	arena.gastar_sucata(int(o["preco"]))
	arena.jogador.adicionar_arma(String(o["id"]), int(o["nivel"]))
	o["vendida"] = true
	_atualizar()
	return true


func rerolar() -> bool:
	var custo: int = custo_reroll()
	if arena.sucata < custo:
		return false
	arena.gastar_sucata(custo)
	rerolls += 1
	sortear_ofertas()
	_atualizar()
	return true


func _montar() -> void:
	_raiz = Control.new()
	_raiz.size = TELA
	_raiz.theme = EstiloMenu.tema()
	add_child(_raiz)
	var fundo := ColorRect.new()
	fundo.color = Color(0.03, 0.02, 0.05, 0.8)
	fundo.size = TELA
	_raiz.add_child(fundo)
	var titulo := Label.new()
	titulo.text = "LOJA DO ILO"
	titulo.add_theme_font_override("font", Fontes.placa())
	titulo.add_theme_font_size_override("font_size", Fontes.TAMANHO_TITULO)
	titulo.position = Vector2(20, 16)
	_raiz.add_child(titulo)
	_rotulo = Label.new()
	_rotulo.add_theme_font_size_override("font_size", Fontes.TAMANHO_TEXTO)
	_rotulo.position = Vector2(20, 36)
	_raiz.add_child(_rotulo)
	for i in int(_dados["ofertas"]):
		var ret := Rect2(20 + i * 112, 70, 104, 60)
		_botoes.append(EstiloMenu.botao(_raiz, "", ret, func() -> void: comprar(i), Fontes.TAMANHO_TEXTO))
	_botao_reroll = EstiloMenu.botao(_raiz, "", Rect2(20, 220, 140, 16), func() -> void: rerolar())
	EstiloMenu.botao(_raiz, "Pronto", Rect2(360, 220, 100, 16), fechar)


func _atualizar() -> void:
	if arena == null:
		return
	_rotulo.text = "Sucata: %d    Onda %d terminada    Armas: %d/%d" % [
		arena.sucata, onda, arena.jogador.inventario.armas.size(), arena.jogador.inventario.slots]
	for i in _botoes.size():
		var b: Button = _botoes[i]
		if i >= ofertas.size():
			b.visible = false
			continue
		var o: Dictionary = ofertas[i]
		var nome: String = String(ConfigArena.arma(String(o["id"]))["nome"])
		b.text = "Vendida" if o["vendida"] else "%s %s\n%d Sucata" % [nome, NOMES_NIVEL[int(o["nivel"]) - 1], o["preco"]]
		b.disabled = not pode_comprar(i)
	_botao_reroll.text = "Trocar ofertas (%d)" % custo_reroll()
	_botao_reroll.disabled = arena.sucata < custo_reroll()
