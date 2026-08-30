# Plano de Maturação de UI e Limpeza Estrutural

Este plano reflete as melhorias estruturais (Tags, Favoritos, Arquivo) na interface do utilizador e limpa os parâmetros obsoletos do nível do caderno, uma vez que agora são geridos folha a folha.

## Mudanças Propostas

### 1. Limpeza Estrutural (Remover Redundância)

#### [MODIFY] [app_database.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/core/database/app_database.dart)
- Remover as colunas `lineType`, `lineSpacing` e `paperSize` da tabela `Notebooks`.
- Incrementar `schemaVersion` para **21**.
- Implementar migração v20 -> v21 para remover estes campos.

#### [MODIFY] [notebook_model.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/notebooks/models/notebook_model.dart)
- Remover os campos `lineType`, `lineSpacing` e `paperSize`.
- Ajustar construtores, `copyWith`, `toJson` e `fromJson`.

### 2. Atualização da Interface (UX/UI)

#### [MODIFY] [notebook_dialogs.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/notebooks/widgets/notebook_dialogs.dart)
- **Remover:** Secção "Tipo de Pauta Inicial".
- **Adicionar:**
    - Campo de entrada para **Tags** (converte texto separado por vírgulas em lista).
    - Toggle/Switch para **Marcar como Favorito**.
- **Ações:** Adicionar opção "Arquivar/Desarquivar" no menu de contexto.

#### [MODIFY] [notebook_grid_item.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/notebooks/widgets/notebook_grid_item.dart)
- Exibir um ícone de estrela (`Icons.star_rounded`) no canto para cadernos favoritos.
- Exibir chips pequenos para as **Tags** na parte inferior da capa.
- Feedback visual (opacidade ou ícone) se o caderno estiver arquivado.

#### [MODIFY] [notebooks_list_screen.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/notebooks/views/notebooks_list_screen.dart)
- Separar a visualização: Mostrar primeiro os favoritos, depois os ativos.
- Adicionar uma secção (ou toggle) para visualizar "Cadernos Arquivados".

### 3. Backend PHP (Sincronização)

#### [MODIFY] [Notebook.php](file:///C:/xampp/htdocs/caderno-backend/app/Models/Notebook.php) e [SyncController.php](file:///C:/xampp/htdocs/caderno-backend/app/Http/Controllers/Api/SyncController.php)
- Remover os campos obsoletos do `$fillable` e das respostas da API.
- Garantir que `tags`, `is_archived` e `is_favorite` são as novas prioridades de metadados.

---

## Verificação Técnica

### Manual Verification
1.  **Limpeza:** Criar um caderno e verificar se as opções de pauta já não aparecem (pois a primeira folha será criada com o padrão do app e alterada na folha).
2.  **Organização:** Marcar um caderno como favorito e arquivar outro. Verificar se a Home organiza os grupos corretamente.
3.  **Tags:** Inserir tags como "Faculdade, Urgente" e verificar se aparecem como etiquetas na capa do caderno.
4.  **Sync:** Confirmar que estas preferências de UI são enviadas para o servidor e aparecem em outros dispositivos.

## Aprovação do Utilizador
> [!IMPORTANT]
> Ao remover a pauta do caderno, a App usará o estilo 'ruled' (pautado) como padrão global para a primeira folha de novos cadernos, simplificando o processo de criação.
