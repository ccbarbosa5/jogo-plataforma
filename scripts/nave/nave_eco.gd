class_name NaveEco
extends Node2D
## Nave-base Eco (GD-01 §9.1), versão mínima do VS. Áreas da esquerda para a direita:
## Reconstrutor (onde o Ryker reaparece) · Ponte (ECO, Sete, Arquivo com Dados) ·
## Arsenal (Garrak: escolha da arma e Treino) · Compartimento Ilo (Vossa Margem: melhorias com
## Núcleos) · Hangar (a cápsula começa a run). O desenho das áreas é provisório, por código.

const LARGURA: float = 1600.0
const CHAO: float = 224.0
const AREAS: Array = [
	["RECONSTRUTOR", 0.0, 280.0, Color("2b2236")],
	["PONTE", 280.0, 640.0, Color("1f2a33")],
	["ARSENAL", 640.0, 960.0, Color("2e2a24")],
	["COMPARTIMENTO ILO", 960.0, 1280.0, Color("2f2a1f")],
	["HANGAR", 1280.0, 1600.0, Color("232630")],
]
const ARMAS: Array[StringName] = [&"mordida", &"bramido"]

@onready var jogador: Jogador = $Ryker
@onready var camera: CameraJogo = $Camera
@onready var hud: Hud = $Hud
@onready var caixa: CaixaDialogo = $CaixaDialogo

var melhorias: MelhoriasPermanentes = MelhoriasPermanentes.new()
var tela: TelaLista
var eco: PontoNave
var garrak: PontoNave
var vossa: PontoNave
var sete: PontoNave
var terminal: PontoNave
var capsula: PontoNave
var _lancando: bool = false
## Árvore de Combate do Ryker (GD-07 §4), no Arsenal.
var progressao: ProgressaoPersonagem
var tela_arvore: TelaArvoreCombate
## Garrak já comentou as Gambiarras da run que acabou (NAR-06 §2.6, 1 por volta).
var _comentou_gambiarras: bool = false
var _lista_do_vossa: bool = false


func _ready() -> void:
	Combate.reiniciar()
	Progresso.limpar_run()
	# Falas da reconstrução que dependem da run que acabou (CAMP_A3, NAR-06 §2.7: morreu com
	# pelo menos 1 Gambiarra).
	if Ciclo.resultado == "morte" and int(Ciclo.ultima_run.get("gambiarras_pegas", 0)) > 0:
		Progresso.definir_run("morreu_com_gambiarra")
	_montar_cenario()
	jogador.global_position = Vector2(120, CHAO)
	jogador.posicao_segura = jogador.global_position
	jogador.limite_queda_y = 400.0
	camera.alvos = [jogador]
	camera.definir_limites(Rect2(0, 0, LARGURA, 270))
	camera.posicionar_imediato()
	hud.conectar(jogador)
	caixa.entrada = jogador.entrada
	tela = TelaLista.new()
	add_child(tela)
	tela.entrada = jogador.entrada
	progressao = ProgressaoPersonagem.new("ryker")
	tela_arvore = TelaArvoreCombate.new()
	add_child(tela_arvore)
	tela.fechou.connect(_ao_fechar_lista)
	PontoNave.criar(self, Vector2(120, CHAO), PontoNave.Figura.RECONSTRUTOR, "")
	eco = _ponto(Vector2(440, CHAO), PontoNave.Figura.ECO, "falar com a ECO", _usar_eco)
	terminal = _ponto(Vector2(590, CHAO), PontoNave.Figura.TERMINAL, "Arquivo (Dados)", _usar_terminal)
	sete = _ponto(Vector2(520, CHAO), PontoNave.Figura.SETE, "falar com o Sete", _usar_sete)
	garrak = _ponto(Vector2(800, CHAO), PontoNave.Figura.GARRAK, "Arsenal", _usar_garrak)
	vossa = _ponto(Vector2(1120, CHAO), PontoNave.Figura.VOSSA, "árvore Passiva (Núcleos)", _usar_vossa)
	capsula = _ponto(Vector2(1480, CHAO), PontoNave.Figura.CAPSULA, "descer para Varrek", _usar_capsula)
	atualizar_presencas()
	_chegada()


func _ponto(pos: Vector2, figura: PontoNave.Figura, acao: String, ao_usar: Callable) -> PontoNave:
	var p := PontoNave.criar(self, pos, figura, acao)
	p.usado.connect(func(_p: PontoNave) -> void:
		if not caixa.esta_ativa() and not tela.esta_aberta() and not tela_arvore.esta_aberta():
			ao_usar.call())
	return p


## Quem está na nave depende da história (NAR-01): Garrak e Vossa chegam depois da 1ª morte;
## o Sete, depois que a ECO o imprime.
func atualizar_presencas() -> void:
	var depois_da_morte: bool = Progresso.valor("mortes_total") >= 1
	_presente(garrak, depois_da_morte or Progresso.tem_flag("garrak_conhecido"))
	_presente(vossa, depois_da_morte or Progresso.tem_flag("vossa_conhecido"))
	_presente(sete, Progresso.tem_flag("sete_chegou"))


func _presente(p: PontoNave, sim: bool) -> void:
	p.visible = sim
	p.monitoring = sim


## Falas da chegada: a abertura (1ª vez), a reconstrução depois da morte e o Sete.
func _chegada() -> void:
	var cenas: Array[String] = []
	match Ciclo.resultado:
		"morte":
			hud.mostrar_mensagem("ECO: RECONSTRUÇÃO CONCLUÍDA" + texto_xp_da_run(), 2.5)
			cenas.assign(["morte_primeira|morte_repeticao", "campo_morte_com_arvore", "sete_chegada"])
		"vitoria", "desistiu":  # desistiu = abandonou a run pela pausa (D-054)
			hud.mostrar_mensagem("DE VOLTA À ECO" + texto_xp_da_run(), 2.5)
			cenas.assign(["sete_chegada"])
		_:
			cenas.assign(["abertura", "sete_chegada"])
	await get_tree().process_frame
	await tocar_em_sequencia(cenas)
	atualizar_presencas()


## XP da run que acabou e o nível agora (GD-07 §4.1: aparece na reconstrução, não no HUD).
func texto_xp_da_run() -> String:
	var xp: int = int(Ciclo.ultima_run.get("xp_ganho", 0))
	if xp <= 0:
		return ""
	var nivel: int = progressao.nivel(Progresso)
	var subiu: bool = nivel > int(Ciclo.ultima_run.get("nivel_inicial", nivel))
	return "\n+%d XP · Nível %d%s" % [xp, nivel, " — novos pontos no Arsenal!" if subiu else ""]


func abrir_arvore_combate() -> void:
	tela_arvore.abrir(progressao, Progresso, String(Ciclo.arma_escolhida))


## Toca as cenas em ordem, esperando cada conversa acabar. "a|b" = a primeira que puder tocar.
func tocar_em_sequencia(cenas: Array[String]) -> void:
	for item in cenas:
		for id in item.split("|"):
			if Dialogos.tocar(id):
				if caixa.esta_ativa():
					await caixa.terminou
				break


# --- Ações ---

func _usar_eco() -> void:
	await tocar_em_sequencia(["misterio", "sete_eco_3", "sete_eco_2", "sete_eco_1"] as Array[String])


func _usar_sete() -> void:
	await tocar_em_sequencia(["sete_eco_3", "sete_eco_2", "sete_eco_1"] as Array[String])


func _usar_terminal() -> void:
	tela.cor_titulo = Color("4fb0a6")
	tela.abrir("Arquivo da Ponte", "eco", func() -> Array[Dictionary]: return opcoes_melhorias("ponte"), _saldos)


func _usar_vossa() -> void:
	await tocar_em_sequencia(["vossa_primeira", "vossa_arvore_primeira"] as Array[String])
	tela.cor_titulo = Color("d9b26a")
	tela.abrir("Vossa Margem · Árvore Passiva", "ilo", func() -> Array[Dictionary]: return opcoes_melhorias("vossa"), _saldos)
	_lista_do_vossa = true
	# NAR-06 §1.2: fala do Vossa ao abrir (sem Núcleos para nada: "Olhar é grátis").
	var alguma: bool = false
	for o in tela.opcoes:
		alguma = alguma or o.get("pode", false)
	tela.falar("vossa_arvore_abrir" if alguma else "vossa_arvore_sem_nucleos")


func _ao_fechar_lista() -> void:
	if _lista_do_vossa:
		_lista_do_vossa = false
		if randf() < 0.5:
			Dialogos.tocar("vossa_fechar")  # NAR-06 §1.4, PASS_X4 (sorteio)


## NAR-06 §1.3/§1.4: o Vossa comenta cada compra (1ª compra, seguintes e tudo comprado). O
## "Completo" (PASS_X1) toca ao tentar comprar uma melhoria que já está no máximo.
func _falar_compra_vossa(id: String) -> void:
	if not tela.falar("vossa_compra_" + id):
		tela.falar("vossa_compra_%s_2" % id)
	var tudo: bool = true
	for i in melhorias.do_lugar("vossa"):
		tudo = tudo and melhorias.custo(i["id"], Progresso) < 0
	if tudo:
		tela.falar("vossa_tudo")


func _usar_garrak() -> void:
	# Garrak fala primeiro quando há algo novo (NAR-01, NAR-03 e NAR-06); depois, o Arsenal.
	var falou: bool = false
	for id: String in ["garrak_primeira", "arsenal_combate_primeira", "arsenal_bramido", "arsenal_aprimoramento",
			"arsenal_treino_primeiro"] + _cenas_de_nivel():
		if Dialogos.tocar(id):
			await caixa.terminou
			falou = true
			break
	tela.cor_titulo = Color("ff5a2e")
	tela.abrir("Arsenal · Garrak", "kharn", opcoes_arsenal, _saldos)
	if not falou:
		comentar_gambiarras()


## Marcos de nível da árvore de Combate (NAR-06 §2.5), do maior para o menor.
func _cenas_de_nivel() -> Array[String]:
	var n: int = progressao.nivel(Progresso)
	var cenas: Array[String] = []
	if n >= 25:
		cenas.append("combate_nivel_25" if Progresso.tem_flag("garrak_chama_ryker") else "combate_nivel_25_kratzu")
	if n >= 10:
		cenas.append("combate_nivel_10")
	if n >= 5:
		cenas.append("combate_nivel_5")
	return cenas


## NAR-06 §2.6: na volta, Garrak comenta as Gambiarras da run (1 vez por volta, só se teve alguma).
func comentar_gambiarras() -> bool:
	if _comentou_gambiarras or int(Ciclo.ultima_run.get("gambiarras_pegas", 0)) <= 0:
		return false
	_comentou_gambiarras = true
	if int(Ciclo.ultima_run.get("gambiarras_pegas", 0)) >= 5:
		return Dialogos.tocar("arsenal_gambiarras_muitas")
	if Ciclo.ultima_run.get("gambiarra_epica", false):
		return Dialogos.tocar("arsenal_gambiarra_epica")
	return Dialogos.tocar("arsenal_gambiarras")


func _usar_capsula() -> void:
	if _lancando:
		return
	_lancando = true
	if not Dialogos.tocar("hangar_primeira"):
		Dialogos.tocar("hangar_repeticao")
	if caixa.esta_ativa():
		await caixa.terminou
	hud.mostrar_mensagem("CÁPSULA LANÇADA", 1.0)
	Ciclo.ir_para_run()


func _saldos() -> String:
	return "%d Núcleos · %d Dados" % [Progresso.valor("nucleos"), Progresso.valor("dados")]


# --- Listas dos menus ---

func opcoes_melhorias(onde: String) -> Array[Dictionary]:
	var lista: Array[Dictionary] = []
	for i in melhorias.do_lugar(onde):
		lista.append(_opcao_melhoria(i))
	return lista


func _opcao_melhoria(i: Dictionary) -> Dictionary:
	var id: String = i["id"]
	var n: int = MelhoriasPermanentes.nivel(id, Progresso)
	var maximo: int = melhorias.maximo(id)
	var custo: int = melhorias.custo(id, Progresso)
	var moeda: String = MelhoriasPermanentes.NOMES_MOEDA[i["moeda"]]
	var direita: String = "COMPLETO" if custo < 0 else "%d %s" % [custo, moeda]
	if maximo > 1:
		direita = "%d/%d · %s" % [n, maximo, direita]
	var motivo: String = "Já no máximo." if custo < 0 else ("Precisa de %s antes." % melhorias.item(i["requer"])["nome"] \
			if melhorias.bloqueado(id, Progresso) else "%s insuficientes." % moeda)
	var nome: String = "%s · %s" % [i["ramo"], i["nome"]] if i.has("ramo") else i["nome"]
	var do_vossa: bool = i.get("onde", "") == "vossa"
	return {
		"nome": nome, "descricao": i["descricao"], "direita": direita, "ativo": n > 0,
		"pode": melhorias.pode_comprar(id, Progresso), "motivo": motivo,
		"feito": "" if do_vossa else "%s comprado." % i["nome"],
		"acao": func() -> bool:
			var ok: bool = melhorias.comprar(id, Progresso)
			if ok and do_vossa:
				_falar_compra_vossa(id)
			return ok,
		"ao_falhar": func() -> void:
			if not do_vossa or melhorias.bloqueado(id, Progresso):
				return
			tela.mensagem = ""
			tela.falar("vossa_maximo" if melhorias.custo(id, Progresso) < 0 else "vossa_falta_nucleos"),
	}


func opcoes_arsenal() -> Array[Dictionary]:
	var lista: Array[Dictionary] = []
	lista.append({
		"nome": "Árvore de Combate",
		"descricao": "Nível %d · %d pontos livres. Redistribuir é grátis." % [progressao.nivel(Progresso), progressao.pontos_livres(Progresso)],
		"direita": "ABRIR", "ativo": false, "pode": true, "motivo": "", "feito": "",
		"acao": func() -> bool:
			tela.fechar()
			abrir_arvore_combate.call_deferred()
			return true,
	})
	for id in ARMAS:
		var dados: DadosArma = load(Ciclo.ARMAS[id])
		var liberada: bool = Ciclo.arma_liberada(id)
		var escolhida: bool = Ciclo.arma_escolhida == id
		lista.append({
			"nome": dados.nome, "descricao": dados.descricao if liberada else "Ainda não liberada.",
			"direita": "EQUIPADA" if escolhida else ("ESCOLHER" if liberada else "—"), "ativo": escolhida,
			"pode": liberada and not escolhida, "motivo": "Equipada." if escolhida else "Ainda não liberada.",
			"feito": "%s equipada." % dados.nome,
			"acao": func() -> bool: return escolher_arma(id),
		})
	lista.append(_opcao_melhoria(melhorias.item("treino_garrak")))
	return lista


func escolher_arma(id: StringName) -> bool:
	if not Ciclo.escolher_arma(id):
		return false
	Dialogos.tocar("arsenal_escolha_" + String(id))
	return true


# --- Cenário provisório ---

func _montar_cenario() -> void:
	var chao := Bloco.new()
	chao.position = Vector2(-16, CHAO)
	chao.tamanho = Vector2(LARGURA + 32, 48)
	chao.cor = Color("3b3f4a")
	add_child(chao)
	for x: float in [-16.0, LARGURA]:
		var parede := Bloco.new()
		parede.position = Vector2(x, 0)
		parede.tamanho = Vector2(16, 270)
		parede.cor = Color("16111c")
		add_child(parede)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-480, -100, LARGURA + 960, 500), Color("120f18"))
	for a: Array in AREAS:
		var r := Rect2(a[1], 40, a[2] - a[1], CHAO - 40)
		draw_rect(r, a[3])
		draw_rect(Rect2(a[1], 40, 2, CHAO - 40), Color("16111c"))
		draw_string(Fontes.pequena(), Vector2(a[1] + 8, 56), a[0], HORIZONTAL_ALIGNMENT_LEFT, -1, Fontes.TAMANHO_PEQUENA, Color("6b6f7a"))
	# Janelas da Ponte com Varrek lá embaixo
	draw_rect(Rect2(320, 70, 280, 50), Color("3a2238"))
	draw_circle(Vector2(460, 150), 50.0, Color("6b3a2a"))
	draw_rect(Rect2(320, 120, 280, 40), Color("1f2a33"))
