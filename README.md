# 📱 SyncScribe - Caderno Digital Inteligente

Um ecossistema de produtividade focado em escrita manual fluida, colaboração em tempo real e persistência resiliente. O SyncScribe emula a experiência de um caderno físico com o poder da nuvem.

## 🚀 Stack Tecnológica de Elite

*   **Frontend:** Flutter (3.24+) - Interface fluida e responsiva para Mobile e Web.
*   **Persistência Reativa:** [Drift (WASM)](https://drift.simonbinder.eu/) - Banco de dados SQL com reatividade nativa e suporte total a WebAssembly.
*   **Gestão de Estado:** Riverpod 2.0 - Arquitetura desacoplada e modular.
*   **Colaboração Real-time:** Laravel Reverb (WebSockets) - Sincronização de traços e conteúdo em milissegundos.
*   **Backend:** Laravel 11 (PHP) - API robusta com MySQL e Redis.

---

## ✨ Funcionalidades Implementadas

### 🔐 Autenticação e Segurança
*   **Sistema de Login:** Acesso seguro com gestão de estado de sessão via Riverpod.
*   **Sincronização de Perfil:** Dados de utilizador integrados com o ecossistema cloud.

### 📂 Gestão de Estrutura e Organização
*   **Matérias (Subjects):** Personalização total com ícones temáticos e paletas de cores profissionais.
*   **Cadernos (Notebooks):** 14 modelos profissionais (Académico, Técnico, Criativo, Gestão, Pessoal).
*   **Páginas:** Gestão dinâmica de folhas com suporte a diferentes estilos de papel (pautado, quadriculado, pontilhado).
*   **Resiliência de Dados:**
    *   **Soft Delete (Lixeira):** Sistema de eliminação em dois níveis para evitar perda acidental de dados.
    *   **Arquivo:** Possibilidade de arquivar matérias e cadernos antigos para manter o foco no presente.

### 🖌️ Canvas Inteligente (Motor de Edição)
O coração do SyncScribe, focado em precisão e ergonomia:
*   **Escrita e Desenho:** Pincéis realistas (Gel, Caneta, Marcador) com suavização de traço via curvas de Bezier.
*   **Blocos de Texto:** Editor WYSIWYG com suporte a negrito, itálico, cores, tipos de letra e listas dinâmicas (bullets, numeradas e checklists).
*   **Tabelas Complexas:**
    *   Criação dinâmica de linhas e colunas.
    *   **União de Células (Merge):** Lógica avançada de spans que permite criar layouts de dados complexos.
    *   Redimensionamento individual de colunas e linhas.
*   **Modo de Transformação Declarativo:** Sistema de proteção que "tranca" o conteúdo durante a edição, exigindo uma ativação explícita para mover ou redimensionar objetos, evitando erros de precisão tátil.
*   **Navegação Multi-Toque (v7.5):** Detecção inteligente de dedos que prioriza automaticamente o Zoom e Pan quando dois ou mais dedos tocam no ecrã, garantindo que o desenho nunca interfira na navegação.

### 🎨 Motor de Cores (Color Engine v2)
*   **Estúdio HSV:** Seletor visual tátil para ajuste fino de Matiz, Saturação e Brilho.
*   **Presets de Elite:** Cores organizadas por gradientes tonais para escolhas rápidas e harmoniosas.

### 🪄 Assistente de Criação (Wizard)
*   **Tecnologia Print-Fidelity:** Pré-visualização baseada em milímetros reais (A0 a A5). O que vê no ecrã é o que terá na impressão.

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
O SyncScribe utiliza o motor WASM para performance máxima.
```bash
flutter run -d chrome --wasm
```

---
Desenvolvido com ❤️ por Jetro Mobilha e equipa.
