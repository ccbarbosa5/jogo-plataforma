"""ART-5 — quadros da abertura da história (D-073B), seguindo o roteiro NAR-07. Versão PROVISÓRIA por código.

Uso: python3 ferramentas/arte/abertura_v01.py   (Python 3 + Pillow).
Saída: assets/sprites/abertura/ (camadas e sprites) + conceito/mockup_v13_abertura.png (os 9 quadros montados).

Os fundos dos quadros 1, 4, 8 e 9 e as duas naves serão trocados pelas imagens do pacote 10 (IA) quando o dono gerar.
⚠ Sem spoiler (D-045): a ECO só aparece como silhueta de luz âmbar se formando (quadro 9); nada de inseto ou colmeia.
"""
from PIL import Image, ImageDraw
import math, os, random, sys

AQUI = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, AQUI)
from prancha_estilo import rgb, hx, outline, bayer, ENV, silhuetas

RAIZ = os.path.join(AQUI, '..', '..')
SAIDA = os.path.join(RAIZ, 'assets', 'sprites', 'abertura')
SPR = os.path.join(RAIZ, 'assets', 'sprites')
T = (0, 0, 0, 0)


def camada(w, h, cor=None):
    return Image.new('RGBA', (w, h), cor if cor else T)


def gradiente(img, y0, y1, cores):
    """Gradiente vertical em faixas pontilhadas (pixel art) entre uma lista de cores hex."""
    px = img.load(); n = len(cores) - 1
    for y in range(y0, y1):
        t = (y - y0) / max(1, y1 - y0 - 1) * n
        i = min(int(t), n - 1); f = t - i
        for x in range(img.width):
            px[x, y] = hx(cores[i + 1] if bayer(x, y) < f else cores[i])


def estrelas(img, n, y_max, semente):
    random.seed(semente)
    for _ in range(n):
        x, y = random.randrange(img.width), random.randrange(y_max)
        img.putpixel((x, y), hx(random.choice(['#6a5a78', '#9a8aa8', '#dff8ff', '#5e6370'])))


def salvar(img, nome):
    os.makedirs(SAIDA, exist_ok=True)
    img.save(os.path.join(SAIDA, nome))


def folha(q):
    w, h = q[0].size; f = camada(w * len(q), h)
    for i, im in enumerate(q):
        f.alpha_composite(im, (i * w, 0))
    return f


def pose_ryker(i):
    return Image.open(os.path.join(SPR, 'personagens', 'ryker', 'ryker_poses_chave.png')).convert('RGBA').crop((i * 48, 0, i * 48 + 48, 48))


# =====================================================================
# QUADRO 1 — A Grande Arena (480×540, câmera desce de y=0 até y=270)
# =====================================================================
def kharn_silhueta(d, x, base, alt, cor, chifres=True):
    """Ombros largos + cabeça pequena (+ chifres): silhueta de Kharn na multidão."""
    larg = int(alt * 0.9)
    d.ellipse((x - larg // 2, base - int(alt * 0.55), x + larg // 2, base + alt // 2), fill=cor)
    cab = max(3, alt // 4)
    d.rectangle((x - cab // 2, base - int(alt * 0.55) - cab, x + cab // 2, base - int(alt * 0.55) + 1), fill=cor)
    if chifres:
        d.line((x - cab // 2, base - int(alt * 0.55) - cab, x - cab, base - int(alt * 0.55) - cab - 3), fill=cor)
        d.line((x + cab // 2, base - int(alt * 0.55) - cab, x + cab, base - int(alt * 0.55) - cab - 3), fill=cor)


def q1():
    W, H = 480, 540
    f = camada(W, H, hx('#16111c'))
    gradiente(f, 0, 150, ['#16111c', '#1e1424', '#2b2236', '#3a1f30'])
    estrelas(f, 40, 90, 1)
    d = ImageDraw.Draw(f)
    # arquibancadas: 5 andares de pedra, cada um um pouco mais claro embaixo
    andares = [(150, 205), (205, 262), (262, 322), (322, 384), (384, 440)]
    for i, (a, b) in enumerate(andares):
        d.rectangle((0, a, W, b), fill=hx(['#1e1424', '#2b2236', '#2f1d28', '#3a1f30', '#4a2a33'][i]))
        d.line((0, a, W, a), fill=hx('#6a3030'))
        for x in range(8 + (i % 2) * 20, W, 40):  # pilares e estandartes
            d.rectangle((x, a, x + 3, b), fill=hx('#16111c'))
            if (x // 40 + i) % 3 == 0:
                d.polygon([(x + 6, a + 2), (x + 16, a + 2), (x + 16, a + 26), (x + 11, a + 20), (x + 6, a + 26)], fill=hx('#9c3527'))
        for x in range(30 + i * 13, W, 96):  # tochas
            d.rectangle((x, a + 4, x + 1, a + 9), fill=hx('#82391f'))
            f.putpixel((x, a + 3), rgb('h')); f.putpixel((x + 1, a + 2), rgb('f'))
    # muro da arena e chão de areia
    d.rectangle((0, 440, W, 462), fill=hx('#20141d'))
    d.line((0, 440, W, 440), fill=hx('#82391f'))
    gradiente(f, 462, H, ['#6a3030', '#a2523a', '#82391f', '#3a1f30'])
    # holofote: cone de luz de cima até o círculo no chão
    luz = camada(W, H); lp = luz.load()
    for y in range(0, H):
        meia = 18 + (y / H) * 70
        for x in range(int(240 - meia), int(240 + meia)):
            if 0 <= x < W:
                borda = abs(x - 240) / meia
                if bayer(x, y) < 0.22 * (1 - borda):
                    lp[x, y] = hx('#fff6ea')[:3] + (110,)
    for y in range(490, 530):
        for x in range(160, 320):
            if ((x - 240) / 80) ** 2 + ((y - 510) / 18) ** 2 <= 1:
                lp[x, y] = hx('#dccfae') if bayer(x, y) < 0.7 else hx('#eba35c')
    f.alpha_composite(luz)
    # multidão do fundo (andares de cima) e da frente (borda do muro): duas camadas para a paralaxe
    mf = camada(W, H); d1 = ImageDraw.Draw(mf); random.seed(11)
    for (a, b) in andares[:4]:
        for x in range(4, W, 9):
            kharn_silhueta(d1, x + random.randint(-2, 2), b - 2, random.randint(12, 16), hx('#16111c'))
    mfr = camada(W, H); d2 = ImageDraw.Draw(mfr); random.seed(12)
    for x in range(-6, W + 10, 22):
        kharn_silhueta(d2, x + random.randint(-4, 4), 446, random.randint(26, 34), hx('#0d0a12'))
    return f, mf, mfr


def urkesh_caido():
    """Silhueta de Ur-Kesh de joelhos (gigante vencido), 96×80, origem nos joelhos (48, 80)."""
    im = camada(96, 80); d = ImageDraw.Draw(im); c = hx('#16111c')
    d.ellipse((16, 14, 84, 66), fill=c)            # costas curvadas
    d.rectangle((58, 6, 76, 26), fill=c)           # cabeça baixa
    d.polygon([(58, 8), (52, 0), (62, 6)], fill=c)  # chifres
    d.polygon([(76, 8), (84, 0), (74, 6)], fill=c)
    d.rectangle((10, 56, 40, 80), fill=c)          # perna dobrada
    d.rectangle((60, 50, 74, 80), fill=c)          # braço apoiado no chão
    d.line((40, 50, 2, 74), fill=c, width=5)       # machado caído
    d.rectangle((0, 66, 10, 80), fill=c)
    im.putpixel((70, 18), rgb('f')); im.putpixel((71, 18), rgb('O'))  # um olho de brasa ainda aceso
    for y in range(14, 66):                         # luz do holofote na borda de cima
        for x in range(16, 84):
            if im.getpixel((x, y))[3] and not im.getpixel((x, y - 1))[3]:
                im.putpixel((x, y), hx('#3a1f30'))
    return im


# =====================================================================
# QUADRO 2 — O prêmio (480×270): fundo da arena escurecido + guardas
# =====================================================================
def guarda():
    """Guarda Kharn em silhueta com corrente nova, 2 quadros de andar 40×48, origem nos pés (20, 48)."""
    q = []
    for p in range(2):
        im = camada(40, 48); d = ImageDraw.Draw(im); c = hx('#16111c')
        d.ellipse((8, 10, 32, 34), fill=c)
        d.rectangle((16, 2, 24, 12), fill=c)
        d.line((16, 3, 12, -1), fill=c, width=2); d.line((24, 3, 28, -1), fill=c, width=2)
        for i, dx in enumerate((-4, 4) if p == 0 else (2, -2)):
            d.rectangle((14 + i * 8 + dx // 2, 32, 18 + i * 8 + dx // 2, 47), fill=c)
        for k in range(6):  # corrente pendurada na mão
            y = 26 + k * 3
            d.rectangle((33 + (k % 2), y, 35 + (k % 2), y + 2), outline=rgb('m'))
        im.putpixel((22, 6), rgb('f'))
        q.append(im)
    return folha(q)


# =====================================================================
# QUADRO 3 — A fuga (travelling): túnel em repetição (480 de largura) + hangar no fim
# =====================================================================
def q3():
    fundo = camada(480, 270, hx('#16111c'))
    gradiente(fundo, 0, 270, ['#16111c', '#1e1424', '#2b2236', '#1e1424'])
    d = ImageDraw.Draw(fundo)
    for x in range(20, 480, 60):  # luzes ao fundo
        d.rectangle((x, 90, x + 6, 96), fill=hx('#82391f')); fundo.putpixel((x + 3, 93), rgb('h'))
    tunel = camada(480, 270); d = ImageDraw.Draw(tunel)
    d.rectangle((0, 0, 480, 40), fill=hx('#2f1d28')); d.rectangle((0, 214, 480, 270), fill=hx('#3a3340'))
    d.line((0, 214, 480, 214), fill=hx('#5b5262'))
    for x in range(0, 480, 96):  # arcos do túnel
        d.rectangle((x, 40, x + 12, 214), fill=hx('#2f1d28'))
        d.arc((x - 40, 20, x + 52, 120), 180, 360, fill=hx('#4a2a33'), width=6)
        d.rectangle((x + 40, 60, x + 46, 66), fill=hx('#eba35c'))  # lâmpada
    frente = camada(480, 270); d = ImageDraw.Draw(frente)
    for x in (60, 300):  # colunas grandes passando rápido
        d.rectangle((x, 0, x + 26, 270), fill=hx('#0d0a12'))
        d.rectangle((x + 26, 0, x + 28, 270), fill=hx('#20141d'))
    hangar = camada(480, 270); d = ImageDraw.Draw(hangar)
    d.rectangle((0, 0, 480, 270), fill=hx('#1e1424'))
    d.rectangle((0, 214, 480, 270), fill=hx('#3a3340')); d.line((0, 214, 480, 214), fill=hx('#5b5262'))
    for x in range(0, 480, 24):  # listras de aviso no chão (laranja e preto, sem a cor AVISO)
        d.polygon([(x, 222), (x + 12, 222), (x + 6, 230), (x - 6, 230)], fill=hx('#c4652e'))
    d.rectangle((140, 30, 470, 40), fill=hx('#2f1d28'))
    for x in range(150, 470, 40):
        d.line((x, 40, x, 214), fill=hx('#2f1d28'), width=2)
    return fundo, tunel, frente, hangar


def nave_ryker(estado=0):
    """Nave de carga remendada, 48×20 (perfil, para a direita). estado 1–2: rachando (quadro 5)."""
    im = camada(48, 20); d = ImageDraw.Draw(im)
    d.polygon([(4, 6), (36, 4), (46, 10), (36, 16), (4, 15)], fill=rgb('m'))
    d.rectangle((10, 6, 20, 14), fill=rgb('x'))       # remendo
    d.rectangle((24, 5, 30, 9), fill=rgb('o'))        # placa laranja
    d.line((6, 6, 34, 5), fill=rgb('M'))
    d.rectangle((0, 8, 5, 13), fill=rgb('x'))         # motor
    im.putpixel((44, 10), rgb('h'))                    # luz da frente
    im = outline(im, 'k')
    if estado:
        px = im.load()
        for y in range(20):  # racha ao meio
            x = 24 + (y % 3) - 1 + estado * (1 if y > 10 else -1)
            for k in range(estado):
                if 0 <= x + k < 48:
                    px[x + k, y] = T
    return im


def chama():
    q = []
    for i in range(2):
        im = camada(8, 6)
        for x in range(8):
            for y in range(6):
                if abs(y - 2.5) < (8 - x) / 3 - i * 0.4:
                    im.putpixel((x, y), rgb('w' if x > 5 else ('h' if x > 2 else 'f')))
        q.append(im)
    return folha(q)


def nave_kharn():
    """Nave de guerra Kharn, 128×44, perfil para a direita: pesada, chifres de osso, brasas."""
    im = camada(128, 44); d = ImageDraw.Draw(im)
    d.polygon([(6, 14), (96, 8), (124, 22), (96, 36), (6, 32)], fill=rgb('G'))
    d.polygon([(10, 16), (94, 11), (112, 20), (10, 22)], fill=rgb('g'))
    for x in range(98, 126, 8):  # chifres de osso na proa
        d.polygon([(x, 14), (x + 8, 6), (x + 4, 16)], fill=rgb('w'))
        d.polygon([(x, 30), (x + 8, 38), (x + 4, 28)], fill=rgb('W'))
    for x in range(20, 90, 14):  # canhões e brasas
        d.rectangle((x, 32, x + 8, 36), fill=rgb('x'))
        im.putpixel((x + 4, 18), rgb('f'))
    d.polygon([(30, 8), (40, 8), (40, 0), (34, 4)], fill=rgb('e'))  # estandarte
    d.rectangle((0, 18, 8, 28), fill=rgb('x'))
    return outline(im, 'k')


# =====================================================================
# QUADRO 4 — O Portão quebrado (zoom out): estrelas + anel partido + luz girando
# =====================================================================
def q4():
    fundo = camada(480, 270, hx('#16111c'))
    gradiente(fundo, 0, 270, ['#16111c', '#1e1424', '#16111c'])
    estrelas(fundo, 160, 270, 4)
    anel = camada(480, 270); px = anel.load()
    cx, cy, R = 300, 135, 118
    for y in range(270):
        for x in range(480):
            r = math.hypot(x - cx, y - cy); a = math.atan2(y - cy, x - cx)
            if R - 16 <= r <= R:
                seg = (a + math.pi) / (2 * math.pi) * 9
                if (seg % 1) < 0.08 or int(seg) in (2, 6):  # rachaduras e dois pedaços faltando
                    continue
                c = '#5e6370' if r > R - 4 else ('#4a2a33' if r < R - 12 else '#2b2236')
                if bayer(x, y) < 0.15:
                    c = '#a4abb6'
                px[x, y] = hx(c)
    # pedaços soltos flutuando nos buracos
    d = ImageDraw.Draw(anel)
    for (a, s) in ((2.6, 10), (6.4, 8), (2.2, 6)):
        ang = a / 9 * 2 * math.pi - math.pi
        x, y = cx + math.cos(ang) * (R + 8), cy + math.sin(ang) * (R + 8)
        d.rectangle((x - s, y - s // 2, x + s, y + s // 2), fill=hx('#2b2236'), outline=hx('#5e6370'))
    luz = []
    for f in range(4):  # luz instável girando no meio (sem nada dentro)
        im = camada(200, 200); lp = im.load()
        for y in range(200):
            for x in range(200):
                r = math.hypot(x - 100, y - 100)
                if r > 96:
                    continue
                a = math.atan2(y - 100, x - 100) + f * 0.4 + r / 30
                v = (math.sin(a * 3) + 1) / 2 * (1 - r / 96)
                if v > 0.55 and bayer(x, y) < v:
                    lp[x, y] = hx('#dff8ff')
                elif v > 0.3 and bayer(x, y) < v + 0.2:
                    lp[x, y] = hx('#4fb0a6')
                elif v > 0.12 and bayer(x, y) < 0.35:
                    lp[x, y] = hx('#2a6a66')
        luz.append(im)
    return fundo, anel, folha(luz)


# =====================================================================
# QUADRO 5 — Dentro do Portão: faixas de luz esticada (960 de largura, rola rápido)
# =====================================================================
def q5():
    im = camada(960, 270, hx('#16111c')); d = ImageDraw.Draw(im); random.seed(5)
    for _ in range(140):
        y = random.randrange(270); x = random.randrange(960); L = random.randint(40, 260)
        cor = random.choice(['#2a6a66', '#4fb0a6', '#dff8ff', '#3d4c60', '#6a3030', '#a4abb6'])
        d.line((x, y, x + L, y), fill=hx(cor), width=random.choice([1, 1, 2]))
    return im


# =====================================================================
# QUADROS 6 e 7 — Varrek: queda em chamas, poeira, silêncio e o feixe âmbar
# =====================================================================
def destroco_em_chamas():
    q = []
    for i in range(2):
        im = camada(20, 28); d = ImageDraw.Draw(im)
        d.polygon([(4, 18), (16, 16), (14, 26), (6, 26)], fill=rgb('m'))
        d.line((5, 19, 15, 17), fill=rgb('M'))
        for k in range(10):  # rastro de fogo para cima
            y = 16 - k * 1.6; w = max(1, 5 - k // 2 + (i if k % 2 else 0))
            c = 'w' if k < 2 else ('h' if k < 5 else ('f' if k < 8 else 'K'))
            x0 = 10 - w // 2 + (k % 2) * (1 - 2 * i)
            d.rectangle((x0, y, max(x0, 10 + w // 2), y + 1), fill=rgb(c))
        q.append(outline(im, 'k'))
    return folha(q)


def poeira():
    q = []
    for i in range(4):
        im = camada(64, 32); d = ImageDraw.Draw(im); random.seed(60 + i)
        r = 8 + i * 6
        for _ in range(40 - i * 6):
            a = random.uniform(math.pi, 2 * math.pi); rr = random.uniform(0.4, 1) * r
            x, y = 32 + math.cos(a) * rr * 1.6, 30 + math.sin(a) * rr
            d.rectangle((x, y, x + 2, y + 2), fill=hx(['#5b5262', '#4a2a33', '#3a3340'][i % 3]))
        q.append(im)
    return folha(q)


def fumaca():
    q = []
    for i in range(2):
        im = camada(16, 64); d = ImageDraw.Draw(im)
        for k in range(12):
            y = 60 - k * 5; x = 8 + math.sin(k * 0.8 + i * 1.5) * 3
            d.ellipse((x - 3 - k // 4, y - 3, x + 3 + k // 4, y + 3), fill=hx('#3a3340' if k < 6 else '#2b2236'))
        q.append(im)
    return folha(q)


def feixe_ambar():
    """Feixe âmbar que desce do céu: 2 quadros 64×270 (cintila). Só âmbar, como já é conhecido (D-073)."""
    q = []
    for i in range(2):
        im = camada(64, 270); px = im.load()
        for y in range(270):
            for x in range(64):
                b = abs(x - 32) / 32
                if b < 1 and bayer(x + i, y) < 0.45 * (1 - b) ** 1.4:
                    px[x, y] = hx('#ffc95c') if b < 0.35 else hx('#eba35c')
        q.append(im)
    return folha(q)


def particula_ambar():
    q = []
    for c in ('#fff3c4', '#ffc95c', '#eba35c'):
        im = camada(3, 3); im.putpixel((1, 1), hx(c))
        for p in ((0, 1), (2, 1), (1, 0), (1, 2)):
            im.putpixel(p, hx('#ffc95c')[:3] + (110,))
        q.append(im)
    return folha(q)


# =====================================================================
# QUADRO 8 — A nave Eco em órbita (960 de largura, pan da esquerda para a direita)
# =====================================================================
def q8():
    f = camada(960, 270, hx('#16111c'))
    estrelas(f, 220, 200, 8)
    d = ImageDraw.Draw(f)
    # curva de Varrek embaixo
    for x in range(960):
        topo = 230 + int(((x - 480) / 480) ** 2 * 30)
        for y in range(topo, 270):
            t = (y - topo) / 40
            f.putpixel((x, y), hx('#a2523a' if t < 0.08 else ('#6a3030' if bayer(x, y) > t else '#3a1f30')))
    nave = camada(960, 270); d = ImageDraw.Draw(nave)
    # casco: blocos retos e pesados (fortaleza antiga), teal escuro
    d.polygon([(110, 140), (220, 96), (760, 90), (880, 128), (760, 176), (220, 172)], fill=rgb('N'))
    d.polygon([(220, 96), (760, 90), (800, 110), (200, 116)], fill=rgb('n'))
    for (x0, x1, y0, y1) in ((300, 420, 64, 96), (520, 600, 52, 92), (640, 700, 70, 92), (380, 460, 172, 194)):
        d.rectangle((x0, y0, x1, y1), fill=rgb('N')); d.line((x0, y0, x1, y0), fill=rgb('n'))
    d.rectangle((548, 20, 556, 52), fill=rgb('N'))  # antena
    # sombra na metade de baixo, painéis e detalhes (para não ficar um bloco liso)
    np_ = nave.load()
    for y in range(270):
        for x in range(960):
            c = np_[x, y]
            if c[3] and c[:3] == hx('#2a6a66')[:3]:
                if y > 140 and bayer(x, y) < (y - 140) / 36:
                    np_[x, y] = hx('#1d4644')
                elif x % 28 == 0 or (y % 22 == 0 and x % 6):
                    np_[x, y] = hx('#1d4644')
    for x in range(240, 750, 56):
        d.rectangle((x, 118, x + 18, 124), fill=hx('#1d4644'))
    # janelas e linhas de luz âmbar
    for x in range(230, 760, 9):
        if (x // 9) % 4:
            nave.putpixel((x, 128), rgb('a'))
    for x in range(260, 740, 30):
        d.rectangle((x, 140, x + 2, 141), fill=rgb('a'))
    for (x0, y0) in ((310, 74), (530, 62), (390, 182)):
        for k in range(0, 60, 7):
            nave.putpixel((x0 + k, y0 + 8), rgb('a'))
    nave = outline(nave, 'k')
    return f, nave


# =====================================================================
# QUADRO 9 — O Reconstrutor: câmara escura + a silhueta de luz se formando (6 quadros)
# =====================================================================
def silhueta_de_luz():
    """Silhueta genérica de mulher, inclinada para a frente (sobre o reconstrutor), 96×96. Sem detalhe nenhum."""
    im = camada(96, 96); px = im.load()
    def meia(y):
        if y < 14: return math.sqrt(max(0, 36 - (y - 7) ** 2))       # cabeça
        if y < 18: return 2                                            # pescoço
        if y < 24: return 2 + (y - 18) * 1.4                           # ombros
        if y < 40: return 10 - (y - 24) * 0.33                         # tronco até a cintura
        if y < 52: return 5 + (y - 40) * 0.3                           # quadril
        return 8.6 + (y - 52) * 0.12                                   # vestido longo, abrindo
    for y in range(2, 95):
        cx = 44 + (94 - y) * 0.12                                       # inclinada para a direita
        w = meia(y)
        for x in range(int(cx - w), int(cx + w) + 1):
            if 0 <= x < 96:
                px[x, y] = (255, 255, 255, 255)
    return im


def q9():
    f = camada(480, 270, hx('#16111c')); d = ImageDraw.Draw(f)
    gradiente(f, 150, 270, ['#16111c', '#1e1424', '#263142'])
    d.ellipse((150, 60, 330, 250), outline=rgb('N'), width=8)          # anel de máquinas
    d.ellipse((160, 70, 320, 240), outline=hx('#263142'), width=3)
    d.polygon([(190, 196), (290, 170), (296, 182), (196, 210)], fill=rgb('m'))   # maca inclinada
    d.line((190, 196, 290, 170), fill=rgb('M'))
    for x0 in (120, 340):  # cabos e painéis
        d.rectangle((x0, 110, x0 + 20, 220), fill=hx('#263142'))
        for y in range(120, 210, 12):
            f.putpixel((x0 + 6, y), rgb('a')); f.putpixel((x0 + 12, y + 4), rgb('n'))
    for x in range(200, 290, 3):  # brilho âmbar fraco por baixo
        if bayer(x, 214) < 0.5:
            f.putpixel((x, 214), hx('#eba35c'))
    # silhueta de luz: usa a forma da ECO de frente, só como contorno de luz (sem detalhe nenhum)
    eco = silhueta_de_luz()
    alvo = [(x, y) for y in range(96) for x in range(96) if eco.getpixel((x, y))[3]]
    random.seed(9)
    origem = {p: (random.randrange(-40, 136), random.randrange(-30, 130)) for p in alvo}
    q = []
    for i in range(6):
        im = camada(96, 96); t = (i + 1) / 6
        for p in alvo:
            if random.random() > 0.35 + 0.65 * t:
                continue
            ox, oy = origem[p]
            x = round(ox + (p[0] - ox) * t); y = round(oy + (p[1] - oy) * t)
            if 0 <= x < 96 and 0 <= y < 96:
                borda = any(eco.getpixel((min(95, max(0, p[0] + dx)), min(95, max(0, p[1] + dy))))[3] == 0
                            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
                c = '#fff3c4' if borda else ('#ffc95c' if bayer(*p) < 0.5 * t else '#eba35c')
                im.putpixel((x, y), hx(c)[:3] + (255 if borda or t > 0.6 else 170,))
        q.append(im)
    return f, folha(q)


# =====================================================================
def montar_mockup(c):
    """Os 9 quadros montados (cada um num momento da animação), 3×3, cada um 480×270 → 1440×810."""
    quadros = []
    # 1
    a = c['q1_fundo'].copy(); a.alpha_composite(c['q1_multidao_fundo']); a.alpha_composite(c['q1_multidao_frente'])
    a.alpha_composite(c['q1_urkesh_caido'], (250, 444)); a.alpha_composite(pose_ryker(0), (196, 476))
    quadros.append(a.crop((0, 270, 480, 540)))
    # 2: fundo da arena escurecido + guardas + retrato ampliado
    b = c['q1_fundo'].crop((0, 270, 480, 540)); b.alpha_composite(Image.new('RGBA', b.size, (10, 6, 14, 120)))
    g = c['q2_guarda']; b.alpha_composite(g.crop((0, 0, 40, 48)), (20, 200)); b.alpha_composite(g.crop((40, 0, 80, 48)).transpose(Image.FLIP_LEFT_RIGHT), (420, 200))
    ret = Image.open(os.path.join(SPR, 'retratos', 'ryker', 'ryker_retratos.png')).convert('RGBA').crop((144, 0, 288, 208))
    b.alpha_composite(ret.resize((180, 260), Image.NEAREST), (150, 10))
    quadros.append(b)
    # 3
    d3 = c['q3_fundo'].copy(); d3.alpha_composite(c['q3_tunel'])
    d3.alpha_composite(pose_ryker(1), (200, 168)); d3.alpha_composite(c['q2_guarda'].crop((0, 0, 40, 48)), (60, 168))
    d3.alpha_composite(c['q3_frente']); quadros.append(d3)
    # 4
    e = c['q4_fundo'].copy(); e.alpha_composite(c['q4_luz'].crop((0, 0, 200, 200)), (200, 35)); e.alpha_composite(c['q4_anel'])
    e.alpha_composite(c['nave_kharn'], (20, 150)); e.alpha_composite(c['nave_ryker'].crop((0, 0, 48, 20)), (170, 140))
    quadros.append(e)
    # 5
    f5 = c['q5_faixas'].crop((200, 0, 680, 270)); f5.alpha_composite(c['nave_ryker'].crop((48, 0, 96, 20)).resize((144, 60), Image.NEAREST), (168, 105))
    quadros.append(f5)
    # 6
    v = [Image.open(os.path.join(SPR, 'cenarios', 'varrek', f'varrek_parallax_{n}.png')).convert('RGBA') for n in ('0_ceu_anel', '1_cascos_longe', '2_cascos_meio')]
    g6 = v[0].copy(); g6.alpha_composite(v[1]); g6.alpha_composite(v[2])
    dc = c['q6_destroco_fogo']
    for (x, y, k) in ((120, 60, 0), (260, 30, 1), (340, 110, 0)):
        g6.alpha_composite(dc.crop((k * 20, 0, k * 20 + 20, 28)), (x, y))
    g6.alpha_composite(c['q6_poeira'].crop((128, 0, 192, 32)), (220, 214)); quadros.append(g6)
    # 7
    g7 = v[0].copy(); g7.alpha_composite(v[1]); g7.alpha_composite(v[2])
    g7.alpha_composite(c['q7_fumaca'].crop((0, 0, 16, 64)), (230, 160)); g7.alpha_composite(c['q7_feixe_ambar'].crop((0, 0, 64, 270)), (208, 0))
    pa = c['particula_ambar']; random.seed(7)
    for _ in range(14):
        k = random.randrange(3); g7.alpha_composite(pa.crop((k * 3, 0, k * 3 + 3, 3)), (220 + random.randrange(40), random.randrange(60, 220)))
    quadros.append(g7)
    # 8
    h8 = c['q8_fundo'].crop((240, 0, 720, 270)); h8.alpha_composite(c['q8_nave_eco'].crop((240, 0, 720, 270))); quadros.append(h8)
    # 9
    i9 = c['q9_fundo'].copy(); i9.alpha_composite(c['q9_silhueta'].crop((96 * 4, 0, 96 * 5, 96)), (196, 104)); quadros.append(i9)
    m = Image.new('RGBA', (1440 + 8, 810 + 8), (40, 30, 48, 255))
    for k, q in enumerate(quadros):
        m.alpha_composite(q, (4 + (k % 3) * 480, 4 + (k // 3) * 270))
    return m


def main():
    c = {}
    c['q1_fundo'], c['q1_multidao_fundo'], c['q1_multidao_frente'] = q1()
    c['q1_urkesh_caido'] = urkesh_caido()
    c['q2_guarda'] = guarda()
    c['q3_fundo'], c['q3_tunel'], c['q3_frente'], c['q3_hangar'] = q3()
    c['nave_ryker'] = folha([nave_ryker(0), nave_ryker(1), nave_ryker(2)])
    c['nave_ryker_chama'] = chama()
    c['nave_kharn'] = nave_kharn()
    c['q4_fundo'], c['q4_anel'], c['q4_luz'] = q4()
    c['q5_faixas'] = q5()
    c['q6_destroco_fogo'] = destroco_em_chamas()
    c['q6_poeira'] = poeira()
    c['q7_fumaca'] = fumaca()
    c['q7_feixe_ambar'] = feixe_ambar()
    c['particula_ambar'] = particula_ambar()
    c['q8_fundo'], c['q8_nave_eco'] = q8()
    c['q9_fundo'], c['q9_silhueta'] = q9()
    for k, im in c.items():
        salvar(im, k + '.png')
    m = montar_mockup(c)
    m.save(os.path.join(SPR, 'conceito', 'mockup_v13_abertura.png'))
    print('ok', len(c), 'arquivos')


if __name__ == '__main__':
    main()
