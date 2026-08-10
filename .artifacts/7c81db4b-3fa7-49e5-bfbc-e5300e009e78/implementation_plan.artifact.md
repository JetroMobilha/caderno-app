# Plano de Implementação: Otimização de Undo/Redo e "Rasgar Folhas"

Este plano visa elevar a qualidade da experiência de edição no Canvas, implementando a função de "Rasgar Folhas" com suporte a Undo e otimizando o motor de histórico de ações.

## 1. Função "Rasgar Folhas" (Page Deletion)
**Objetivo**: Transformar a remoção de páginas numa ação natural, segura e reversível.

### Mudanças Propostas:
- **Ação Reversível**: Criar a classe `DeletePageAction` no motor de Undo. Ao "rasgar", a página não é destruída imediatamente, mas marcada como `isDeleted` e movida para o histórico.
- **Animação de Feedback**: Implementar um efeito visual (ex: slide para cima/fora ou fade agressivo) e um som opcional de papel a rasgar.
- **Re-indexação Inteligente**: Ao apagar a página 2 de 5, as páginas 3, 4 e 5 são re-numeradas automaticamente, mas o Undo restaura a ordem original.

## 2. Otimização do Motor de Undo/Redo
**Objetivo**: Seguir as melhores práticas de arquitetura de comandos (Command Pattern) e gestão de memória.

### Melhorias Técnicas:
- **Ações de Página no Histórico**: Unificar as ações de desenho (strokes/texto) com as ações de estrutura (adicionar/apagar folha) numa única stack cronológica.
- **Agrupamento de Comandos (Transactions)**: Garantir que ações complexas (ex: apagar vários objetos e a folha ao mesmo tempo) sejam tratadas como uma única entrada no Undo.
- **Gestão de Memória**: A stack de Undo guardará apenas os metadados necessários para reconstruir o estado, evitando retenção excessiva de memória em cadernos muito longos.
- **Sincronização de Efeito**: Ao desfazer uma ação localmente, o aplicativo enviará o sinal de correção correspondente para os colegas (ex: se desfiz uma borracha, o objeto reaparece para todos).

## 3. Estratégia Offline-First
- O "lixo" de páginas rasgadas será mantido localmente por tempo limitado (ex: até fechar o caderno) para permitir Undo imediato sem rede.
- A sincronização da "deleção" com o servidor Laravel será feita em background, respeitando a ordem das ações.

---

## Proposta de Alterações

### [Componente: Mobile - Comandos]

#### [MODIFY] [canvas_action_model.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/models/canvas_action_model.dart)
- Adicionar `DeletePageAction`.
- Adicionar `AddPageAction`.

### [Componente: Mobile - Controlador]

#### [MODIFY] [canvas_controller.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/controllers/canvas_controller.dart)
- Refatorar `addNewPage` e `deletePage` para usarem o sistema de `_executeAction`.
- Integrar a stack de Undo com as mudanças de estrutura de páginas.

### [Componente: Mobile - UI]

#### [MODIFY] [canvas_screen.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/views/canvas_screen.dart)
- Adicionar o feedback visual ao disparar a remoção de página.

## Plano de Verificação

### Testes Manuais
1. Desenhar algo na página 2.
2. Rasgar a página 2.
3. Clicar em "Desfazer" e verificar se a página 2 volta com o desenho intacto.
4. Rasgar a página, fechar o app, abrir e verificar se a re-indexação foi persistida.

---

**Desejas que implemente este motor de Undo unificado e a função de rasgar folhas agora?**
