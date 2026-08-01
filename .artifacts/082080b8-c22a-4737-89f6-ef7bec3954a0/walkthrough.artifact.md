# Resumo das Melhorias no Canvas e Colaboração

Implementamos uma série de melhorias para tornar o Canvas mais limpo, intuitivo e eficiente para o trabalho em equipa.

## Mudanças Realizadas

### 1. Navegação Simplificada e Informativa
- **Título do Caderno**: Agora, clicar no título do caderno no topo do ecrã abre diretamente o menu lateral de folhas.
- **Contador de Páginas**: O título agora mostra em que folha estás e o total de folhas (ex: `Título (1/5)`), e está fixado à esquerda para facilitar a leitura.
- **Menu Lateral**: Isso elimina a navegação duplicada e oferece uma experiência mais elegante para alternar entre páginas.

### 2. Colaboração Imersiva
- **Centro de Colaboração**: O layout foi otimizado para dar mais destaque às ações principais: "Iniciar Estudo Live" e "Transmitir Visão".
- **Remoção do "Pedir Palavra"**: O sistema de levantar a mão foi removido de todos os menus (Centro de Colaboração e Cockpit de Voz) para simplificar o fluxo de trabalho.
- **Identidade Visual**: Removida a etiqueta laranja "Dono" no modal de partilha, tornando a lista de colaboradores mais limpa.

### 3. Melhorias nas Ferramentas
- **Borracha Inteligente**: Agora podes selecionar vários itens e, ao tocar neles com a borracha, todos são apagados de uma vez. A ferramenta de borracha já não limpa a tua seleção automaticamente ao ser ativada.
- **Gestão de Imagens**:
    - **Placeholder Dinâmico**: Enquanto uma imagem está a ser carregada, aparece um retângulo tracejado que delimita o espaço onde a imagem ficará.
    - **Sincronização em Tempo Real**: Podes mover e redimensionar a imagem mesmo enquanto ela está em upload, e os teus colegas verão essas mudanças instantaneamente.
    - **Recuperação de Falhas**: Se o upload de uma imagem falhar devido à internet, aparecerá um botão "Repetir" diretamente sobre a imagem para tentares novamente.

## Verificação Técnica
- [x] Correção de erros de sintaxe no `canvas_screen.dart`.
- [x] Limpeza de parâmetros não utilizados no `live_voice_cockpit.dart`.
- [x] Validação da lógica de estado no `canvas_controller.dart`.

> [!TIP]
> Experimenta selecionar um conjunto de desenhos e usar a borracha para ver a nova funcionalidade de "apagar em massa" em ação!
