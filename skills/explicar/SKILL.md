---
name: explicar
description: Use quando o usuário digitar /explicar ou pedir para explicar, entender ou interpretar algo — "o que é X", "para que serve", "como funciona", "por que", "de onde vem", "não entendi", "vou explicar o que entendi, confere", "qual a diferença entre X e Y", "por que ficou mais lento", "o que significa esse erro/número/gráfico", "como explico isso na apresentação". Vale para código do projeto (valor, função, módulo, protocolo, script), conceitos de computação (SO, arquitetura, redes, concorrência, sistemas distribuídos, hardware, linguagens), comparações de abordagens, resultados de medição, mensagens de erro e decisões de projeto. Explica em profundidade técnica, com modo leigo quando a pessoa não entende e conferência do que ela entendeu. NÃO usar para pedidos de mudança de código, review com achados ou planejamento.
---

# Explicar com profundidade técnica

**Antes de começar:** se o `CLAUDE.md` do projeto tiver a seção **"Perfil para as skills"**, ler
os campos `publico`, `fontes_de_verdade` e `contexto_apresentacao` (modelo em
`modelos/CLAUDE-perfil.md` do repositório desta skill). Sem perfil, usar os padrões abaixo.

**Público padrão:** estudante ou profissional de Engenharia/Ciência da Computação. Domina
programação, estruturas de dados, arquitetura, SO, redes e sistemas digitais: não explicar o
básico disso. Ir direto ao **mecanismo** — o que acontece no código, no *runtime* (CPython, JVM,
Node...), no SO, no hardware e na rede — com números quando existirem.

Objetivo: deixar a pessoa **capaz de defender a decisão** (banca, professor, *code review*,
apresentação), não só de descrevê-la.

## 1. Calibrar a profundidade

| Situação | Como explicar |
|---|---|
| Assunto comum para engenharia (threads, sockets, cache, complexidade, TCP, condição de corrida, pipeline) | Direto ao detalhe técnico; zero introdução conceitual |
| Assunto de nicho (métrica específica de um artigo, *false sharing*, Nagle + *delayed ACK*, internals de uma biblioteca, API pouco usada, norma técnica) | Uma ou duas frases de enquadramento (o que é, onde se encaixa) e depois o mesmo nível técnico |
| O usuário não entendeu | Formato "Não entendi" (seção 7): explicação leiga → exemplo concreto → ponte de volta ao técnico. Não repetir o mesmo texto |
| Pergunta curta e fechada ("isso é bloqueante?") | Responder em 1–3 frases com o porquê; aprofundar só se houver armadilha relevante |

Na dúvida, prefira mais profundidade, organizada em camadas (seção 3) para quem lê poder parar
quando já entendeu.

## 2. Escolher o modo (ou combinar)

| A pergunta é sobre... | Modo |
|---|---|
| Um valor: variável, parâmetro, constante, campo de mensagem, sinal, flag, argumento de CLI, registrador, estado | **A — Valor** |
| Um bloco: função, classe, módulo, laço, processo/worker, protocolo, script, trecho selecionado | **B — Bloco** |
| Um conceito ou teoria (GIL, barreira, consistência, lei de Amdahl, memória virtual, *pipeline*) | **C — Conceito** |
| "X ou Y?", "qual a diferença", "por que não usaram Z" | **D — Comparação/decisão** |
| Algo observado: "por que ficou mais lento", "por que travou", "por que deu diferente" | **E — Comportamento/diagnóstico** |
| Um número, tabela, gráfico, *profile*, relatório de ferramenta ou mensagem de erro | **F — Interpretar evidência** |

Pergunta que mistura modos: responder em partes, cada uma com título, na ordem que faz sentido
(normalmente o "o que é" antes do "por que"). **Nada se encaixa?** Use o esqueleto genérico:
abertura → modelo mental → mecanismo → evidência → consequências e limites.

## 3. Camadas de profundidade (usar as que se aplicam, nessa ordem)

1. **O quê** — função, contrato, invariantes.
2. **Como, no código** — fluxo de dados e de controle, com trechos e links `[arquivo:linha](caminho#Lnn)`.
3. **Como, por baixo** — o que o *runtime*, o compilador, o SO, o hardware ou a rede fazem:
   escalonamento, troca de contexto, GIL, *spawn* × *fork*, serialização entre processos,
   memória compartilhada, *page faults*, localidade de cache, *false sharing*, chamadas de sistema,
   *buffers* de socket, Nagle, latência de *loopback* × rede, núcleos heterogêneos (P/E), SMT.
4. **Custo e limites** — complexidade, ordem de grandeza (ns/µs/ms, bytes, ciclos), o que escala e
   o que não escala, gargalo dominante.
5. **Por que é assim** — decisão de projeto, alternativas descartadas e o motivo, o que mudou em
   relação à versão anterior.
6. **Armadilhas e contrafactuais** — "e se fosse diferente?": o que quebraria (condição de corrida,
   *deadlock*, resultado divergente, perda de desempenho) e casos de borda.

Quando o assunto tem nome na literatura (decomposição de domínio, sincronização em barreira,
modelo de falhas, *write-back* × *write-through*...), dizer o nome e onde aprofundar — é o que
banca e professores perguntam.

## 4. Regras de rigor

- **Ler antes de explicar:** o código envolvido (definição, onde é criado e usado, testes) e as
  fontes de verdade do perfil. O código do projeto é a fonte da verdade; não explicar de memória.
- **Evidência barata vale mais que afirmação:** quando der para mostrar em segundos, mostre —
  rodar um trecho curto, medir o tempo, ver o *bytecode*/assembly gerado, medir o tamanho de uma
  mensagem serializada, simular uma entrada pequena antes/depois. Diga o que foi rodado.
- **Afirmação não óbvia sobre linguagem/SO/rede/hardware:** citar a fonte (documentação oficial,
  especificação, livro, artigo) ou dizer que é comportamento observado. Sem certeza, dizer isso e
  como verificar.
- **Números com unidade e contexto** (máquina, tamanho da entrada, repetições). Nada de "muito mais rápido".
- **Precisão de termos:** processo ≠ *thread*; concorrência ≠ paralelismo; latência ≠ vazão;
  cópia de *buffer* ≠ sincronização; síncrono ≠ bloqueante. Se o usuário usar um termo impreciso, corrigir.

## 5. Formato por modo

Toda resposta começa com **um parágrafo de abertura de 1 a 3 frases**, técnico e direto, com a
função geral e o mecanismo central. Sem título antes, sem "vou explicar". Ex.:

> `atualiza` faz uma atualização síncrona (*double buffering*): lê só o estado t e escreve num
> *buffer* novo, então nenhum elemento enxerga um vizinho já atualizado — por isso o laço pode ser
> dividido entre *workers* sem *lock*.

### A — Valor
1. **Tabela-resumo** valor → efeito (combinações com outros valores; impossíveis marcadas com motivo).
2. **O que é:** tipo, representação em memória/no fio/em hardware (largura, *endianness*), faixa
   válida, invariantes.
3. **Onde é usado:** tabela arquivo/linha → o que faz com ele. Sem consumidor = achado (reportar, não corrigir).
4. **De onde vem:** caminho em uma linha, incluindo saltos entre módulos, processos ou rede
   (`--limiar ──► main ──[INIT]──► worker.limiar`) e como é calculado.
5. **Exemplo concreto** com caso de borda.
6. **Por que existe** e restrições.

### B — Bloco
1. **Tabela de interface:** direção (entrada/saída/estado), nome, tipo, origem/destino, significado.
   Em código concorrente, incluir estado compartilhado e primitivas (fila, *lock*, barreira, socket).
2. **Tabela de comportamento:** situação → efeito; em código concorrente ou com *clock*, separar o
   que ocorre **dentro de um passo** do que ocorre **na sincronização entre passos**.
3. **Como funciona:** passo a passo do fluxo; em concorrência, **quem espera quem**, onde está a
   ordem de memória/visibilidade e **por que não há condição de corrida nem *deadlock***.
   Diagrama em texto quando ajudar:
   ```
   passo t:  [W0: 0-249] [W1: 250-499] [W2: 500-749] [W3: 750-999]
             W0 ⇄ W1: bordas 249/250   W1 ⇄ W2: 499/500   W2 ⇄ W3: 749/750
   barreira → troca de buffers → passo t+1
   ```
4. **Camadas 3–4** (por baixo e custo) para o bloco.
5. **Exemplo concreto** (entrada pequena, mensagens reais) com caso de borda; teste que cobre.
6. **Por que é assim** e contrafactuais.

### C — Conceito
1. **Definição precisa** (formal quando houver: equação, invariante, propriedade).
2. **Mecanismo** — como funciona de verdade, não a metáfora.
3. **Onde aparece neste projeto** (arquivo/linha) ou, se não aparece, onde apareceria.
4. **Consequências práticas** e números típicos.
5. **Limites e equívocos comuns** (ex.: "o GIL impede concorrência" — não; impede execução paralela
   de *bytecode* em CPython; I/O e extensões em C o liberam).
6. **Referência** para aprofundar (seção do livro, documentação, artigo).

### D — Comparação/decisão
1. **Veredito em uma frase** para o contexto deste projeto (não em geral).
2. **Tabela de critérios:** desempenho (com o mecanismo que explica), complexidade de
   implementação, correção/determinismo, comunicação, portabilidade, adequação aos requisitos,
   risco de prazo.
3. **Quando a outra opção venceria** (tamanho do problema, plataforma, carga, rede).
4. **Como verificar empiricamente** (qual medição faria a diferença aparecer).

### E — Comportamento/diagnóstico
1. **Hipóteses** ordenadas por probabilidade, cada uma com o mecanismo que produziria o sintoma.
2. **Evidência** que confirma ou descarta cada uma (o que olhar, o que medir, o que rodar).
3. **Conclusão** com o grau de certeza; se não der para concluir sem rodar algo, diga o quê.
4. Não corrigir código aqui: se a causa for bug, descrever e sugerir o próximo passo.

### F — Interpretar evidência
1. **O que o dado diz** literalmente (eixos, unidades, condição de medição).
2. **O que ele implica** (ex.: eficiência caindo depois de N *workers* → núcleos mais lentos ou SMT
   entrando; fração serial crescendo com p → *overhead* de sincronização, não parte serial).
3. **O que ele não diz** e que medição faltaria para afirmar.
4. Mensagem de erro: significado exato, camada que a gerou (linguagem, biblioteca, SO, rede,
   ferramenta), causa típica e como confirmar.

## 6. "Como eu explico isso na apresentação/defesa"

Depois da explicação, acrescentar:
- **Roteiro de fala** de 45–90 s: 4–6 frases em linguagem falada (o que é → como funciona → por que
  assim → número que comprova), com o arquivo/trecho a mostrar na tela.
- **3 perguntas prováveis** de quem avalia, cada uma com resposta curta e técnica (pelo menos uma do
  tipo "e se..." e uma sobre o ponto mais delicado: sincronização, consistência, *timing*, limite).

## 7. Interação

- **"Não entendi" (ou sinais disso: a mesma pergunta de novo, resumo errado, "como assim?"):**
  responder nesta ordem, sem repetir o texto anterior:
  1. **Explicação leiga** — 1 a 2 parágrafos em linguagem do dia a dia, sem jargão (ou com cada
     termo técnico traduzido na hora), focada na **intuição**: qual problema a coisa resolve e a
     ideia central de como resolve. Analogia permitida aqui, dizendo onde ela deixa de valer.
  2. **Exemplo concreto** — passo a passo com valores reais e pequenos (entrada 5×5, 2 processos,
     uma mensagem de verdade, números redondos), mostrando o que acontece em cada passo.
  3. **Ponte de volta** — 2 a 4 frases ligando a intuição e o exemplo aos termos técnicos e ao
     trecho do código, para a pessoa conseguir repetir a explicação no nível técnico.
  Se ainda assim não entender, **não explicar tudo de novo**: oferecer, numa pergunta curta,
  (a) dizer qual parte específica travou, ou (b) **explicar de volta** (item seguinte).
- **Explicar de volta** (a pessoa conta, com as palavras dela, o que entendeu — a qualquer momento;
  também serve para treinar a fala da apresentação):
  1. **Veredito em uma linha:** "Isso mesmo", "Quase isso. Faltam N ajustes:" ou "Tem um ponto
     central errado:".
  2. **Conferência ponto a ponto:** quebrar a fala nas afirmações feitas e classificar cada uma numa
     tabela — ✅ correto · ⚠️ incompleto (o que falta) · ❌ errado (o que é na verdade) ·
     🔤 termo trocado. Conferir contra o código e as fontes, não contra a explicação anterior.
  3. **Causa raiz:** se houver erro, dizer qual ideia errada está gerando os outros.
  4. **Corrigir só o que falhou:** para cada ⚠️/❌, a frase certa em **negrito** e, se for o ponto
     central, uma mini-explicação leiga + exemplo só daquela parte. Não reexplicar o que estava certo.
  5. **O que ficou de fora:** pontos importantes não mencionados que provavelmente seriam perguntados.
  6. **Pergunta de checagem** sobre o ponto corrigido (de preferência um "e se..."); avaliar a
     resposta da mesma forma.
- **Analogias** fora do caso "não entendi" só quando pedirem.
- Sem meta-texto ("vou explicar", "em resumo") e sem oferecer ajuda no final.
- Tamanho proporcional à pergunta: profundidade não é prolixidade — cada parágrafo traz informação nova.
