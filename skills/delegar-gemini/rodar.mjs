#!/usr/bin/env node
// Roda o Antigravity CLI (agy) em modo somente leitura e devolve um resumo curto em JSON.
// Uso: node rodar.mjs --pedido "..." [--saida arq.md] [--conversa ID] [--dir PASTA]... [--cwd PASTA] [--modelo NOME] [--timeout SEG]
import { spawnSync } from "node:child_process";
import { writeFileSync, existsSync } from "node:fs";
import { join } from "node:path";

const args = process.argv.slice(2);
const opt = { dir: [] };
for (let i = 0; i < args.length; i++) {
  const k = args[i].replace(/^--/, "");
  const v = args[++i];
  if (k === "dir") opt.dir.push(v); else opt[k] = v;
}
if (!opt.pedido) { console.error("faltou --pedido"); process.exit(2); }

const PROTOCOLO = `
Regras desta tarefa (obrigatórias):
- Use apenas a ferramenta de leitura de arquivos. Não execute comandos de terminal e não crie nem edite arquivos.
- Se precisar de um comando de terminal (listar pastas, buscar texto, git, rodar algo), não tente executá-lo: termine a resposta com um bloco exatamente neste formato e pare:
COMANDOS_PROPOSTOS
1. \`comando exato em PowerShell\` | motivo curto | leitura ou altera
- Responda em português do Brasil.`;

const agy = existsSync(join(process.env.LOCALAPPDATA || "", "agy", "bin", "agy.exe"))
  ? join(process.env.LOCALAPPDATA, "agy", "bin", "agy.exe") : "agy";
const timeout = Number(opt.timeout || 420);
const cli = ["-p", opt.pedido + "\n" + PROTOCOLO, "--mode", "plan",
  "--model", opt.modelo || "gemini-3.8-flash-medium",
  "--print-timeout", `${timeout}s`, "--output-format", "json"];
if (opt.conversa) cli.push("--conversation", opt.conversa);
for (const d of opt.dir) cli.push("--add-dir", d);

const r = spawnSync(agy, cli, { cwd: opt.cwd || process.cwd(), encoding: "utf8", maxBuffer: 64 * 1024 * 1024, timeout: (timeout + 30) * 1000 });
let j;
try { j = JSON.parse(r.stdout); } catch {
  console.log(JSON.stringify({ status: "ERRO", erro: (r.stderr || r.stdout || String(r.error)).slice(-600) }, null, 1));
  process.exit(1);
}

let resposta = j.response || "";
let comandos = null;
const m = resposta.match(/\n?COMANDOS_PROPOSTOS\s*\n([\s\S]*)$/);
if (m) { comandos = m[1].trim(); resposta = resposta.slice(0, m.index).trimEnd(); }

const out = { status: j.status, conversa: j.conversation_id, segundos: Math.round(j.duration_seconds || 0) };
if (opt.saida) {
  writeFileSync(opt.saida, resposta + "\n", "utf8");
  out.saida = opt.saida;
  out.linhas = resposta.split("\n").length;
} else {
  out.resposta = resposta;
}
if (comandos) out.comandos_propostos = comandos;
console.log(JSON.stringify(out, null, 1));
