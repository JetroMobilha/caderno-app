# Plano de Implementação: Expansão do Perfil do Utilizador e Remoção do Perfil da Aplicação

Este plano visa simplificar a experiência do utilizador ao remover a seleção global de "Perfil da Aplicação" e expandir o "Perfil do Utilizador" com campos e preferências úteis para um projeto de grande dimensão (EdTech, Colaboração e IA).

## User Review Required

> [!IMPORTANT]
> A remoção do `AppProfile` significa que a aplicação deixará de ter um seletor de "Modo Académico/Corporativo" na gaveta. As variações visuais serão agora baseadas nas preferências do utilizador ou no contexto do caderno aberto.

> [!WARNING]
> Esta alteração envolve uma migração de base de dados (versão 18) para adicionar novos campos à tabela de utilizadores.

## Proposed Changes

### [Auth & User Model]
Expandir o modelo de utilizador para suportar a nova visão de "Perfil Premium".

#### [MODIFY] [user_model.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/auth/models/user_model.dart)
- Adicionar campos: `bio`, `institution`, `preferredColor`, `preferredFont`, `specialties`.
- Atualizar construtor, `fromJson` e `toJson`.

#### [MODIFY] [app_database.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/core/database/app_database.dart)
- Adicionar colunas correspondentes na tabela `Users`.
- Implementar migração para a versão 18 no `onUpgrade`.

### [Theme & UI Cleanup]
Remover a dependência do `AppProfile` e unificar o tema.

#### [DELETE] [app_profile.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/core/theme/app_profile.dart)
- Remover este ficheiro e o seu respectivo Notifier/Provider.

#### [MODIFY] [app_theme.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/core/theme/app_theme.dart)
- Ajustar para ler a cor primária e a fonte diretamente do utilizador autenticado (`authProvider`).
- Definir "Inter" como a fonte padrão e o azul petróleo (`#0F4C5C`) como cor padrão de fallback.

### [User Interface]
Refatorar a Gaveta e o ecrã de Perfil.

#### [MODIFY] [app_drawer.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/shared/widgets/app_drawer.dart)
- Remover o seletor de perfil no `DrawerHeaderWidget`.
- Substituir etiquetas dinâmicas ("Disciplinas" vs "Projetos") por uma nomenclatura única e profissional.

#### [MODIFY] [profile_screen.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/auth/views/profile_screen.dart)
- Adicionar campos de edição para Bio, Instituição e Especialidades.
- Adicionar seletor de "Cor Favorita" (para personalizar a UI).

## Verification Plan

### Automated Tests
- Verificar se o `UserModel.fromJson` lida corretamente com os novos campos nulos.
- Validar se a migração 18 da base de dados não causa perda de dados existentes.

### Manual Verification
- Fazer logout e login para garantir que os dados persistidos no servidor (Laravel) são recuperados.
- Abrir a gaveta e verificar se a seleção de perfil desapareceu.
- Mudar a "Cor Favorita" no perfil e ver se a cor primária da app muda instantaneamente.
