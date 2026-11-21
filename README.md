# claude-skills

Skills para o [Claude Code](https://docs.claude.com/en/docs/claude-code) voltadas a trabalhos de
engenharia/computação e trabalhos acadêmicos brasileiros (com suporte a ABNT, LaTeX e Overleaf).
Escritas em português.

| Skill | Para quê |
|---|---|
| [`explicar`](skills/explicar/SKILL.md) | Explica código, conceitos, comparações, diagnósticos, números e erros com profundidade técnica, em camadas (código → *runtime*/SO/hardware → custo → decisão → armadilhas). Tem modo leigo + exemplo quando a pessoa não entende, modo "explicar de volta" (confere o que a pessoa entendeu ponto a ponto) e roteiro de fala para apresentação/defesa. |
| [`planejar-tarefa`](skills/planejar-tarefa/SKILL.md) | Antes de tarefas grandes: levanta dúvidas com opções, escreve um plano (decisões, interfaces, sincronização, verificação, riscos) e só executa depois de aprovado, com teste primeiro. |
| [`fazer-commit`](skills/fazer-commit/SKILL.md) | Separa o diff em commits lógicos, roda os testes antes de commitar código e escreve mensagens Conventional Commits em português. Nunca faz push/rebase/amend sem pedido. |
| [`medir-desempenho`](skills/medir-desempenho/SKILL.md) | Metodologia de benchmark: validade antes de tempo, decomposição de tempos, repetições e mediana, captura automática do hardware (Windows/macOS/Linux), CSV padrão, speedup, eficiência, Karp–Flatt, gráficos. |
| [`escrever-documento-latex`](skills/escrever-documento-latex/SKILL.md) | Escreve e revisa TCC/relatório/artigo em LaTeX (local ou Overleaf) sem trocar a voz do autor: o que pode ser editado, fontes de verdade, estilo impessoal, padrões de figura/tabela/sigla/citação, compilação e cópia versionada no git. |
| [`otimizar-timing-fpga`](skills/otimizar-timing-fpga/SKILL.md) | Fechar *timing* e reduzir área em FPGA (Vivado, 7-series/UltraScale): fluxo *non-project* reprodutível, leitura do caminho crítico por primitiva, alavancas da menos para a mais invasiva, ruído de *placement* e relato antes → depois. |
| [`abnt-academico`](skills/abnt-academico/SKILL.md) | Normalização ABNT (NBR 14724:2024, 10520:2023, 6023, 6028...) e APA 7, com perfil para a **UTFPR** (referências pela NBR 6023:2018 e convenções do template LaTeX `utfpr.cls`). Baseada no projeto de Carlos Alberto Ferreira (MIT). |

Ferramentas (PowerShell, Windows):

- [`ferramentas/importar-overleaf.ps1`](ferramentas/importar-overleaf.ps1) — espelha um projeto do
  Overleaf (zip do código-fonte) numa pasta local para versionar no git. Baixa direto com a sessão
  do [overleaf-mcp-rt](https://github.com/DanielHou315/overleaf-mcp-rt) (sem expor o cookie) ou usa
  um zip baixado à mão, com travas para não apagar nada fora da cópia.
- [`ferramentas/compilar-latex.ps1`](ferramentas/compilar-latex.ps1) — compila um documento LaTeX
  numa pasta de build separada (pdflatex → bibtex/biber → glossários/índices → pdflatex ×2,
  `-shell-escape` automático para `minted`) e resume erros, referências indefinidas, avisos da
  bibliografia e *overfull hbox*. Aceita um TeX Live específico (`-TexBin`).

## Instalação

Copie as pastas de `skills/` que quiser para:

- `~/.claude/skills/` — vale para todos os seus projetos; ou
- `<projeto>/.claude/skills/` — só para aquele projeto (pode ficar fora do repositório do grupo se
  você rodar o Claude Code numa pasta acima dele).

```powershell
git clone https://github.com/vinicius-10/claude-skills.git
Copy-Item -Recurse .\claude-skills\skills\* "$env:USERPROFILE\.claude\skills\"
```

```bash
git clone https://github.com/vinicius-10/claude-skills.git
cp -r claude-skills/skills/* ~/.claude/skills/
```

As skills aparecem a partir da próxima sessão do Claude Code.

## Configuração por projeto

As skills são genéricas e leem os detalhes de cada projeto (comando de testes, escopos de commit,
fontes de verdade, onde está o documento LaTeX, o que pode ser editado, restrições do enunciado)
de uma seção **"Perfil para as skills"** no `CLAUDE.md` do projeto. Modelo:
[`modelos/CLAUDE-perfil.md`](modelos/CLAUDE-perfil.md). Sem o perfil, cada skill usa padrões
razoáveis ou pergunta.

## Requisitos opcionais

- **Overleaf:** MCP [`overleaf-mcp-rt`](https://github.com/DanielHou315/overleaf-mcp-rt) (Node 20+)
  para `escrever-documento-latex` e `abnt-academico` editarem e compilarem no Overleaf.
- **PowerShell** (Windows) para `importar-overleaf.ps1` e para a captura de hardware no Windows.

## Créditos e licença

- Licença **MIT** (ver [`LICENSE`](LICENSE)): use, modifique e redistribua livremente.
- `skills/abnt-academico/` deriva de
  [carlosafjr-dev/abnt-academico-skill](https://github.com/carlosafjr-dev/abnt-academico-skill)
  (MIT, © Carlos Alberto Ferreira, Agência Ojuobá); a licença original está em
  [`skills/abnt-academico/LICENSE`](skills/abnt-academico/LICENSE) e as alterações em
  [`ORIGEM.md`](skills/abnt-academico/ORIGEM.md).
- `skills/fazer-commit/` adapta
  [github/awesome-copilot `git-commit`](https://github.com/github/awesome-copilot/blob/main/skills/git-commit/SKILL.md) (MIT).
- As regras de normas ABNT vêm de guias de bibliotecas universitárias, não do texto oficial das
  normas (que é pago). Em caso de dúvida, confira a norma oficial ou a biblioteca da sua instituição.
- Escrito com auxílio do Claude (Anthropic).
