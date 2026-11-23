# Fase 8a2 (Artista de Personagens): registra no manifest os ALUNOS DA RAÍZES (gerador center_students, só no centro):
# 4 folhas student_1..student_4 (48x72, 4 quadros, pivô 22,67, iguais à equipe de hoje) e by_data_id.center_students.people.
# Lê tools/art/fase8a2_personagens.json (gravado pelo make_sprites_fase8a2.gd) e só acrescenta/atualiza essas chaves.
# by_data_id.center_students: só "people" e "_nota_personagens" são do Artista; as outras chaves (icon etc., do Diretor de
# Arte/Programador) ficam como estão. Rodar de novo não muda nada (idempotente). Mantém o formato (tab, CRLF, UTF-8).
#   python tools/art/manifest_8a2_personagens.py            grava assets/sprites/manifest.json
#   python tools/art/manifest_8a2_personagens.py --check    só diz o que mudaria (não grava)
#   python tools/art/manifest_8a2_personagens.py <arquivo>  grava em outro manifest (cópia de teste)
# Detalhes: docs/arte/fase8a2-personagens-manifest.md.
import json
import os
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
PATH = os.path.join(ROOT, "assets", "sprites", "manifest.json")
META = os.path.join(ROOT, "tools", "art", "fase8a2_personagens.json")
IDS = ("student_1", "student_2", "student_3", "student_4")
GEN = " Gerador: tools/art/make_sprites_fase8a2.gd; registro: manifest_8a2_personagens.py."


def inteiro(v):
    """O Godot grava 48.0; o manifest usa 48. Números inteiros viram int, o resto fica como está."""
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
    S, B = m["sprites"], m["by_data_id"]
    novos = mudados = 0
    for sid, e in meta["sprites"].items():
        if sid not in IDS:
            raise SystemExit("id fora da fase 8a2: " + sid)
        e = inteiro(e)
        if not str(e.get("note", "")).endswith(GEN):
            e["note"] = str(e.get("note", "")) + GEN
        if sid not in S:
            novos += 1
        elif S[sid] != e:
            mudados += 1
        S[sid] = e
    src = meta["by_data_id"]["center_students"]
    cs = B.setdefault("center_students", {})
    cs["people"] = list(src["people"])
    cs["_nota_personagens"] = src["_nota"]
    for sid in IDS:
        arq = S[sid]["file"].replace("res://", "")
        if not os.path.exists(os.path.join(ROOT, arq)):
            print("AVISO: falta o arquivo " + arq)
    out = json.dumps(m, indent="\t", ensure_ascii=False).replace("\n", "\r\n") + "\r\n"
    igual = out == raw
    print("8a2 personagens: %d sprites (%d novos, %d mudados), by_data_id center_students.people; %s" % (
        len(meta["sprites"]), novos, mudados, "nada mudou" if igual else ("mudaria" if check else "gravado")))
    if not check and not igual:
        open(path, "wb").write(out.encode("utf-8"))


if __name__ == "__main__":
    main()
