# Fase 8a1 (Artista de Personagens): registra no manifest os 4 adversários da liga regional (Zé Bigorna, Tião Estaca,
# Rony Sabão e James Blindado): folhas de luta, poses de assinatura, retratos e as entradas by_data_id.
# Lê tools/art/fase8a1_personagens.json (gravado pelo make_sprites_elenco.gd, modo "regional") e só acrescenta/atualiza
# as chaves desses 4 ids. Rodar de novo não muda nada (idempotente). Mantém o formato do arquivo (tab, CRLF, UTF-8).
#   python tools/art/manifest_8a1_personagens.py            grava assets/sprites/manifest.json
#   python tools/art/manifest_8a1_personagens.py --check    só diz o que mudaria (não grava)
#   python tools/art/manifest_8a1_personagens.py <arquivo>  grava em outro manifest (cópia de teste)
# Detalhes e nomes das ações: docs/arte/fase8a1-personagens-manifest.md.
import json
import os
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
PATH = os.path.join(ROOT, "assets", "sprites", "manifest.json")
META = os.path.join(ROOT, "tools", "art", "fase8a1_personagens.json")
IDS = ("opp_reg_1", "opp_reg_2", "opp_reg_3", "opp_james")
GEN = " Gerador: tools/art/make_sprites_elenco.gd (modo regional) + poses_8a1.py; registro: manifest_8a1_personagens.py."


def inteiro(v):
    """O Godot grava 112.0; o manifest usa 112. Números inteiros viram int, o resto fica como está."""
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
        if not any(sid == "portrait_" + i or sid.startswith(i + "_") or sid == "portrait_opp_james_dialog" for i in IDS):
            raise SystemExit("id fora da fase 8a1: " + sid)
        e = inteiro(e)
        if not str(e.get("note", "")).endswith(GEN):
            e["note"] = str(e.get("note", "")) + GEN
        if sid not in S:
            novos += 1
        elif S[sid] != e:
            mudados += 1
        S[sid] = e
    for oid in IDS:
        B[oid] = inteiro(meta["by_data_id"][oid])
    out = json.dumps(m, indent="\t", ensure_ascii=False).replace("\n", "\r\n") + "\r\n"
    igual = out == raw
    print("8a1 personagens: %d sprites (%d novos, %d mudados), by_data_id %s; %s" % (
        len(meta["sprites"]), novos, mudados, ", ".join(IDS), "nada mudou" if igual else ("mudaria" if check else "gravado")))
    if not check and not igual:
        open(path, "wb").write(out.encode("utf-8"))


if __name__ == "__main__":
    main()
