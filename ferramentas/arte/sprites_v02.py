"""ART v0.2 — gera os sprites do Ryker, do Guerreiro de Clã, o tileset e o parallax de Varrek.

Uso: python3 ferramentas/arte/sprites_v02.py   (Python 3 + Pillow)
Tudo sai em assets/sprites/. Rodar de novo sobrescreve os PNGs.
A arma do Ryker é PROVISÓRIA (D-038): troque `desenhar_arma` quando GD/NAR definirem a arma própria.
"""
from PIL import Image, ImageDraw
import math, os, random, sys

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
from prancha_estilo import PAL, ENV, rgb, hx, outline, bayer  # paleta v0.1 (D-033)

RAIZ = os.path.normpath(os.path.join(AQUI, '..', '..', 'assets', 'sprites'))
TRANSP = (0, 0, 0, 0)


def salvar(img, *partes):
    p = os.path.join(RAIZ, *partes)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    img.save(p)
    return p


def folha(quadros):
    w, h = quadros[0].size
    f = Image.new('RGBA', (w * len(quadros), h), TRANSP)
    for i, q in enumerate(quadros):
        f.alpha_composite(q, (i * w, 0))
    return f


def disco(img, x, y, r, cor):
    w, h = img.size
    for yy in range(int(y - r) - 1, int(y + r) + 2):
        for xx in range(int(x - r) - 1, int(x + r) + 2):
            if 0 <= xx < w and 0 <= yy < h and (xx + 0.5 - x) ** 2 + (yy + 0.5 - y) ** 2 <= r * r:
                img.putpixel((xx, yy), cor)


def segmento(img, a, b, r, cor):
    n = max(2, int(math.dist(a, b) * 3))
    for i in range(n + 1):
        t = i / n
        disco(img, a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, r, cor)


def linha(img, a, b, cor):
    """Bresenham, 1 px."""
    x0, y0 = map(int, map(round, a)); x1, y1 = map(int, map(round, b))
    dx, dy = abs(x1 - x0), -abs(y1 - y0); sx = 1 if x0 < x1 else -1; sy = 1 if y0 < y1 else -1; e = dx + dy
    w, h = img.size
    while True:
        if 0 <= x0 < w and 0 <= y0 < h: img.putpixel((x0, y0), cor)
        if x0 == x1 and y0 == y1: break
        e2 = 2 * e
        if e2 >= dy: e += dy; x0 += sx
        if e2 <= dx: e += dx; y0 += sy


def ascii_em(img, txt, ox=0, oy=0):
    for y, r in enumerate(txt.strip('\n').split('\n')):
        for x, ch in enumerate(r):
            if ch not in '. ':
                xx, yy = x + ox, y + oy
                if 0 <= xx < img.size[0] and 0 <= yy < img.size[1]:
                    img.putpixel((xx, yy), rgb(ch))


def camada(w=32, h=32):
    return Image.new('RGBA', (w, h), TRANSP)


def compor(*camadas):
    base = camada(*camadas[0].size)
    for c in camadas:
        base.alpha_composite(c)
    return base


# =====================================================================
# RYKER — quadro 32×32, origem nos pés em (16, 32). Olhando para a direita.
# =====================================================================
QUADRIL_Y = 18  # 14 px acima dos pés (corpo de 28 px: hitbox 12×28)
COXA, CANELA = 6.0, 6.0


def perna(quadril, ang_coxa, dobra_joelho, cor, cor_bota):
    """ang_coxa: graus a partir da vertical, + = para frente. dobra: quanto a canela volta para trás."""
    c = camada()
    a1 = math.radians(ang_coxa); a2 = math.radians(ang_coxa - dobra_joelho)
    joelho = (quadril[0] + COXA * math.sin(a1), quadril[1] + COXA * math.cos(a1))
    tornoz = (joelho[0] + CANELA * math.sin(a2), joelho[1] + CANELA * math.cos(a2))
    segmento(c, quadril, joelho, 1.6, cor)
    segmento(c, joelho, tornoz, 1.4, cor)
    # bota: 4 px para a frente do tornozelo, 2 de altura
    tx, ty = int(round(tornoz[0])), int(round(tornoz[1]))
    d = ImageDraw.Draw(c)
    d.rectangle((tx - 1, ty - 1, tx + 2, ty), fill=cor_bota)
    return outline(c), max(ty, 0)


def pernas_quadro(frente, tras, quadril_y=QUADRIL_Y, apoiar=True):
    """frente/tras = (ang_coxa, dobra). Retorna (camada, deslocamento_y aplicado)."""
    pt, yt = perna((14.5, quadril_y), tras[0], tras[1], rgb('B'), rgb('O'))
    pf, yf = perna((17.5, quadril_y), frente[0], frente[1], rgb('b'), rgb('O'))
    quadril = camada(); d = ImageDraw.Draw(quadril)
    d.rectangle((12, quadril_y - 1, 20, quadril_y + 1), fill=rgb('b'))
    d.line((12, quadril_y + 1, 20, quadril_y + 1), fill=rgb('B'))
    quadril = outline(quadril)
    q = compor(pt, quadril, pf)
    desl = 0
    if apoiar:  # encosta o pé mais baixo no chão (linha 31)
        desl = 31 - max(yt, yf)
        if desl:
            q2 = camada(); q2.alpha_composite(q, (0, desl)); q = q2
    return q, desl


CORRER = [((35, 10), (-35, 30)), ((20, 20), (-15, 75)), ((0, 15), (15, 80)), ((-20, 10), (35, 40)),
          ((-35, 30), (35, 10)), ((-15, 75), (20, 20)), ((15, 80), (0, 15)), ((35, 40), (-20, 10))]
PULO = [  # subida 2, topo 1, queda 2, pouso 2
    ((40, 70), (-10, 30), 0), ((30, 60), (-15, 40), 0), ((45, 95), (5, 70), 0),
    ((10, 20), (-20, 15), 0), ((15, 10), (-10, 5), 0),
    ((55, 110), (-25, 60), 4), ((25, 45), (-10, 25), 1)]


def pernas_ryker():
    saida = {}
    parado, _ = pernas_quadro((6, 0), (-6, 0))
    saida['parado'] = ([parado], [0])
    q, d = zip(*[pernas_quadro(f, t) for f, t in CORRER]); saida['correr'] = (list(q), list(d))
    qs, ds = [], []
    for f, t, abaixa in PULO:
        q, dd = pernas_quadro(f, t, QUADRIL_Y + abaixa, apoiar=abaixa > 0)
        qs.append(q); ds.append(dd if abaixa else 0)
    saida['pulo'] = (qs, ds)
    # agachado: quadril 4 px acima do chão; tronco desce 10 px (hitbox 12×18)
    ag, _ = pernas_quadro((72, 150), (-60, 30), 28, apoiar=False)
    saida['agachado'] = ([ag], [0])
    qs = []
    for i in range(6):
        s = math.sin(i / 6 * 2 * math.pi)
        q, _ = pernas_quadro((70 + 8 * s, 148 + 6 * s), (-58 - 8 * s, 30), 28, apoiar=False)
        qs.append(q)
    saida['agachado_andar'] = (qs, [0] * 6)
    return saida


TRONCO_ASCII = """
............k.kk.k..............
...........kckcckck.............
...........kcccccck.............
..........akSScsssk.............
..........kSSsssksk.............
...........kSssssssk............
............kSsSSsk.............
............kkSSSkk.............
...........kOooshhk.............
..........kOoossshhk............
..........kOoosssohk............
..........kOoosssohk............
...........kOkwwkOk.............
...........kOOwwOOk.............
"""  # topo da cabeça na linha 4; cintura na linha 17

OMBREIRA_ASCII = """
...............k.k
..............kwkwk
.............kwwwWk
.............kWWWk.
"""  # troféu da final da Grande Arena, no ombro DIREITO (o da frente, olhando para a direita)

DIRECOES = {  # nome: vetor de mira (y para baixo)
    'frente': (1, 0), 'diag_cima': (1, -1), 'cima': (0, -1), 'diag_baixo': (1, 1), 'baixo': (0, 1)}
OMBRO_FRENTE, OMBRO_TRAS = (18.5, 13.5), (13.5, 13.5)


def braco(c, ombro, mao, cor, cor_sombra, dobra=1, cor_antebraco=None):
    # IK de 2 ossos (4 + 4 px), cotovelo para baixo
    L1 = L2 = 4.2
    dx, dy = mao[0] - ombro[0], mao[1] - ombro[1]; dist = min(math.hypot(dx, dy), L1 + L2 - 0.01)
    base = math.atan2(dy, dx)
    alfa = math.acos(max(-1, min(1, (L1 * L1 + dist * dist - L2 * L2) / (2 * L1 * dist))))
    opcoes = [(ombro[0] + L1 * math.cos(base + alfa * sg), ombro[1] + L1 * math.sin(base + alfa * sg)) for sg in (1, -1)]
    cotovelo = max(opcoes, key=lambda p: p[1])  # cotovelo sempre para baixo, longe do rosto
    segmento(c, ombro, cotovelo, 0.95, cor)
    segmento(c, cotovelo, mao, 0.9, cor_antebraco or cor)  # faixas de luta no antebraço
    disco(c, mao[0], mao[1], 1.0, cor_sombra)


# ---------------------------------------------------------------- armas (D-041)
# Cada arma é um "mapa" cor(t, s): t = distância ao longo do cano (0 = empunhadura),
# s = distância lateral (negativo = lado de cima). Desenhada em qualquer direção de mira.
def _mordida(t, s):
    """Mordida: rebitadeira de mineração (NAR-03). Faixas de perigo LARANJA e pretas (amarelo é a cor AVISO)."""
    if -1.2 <= t <= 0.2 and 1.2 <= s <= 3.0: return 'x'                      # cabo
    if 2.0 <= t <= 5.0 and 1.2 <= s <= 3.2: return 'm'                       # carregador de rebites
    if -4.0 <= t <= -1.5 and -1.5 <= s <= 0.6: return 'w' if s < -0.3 else 'W'  # placa de osso Kharn (sucata)
    if -4.0 <= t <= 9.0 and -1.5 <= s <= 1.2:
        if 1.0 <= t <= 7.0 and s < 0.0: return 'o' if int(t // 2) % 2 else 'k'  # faixas de perigo
        return 'X' if s < -0.6 else 'x'
    if 9.0 <= t <= 10.6 and -1.0 <= s <= 0.8:
        return 'h' if t >= 10.1 and abs(s) <= 0.35 else 'x'                  # bico com rebite incandescente
    return None


def _bramido(t, s):
    """Bramido: canhão dos campeões do Clã Kesh (NAR-03), quase do tamanho do Ryker."""
    if -1.0 <= t <= 1.0 and 2.5 <= s <= 5.0: return 'x'                      # empunhadura humana soldada
    if -5.0 <= t < -2.0 and -2.0 <= s <= 2.0: return 'x'
    if -2.0 <= t < 13.0 and -3.0 <= s <= 2.5:
        if 0.0 <= t <= 8.0 and s <= -0.5: return 'w' if s < -1.5 else 'W'    # placas de osso
        if 9.5 <= t <= 10.5 or 11.5 <= t <= 12.5: return 'e'                # listras do Clã Kesh
        return 'X' if s < -2.2 else 'x'
    if 13.0 <= t <= 16.6 and -3.5 <= s <= 3.0:
        if t >= 15.8 and abs(s) <= 1.3: return 'f'                           # brasa dentro da boca
        return 'X' if s < -2.7 else 'x'
    return None


ARMAS = {  # mapa, limites (t0, t1, s0, s1), comprimento até a boca, distância da mão de apoio
    'mordida': (_mordida, (-4.5, 11.0, -2.0, 3.5), 10.6, 4.0),
    'bramido': (_bramido, (-5.5, 17.0, -4.0, 5.5), 16.6, 7.0),
}


def desenhar_arma(c, empunhadura, d, recuo, arma='mordida'):
    fn, (t0, t1, s0, s1), comp, _ = ARMAS[arma]
    ux, uy = d; n = math.hypot(ux, uy); ux, uy = ux / n, uy / n
    px_, py_ = -uy, ux  # perpendicular: + = lado de baixo da arma
    g = (empunhadura[0] - ux * recuo, empunhadura[1] - uy * recuo)
    lc = camada(*c.size); W, H = c.size
    raio = int(max(abs(t0), abs(t1), abs(s0), abs(s1))) + 2
    for y in range(int(g[1]) - raio, int(g[1]) + raio + 1):  # pinta cada pixel pelo seu centro
        for x in range(int(g[0]) - raio, int(g[0]) + raio + 1):
            if not (0 <= x < W and 0 <= y < H): continue
            dx, dy = x + 0.5 - g[0], y + 0.5 - g[1]
            t, s_ = dx * ux + dy * uy, dx * px_ + dy * py_
            if t0 <= t <= t1 and s0 <= s_ <= s1:
                ch = fn(t, s_)
                if ch: lc.putpixel((x, y), rgb(ch))
    c.alpha_composite(outline(lc))
    return (g[0] + ux * comp, g[1] + uy * comp)


def clarao(q, cano, u, tipo):
    """Clarões de boca. Nunca usam a cor AVISO (D-033)."""
    cx, cy = cano
    if tipo == 'mordida':
        disco(q, cx + u[0] * 2, cy + u[1] * 2, 1.8, rgb('h')); disco(q, cx + u[0] * 2, cy + u[1] * 2, 1.0, rgb('t'))
    elif tipo == 'mordida_rajada':  # três clarões em fila = "rajada de 3"
        for k, r in ((2, 1.7), (5, 1.4), (8, 1.1)):
            disco(q, cx + u[0] * k, cy + u[1] * k, r, rgb('h'))
        disco(q, cx + u[0] * 2, cy + u[1] * 2, 0.9, rgb('t'))
    elif tipo == 'bramido_balins':  # leque largo e curto
        for ang in (-28, -14, 0, 14, 28):
            a = math.radians(ang); v = (u[0] * math.cos(a) - u[1] * math.sin(a), u[0] * math.sin(a) + u[1] * math.cos(a))
            segmento(q, (cx, cy), (cx + v[0] * 6, cy + v[1] * 6), 0.7, rgb('f'))
            segmento(q, (cx, cy), (cx + v[0] * 3.5, cy + v[1] * 3.5), 0.6, rgb('h'))
        disco(q, cx + u[0], cy + u[1], 1.6, rgb('t'))
    elif tipo == 'bramido_cerco':  # jato longo e estreito = "bala única"
        segmento(q, (cx, cy), (cx + u[0] * 10, cy + u[1] * 10), 1.5, rgb('f'))
        segmento(q, (cx, cy), (cx + u[0] * 7, cy + u[1] * 7), 0.8, rgb('t'))


def tronco_quadro(nome, recuo=0, flash=None, arma='mordida', lado=32):
    """Tronco + braços + arma numa direção. lado 32 (origem nos pés em (16,32)) ou 48 (origem em (24,48))."""
    ox, oy = (lado - 32) // 2, lado - 32
    d = DIRECOES[nome]; n = math.hypot(*d); u = (d[0] / n, d[1] / n)
    sh = lambda p: (p[0] + ox, p[1] + oy)
    centro = sh((17.0, 15.5))  # altura do peito
    emp = (centro[0] + u[0] * 5 + (2 if d[0] == 0 else 0), centro[1] + u[1] * 4)
    dist_apoio = ARMAS[arma][3]
    apoio = (emp[0] + u[0] * dist_apoio, emp[1] + u[1] * dist_apoio)
    bt = camada(lado, lado)
    braco(bt, sh(OMBRO_TRAS), (apoio[0] - u[0] * recuo, apoio[1] - u[1] * recuo), rgb('S'), rgb('m'), 1, rgb('m'))
    mx, my = int(apoio[0] - u[0] * recuo), int(apoio[1] - u[1] * recuo)
    if 0 <= mx < lado and 0 <= my < lado: bt.putpixel((mx, my), rgb('M'))  # algema
    for i in range(1, 4):  # corrente pendurada (sempre cai para baixo)
        if 0 <= my + i < lado and 0 <= mx - (i // 2) < lado: bt.putpixel((mx - (i // 2), my + i), rgb('m'))
    bt = outline(bt)
    corpo = camada(lado, lado); ascii_em(corpo, TRONCO_ASCII, ox, 4 + oy); corpo = outline(corpo)
    camada_arma = camada(lado, lado); cano = desenhar_arma(camada_arma, emp, u, recuo, arma)
    bf = camada(lado, lado); braco(bf, sh(OMBRO_FRENTE), (emp[0] - u[0] * recuo, emp[1] - u[1] * recuo), rgb('s'), rgb('M'), -1, rgb('M'))
    bf = outline(bf)
    omb = camada(lado, lado); ascii_em(omb, OMBREIRA_ASCII, ox, 11 + oy)
    q = compor(bt, corpo, camada_arma, bf, omb)
    if flash: clarao(q, cano, u, flash)
    return q


def tronco_ryker(arma='mordida', lado=48):
    """4 quadros por direção: 0 parado, 1 disparo, 2 recuo, 3 disparo do modo especial. Quadro 48×48, origem (24, 48)."""
    if arma == 'mordida':
        return {n: [tronco_quadro(n, 0, None, 'mordida', lado), tronco_quadro(n, 1, 'mordida', 'mordida', lado),
                    tronco_quadro(n, 1, None, 'mordida', lado), tronco_quadro(n, 1, 'mordida_rajada', 'mordida', lado)]
                for n in DIRECOES}
    return {n: [tronco_quadro(n, 0, None, 'bramido', lado), tronco_quadro(n, 2, 'bramido_balins', 'bramido', lado),
                tronco_quadro(n, 1, None, 'bramido', lado), tronco_quadro(n, 2, 'bramido_cerco', 'bramido', lado)]
            for n in DIRECOES}


def silhueta_cor(img, cor):
    out = camada(*img.size); px = img.load(); c = rgb(cor)
    for y in range(img.size[1]):
        for x in range(img.size[0]):
            if px[x, y][3]: out.putpixel((x, y), c[:3] + (px[x, y][3],))
    return out


def ryker_inteiro(pernas, tronco, desl=0, tronco_dy=0):
    """Pernas (32×32) + tronco (48×48) num quadro 48×48, origem nos pés em (24, 48)."""
    q = camada(48, 48); q.alpha_composite(pernas, (8, 16))
    t = camada(48, 48); t.alpha_composite(tronco, (0, desl + tronco_dy)); q.alpha_composite(t)
    return q


def dash_ryker(pern, tron):
    base_p, d = pernas_quadro((40, 20), (-50, 40))
    corpo = ryker_inteiro(base_p, tron['frente'][0], d, 1)
    rastro = silhueta_cor(corpo, 'a'); rastro.putalpha(rastro.getchannel('A').point(lambda v: v * 0.45))
    quadros = []
    for i, off in enumerate([0, 3, 5, 6]):  # rastro âmbar ficando para trás
        q = camada(48, 48)
        if i > 0:
            q.alpha_composite(rastro, (-off - 4, 0))
        q.alpha_composite(corpo)
        quadros.append(q)
    return quadros


def morte_ryker(pern, tron):
    """O corpo vira poeira de luz âmbar subindo: a âncora puxando de volta para a Eco."""
    corpo = ryker_inteiro(pern['parado'][0][0], tron['frente'][0])
    rnd = random.Random(4); px = [(x, y) for y in range(48) for x in range(48) if corpo.getpixel((x, y))[3]]
    ordem = sorted(px, key=lambda p: (p[1] + rnd.random() * 10))  # some de cima para baixo, com ruído
    quadros = []
    for i in range(8):
        q = corpo.copy(); n = int(len(ordem) * i / 7)
        for (x, y) in ordem[:n]:
            q.putpixel((x, y), TRANSP)
        for (x, y) in ordem[max(0, n - 25):n]:
            yy = y - (i * 2) - rnd.randint(0, 3)
            if 0 <= yy < 48 and rnd.random() < 0.45:
                q.putpixel((x, yy), rgb('a') if rnd.random() < 0.7 else rgb('t'))
        quadros.append(q)
    return quadros


# =====================================================================
# GUERREIRO DE CLÃ — quadro 64×64, origem nos pés em (32, 64). Olhando para a direita.
# Canhão em (+26, -38) a partir da origem (bate com _ponto_canhao do DEV: ±16 de largura, 0,6 da altura).
# =====================================================================
def guerreiro(fase=0.0, brilho=0, armadura=True, dy=0, recuo=0, inclina=0):
    """brilho: 0 normal, 1 carregando (brasa), 2 aviso final (cor AVISO), 3 disparo."""
    W, H = 64, 64
    im = camada(W, H); d = ImageDraw.Draw(im)
    g, G, l, w, Wc, e, f, x, X = (rgb(c) for c in 'gGlwWefxX')
    ox = 14 + inclina  # desloca o desenho original (44 de largura) para centrar o corpo em x=32
    s = math.sin(fase * 2 * math.pi); c_ = math.cos(fase * 2 * math.pi)
    a = int(round(2 * s)); lev_t = max(0, int(round(2 * c_))); lev_f = max(0, int(round(-2 * c_)))
    P = lambda pts: [(px_ + ox, py_ + dy) for px_, py_ in pts]
    d.polygon(P([(8, 44), (0, 58 - a), (2, 60 - a), (12, 50)]), fill=G)  # cauda balança
    d.polygon(P([(10 - a, 44), (20 - a, 44), (18 - a, 54), (22 - a, 62 - lev_t), (10 - a, 62 - lev_t), (13 - a, 54)]), fill=G)
    d.polygon(P([(20 + a, 44), (30 + a, 44), (28 + a, 54), (32 + a, 62 - lev_f), (20 + a, 62 - lev_f), (23 + a, 54)]), fill=g)
    by = -1 if abs(s) > 0.7 else 0  # sobe 1 px no meio do passo
    Q = lambda pts: [(px_ + ox, py_ + dy + by) for px_, py_ in pts]
    def ell(b, cor): d.ellipse((b[0] + ox, b[1] + dy + by, b[2] + ox, b[3] + dy + by), fill=cor)
    def ret(b, cor): d.rectangle((b[0] + ox, b[1] + dy + by, b[2] + ox, b[3] + dy + by), fill=cor)
    ell((4, 14, 32, 50), g)
    ell((24, 8, 36, 20), g)
    d.polygon(Q([(30, 16), (38, 15), (37, 19), (29, 20)]), fill=G)
    ell((5, 12, 22, 27), w)
    d.polygon(Q([(6, 12), (4, 4), (10, 11)]), fill=w); d.polygon(Q([(13, 10), (13, 2), (17, 10)]), fill=w)
    d.polygon(Q([(19, 12), (22, 5), (23, 13)]), fill=Wc)
    if armadura:
        ret((25, 22, 32, 42), x); ret((26, 23, 31, 30), w); ret((26, 32, 31, 41), Wc)
    d.line(Q([(8, 30), (14, 36)]), fill=e); d.line(Q([(8, 34), (12, 38)]), fill=e)
    cy = 26 - by - dy  # canhão alinhado em y=26 do quadro (38 px acima dos pés) quando dy=0
    r = -recuo
    d.rectangle((22 + ox + r, cy - 3 + dy + by, 38 + ox + r, cy + 3 + dy + by), fill=x)
    d.rectangle((23 + ox + r, cy - 3 + dy + by, 38 + ox + r, cy - 2 + dy + by), fill=X)
    d.rectangle((38 + ox + r, cy - 4 + dy + by, 42 + ox + r, cy + 4 + dy + by), fill=x)
    boca = {0: f, 1: f, 2: rgb('y'), 3: rgb('t')}[brilho]
    d.rectangle((40 + ox + r, cy - 1 + dy + by, 42 + ox + r, cy + 2 + dy + by), fill=boca)
    d.polygon(Q([(14, 40), (20, 40), (22, 46), (14, 46)]), fill=G)
    from prancha_estilo import shade_lower
    shade_lower(im, 'g', 'G', 0.35); shade_lower(im, 'w', 'W', 0.3)
    xs = [xx for xx in range(24 + ox, 31 + ox) if 0 <= xx < W]
    for xx in xs:
        yy = 15 + dy + by
        if 0 <= yy < H and im.getpixel((xx, yy))[3] and im.getpixel((xx, yy))[:3] == g[:3]: im.putpixel((xx, yy), l)
    im = outline(im)
    if brilho in (1, 2, 3):  # halo em volta da boca do canhão
        bx, by2 = 41 + ox + r, cy + dy + by
        dd = ImageDraw.Draw(im)
        if brilho == 1: dd.ellipse((bx - 3, by2 - 3, bx + 3, by2 + 3), outline=f)
        if brilho == 2:
            dd.ellipse((bx - 4, by2 - 4, bx + 4, by2 + 4), fill=rgb('y')); dd.ellipse((bx - 2, by2 - 2, bx + 2, by2 + 2), fill=(255, 255, 255, 255))
        if brilho == 3:
            dd.polygon([(bx + 2, by2 - 4), (bx + 9, by2), (bx + 2, by2 + 4)], fill=f); dd.ellipse((bx - 2, by2 - 2, bx + 2, by2 + 2), fill=rgb('t'))
    return im


def placa_caida():
    im = camada(12, 16); d = ImageDraw.Draw(im)
    d.rectangle((1, 1, 8, 13), fill=rgb('x')); d.rectangle((2, 2, 7, 6), fill=rgb('w')); d.rectangle((2, 8, 7, 12), fill=rgb('W'))
    return outline(im).rotate(-90, expand=True)  # caída de lado no chão


def morte_guerreiro(armadura):
    quadros = [guerreiro(0, 0, armadura, dy=k, inclina=-k // 2) for k in (0, 3, 7)]
    base = quadros[-1]; rnd = random.Random(9)
    for i in range(3):
        q = base.copy(); a = q.getchannel('A').point(lambda v: int(v * (0.7 - 0.3 * i))); q.putalpha(a)
        dd = ImageDraw.Draw(q)
        for _ in range(18 + i * 6):
            px_, py_ = rnd.randint(12, 52), rnd.randint(46, 63) - i * 3
            dd.point((px_, py_), fill=rgb(rnd.choice('WWw')))
        quadros.append(q)
    return quadros


# =====================================================================
# TILESET DE VARREK — 16×16. Terreno "combina lados" (16 tiles, bits N=1 L=2 S=4 O=8).
# =====================================================================
CHAO, LUZ, SOMBRA = hx(ENV['chao']), hx(ENV['chao_luz']), hx(ENV['chao_sombra'])
MEIO = hx('#463e4d')


def tile_casco(mask, variante=0, seed=0):
    rnd = random.Random(seed * 31 + mask)
    t = Image.new('RGBA', (16, 16), CHAO); d = ImageDraw.Draw(t)
    # textura: dither leve de duas tonalidades (cenário não tem contorno)
    for y in range(16):
        for x in range(16):
            if bayer(x + seed, y) < 0.18 and rnd.random() < 0.6: t.putpixel((x, y), MEIO)
    d.line((0, 7, 15, 7), fill=SOMBRA)  # emenda da chapa
    d.line((0, 8, 15, 8), fill=MEIO)
    for rx in (3, 12):
        d.point((rx, 3), fill=LUZ); d.point((rx, 11), fill=LUZ); d.point((rx + 1, 12), fill=SOMBRA)
    if variante == 1:  # grade de ventilação
        d.rectangle((4, 9, 11, 13), fill=SOMBRA)
        for xx in range(5, 11, 2): d.line((xx, 10, xx, 12), fill=CHAO)
    if variante == 2:  # cabo passando
        d.line((0, 4, 6, 5), fill=hx('#2a2430')); d.line((6, 5, 15, 4), fill=hx('#2a2430'))
    if variante == 3:  # placa de casco humano com marca laranja apagada
        d.rectangle((5, 2, 10, 5), fill=hx('#4e3d42'))
    N, L, S, O = mask & 1, mask & 2, mask & 4, mask & 8
    if not N:
        d.line((0, 0, 15, 0), fill=LUZ); d.line((0, 1, 15, 1), fill=hx('#4d4555'))
    if not S:
        d.line((0, 15, 15, 15), fill=hx('#1a1520')); d.line((0, 14, 15, 14), fill=SOMBRA)
    if not O:
        d.line((0, 0 if N else 0, 0, 15), fill=SOMBRA)
        if not N: t.putpixel((0, 0), MEIO)
    if not L:
        d.line((15, 0, 15, 15), fill=hx('#1a1520'))
        if not N: t.putpixel((15, 0), MEIO)
    return t


def tile_plataforma(parte):
    """Plataforma fina de antena (atravessável por baixo): 0 esq, 1 meio, 2 dir. Ocupa os 6 px de cima."""
    t = Image.new('RGBA', (16, 16), TRANSP); d = ImageDraw.Draw(t)
    d.rectangle((0, 0, 15, 5), fill=CHAO); d.line((0, 0, 15, 0), fill=LUZ); d.line((0, 5, 15, 5), fill=hx('#1a1520'))
    for xx in range(2, 16, 4): d.point((xx, 2), fill=SOMBRA)
    if parte == 0: d.line((0, 0, 0, 5), fill=SOMBRA); d.line((3, 6, 3, 12), fill=SOMBRA)
    if parte == 2: d.line((15, 0, 15, 5), fill=hx('#1a1520')); d.line((12, 6, 12, 12), fill=SOMBRA)
    return t


def tile_argola():
    """Ponto de ancoragem do Grilhão: sempre esta peça. Destaque laranja = 'isto é para o Ryker'."""
    t = Image.new('RGBA', (16, 16), TRANSP); d = ImageDraw.Draw(t)
    d.rectangle((5, 0, 10, 3), fill=hx(ENV['chao_luz'])); d.line((5, 3, 10, 3), fill=rgb('k'))
    d.ellipse((3, 4, 12, 13), outline=rgb('M')); d.ellipse((4, 5, 11, 12), outline=rgb('m'))
    d.rectangle((7, 12, 8, 13), fill=rgb('h'))
    return outline(t)


def tile_decor(tipo):
    t = Image.new('RGBA', (16, 16), TRANSP); d = ImageDraw.Draw(t)
    if tipo == 0:  # cabo pendurado
        for y in range(16): t.putpixel((7 + (1 if 5 < y < 11 else 0), y), hx('#2a2430'))
        d.point((8, 15), fill=rgb('f'))
    if tipo == 1:  # luz de socorro humana (pisca no jogo: alternar com tipo 2)
        d.rectangle((5, 10, 10, 15), fill=hx(ENV['chao'])); d.rectangle((6, 11, 9, 12), fill=hx('#c4652e'))
    if tipo == 2:
        d.rectangle((5, 10, 10, 15), fill=hx(ENV['chao'])); d.rectangle((6, 11, 9, 12), fill=hx('#eba35c'))
        d.point((7, 9), fill=hx('#eba35c')); d.point((8, 9), fill=hx('#eba35c'))
    if tipo == 3:  # destroço / sucata no chão
        d.polygon([(1, 15), (4, 10), (9, 12), (14, 9), (15, 15)], fill=hx(ENV['chao_sombra']))
        d.line((4, 10, 9, 12), fill=hx(ENV['chao']))
    return t


def tileset_varrek():
    T = 16
    img = Image.new('RGBA', (T * 8, T * 4), TRANSP)
    for m in range(16):  # linhas 0-1: os 16 tiles de terreno, na ordem do bitmask
        img.alpha_composite(tile_casco(m), ((m % 8) * T, (m // 8) * T))
    for v in range(1, 4):  # linha 2: variantes do miolo (mask 15)
        img.alpha_composite(tile_casco(15, v, v), ((v - 1) * T, 2 * T))
    for p in range(3):
        img.alpha_composite(tile_plataforma(p), ((3 + p) * T, 2 * T))
    img.alpha_composite(tile_argola(), (6 * T, 2 * T))
    for k in range(4):  # linha 3: decoração
        img.alpha_composite(tile_decor(k), (k * T, 3 * T))
    return img


# =====================================================================
# PARALLAX — 480×270 cada, as camadas 1 a 3 emendam na horizontal (repetição sem costura).
# =====================================================================
def ceu_anel():
    from prancha_estilo import ceu, anel_portal
    img = Image.new('RGBA', (480, 270)); ceu(img); anel_portal(img)
    return img


def silhueta_ciclica(base_y, amp, cor, seed, passo, antenas=True):
    rnd = random.Random(seed)
    pad = Image.new('RGBA', (480, 270), TRANSP)
    pts = [(-20, 270)]; x = -20
    while x < 500:
        w = rnd.randint(*passo); y = base_y - rnd.randint(0, amp); tipo = rnd.random()
        if tipo < 0.3: pts += [(x, y + 10), (x + w, y)]
        elif tipo < 0.6 and antenas:
            pts += [(x, y), (x + w // 2, y), (x + w // 2, y - 12), (x + w // 2 + 2, y - 12), (x + w // 2 + 2, y), (x + w, y)]
        else: pts += [(x, y), (x + 3, y - 8), (x + 6, y), (x + w, y + 4)]
        x += w
    pts += [(520, 270)]
    for off in (-480, 0, 480):
        ImageDraw.Draw(pad).polygon([(px_ + off, py_) for px_, py_ in pts], fill=hx(cor))
    return pad


def luzes(img, n, cor, seed, y0, y1):
    rnd = random.Random(seed); px = img.load()
    for _ in range(n):
        x, y = rnd.randrange(480), rnd.randint(y0, y1)
        if px[x, y][3]: px[x, y] = hx(cor)


def primeiro_plano():
    img = Image.new('RGBA', (480, 270), TRANSP); d = ImageDraw.Draw(img); rnd = random.Random(5)
    cor = hx('#120c12')
    x = 0
    while x < 480:  # cabos e vigas pendurados no topo (nunca descem até a faixa de combate)
        comp = rnd.randint(10, 46); larg = rnd.choice((1, 1, 2, 5))
        for off in (-480, 0, 480):
            d.rectangle((x + off, 0, x + off + larg - 1, comp), fill=cor)
            if larg == 5: d.rectangle((x + off - 3, comp - 4, x + off + 7, comp), fill=cor)
        x += rnd.randint(18, 70)
    return img


def parallax():
    longe = silhueta_ciclica(175, 25, ENV['longe'], 1, (14, 34)); luzes(longe, 14, '#7a4a3a', 11, 150, 200)
    meio = silhueta_ciclica(200, 30, ENV['meio'], 2, (20, 46)); luzes(meio, 8, '#4fb0a6', 12, 180, 240)
    return {'0_ceu_anel': ceu_anel(), '1_cascos_longe': longe, '2_cascos_meio': meio, '3_primeiro_plano': primeiro_plano()}



def mockup_v02():
    """Tela de conferência 480×270 com tileset, parallax e sprites (não é uma sala do jogo)."""
    V = os.path.join(RAIZ, 'cenarios', 'varrek')
    tela = Image.new('RGBA', (480, 270))
    for i, n in enumerate(['0_ceu_anel', '1_cascos_longe', '2_cascos_meio']):
        im = Image.open(os.path.join(V, f'varrek_parallax_{n}.png')); off = [0, -130, -260][i] % 480
        tela.alpha_composite(im, (off - 480, 0)); tela.alpha_composite(im, (off, 0))
    ts = Image.open(os.path.join(V, 'varrek_tileset.png'))
    tile = lambda c, r: ts.crop((c * 16, r * 16, c * 16 + 16, r * 16 + 16))
    cols, rows = 30, 17
    mapa = [[1 if y >= 14 or (11 <= y < 14 and 22 <= x < 26) else 0 for x in range(cols)] for y in range(rows)]
    def solido(x, y):
        if y >= rows: return True
        if x < 0 or x >= cols: return y >= 14
        return y >= 0 and mapa[y][x] == 1
    for y in range(rows):
        for x in range(cols):
            if mapa[y][x]:
                m = (solido(x, y - 1)) | (solido(x + 1, y) << 1) | (solido(x, y + 1) << 2) | (solido(x - 1, y) << 3)
                t = tile((x + y) % 3, 2) if m == 15 and (x * 7 + y) % 5 == 0 else tile(m % 8, m // 8)
                tela.alpha_composite(t, (x * 16, y * 16))
    for i, c in enumerate([3, 4, 4, 5]): tela.alpha_composite(tile(c, 2), ((9 + i) * 16, 9 * 16))
    tela.alpha_composite(tile(6, 2), (16 * 16, 4 * 16))
    tela.alpha_composite(tile(1, 3), (4 * 16, 13 * 16)); tela.alpha_composite(tile(3, 3), (18 * 16, 13 * 16))
    pern = pernas_ryker(); tron = tronco_ryker(); qs, ds = pern['correr']
    tela.alpha_composite(ryker_inteiro(qs[2], tron['diag_cima'][1], ds[2]), (86, 176))
    k = guerreiro(0, 2).transpose(Image.FLIP_LEFT_RIGHT); tela.alpha_composite(k, (268, 160))
    tela.alpha_composite(Image.open(os.path.join(V, 'varrek_parallax_3_primeiro_plano.png')))
    return tela

# =====================================================================
# PROJÉTEIS E ÍCONES DAS ARMAS — desenhados apontando para a DIREITA (o código gira).
# Tiros do jogador: sem contorno e claros; tiros inimigos: com contorno (ART-01, seção 3).
# =====================================================================
def projetil(tipo):
    if tipo == 'rebite':  # Mordida: rebite incandescente
        im = camada(7, 3); ascii_em(im, "..oohh.\n.Oohhtt\n..oohh.")
    elif tipo == 'rebite_rajada':  # Mordida no modo rajada (ramo B): rastro mais longo e cabeça mais clara
        im = camada(10, 3); ascii_em(im, "...oohhh..\nOOoohhhttt\n...oohhh..")
    elif tipo == 'golpe_do_campeao':  # Mordida, Ápice A3 "Grande Arena"
        im = camada(14, 7)
        ascii_em(im, "......ohh.....\n...oohhhhhh...\n.Oohhhtttthh..\nOoohhtttttthh.\n.Oohhhtttthh..\n...oohhhhhh...\n......ohh.....")
    elif tipo == 'balim':  # Bramido: cada um dos balins
        im = camada(3, 3); ascii_em(im, ".h.\nhth\n.h.")
    elif tipo == 'bala_cerco':  # Bramido no modo bala única (ramo A)
        im = camada(13, 5); ascii_em(im, "...ffffhh....\n.Offfhhhhtt..\nOfffhhhtttth.\n.Offfhhhhtt..\n...ffffhh....")
    elif tipo == 'bala_carregada':  # Bramido, Ápice A3 "Artilharia" (explode no impacto)
        im = camada(16, 9)
        ascii_em(im, ".......ff.......\n....fffhhff.....\n..ffhhhhhhhf....\n.Ofhhhtttthhf...\nOffhhttttttthf..\n.Ofhhhtttthhf...\n..ffhhhhhhhf....\n....fffhhff.....\n.......ff.......")
    return im


def icone_arma(arma, w, h, escala):
    """Ícone de perfil (Arsenal, árvore): a arma desenhada maior, sem personagem."""
    fn, (t0, t1, s0, s1), comp, _ = ARMAS[arma]
    im = camada(w, h)
    g = (w / 2 - (t0 + t1) / 2 * escala, h / 2 - (s0 + s1) / 2 * escala)
    for y in range(h):
        for x in range(w):
            t, s_ = (x + 0.5 - g[0]) / escala, (y + 0.5 - g[1]) / escala
            ch = fn(t, s_)
            if ch: im.putpixel((x, y), rgb(ch))
    return outline(im)


# =====================================================================
def main():
    pern = pernas_ryker(); tron = tronco_ryker()
    R = ('personagens', 'ryker')
    for nome, (qs, _) in pern.items():
        salvar(folha(qs), *R, f'ryker_pernas_{nome}.png')
    for nome, qs in tron.items():  # Mordida (arma própria) = folhas sem sufixo
        salvar(folha(qs), *R, f'ryker_tronco_{nome}.png')
    for nome, qs in tronco_ryker('bramido').items():
        salvar(folha(qs), *R, f'ryker_tronco_bramido_{nome}.png')
    for tipo in ('rebite', 'rebite_rajada', 'golpe_do_campeao', 'balim', 'bala_cerco', 'bala_carregada'):
        salvar(projetil(tipo), 'armas', 'projeteis', f'{tipo}.png')
    salvar(icone_arma('mordida', 32, 16, 1.9), 'armas', 'icones', 'icone_mordida.png')
    salvar(icone_arma('bramido', 48, 24, 1.9), 'armas', 'icones', 'icone_bramido.png')
    salvar(folha(dash_ryker(pern, tron)), *R, 'ryker_dash.png')
    salvar(folha(morte_ryker(pern, tron)), *R, 'ryker_morte.png')
    for nome, (_, ds) in pern.items():  # deslocamento do tronco por quadro (copiar para o LEIAME se mudar)
        print(f'pernas {nome}: {ds}')

    K = ('inimigos', 'kharn', 'guerreiro_cla')
    for arm, suf in ((True, ''), (False, '_sem_armadura')):
        salvar(folha([guerreiro(i / 6, 0, arm) for i in range(6)]), *K, f'guerreiro_andar{suf}.png')
        salvar(folha([guerreiro(0, 1, arm), guerreiro(0, 2, arm)]), *K, f'guerreiro_aviso{suf}.png')
        salvar(folha([guerreiro(0, 3, arm, recuo=2), guerreiro(0, 0, arm, recuo=1)]), *K, f'guerreiro_tiro{suf}.png')
        salvar(folha(morte_guerreiro(arm)), *K, f'guerreiro_morte{suf}.png')
    salvar(placa_caida(), *K, 'guerreiro_placa_caida.png')

    salvar(tileset_varrek(), 'cenarios', 'varrek', 'varrek_tileset.png')
    for nome, im in parallax().items():
        salvar(im, 'cenarios', 'varrek', f'varrek_parallax_{nome}.png')
    salvar(mockup_v02(), 'conceito', 'mockup_v02_varrek.png')
    print('ok')


if __name__ == '__main__':
    main()
