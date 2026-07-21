# 📱 SyncScribe - Caderno Digital Inteligente

Um ecossistema de produtividade focado em escrita manual fluida, colaboração em tempo real e persistência resiliente. O SyncScribe emula a experiência de um caderno físico com o poder da nuvem.

## 🚀 Stack Tecnológica de Elite

*   **Frontend:** Flutter (3.24+) - Interface fluida e responsiva para Mobile e Web.
*   **Persistência Reativa:** [Drift (WASM)](https://drift.simonbinder.eu/) - Banco de dados SQL de alta performance com reatividade nativa e suporte total a WebAssembly.
*   **Gestão de Estado:** Riverpod 2.0 - Arquitetura desacoplada e testável.
*   **Colaboração Real-time:** Laravel Reverb (WebSockets) - Sincronização de traços e conteúdo em milissegundos.
*   **Motor de Áudio:** WebRTC P2P - Chamadas de voz integradas para estudo em grupo.
*   **Backend:** Laravel 11 (PHP) - API robusta e escalável.

## ✨ Funcionalidades Principais

### 🎨 Canvas Vetorial Infinito
*   Escrita manual de baixa latência.
*   Suporte a blocos de texto e imagens.
*   Múltiplos tamanhos de folha (A0 a A5) e estilos de pauta (Pautado, Quadriculado, Liso).

### ☁️ Sincronização Inteligente (Delta-Sync)
*   **Motor Offline-First:** Trabalhe sem internet; os dados são sincronizados automaticamente assim que a conexão volta.
*   **Eficiência de Dados:** O sistema utiliza sincronização diferencial (Delta), baixando apenas o que mudou para poupar a bateria e os dados do utilizador.
*   **Batch Processing:** Ingestão de dados em massa para performance máxima durante o PULL inicial.

### 🤝 Colaboração de Luxo
*   **Multi-utilizador:** Vários utilizadores na mesma folha em simultâneo.
*   **Assistência em Direto:** Siga a visão de um professor ou colega (Viewport Follow).
*   **Voz Integrada:** Estude e discuta conteúdos sem sair da app.

### 🛒 Marketplace de Conhecimento
*   Publique os seus cadernos na loja.
*   Adquira cadernos de autores renomados ou colegas.

## 🛠️ Como Instalar o Projeto

### Pré-requisitos
*   Flutter SDK (Canal Stable).
*   Dart SDK.
*   `sqlite3.wasm` e `drift_worker.js` na pasta `web/` (Para suporte Web).

### Comandos Iniciais
```bash
# Instalar dependências
flutter pub get

# Gerar código do banco de dados (Drift) e modelos
dart run build_runner build --delete-conflicting-outputs

# Executar o projeto
flutter run
```

### Executar Testes
```bash
flutter test
```

## 📚 Documentação Adicional
A arquitetura detalhada e os diagramas de sequência podem ser encontrados na [Wiki do Projeto](https://github.com/JetroMobilha/caderno--backend/wiki).

---
Desenvolvido com ❤️ por Jetro Mobilha e equipa.
