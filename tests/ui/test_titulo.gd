extends TestCase
## D-053: menu inicial (logo, fundo animado, Continuar só com jogo salvo, Novo jogo com
## confirmação, Opções, Créditos, Sair) e a volta ao menu pela pausa da nave (D-054).

const ARQUIVO_PROGRESSO: String = "user://progresso_teste_titulo.cfg"
const CENA_TITULO: String = "res://scenes/ui/tela_titulo.tscn"


func _progresso(com_jogo: bool) -> DadosProgresso:
	var p := DadosProgresso.new()
	p.caminho = ARQUIVO_PROGRESSO
	add_child(p)  # o _ready carrega o arquivo
	p.apagar()
	if com_jogo:
		p.definir_flag("abertura_vista")
		p.salvar()
	return p


func _titulo(progresso: DadosProgresso) -> TelaTitulo:
	var t: TelaTitulo = (load(CENA_TITULO) as PackedScene).instantiate()
	t.progresso = progresso
	add_child(t)
	return t


func _limpar() -> void:
	Ciclo.ultima_cena_pedida = ""
	Config.abertura_vista = false
	if FileAccess.file_exists(ARQUIVO_PROGRESSO):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ARQUIVO_PROGRESSO))


func test_o_jogo_abre_no_logo_e_depois_no_menu() -> void:
	# D-073A: o logo animado vem antes do menu e termina nele.
	afirmar_igual(ProjectSettings.get_setting("application/run/main_scene"), "res://scenes/ui/logo_animado.tscn", "cena principal")
	afirmar_igual(Ciclo.CENA_TITULO, CENA_TITULO, "o logo leva ao menu")


func test_tem_logo_fundo_e_brasas() -> void:
	var t := _titulo(_progresso(false))
	await esperar_frames(1)
	var logo := t.get_node("Logo") as TextureRect
	afirmar(logo.texture != null and logo.texture.resource_path.ends_with("logo_no_rest.png"), "logo da ART")
	afirmar((t.get_node("Fundo") as TextureRect).texture != null, "fundo da ART")
	var brasas := t.get_node("Brasas") as CPUParticles2D
	afirmar(brasas.emitting and brasas.amount >= 20 and brasas.amount <= 30, "20 a 30 brasas subindo")
	afirmar_proximo(logo.position.x + logo.size.x * 0.5, 240.0, 1.0, "logo centralizado")
	_limpar()


func test_sem_jogo_salvo_nao_tem_continuar() -> void:
	var t := _titulo(_progresso(false))
	await esperar_frames(1)
	var textos: Array[String] = t.textos_dos_botoes()
	afirmar(not textos.has("Continuar"), "sem Continuar")
	afirmar_igual(textos.slice(0, 5), ["Novo jogo", "Arena (teste)", "Opções", "Créditos", "Sair"] as Array[String], "botões na ordem")
	_limpar()


func test_continuar_vai_para_a_nave_sem_apagar() -> void:
	var p := _progresso(true)
	var t := _titulo(p)
	await esperar_frames(1)
	afirmar_igual(t.textos_dos_botoes()[0], "Continuar", "Continuar é o primeiro")
	t.ativar("Continuar")
	afirmar_igual(Ciclo.ultima_cena_pedida, Ciclo.CENA_NAVE, "foi para a nave")
	afirmar(p.tem_flag("abertura_vista"), "progresso mantido")
	_limpar()


func test_novo_jogo_com_progresso_pede_confirmacao_e_apaga() -> void:
	Config.abertura_vista = true  # D-073B: com a abertura já vista, vai direto à nave
	var p := _progresso(true)
	var t := _titulo(p)
	await esperar_frames(1)
	t.ativar("Novo jogo")
	afirmar_igual(t.sobreposicao, "confirmar_novo", "pediu confirmação")
	afirmar_igual(Ciclo.ultima_cena_pedida, "", "ainda não saiu")
	t.ativar("Cancelar")
	afirmar_igual(t.sobreposicao, "", "cancelar volta aos botões")
	afirmar(p.tem_flag("abertura_vista"), "nada apagado")
	t.ativar("Novo jogo")
	t.ativar("Apagar e começar")
	afirmar(not p.tem_flag("abertura_vista"), "progresso apagado")
	afirmar(not p.tem_jogo_salvo(), "sem jogo salvo")
	afirmar_igual(Ciclo.ultima_cena_pedida, Ciclo.CENA_NAVE, "começou na nave")
	_limpar()


func test_novo_jogo_sem_progresso_comeca_direto() -> void:
	Config.abertura_vista = true  # D-073B: com a abertura já vista, vai direto à nave
	var t := _titulo(_progresso(false))
	await esperar_frames(1)
	t.ativar("Novo jogo")
	afirmar_igual(t.sobreposicao, "", "sem confirmação")
	afirmar_igual(Ciclo.ultima_cena_pedida, Ciclo.CENA_NAVE, "foi para a nave")
	_limpar()


func test_opcoes_do_titulo_usam_as_telas_da_pausa_sem_pausar() -> void:
	var t := _titulo(_progresso(false))
	var pausa: Node = tree.root.get_node("Pausa")
	await esperar_frames(1)
	t.ativar("Opções")
	afirmar(pausa.esta_aberto(), "Opções abertas")
	afirmar_igual(pausa.tela, pausa.Tela.OPCOES, "direto nas Opções")
	afirmar(not tree.paused, "não pausa nada")
	afirmar(pausa.textos_dos_botoes().has("Controles"), "Controles dentro das Opções")
	pausa.ativar("Controles")
	afirmar_igual(pausa.tela, pausa.Tela.CONTROLES, "abriu Controles")
	pausa.voltar()
	afirmar_igual(pausa.tela, pausa.Tela.OPCOES, "Esc volta para as Opções")
	pausa.ativar("Voltar")
	afirmar(not pausa.esta_aberto(), "Voltar fecha")
	afirmar(not tree.paused, "continua sem pausa")
	_limpar()


func test_creditos_mostram_fonte_e_motor() -> void:
	var t := _titulo(_progresso(false))
	await esperar_frames(1)
	t.ativar("Créditos")
	afirmar_igual(t.sobreposicao, "creditos", "abriu Créditos")
	var texto: String = TelaTitulo.texto_dos_creditos()
	for trecho in ["Open Sans", "OFL", "Godot Engine", "CREDITS.md"]:
		afirmar(texto.contains(trecho), "créditos citam %s" % trecho)
	t.ativar("Voltar")
	afirmar_igual(t.sobreposicao, "", "Voltar fecha")
	_limpar()


func test_pausa_da_nave_volta_ao_menu() -> void:
	var flags: Dictionary = Progresso.flags.duplicate()
	var contadores: Dictionary = Progresso.contadores.duplicate()
	var resultado: String = Ciclo.resultado
	var pausa: Node = tree.root.get_node("Pausa")
	var nave: Node = (load("res://scenes/nave/nave_eco.tscn") as PackedScene).instantiate()
	tree.root.add_child(nave)
	tree.current_scene = nave
	await esperar_frames(3)
	var caixa := tree.get_first_node_in_group("caixa_dialogo") as CaixaDialogo
	var limite: int = 60
	while caixa != null and caixa.esta_ativa() and limite > 0:
		caixa.avancar()
		limite -= 1
	tree.paused = false
	afirmar(pausa.abrir(), "abriu na nave")
	var textos: Array[String] = pausa.textos_dos_botoes()
	afirmar(textos.has("Voltar ao menu"), "na nave: Voltar ao menu")
	afirmar(not textos.has("Voltar à nave"), "na nave não tem Voltar à nave")
	pausa.ativar("Voltar ao menu")
	afirmar(not pausa.esta_aberto() and not tree.paused, "fechou e despausou")
	afirmar_igual(Ciclo.ultima_cena_pedida, Ciclo.CENA_TITULO, "foi para o menu inicial")
	tree.current_scene = null
	nave.queue_free()
	await esperar_frames(1)
	Progresso.flags = flags
	Progresso.contadores = contadores
	Ciclo.resultado = resultado
	_limpar()
