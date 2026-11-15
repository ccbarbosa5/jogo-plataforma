class_name ProgressaoPersonagem
extends RefCounted
## Progressão permanente de um personagem (GD-07 §4, D-058): XP, nível e árvore de Combate.
## Dados em data/progressao/<personagem>.json. O XP total fica no Progresso ("xp_<personagem>")
## e os nós comprados viram flags ("combate_<id>"). A morte não tira nada.
## Regras da árvore: só abre na nave; nós de cada ramo em ordem; custo por nó (1, 1, 2, 2, Ápice 3);
## no máximo 2 Ápices; 1 ponto por nível; redistribuir é grátis; o ramo da arma que não foi
## levada fica inativo na run.

enum Estado { COMPRADO, DISPONIVEL, SEM_PONTOS, TRANCADO, LIMITE_APICES }

const PASTA: String = "res://data/progressao/"

var personagem: String
var xp: Dictionary = {}
var ramos: Array = []
var maximo_apices: int = 2
## id do nó -> {"no": Dictionary, "ramo": Dictionary, "indice": int}
var _nos: Dictionary = {}


func _init(personagem_: String = "ryker") -> void:
	personagem = personagem_
	var dados: Variant = JSON.parse_string(FileAccess.get_file_as_string(PASTA + personagem + ".json"))
	if not dados is Dictionary:
		push_error("ProgressaoPersonagem: não deu para ler %s" % personagem)
		return
	xp = dados["xp"]
	ramos = dados["combate"]["ramos"]
	maximo_apices = int(dados["combate"].get("maximo_apices", 2))
	for ramo: Dictionary in ramos:
		var nos: Array = ramo["nos"]
		for i in nos.size():
			_nos[StringName(nos[i]["id"])] = {"no": nos[i], "ramo": ramo, "indice": i}


# --- XP e nível ---

func chave_xp() -> String:
	return "xp_" + personagem


## XP para subir do nível n para n+1: 60 + 20 × n.
func xp_para_subir(n: int) -> int:
	return int(xp["base"]) + int(xp["por_nivel"]) * n


func nivel_maximo() -> int:
	return int(xp["nivel_maximo"])


func xp_total(progresso: DadosProgresso) -> int:
	return progresso.valor(chave_xp())


## Nível a partir do XP total (começa no 1).
func nivel_de(total: int) -> int:
	var n: int = 1
	var resto: int = total
	while n < nivel_maximo() and resto >= xp_para_subir(n):
		resto -= xp_para_subir(n)
		n += 1
	return n


func nivel(progresso: DadosProgresso) -> int:
	return nivel_de(xp_total(progresso))


## [XP dentro do nível atual, XP para o próximo] (no máximo: [0, 0]).
func xp_no_nivel(progresso: DadosProgresso) -> Vector2i:
	var n: int = 1
	var resto: int = xp_total(progresso)
	while n < nivel_maximo() and resto >= xp_para_subir(n):
		resto -= xp_para_subir(n)
		n += 1
	return Vector2i(resto, xp_para_subir(n)) if n < nivel_maximo() else Vector2i.ZERO


## Soma XP (já com bônus). Devolve quantos níveis subiu.
func ganhar_xp(progresso: DadosProgresso, valor: int) -> int:
	if valor <= 0:
		return 0
	var antes: int = nivel(progresso)
	progresso.incrementar(chave_xp(), valor)
	return nivel(progresso) - antes


## XP que o inimigo vale (GD-07 §4.1): pela cena; senão pela categoria.
func xp_do_inimigo(inimigo: Inimigo) -> int:
	var tabela: Dictionary = xp["por_inimigo"]
	var nome: String = inimigo.scene_file_path.get_file().get_basename()
	if tabela.has(nome):
		return int(tabela[nome])
	match inimigo.categoria:
		Inimigo.Categoria.ELITE:
			return int(xp["elite"])
		Inimigo.Categoria.CHEFE:
			return int(xp["chefe"])
	return int(xp.get("padrao", 4))


# --- Árvore de Combate ---

func pontos_totais(progresso: DadosProgresso) -> int:
	return nivel(progresso) - 1


func comprado(id: StringName, progresso: DadosProgresso) -> bool:
	return progresso.tem_flag("combate_" + String(id))


func no(id: StringName) -> Dictionary:
	return _nos[id]["no"] if _nos.has(id) else {}


func ramo_do(id: StringName) -> Dictionary:
	return _nos[id]["ramo"] if _nos.has(id) else {}


func custo(id: StringName) -> int:
	return int(no(id).get("custo", 1))


func e_apice(id: StringName) -> bool:
	return no(id).get("apice", false)


func comprados(progresso: DadosProgresso) -> Array[StringName]:
	var lista: Array[StringName] = []
	for id: StringName in _nos:
		if comprado(id, progresso):
			lista.append(id)
	return lista


func pontos_gastos(progresso: DadosProgresso) -> int:
	var total: int = 0
	for id in comprados(progresso):
		total += custo(id)
	return total


func pontos_livres(progresso: DadosProgresso) -> int:
	return pontos_totais(progresso) - pontos_gastos(progresso)


func apices(progresso: DadosProgresso) -> int:
	var n: int = 0
	for id in comprados(progresso):
		if e_apice(id):
			n += 1
	return n


func estado(id: StringName, progresso: DadosProgresso) -> Estado:
	if comprado(id, progresso):
		return Estado.COMPRADO
	var info: Dictionary = _nos.get(id, {})
	if info.is_empty():
		return Estado.TRANCADO
	if info["indice"] > 0:
		var anterior: StringName = StringName(info["ramo"]["nos"][info["indice"] - 1]["id"])
		if not comprado(anterior, progresso):
			return Estado.TRANCADO
	if e_apice(id) and apices(progresso) >= maximo_apices:
		return Estado.LIMITE_APICES
	if pontos_livres(progresso) < custo(id):
		return Estado.SEM_PONTOS
	return Estado.DISPONIVEL


func comprar(id: StringName, progresso: DadosProgresso) -> bool:
	if estado(id, progresso) != Estado.DISPONIVEL:
		return false
	progresso.definir_flag("combate_" + String(id))
	progresso.salvar()
	return true


## Devolve todos os pontos (grátis, entre as runs).
func redistribuir(progresso: DadosProgresso) -> void:
	for id in comprados(progresso):
		progresso.definir_flag("combate_" + String(id), false)
	progresso.salvar()


## Começo da run: nós do ramo da arma levada viram modificadores permanentes da arma;
## os outros (Granada, Grilhão, Dash) entram em Jogador.nos_combate e mudam os números.
func aplicar(jogador: Jogador, progresso: DadosProgresso) -> void:
	var arma_id: String = String(jogador.arma.id) if jogador.arma != null else ""
	for id in comprados(progresso):
		var ramo: Dictionary = ramo_do(id)
		if ramo.has("arma"):
			if ramo["arma"] == arma_id:
				jogador.arma_equipada.adicionar_permanente(_modificador(id))
			continue
		if not id in jogador.nos_combate:
			jogador.nos_combate.append(id)
	_aplicar_numeros(jogador)
	jogador.controle_arma.reiniciar_carregador()


func _modificador(id: StringName) -> ModificadorArma:
	var dados: Dictionary = no(id).get("modificador", {})
	var m := ModificadorArma.new()
	m.id = id
	m.nome = no(id)["nome"]
	m.descricao = no(id)["descricao"]
	for campo: String in dados:
		if campo == "marcadores":
			var marcadores: Array[StringName] = []
			for marcador in dados[campo]:
				marcadores.append(StringName(marcador))
			m.marcadores = marcadores
		else:
			m.set(campo, dados[campo])
	return m


## Números da Granada e do Dash (GD-07 §4.3).
func _aplicar_numeros(jogador: Jogador) -> void:
	if jogador.granada != null and (jogador.tem_no(&"granada_cinto") or jogador.tem_no(&"granada_pavio_curto")):
		jogador.granada = jogador.granada.duplicate()
		if jogador.tem_no(&"granada_cinto"):
			jogador.granada.por_sala += 1
		if jogador.tem_no(&"granada_pavio_curto"):
			jogador.granada.raio *= 1.25
		jogador.reabastecer_granadas()
	if jogador.tem_no(&"dash_passo_leve") or jogador.tem_no(&"dash_duplo"):
		jogador.parametros = jogador.parametros.duplicate()
		if jogador.tem_no(&"dash_passo_leve"):
			jogador.parametros.recarga_dash = maxf(jogador.parametros.recarga_dash - 0.15, 0.05)
		if jogador.tem_no(&"dash_duplo"):
			jogador.parametros.cargas_dash += 1
		jogador.cargas_dash = jogador.parametros.cargas_dash
