# Correção Definitiva da Transmissão em Tempo Real de Anexos

## O Causa do Problema Encontrada
Quando o utilizador adicionava um anexo em colaboração:
1. O anexo era guardado localmente e a tarefa de upload em plano de fundo iniciava.
2. Como o utilizador tinha acabado de voltar do seletor de ficheiros do telemóvel, o Reverb estava a reconectar.
3. A função de upload aguardava no máximo 5 segundos por `_realtimeService.isConnected`. Se a reconexão demorasse mais do que isso (ou se o canal de presenza estivesse a re-subscrever), a transmissão era **abortada silenciosamente** (`if (_realtimeService.isConnected)` era falso).
4. No entanto, o `_executeAction` local já tinha registado o anexo no `_historyManager`.
5. **Consequência:** Em tempo real o Reverb não enviava a mensagem e o colega não via o anexo na hora. Mas quando o colega pedia o histórico P2P, o `_historyManager` trazia a ação, fazendo o anexo aparecer do nada!

## A Solução Aplicada
Substituímos o bloco manual com timeout pela nossa função resiliente `_broadcastAction(AddAttachmentAction(..., attach: updatedAttach))`:
- A função `_broadcastAction` utiliza o `ensureChannelReady()`.
- O `ensureChannelReady()` aguarda de forma inteligente e resiliente até que o canal do Reverb esteja 100% estabelecido e pronto a transmitir, sem abortar silenciosamente.
- Assim que o upload conclui, o `AddAttachmentAction` é transmitido à sala e chega ao colega **imediatamente** em tempo real com o `remoteUrl` preenchido!
