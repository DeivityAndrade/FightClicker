# Ronda Noturna (Artista de Personagens): registra no manifest as folhas do VULTO (Gato Preto).
# Lê tools/art/ronda_personagens.json (gravado por tools/art/make_sprites_ronda_vulto.gd) e só acrescenta/atualiza essas chaves.
# ESTADO: AMOSTRA aguardando o dono. Enquanto não for aprovada, rode só com --check (não grava).
# Rodar de novo não muda nada (idempotente). Mantém o formato do manifest (tab, CRLF, UTF-8).
#   python tools/art/manifest_ronda_personagens.py --check    só diz o que mudaria (não grava)
#   python tools/art/manifest_ronda_personagens.py            grava assets/sprites/manifest.json
#   python tools/art/manifest_ronda_personagens.py <arquivo>  grava em outro manifest (cópia de teste)
import json
import os
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
PATH = os.path.join(ROOT, "assets", "sprites", "manifest.json")
META = os.path.join(ROOT, "tools", "art", "ronda_personagens.json")
PREFIX = "ronda_vulto_"
GEN = " Gerador: tools/art/make_sprites_ronda_vulto.gd; registro: manifest_ronda_personagens.py."


def inteiro(v):
    """O Godot grava 48.0; o manifest usa 48."""
    if isinstance(v, float) and v.is_integer():
        return int(v)
    if isinstance(v, list):
        return [inteiro(x) for x in v]
    if isinstance(v, dict):
        return {k: inteiro(x) for k, x in v.items()}
    return v


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    check = "--check" in sys.argv
    path = args[0] if args else PATH
    raw = open(path, "rb").read().decode("utf-8")
    m = json.loads(raw)
    meta = json.load(open(META, encoding="utf-8"))
    S = m["sprites"]
    novos = mudados = 0
    for sid, e in meta["sprites"].items():
        if not sid.startswith(PREFIX):
            raise SystemExit("id fora da Ronda (vulto): " + sid)
        e = inteiro(e)
        if not str(e.get("note", "")).endswith(GEN):
            e["note"] = str(e.get("note", "")) + GEN
        if sid not in S:
            novos += 1
        elif S[sid] != e:
            mudados += 1
        S[sid] = e
        arq = e["file"].replace("res://", "")
        if not os.path.exists(os.path.join(ROOT, arq)):
            print("AVISO: falta o arquivo " + arq + " (amostra: as folhas ainda não foram para assets/)")
    out = json.dumps(m, indent="\t", ensure_ascii=False).replace("\n", "\r\n") + "\r\n"
    igual = out == raw
    print("ronda personagens: %d sprites (%d novos, %d mudados); %s" % (
        len(meta["sprites"]), novos, mudados, "nada mudou" if igual else ("mudaria" if check else "gravado")))
    if not check and not igual:
        open(path, "wb").write(out.encode("utf-8"))


if __name__ == "__main__":
    main()
