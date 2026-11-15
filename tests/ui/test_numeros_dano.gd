extends TestCase
## D-067: números de dano na tela.


func _numeros() -> NumerosDano:
	var n := NumerosDano.instancia(tree)
	n.numeros.clear()
	return n


func _limpar() -> void:
	tree.root.get_node("Config").numeros_dano = true
	NumerosDano.instancia(tree).numeros.clear()


func test_acerto_mostra_o_dano_e_some_em_meio_segundo() -> void:
	var n := _numeros()
	CenarioTeste.criar_chao(self)
	var b := CenarioTeste.criar_boneco(self, Vector2(100, 0))
	await esperar_frames(2)
	b.receber_ataque(InfoDano.criar(14))
	afirmar_igual(n.numeros.size(), 1, "um número")
	afirmar_igual([n.numeros[0]["valor"], n.numeros[0]["tipo"]], [14, NumerosDano.Tipo.NORMAL], "14, branco")
	await esperar_frames(45)
	afirmar(n.numeros.is_empty(), "sumiu depois de ~0,6 s")
	_limpar()


func test_numeros_do_mesmo_alvo_se_somam() -> void:
	var n := _numeros()
	CenarioTeste.criar_chao(self)
	var b := CenarioTeste.criar_boneco(self, Vector2(100, 0))
	var outro := CenarioTeste.criar_boneco(self, Vector2(200, 0))
	await esperar_frames(2)
	b.receber_ataque(InfoDano.criar(10))
	await esperar_frames(5)
	b.receber_ataque(InfoDano.criar(10))
	outro.receber_ataque(InfoDano.criar(7))
	afirmar_igual(n.numeros.size(), 2, "um por alvo")
	afirmar_igual(n.numeros[0]["valor"], 20, "somou 10 + 10")
	_limpar()


func test_cores_forte_efeito_e_ryker() -> void:
	var n := _numeros()
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	var b := CenarioTeste.criar_boneco(self, Vector2(100, 0))
	var c := CenarioTeste.criar_boneco(self, Vector2(200, 0))
	await esperar_frames(2)
	b.receber_ataque(InfoDano.criar(30))
	afirmar_igual(n.numeros.back()["tipo"], NumerosDano.Tipo.FORTE, "dano alto: forte (laranja e maior)")
	afirmar(NumerosDano.TAMANHOS[NumerosDano.Tipo.FORTE] > NumerosDano.TAMANHOS[NumerosDano.Tipo.NORMAL], "maior")
	c.adicionar_acido(2, j)
	await esperar_frames(70)
	var efeito: bool = false
	for x in n.numeros:
		efeito = efeito or x["tipo"] == NumerosDano.Tipo.EFEITO
	afirmar(efeito, "Ácido: verde")
	j.receber_ataque(InfoDano.criar(1))
	afirmar_igual(n.numeros.back()["tipo"], NumerosDano.Tipo.JOGADOR, "dano no Ryker: vermelho")
	_limpar()


func test_limite_de_30_e_opcao_de_desligar() -> void:
	var n := _numeros()
	CenarioTeste.criar_chao(self)
	var bonecos: Array[Boneco] = []
	for k in 35:
		bonecos.append(CenarioTeste.criar_boneco(self, Vector2(k * 30, 0)))
	await esperar_frames(2)
	for b in bonecos:
		b.receber_ataque(InfoDano.criar(5))
	afirmar_igual(n.numeros.size(), NumerosDano.MAXIMO, "no máximo 30 na tela")
	n.numeros.clear()
	tree.root.get_node("Config").numeros_dano = false
	bonecos[0].receber_ataque(InfoDano.criar(5))
	afirmar(n.numeros.is_empty(), "desligado nas Opções: nada")
	_limpar()
