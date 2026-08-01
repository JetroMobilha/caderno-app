# Plano de Correção: Sincronização de Títulos e Tipos de Folha

Este plano visa corrigir as discrepâncias entre o Flutter e o Laravel que impedem a renderização correta das linhas das folhas e causam a exibição de JSON nos títulos.

## User Review Required

> [!IMPORTANT]
> As mudanças no `SyncController.php` devem ser aplicadas no servidor. Vou fornecer o código corrigido para que possas atualizar o arquivo no teu backend Laravel.

## Proposed Changes

### 1. Backend: Laravel (SyncController.php)

#### [MODIFY] `SyncController.php`
- **Ajuste de Tipos de Linha**: Mudar o default de `line_type` para `ruled` (o padrão do Flutter).
- **Simplificação de Metadados**: Alterar `normalizeJsonColumn` para não forçar a criação de um objeto `{"title": "..."}` se receber uma string simples. Isso evitará que o Flutter receba JSON e o exiba como texto.

```php
// No pushNotebooks:
'line_type' => !empty($notebookData['line_type']) ? $notebookData['line_type'] : 'ruled',

// No normalizeJsonColumn:
// Se for uma string que NÃO é JSON, retornar a string pura em vez de envolver em array.
```

### 2. Frontend: Flutter (Modelos)

#### [MODIFY] [local_page_model.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/models/local_page_model.dart)
- Garantir que o `fromJson` consegue lidar tanto com strings puras quanto com objetos JSON (por segurança).

#### [MODIFY] [notebook_model.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/notebooks/models/notebook_model.dart)
- Garantir que o default no `fromJson` é consistente.

## Verification Plan

### Manual Verification
1. Criar um caderno com linhas (`ruled`) no Telemóvel A.
2. Sincronizar e abrir no Telemóvel B/Windows.
3. Verificar se as linhas aparecem corretamente.
4. Alterar o título da página e verificar se aparece o texto limpo (sem `{}` ou `"title"`).
