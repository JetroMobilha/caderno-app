# Guia de Testes: Funcionalidades do Canvas e Colaboração

Utilize este roteiro para validar todas as melhorias implementadas antes de prosseguir para novas funcionalidades.

## 1. Desenho e Sincronização (Ink)
- [ ] **Teste de Ghost Stroke:** Desenhe formas fechadas (círculos) em dois dispositivos. Verifique se a linha reta final desapareceu.
- [ ] **Throttling:** Desenhe lentamente e verifique se o traço aparece fluido no outro dispositivo.

## 2. Ferramenta de Seleção e Borracha
- [ ] **Seleção de Imagens:** Tente selecionar uma imagem arrastando o retângulo de seleção. Verifique a borda azul.
- [ ] **Seleção Mista:** Selecione um traço, um texto e uma imagem ao mesmo tempo. Mova-os em conjunto.
- [ ] **Borracha "Apaga Tudo":** Com itens selecionados, clique na ferramenta Borracha (`Icons.auto_fix_high`). Verifique se a seleção foi eliminada.

## 3. Imagens e Fluidez
- [ ] **Movimentação Remota:** Peça a um colega para mover uma imagem. Verifique se ela desliza suavemente (`AnimatedPositioned`).
- [ ] **Botão Remover (X):** No modo "Editar Imagem", clique no botão (X) vermelho. A imagem deve ser removida imediatamente.
- [ ] **Z-Index:** Verifique se o botão (X) funciona mesmo que existam traços de tinta por cima da imagem.

## 4. Sistema de Undo/Redo (Histórico)
- [ ] **Undo de Deleção:** Apague a seleção com a borracha e clique em Undo. Todos os itens (incluindo imagens) devem voltar.
- [ ] **Undo Individual:** Desenhe um traço e desfaça. Apenas esse traço deve sumir.
- [ ] **Redo:** Refaça uma ação e verifique se ela é refletida nos colegas (broadcast do redo).

## 5. Colaboração e Presença
- [ ] **Entrada na Sala:** Observe a "Trava de Alinhamento" (*A alinhar caderno...*) ao entrar numa sessão ativa.
- [ ] **Saída de Utilizador:** Feche a app num dispositivo e verifique se o avatar some instantaneamente no cockpit do outro.
- [ ] **Auto-vigília:** Tente clicar no seu próprio avatar no cockpit. A ação deve ser ignorada (não pode seguir-se a si próprio).

## 6. Interface e Layout
- [ ] **Ecrãs Grandes:** Abra o Centro de Colaboração num tablet ou simulador de PC. Verifique se os botões têm espaçamento adequado.
- [ ] **Responsive Spacing:** Verifique se o campo de e-mail e o botão "Convidar" no modal de partilha não estão sobrepostos.
