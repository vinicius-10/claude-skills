# Modelo: seção "Perfil para as skills" do CLAUDE.md

Copie a seção abaixo para o `CLAUDE.md` do projeto e preencha. As skills deste repositório leem
esses campos; o que ficar em branco usa o padrão de cada skill. Apague as linhas que não se aplicam.

```markdown
## Perfil para as skills

- **publico** (explicar): Engenharia de Computação; aprofundar no técnico, sem explicar o básico.
- **contexto_apresentacao** (explicar): ex.: "todos explicam partes do código num vídeo de 10–15 min".
- **repositorio** (fazer-commit): pasta do git, se não for a raiz (ex.: `projeto/`).
- **escopos** (fazer-commit): ex.: `api`, `web`, `banco`, `testes`, `docs`, `relatorio`.
- **comando_testes** (fazer-commit, planejar-tarefa, medir-desempenho): ex.: `python -m pytest -q`.
- **nunca_commitar** (fazer-commit): ex.: `.claude/`, `CLAUDE.md`, `build/`, `*.xpr`, dados brutos.
- **equipe** (fazer-commit, planejar-tarefa): integrantes e quem cuida de quê; repositório compartilhado?
- **pasta_planos** (planejar-tarefa): ex.: `docs/planos/` (ou fora do repositório, se o grupo não quer material de IA no git).
- **restricoes** (todas): requisitos que não podem ser violados (enunciado, cliente, bibliotecas proibidas, prazo).
- **fontes_de_verdade** (explicar, planejar-tarefa, escrever-documento-latex), em ordem:
  1. código em `src/`
  2. resultados em `experimentos/resultados/`
  3. documentação técnica em `docs/`
  4. enunciado/requisitos em `ENUNCIADO.md`
- **armadilhas** (escrever-documento-latex, explicar): fatos do projeto que costumam sair errados no texto.
- **pasta_experimentos** (medir-desempenho): ex.: `experimentos/`.
- **maquina** (medir-desempenho): CPU (núcleos físicos/lógicos, P/E), RAM, SO — ou "capturar na hora".

### documento (escrever-documento-latex, abnt-academico)
- **onde**: pasta local `tcc/` | Overleaf `https://<host>/project/<id>` (via MCP overleaf-mcp-rt).
- **arquivo_principal**: `main.tex`.
- **editaveis**: `capitulos/*.tex` (os demais só por sugestão).
- **com_permissao**: `\include` do `main.tex`, novas entradas no `.bib`, novas siglas.
- **instituicao_norma**: ex.: UTFPR (ABNT; referências pela NBR 6023:2018) → perfil `utfpr.md` da skill abnt-academico.
- **estilo**: impessoal; termos estrangeiros em itálico: *thread*, *socket*, *pipeline*...
- **marcador_pendencia**: `\todo{...}` ou `\textcolor{red}{[PENDENTE: ...]}`.
- **comando_compilacao**: local `latexmk -pdf main.tex` | Overleaf `overleaf_compile`.
- **avisos_conhecidos**: avisos do template que podem ser ignorados.
- **mapa_requisitos**: requisito do enunciado/orientador → seção do documento.
- **espelho_git**: ex.: `docs/relatorio/` atualizado com `importar-overleaf.ps1 -Baixar -ProjetoId <id> -Destino docs/relatorio`.
```
