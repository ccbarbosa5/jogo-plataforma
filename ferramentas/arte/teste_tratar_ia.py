"""Teste da ferramenta de tratamento (D-039).

Pega sprites de verdade do Ryker, estraga do jeito que um gerador de imagem estraga
(escala quebrada, borrão, ruído, JPEG, fundo magenta com variação) e confere se o
tratar_ia.py devolve algo próximo do original. Rodar: python3 ferramentas/arte/teste_tratar_ia.py
"""
import io, os, sys, tempfile
import numpy as np
from PIL import Image, ImageFilter

AQUI = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, AQUI)
import tratar_ia
from sprites_v02 import pernas_ryker, tronco_ryker, ryker_inteiro

rnd = np.random.default_rng(3)


def estragar(figs, escala=13.37):
    larg = int(sum(f.width for f in figs) * escala + 200); alt = int(max(f.height for f in figs) * escala + 160)
    fundo = np.clip(np.array([248, 6, 250]) + rnd.normal(0, 6, (alt, larg, 3)), 0, 255).astype(np.uint8)
    tela = Image.fromarray(fundo).convert('RGBA'); x = 60
    for f in figs:
        g = f.resize((round(f.width * escala), round(f.height * escala)), Image.BICUBIC)
        tela.alpha_composite(g, (x, alt - g.height - 60)); x += g.width + 40
    tela = tela.convert('RGB').filter(ImageFilter.GaussianBlur(1.6))
    arr = np.clip(np.asarray(tela, float) + rnd.normal(0, 7, (alt, larg, 3)), 0, 255).astype(np.uint8)
    buf = io.BytesIO(); Image.fromarray(arr).save(buf, 'JPEG', quality=78); buf.seek(0)
    return Image.open(buf).convert('RGB')


def comparar(a, b):
    """IoU da silhueta e fração de cores iguais, no melhor alinhamento de até 1 px."""
    A = np.asarray(a); melhor = (0, 0)
    for dx in (-1, 0, 1):
        for dy in (-1, 0, 1):
            B = np.roll(np.asarray(b), (dy, dx), (0, 1))
            ma, mb = A[..., 3] > 0, B[..., 3] > 0
            iou = (ma & mb).sum() / max(1, (ma | mb).sum())
            k = np.array([0x16, 0x11, 0x1c])  # o contorno é redesenhado de propósito: compara só o miolo
            ambos = ma & mb & ~(A[..., :3] == k).all(-1) & ~(B[..., :3] == k).all(-1)
            cor = (A[ambos][:, :3] == B[ambos][:, :3]).all(1).mean()
            melhor = max(melhor, (iou, cor))
    return melhor


def main():
    pern = pernas_ryker(); tron = tronco_ryker()
    qs, ds = pern['correr']
    originais = [ryker_inteiro(pern['parado'][0][0], tron['frente'][0]),
                 ryker_inteiro(qs[0], tron['frente'][0], ds[0]),
                 ryker_inteiro(qs[4], tron['diag_cima'][0], ds[4]),
                 ryker_inteiro(pern['parado'][0][0], tron['cima'][0])]
    alturas = [int((np.asarray(o)[..., 3] > 0).any(1).sum()) for o in originais]
    falsa = estragar(originais)
    with tempfile.TemporaryDirectory() as d:
        ent = os.path.join(d, 'falsa.png'); falsa.save(ent)
        figs, rel = tratar_ia.tratar(ent, 'sprite', altura=max(alturas), quadro=(32, 32), separar=True,
                                     chaves='kKoOhsScbBmMxXat')
        falsa.save(os.path.join(AQUI, '_teste_entrada.png')) if '--salvar' in sys.argv else None
        if '--salvar' in sys.argv:
            tratar_ia.xadrez(tratar_ia.folha(originais + figs), 6).save(os.path.join(AQUI, '_teste_resultado.png'))
    print('relatório:', rel)
    assert rel['figuras'] == 4, 'deveria separar 4 figuras'
    for i, (o, f) in enumerate(zip(originais, figs)):
        iou, cor = comparar(o, f)
        print(f'figura {i}: silhueta (IoU) {iou:.2f} · cores iguais no miolo {cor:.0%}')
        assert iou >= 0.85, 'silhueta muito diferente do original'
        assert cor >= 0.85, 'cores muito diferentes do original'
    # modo retrato: quadro 144×208, paleta ampliada, nunca a cor AVISO
    from sprites_v02 import guerreiro
    g = guerreiro(0, 2)  # tem o flash AVISO no canhão: tem que sumir no retrato
    falsa = estragar([g], escala=9.1)
    with tempfile.TemporaryDirectory() as d:
        ent = os.path.join(d, 'r.png'); falsa.save(ent)
        figs, rel = tratar_ia.tratar(ent, 'retrato', quadro=(144, 208))
    a = np.asarray(figs[0]); cores = {tuple(c) for c in a[a[..., 3] > 0][:, :3]}
    print('retrato:', rel)
    assert figs[0].size == (144, 208)
    assert (0xff, 0xf3, 0xa0) not in cores, 'a cor AVISO não pode aparecer fora dos ataques'
    assert rel['cores_na_paleta'] > 100, 'paleta de retrato deveria ter rampas ampliadas'
    print('OK: a ferramenta recupera os sprites a partir de uma imagem estragada, e o modo retrato funciona.')


if __name__ == '__main__':
    main()
