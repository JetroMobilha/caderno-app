# 📱 SyncScribe - Caderno Digital Inteligente

Um ecossistema de produtividade focado em escrita manual fluida, colaboração em tempo real e persistência resiliente. O SyncScribe emula a experiência de um caderno físico com o poder da nuvem.

## 🚀 Stack Tecnológica de Elite

*   **Frontend:** Flutter (3.24+) - Interface fluida e responsiva para Mobile e Web.
*   **Persistência Reativa:** [Drift (WASM)](https://drift.simonbinder.eu/) - Banco de dados SQL v26 com reatividade nativa e suporte total a WebAssembly.
*   **Gestão de Estado:** Riverpod 2.0 - Arquitetura desacoplada e testável.
*   **Colaboração Real-time:** Laravel Reverb (WebSockets) - Sincronização de traços e conteúdo em milissegundos.
*   **Motor de Áudio:** WebRTC P2P - Chamadas de voz integradas para estudo em grupo.
*   **Backend:** Laravel 11 (PHP) - API robusta com MySQL e Redis.

---

## ✨ Funcionalidades Principais

### 📂 Gestão de Estrutura e Organização
O SyncScribe oferece uma hierarquia clara para organizar o conhecimento:
*   **Pastas (Subjects):** Personalização total com 24 ícones temáticos e 48 cores profissionais.
*   **Cadernos (Notebooks):** 14 modelos profissionais pré-configurados:
    *   *Académico:* Escolar, Universitário, Estudo (Layout versátil).
    *   *Técnico:* Engenharia (Milimetrado/Isométrico), Contabilidade, Laboratório (STEM).
    *   *Criativo:* Desenho (A3/Livre), Música (Pentagramas).
    *   *Gestão:* Agenda, Projeto, Reunião.
    *   *Pessoal:* Diário, Em Branco, Personalizado.
*   **Organização Inteligente:** Sistema de **Etiquetas (Tags)** transversais, **Favoritos** e **Arquivamento** de pastas e cadernos.

### 🎨 Motor de Cores Profissional (Color Engine v2)
Uma ferramenta de design independente integrada em toda a aplicação:
*   **Presets de Elite:** 48 cores organizadas por gradientes tonais para escolhas rápidas.
*   **Estúdio HSV:** Seletor visual tátil para ajustar Matiz, Saturação e Brilho sem necessidade de conhecimentos técnicos (sem códigos hexadecimais).
*   **Memória de Sessão:** Lembra-se automaticamente das cores e categorias usadas recentemente.

### 🪄 Assistente de Criação (Wizard) com Print-Fidelity
Experiência de criação otimizada com foco na fidelidade física:
*   **Criação Rápida vs. Personalizada:** Gere um caderno em 2 cliques ou ajuste cada detalhe técnico.
*   **Tecnologia Print-Fidelity:** Pré-visualização baseada em milímetros reais (WYSIWYG). O que vê no ecrã é exatamente o que terá na impressão ou PDF.
*   **Formatos ISO (A0 a A5):** Suporte total desde o pequeno A5 até posters técnicos A0 (841 x 1189 mm).
*   **Zoom Interativo:** Inspeção detalhada do papel com recorte visual (clipping) garantido.

### ♻️ Resiliência e Gestão de Ficheiros
Segurança máxima para os seus dados:
*   **Soft Deletion (Lixeira):** Sistema de eliminação em dois níveis. Itens apagados podem ser restaurados a qualquer momento até à limpeza definitiva da lixeira.
*   **Gestão de Media:** Armazenamento local eficiente de imagens e gravações de áudio, com sincronização em background para o servidor Laravel.
*   **Motor Offline-First:** Sincronização diferencial (Delta-Sync) inteligente que funciona sem interrupções, mesmo com conectividade instável.

### 🛒 Marketplace de Conhecimento
Ecossistema de partilha e monetização:
*   **Publicação:** Disponibilize cadernos na loja com sinopse, preço e nome de autor.
*   **Aquisição Server-Side:** A clonagem de cadernos é processada no servidor para garantir integridade absoluta em múltiplos dispositivos.
*   **Sincronização Automática:** Cadernos adquiridos aparecem instantaneamente na pasta "Matérias Adquiridas 🛒" via motor de sync.

---

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

# Executar o projeto (Mobile/Desktop)
flutter run
```

### Executar em WebAssembly (WASM)
O SyncScribe utiliza o novo motor WASM do Flutter para performance máxima no browser.
```bash
flutter run -d chrome --wasm
```

### Executar Testes
```bash
flutter test
```

## 📚 Documentação Adicional
A arquitetura detalhada, esquemas de base de dados e diagramas de sequência podem ser encontrados na [Wiki do Projeto](https://github.com/JetroMobilha/caderno--backend/wiki).

---
Desenvolvido com ❤️ por Jetro Mobilha e equipa.
