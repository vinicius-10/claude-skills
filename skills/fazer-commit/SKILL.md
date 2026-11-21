---
name: fazer-commit
description: Use quando o usuário pedir para fazer commit, separar mudanças em vários commits ou digitar /fazer-commit. Examina o diff, separa as mudanças em commits lógicos, roda os testes do projeto quando há código, escreve mensagens Conventional Commits em português e executa git commit. NÃO usar para push, pull request, merge, rebase, amend ou para só sugerir uma mensagem sem commitar.
---

# Fazer commits (Conventional Commits, em português)

Adaptada de [github/awesome-copilot `git-commit`](https://github.com/github/awesome-copilot/blob/main/skills/git-commit/SKILL.md) (MIT).
Especificação: [Conventional Commits 1.0.0](https://www.conventionalcommits.org/pt-br/v1.0.0/).

**Antes de começar:** ler o `CLAUDE.md` do projeto. Se houver a seção **"Perfil para as skills"**,
usar `repositorio` (pasta do git, se não for a raiz), `escopos`, `comando_testes`,
`nunca_commitar` e `equipe` (modelo em `modelos/CLAUDE-perfil.md`). Sem perfil, inferir os
escopos dos nomes de pastas/módulos e do histórico (`git log`), e os testes pelo README.

Só faça commit quando o usuário pedir. Não faça push, não abra PR, não faça merge e não reescreva
histórico (`--amend`, `rebase`, `reset --hard`, `push --force`) sem pedido explícito.

## Formato

```text
<tipo>(<escopo>): <resumo>

<corpo>

<rodapé>
```

- **Tipo e escopo em inglês/identificador; resumo e corpo em português**, com acentos (salvo se o
  projeto usar outro idioma no histórico — siga o histórico).
- Resumo: minúscula, sem ponto final, até 72 caracteres na primeira linha. Descreva a mudança, não
  a tarefa: `divide o processamento em faixas entre workers`, `corrige extensão de sinal do LH`.
- Corpo (recomendado para código): o que mudou e por quê; números antes → depois quando houver
  (tempo, memória, área, *timing*); resultado dos testes. Linhas de ~72 caracteres; listas com `-`.
- Rodapé: `BREAKING CHANGE: <o que quebra>` quando a mudança exige alterar quem usa o código
  (interface, formato de arquivo/mensagem, parâmetros de CLI, mapa de memória); e a linha de
  coautoria pedida pelo sistema (`Co-Authored-By: ...`), se houver — útil também como registro de
  uso de IA em trabalhos acadêmicos.

## Tipos

| Tipo | Quando |
| :-- | :-- |
| `feat` | funcionalidade nova |
| `fix` | correção de bug |
| `perf` | melhora de desempenho/área/*timing* sem mudar o comportamento |
| `refactor` | reorganização sem mudar comportamento nem desempenho de propósito |
| `test` | só testes |
| `docs` | só documentação, comentários, relatórios |
| `build` | scripts de build/execução, dependências, configuração de ambiente |
| `chore` | manutenção: `.gitignore`, configuração de ferramentas, arquivos movidos |
| `style` | só formatação, sem mudar lógica |
| `revert` | reverte um commit (`revert: <resumo do original>`, corpo `Reverte <hash>.`) |

## Escopos

Use os `escopos` do perfil; sem perfil, o nome da área afetada (pasta, módulo, componente), sempre
o mesmo nome para a mesma coisa. Mudança que cruza áreas: escolha a principal.

## Como separar os commits

Um commit = uma mudança lógica que faz sentido sozinha e passa nos testes.

- **Juntos:** o código, os testes que o verificam e a documentação que ele obriga a atualizar.
- **Separados:** medições e resultados, documentação sem relação com a mudança, ajustes de scripts,
  correções cosméticas encontradas no caminho.
- Etapas diferentes no mesmo diff → um commit por etapa, na ordem em que foram feitas. Se o mesmo
  arquivo mistura duas etapas e não dá para separar por arquivo, pergunte se junta ou se separa
  montando a versão intermediária (`git hash-object -w` + `git update-index --cacheinfo`); nunca
  use `git add -p`/`-i` (interativos).
- **Mudanças que você não fez** (do usuário antes do pedido ou de outro integrante): liste e
  pergunte em qual commit entram, ou se ficam de fora.

## Nunca colocar no commit (sem pedido explícito)

- Itens de `nunca_commitar` do perfil.
- Saídas de build/execução, caches, ambientes virtuais (devem estar no `.gitignore`; se aparecerem, avise).
- Arquivos de configuração de IA quando o perfil disser que ficam fora do repositório.
- `.env`, credenciais, cookies, tokens, chaves: nunca. Liste e avise.
- Arquivos grandes gerados (dados brutos, binários) e arquivos não rastreados que você não criou:
  liste e pergunte.

## Fluxo

1. **Histórico e branch:** `git log --oneline -10` (manter o estilo) e `git branch --show-current`.
   Se estiver na branch principal de um repositório compartilhado, pergunte se deve criar uma
   branch antes. Primeiro commit de um repositório vazio pode ir direto na principal.
2. **Ver as mudanças:** `git status --short`, `git diff --stat`, `git diff` (e `--staged`). Sem
   mudanças → avise e pare; nunca commit vazio.
3. **Planejar os commits:** agrupar por mudança lógica; definir tipo, escopo e resumo de cada um.
4. **Testes (portão):** se algum commit inclui código, rode `comando_testes`. Falhou → não commite;
   mostre o erro e pergunte. Falha de ambiente (arquivo travado, porta ocupada, rede) → rode de
   novo antes de concluir que falhou. Commits só de docs/configuração não exigem testes.
5. **Stage e commit, um por vez:**
   ```bash
   git add -- caminho/arquivo1 caminho/arquivo2
   git diff --staged --name-only          # conferir: só os arquivos desta mudança
   git commit -q -F - <<'EOF'
   feat(escopo): resumo da mudança

   Corpo explicando o que e por quê.

   Co-Authored-By: ...
   EOF
   ```
   Em PowerShell, use `git commit -F <arquivo>` com o texto num arquivo temporário ou vários `-m`.
6. **Conferir:** `git log --oneline -<n>` e `git status --short` (o que sobrou deve ser só o que
   ficou de fora de propósito).
7. **Relatar:** lista dos commits (hash curto + primeira linha), o que ficou de fora e por quê, e
   que não houve push.

## Segurança

- Não altere a configuração do git (`git config`), nem nome/e-mail do autor.
- Não use `--no-verify`. Se um hook falhar, corrija, faça o stage de novo e repita o mesmo commit (sem `--amend`).
- Não use `--amend`, `rebase`, `reset --hard`, `push --force` nem `git history` sem pedido explícito.
