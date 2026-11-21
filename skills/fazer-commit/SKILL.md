---
name: fazer-commit
description: Use quando o usuário pedir para fazer commit, separar mudanças em vários commits, sincronizar com o remoto (pull/push), resolver conflitos de merge ou digitar /fazer-commit. Examina o diff, separa as mudanças em commits lógicos, roda os testes do projeto quando há código, escreve mensagens Conventional Commits em português, integra o trabalho de outras pessoas, resolve conflitos entendendo os dois lados (base, nosso, deles) e sempre envia para o remoto ao final. NÃO usar para pull request, rebase, amend, force push ou para só sugerir uma mensagem sem commitar.
---

# Fazer commits (Conventional Commits, em português)

Adaptada de [github/awesome-copilot `git-commit`](https://github.com/github/awesome-copilot/blob/main/skills/git-commit/SKILL.md) (MIT).
Especificação: [Conventional Commits 1.0.0](https://www.conventionalcommits.org/pt-br/v1.0.0/).

**Antes de começar:** ler o `CLAUDE.md` do projeto. Se houver a seção **"Perfil para as skills"**,
usar `repositorio` (pasta do git, se não for a raiz), `escopos`, `comando_testes`,
`nunca_commitar` e `equipe` (modelo em `modelos/CLAUDE-perfil.md`). Sem perfil, inferir os
escopos dos nomes de pastas/módulos e do histórico (`git log`), e os testes pelo README.

Só faça commit quando o usuário pedir. **Depois de commitar, sempre envie para o remoto** (push):
nada fica só local, para não perder trabalho nem divergir do grupo. Se a branch estiver atrás do
`origin`, integre antes (seção "Sincronizar") e então envie. Repositório sem remote: avise e
ofereça criar um (ex.: `gh repo create`). Para desligar o envio automático num projeto, o perfil
pode dizer `enviar_automatico: não`. Não abra PR e não reescreva histórico (`--amend`, `rebase`,
`reset --hard`, `push --force`) sem pedido explícito — em repositório compartilhado isso apaga
trabalho de outra pessoa.

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

1. **Histórico, branch e remoto:** `git log --oneline -10` (manter o estilo),
   `git branch --show-current` e, se houver remote, `git fetch` + `git status -sb` para saber se a
   branch está atrás/à frente. Se estiver atrás, avise (o push vai pedir integração; ver
   "Sincronizar"). Na branch principal de um repositório compartilhado, pergunte se deve criar uma
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
7. **Enviar (sempre):** `git push origin <branch>` (branch nova: `push -u origin <branch>`).
   Recusado porque o `origin` andou → integrar (seção "Sincronizar", com resolução de conflitos se
   houver) e enviar de novo; **nunca** `--force`. Conferir com `git status -sb` que não ficou nada
   à frente do `origin`. Falha de rede/autenticação → avisar o usuário com o erro; não deixar
   parecer que foi enviado.
8. **Relatar:** lista dos commits (hash curto + primeira linha), o que ficou de fora e por quê, e
   a confirmação do envio (branch e remoto).

## Sincronizar com o remoto (antes do envio, ou quando o usuário pedir pull)

1. **Antes de integrar:** working tree limpa (commite ou pergunte o que fazer com o pendente; não
   use `git stash` sem avisar). `git fetch` e veja o que chegou:
   `git log --oneline HEAD..origin/<branch>` (dos outros) e `git log --oneline origin/<branch>..HEAD`
   (seus). Resuma ao usuário quem mudou o quê.
2. **Integrar com merge** (padrão: preserva o histórico de todos):
   `git pull --no-rebase --no-edit origin <branch>`. Rebase só se o usuário pedir.
3. Sem conflito → rode `comando_testes` se entrou código.
4. Com conflito → seção "Resolver conflitos".
5. **Push** (`git push origin <branch>`) logo em seguida, como no passo 7 do Fluxo. Recusado por
   estar atrás → integrar de novo; **nunca** `--force`.

## Resolver conflitos

Objetivo: preservar a intenção dos dois lados. Conflito não se resolve escolhendo um lado "no
escuro": é o trabalho de outra pessoa que pode sumir.

1. **Mapear:** `git status` e `git diff --name-only --diff-filter=U`. Para cada arquivo, entender os
   dois lados antes de editar:
   - `git log --merge --format='%h %an: %s' -- <arquivo>`: commits de cada lado, autor e motivo;
   - `git show :1:<arquivo>` (base comum), `:2:` (nosso), `:3:` (deles);
   - o código em volta (quem chama, testes que cobrem).
2. **Classificar e decidir cada trecho:**

   | Situação | O que fazer |
   |---|---|
   | Mudanças independentes que só ficaram próximas | Manter as duas |
   | Mesma correção feita dos dois lados | Manter uma; conferir se são equivalentes |
   | Um lado refatorou/renomeou e o outro alterou o código antigo | Reaplicar a alteração dentro da versão refatorada |
   | Decisões diferentes (parâmetro, interface, algoritmo, formato de dados) | **Perguntar ao usuário**, mostrando as duas versões, autores e impacto |
   | Arquivo gerado por ferramenta (espelho de Overleaf, `package-lock`, build, resultados) | Não mesclar à mão: regenerar pela ferramenta (ex.: `importar-overleaf.ps1`, `npm install`, script de experimento) |
   | Binário (imagem, PDF) | Perguntar qual versão fica |
   | Apagado de um lado e alterado do outro | Perguntar (pode ter sido movido: `git log --follow`) |

3. **Editar** removendo os marcadores (`<<<<<<<`, `=======`, `>>>>>>>`) e deixando o resultado
   coerente (imports, nomes, chamadas). Conferir `git diff --check` e
   `grep -rn '^<<<<<<<\|^>>>>>>>' -- <arquivos>` (nada pode sobrar).
4. **Validar:** `comando_testes` (e compilar, se for documento/código compilado). Falhou →
   corrigir ou perguntar antes de concluir.
5. **Concluir:** `git add -- <arquivos>` e `git commit -F` com
   `merge: integra origin/<branch> (conflitos em <arquivos>)` e, no corpo, uma linha por arquivo
   com o que foi mantido de cada lado e por quê, o resultado dos testes e a linha de coautoria.
6. **Relatar:** arquivos, decisão em cada um, o que foi perguntado, testes. Se algo de outra
   pessoa foi descartado (com aprovação), dizer explicitamente para ela ser avisada.
7. **Desistir é seguro:** `git merge --abort` volta ao estado anterior sem perder nada.

**Prevenção** (sugerir quando fizer sentido): fetch/pull antes de começar; commits pequenos e
frequentes; uma branch por frente de trabalho; combinar quem mexe nos arquivos compartilhados.

## Segurança

- Não altere a configuração do git (`git config`), nem nome/e-mail do autor.
- Não use `--no-verify`. Se um hook falhar, corrija, faça o stage de novo e repita o mesmo commit (sem `--amend`).
- Não use `--amend`, `rebase`, `reset --hard`, `push --force` nem `git history` sem pedido explícito.
- Não resolva conflito com `-X ours`/`-X theirs` nem `git checkout --ours/--theirs` no arquivo
  inteiro sem ter lido os dois lados e sem o usuário concordar.
- `git merge --abort` é sempre permitido para desfazer uma integração em andamento.
