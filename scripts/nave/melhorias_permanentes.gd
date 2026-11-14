class_name MelhoriasPermanentes
extends RefCounted
## Melhorias permanentes (GD-01 §9.2, Vossa Margem, Núcleos) e desbloqueios (GD-03 §3.3, Ponte e
## Arsenal, Dados). Os níveis ficam no Progresso ("melhoria_<id>"), e os desbloqueios também
## ligam a flag que o resto do jogo consulta (treino_garrak, arquivo_kharn, rotas_varrek_1...).

const ARQUIVO: String = "res://data/nave/melhorias.json"
const NOMES_MOEDA: Dictionary = {"nucleos": "Núcleos", "dados": "Dados"}

var itens: Array[Dictionary] = []


func _init() -> void:
	var dados: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ARQUIVO))
	for i: Dictionary in dados["melhorias"]:
		itens.append(i)


func item(id: String) -> Dictionary:
	for i in itens:
		if i["id"] == id:
			return i
	return {}


func do_lugar(onde: String) -> Array[Dictionary]:
	var lista: Array[Dictionary] = []
	for i in itens:
		if i["onde"] == onde:
			lista.append(i)
	return lista


static func nivel(id: String, progresso: DadosProgresso) -> int:
	return progresso.valor("melhoria_" + id)


func maximo(id: String) -> int:
	return item(id).get("custos", []).size()


## Custo do próximo nível (−1 = já no máximo).
func custo(id: String, progresso: DadosProgresso) -> int:
	var custos: Array = item(id).get("custos", [])
	var n: int = nivel(id, progresso)
	return int(custos[n]) if n < custos.size() else -1


func bloqueado(id: String, progresso: DadosProgresso) -> bool:
	var requer: String = item(id).get("requer", "")
	return not requer.is_empty() and nivel(requer, progresso) == 0


func pode_comprar(id: String, progresso: DadosProgresso) -> bool:
	var c: int = custo(id, progresso)
	return c >= 0 and not bloqueado(id, progresso) and progresso.valor(item(id)["moeda"]) >= c


func comprar(id: String, progresso: DadosProgresso) -> bool:
	if not pode_comprar(id, progresso):
		return false
	var i: Dictionary = item(id)
	progresso.incrementar(i["moeda"], -custo(id, progresso))
	progresso.incrementar("melhoria_" + id)
	if i.has("flag"):
		progresso.definir_flag(i["flag"])
	progresso.salvar()
	return true


## Aplica as melhorias de Núcleos no começo da run.
static func aplicar(jogador: Jogador, progresso: DadosProgresso) -> void:
	var blindagem: int = nivel("blindagem", progresso)
	if blindagem > 0:
		jogador.vida.reiniciar(jogador.vida.maxima + blindagem)
	var cinto: int = nivel("cinto_granadas", progresso)
	if cinto > 0 and jogador.granada != null:
		jogador.granada = jogador.granada.duplicate()
		jogador.granada.por_sala += cinto
		jogador.reabastecer_granadas()
	var propulsores: int = nivel("propulsores", progresso)
	if propulsores > 0:
		jogador.parametros = jogador.parametros.duplicate()
		jogador.parametros.cargas_dash += propulsores
		jogador.cargas_dash = jogador.parametros.cargas_dash
	jogador.creditos += 30 * nivel("contato_mercado", progresso)
	jogador.rerolls = nivel("recalibrar", progresso)
	jogador.retornos = nivel("sinal_emergencia", progresso)
