// Insere/atualiza SÓ as entradas dos adversários da academia (opp_gym_1, opp_gym_2) no manifest,
// por inserção de texto (não reescreve o resto do arquivo: o Diretor de Arte edita em paralelo).
// Uso: node manifest_gym.js <manifest.json> [--dry]
const fs = require('fs');
const path = process.argv[2];
const dry = process.argv.includes('--dry');
const ORIG = fs.readFileSync(path, "utf8");
let txt = ORIG;
const M = JSON.parse(txt);
const S = M.sprites;
const ACTS = ["idle", "jab", "heavy", "hit", "dodge", "block", "tired", "victory", "ko"];
const PLAYER_FPS = {idle: 6, jab: 14, heavy: 12, hit: 12, dodge: 14, block: 12, tired: 6, victory: 8, ko: 10};

const OPPS = {
  opp_gym_1: {
    scale: 1.04, speed: 0.83, name: "Tonhão do Tatame", profile: "RESISTENTE", color: "p1", frame: "ui_portrait_frame",
    desc: "Tonhão do Tatame (resistente, veterano da academia): largo e pesado, quimono velho amarelado de faixa roxa desbotada (ponta preta), descalço, orelha de couve-flor, barba curta, luvas azuis. Virado para a esquerda.",
  },
  opp_gym_2: {
    scale: 1.08, speed: 1.3, name: "Kid Navalha", profile: "RÁPIDO", color: "st2", frame: "ui_portrait_frame",
    desc: "Kid Navalha (rápido, campeão da academia): magro e comprido, braços longos, sem camisa, calção de cetim prateado com cós dourado, bota de boxe preta, luvas brancas, risco de navalha no cabelo e na sobrancelha. Virado para a esquerda.",
  },
};

// parte do texto de cada ação que vem depois da descrição do personagem (igual às dos outros adversários)
function actionTail(a) {
  const n = S["opp_tank_" + a].note;
  const i = n.indexOf("Virado para a esquerda.");
  return n.substring(i + "Virado para a esquerda.".length).trim();
}

const F = (v) => "__F" + (Number.isInteger(v) ? v.toFixed(1) : String(v)) + "__";
const r = (v) => Math.round(v) === 0 ? 0 : Math.round(v);   // sem -0

function spriteEntries(oid) {
  const o = OPPS[oid];
  const out = [];
  for (const a of ACTS) {
    const p = S["fight_player_" + a];
    const t = S["opp_tank_" + a];
    const fps = Math.round(PLAYER_FPS[a] * o.speed * 2) / 2;
    const hands = p.hands.map(h => ({
      hand_front: [r(-h.hand_front[0] * o.scale), r(h.hand_front[1] * o.scale)],
      hand_back: [r(-h.hand_back[0] * o.scale), r(h.hand_back[1] * o.scale)],
    }));
    const e = {
      file: `res://assets/sprites/opponents/${oid}/${oid}_${a}.png`,
      frame_size: [112, 104], frames: p.frames, fps: F(fps), pivot: [56, 98], loop: t.loop,
      facing: "esquerda", action: a, note: o.desc + " " + actionTail(a),
    };
    if (p.hit_point) {
      e.hit_frame = p.hit_frame;
      e.hit_point = [r(-p.hit_point[0] * o.scale), r(p.hit_point[1] * o.scale)];
      e.hit_point_note = t.hit_point_note;
    }
    if (t.hold_last !== undefined) e.hold_last = t.hold_last;
    e.hands = hands;
    out.push([`${oid}_${a}`, e]);
  }
  return out;
}

function portraitEntry(oid) {
  const e = JSON.parse(JSON.stringify(S.portrait_opp_tank));
  e.file = `res://assets/sprites/opponents/portrait_${oid}.png`;
  e.fps = F(0); e.note = S.portrait_opp_fast.note;
  return [`portrait_${oid}`, e];
}

function dataEntry(oid) {
  const o = OPPS[oid];
  const actions = {};
  for (const a of ACTS) actions[a] = `${oid}_${a}`;
  return [oid, {
    actions, portrait: `portrait_${oid}`, portrait_frame: o.frame, pos: [346, 318], facing: "esquerda",
    name_hint: o.name, profile: o.profile, color: o.color, scale: F(o.scale),
    _nota: "Mesmo quadro 112x104 e pivô (56,98) do jogador: trocar o adversário = trocar o prefixo do id. Academia (Fase 5).",
  }];
}

function ser(key, val, depth) {
  const ind = "\t".repeat(depth);
  let s = JSON.stringify(val, null, "\t").replace(/"__F([-0-9.]+)__"/g, "$1");
  s = s.split("\n").map((l, i) => i === 0 ? l : ind + l).join("\n");
  return `${ind}"${key}": ${s}`;
}

// remove um bloco "key": {...} no nível de indentação depth (idempotente)
function removeBlock(t, key, depth) {
  const ind = "\t".repeat(depth);
  const start = t.indexOf(`\n${ind}"${key}": {`);
  if (start < 0) return t;
  const end = t.indexOf(`\n${ind}}`, start + 1);
  let stop = end + 1 + ind.length + 1;
  if (t[stop] === ",") stop++;
  return t.substring(0, start) + t.substring(stop);
}

// insere blocos depois do bloco "after" (nível depth); o bloco "after" precisa terminar com vírgula (não é o último)
function insertAfter(t, after, depth, blocks) {
  const ind = "\t".repeat(depth);
  const start = t.indexOf(`\n${ind}"${after}": {`);
  if (start < 0) throw new Error("não achei " + after);
  const end = t.indexOf(`\n${ind}}`, start + 1);
  let stop = end + 1 + ind.length + 1;
  if (t[stop] !== ",") throw new Error(after + " é o último do objeto");
  stop++;
  return t.substring(0, stop) + "\n" + blocks.join(",\n") + "," + t.substring(stop);
}

for (const oid of Object.keys(OPPS)) {
  for (const a of ACTS) txt = removeBlock(txt, `${oid}_${a}`, 2);
  txt = removeBlock(txt, `portrait_${oid}`, 2);
}
// by_data_id fica no nível 2 também: tira só dentro dele
for (const oid of Object.keys(OPPS)) {
  const bi = txt.indexOf('\n\t"by_data_id": {');
  const pre = txt.substring(0, bi), post = txt.substring(bi);
  const be = post.indexOf("\n\t}");
  txt = pre + removeBlock(post.substring(0, be), oid, 2) + post.substring(be);
}

// by_data_id: depois de opp_tank (dentro de by_data_id)
{
  const bi = txt.indexOf('\n\t"by_data_id": {');
  const pre = txt.substring(0, bi), post = txt.substring(bi);
  const be = post.indexOf("\n\t}");
  const blocks = Object.keys(OPPS).map(o => { const [k, v] = dataEntry(o); return ser(k, v, 2); });
  txt = pre + insertAfter(post.substring(0, be), "opp_tank", 2, blocks) + post.substring(be);
}
// folhas: depois de opp_tank_ko; retratos: depois de portrait_opp_tank
{
  const blocks = [];
  for (const o of Object.keys(OPPS)) for (const [k, v] of spriteEntries(o)) blocks.push(ser(k, v, 2));
  txt = insertAfter(txt, "opp_tank_ko", 2, blocks);
  const pb = Object.keys(OPPS).map(o => { const [k, v] = portraitEntry(o); return ser(k, v, 2); });
  txt = insertAfter(txt, "portrait_opp_tank", 2, pb);
}

const chk = JSON.parse(txt);   // tem que continuar sendo JSON válido
for (const o of Object.keys(OPPS)) {
  if (!chk.by_data_id[o] || !chk.sprites[o + "_ko"] || !chk.sprites["portrait_" + o]) throw new Error("faltou " + o);
}
// nada além das minhas chaves mudou
const before = M, after = chk;
for (const top of Object.keys(before)) {
  if (JSON.stringify(before[top]) === JSON.stringify(after[top])) continue;
  const mine = (k) => /^(portrait_)?opp_gym_[12](_[a-z]+)?$/.test(k);
  const a = Object.keys(before[top]).filter(k => !mine(k)), b = Object.keys(after[top]).filter(k => !mine(k));
  if (JSON.stringify(a) !== JSON.stringify(b)) throw new Error("chaves alheias mudaram em " + top);
  for (const k of a) if (JSON.stringify(before[top][k]) !== JSON.stringify(after[top][k])) throw new Error("valor alheio mudou: " + top + "." + k);
}
if (dry) { console.log("dry ok", txt.length - fs.readFileSync(path, 'utf8').length, "bytes a mais"); }
else {
  // relê o arquivo agora: se alguém escreveu no meio, aborta (para não pisar no trabalho alheio)
  if (fs.readFileSync(path, 'utf8') !== ORIG) throw new Error("manifest mudou durante a edição; rode de novo");
  fs.writeFileSync(path, txt);
  console.log("manifest atualizado");
}
