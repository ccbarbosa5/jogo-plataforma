"""ART-6 — logo animado de No Rest (D-073A), a partir do logo definitivo (variação 3, D-060).

Uso: python3 ferramentas/arte/logo_animado_v01.py   (Python 3 + Pillow).
Saída: assets/sprites/ui/titulo/logo_animado.png (folha em grade) + logo_animado_previa.gif (só conferência, fora do jogo:
       em ferramentas/arte/previas/).

Sequência (12 qps, 56 quadros ≈ 4,7 s; depois o último quadro fica parado):
  0–9    surge   : a silhueta escura do logo aparece em pontilhado (metal frio, apagado)
  10–29  acende  : uma linha de brasa corre da esquerda para a direita, inclinada como as letras, e deixa o metal aceso
  30–41  quebra  : faíscas saem da corrente partida (é o momento do som curto)
  42–55  brilho  : um reflexo branco atravessa as letras; o último quadro é o logo normal
"""
from PIL import Image
import math, os, random, sys

AQUI = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, AQUI)
from prancha_estilo import rgb, bayer

RAIZ = os.path.join(AQUI, '..', '..')
PASTA = os.path.join(RAIZ, 'assets', 'sprites', 'ui', 'titulo')
PAD = 10
QUEBRA = (129, 53)  # centro da corrente partida, em pixels do logo
INCL = 0.28        # inclinação das letras (para a linha de brasa e o reflexo)
N_SURGE, N_ACENDE, N_QUEBRA, N_BRILHO = 10, 20, 12, 14
COLUNAS = 8


def carregar():
    return Image.open(os.path.join(PASTA, 'logo_no_rest.png')).convert('RGBA')


def e_contorno(c):
    return c[0] + c[1] + c[2] < 110  # contorno e sombras quase pretas ficam como estão


def quadro_vazio(logo):
    return Image.new('RGBA', (logo.width + 2 * PAD, logo.height + 2 * PAD), (0, 0, 0, 0))


def silhueta(logo, px, x, y):
    c = px[x, y]
    return c if e_contorno(c) else rgb('K')


def surge(logo, f):
    q = quadro_vazio(logo); px = logo.load(); qp = q.load()
    lim = (f + 1) / N_SURGE
    for y in range(logo.height):
        for x in range(logo.width):
            if px[x, y][3] and bayer(x, y) < lim:
                qp[x + PAD, y + PAD] = silhueta(logo, px, x, y)
    return q


def acende(logo, f):
    q = quadro_vazio(logo); px = logo.load(); qp = q.load()
    frente = -20 + (logo.width + 40) * (f + 1) / N_ACENDE
    for y in range(logo.height):
        for x in range(logo.width):
            c = px[x, y]
            if not c[3]:
                continue
            d = frente - (x + (logo.height - y) * INCL)  # >0: já passou
            if d < 0:
                qp[x + PAD, y + PAD] = silhueta(logo, px, x, y)
            elif e_contorno(c):
                qp[x + PAD, y + PAD] = c
            elif d < 2:
                qp[x + PAD, y + PAD] = rgb('w')
            elif d < 4:
                qp[x + PAD, y + PAD] = rgb('h')
            elif d < 7:
                qp[x + PAD, y + PAD] = rgb('f') if bayer(x, y) < 0.5 else c
            else:
                qp[x + PAD, y + PAD] = c
    return q


FAISCAS = None


def faiscas():
    global FAISCAS
    if FAISCAS is None:
        random.seed(73)
        FAISCAS = []
        for i in range(26):
            ang = -math.pi / 2 + random.uniform(-1.3, 1.3)
            v = random.uniform(2.4, 4.6)
            FAISCAS.append((math.cos(ang) * v, math.sin(ang) * v, random.choice('wwhhf'), random.randint(7, 12)))
    return FAISCAS


def quebra(logo, f):
    q = quadro_vazio(logo)
    q.alpha_composite(logo, (PAD, PAD))
    qp = q.load()
    cx, cy = QUEBRA[0] + PAD, QUEBRA[1] + PAD
    if f < 2:  # clarão na quebra
        for dy in range(-3, 4):
            for dx in range(-3, 4):
                if abs(dx) + abs(dy) <= 3 - f:
                    xx, yy = cx + dx, cy + dy
                    if 0 <= xx < q.width and 0 <= yy < q.height:
                        qp[xx, yy] = rgb('w' if abs(dx) + abs(dy) < 2 else 'h')
    for (vx, vy, cor, vida) in faiscas():
        if f >= vida:
            continue
        t = f + 1
        x = cx + vx * t
        y = cy + vy * t + 0.18 * t * t  # gravidade
        for k in range(2):  # rastro de 2 px
            xx, yy = int(round(x - vx * k * 0.5)), int(round(y - vy * k * 0.5))
            if 0 <= xx < q.width and 0 <= yy < q.height:
                qp[xx, yy] = rgb(cor if k == 0 else 'f')
    return q


def brilho(logo, f):
    q = quadro_vazio(logo); px = logo.load(); qp = q.load()
    q.alpha_composite(logo, (PAD, PAD))
    if f >= N_BRILHO - 3:
        return q  # termina no logo limpo
    frente = -10 + (logo.width + 30) * (f + 1) / (N_BRILHO - 3)
    for y in range(logo.height):
        for x in range(logo.width):
            c = px[x, y]
            if not c[3] or e_contorno(c):
                continue
            d = frente - (x + (logo.height - y) * INCL)
            if 0 <= d < 2:
                qp[x + PAD, y + PAD] = rgb('w')
            elif 2 <= d < 3:
                qp[x + PAD, y + PAD] = rgb('h')
    return q


def quadros():
    logo = carregar()
    q = [surge(logo, f) for f in range(N_SURGE)]
    q += [acende(logo, f) for f in range(N_ACENDE)]
    q += [quebra(logo, f) for f in range(N_QUEBRA)]
    q += [brilho(logo, f) for f in range(N_BRILHO)]
    return q


def grade(q):
    w, h = q[0].size
    linhas = math.ceil(len(q) / COLUNAS)
    g = Image.new('RGBA', (w * COLUNAS, h * linhas), (0, 0, 0, 0))
    for i, im in enumerate(q):
        g.alpha_composite(im, ((i % COLUNAS) * w, (i // COLUNAS) * h))
    return g


def previa(q):
    fundo = (22, 17, 28, 255)
    seq = []
    for im in q + [q[-1]] * 18:
        b = Image.new('RGBA', im.size, fundo); b.alpha_composite(im)
        seq.append(b.resize((im.width * 3, im.height * 3), Image.NEAREST).convert('P', palette=Image.ADAPTIVE))
    pasta = os.path.join(AQUI, 'previas'); os.makedirs(pasta, exist_ok=True)
    caminho = os.path.join(pasta, 'logo_animado_previa.gif')
    seq[0].save(caminho, save_all=True, append_images=seq[1:], duration=83, loop=0, disposal=2)
    return caminho


def main():
    q = quadros()
    g = grade(q)
    g.save(os.path.join(PASTA, 'logo_animado.png'))
    print('quadros', len(q), 'tamanho', q[0].size, 'folha', g.size, previa(q))


if __name__ == '__main__':
    main()
