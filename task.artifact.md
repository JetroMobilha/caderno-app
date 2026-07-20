# Tarefas: Otimização de Imagens (Upload-then-Signal)

- [ ] `[/]` Implementar upload de imagem no Repository
    - [ ] Criar método `uploadImage` no `CanvasRepository`
    - [ ] Configurar cabeçalhos Multipart e Sanctum
- [ ] `[ ]` Atualizar lógica de inserção no Controller
    - [ ] Modificar `pickAndInsertImage` para realizar upload
    - [ ] Adicionar feedback de carregamento
- [ ] `[ ]` Otimizar sinais de Realtime
    - [ ] Remover Base64 do modelo `ImageBlock`
    - [ ] Atualizar broadcast para enviar apenas URLs remotos
- [ ] `[ ]` Verificação e Testes
