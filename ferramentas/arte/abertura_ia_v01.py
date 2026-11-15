"""ART-5 (parte 2) — trata as imagens do pacote 10 (IA) e troca as peças provisórias da abertura.

Uso: python3 ferramentas/arte/abertura_ia_v01.py   (depois de abertura_v01.py; Python 3 + Pillow + numpy)
Entrada: ferramentas/arte/originais_ia/10A..10E_*_v1.png
Saída (assets/sprites/abertura/): q1_fundo_ia.png (480×540), q4_fundo_ia.png (480×270), q4_redemoinho_ia.png (190×190),
       q8_fundo_ia.png (720×360), q9_fundo_ia.png (480×270), nave_ryker_ia.png (3 quadros 52×24), nave_kharn_ia.png
       + conceito/mockup_v13_abertura.png refeito com as versões da IA.

Fundos: amostragem na grade de pixels da IA + 48 cores próprias (como o fundo do título); a paleta do jogo
estragaria os tons de luz. Naves: tratar_ia.py (paleta do jogo, contorno), na mesma escala da folha (~9,5 px por pixel).
"""
from PIL import Image
import numpy as np
import os, subprocess, sys

AQUI = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, AQUI)
RAIZ = os.path.join(AQUI, '..', '..')
ORIG = os.path.join(AQUI, 'originais_ia')
SAIDA = os.path.join(RAIZ, 'assets', 'sprites', 'abertura')
SPR = os.path.join(RAIZ, 'assets', 'sprites')
TMP = '/tmp/abertura_ia'


def reduzir(nome, W, H, cores=48):
    """Reduz a imagem da IA para W×H escolhendo a fase da grade com blocos mais uniformes."""
    src = Image.open(os.path.join(ORIG, nome)).convert('RGB')
    a = np.asarray(src).astype(float)
    sx, sy = src.width / W, src.height / H
    melhor = None
    for fx in np.linspace(0, sx, 6, endpoint=False):
        for fy in np.linspace(0, sy, 6, endpoint=False):
            xs = np.clip((np.arange(W) * sx + fx + sx / 2).astype(int), 0, src.width - 1)
            ys = np.clip((np.arange(H) * sy + fy + sy / 2).astype(int), 0, src.height - 1)
            c = a[ys][:, xs]
            d = np.abs(a[np.clip(ys + 1, 0, src.height - 1)][:, np.clip(xs + 1, 0, src.width - 1)] - c).sum()
            if melhor is None or d < melhor[0]:
                melhor = (d, xs, ys)
    _, xs, ys = melhor
    img = Image.fromarray(a[ys][:, xs].astype('uint8'))
    return img.quantize(colors=cores, method=Image.MEDIANCUT, dither=Image.NONE).convert('RGBA')


def redemoinho(fundo, cx, cy, r):
    """Recorte circular da luz do Portão, para o DEV girar devagar por cima do fundo."""
    rec = fundo.crop((cx - r, cy - r, cx + r, cy + r)).copy(); px = rec.load()
    for y in range(2 * r):
        for x in range(2 * r):
            if (x - r) ** 2 + (y - r) ** 2 > r * r:
                px[x, y] = (0, 0, 0, 0)
    return rec


def naves():
    """Separa a folha 10E e trata cada nave na mesma escala (~9,5 px da IA por pixel do jogo)."""
    os.makedirs(TMP, exist_ok=True)
    im = Image.open(os.path.join(ORIG, '10E_naves_v1.png')).convert('RGB'); a = np.asarray(im).astype(int)
    mag = (a[..., 0] > 200) & (a[..., 1] < 80) & (a[..., 2] > 200)
    cols = np.where((~mag).any(0))[0]; i = np.diff(cols).argmax(); corte = (cols[i] + cols[i + 1]) // 2
    saidas = {}
    for nome, (x0, x1), alt in (('pequena', (0, corte), 22), ('grande', (corte, im.width), 58)):
        sub = ~mag[:, x0:x1]; ys = np.where(sub.any(1))[0]; xx = np.where(sub.any(0))[0]
        box = (max(0, x0 + xx[0] - 20), ys[0] - 20, x0 + xx[-1] + 20, ys[-1] + 20)
        im.crop(box).save(os.path.join(TMP, nome + '.png'))
        dest = os.path.join(TMP, nome + '_t.png')
        subprocess.run([sys.executable, os.path.join(AQUI, 'tratar_ia.py'), os.path.join(TMP, nome + '.png'), dest,
                        '--altura', str(alt), '--cores', 'kKmMxohgGwWef', '--rampas'], check=True, capture_output=True)
        t = Image.open(dest).convert('RGBA'); saidas[nome] = t.crop(t.getbbox())
    return saidas['pequena'], saidas['grande']


def rachar(nave, n):
    """Quadros da nave do Ryker rachando ao meio (quadro 5 da abertura)."""
    q = Image.new('RGBA', (52, 24), (0, 0, 0, 0)); q.alpha_composite(nave, ((52 - nave.width) // 2, (24 - nave.height) // 2))
    if n:
        px = q.load(); meio = 26
        for y in range(24):
            x = meio + (y % 3) - 1
            for k in range(-n, n + 1):
                if 0 <= x + k < 52:
                    px[x + k, y] = (0, 0, 0, 0)
        esq = q.crop((0, 0, meio, 24)); dir_ = q.crop((meio, 0, 52, 24))
        q = Image.new('RGBA', (52, 24), (0, 0, 0, 0))
        q.alpha_composite(esq.rotate(4 * n, center=(meio, 12)), (-n, 0)); q.alpha_composite(dir_.rotate(-4 * n, center=(0, 12)), (meio + n, 0))
    return q


def mockup():
    """Refaz conceito/mockup_v13_abertura.png com as peças da IA."""
    import abertura_v01 as P
    c = {}
    for f in os.listdir(SAIDA):
        if f.endswith('.png'):
            c[f[:-4]] = Image.open(os.path.join(SAIDA, f)).convert('RGBA')
    q = []
    # 1: arena da IA + Ur-Kesh caído + Ryker no círculo de luz
    a = c['q1_fundo_ia'].copy()
    a.alpha_composite(c['q1_urkesh_caido'], (262, 456 - 80)); a.alpha_composite(P.pose_ryker(0), (214, 456 - 48))
    q.append(a.crop((0, 270, 480, 540)))
    # 2
    b = c['q1_fundo_ia'].crop((0, 270, 480, 540)); b.alpha_composite(Image.new('RGBA', b.size, (10, 6, 14, 120)))
    g = c['q2_guarda']; b.alpha_composite(g.crop((0, 0, 40, 48)), (20, 200)); b.alpha_composite(g.crop((40, 0, 80, 48)).transpose(Image.FLIP_LEFT_RIGHT), (420, 200))
    ret = Image.open(os.path.join(SPR, 'retratos', 'ryker', 'ryker_retratos.png')).convert('RGBA').crop((144, 0, 288, 208))
    b.alpha_composite(ret.resize((180, 260), Image.NEAREST), (150, 10)); q.append(b)
    # 3: fim do túnel, a nave no hangar
    d3 = c['q3_hangar'].copy(); d3.alpha_composite(c['nave_ryker_ia'].crop((0, 0, 52, 24)).resize((96, 48), Image.NEAREST), (300, 166))
    d3.alpha_composite(P.pose_ryker(2), (220, 150)); q.append(d3)
    # 4
    e = c['q4_fundo_ia'].copy(); e.alpha_composite(c['nave_kharn_ia'], (4, 170)); e.alpha_composite(c['nave_ryker_ia'].crop((0, 0, 52, 24)), (178, 170))
    q.append(e)
    # 5
    f5 = c['q5_faixas'].crop((200, 0, 680, 270)); f5.alpha_composite(c['nave_ryker_ia'].crop((104, 0, 156, 24)).resize((156, 72), Image.NEAREST), (168, 100)); q.append(f5)
    # 6 e 7 (iguais à versão por código)
    v = [Image.open(os.path.join(SPR, 'cenarios', 'varrek', f'varrek_parallax_{n}.png')).convert('RGBA') for n in ('0_ceu_anel', '1_cascos_longe', '2_cascos_meio')]
    g6 = v[0].copy(); g6.alpha_composite(v[1]); g6.alpha_composite(v[2])
    for (x, y, k) in ((120, 60, 0), (260, 30, 1), (340, 110, 0)):
        g6.alpha_composite(c['q6_destroco_fogo'].crop((k * 20, 0, k * 20 + 20, 28)), (x, y))
    g6.alpha_composite(c['q6_poeira'].crop((128, 0, 192, 32)), (220, 214)); q.append(g6)
    g7 = v[0].copy(); g7.alpha_composite(v[1]); g7.alpha_composite(v[2])
    g7.alpha_composite(c['q7_fumaca'].crop((0, 0, 16, 64)), (230, 160)); g7.alpha_composite(c['q7_feixe_ambar'].crop((0, 0, 64, 270)), (208, 0)); q.append(g7)
    # 8: janela de 480×270 no meio do pan
    q.append(c['q8_fundo_ia'].crop((120, 40, 600, 310)))
    # 9: a silhueta se formando sobre a maca
    i9 = c['q9_fundo_ia'].copy(); i9.alpha_composite(c['q9_silhueta'].crop((96 * 4, 0, 96 * 5, 96)), (196, 62)); q.append(i9)
    m = Image.new('RGBA', (1448, 818), (40, 30, 48, 255))
    for k, im in enumerate(q):
        m.alpha_composite(im, (4 + (k % 3) * 480, 4 + (k // 3) * 270))
    m.save(os.path.join(SPR, 'conceito', 'mockup_v13_abertura.png'))


def main():
    salvar = lambda im, n: im.save(os.path.join(SAIDA, n))
    salvar(reduzir('10A_arena_v1.png', 480, 540), 'q1_fundo_ia.png')
    q4 = reduzir('10B_portao_v1.png', 480, 270)
    salvar(q4, 'q4_fundo_ia.png'); salvar(redemoinho(q4, 240, 135, 95), 'q4_redemoinho_ia.png')
    salvar(reduzir('10C_nave_eco_v1.png', 720, 360), 'q8_fundo_ia.png')
    salvar(reduzir('10D_reconstrutor_v1.png', 480, 270), 'q9_fundo_ia.png')
    pequena, grande = naves()
    f = Image.new('RGBA', (156, 24), (0, 0, 0, 0))
    for n in range(3):
        f.alpha_composite(rachar(pequena, n), (n * 52, 0))
    salvar(f, 'nave_ryker_ia.png'); salvar(grande, 'nave_kharn_ia.png')
    mockup()
    print('ok', pequena.size, grande.size)


if __name__ == '__main__':
    main()
