class_name CenarioTeste
## Ajudantes para montar cenários mínimos dentro dos testes.

const CENA_RYKER: String = "res://scenes/jogador/ryker.tscn"
const CENA_SOLDADO: String = "res://scenes/inimigos/soldado.tscn"
const CHAO_Y: float = 0.0


## Cria um bloco sólido (ou plataforma de mão única) com o topo em `topo_esquerdo`.
static func criar_bloco(pai: Node, topo_esquerdo: Vector2, tamanho: Vector2, uma_via: bool = false) -> Bloco:
	var bloco := Bloco.new()
	pai.add_child(bloco)
	bloco.position = topo_esquerdo
	bloco.tamanho = tamanho
	bloco.uma_via = uma_via
	return bloco


## Chão longo com o topo em y = CHAO_Y, de x = inicio até x = fim.
static func criar_chao(pai: Node, inicio: float = -2000.0, fim: float = 2000.0) -> Bloco:
	return criar_bloco(pai, Vector2(inicio, CHAO_Y), Vector2(fim - inicio, 32.0))


## Ryker controlado por um EntradaJogador "manual" (o teste preenche os campos).
static func criar_jogador(caso: TestCase, posicao: Vector2 = Vector2(0, CHAO_Y)) -> Jogador:
	var jogador := caso.instanciar(CENA_RYKER) as Jogador
	jogador.entrada = EntradaJogador.new()
	jogador.global_position = posicao
	jogador.container_projeteis = caso
	return jogador


static func criar_soldado(caso: TestCase, posicao: Vector2, pesado: bool = false) -> Soldado:
	var cena: PackedScene = load(CENA_SOLDADO)
	var soldado := cena.instantiate() as Soldado
	soldado.pesado = pesado
	caso.add_child(soldado)
	soldado.global_position = posicao
	soldado.container_projeteis = caso
	return soldado


static func tiles(n: float) -> float:
	return Unidades.px(n)
