# Plano de Implementação: Transição de Terminologia para "Pastas"

Este plano visa tornar a aplicação mais abrangente para diversos setores (Corporativo, Engenharia, Direito, etc.), substituindo os termos académicos "Disciplina" e "Matéria" por "**Pasta**" em toda a interface do utilizador.

## User Review Required

> [!IMPORTANT]
> Esta alteração é puramente visual e de experiência de utilizador (UX). O código interno, as tabelas da base de dados e os endpoints da API continuarão a usar o termo `Subject` para manter a compatibilidade técnica e evitar quebras no sistema de sincronização.

## Proposed Changes

### [App - Flutter]
Substituição massiva de strings visíveis ao utilizador.

#### [MODIFY] [drawer_subjects_list.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/shared/widgets/drawer/drawer_subjects_list.dart)
- "AS MINHAS DISCIPLINAS" -> "**AS MINHAS PASTAS**"
- "Criar Nova Disciplina" -> "**Criar Nova Pasta**"
- "Nenhuma disciplina criada" -> "**Nenhuma pasta criada**"

#### [MODIFY] [subject_dialogs.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/subjects/widgets/subject_dialogs.dart)
- "Apagar Disciplina?" -> "**Apagar Pasta?**"
- "A disciplina... será apagada" -> "**A pasta... será apagada**"
- "Disciplina eliminada!" -> "**Pasta eliminada!**"
- "Editar Matéria" -> "**Editar Pasta**"
- "Nova Disciplina" -> "**Nova Pasta**"
- "Nome da Matéria" -> "**Nome da Pasta**"

#### [MODIFY] [notebook_dialogs.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/notebooks/widgets/notebook_dialogs.dart)
- "Disciplina de Destino:" -> "**Pasta de Destino:**"
- "Para qual disciplina desejas mover..." -> "**Para qual pasta desejas mover...**"

#### [MODIFY] [marketplace_screen.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/marketplace/views/marketplace_screen.dart)
- "Pesquisar por matéria..." -> "**Pesquisar por pasta...**"

#### [MODIFY] [notebook_empty_states.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/notebooks/widgets/notebook_empty_states.dart)
- "...selecionares ou criares a tua primeira disciplina" -> "**...selecionares ou criares a tua primeira pasta**"

### [Backend - Laravel]
Atualizar mensagens de erro enviadas para o cliente.

#### [MODIFY] [SubjectController.php](file:///C:/xampp/htdocs/caderno-backend/app/Http/Controllers/SubjectController.php)
- "Disciplina não encontrada" -> "**Pasta não encontrada**"
- "Disciplina eliminada com sucesso" -> "**Pasta eliminada com sucesso**"

## Verification Plan

### Manual Verification
1.  Abrir a gaveta e confirmar o título "**AS MINHAS PASTAS**".
2.  Tentar criar uma pasta e verificar se o título do diálogo é "**Nova Pasta**".
3.  Tentar apagar uma pasta e verificar a mensagem de confirmação.
4.  No ecrã de Marketplace, verificar a barra de pesquisa.
5.  Mover um caderno entre pastas e validar as labels do seletor.
