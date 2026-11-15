"""ART-4 — inimigos de enxame de Varrek (GD-08, seção 2): Roedor, Chacal de Clã e Zangão (animado).

Uso: python3 ferramentas/arte/horda_v01.py   (Python 3 + Pillow).
Saída: assets/sprites/inimigos/{vesh/roedor, kharn/chacal, vesh/zangao}/ + conceito/mockup_v12_horda.png.

Regras de enxame (GD-08): pequeno, legível em bando, poucas cores (4–5 + contorno), animação curta.
Todos desenhados olhando para a DIREITA (para a esquerda, flip_h), origem nos pés (voadores: no centro).
"""
from PIL import Image
import os, sys, random

AQUI = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, AQUI)
from prancha_estilo import rgb, outline
from sprites_v02 import salvar, folha, camada, ascii_em

RAIZ = os.path.join(AQUI, '..', '..')


def _px(img, x, y, c):
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), rgb(c))


def _perna(img, x, y, dx, comp, c):
    """Perna de 1 px que desce 'comp' px e termina deslocada 'dx' (passada)."""
    for i in range(comp):
        _px(img, x + round(dx * i / max(1, comp - 1)), y + i, c)


# =====================================================================
# ROEDOR (Vesh) — corpo 10×8, quadro 16×12, origem nos pés (8, 12)
# =====================================================================
ROEDOR_CORPO = """
.....zZ.....
...zzZZz..p.
..vvvvvvvpp.
.vvvvvvvvvpz
VvvvvvvvvvvV
.VVVVVVVVVV.
"""


def roedor_quadro(fase=0, dy=0, pernas=True, corpo=ROEDOR_CORPO, cor_contorno='k'):
    im = camada(16, 12)
    ascii_em(im, corpo, 2, 3 + dy)
    if pernas:
        # 3 pernas visíveis (de 6), passada alternada
        passos = [(-1, 1), (1, -1), (0, 0), (1, -1)][fase % 4]
        for i, x in enumerate((4, 8, 11)):
            d = passos[i % 2]
            _perna(im, x, 9 + dy, d, 2, 'V')
    return outline(im, cor_contorno)


def roedor():
    correr = []
    for f in range(4):
        correr.append(roedor_quadro(f, dy=(0 if f % 2 == 0 else -1)))
    # pulo: corpo esticado, pernas para trás
    pulo = roedor_quadro(0, dy=-1, pernas=False)
    for x in (4, 8, 11):
        _px(pulo, x - 1, 9, 'V'); _px(pulo, x - 2, 9, 'k')
    # escalar parede: o corpo de pé (girado 90°) colado à direita
    escalar = [roedor_quadro(f).rotate(90, expand=False) for f in (0, 1)]
    # recuo depois do contato: encolhido, contorno mais claro (1 quadro)
    recuo = roedor_quadro(2, dy=1)
    # morte: estoura em ácido
    morte = []
    for r in range(4):
        im = camada(16, 12)
        random.seed(r)
        if r == 0:
            im = roedor_quadro(0, dy=1)
            for (x, y) in ((6, 6), (9, 5)):
                _px(im, x, y, 'z')
        else:
            n = (10, 7, 3)[r - 1]
            for _ in range(n):
                x, y = 8 + random.randint(-2 - 2 * r, 2 + 2 * r), 9 - random.randint(0, 5 - r)
                _px(im, x, y, random.choice('zzZv'))
            for x in range(8 - r * 2, 9 + r * 2):
                _px(im, x, 11, 'Z')
        morte.append(im)
    return {'roedor_correr': correr, 'roedor_pulo': [pulo], 'roedor_escalar': escalar,
            'roedor_recuo': [recuo], 'roedor_morte': morte}


# =====================================================================
# CHACAL DE CLÃ (Kharn) — corpo 14×10, quadro 24×16, origem nos pés (12, 16)
# =====================================================================
CHACAL_CORPO = """
....w.w.w..........
...wWwWwW.....ll...
..GgggggggGg.lggg..
.GgggggggggggggggfG
GGgggggggggggggggww
.GGgggggggggggGG.W.
..GGGGGGGGGGGG.....
"""
CHACAL_AGACHADO = """
...................
....w.w.w..........
...wWwWwW....lll...
.GGgggggggggggggfG.
GGgggggggggggggggww
.GGGGGGGGGGGGGGG.W.
"""


def chacal_quadro(pernas, dy=0, corpo=CHACAL_CORPO, cor_contorno='k', olho=None):
    im = camada(24, 16)
    ascii_em(im, corpo, 2, 5 + dy)
    for (x, dx, comp) in pernas:  # cada perna: 2 px de largura
        _perna(im, x, 12 + dy, dx, comp, 'G'); _perna(im, x + 1, 12 + dy, dx, comp, 'g')
    if olho:
        _px(im, 19, 8 + dy, olho)
    return outline(im, cor_contorno)


def chacal():
    # corrida em 6 quadros: pares de pernas (trás x=5, frente x=14) alternando
    ciclo = [(-2, 2), (-1, 1), (0, 0), (2, -2), (1, -1), (0, 0)]
    correr = []
    for i, (a, b) in enumerate(ciclo):
        dy = -1 if i in (1, 4) else 0
        correr.append(chacal_quadro([(4, a, 3 - (dy < 0)), (6, b, 3), (13, b, 3), (15, a, 3 - (dy < 0))], dy))
    # aviso (0,3 s): agacha e o olho brilha; o 2º quadro é o flash AVISO dos últimos 0,2 s (regra do ART-01)
    pernas_agachado = [(4, -1, 2), (6, 0, 2), (13, 0, 2), (15, 1, 2)]
    aviso = [chacal_quadro(pernas_agachado, 1, CHACAL_AGACHADO, olho='f'),
             chacal_quadro(pernas_agachado, 1, CHACAL_AGACHADO, cor_contorno='y', olho='y')]
    # salto: subida (pernas esticadas para trás) e descida (pernas para a frente)
    salto = [chacal_quadro([(3, -3, 3), (5, -3, 3), (13, -2, 2), (15, -2, 2)], -1),
             chacal_quadro([(4, 2, 2), (6, 2, 2), (14, 3, 3), (16, 3, 3)], 0)]
    recuo = chacal_quadro(pernas_agachado, 1, CHACAL_AGACHADO)
    morte = []
    for r in range(4):
        if r == 0:
            morte.append(chacal_quadro([(4, -2, 2), (13, 2, 2)], 2))
            continue
        im = camada(24, 16); random.seed(10 + r)
        for _ in range((14, 9, 4)[r - 1]):
            x, y = 12 + random.randint(-3 - 2 * r, 3 + 2 * r), 15 - random.randint(0, 6 - r * 2)
            _px(im, x, y, random.choice('wWWG'))
        for x in range(12 - r * 3, 13 + r * 3):
            _px(im, x, 15, 'W')
        morte.append(im)
    return {'chacal_correr': correr, 'chacal_aviso': aviso, 'chacal_salto': salto,
            'chacal_recuo': [recuo], 'chacal_morte': morte}


# =====================================================================
# ZANGÃO (Vesh) — 12×12 do conceito, animado: quadro 16×16, origem no centro (8, 8)
# =====================================================================
ZANGAO_CORPO = """
............
............
....kkkkk...
...kvpppvk..
..kvpaapvk..
.kvpaapvzvk.
.kvvppvvzvk.
..kvvvvzvk..
...kvZzzk...
....kvzk....
.....kk.....
"""
ASAS = {
    'cima': [(2, 0), (1, 1), (2, 1), (3, 1), (8, 0), (7, 1), (8, 1), (9, 1)],
    'meio': [(0, 3), (1, 3), (1, 2), (2, 2), (10, 3), (11, 3), (9, 2), (10, 2)],
    'baixo': [(0, 5), (0, 6), (1, 6), (11, 5), (11, 6), (10, 6)],
}


def zangao_quadro(asa, dy=0, contorno_aviso=False):
    base = camada(12, 12)
    ascii_em(base, ZANGAO_CORPO.replace('k', '.'), 0, 0)
    for (x, y) in ASAS[asa]:
        if base.getpixel((x, y))[3] == 0:
            base.putpixel((x, y), rgb('u'))
    im = camada(16, 16)
    im.alpha_composite(base, (2, 2 + dy))
    return outline(im, 'k') if not contorno_aviso else outline(im, 'y')


def zangao():
    voo = [zangao_quadro(a, dy) for a, dy in (('cima', 0), ('meio', 1), ('baixo', 1), ('meio', 0))]
    morte = []
    for r in range(3):
        im = camada(16, 16); random.seed(30 + r)
        if r == 0:
            im = zangao_quadro('baixo', 2)
        else:
            for _ in range((10, 5)[r - 1]):
                _px(im, 8 + random.randint(-3 * r, 3 * r), 8 + random.randint(-2, 4 + 2 * r), random.choice('vpzZ'))
        morte.append(im)
    return {'zangao_voo': voo, 'zangao_morte': morte}


# =====================================================================
def mockup_bando():
    """Tela de conferência: bando de enxame vindo da direita, ×4 (1920×1080)."""
    fundo = Image.open(os.path.join(RAIZ, 'assets', 'sprites', 'conceito', 'mockup_v02_varrek.png')).convert('RGBA')
    tela = fundo.copy()
    R, C, Z = roedor(), chacal(), zangao()
    chao = 222
    random.seed(4)
    for i in range(10):
        q = R['roedor_correr'][i % 4].transpose(Image.FLIP_LEFT_RIGHT)
        tela.alpha_composite(q, (300 + i * 16 + random.randint(-4, 4), chao - 12))
    for i in range(4):
        q = C['chacal_correr'][i % 6].transpose(Image.FLIP_LEFT_RIGHT)
        tela.alpha_composite(q, (250 + i * 40, chao - 16))
    tela.alpha_composite(C['chacal_aviso'][1].transpose(Image.FLIP_LEFT_RIGHT), (220, chao - 16))
    for i in range(7):
        q = Z['zangao_voo'][i % 4].transpose(Image.FLIP_LEFT_RIGHT)
        tela.alpha_composite(q, (280 + i * 24, 120 + (i % 3) * 18 - (i % 2) * 6))
    return tela.resize((1920, 1080), Image.NEAREST)


def prancha(tudo):
    """Todas as animações lado a lado, ×6, sobre fundo escuro (para conferir)."""
    linhas = [(k, v) for k, v in tudo.items()]
    W = max(sum(q.width + 2 for q in v) for _, v in linhas) + 4
    H = sum(v[0].height + 4 for _, v in linhas) + 4
    p = Image.new('RGBA', (W, H), (58, 31, 48, 255)); y = 4
    for _, v in linhas:
        x = 4
        for q in v:
            p.alpha_composite(q, (x, y)); x += q.width + 2
        y += v[0].height + 4
    return p.resize((W * 6, H * 6), Image.NEAREST)


def main():
    R, C, Z = roedor(), chacal(), zangao()
    for nome, q in R.items():
        salvar(folha(q), 'inimigos', 'vesh', 'roedor', nome + '.png')
    for nome, q in C.items():
        salvar(folha(q), 'inimigos', 'kharn', 'chacal', nome + '.png')
    for nome, q in Z.items():
        salvar(folha(q), 'inimigos', 'vesh', 'zangao', nome + '.png')
    salvar(mockup_bando(), 'conceito', 'mockup_v12_horda.png')
    prancha({**R, **C, **Z}).save('/tmp/prancha_horda.png')
    print('ok')


if __name__ == '__main__':
    main()
