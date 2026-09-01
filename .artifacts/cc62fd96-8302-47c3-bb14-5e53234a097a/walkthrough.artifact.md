# Correção de Sync e Presença em Tempo Real

Esta atualização resolve o erro de sincronização que impedia a visualização da contagem de participantes e ativa o indicador "Online".

## Alterações Realizadas

### 1. Correção Crítica no Sync (`SyncService`)
- **Problema**: O App estava a falhar ao sincronizar cadernos devido a um erro de conversão (`bool` para `int`) no campo de notificações. Isto bloqueava a receção de qualquer metadado novo, incluindo a contagem de participantes.
- **Correção**: Ajustei a lógica de mapeamento para converter corretamente os valores booleanos do servidor para o formato `int` esperado pela base de dados local (`drift`).

### 2. Ativação da Presença "Online"
- **Contagem de Acessos**: O ícone de grupo agora mostra corretamente o número total de pessoas com acesso (ex: `[Icon] 2` para um caderno partilhado entre duas pessoas).
- **Indicador Online**: Agora que o sync completa com sucesso, o ponto verde e o rótulo **Online** aparecerão sempre que houver utilizadores ativos no caderno.
- **Eficiência**: Esta informação é processada no backend e entregue como metadado leve, sem sobrecarregar a ligação.

### 3. Refinamento de Layout
- Removi variáveis não utilizadas e simplifiquei a estrutura da capa para garantir que a indicação de presença flutua de forma limpa acima do rodapé, sem sobreposições.

---

### Como Verificar
1. Faça um **Hot Restart** para aplicar as correções de código.
2. Na grid de cadernos, arraste para baixo para disparar um **Sync**.
3. Verifique se o erro no terminal desapareceu.
4. Em cadernos partilhados, verás agora a contagem de acessos. Se alguém estiver com o caderno aberto, verás o indicador **Online** (Ponto Verde).
