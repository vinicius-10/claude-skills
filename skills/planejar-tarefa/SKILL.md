---
name: planejar-tarefa
description: Use quando o usuário digitar /planejar-tarefa ou pedir para planejar, e também ANTES de começar tarefas complexas — módulo ou componente novo, mudança de interface entre módulos, protocolo de comunicação, concorrência/sincronização, mudança de formato de dados, nova funcionalidade que atravessa camadas, mudança de arquitetura, ou qualquer tarefa que toque 3+ arquivos de código. Levanta dúvidas com opções, escreve um plano com decisões, interfaces, verificação e riscos, e só executa depois de aprovado. NÃO usar para mudanças pequenas e claras (renomear, corrigir comentário, ajustar um teste, perguntas).
---

# Planejar antes de executar

Objetivo: chegar a um plano **aprovado pelo usuário**, sem dúvidas pendentes, antes de editar
qualquer arquivo. Planejar é barato; refazer código, testes, documentação e experimentos é caro.

**Antes de começar:** ler o `CLAUDE.md` do projeto. Se houver a seção **"Perfil para as skills"**,
usar `fontes_de_verdade`, `comando_testes`, `pasta_planos`, `restricoes` e `equipe`
(modelo em `modelos/CLAUDE-perfil.md`). Sem perfil: planos em `docs/planos/` e testes pelo README.

Regras gerais:
- **Não edite arquivos do projeto até o plano ser aprovado.** Ler código, rodar testes e
  experimentos curtos e consultar documentação é permitido (e necessário).
- O código é a fonte da verdade; não planeje de memória.
- Respeite as regras do `CLAUDE.md` e as `restricoes` do perfil (enunciado, requisitos do cliente,
  convenções de código, o que não pode ser editado).
- Em trabalho em equipe, o plano diz **quem faz o quê**.

## Passo 1 — Entender o pedido e o estado atual

1. Reescreva o objetivo em 1–2 frases e o **critério de pronto** (o que precisa funcionar e como
   será verificado: teste, comparação com uma referência, medição).
2. Leia os arquivos envolvidos e os testes que os cobrem.
3. Rode os testes existentes para saber o ponto de partida. Se algo já falha, avise antes de continuar.

## Passo 2 — Levantar dúvidas

Liste tudo que o pedido e o código não definem. Para cada dúvida, 2–4 opções com a recomendada
primeiro e o impacto de cada uma (desempenho, complexidade, correção, risco de prazo). Use a
ferramenta de perguntas (até 4 por rodada; agrupe as relacionadas). Categorias que costumam render
dúvidas:

- **Comportamento em bordas:** entrada inválida, vazio, limite, *overflow*, falha no meio da operação.
- **Interfaces:** formato de dados, nomes, compatibilidade com o que já usa o código atual.
- **Concorrência/distribuição:** mecanismo (threads, processos, assíncrono), divisão do trabalho,
  sincronização, quem detecta o fim, falhas parciais, determinismo do resultado.
- **Comunicação:** formato de mensagem, serialização, topologia, o que trafega a cada passo.
- **Desempenho × simplicidade:** onde vale otimizar agora e onde não.
- **Plataforma:** SO, versões, rede/firewall, hardware alvo.
- **Verificação e avaliação:** como provar que está correto e como vai aparecer em
  testes, medições, documentação ou apresentação.

Não pergunte o que dá para descobrir lendo o código. Repita rodadas até não sobrar dúvida que
afete o desenho.

## Passo 3 — Escrever o plano

Salve em `<pasta_planos>/AAAA-MM-DD-<nome-curto>.md` (crie a pasta se não existir) e mostre um
resumo no chat. Estrutura:

```markdown
# <Título>
Data: AAAA-MM-DD · Status: proposto | aprovado | concluído · Responsável(is): <nomes>

## Objetivo e critério de pronto
## Decisões (dúvida → escolha → motivo [→ referência])
## Arquitetura
- Componentes novos/alterados e o papel de cada um
- Diagrama em texto do fluxo de dados/controle
## Comunicação e sincronização
| De → Para | Mensagem/primitiva | Conteúdo | Quando |
- Onde há lock/barreira/fila e por que não há condição de corrida nem deadlock
## Interfaces
| Arquivo/módulo | Função/classe/porta | Parâmetros | Retorno/efeito |
## Verificação (teste primeiro)
- Testes novos/alterados; casos de borda; o que deve FALHAR antes da implementação
## Medição (se desempenho importa)
- Cenários, métrica, linha de base
## Arquivos
| Arquivo | Mudança |
## Passos de execução (ordem)
## Documentação e apresentação
- O que atualizar; quem precisa saber explicar o quê
## Riscos e fora do escopo
```

Seções que não se aplicam: escreva "não se aplica" em vez de apagar, para mostrar que foram consideradas.

## Passo 4 — Aprovação

Peça aprovação explícita (aprovar / ajustar / cancelar). Se ajustar, atualize o arquivo e peça de
novo. Só com "aprovado" marque `Status: aprovado` e siga.

## Passo 5 — Executar o plano aprovado

1. **Teste primeiro:** escreva/estenda os testes do plano e rode — confirme que falham pelo motivo
   esperado (a funcionalidade ainda não existe), não por erro de sintaxe ou ambiente.
2. Implemente na ordem dos passos. Rode os testes afetados a cada passo relevante.
3. Ao final, rode a suíte completa (e uma medição curta, se desempenho importa) e atualize a documentação.
4. Se surgir algo que muda o desenho (não um detalhe), **pare e pergunte** — registre a decisão no plano.
5. Marque `Status: concluído` e informe: o que foi feito, resultado dos testes, desvios do plano e
   o que ficou pendente para o usuário.
