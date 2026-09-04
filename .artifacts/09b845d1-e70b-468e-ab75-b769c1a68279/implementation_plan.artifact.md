# Plano de Manutenção: OCR e Reconhecimento de Escrita (v29)

Garantir que a funcionalidade de transformar desenhos em texto de máquina (OCR) continue operacional após a migração para o sistema de objetos unificados (`objects_data`).

## Diagnóstico
O motor de OCR atual (`ProcessPageOcr.php`) procura os traços na coluna `stroke_data`. Com a unificação, os novos traços estarão dentro de `objects_data` com o tipo `stroke`. Precisamos de adaptar o Job para extrair os dados do local correto.

## Mudanças Propostas - Backend (Laravel)

### 1. Modelo de Página (`Page.php`)
- **[MODIFY] [Page.php](file:///C:/xampp/htdocs/caderno-backend/app/Models/Page.php)**:
    - Adicionar um método auxiliar `getStrokes()` que tenta ler de `objects_data` (filtrando por `type: stroke`) e, se vazio, recorre ao antigo `stroke_data`. Isto garante que o OCR funcione tanto para cadernos novos como legados.

### 2. Job de Processamento (`ProcessPageOcr.php`)
- **[MODIFY] [ProcessPageOcr.php](file:///C:/xampp/htdocs/caderno-backend/app/Jobs/ProcessPageOcr.php)**:
    - Atualizar a lógica de extração de traços para utilizar o novo método `getStrokes()`.

### 3. Sincronização Inteligente (`SyncService.php`)
- **[MODIFY] [SyncService.php](file:///C:/xampp/htdocs/caderno-backend/app/Services/SyncService.php)**:
    - Garantir que, ao receber `objects_data`, o gatilho para o `ProcessPageOcr` seja disparado se houver traços novos na lista.

## Plano de Verificação

### Verificação Manual
1. **Desenho para Texto**: Desenhar uma palavra legível no App, sincronizar e verificar nos logs do Laravel se o Job `ProcessPageOcr` foi disparado com sucesso.
2. **Confirmação no Banco**: Verificar se a coluna `extracted_text` é preenchida corretamente no MySQL após o processamento.
3. **Legado**: Abrir uma página antiga e confirmar que o OCR ainda consegue ler os dados da coluna `stroke_data` original.
