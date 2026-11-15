class_name MelhoriasPermanentes
extends RefCounted
## Árvore Passiva (GD-07 §3, D-058: Vossa Margem, Núcleos, igual para todos os personagens) e
## desbloqueios (GD-03 §3.3, Ponte e Arsenal, Dados). Os níveis ficam no Progresso ("melhoria_<id>"), e os desbloqueios também
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


## Aplica a árvore Passiva no começo da run.
static func aplicar(jogador: Jogador, progresso: DadosProgresso) -> void:
	var blindagem: int = nivel("blindagem", progresso)
	if blindagem > 0:
		jogador.vida.reiniciar(jogador.vida.maxima + blindagem)
	var passada: int = nivel("passada", progresso)
	var pernas: int = nivel("pernas_de_mineiro", progresso)
	var propulsores: int = nivel("propulsores", progresso)
	if passada > 0 or pernas > 0 or propulsores > 0:
		jogador.parametros = jogador.parametros.duplicate()
		jogador.parametros.velocidade_corrida *= 1.0 + 0.05 * passada
		jogador.parametros.altura_pulo *= 1.0 + 0.06 * pernas
		jogador.parametros.recarga_dash = maxf(jogador.parametros.recarga_dash - 0.1 * propulsores, 0.05)
	jogador.creditos += 30 * nivel("contato_mercado", progresso)
	jogador.rerolls = nivel("recalibrar", progresso)
	jogador.retornos = nivel("sinal_emergencia", progresso)


## Memória da Âncora: +10% de XP por nível.
static func mult_xp(progresso: DadosProgresso) -> float:
	return 1.0 + 0.1 * nivel("memoria_da_ancora", progresso)


## Coleta Fina: +10% de Núcleos por nível.
static func mult_nucleos(progresso: DadosProgresso) -> float:
	return 1.0 + 0.1 * nivel("coleta_fina", progresso)
