extends TestCase
## Sistema de diálogo a partir de dados (NAR-01).

const CAMINHO_TESTE: String = "user://teste_progresso.cfg"

var banco: BancoDialogos
var progresso: DadosProgresso
var diretor: DiretorDialogo


func _preparar() -> void:
	banco = BancoDialogos.new()
	afirmar_igual(banco.carregar("res://data/dialogos/vs_varrek.json"), OK, "arquivo carrega")
	progresso = DadosProgresso.new()
	progresso.caminho = CAMINHO_TESTE
	add_child(progresso)
	progresso.apagar()
	diretor = DiretorDialogo.new(banco, progresso)


func _ids(falas: Array[Dictionary]) -> Array[String]:
	var lista: Array[String] = []
	for f in falas:
		lista.append(f["id"])
	return lista


func test_arquivo_do_vs_e_valido() -> void:
	_preparar()
	var problemas: Array[String] = banco.validar()
	afirmar(problemas.is_empty(), "problemas no arquivo: %s" % ", ".join(problemas))
	afirmar(banco.cenas.size() >= 25, "todas as cenas do NAR-01")


func test_abertura_toca_em_ordem_e_so_uma_vez() -> void:
	_preparar()
	var falas := diretor.preparar("abertura")
	afirmar_igual(falas.size(), 18, "18 falas")
	afirmar_igual(falas[0]["id"], "ABER_01", "começa na ABER_01")
	afirmar_igual(falas[17]["id"], "ABER_18", "termina na ABER_18")
	afirmar(progresso.tem_flag("abertura_vista"), "liga a flag")
	afirmar(diretor.preparar("abertura").is_empty(), "não toca de novo")


func test_direcao_de_cena_fica_separada_do_texto() -> void:
	_preparar()
	var falas := diretor.preparar("abertura")
	var aber_08: Dictionary = falas[7]
	afirmar(not "[" in aber_08["texto"], "texto sem colchetes")
	afirmar_igual(aber_08.get("direcao", ""), "olha para o pulso, onde ainda está a algema", "direção guardada à parte")


func test_falas_condicionais_da_primeira_morte() -> void:
	_preparar()
	afirmar(diretor.preparar("morte_primeira").is_empty(), "sem morte, não toca")
	progresso.incrementar("mortes_total")
	var sem_urkesh := _ids(diretor.preparar("morte_primeira"))
	afirmar(not "MORT_U1" in sem_urkesh, "sem as falas de Ur-Kesh")
	afirmar_igual(sem_urkesh.size(), 8, "8 falas")
	progresso.apagar()
	progresso.incrementar("mortes_total")
	progresso.definir_flag("1a_morte_urkesh")
	var com_urkesh := _ids(diretor.preparar("morte_primeira"))
	afirmar_igual(com_urkesh.slice(0, 5), ["MORT_01", "MORT_02", "MORT_U1", "MORT_U2", "MORT_U3"] as Array[String], "variante entra depois da MORT_02")


func test_garrak_escolhe_a_fala_certa() -> void:
	_preparar()
	progresso.incrementar("mortes_total")
	var ids := _ids(diretor.preparar("garrak_primeira"))
	afirmar("GARR_11b" in ids and not "GARR_11a" in ids, "outra causa → GARR_11b")


func test_sorteio_nao_repete_a_mesma_seguida() -> void:
	_preparar()
	progresso.definir_flag("hangar_visto")
	var anterior: String = ""
	for i in 40:
		var falas := diretor.preparar("hangar_repeticao")
		afirmar_igual(falas.size(), 1, "uma fala sorteada")
		afirmar(falas[0]["id"] != anterior, "repetiu %s" % anterior)
		anterior = falas[0]["id"]


func test_condicoes_com_contador() -> void:
	_preparar()
	afirmar(not diretor.pode_tocar("misterio"), "precisa de 3 mortes")
	progresso.incrementar("mortes_total", 3)
	afirmar(diretor.pode_tocar("misterio"), "depois da 3ª morte")
	afirmar(progresso.avaliar("mortes_total>=3 e !sete_chegou"), "combinação com 'e'")
	afirmar(not progresso.avaliar("mortes_total>=3 e sete_chegou"), "combinação falsa")


func test_progresso_salva_e_carrega() -> void:
	_preparar()
	progresso.definir_flag("1a_loja")
	progresso.incrementar("urkesh_encontros", 2)
	afirmar_igual(progresso.salvar(), OK, "salvou")
	var outro := DadosProgresso.new()
	outro.caminho = CAMINHO_TESTE
	outro.carregar()
	afirmar(outro.tem_flag("1a_loja"), "flag voltou")
	afirmar_igual(outro.valor("urkesh_encontros"), 2, "contador voltou")
	outro.free()
	progresso.apagar()


func test_caixa_de_dialogo_mostra_e_avanca() -> void:
	_preparar()
	var caixa: CaixaDialogo = instanciar("res://scenes/ui/caixa_dialogo.tscn")
	var falas := diretor.preparar("dual")
	var terminou: Array[String] = [""]
	caixa.terminou.connect(func(id: String) -> void: terminou[0] = id)
	caixa.mostrar("dual", falas, "conversa", banco)
	afirmar(caixa.esta_ativa(), "aparece")
	afirmar(tree.paused, "conversa pausa o jogo")
	afirmar_igual(caixa.nome.text, "Ryker", "nome do falante")
	caixa.avancar()
	afirmar_igual(caixa.nome.text, "ECO", "segunda fala")
	caixa.avancar()
	afirmar(not caixa.esta_ativa(), "fecha no fim")
	afirmar(not tree.paused, "despausa")
	afirmar_igual(terminou[0], "dual", "avisa que terminou")


func test_fala_rapida_some_sozinha_sem_pausar() -> void:
	_preparar()
	var caixa: CaixaDialogo = instanciar("res://scenes/ui/caixa_dialogo.tscn")
	caixa.mostrar("queda_saida", diretor.preparar("queda_saida"), "rapida", banco)
	afirmar(not tree.paused, "rápida não pausa")
	await esperar_frames(200)
	afirmar(not caixa.esta_ativa(), "sumiu sozinha")
