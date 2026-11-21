---
name: otimizar-timing-fpga
description: Use quando o objetivo for fechar timing (atingir a frequência do clock), aumentar a Fmax, reduzir área (LUTs, FFs, BRAM, DSP) ou entender relatórios de síntese/implementação de FPGA (Vivado; foco em AMD/Xilinx 7-series e UltraScale) — WNS/TNS/WHS negativos, caminho crítico, latches, memória inferida como flip-flops, fanout, congestionamento, diretivas de ferramenta. Também ao comparar antes/depois de uma mudança de RTL em área ou timing. NÃO usar para escrever testbench nem depurar comportamento funcional.
---

# Otimizar timing e área em FPGA (Vivado)

**Princípio:** diagnosticar com dados, mudar **uma** estrutura, medir de novo. O gargalo raramente
está onde a intuição aponta. **Nunca dizer que algo melhorou sem número de antes e depois.**

**Antes de começar:** ler o `CLAUDE.md` do projeto ("Perfil para as skills", modelo em
`modelos/CLAUDE-perfil.md`): parte alvo (ex.: `xc7a100tcsg324-1`), clock alvo (`create_clock`
no XDC), top, como rodar síntese/implementação (script do projeto ou fluxo abaixo), comando da
regressão funcional (testbenches) e onde registrar medições (ex.: `docs/TIMING.md`). Registrar o
alvo usado em cada medição.

## 1. Medir sempre pelo mesmo fluxo

Preferir **modo non-project em batch** (reprodutível, não depende do estado da GUI nem altera o
`.xpr`). Esqueleto de `run.tcl` (`vivado -mode batch -source run.tcl -log vivado.log`):

```tcl
set part xc7a100tcsg324-1 ; set top top ; set out build/synth/<tag>
file mkdir $out
read_verilog -sv [glob src/*.sv]        ;# ajustar: read_vhdl, read_mem, IPs
read_xdc constrs/top.xdc
synth_design -top $top -part $part      ;# -directive PerformanceOptimized | -retiming (experimentos)
report_utilization -file $out/util_synth.rpt
opt_design                               ;# -directive ExploreWithRemap (experimento)
place_design                             ;# -directive Explore | ExtraTimingOpt (experimento)
# phys_opt_design                        ;# replicação de fanout, retiming físico (experimento)
route_design                             ;# -directive Explore (experimento)
report_timing_summary -max_paths 10 -file $out/timing.rpt
report_timing -max_paths 20 -nworst 1 -file $out/paths.rpt
report_utilization -file $out/util.rpt
report_utilization -hierarchical -file $out/util_hier.rpt
report_methodology -file $out/methodology.rpt
```

- Um diretório por medição (`<tag>`) e uma linha por execução num histórico (CSV: data, tag,
  commit, mudança, WNS, TNS, WHS, Fmax estimada, LUT, FF, LUTRAM, BRAM, DSP).
- **Fmax estimada** = 1 / (período − WNS).
- Decisões só com números **pós-roteamento**; pós-síntese serve para triagem rápida (o roteamento
  costuma ser a maior parte do atraso em 7-series).
- **Conteúdo de memórias ROM/inicializadas muda o resultado:** se uma ROM (ex.: memória de
  instruções) tem conteúdo conhecido na síntese, o Vivado remove a lógica que aquele conteúdo nunca
  usa. Para medir o **circuito**, use um conteúdo que exercite tudo (programa de autoteste) e
  compare sempre com o **mesmo** conteúdo. Melhora que só aparece trocando o conteúdo não é
  melhora de RTL.

## 2. Ciclo de trabalho

1. **Medir a base** se não houver medição recente do RTL atual.
2. **Diagnosticar** pelo caminho crítico (`timing.rpt`): origem e destino, níveis de lógica,
   atraso de lógica × roteamento, primitivas no caminho, *fanout* dos nós.
3. **Hipótese sobre uma estrutura**, escrita antes de mudar: "o caminho X passa por Y; trocando Y
   por Z espero WNS melhorar ~N ns / área cair ~M LUTs".
4. **Se mudar arquitetura** (latência de memória, *pipeline*, novo clock, interface entre módulos):
   usar a skill `planejar-tarefa` e obter aprovação. Mudança local equivalente (reescrever uma
   expressão, separar um comparador) segue direto.
5. **Validar funcionalmente** com a regressão completa antes de medir. Otimização que quebra a
   função não conta.
6. **Medir de novo** com *tag* nova e comparar com a base.
7. **Decidir:** manter se melhorou além do ruído (seção 5); senão reverter. Parar de atacar uma
   estrutura quando ela sair do caminho crítico — o próximo gargalo é outro.
8. **Registrar:** data, *tag*, mudança, números antes → depois e conclusão (inclusive tentativas
   que não funcionaram).

## 3. Como ler o caminho crítico (7-series)

| Sinal no relatório | Significado provável |
| :-- | :-- |
| Roteamento > ~60% do atraso | *fanout* alto, mux enorme espalhado, ou lógica distribuída pelo chip (ex.: memória virando milhares de FFs). Atacar a estrutura, não a lógica. |
| Muitos `MUXF7`/`MUXF8` | mux largo — leitura de um array implementado em FFs/LUTs (banco de registradores, memória). |
| `RAMD32`/`RAMS32`/`RAMD64E` | LUTRAM (memória distribuída) — leitura assíncrona, boa para tamanhos pequenos. |
| `FDRE`/`FDSE` em quantidade ≈ bits de uma memória | a memória **não** foi inferida como RAM; virou flip-flops. Grande perda de área e de timing. |
| `RAMB18`/`RAMB36` | Block RAM — leitura **síncrona** (1 ciclo de latência); pode exigir mudança de arquitetura. |
| `CARRY4` (`CARRY8` em UltraScale) em cadeia longa | somador/comparador largo. 32 bits ≈ 8 `CARRY4`. |
| Muitos níveis de `LUT6` | lógica de decisão profunda (decodificação → controle → mux). |
| `DSP48E1/E2` | multiplicação/MAC; confira se era esperado. |

Também olhar: `report_methodology` (avisos que indicam restrição faltando ou estrutura ruim),
mensagens de inferência de RAM no `vivado.log`, *latches* inferidos (`Synth 8-327`) e a área por
módulo (`util_hier.rpt`) para saber onde a área está.

## 4. Alavancas, da menos para a mais invasiva

1. **Inferência de memória correta** (geralmente o maior ganho): arrays que viram FFs. Para
   LUTRAM com leitura assíncrona: array 1-D (por faixa de byte se houver escrita parcial), escrita
   síncrona simples, sem reset e sem lógica extra no array. Para BRAM: leitura registrada. Confirmar
   no `util.rpt` (LUT as Memory/Block RAM sobe, Registers caem) e no `vivado.log`.
2. **Encurtar o caminho mantendo o comportamento:** separar comparadores/somadores do caminho
   principal e calcular em paralelo; pré-calcular valores (ex.: PC+4, alvos); simplificar muxes;
   decodificação rasa (one-hot); trocar `if/else` encadeado (cadeia de prioridade) por `case`
   paralelo quando as condições são exclusivas; reduzir *fanout* (replicação de registradores).
3. **Opções de ferramenta** (sem mudar RTL; registrar como experimento): `synth_design -directive
   PerformanceOptimized`, `-retiming`, `opt_design -directive ExploreWithRemap`,
   `place_design -directive Explore/ExtraTimingOpt`, `phys_opt_design` (antes e/ou depois do
   route), `route_design -directive Explore`. Medir sempre nos dois fluxos (padrão e o de esforço
   máximo, se for o usado no bitstream final).
4. **Mudanças de arquitetura** (sempre com `planejar-tarefa`): BRAM síncrona, *pipeline*,
   *multicycle* real com habilitação, clock menor via MMCM/PLL quando o objetivo é só funcionar na placa.

**Não fazer:** `set_false_path`/`set_multicycle_path` para esconder caminhos reais; afrouxar o
`create_clock` sem decisão do usuário; otimizar fora do caminho crítico; trocar várias estruturas
de uma vez (não dá para saber o que ajudou).

## 5. Ruído e confiabilidade

- Área pós-síntese é praticamente determinística para o mesmo RTL; diferenças de dezenas de LUTs
  podem ser ruído do otimizador.
- Timing pós-roteamento varia com o *placement*: diferenças de WNS abaixo de ~0,5 ns em designs
  pequenos não provam nada. O fluxo é determinístico (rodar de novo dá o mesmo número), então
  repetir não mede ruído: compare níveis de lógica e atraso de lógica do caminho, ou varie a
  semente/diretiva para ver a dispersão.
- WHS (*hold*) negativo pós-roteamento é problema real; pós-síntese pode ser ignorado.
- *Latches* inferidos são bug de RTL combinacional (atribuição faltando em algum ramo): sempre relatar.
- Avisos de methodology esperados no projeto (ex.: pinos assíncronos sem `set_input_delay`): listar
  no perfil para não serem confundidos com o gargalo.

## 6. Relato ao usuário

Tabela antes → depois (WNS, Fmax estimada, TNS, WHS, LUT, FF, LUTRAM, BRAM, DSP), o caminho
crítico atual em uma linha (origem → destino, níveis, % roteamento), o que foi mudado e a próxima
alavanca sugerida. Se não melhorou, dizer isso e reverter.
