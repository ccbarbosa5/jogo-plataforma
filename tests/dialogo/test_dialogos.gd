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
	afirmar_igual(falas[6].get("aud", ""), "zumbido", "ABER_07 marca o zumbido para o AUD")
	afirmar(not "AUD" in falas[6]["texto"], "a marcação não aparece no texto")
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
	afirmar_igual(sem_urkesh.size(), 9, "9 falas (v0.3 tem a MORT_09)")
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
	afirmar_igual(caixa.nome_atual(), "RYKER", "nome do falante (D-046: só o nome, em maiúsculas)")
	caixa.avancar()
	afirmar_igual(caixa.nome_atual(), "ECO", "segunda fala")
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


func test_entrada_de_urkesh_por_prioridade() -> void:
	_preparar()
	progresso.definir_flag("urkesh_visto")
	progresso.definir_run("tem_dadiva_kharn")
	afirmar_igual(_ids(diretor.preparar("urkesh_entrada")), ["UREK_K"] as Array[String], "dádiva Kharn")
	progresso.definir_run("tem_dadiva_vesh")
	afirmar_igual(_ids(diretor.preparar("urkesh_entrada")), ["UREK_KV1", "UREK_KV2"] as Array[String], "as duas dádivas")
	progresso.limpar_run()
	var generica := _ids(diretor.preparar("urkesh_entrada"))
	afirmar(generica[0].begins_with("UREK_G"), "sem condição especial: genérica sorteada (%s)" % generica[0])


func test_estado_de_run_nao_e_salvo() -> void:
	_preparar()
	progresso.definir_run("tem_dadiva_vesh")
	afirmar(progresso.tem_flag("tem_dadiva_vesh"), "vale durante a run")
	progresso.salvar()
	var outro := DadosProgresso.new()
	outro.caminho = CAMINHO_TESTE
	outro.carregar()
	afirmar(not outro.tem_flag("tem_dadiva_vesh"), "não vai para o arquivo")
	outro.free()


func test_pistas_somam_duvida_uma_vez_cada() -> void:
	# D-034: contador "duvida" gravado desde o VS.
	_preparar()
	progresso.definir_flag("1a_oferta_vesh")
	progresso.incrementar("ofertas_vesh_total", 3)
	afirmar_igual(_ids(diretor.preparar("vesh_repeticao")), ["VESH_P1"] as Array[String], "1ª pista")
	afirmar_igual(progresso.valor("duvida"), 1, "duvida +1")
	afirmar_igual(_ids(diretor.preparar("vesh_repeticao")), ["VESH_P2", "VESH_P2b"] as Array[String], "2ª pista")
	afirmar_igual(progresso.valor("duvida"), 2, "duvida +1")
	var depois := _ids(diretor.preparar("vesh_repeticao"))
	afirmar(depois[0].begins_with("VESH_R"), "pistas não repetem")
	afirmar_igual(progresso.valor("duvida"), 2, "falas comuns não somam")
	diretor.preparar("registro_molde1")
	afirmar_igual(progresso.valor("duvida"), 3, "o Registro do Molde 1 é pista")
	afirmar(progresso.tem_flag("registro_molde1_1"), "flag da NAR")


func test_pista_da_loja_na_4a_visita() -> void:
	_preparar()
	progresso.definir_flag("1a_loja")
	progresso.incrementar("visitas_loja", 3)
	afirmar(not "LOJA_P1" in _ids(diretor.preparar("loja_entrada")), "3ª visita: sem pista")
	progresso.incrementar("visitas_loja")
	afirmar_igual(_ids(diretor.preparar("loja_entrada")), ["LOJA_P1"] as Array[String], "4ª visita: pista")


func test_falantes_tem_placa_moldura_e_lado() -> void:
	_preparar()
	afirmar_igual(banco.nome_do_falante("RYKER"), "RYKER", "nome na placa")
	afirmar_igual(banco.nome_do_falante("VOSSA"), "VOSSA MARGEM", "nome na placa")
	afirmar_igual(banco.moldura_do_falante("SINAL"), "humano_danificada", "sinal usa a moldura danificada")
	afirmar_igual(banco.retrato_do_falante("SINAL"), "estatica", "sinal sem rosto")
	afirmar_igual(banco.lado_do_falante("RYKER"), "esquerda", "jogável à esquerda")
	afirmar_igual(banco.lado_do_falante("ECO"), "direita", "interlocutor à direita")
	afirmar_igual(banco.moldura_do_falante("TOR-AMA"), "kharn", "moldura Kharn")
	afirmar_igual(banco.moldura_do_falante("ECO"), "eco", "moldura da ECO")


func test_nao_ha_falas_de_arma_pesada() -> void:
	# D-038: a fala LOJA_C3 (compra de arma pesada) fica fora do jogo.
	_preparar()
	for id_cena: String in banco.cenas:
		for fala in banco.todas_as_falas(id_cena):
			afirmar(fala["id"] != "LOJA_C3", "LOJA_C3 ainda no arquivo")


func test_caixa_estilo_hades_lados_placa_e_moldura() -> void:
	_preparar()
	var caixa: CaixaDialogo = instanciar("res://scenes/ui/caixa_dialogo.tscn")
	progresso.incrementar("mortes_total")
	caixa.mostrar("morte_primeira", diretor.preparar("morte_primeira"), "conversa", banco)
	afirmar(caixa.escurecer.visible, "cenário escurecido atrás")
	afirmar(caixa.retrato_esquerda.visible and caixa.retrato_esquerda.ativo, "Ryker à esquerda")
	afirmar_igual(caixa.nome.text, "RYKER", "placa só com o nome")
	afirmar_igual(caixa.caixa.moldura, "humano", "moldura do Ryker")
	caixa.avancar()
	afirmar(caixa.retrato_direita.visible and caixa.retrato_direita.ativo, "ECO à direita")
	afirmar(caixa.retrato_esquerda.visible and not caixa.retrato_esquerda.ativo, "Ryker continua, escurecido (mockup ART v04)")
	afirmar_igual(caixa.caixa.moldura, "eco", "moldura da ECO")
	afirmar(caixa.texto.position.x < caixa.caixa.size.x * 0.5, "texto longe do retrato da direita")
	while caixa.esta_ativa():
		caixa.avancar()
	afirmar(not tree.paused, "despausa no fim")


func test_caixa_avanca_pela_entrada_do_jogador() -> void:
	_preparar()
	var caixa: CaixaDialogo = instanciar("res://scenes/ui/caixa_dialogo.tscn")
	var entrada := EntradaJogador.new()
	caixa.entrada = entrada
	caixa.mostrar("dual", diretor.preparar("dual"), "conversa", banco)
	await tree.create_timer(0.25, true).timeout  # passa a trava contra avanço acidental
	entrada.interagir_pressionado = true
	await _quadros(2)
	afirmar_igual(caixa.nome_atual(), "ECO", "avançou com Interagir do EntradaJogador")
	await tree.create_timer(0.25, true).timeout
	entrada.atirar_pressionado = true
	await _quadros(2)
	afirmar(not caixa.esta_ativa(), "fechou")
	while caixa.esta_ativa():  # garante que o jogo não fica pausado se o teste falhar
		caixa.avancar()
	tree.paused = false


func test_retratos_da_art_por_expressao() -> void:
	_preparar()
	var exp_ryker := banco.expressoes_do_falante("RYKER")
	var deboche := RetratoDialogo.carregar_textura("RYKER", "deboche", exp_ryker) as AtlasTexture
	afirmar(deboche != null, "retrato do Ryker entregue pela ART")
	afirmar_igual(deboche.region.position.x, RetratoDialogo.TAMANHO.x * exp_ryker.find("deboche"), "quadro da expressão")
	var padrao := RetratoDialogo.carregar_textura("RYKER", "inexistente", exp_ryker) as AtlasTexture
	afirmar_igual(padrao.region.position.x, 0.0, "expressão desconhecida usa a primeira")
	afirmar(RetratoDialogo.carregar_textura("UR-KESH", "fúria", banco.expressoes_do_falante("UR-KESH")) == null, "sem arquivo: provisório")
	afirmar_igual(RetratoDialogo.caminho("UR-KESH"), "res://assets/sprites/retratos/ur_kesh/ur_kesh_retratos.png", "caminho esperado para ART")


func test_expressoes_das_falas_existem() -> void:
	_preparar()
	for id_cena: String in banco.cenas:
		for fala in banco.todas_as_falas(id_cena):
			var e: String = fala.get("expressao", "")
			if not e.is_empty():
				afirmar(e in banco.expressoes_do_falante(fala["falante"]), "%s: expressão %s" % [fala["id"], e])


func test_placa_so_com_o_nome() -> void:
	# D-046: a placa mostra só o nome, em maiúsculas; sem título.
	_preparar()
	for codigo: String in banco.falantes:
		var n := banco.nome_do_falante(codigo)
		afirmar_igual(n, n.to_upper(), "%s em maiúsculas" % codigo)
		afirmar(not banco.falantes[codigo].has("titulo"), "%s sem título" % codigo)


func test_bramido_muda_a_entrada_de_urkesh() -> void:
	_preparar()
	progresso.definir_flag("urkesh_visto")
	progresso.definir_run("tem_dadiva_kharn")
	progresso.definir_run("arma_atual", "bramido")
	afirmar_igual(_ids(diretor.preparar("urkesh_entrada")), ["UREK_BR", "UREK_BR2"] as Array[String], "vê o próprio Bramido")
	afirmar_igual(_ids(diretor.preparar("urkesh_entrada")), ["UREK_K"] as Array[String], "só uma vez")


## Espera quadros de processo (a caixa roda com o jogo pausado).
func _quadros(n: int) -> void:
	for i in n:
		await tree.process_frame
