"""ART-8 — abertura v2 (D-075, roteiro NAR-07 v2): quadros novos e ajustados + estilo das legendas.

Uso: python3 ferramentas/arte/abertura_v2.py   (Python 3 + Pillow; depois de abertura_v01.py e abertura_ia_v01.py)
Saída: assets/sprites/abertura/v2_*.png + conceito/mockup_v14_abertura_v2.png (os 12 quadros)
       + conceito/mockup_v15_legenda_1080p.png (legenda sobre a imagem, em 1080p).

Quadros novos: 1 galáxia em guerra, 10 o trato (rota dos planetas), 11 morrer = voltar, 12 a cápsula.
Ajustados: 8 (subida do feixe até a nave), 9 (o corpo do Ryker se formando em linhas de luz).
Ryker em destaque (D-075): poses-chave com contorno claro. Sem spoiler (D-045): o símbolo dos Vesh NÃO usa âmbar.
"""
from PIL import Image, ImageDraw, ImageFont
import math, os, random, sys

AQUI = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, AQUI)
from prancha_estilo import rgb, hx, outline, bayer
import abertura_v01 as P

RAIZ = os.path.join(AQUI, '..', '..')
SAIDA = os.path.join(RAIZ, 'assets', 'sprites', 'abertura')
SPR = os.path.join(RAIZ, 'assets', 'sprites')
T = (0, 0, 0, 0)


def abrir(*p):
    return Image.open(os.path.join(SPR, *p)).convert('RGBA')


def salvar(im, nome):
    im.save(os.path.join(SAIDA, nome))


def camada(w, h, cor=None):
    return Image.new('RGBA', (w, h), cor if cor else T)


def folha(q):
    w, h = q[0].size; f = camada(w * len(q), h)
    for i, im in enumerate(q):
        f.alpha_composite(im, (i * w, 0))
    return f


def ascii_img(txt, escala=1):
    linhas = txt.strip('\n').split('\n'); w = max(len(l) for l in linhas)
    im = camada(w, len(linhas))
    for y, l in enumerate(linhas):
        for x, ch in enumerate(l):
            if ch != '.':
                im.putpixel((x, y), rgb(ch))
    return im.resize((w * escala, len(linhas) * escala), Image.NEAREST) if escala > 1 else im


def varrek():
    v = [abrir('cenarios', 'varrek', f'varrek_parallax_{n}.png') for n in ('0_ceu_anel', '1_cascos_longe', '2_cascos_meio')]
    g = v[0].copy()
    for c in v[1:]:
        g.alpha_composite(c.crop((0, 0, 480, 270)))
    return g


# =====================================================================
# DESTAQUE DO RYKER — contorno claro de 1 px (ele é o pequeno no meio de gigantes)
# =====================================================================
def destaque(im, cor='#fff6ea'):
    base = im.copy(); px = base.load(); w, h = base.size
    out = camada(w + 2, h + 2); op = out.load()
    for y in range(h):
        for x in range(w):
            if px[x, y][3]:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    op[x + 1 + dx, y + 1 + dy] = hx(cor)
    out.alpha_composite(base, (1, 1))
    return out


def poses_destaque():
    p = abrir('personagens', 'ryker', 'ryker_poses_chave.png')
    n = p.width // 48
    return folha([destaque(p.crop((i * 48, 0, i * 48 + 48, 48))) for i in range(n)])


# =====================================================================
# QUADRO 1 — A galáxia em guerra (640×360: a câmera aproxima devagar até o pontinho humano)
# =====================================================================
SIMBOLO_KHARN = """
.....kkkkkkkk.....
...kkeeeeeeeekk...
..keeeffeeffeeek..
.keeekkeeeekkeeek.
.keekkkkeekkkkeek.
.keeekkeeeekkeeek.
.keeeeeekkeeeeeek.
..keeeekkkkeeeek..
...keeeeeeeeeek...
...kekeekeekeek...
....kkeekeekkk....
.....kkkkkkkk.....
..................
.ff.....ff.....ff.
..ff.....ff.....ff
...ff.....ff.....f
....f......f......
"""
SIMBOLO_VESH = """
......kkkkk.......
.....kvvvvvk......
..kkkkvpzpvkkkk...
.kvvvvkvvvkvvvvk..
.kvpzpkkkkkvpzpk..
.kvvvvkvvvkvvvvk..
..kkkkvvvvvkkkk...
.....kvpzpvk......
..kkkkvvvvvkkkk...
.kvvvvkkkkkvvvvk..
.kvpzpk...kvpzpk..
.kvvvvk...kvvvvk..
..kkkk.....kkkk...
"""
SIMBOLO_ILO = """
.....kkkkkkk......
...kkooooooookk...
..koohhhhhhhhook..
.kohhkkkkkkkhhok..
.kohk...k...khok..
kohhk..kuk..khhok.
kohk..kuuuk..khok.
kohk.kuutuuk.khok.
kohk.kuuuuuk.khok.
.kohk.kuuuk.khok..
.kohhk.kkk.khhok..
..koohkkkkkhhook..
...kkooooooookk...
.....kkkkkkkk.....
"""


def simbolos():
    q = []
    for s in (SIMBOLO_KHARN, SIMBOLO_VESH, SIMBOLO_ILO):
        im = ascii_img(s); c = camada(20, 20); c.alpha_composite(im, ((20 - im.width) // 2, (20 - im.height) // 2))
        q.append(c.resize((60, 60), Image.NEAREST))
    return folha(q)


POS_SIMB = [(150, 110), (470, 120), (320, 265)]   # centro de cada símbolo no fundo 640×360 (Kharn, Vesh, Ilo)
POS_HUMANO = (540, 290)


def galaxia():
    f = camada(640, 360, hx('#16111c')); px = f.load(); random.seed(21)
    for y in range(360):
        for x in range(640):  # nebulosas fracas puxando para a cor de cada raça
            for (cx, cy), cor in zip(POS_SIMB, ('#3a1f30', '#2b1838', '#263142')):
                d = math.hypot(x - cx, y - cy) / 130
                if d < 1 and bayer(x, y) < 0.6 * (1 - d):
                    px[x, y] = hx(cor)
    for _ in range(320):
        x, y = random.randrange(640), random.randrange(360)
        px[x, y] = hx(random.choice(['#4b4753', '#6a5a78', '#9a8aa8', '#dff8ff']))
    frotas = camada(640, 360); d = ImageDraw.Draw(frotas)
    for (a, b, cor) in ((0, 1, '#9c3527'), (1, 0, '#7d4c90'), (0, 2, '#c4652e'), (1, 2, '#57901f')):
        (x0, y0), (x1, y1) = POS_SIMB[a], POS_SIMB[b]
        n = int(math.hypot(x1 - x0, y1 - y0) / 6)
        for i in range(n):
            if i % 2:
                t = i / n; off = math.sin(t * math.pi) * (30 if a < b else -30)
                xx, yy = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t + off
                d.rectangle((xx, yy, xx + 1, yy + 1), fill=hx(cor))
    return f, frotas


def clarao():
    q = []
    for i in range(4):
        im = camada(9, 9); r = (1, 3, 4, 2)[i]
        for y in range(9):
            for x in range(9):
                d = abs(x - 4) + abs(y - 4)
                if d <= r:
                    im.putpixel((x, y), hx('#fff6ea' if d < r - 1 else ('#eba35c' if i < 3 else '#6a3030')))
        q.append(im)
    return folha(q)


def humano():
    q = []
    for c in ('#a4abb6', '#fff6ea'):
        im = camada(7, 7)
        for p in ((3, 2), (2, 3), (3, 3), (4, 3), (3, 4)):
            im.putpixel(p, hx(c))
        q.append(im)
    return folha(q)


# =====================================================================
# QUADRO 8 — A luz e a nave: subida contínua de Varrek até o espaço (480×810)
# =====================================================================
def subida():
    f = camada(480, 810, hx('#16111c'))
    topo_varrek = '#%02x%02x%02x' % varrek().getpixel((0, 0))[:3]
    P.gradiente(f, 250, 541, ['#16111c', '#1e1424', topo_varrek])
    P.estrelas(f, 120, 400, 31)
    f.alpha_composite(varrek(), (0, 540))
    return f


# =====================================================================
# QUADRO 9 — O corpo do Ryker se formando em linhas de luz (8 quadros 64×64)
# =====================================================================
def ryker_formando():
    ref = abrir('personagens', 'ryker', 'ryker_referencia.png').crop((0, 0, 48, 48))
    alvo = camada(64, 64); alvo.alpha_composite(ref, (8, 14)); ap = alvo.load()
    linhas = sorted({y for y in range(64) for x in range(64) if ap[x, y][3]}, key=lambda y: abs(y - 38))
    q = []
    for i in range(8):
        im = camada(64, 64); px = im.load(); t = (i + 1) / 8
        feitas = set(linhas[:int(len(linhas) * min(1, t * 1.25))])
        for y in range(64):
            for x in range(64):
                if not ap[x, y][3]:
                    continue
                if y in feitas:
                    if t >= 1:
                        px[x, y] = ap[x, y]                    # último quadro: o Ryker de verdade
                    else:
                        borda = any(not ap[min(63, max(0, x + dx)), min(63, max(0, y + dy))][3] for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
                        px[x, y] = hx('#fff3c4') if borda else (hx('#ffc95c') if (x + y + i) % 3 else hx('#eba35c'))
                elif y % 3 == 0 and bayer(x, y) < t:            # linhas de varredura antecipando a forma
                    px[x, y] = hx('#eba35c')[:3] + (120,)
        if t >= 1:
            im = destaque(im, '#ffc95c').crop((1, 1, 65, 65))
        q.append(im)
    return folha(q)


# =====================================================================
# QUADRO 10 — O trato: rota dos planetas (960×270, pan da esquerda para a direita)
# =====================================================================
PLANETAS = [(150, 190, 34, 'varrek'), (390, 196, 28, None), (620, 186, 32, None), (840, 194, 26, None)]


def rota():
    f = camada(960, 270, hx('#16111c')); P.estrelas(f, 260, 270, 41); d = ImageDraw.Draw(f); px = f.load()
    for i, (x, y, r, nome) in enumerate(PLANETAS):
        for yy in range(y - r, y + r + 1):
            for xx in range(x - r, x + r + 1):
                dd = math.hypot(xx - x, yy - y) / r
                if dd <= 1 and 0 <= xx < 960 and 0 <= yy < 270:
                    luz = (xx - x) / r + (yy - y) / r
                    if nome:  # Varrek aceso: ferrugem
                        c = '#c4652e' if luz < -0.6 else ('#a2523a' if luz < 0.2 else ('#6a3030' if bayer(xx, yy) > 0.4 else '#3a1f30'))
                    else:     # desconhecidos: só silhueta escura com borda
                        c = '#4b4753' if dd > 0.9 else ('#2b2236' if luz < 0 else '#1e1424')
                    px[xx, yy] = hx(c)
        if i:
            x0 = PLANETAS[i - 1][0] + PLANETAS[i - 1][2] + 6; x1 = x - r - 6
            for xx in range(x0, x1, 6):
                d.rectangle((xx, y - 1 + (0 if i % 2 else 2), xx + 2, y + (0 if i % 2 else 2)), fill=hx('#5e6370'))
    for (x, y, r, nome) in PLANETAS[1:]:  # "?" dos planetas desconhecidos
        q = ascii_img("""
.MMM.
M...M
...M.
..M..
.....
..M..
""", 2)
        f.alpha_composite(q, (x - 5, y - 6))
    return f


def nave_eco_mini():
    """Recorte da nave da IA (q8_fundo_ia), reduzido para o mapa da rota."""
    src = Image.open(os.path.join(SAIDA, 'q8_fundo_ia.png')).convert('RGBA').crop((10, 10, 710, 262))
    px = src.load()
    for y in range(src.height):  # tira o fundo escuro (céu) para virar sprite
        for x in range(src.width):
            r, g, b, a = px[x, y]
            if r + g + b < 95 and abs(g - b) < 18:
                px[x, y] = T
    im = src.resize((175, 63), Image.NEAREST)
    return outline(im.crop(im.getbbox()), 'k')


def capsula():
    """Cápsula de descida, 4 quadros 16×28: inteira, em chamas (2), no chão aberta."""
    base = ascii_img("""
....kkk.....
...kMMMk....
..kMmmmMk...
.kMmmammMk..
.kmmmmmmmk..
.kmxmmmxmk..
.kmmmmmmmk..
.kxxxxxxxk..
..kxxxxxk...
...kkkkk....
""")
    q = []
    for i in range(4):
        im = camada(16, 28)
        if i in (1, 2):  # rastro de fogo para cima (ela cai)
            for k in range(14):
                w = max(1, 5 - k // 3 + (i == 2 and k % 2))
                c = 'w' if k > 11 else ('h' if k > 7 else ('f' if k > 3 else 'K'))
                for x in range(8 - w // 2, 8 + w // 2 + 1):
                    im.putpixel((x, 13 - k), rgb(c))
        if i == 3:
            aberta = base.copy(); dd = ImageDraw.Draw(aberta); dd.rectangle((3, 3, 7, 6), fill=rgb('k'))
            im.alpha_composite(aberta, (2, 18))
        else:
            im.alpha_composite(base, (2, 14 if i else 18))
        q.append(im)
    return folha(q)


# =====================================================================
# QUADRO 11 — Morrer = voltar: o Ryker vira luz e sobe (8 quadros 48×80)
# =====================================================================
def ryker_vira_luz():
    pose = abrir('personagens', 'ryker', 'ryker_poses_chave.png').crop((0, 0, 48, 48))
    caido = pose.rotate(-80, center=(24, 46), resample=Image.NEAREST)
    alvo = [(x, y) for y in range(48) for x in range(48) if caido.getpixel((x, y))[3]]
    q = []
    for i in range(8):
        im = camada(48, 80); t = i / 7; random.seed(77)
        for (x, y) in alvo:
            sobe = random.random()
            if i == 0:
                im.putpixel((x, y + 32), caido.getpixel((x, y))); continue
            if sobe > 1 - t * 1.1:  # a partícula já soltou: sobe em luz
                yy = int(y + 32 - (t * 70) * (0.5 + sobe))
                xx = x + int(math.sin(y + i) * 2)
                if 0 <= xx < 48 and 0 <= yy < 80:
                    im.putpixel((xx, yy), hx('#fff3c4' if sobe > 0.85 else '#ffc95c'))
            elif t < 0.8:
                c = caido.getpixel((x, y))
                im.putpixel((x, y + 32), hx('#ffc95c') if (x + y + i) % 2 else c)  # o corpo já brilhando
        q.append(im)
    return folha(q)


# =====================================================================
# LEGENDAS (D-056, D-075) — faixa escura semitransparente com filete laranja à esquerda
# =====================================================================
def faixa_legenda():
    im = camada(16, 16); d = ImageDraw.Draw(im)
    d.rectangle((0, 0, 15, 15), fill=hx('#16111c')[:3] + (190,))
    d.rectangle((0, 0, 1, 15), fill=rgb('o'))
    d.line((2, 0, 15, 0), fill=hx('#2b2236')[:3] + (220,))
    return im


def fonte(tam, peso='Bold'):
    f = ImageFont.truetype(os.path.join(AQUI, 'fontes_conferencia', 'OpenSans-Variavel.ttf'), tam)
    f.set_variation_by_name(peso); return f


def legenda_1080p(tela, texto, nome=None):
    """Desenha a legenda em 1080p: faixa ×4 + texto nativo. O nome novo do quadro sai em laranja."""
    from titulo_menus_v01 import np16
    f = fonte(34); d = ImageDraw.Draw(tela)
    partes = texto.split(nome) if nome and nome in texto else [texto]
    larg = sum(d.textlength(p, font=f) for p in partes) + (d.textlength(nome, font=f) if len(partes) > 1 else 0)
    w_arte = math.ceil((larg + 2 * 28) / 4)
    faixa = np16(faixa_legenda(), w_arte, 16, 4).resize((w_arte * 4, 64), Image.NEAREST)
    x0, y0 = 48, 1080 - 48 - 64
    tela.alpha_composite(faixa, (x0, y0))
    x = x0 + 28
    for k, p in enumerate(partes):
        d.text((x + 2, y0 + 34), p, font=f, fill=hx('#16111c'), anchor='lm'); d.text((x, y0 + 32), p, font=f, fill=hx('#fff6ea'), anchor='lm')
        x += d.textlength(p, font=f)
        if k < len(partes) - 1:
            d.text((x + 2, y0 + 34), nome, font=f, fill=hx('#16111c'), anchor='lm'); d.text((x, y0 + 32), nome, font=f, fill=hx('#eba35c'), anchor='lm')
            x += d.textlength(nome, font=f)


# =====================================================================
def mockup(c):
    up = lambda im, s: im.resize((im.width * s, im.height * s), Image.NEAREST)
    pd = c['v2_ryker_poses_destaque']; pose = lambda i: pd.crop((i * 50, 0, i * 50 + 50, 50))
    q = []
    # 1 galáxia (janela no meio da aproximação)
    g = c['v2_q1_galaxia_fundo'].copy(); g.alpha_composite(c['v2_q1_frotas'])
    for k, (x, y) in enumerate(POS_SIMB):
        g.alpha_composite(c['v2_q1_simbolos'].crop((k * 60, 0, k * 60 + 60, 60)), (x - 30, y - 30))
    for (x, y, k) in ((300, 150, 1), (230, 190, 2), (390, 200, 0)):
        g.alpha_composite(c['v2_q1_clarao'].crop((k * 9, 0, k * 9 + 9, 9)), (x, y))
    g.alpha_composite(c['v2_q1_humano'].crop((7, 0, 14, 7)), (POS_HUMANO[0] - 3, POS_HUMANO[1] - 3))
    q.append(g.crop((100, 60, 580, 330)))
    # 2 arena
    a = c['q1_fundo_ia'].copy(); a.alpha_composite(c['q1_urkesh_caido'], (262, 376)); a.alpha_composite(pose(0), (213, 407))
    q.append(a.crop((0, 270, 480, 540)))
    # 3 prêmio
    b = c['q1_fundo_ia'].crop((0, 270, 480, 540)); b.alpha_composite(Image.new('RGBA', b.size, (10, 6, 14, 120)))
    ret = abrir('retratos', 'ryker', 'ryker_retratos.png').crop((0, 0, 144, 208)); b.alpha_composite(ret.resize((180, 260), Image.NEAREST), (150, 10))
    gu = c['q2_guarda']; b.alpha_composite(gu.crop((0, 0, 40, 48)), (20, 200)); b.alpha_composite(gu.crop((40, 0, 80, 48)).transpose(Image.FLIP_LEFT_RIGHT), (420, 200))
    q.append(b)
    # 4 fuga
    d4 = c['q3_fundo'].copy(); d4.alpha_composite(c['q3_tunel']); d4.alpha_composite(pose(1), (200, 167)); d4.alpha_composite(c['q2_guarda'].crop((0, 0, 40, 48)), (60, 168)); d4.alpha_composite(c['q3_frente']); q.append(d4)
    # 5 portão
    e = c['q4_fundo_ia'].copy(); e.alpha_composite(c['nave_kharn_ia'], (4, 170)); e.alpha_composite(c['nave_ryker_ia'].crop((0, 0, 52, 24)), (178, 170)); q.append(e)
    # 6 dentro
    f6 = c['q5_faixas'].crop((200, 0, 680, 270)); f6.alpha_composite(c['nave_ryker_ia'].crop((104, 0, 156, 24)).resize((156, 72), Image.NEAREST), (168, 100)); q.append(f6)
    # 7 varrek
    v = varrek()
    for (x, y, k) in ((120, 60, 0), (260, 30, 1), (340, 110, 0)):
        v.alpha_composite(c['q6_destroco_fogo'].crop((k * 20, 0, k * 20 + 20, 28)), (x, y))
    q.append(v)
    # 8 subida (meio da subida: feixe atravessando o céu)
    s = c['v2_q8_subida'].crop((0, 380, 480, 650))
    for yy in range(0, 270, 270):
        s.alpha_composite(c['q7_feixe_ambar'].crop((0, 0, 64, 270)), (208, yy))
    q.append(s)
    # 9 reconstrutor: Ryker se formando + a silhueta observando ao lado
    r9 = c['q9_fundo_ia'].copy(); r9.alpha_composite(c['v2_q9_ryker_formando'].crop((64 * 5, 0, 64 * 6, 64)), (210, 100))
    sil = c['q9_silhueta'].crop((96 * 5, 0, 96 * 6, 96)); sil.putalpha(sil.getchannel('A').point(lambda a: int(a * 0.7)))
    r9.alpha_composite(sil, (300, 60)); q.append(r9)
    # 10 rota
    r10 = c['v2_q10_rota'].crop((60, 0, 540, 270)); r10.alpha_composite(c['v2_q10_nave_eco_mini'], (150, 14))
    r10.alpha_composite(c['v2_capsula'].crop((16, 0, 32, 28)), (84, 116)); r10.alpha_composite(c['v2_capsula'].crop((16, 0, 32, 28)), (322, 70)); q.append(r10)
    # 11 morrer = voltar (luta + luz subindo)
    v11 = varrek(); random.seed(3)
    ro = abrir('inimigos', 'vesh', 'roedor', 'roedor_correr.png'); ch = abrir('inimigos', 'kharn', 'chacal', 'chacal_correr.png')
    for k in range(7):
        v11.alpha_composite(ro.crop((k % 4 * 16, 0, k % 4 * 16 + 16, 12)).transpose(Image.FLIP_LEFT_RIGHT), (250 + k * 18, 228))
    v11.alpha_composite(ch.crop((0, 0, 24, 16)).transpose(Image.FLIP_LEFT_RIGHT), (300, 224))
    v11.alpha_composite(c['v2_q11_ryker_vira_luz'].crop((48 * 4, 0, 48 * 5, 80)), (200, 160)); q.append(v11)
    # 12 cápsula caindo em Varrek
    v12 = varrek(); v12.alpha_composite(c['v2_capsula'].crop((32, 0, 48, 28)).resize((32, 56), Image.NEAREST), (230, 90)); q.append(v12)
    m = Image.new('RGBA', (4 + 4 * 484, 4 + 3 * 274), (40, 30, 48, 255))
    for k, im in enumerate(q):
        m.alpha_composite(im, (4 + (k % 4) * 484, 4 + (k // 4) * 274))
    m.save(os.path.join(SPR, 'conceito', 'mockup_v14_abertura_v2.png'))
    # legenda em 1080p sobre o quadro 7 (Varrek)
    tela = up(q[6], 4); legenda_1080p(tela, 'VARREK — O CEMITÉRIO DE NAVES', 'VARREK')
    tela.save(os.path.join(SPR, 'conceito', 'mockup_v15_legenda_1080p.png'))


def main():
    c = {}
    c['v2_ryker_poses_destaque'] = poses_destaque()
    c['v2_q1_galaxia_fundo'], c['v2_q1_frotas'] = galaxia()
    c['v2_q1_simbolos'] = simbolos(); c['v2_q1_clarao'] = clarao(); c['v2_q1_humano'] = humano()
    c['v2_q8_subida'] = subida()
    c['v2_q9_ryker_formando'] = ryker_formando()
    c['v2_q10_rota'] = rota(); c['v2_q10_nave_eco_mini'] = nave_eco_mini(); c['v2_capsula'] = capsula()
    c['v2_q11_ryker_vira_luz'] = ryker_vira_luz()
    c['v2_legenda_faixa'] = faixa_legenda()
    for k, im in c.items():
        salvar(im, k + '.png')
    for f in os.listdir(SAIDA):
        if f.endswith('.png') and f[:-4] not in c:
            c[f[:-4]] = Image.open(os.path.join(SAIDA, f)).convert('RGBA')
    mockup(c)
    print('ok', len([k for k in c if k.startswith('v2_')]), 'arquivos v2')


if __name__ == '__main__':
    main()
