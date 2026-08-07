# Plano de Expansão da Cobertura de Testes (QA Global)

Este plano visa garantir que todas as funcionalidades críticas da aplicação, especialmente as recentemente implementadas (Marketplace e Caligrafia), estejam protegidas por testes unitários e de integração, atingindo uma cobertura de código saudável.

## Proposed Changes

### [Novas Suites de Testes]

#### [NEW] [marketplace_controller_test.dart](file:///C:/Users/HP/StudioProjects/caderno-app/test/features/marketplace/controllers/marketplace_controller_test.dart)
- Testar carregamento inicial e paginação infinita.
- Testar lógica de aquisição: simular resposta do servidor, mapeamento de ID de disciplina local e inserção no banco de dados.
- Garantir que estados de `isAcquiring` e `isLoading` mudam corretamente.

#### [NEW] [handwriting_controller_test.dart](file:///C:/Users/HP/StudioProjects/caderno-app/test/features/handwriting/controllers/handwriting_controller_test.dart)
- Testar seletor de caracteres.
- Validar acumulação de traços (strokes) e função de `undo`.
- Simular gravação de letra no servidor e atualização do progresso (trained characters).

#### [NEW] [ai_assistant_service_test.dart](file:///C:/Users/HP/StudioProjects/caderno-app/test/core/services/ai_assistant_service_test.dart)
- Mockar chamadas HTTP para o assistente de IA.
- Validar processamento de respostas (streaming ou JSON).

#### [NEW] [sync_conflict_test.dart](file:///C:/Users/HP/StudioProjects/caderno-app/test/core/network/sync_conflict_test.dart)
- Testar exaustivamente a regra **Last-Write-Wins (LWW)** do `SyncService`.
- Cenário: Item local v5 vs Item remoto v3 (Local ganha).
- Cenário: Item local v2 vs Item remoto v5 (Remoto ganha e atualiza local).

### [Refinação de Infraestrutura]

- Atualizar mocks com `GenerateMocks` para incluir `MarketplaceRepository` e `HandwritingRepository`.
- Garantir que todos os testes de plataforma (Audio/Path) estão devidamente simulados.

## Verification Plan

### Automated Tests
- Execução de `dart run build_runner build` para atualizar mocks.
- Execução de `flutter test` para validar toda a suite.

### Manual Verification
- Nenhuma necessária, o objetivo é a validação automática do comportamento do código.
