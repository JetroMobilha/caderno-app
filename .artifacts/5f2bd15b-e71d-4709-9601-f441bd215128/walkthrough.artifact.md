# Walkthrough - Acesso Contextual à Lixeira

Separei o acesso à lixeira para pastas (Subjects) e cadernos (Notebooks), colocando os botões nos seus respetivos contextos para uma navegação mais intuitiva.

## Alterações Realizadas

### 1. Lixeira Contextual
- **[TrashScreen](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/trash/views/trash_screen.dart)**:
    - Adicionado suporte a `initialTabIndex`. Agora é possível abrir a lixeira diretamente no separador de "Pastas" ou "Cadernos".

### 2. Gestão de Pastas (Drawer)
- **[DrawerSubjectsList](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/shared/widgets/drawer/drawer_subjects_list.dart)**:
    - Removido o item de menu "Lixeira" global que ficava no fundo do menu.
    - Adicionado um novo botão de lixeira (vermelho) no cabeçalho das pastas, ao lado dos botões de arquivo e adição.
    - Ao clicar, abre a lixeira focada em **Pastas**.

### 3. Gestão de Cadernos
- **[NotebooksListScreen](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/notebooks/views/notebooks_list_screen.dart)**:
    - Adicionado um botão de lixeira no `AppBar`, ao lado do botão de arquivo.
    - Ao clicar, abre a lixeira focada em **Cadernos**.

## Verificação

- **Navegação**: O acesso à lixeira é agora mais rápido e contextual. Se o utilizador está a gerir cadernos, o botão de lixo leva-o diretamente aos cadernos apagados.
- **UI**: Os botões estão agrupados de forma lógica (Lixo, Arquivo, Adição), mantendo a interface limpa e organizada.
