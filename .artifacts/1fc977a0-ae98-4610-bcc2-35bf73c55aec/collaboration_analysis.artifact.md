# Análise de Melhores Práticas para Colaboração em Tempo Real

Este documento analisa o estado atual da colaboração no Caderno Digital e propõe melhorias baseadas em padrões de arquitetura de sistemas distribuídos e colaborativos.

## 1. Estado Atual
- **Protocolo**: WebSockets (via Laravel Reverb).
- **Consistência**: Last-Write-Wins (LWW) baseado em `updatedAt` (timestamp físico).
- **Granularidade**: Nível de Bloco (Stroke, TextBlock, ImageBlock).
- **Deleção**: Soft-Deletes com Tombstones (implementado recentemente).
- **Problema Identificado**: Possível perda de dados em conflitos de edição simultânea no mesmo bloco de texto e dependência de relógios de sistema sincronizados.

## 2. Soluções de Mercado vs. Necessidades do Projeto

### A. CRDTs (Conflict-free Replicated Data Types)
- **O que é**: Estruturas de dados que podem ser replicadas e modificadas de forma independente, garantindo que todos os nós convirjam para o mesmo estado sem um coordenador central.
- **Vantagem**: Funciona perfeitamente offline, suporta edições concorrentes granulares (ex: duas pessoas a escrever na mesma frase).
- **Implementação**: Bibliotecas como `Yjs` ou `Automerge`. No Flutter, exigiria uma ponte via Rust ou JavaScript.
- **Veredito**: Excelente para o **Texto dentro dos blocos**, mas complexo demais para os **Traços (Inking)** onde o LWW já resolve bem.

### B. OT (Operational Transformation)
- **O que é**: Transformação de operações baseada num servidor central (usado pelo Google Docs).
- **Vantagem**: Alta fidelidade em texto.
- **Desvantagem**: Extremamente complexo de implementar corretamente e exige que o servidor processe toda a lógica.
- **Veredito**: Não recomendado para este projeto devido à natureza mista (desenho + texto).

### C. LWW com Relógios Lógicos (Lamport Clocks)
- **O que é**: Em vez de usar a hora do telemóvel, usamos um contador inteiro que aumenta a cada ação.
- **Vantagem**: Elimina problemas de telemóveis com horas erradas. Se o meu contador é 10 e recebo uma ação com 11, a do colega é mais recente, ponto final.
- **Veredito**: **Altamente Recomendado**. É uma melhoria incremental barata e muito eficaz.

## 3. Estratégia Proposta para o Caderno Digital

### Fase 1: Reforço da Integridade (Curto Prazo)
1. **Relógios Lógicos**: Implementar um `version` ou `logical_clock` em cada caderno para ordenar ações sem depender do relógio do sistema.
2. **Confirmação de Escrita (Acks)**: O servidor deve responder com um "OK" e o ID final. O cliente mantém o item em estado "pendente" (visualização a cinzento, por exemplo) até receber o OK.

### Fase 2: Edição Granular (Médio Prazo)
1. **Deltas de Texto**: Em vez de enviar o texto todo a cada letra escrita, enviar apenas o que mudou (Diff).
2. **Bloqueio de Bloco (Pessimistic Locking)**: Quando um utilizador clica para editar um texto, o bloco fica "bloqueado" visualmente para os outros, impedindo edições simultâneas que causem conflitos.

### Fase 3: Sync Delta (Longo Prazo)
1. Implementar um sistema de **Snapshots** diários e **Logs de Operações** horários para permitir que um utilizador que esteve uma semana offline recupere apenas o que mudou, sem baixar o caderno todo.

## 4. Próximos Passos Sugeridos
1. **Ajustar o Servidor**: Preparar a base de dados para aceitar relógios lógicos.
2. **Modificar o SyncService**: Criar uma fila de "Ações Pendentes" que sobrevive ao fecho da App.
