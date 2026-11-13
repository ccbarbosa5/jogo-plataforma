"""Ferramenta de tratamento da ART (D-039): imagem gerada por IA -> pixel art de verdade.

Os geradores de imagem fazem "falsa pixel art": grade irregular, pixels borrados, cores demais,
fundo sólido. Esta ferramenta deixa todas as peças iguais:
  1. tira o fundo (transparência própria, ou cor lisa nas bordas, ou magenta #FF00FF);
  2. recorta a figura (ou separa várias figuras de uma mesma imagem com --separar);
  3. reduz para o tamanho exato do jogo com grade limpa (amostragem por moda, sem meio-tom);
  4. converte para a paleta oficial (ART-01 / D-033) — no modo retrato, uma paleta ampliada
     com rampas de 5 a 7 tons derivadas da mesma base (D-032);
  5. limpa pixels soltos e refaz o contorno de 1 px;
  6. encaixa no quadro com a origem nos pés e monta a folha.

Exemplos:
  # 1 pose do Ryker, corpo com 28 px de altura, num quadro 32×32
  python3 ferramentas/arte/tratar_ia.py entrada.png saida.png --altura 28 --quadro 32x32

  # imagem com várias poses lado a lado -> folha de animação
  python3 ferramentas/arte/tratar_ia.py poses.png ryker_correr.png --separar --altura 28 --quadro 32x32

  # 4 expressões de retrato numa imagem -> 4 retratos 144×208 (meio corpo, cortado embaixo)
  python3 ferramentas/arte/tratar_ia.py expressoes.png ryker_retratos.png --modo retrato --separar --quadro 144x208

Requer Python 3 + Pillow + numpy.
"""
import argparse, math, os, sys
import numpy as np
from PIL import Image

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
from prancha_estilo import PAL  # paleta oficial v0.1

MAGENTA = np.array([255, 0, 255], float)


# ----------------------------------------------------------------- cor
def srgb_para_oklab(rgb):
    c = np.asarray(rgb, float) / 255.0
    c = np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    M1 = np.array([[0.4122214708, 0.5363325363, 0.0514459929],
                   [0.2119034982, 0.6806757226, 0.1073784320],
                   [0.0883024619, 0.2817188376, 0.6299787005]])
    lms = np.cbrt(c @ M1.T)
    M2 = np.array([[0.2104542553, 0.7936617850, -0.0040720468],
                   [1.9779984951, -2.4285922050, 0.4505937099],
                   [0.0259040371, 0.7827717662, -0.8086757660]])
    return lms @ M2.T


def hex_rgb(h):
    h = h.lstrip('#'); return [int(h[i:i + 2], 16) for i in (0, 2, 4)]


def mistura(a, b, t):
    return [round(a[i] + (b[i] - a[i]) * t) for i in range(3)]


def montar_paleta(modo, chaves=None, permitir_aviso=False, rampas=None):
    """Retorna (rgb Nx3, nomes). Sprite: paleta v0.1 exata. Retrato: rampas derivadas (D-032)."""
    base = {k: hex_rgb(v[0]) for k, v in PAL.items()}
    if not permitir_aviso:
        base.pop('y', None)  # AVISO é reservada para ataques anunciados (D-033)
    if chaves:
        base = {k: v for k, v in base.items() if k in chaves or k in 'kK'}
    cores, nomes = [], []
    escuro, claro = hex_rgb('#16111c'), hex_rgb('#fff6ea')
    for k, c in base.items():
        cores.append(c); nomes.append(k)
        if (rampas if rampas is not None else modo == 'retrato') and k not in 'kKt':
            for t in (0.22, 0.45):
                cores.append(mistura(c, escuro, t)); nomes.append(k + '-')
            for t in (0.18, 0.36):
                cores.append(mistura(c, claro, t)); nomes.append(k + '+')
    rgb = np.unique(np.array(cores, float), axis=0, return_index=True)
    idx = sorted(rgb[1])
    return np.array(cores, float)[idx], [nomes[i] for i in idx]


def quantizar(rgb_img, paleta):
    """rgb_img HxWx3 -> índices na paleta (vizinho mais próximo em OKLab)."""
    lab = srgb_para_oklab(rgb_img.reshape(-1, 3))
    plab = srgb_para_oklab(paleta)
    d = ((lab[:, None, :] - plab[None, :, :]) ** 2).sum(-1)
    return d.argmin(1).reshape(rgb_img.shape[:2])


# ----------------------------------------------------------------- fundo e figuras
def dilatar(m):
    o = m.copy()
    o[1:] |= m[:-1]; o[:-1] |= m[1:]; o[:, 1:] |= m[:, :-1]; o[:, :-1] |= m[:, 1:]
    return o


def mascara_figura(img, modo_fundo='auto', tol=48.0):
    a = np.asarray(img.convert('RGBA'), float)
    rgb, alfa = a[..., :3], a[..., 3]
    if modo_fundo == 'nenhum':
        return alfa > 127
    if modo_fundo == 'auto' and alfa.min() < 250:
        return alfa > 127
    borda = np.concatenate([rgb[0], rgb[-1], rgb[:, 0], rgb[:, -1]])
    cor_fundo = np.median(borda, 0)
    perto_fundo = np.sqrt(((rgb - cor_fundo) ** 2).sum(-1)) < tol
    perto_magenta = np.sqrt(((rgb - MAGENTA) ** 2).sum(-1)) < 110
    # flood fill a partir das bordas, só por pixels parecidos com o fundo
    fundo = np.zeros_like(perto_fundo)
    fundo[0] = perto_fundo[0]; fundo[-1] = perto_fundo[-1]; fundo[:, 0] = perto_fundo[:, 0]; fundo[:, -1] = perto_fundo[:, -1]
    while True:
        novo = dilatar(fundo) & perto_fundo
        if (novo == fundo).all(): break
        fundo = novo
    return ~(fundo | perto_magenta) & (alfa > 127)


def tirar_franja(img, mask, largura):
    """Na faixa de borda da figura, descarta pixels contaminados pelo magenta do fundo."""
    rgb = np.asarray(img.convert('RGB'), float)
    fundo = ~mask
    for _ in range(max(1, largura)):
        fundo = dilatar(fundo)
    banda = mask & fundo
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    magentado = (r - g > 35) & (b - g > 35)
    return mask & ~(banda & magentado)


def componentes(mask, passo=4, minimo=0.02):
    """Separa figuras (rótulos numa grade reduzida). Retorna caixas (x0,y0,x1,y1), ordenadas."""
    h, w = mask.shape
    hh, ww = math.ceil(h / passo), math.ceil(w / passo)
    pad = np.zeros((hh * passo, ww * passo), bool); pad[:h, :w] = mask
    g = pad.reshape(hh, passo, ww, passo).any((1, 3))
    rot = np.zeros(g.shape, int); n = 0; caixas = []
    for y0 in range(hh):
        for x0 in range(ww):
            if g[y0, x0] and not rot[y0, x0]:
                n += 1; pilha = [(y0, x0)]; rot[y0, x0] = n; pts = []
                while pilha:
                    y, x = pilha.pop(); pts.append((y, x))
                    for dy in (-1, 0, 1):
                        for dx in (-1, 0, 1):
                            yy, xx = y + dy, x + dx
                            if 0 <= yy < hh and 0 <= xx < ww and g[yy, xx] and not rot[yy, xx]:
                                rot[yy, xx] = n; pilha.append((yy, xx))
                ys, xs = zip(*pts)
                caixas.append((len(pts), min(xs) * passo, min(ys) * passo, min(w, (max(xs) + 1) * passo), min(h, (max(ys) + 1) * passo)))
    if not caixas: return []
    maior = max(c[0] for c in caixas)
    caixas = [c[1:] for c in caixas if c[0] >= maior * minimo]
    # Linhas = figuras que se sobrepõem na vertical (poses de alturas diferentes ficam na mesma linha);
    # dentro de cada linha, da esquerda para a direita.
    linhas = []
    for c in sorted(caixas, key=lambda c: (c[1] + c[3]) / 2):
        if linhas:
            y0, y1 = linhas[-1]['span']
            sobrepoe = min(y1, c[3]) - max(y0, c[1])
            if sobrepoe >= 0.5 * min(c[3] - c[1], y1 - y0):
                linhas[-1]['caixas'].append(c); linhas[-1]['span'] = (min(y0, c[1]), max(y1, c[3])); continue
        linhas.append({'span': (c[1], c[3]), 'caixas': [c]})
    return [c for l in linhas for c in sorted(l['caixas'], key=lambda c: c[0])]


def recortar(mask, caixa=None):
    if caixa:
        x0, y0, x1, y1 = caixa; sub = np.zeros_like(mask); sub[y0:y1, x0:x1] = mask[y0:y1, x0:x1]; mask = sub
    ys, xs = np.nonzero(mask)
    return xs.min(), ys.min(), xs.max() + 1, ys.max() + 1, mask


# ----------------------------------------------------------------- redução com grade limpa
def _reduzir_fase(img, mask, bbox, escala, paleta, fx, fy, sub):
    x0, y0, x1, y1 = bbox
    W = max(1, round((x1 - x0) / escala) + 1); H = max(1, round((y1 - y0) / escala) + 1)
    caixa = (x0 - fx, y0 - fy, x0 - fx + W * escala, y0 - fy + H * escala)
    rgb = np.asarray(img.convert('RGB').resize((W * sub, H * sub), Image.BOX, box=caixa), float)
    m = Image.fromarray((mask * 255).astype(np.uint8))
    alf = np.asarray(m.resize((W * sub, H * sub), Image.BOX, box=caixa), float) / 255.0
    idx = quantizar(rgb, paleta)
    idx_b = idx.reshape(H, sub, W, sub).transpose(0, 2, 1, 3).reshape(H, W, -1)
    alf_b = alf.reshape(H, sub, W, sub).transpose(0, 2, 1, 3).reshape(H, W, -1)
    opaco = alf_b.mean(-1) >= 0.5
    saida = np.full((H, W), -1, int); purezas = []
    for y in range(H):
        for x in range(W):
            if opaco[y, x]:
                v = idx_b[y, x][alf_b[y, x] >= 0.5]
                if v.size == 0: v = idx_b[y, x]
                cont = np.bincount(v); saida[y, x] = cont.argmax(); purezas.append(cont.max() / v.size)
    # tira linhas/colunas vazias que sobraram da margem
    ys, xs = np.nonzero(saida >= 0)
    if ys.size: saida = saida[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    return saida, (np.mean(purezas) if purezas else 0.0)


def reduzir(img, mask, bbox, escala, paleta, sub=4, passos=4):
    """escala = px da fonte por px do jogo. Testa passos×passos fases da grade e fica com a mais
    "pura" (cada bloco com uma cor dominante): é assim que se acha a grade de uma falsa pixel art."""
    melhor = None
    for i in range(passos):
        for j in range(passos):
            r = _reduzir_fase(img, mask, bbox, escala, paleta, escala * i / passos, escala * j / passos, sub)
            if melhor is None or r[1] > melhor[1]: melhor = r
    return melhor[0]


def limpar_soltos(ind):
    """Pixel cercado por 8 vizinhos de outra cor, com maioria clara (>=6), vira a cor da maioria."""
    H, W = ind.shape; out = ind.copy()
    for y in range(1, H - 1):
        for x in range(1, W - 1):
            c = ind[y, x]
            if c < 0: continue
            viz = [ind[y + dy, x + dx] for dy in (-1, 0, 1) for dx in (-1, 0, 1) if dy or dx]
            if c in viz: continue
            vals, cont = np.unique(viz, return_counts=True)
            if cont.max() >= 6 and vals[cont.argmax()] >= 0:
                out[y, x] = vals[cont.argmax()]
    return out


def refazer_contorno(ind, paleta, i_contorno, descascar=True):
    H, W = ind.shape
    viz_transp = lambda a, y, x: any(not (0 <= y + dy < H and 0 <= x + dx < W) or a[y + dy, x + dx] < 0
                                    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)))
    if descascar:  # tira o contorno que veio da IA (grosso/irregular); cabelo e sombras escuras ficam
        out = ind.copy()
        for y in range(H):
            for x in range(W):
                if ind[y, x] == i_contorno and viz_transp(ind, y, x):
                    out[y, x] = -1
        ind = out
    pad = np.full((H + 2, W + 2), -1, int); pad[1:-1, 1:-1] = ind
    out = pad.copy()
    for y in range(H + 2):
        for x in range(W + 2):
            if pad[y, x] < 0:
                for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    yy, xx = y + dy, x + dx
                    if 0 <= yy < H + 2 and 0 <= xx < W + 2 and pad[yy, xx] >= 0 and pad[yy, xx] != i_contorno:
                        out[y, x] = i_contorno; break
    return out


def para_imagem(ind, paleta):
    H, W = ind.shape; a = np.zeros((H, W, 4), np.uint8)
    m = ind >= 0
    a[m, :3] = paleta[ind[m]].astype(np.uint8); a[m, 3] = 255
    return Image.fromarray(a, 'RGBA')


def encaixar(fig, quadro, modo):
    """Sprite: pés no fundo, centro dos pés no meio. Retrato: base cortada no fundo, centralizado."""
    Wq, Hq = quadro; q = Image.new('RGBA', quadro, (0, 0, 0, 0))
    a = np.asarray(fig)[..., 3] > 0
    if modo == 'sprite':
        linhas = np.nonzero(a.any(1))[0]; base = a[linhas[-4:]].any(0)
        cx = np.nonzero(base)[0].mean() if base.any() else fig.width / 2
    else:
        cx = fig.width / 2
    x = round(Wq / 2 - cx); y = Hq - fig.height
    if fig.width > Wq or fig.height > Hq:
        print(f'  ! aviso: figura {fig.size} maior que o quadro {quadro}; vai ser cortada', file=sys.stderr)
    q.alpha_composite(fig, (x, y)) if x >= 0 and y >= 0 else q.paste(fig, (x, y), fig)
    return q


def xadrez(img, s):
    big = img.resize((img.width * s, img.height * s), Image.NEAREST)
    fundo = Image.new('RGBA', big.size)
    px = fundo.load(); t = max(4, s * 4)
    for y in range(big.height):
        for x in range(big.width):
            px[x, y] = (70, 62, 80, 255) if (x // t + y // t) % 2 else (52, 46, 60, 255)
    fundo.alpha_composite(big); return fundo


# ----------------------------------------------------------------- principal
def tratar(entrada, modo='sprite', altura=None, quadro=None, separar=False, fundo='auto', chaves=None,
           limpar=True, contorno=True, permitir_aviso=False, rampas=None):
    img = Image.open(entrada).convert('RGBA')
    paleta, nomes = montar_paleta(modo, chaves, permitir_aviso, rampas)
    i_k = int(np.argmin(np.abs(paleta - np.array(hex_rgb('#16111c'))).sum(1)))
    mask = mascara_figura(img, fundo)
    caixas = componentes(mask) if separar else [None]
    recortes = [recortar(mask, c) for c in caixas]
    if not recortes: raise SystemExit('nenhuma figura encontrada (fundo removido demais?)')
    # A figura da IA já vem com contorno escuro: a altura pedida inclui o contorno.
    margem = 0
    maior_h = max(r[3] - r[1] for r in recortes)
    if altura:
        escala = maior_h / max(1, altura - margem)
    elif quadro:  # cabe no quadro (retratos: a altura do quadro)
        maior_w = max(r[2] - r[0] for r in recortes)
        escala = max(maior_h / (quadro[1] - 2), maior_w / (quadro[0] - 2))  # 2 px de folga: a busca de grade pode somar 1
    else:
        raise SystemExit('informe --altura ou --quadro')
    figuras = []
    mask = tirar_franja(img, mask, round(escala * 0.6))
    # margem transparente: a grade pode passar da borda (retratos de meio corpo encostam embaixo)
    P = int(escala * 3) + 2
    grande = Image.new('RGBA', (img.width + 2 * P, img.height + 2 * P), (0, 0, 0, 0)); grande.paste(img, (P, P)); img = grande
    mask = np.pad(mask, P)
    caixas = [None if c is None else (c[0] + P, c[1] + P, c[2] + P, c[3] + P) for c in caixas]
    recortes = [recortar(mask, c) for c in caixas]
    for (x0, y0, x1, y1, m) in recortes:
        ind = reduzir(img, m, (x0, y0, x1, y1), escala, paleta)
        if limpar: ind = limpar_soltos(ind)
        if contorno:
            ind = refazer_contorno(ind, paleta, i_k)
            if modo == 'retrato':  # meio corpo: o corte de baixo não tem contorno
                ind = ind[:-1]
                ultima = ind[-1]; ind[-1] = np.where(ultima == i_k, ind[-2], ultima)
        figuras.append(para_imagem(ind, paleta))
    if quadro:
        figuras = [encaixar(f, quadro, modo) for f in figuras]
    usadas = set()
    for f in figuras:
        a = np.asarray(f); usadas |= {tuple(c) for c in a[a[..., 3] > 0][:, :3]}
    relatorio = {'figuras': len(figuras), 'escala_fonte_por_px': round(float(escala), 2),
                 'tamanhos': [f.size for f in figuras], 'cores_usadas': len(usadas), 'cores_na_paleta': len(paleta)}
    return figuras, relatorio


def folha(figs):
    w = sum(f.width for f in figs); h = max(f.height for f in figs)
    s = Image.new('RGBA', (w, h), (0, 0, 0, 0)); x = 0
    for f in figs:
        s.alpha_composite(f, (x, h - f.height)); x += f.width
    return s


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('entrada'); p.add_argument('saida')
    p.add_argument('--modo', choices=['sprite', 'retrato'], default='sprite')
    p.add_argument('--altura', type=int, help='altura final da figura em px, com contorno (ex.: 28 para o Ryker)')
    p.add_argument('--quadro', help='LxA do quadro final, ex.: 32x32 ou 144x208')
    p.add_argument('--separar', action='store_true', help='a imagem tem várias figuras: vira uma folha')
    p.add_argument('--fundo', choices=['auto', 'nenhum'], default='auto')
    p.add_argument('--cores', help='só estas chaves da paleta (ex.: "kKoOhsScbBmMxXa"); contorno sempre entra')
    p.add_argument('--sem-limpeza', action='store_true'); p.add_argument('--sem-contorno', action='store_true')
    p.add_argument('--rampas', action='store_true', help='usa as rampas ampliadas (5 a 7 tons) também no modo sprite (ex.: a ECO, toda em âmbar)')
    p.add_argument('--permitir-aviso', action='store_true', help='libera a cor AVISO (só para efeitos de ataque)')
    p.add_argument('--previa', type=int, default=4, help='zoom da prévia (0 = sem prévia)')
    a = p.parse_args(argv)
    quadro = tuple(int(v) for v in a.quadro.lower().split('x')) if a.quadro else None
    figs, rel = tratar(a.entrada, a.modo, a.altura, quadro, a.separar, a.fundo, a.cores,
                       not a.sem_limpeza, not a.sem_contorno, a.permitir_aviso, True if a.rampas else None)
    s = folha(figs); s.save(a.saida)
    if a.previa:
        base, ext = os.path.splitext(a.saida); xadrez(s, a.previa).save(base + '_previa' + ext)
    print('ok', rel)
    return rel


if __name__ == '__main__':
    main()
