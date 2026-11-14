class_name GeradorAto
extends RefCounted
## Planeja as salas do Ato 1 (GD-01 §7.3 e GD-03 §2): o mapa fixa a ordem e o tipo de cada
## sala; sorteiam-se os blocos (sem repetir trecho nem arena na run), as ondas (orçamento de
## ameaça) e as recompensas das portas. Só planeja (dados); quem monta os nós é o MontadorSala.

const ARQUIVO_MAPA: String = "res://data/salas/mapa_ato1.json"

var blocos: BancoBlocos = BancoBlocos.new()
var ondas: BancoOndas = BancoOndas.new()
var mapa: Array[Dictionary] = []
var recompensas: Dictionary = {}
var estado: EstadoAto = EstadoAto.new()
var progresso: DadosProgresso
var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _init(progresso_: DadosProgresso = null, semente: int = -1) -> void:
	progresso = progresso_
	blocos.carregar()
	ondas.carregar()
	var dados: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ARQUIVO_MAPA))
	for s: Dictionary in dados["salas"]:
		mapa.append(s)
	recompensas = dados.get("recompensas", {})
	if semente >= 0:
		rng.seed = semente
	else:
		rng.randomize()
	estado.primeira_run = progresso != null and not progresso.tem_flag("queda_completa_vista")


func quantidade_de_salas() -> int:
	return mapa.size()


func info_sala(numero: int) -> Dictionary:
	return mapa[numero]


## Plano da sala: {numero, tipo, nome, bioma, blocos, ondas, elite, portas}.
func planejar_sala(numero: int) -> Dictionary:
	var info: Dictionary = mapa[numero]
	var tipo: String = info["tipo"]
	var plano: Dictionary = {"numero": numero, "nome": info.get("nome", ""), "bioma": info["bioma"],
			"tipo": tipo, "blocos": [], "ondas": [], "elite": false, "portas": []}
	var lista: Array[String] = []
	match tipo:
		"queda":
			lista.append("queda_capsula")
			if estado.primeira_run:
				lista.append_array(["queda_tutorial_degraus", "queda_tutorial_tiro", "queda_tutorial_grilhao", "queda_tutorial_dash"])
				plano["ondas"] = [_onda("guerreiro_soldado")]
			else:
				lista.append(_sortear_bloco("queda", "trecho"))
				plano["ondas"] = ondas.planejar(int(info["orcamento"]), "queda", rng, 1, 1)
			lista.append_array(["queda_arena", "saida_varrek"])
		"combate", "elite":
			var elite: bool = tipo == "elite" or rng.randf() < float(info.get("chance_elite", 0.0))
			plano["elite"] = elite
			lista.append("entrada_varrek")
			var bioma_trechos: String = info.get("bioma_trechos", info["bioma"])
			var n: int = rng.randi_range(1, 3)
			for i in n:
				var t: String = _sortear_bloco(bioma_trechos, "trecho")
				if not t.is_empty():
					lista.append(t)
			var arena: String = _sortear_bloco("elite" if elite else info["bioma"], "arena")
			if arena.is_empty():
				arena = _sortear_bloco(info["bioma"], "arena")
			lista.append(arena)
			lista.append("saida_varrek")
			var plano_ondas: Array[Dictionary] = []
			if elite:
				plano_ondas.append(ondas.onda_elite(rng))
			plano_ondas.append_array(ondas.planejar(int(info["orcamento"]), info["bioma"], rng))
			plano["ondas"] = plano_ondas
		"loja_ou_reparo":
			var loja: bool = rng.randf() < 0.5
			plano["tipo"] = "loja" if loja else "reparo"
			plano["nome"] = "Loja Ilo" if loja else "Reparo"
			lista.append_array(["entrada_varrek", "loja_varrek" if loja else "reparo_varrek", "saida_varrek"])
		"reparo":
			lista.append_array(["entrada_varrek", "reliquia_aproximacao", "reliquia_reparo", "saida_varrek"])
		"chefe":
			lista.append_array(["entrada_varrek", "chefe_arena"])
			var plano_chefe: Array[Dictionary] = [ondas.onda_elite(rng)]
			plano_chefe.append_array(ondas.planejar(int(info["orcamento"]), "chefe", rng))
			plano["ondas"] = plano_chefe
	plano["blocos"] = lista
	# Portas da saída.
	if tipo == "chefe":
		plano["portas"] = []
	elif numero == mapa.size() - 2:
		plano["portas"] = ["chefe"]  # sala 7 leva direto ao chefe
	else:
		var pesos: Dictionary = recompensas.get("pesos", {})
		plano["portas"] = RegrasRecompensas.sortear(numero, estado, rng, pesos, -1,
				int(recompensas.get("vida_maxima_a_partir_da_sala", 3)))
	return plano


func _onda(id: String) -> Dictionary:
	for o in ondas.ondas:
		if o["id"] == id:
			return o
	return {}


## Sorteia um bloco do bioma e tipo ainda não usado na run e o marca como usado.
func _sortear_bloco(bioma: String, tipo: String) -> String:
	var lista: Array[String] = blocos.disponiveis(bioma, tipo, progresso, estado.blocos_usados)
	if lista.is_empty():
		return ""
	var id: String = lista[rng.randi_range(0, lista.size() - 1)]
	estado.blocos_usados.append(id)
	return id


## Valor sorteado de uma recompensa de quantidade (Créditos, Núcleos, Dados).
func valor_recompensa(tipo: String) -> int:
	var faixa: Array = recompensas.get(tipo, [0, 0])
	return rng.randi_range(int(faixa[0]), int(faixa[1]))
