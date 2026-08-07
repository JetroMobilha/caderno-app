# Relatório de Auditoria Técnica e Propostas de Melhoria

Este documento contém uma análise profunda da base de código atual, identificando bugs latentes, gargalos de performance e sugestões de refatoração para aumentar a robustez do **Caderno Digital**.

## 1. 🐞 Caça aos Bugs (Prioridade Alta)

### A. Silêncio Perigoso (Empty Catch Blocks)
Detetei vários blocos `try-catch` vazios no `CanvasController` (ex: linhas 991, 1056, 1112, 1146).
- **Problema**: Se o servidor enviar um JSON ligeiramente malformado ou se houver um erro de casting, a subscrição de Realtime pode "morrer" silenciosamente e o utilizador deixa de ver os desenhos dos colegas sem saber porquê.
- **Solução**: Implementar um `debugPrint` informativo e, em casos críticos, disparar um alerta visual para o utilizador sugerindo um refresh.

### B. Gestão de Memória no Realtime
No `RealtimeService.dart`, os `StreamControllers` são globais ao serviço.
- **Problema**: Quando mudas de um caderno para outro, se houver eventos "pendentes" no socket que cheguem com atraso, eles podem ser processados pelo controlador do novo caderno.
- **Solução**: Adicionar um filtro de `notebookId` em cada receptor do `CanvasController` para garantir que a página só reage a eventos do caderno atual.

### C. Inconsistência de Versão em Novas Ações
A lógica de Relógios Lógicos foi bem aplicada no `DeleteAction`, mas detetei que no `AddStrokeAction` e `AddTextAction`, o incremento da `version` pode estar a ser ignorado em certos fluxos de retorno.
- **Risco**: Um traço novo pode nascer com `version: 1` e ser imediatamente sobrescrito por um "fantasma" de sincronização que tenha uma versão superior por erro de estado anterior.

## 2. ⚡ Performance e Fluidez (Prioridade Média)

### A. Otimização do Painter
O `StaticNotebookPainter` percorre a lista completa de `strokes` a cada frame.
- **Problema**: Mesmo com `isDeleted`, o loop continua a crescer. Num caderno com meses de uso, isto pode causar "jank" (pequenas travagens).
- **Solução**:
    1. Implementar um sistema de **"Flattening"**: A cada 50 traços, a App poderia gerar uma imagem estática de fundo e limpar os traços individuais da memória (mantendo-os apenas no banco para histórico).
    2. Filtrar a lista de traços *antes* de passar para o Painter, e não dentro do loop `for` do `paint`.

### B. Debounce de Viewport
O envio da posição do ecrã (`client-viewport-sync`) ocorre a cada 80ms.
- **Problema**: Isto gera muito tráfego de rede desnecessário se o utilizador estiver apenas a ler sem se mexer.
- **Solução**: Só disparar o broadcast se a mudança de posição for superior a um limiar de pixels (ex: > 5px).

## 3. 🏗️ Arquitetura e Limpeza

### A. Ambiguidade de Modelos
O conflito entre `Notebook` (Drift) e `Notebook` (Model) no Marketplace é um aviso de que os nomes estão demasiado genéricos.
- **Sugestão**: Renomear as classes geradas pelo Drift no `app_database.dart` usando o sufixo `Table` (ex: `NotebooksTable`). Isto evita a necessidade de `hide` ou prefixos em todo o projeto.

### B. Centralização de Erros de Rede
Atualmente, cada controlador trata os seus erros de API.
- **Sugestão**: Criar um `GlobalErrorProvider` que o `ApiService` possa usar para mostrar SnackBars automáticas de "Sem Internet" ou "Sessão Expirada", removendo código repetitivo dos controladores.

## 4. Próximas Implementações Sugeridas

1.  **Deltas de Texto**: No chat e nos blocos de texto, enviar apenas as letras alteradas em vez do parágrafo todo.
2.  **Modo de Baixo Consumo**: Desativar ponteiros remotos automaticamente se a bateria estiver fraca ou se a net for lenta.
3.  **Verificação de Integridade Local**: Um botão "Reparar Caderno" que limpa duplicados e re-sincroniza tudo do zero com a nuvem.

---
**Conclusão**: O projeto está numa excelente direção. Os maiores riscos são o tratamento de erros silencioso e o crescimento linear do processamento do Canvas.
