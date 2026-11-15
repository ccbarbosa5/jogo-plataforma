class_name EfeitosArvore
extends RefCounted
## Nós da árvore de Combate que precisam de código na run (GD-07 §4.3), fora da arma e do
## Grilhão: Estilhaços, Recarga de Campo e Bomba de Fragmentação (Granada) e Esquiva de Arena
## (Dash). Os números simples (Cinto, Pavio Curto, Passo Leve, Dash Duplo) vêm de
## ProgressaoPersonagem.aplicar().

const ESTILHACOS: int = 4
const DANO_ESTILHACO: int = 10
const MORTES_POR_GRANADA: int = 3
const GRANADAS_MENORES: int = 3
const DANO_MENOR: int = 25
## 24 px
const RAIO_MENOR_TILES: float = 1.5
const BONUS_ESQUIVA: float = 0.5
const JANELA_ESQUIVA: float = 1.0
const CENA_ESTILHACO: String = "res://scenes/armas/projetil_jogador.tscn"

var jogador: Jogador
var mortes: int = 0


func _init(jogador_: Jogador) -> void:
	jogador = jogador_


func conectar() -> void:
	jogador.lancou_granada.connect(_ao_lancar_granada)
	jogador.controle_arma.acertou.connect(func(_i: Inimigo, _info: InfoDano, matou: bool) -> void:
		if matou:
			contar_morte())


func _ao_lancar_granada(g: Granada) -> void:
	g.explodiu.connect(_ao_explodir.bind(g))


func _ao_explodir(atingidos: Array[Node], g: Granada) -> void:
	for alvo in atingidos:
		var inimigo := alvo as Inimigo
		if inimigo != null and not inimigo.esta_vivo():
			contar_morte()
	if g.has_meta("menor"):
		return  # as menores não se dividem de novo
	var destino: Node = g.get_parent()
	var centro: Vector2 = g.global_position
	if jogador.tem_no(&"granada_estilhacos"):
		_soltar_estilhacos.call_deferred(destino, centro)
	if jogador.tem_no(&"granada_bomba_de_fragmentacao"):
		_soltar_menores.call_deferred(destino, centro)


## Recarga de Campo: a cada 3 mortes, +1 granada (até o limite da sala).
func contar_morte() -> void:
	if not jogador.tem_no(&"granada_recarga_de_campo") or jogador.granada == null:
		return
	mortes += 1
	if mortes % MORTES_POR_GRANADA == 0 and jogador.granadas < jogador.granada.por_sala:
		jogador.granadas += 1


## Esquiva de Arena: atravessar um golpe ou projétil durante o dash.
func ao_atravessar_no_dash() -> void:
	if jogador.tem_no(&"dash_esquiva_de_arena"):
		jogador.controle_arma.armar_bonus_proximo_tiro(BONUS_ESQUIVA, JANELA_ESQUIVA)


func _soltar_estilhacos(destino: Node, centro: Vector2) -> void:
	if destino == null or not is_instance_valid(destino):
		return
	var cena: PackedScene = load(CENA_ESTILHACO)
	for i in ESTILHACOS:
		var e: Projetil = cena.instantiate()
		destino.add_child(e)
		var dir: Vector2 = Vector2.RIGHT.rotated(TAU * (float(i) + 0.5) / ESTILHACOS)
		e.configurar(centro, dir, 200.0, InfoDano.criar(DANO_ESTILHACO, jogador), 0.25,
				Camadas.PROJETEIS_JOGADOR, Camadas.MUNDO | Camadas.INIMIGOS)
		e.fragmento = true


func _soltar_menores(destino: Node, centro: Vector2) -> void:
	if destino == null or not is_instance_valid(destino) or jogador.granada == null or jogador.granada.cena == null:
		return
	var dados: DadosGranada = jogador.efeitos.dados_da_granada(jogador.granada).duplicate()
	dados.dano = DANO_MENOR
	dados.raio = RAIO_MENOR_TILES
	for i in GRANADAS_MENORES:
		var g: Granada = jogador.granada.cena.instantiate()
		g.set_meta("menor", true)
		destino.add_child(g)
		var angulo: float = deg_to_rad(-90.0 + (i - 1) * 40.0)
		g.lancar(centro + Vector2(0, -4), Vector2.RIGHT.rotated(angulo) * 120.0, dados, jogador)
		g.explodiu.connect(_ao_explodir.bind(g))
