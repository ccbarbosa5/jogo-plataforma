extends TestCase
## Gambiarras (GD-07 §5, D-058): bancos de 12 por arma, sorteio por raridade, única não volta,
## acumulável respeita o máximo, Elite garante Rara, a tela de 3 cartas e quando ela aparece.

const MORDIDA: String = "res://scenes/armas/mordida.tres"
const BRAMIDO: String = "res://scenes/armas/bramido.tres"
const CENA_RUN: String = "res://scenes/run/run_ato1.tscn"

var _salvo: Dictionary = {}


func _equipada(arma: String = MORDIDA) -> ArmaEquipada:
	return ArmaEquipada.new(load(arma))


func _rng(semente: int = 7) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = semente
	return r


func _do_banco(banco: BancoGambiarras, arma: StringName, id: StringName) -> ModificadorArma:
	for m in banco.todas(arma):
		if m.id == id:
			return m
	return null


func _guardar() -> void:
	_salvo = {"flags": Progresso.flags.duplicate(), "contadores": Progresso.contadores.duplicate()}


func _restaurar() -> void:
	Progresso.flags = _salvo["flags"]
	Progresso.contadores = _salvo["contadores"]
	tree.paused = false


func _fechar_falas() -> void:
	var caixa := tree.get_first_node_in_group("caixa_dialogo") as CaixaDialogo
	var limite: int = 60
	while caixa != null and caixa.esta_ativa() and limite > 0:
		caixa.avancar()
		limite -= 1


func test_bancos_tem_12_por_arma_com_as_raridades_do_gd07() -> void:
	var banco := BancoGambiarras.new()
	for arma: StringName in [&"mordida", &"bramido"]:
		var lista: Array[ModificadorArma] = banco.todas(arma)
		afirmar_igual(lista.size(), 12, "%s: 12 Gambiarras" % arma)
		var por_raridade: Array[int] = [0, 0, 0]
		for m in lista:
			por_raridade[m.raridade] += 1
			afirmar(not m.nome.is_empty() and not m.descricao.is_empty(), "%s tem nome e texto" % m.id)
			afirmar_igual(m.arma, arma, "%s é da %s" % [m.id, arma])
		afirmar_igual(por_raridade, [5, 5, 2] as Array[int], "%s: 5 Comuns, 5 Raras, 2 Épicas" % arma)
	var duplo := _do_banco(banco, &"mordida", &"rebite_duplo")
	afirmar_igual([duplo.raridade, duplo.maximo], [ModificadorArma.Raridade.COMUM, 2], "Rebite Duplo: Comum, máx. 2")
	var grosso := _do_banco(banco, &"mordida", &"rebite_grosso")
	afirmar_igual([grosso.maximo, grosso.mult_dano, grosso.mult_tamanho_projetil], [3, 1.1, 1.25], "Rebite Grosso")
	var art := _do_banco(banco, &"bramido", &"artilharia")
	afirmar_igual([art.raridade, art.marcadores], [ModificadorArma.Raridade.EPICA, [&"artilharia"] as Array[StringName]], "Artilharia")
	afirmar_proximo(banco.chances[0] + banco.chances[1] + banco.chances[2], 100.0, 0.01, "chances somam 100")


func test_sorteio_da_3_diferentes_da_arma_em_uso() -> void:
	var banco := BancoGambiarras.new()
	var rng := _rng()
	for arma: String in [MORDIDA, BRAMIDO]:
		var eq := _equipada(arma)
		for i in 100:
			var opcoes: Array[ModificadorArma] = banco.sortear(eq, rng)
			afirmar_igual(opcoes.size(), 3, "3 opções")
			var ids: Dictionary = {}
			for m in opcoes:
				ids[m.id] = true
				afirmar_igual(m.arma, eq.base.id, "só da arma em uso")
			afirmar_igual(ids.size(), 3, "diferentes")


func test_unica_ja_pega_nao_volta_e_acumulavel_respeita_o_maximo() -> void:
	var banco := BancoGambiarras.new()
	var rng := _rng(3)
	var eq := _equipada()
	eq.adicionar(_do_banco(banco, &"mordida", &"leque"))
	var grosso := _do_banco(banco, &"mordida", &"rebite_grosso")
	eq.adicionar(grosso)
	eq.adicionar(grosso)
	var viu_grosso: bool = false
	for i in 400:
		for m in banco.sortear(eq, rng):
			afirmar(m.id != &"leque", "Leque (única) não volta")
			viu_grosso = viu_grosso or m.id == &"rebite_grosso"
	afirmar(viu_grosso, "Rebite Grosso com 2 de 3 ainda aparece")
	eq.adicionar(grosso)
	for i in 400:
		for m in banco.sortear(eq, rng):
			afirmar(m.id != &"rebite_grosso", "no máximo (3) não volta")


func test_elite_garante_pelo_menos_uma_rara() -> void:
	var banco := BancoGambiarras.new()
	var rng := _rng(11)
	var eq := _equipada(BRAMIDO)
	for i in 300:
		var opcoes: Array[ModificadorArma] = banco.sortear(eq, rng, true)
		afirmar(opcoes.any(func(m: ModificadorArma) -> bool: return m.raridade != ModificadorArma.Raridade.COMUM),
				"sorteio %d: 1 Rara ou melhor" % i)


func test_chances_65_28_7() -> void:
	var banco := BancoGambiarras.new()
	var rng := _rng(5)
	var eq := _equipada()
	var contagem: Array[int] = [0, 0, 0]
	var n: int = 4000
	for i in n:
		contagem[banco.sortear(eq, rng, false, false, 1)[0].raridade] += 1
	afirmar_proximo(contagem[0] / float(n), 0.65, 0.03, "Comum ~65%")
	afirmar_proximo(contagem[1] / float(n), 0.28, 0.03, "Rara ~28%")
	afirmar_proximo(contagem[2] / float(n), 0.07, 0.02, "Épica ~7%")


func test_so_comuns_no_treino() -> void:
	var banco := BancoGambiarras.new()
	var rng := _rng(9)
	for i in 100:
		for m in banco.sortear(_equipada(), rng, false, true):
			afirmar_igual(m.raridade, ModificadorArma.Raridade.COMUM, "só Comuns")


func test_tela_pausa_escolhe_e_recalibra() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	j.equipar(load(MORDIDA))
	var banco := BancoGambiarras.new()
	var rng := _rng(2)
	var tela := TelaGambiarras.new()
	add_child(tela)
	await esperar_frames(1)
	tela.ao_recalibrar = func() -> Array[ModificadorArma]: return banco.sortear(j.arma_equipada, rng)
	j.rerolls = 1
	afirmar(tela.abrir(j, banco.sortear(j.arma_equipada, rng)), "abriu")
	afirmar(tree.paused, "jogo pausado")
	var antes: Array[String] = tela.textos_das_cartas()
	afirmar(tela.recalibrar(), "recalibrou")
	afirmar_igual(j.rerolls, 0, "gastou o reroll")
	afirmar(not tela.recalibrar(), "sem reroll, não recalibra")
	var escolhida: ModificadorArma = tela.opcoes[1]
	var recebida: Array = []
	tela.fechou.connect(func(m: ModificadorArma) -> void: recebida.append(m))
	tela.escolher(1)
	afirmar(not tela.esta_aberta() and not tree.paused, "fechou e despausou")
	afirmar_igual(j.arma_equipada.acumulos(escolhida.id), 1, "a Gambiarra entrou na arma")
	afirmar_igual(recebida, [escolhida], "avisou qual foi")
	afirmar(antes.size() == 3, "3 cartas")


func test_aparece_ao_limpar_combate_e_elite_mas_nao_na_loja_reparo_ou_sala_0() -> void:
	_guardar()
	Progresso.definir_flag("treino_garrak", false)
	var run: RunAto = instanciar(CENA_RUN)
	await esperar_frames(2)
	_fechar_falas()
	tree.paused = false
	for tipo: String in ["queda", "loja", "reparo"]:
		run.sala.plano["tipo"] = tipo
		run._ao_concluir_sala()
		await esperar_frames(2)
		afirmar(not run.tela_gambiarras.esta_aberta(), "%s: sem Gambiarra" % tipo)
	run.sala.plano["tipo"] = "combate"
	run._ao_concluir_sala()
	await esperar_frames(2)
	afirmar(run.tela_gambiarras.esta_aberta(), "combate: abre a escolha")
	run.tela_gambiarras.escolher(0)
	afirmar_igual(run.jogador.arma_equipada.modificadores.size(), 1, "pegou 1")
	run.sala.plano["tipo"] = "elite"
	run._ao_concluir_sala()
	await esperar_frames(2)
	afirmar(run.tela_gambiarras.esta_aberta(), "elite: abre a escolha")
	afirmar(run.tela_gambiarras.opcoes.any(func(m: ModificadorArma) -> bool: return m.raridade != ModificadorArma.Raridade.COMUM),
			"elite com 1 Rara ou melhor")
	run.tela_gambiarras.escolher(0)
	run.jogador.fim_da_run()
	afirmar_igual(run.jogador.arma_equipada.modificadores.size(), 0, "as Gambiarras somem no fim da run")
	_restaurar()


func test_treino_com_garrak_comeca_com_uma_comum() -> void:
	_guardar()
	Progresso.definir_flag("treino_garrak")
	var run: RunAto = instanciar(CENA_RUN)
	for i in 10:
		await esperar_frames(2)
		_fechar_falas()
		if run.tela_gambiarras.esta_aberta():
			break
	afirmar(run.tela_gambiarras.esta_aberta(), "abriu no começo da run")
	for m in run.tela_gambiarras.opcoes:
		afirmar_igual(m.raridade, ModificadorArma.Raridade.COMUM, "%s é Comum" % m.nome)
	run.tela_gambiarras.escolher(0)
	afirmar_igual(run.jogador.arma_equipada.modificadores.size(), 1, "começa com 1 Gambiarra")
	_restaurar()
