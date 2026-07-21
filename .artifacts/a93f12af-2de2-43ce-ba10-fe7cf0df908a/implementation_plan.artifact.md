# Plano de Otimização, Testes e Documentação Final

Este plano visa tornar a sincronização automática e eficiente, garantir a integridade do código através de testes unitários e atualizar a documentação do projeto para refletir a nova arquitetura reativa com Drift.

## Otimização da Sincronização
Para economizar dados e bateria, implementaremos uma "Sincronização Delta" inteligente:
* **Background Sync:** O `SyncService` será gerido por um `Notifier` que executa ciclos de sincronização periódicos (ex: a cada 5 minutos) apenas se houver alterações detetadas.
* **Verificação de Cabeçalho:** Antes de fazer um `PULL` pesado, pediremos ao servidor o `last_updated_at` global. Se for igual ao local, ignoramos o download.

## Alinhamento de Views
Revisão das views principais para garantir que utilizam os Providers reativos de forma consistente:
* `SubjectsListScreen`
* `NotebooksListScreen`
* `MarketplaceScreen`
* `ProfileScreen`

## Estratégia de Testes Unitários
Criaremos uma suite de testes focada na confiança do motor de dados:
* **Models:** Testar serialização/deserialização JSON de todos os modelos.
* **Repositories:** Usar o `Drift` em memória para testar CRUD e Streams.
* **Sync Logic:** Simular payloads do servidor para validar a lógica de Merge/Batch.

## Atualização do README.md
Documentar a nova "Stack de Elite":
* **Drift (WASM):** Persistência reativa multiplataforma.
* **Riverpod:** Gestão de estado moderna.
* **Laravel Reverb:** Colaboração em tempo real via WebSockets.
* **Sincronização Diferencial:** Como o projeto poupa dados do utilizador.

## User Review Required
> [!NOTE]
> A sincronização automática em background pode consumir alguma bateria. Recomenda-se desativar se o nível de bateria estiver baixo (lógica futura).

## Proposed Changes

### [Core]
#### [NEW] [sync_provider.dart](file:///C:/Users/Jetro.Domingos/StudioProjects/caderno_digital_app/lib/core/network/sync_provider.dart)
* Criar um `StreamProvider` ou `Notifier` que orquestra o ciclo de vida do `SyncService`.

### [Testes]
#### [NEW] suite de testes em `test/core/database/` e `test/features/`

### [Documentação]
#### [MODIFY] [README.md](file:///C:/Users/Jetro.Domingos/StudioProjects/caderno_digital_app/README.md)

## Verification Plan
### Automated Tests
* `flutter test` - Todos os novos testes devem passar.
### Manual Verification
* Monitorizar o logcat para ver os ciclos de sincronização automática a disparar sem intervenção do utilizador.
* Verificar no Chrome DevTools (Web) se o tráfego de rede é minimizado quando não há alterações no servidor.
