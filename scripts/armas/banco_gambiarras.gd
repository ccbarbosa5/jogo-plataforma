class_name BancoGambiarras
extends RefCounted
## Banco de Gambiarras de cada arma (GD-07 §5), lido de data/armas/gambiarras.json.
## Cada Gambiarra vira um ModificadorArma (raridade, máximo de acúmulos, números e marcadores).
## Sorteio: 3 opções diferentes da arma em uso; Comum 65% · Rara 28% · Épica 7%; uma única já
## pega não volta; uma acumulável no máximo não volta; sala Elite garante 1 Rara ou melhor.

const CAMINHO: String = "res://data/armas/gambiarras.json"
const RARIDADES: Dictionary = {
	"comum": ModificadorArma.Raridade.COMUM,
	"rara": ModificadorArma.Raridade.RARA,
	"epica": ModificadorArma.Raridade.EPICA,
}
const NOMES_RARIDADE: Array[String] = ["Comum", "Rara", "Épica"]
## Campos numéricos copiados do JSON para o ModificadorArma.
const CAMPOS: Array[String] = [
	"mult_dano", "mult_cadencia", "mult_velocidade_projetil", "mult_duracao_projetil",
	"mult_tamanho_projetil", "soma_dano", "soma_projeteis_por_tiro", "soma_espalhamento_graus",
	"soma_perfuracoes", "soma_ricochetes", "soma_queda_px",
]

## arma -> Array[ModificadorArma]
var por_arma: Dictionary = {}
## Chances por raridade (índice = ModificadorArma.Raridade).
var chances: Array[float] = [65.0, 28.0, 7.0]


func _init(caminho: String = CAMINHO) -> void:
	carregar(caminho)


func carregar(caminho: String) -> void:
	var texto: String = FileAccess.get_file_as_string(caminho)
	var dados: Variant = JSON.parse_string(texto)
	if not dados is Dictionary:
		push_error("BancoGambiarras: não deu para ler %s" % caminho)
		return
	var c: Dictionary = dados.get("chances", {})
	chances = [float(c.get("comum", 65)), float(c.get("rara", 28)), float(c.get("epica", 7))]
	for chave: String in dados:
		if chave.begins_with("_") or chave == "chances":
			continue
		var lista: Array[ModificadorArma] = []
		for item: Dictionary in dados[chave]:
			lista.append(_criar(StringName(chave), item))
		por_arma[StringName(chave)] = lista


func _criar(arma: StringName, item: Dictionary) -> ModificadorArma:
	var m := ModificadorArma.new()
	m.id = StringName(item["id"])
	m.nome = item["nome"]
	m.descricao = item.get("descricao", "")
	m.raridade = RARIDADES.get(item.get("raridade", "comum"), ModificadorArma.Raridade.COMUM)
	m.maximo = int(item.get("maximo", 1))
	m.arma = arma
	for campo in CAMPOS:
		if item.has(campo):
			m.set(campo, item[campo])
	var marcadores: Array[StringName] = []
	for marcador in item.get("marcadores", []):
		marcadores.append(StringName(marcador))
	m.marcadores = marcadores
	return m


func todas(arma: StringName) -> Array[ModificadorArma]:
	var lista: Array[ModificadorArma] = []
	lista.assign(por_arma.get(arma, []))
	return lista


## Gambiarras da arma que ainda podem sair (únicas não pegas, acumuláveis abaixo do máximo).
func disponiveis(equipada: ArmaEquipada) -> Array[ModificadorArma]:
	var lista: Array[ModificadorArma] = []
	if equipada == null or equipada.base == null:
		return lista
	for m in todas(equipada.base.id):
		if equipada.acumulos(m.id) < m.maximo:
			lista.append(m)
	return lista


## Sorteia até 3 opções diferentes. `elite`: pelo menos 1 Rara ou melhor.
## `so_comuns`: só Comuns (Treino com Garrak, no começo da run).
func sortear(equipada: ArmaEquipada, rng: RandomNumberGenerator, elite: bool = false,
		so_comuns: bool = false, quantas: int = 3) -> Array[ModificadorArma]:
	var restantes: Array[ModificadorArma] = disponiveis(equipada)
	if so_comuns:
		restantes = restantes.filter(func(m: ModificadorArma) -> bool: return m.raridade == ModificadorArma.Raridade.COMUM)
	var escolhidas: Array[ModificadorArma] = []
	while escolhidas.size() < quantas and not restantes.is_empty():
		var raridade: int = _sortear_raridade(rng)
		var da_raridade: Array[ModificadorArma] = restantes.filter(func(m: ModificadorArma) -> bool: return m.raridade == raridade)
		var fonte: Array[ModificadorArma] = da_raridade if not da_raridade.is_empty() else restantes
		var m: ModificadorArma = fonte[rng.randi_range(0, fonte.size() - 1)]
		escolhidas.append(m)
		restantes.erase(m)
	if elite and not so_comuns and not escolhidas.is_empty():
		var tem_rara: bool = escolhidas.any(func(m: ModificadorArma) -> bool: return m.raridade != ModificadorArma.Raridade.COMUM)
		var raras: Array[ModificadorArma] = restantes.filter(func(m: ModificadorArma) -> bool: return m.raridade != ModificadorArma.Raridade.COMUM)
		if not tem_rara and not raras.is_empty():
			escolhidas[rng.randi_range(0, escolhidas.size() - 1)] = raras[rng.randi_range(0, raras.size() - 1)]
	return escolhidas


func _sortear_raridade(rng: RandomNumberGenerator) -> int:
	var total: float = chances[0] + chances[1] + chances[2]
	var x: float = rng.randf() * total
	for i in 3:
		x -= chances[i]
		if x < 0.0:
			return i
	return 0
