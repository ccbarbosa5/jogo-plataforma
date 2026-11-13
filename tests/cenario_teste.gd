class_name CenarioTeste
## Ajudantes para montar cenários mínimos dentro dos testes.

const CENA_RYKER: String = "res://scenes/jogador/ryker.tscn"
const CENA_GUERREIRO: String = "res://scenes/inimigos/guerreiro_cla.tscn"
const CENA_BONECO: String = "res://scenes/inimigos/boneco.tscn"
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


static func criar_guerreiro(caso: TestCase, posicao: Vector2) -> GuerreiroCla:
	var cena: PackedScene = load(CENA_GUERREIRO)
	var g := cena.instantiate() as GuerreiroCla
	caso.add_child(g)
	g.global_position = posicao
	g.container_projeteis = caso
	return g


## Boneco de treino (não anda nem ataca) com o peso e o tamanho pedidos.
static func criar_boneco(caso: TestCase, posicao: Vector2, peso: Inimigo.Peso = Inimigo.Peso.MEDIO,
		tamanho: Vector2 = Vector2(20, 32), armadura: bool = false, vida: int = 500) -> Boneco:
	var cena: PackedScene = load(CENA_BONECO)
	var b := cena.instantiate() as Boneco
	b.peso = peso
	b.tamanho = tamanho
	b.armadura_frontal = armadura
	b.get_node("Vida").maxima = vida
	caso.add_child(b)
	b.global_position = posicao
	return b


static func tiles(n: float) -> float:
	return Unidades.px(n)
