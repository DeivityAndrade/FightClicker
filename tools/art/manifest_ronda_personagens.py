# Ronda Noturna (Artista de Personagens): registra no manifest o ELENCO da tela "Estátua no telhado":
#   ronda_vulto_* (o vulto em camadas do discípulo) e ronda_thief_* (os 3 ladrões), + by_data_id.ronda_characters.
# Lê tools/art/ronda_personagens.json (gravado por tools/art/make_sprites_ronda.gd) e só acrescenta/atualiza essas chaves;
# chaves ronda_vulto_*/ronda_thief_* que saíram do gerador são apagadas. Não mexe nas chaves do Diretor de Arte
# (manifest_ronda.py), em qualquer ordem. Rodar de novo não muda nada (idempotente). Mantém o formato (tab, CRLF, UTF-8).
# O manifest é LIDO DE NOVO logo antes de gravar (outro agente pode ter gravado no meio).
#   python tools/art/manifest_ronda_personagens.py --check    só diz o que mudaria (não grava)
#   python tools/art/manifest_ronda_personagens.py            grava assets/sprites/manifest.json
#   python tools/art/manifest_ronda_personagens.py <arquivo>  grava em outro manifest (cópia de teste)
import json
import os
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
PATH = os.path.join(ROOT, "assets", "sprites", "manifest.json")
META = os.path.join(ROOT, "tools", "art", "ronda_personagens.json")
PREFIXES = ("ronda_vulto_", "ronda_thief_")
BY_KEY = "ronda_characters"
GEN = " Gerador: tools/art/make_sprites_ronda.gd; registro: manifest_ronda_personagens.py."


def inteiro(v):
    """O Godot grava 48.0; o manifest usa 48."""
    if isinstance(v, float) and v.is_integer():
        return int(v)
    if isinstance(v, list):
        return [inteiro(x) for x in v]
    if isinstance(v, dict):
        return {k: inteiro(x) for k, x in v.items()}
    return v


def aplicar(m, meta):
    S = m["sprites"]
    novos = mudados = apagados = 0
    for sid in [k for k in S if k.startswith(PREFIXES) and k not in meta["sprites"]]:
        del S[sid]
        apagados += 1
    for sid, e in meta["sprites"].items():
        if not sid.startswith(PREFIXES):
            raise SystemExit("id fora do elenco da Ronda: " + sid)
        e = inteiro(e)
        if not str(e.get("note", "")).endswith(GEN):
            e["note"] = str(e.get("note", "")) + GEN
        if sid not in S:
            novos += 1
        elif S[sid] != e:
            mudados += 1
        S[sid] = e
    by = inteiro(meta.get("by_data_id", {}).get(BY_KEY))
    if by is not None:
        m.setdefault("by_data_id", {})[BY_KEY] = by
    return novos, mudados, apagados


def arquivos(meta):
    falta = []
    for e in meta["sprites"].values():
        fs = [e["file"]]
        ly = e.get("layers", {})
        for k, v in ly.items():
            if isinstance(v, str):
                fs.append(v)
            elif isinstance(v, dict):
                fs += list(v.values())
        for f in fs:
            if f.startswith("res://") and not os.path.exists(os.path.join(ROOT, f.replace("res://", ""))):
                falta.append(f)
    return falta


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    check = "--check" in sys.argv
    path = args[0] if args else PATH
    meta = json.load(open(META, encoding="utf-8"))
    falta = arquivos(meta)
    for f in falta:
        print("FALTA o arquivo " + f)
    if falta and not check:
        raise SystemExit("não gravei: copie as folhas para assets/sprites/minigame/ antes")
    raw = open(path, "rb").read().decode("utf-8")
    m = json.loads(raw)
    novos, mudados, apagados = aplicar(m, meta)
    out = json.dumps(m, indent="\t", ensure_ascii=False).replace("\n", "\r\n") + "\r\n"
    igual = out == raw
    if not check and not igual:
        # lê de novo logo antes de gravar e aplica em cima do que estiver lá agora
        raw = open(path, "rb").read().decode("utf-8")
        m = json.loads(raw)
        novos, mudados, apagados = aplicar(m, meta)
        out = json.dumps(m, indent="\t", ensure_ascii=False).replace("\n", "\r\n") + "\r\n"
        igual = out == raw
        if not igual:
            open(path, "wb").write(out.encode("utf-8"))
    print("ronda elenco: %d sprites (%d novos, %d mudados, %d apagados); %s" % (
        len(meta["sprites"]), novos, mudados, apagados, "nada mudou" if igual else ("mudaria" if check else "gravado")))


if __name__ == "__main__":
    main()
