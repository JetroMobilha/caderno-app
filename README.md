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

### 🖌️ Canvas Inteligente (Motor de Interação de Alta Fidelidade)
O coração do SyncScribe, redesenhado para oferecer uma experiência de escrita manual comparável a apps profissionais como Procreate e Notability:

*   **Inteligência Cinética de Arbitragem (Arena de Palmas v2):**
    *   **Duelo de Intenções:** Sistema de "Rei e Desafiantes" que permite que múltiplos pontos (dedo e palma) desenhem instantaneamente para garantir latência zero.
    *   **Golpe de Estado Cinético:** Algoritmo que avalia a velocidade, linearidade e distância (Score) de cada toque. Se o sistema deteta que um "Desafiante" é um dedo de escrita e o "Rei" atual é uma palma, o trono é trocado e a linha da palma é apagada instantaneamente sem rasto.
    *   **Consolidação por Movimento:** Um toque só é validado como "Sénior" (imune) após provar intenção real de desenho (60px de movimento fluido), eliminando o "vício" no primeiro toque.
*   **Gestão Avançada de Hardware:**
    *   **Prioridade Absoluta:** Stylus (Caneta) e Mouse possuem autoridade máxima, "roubando" o foco do desenho de qualquer toque de dedo no momento do contacto.
    *   **Navegação Blindada (3 Dedos):** Para evitar que o apoio da mão mova a folha, o Zoom e o Pan exigem **3 dedos simultâneos**. Toques de 1 ou 2 dedos são reservados exclusivamente para desenho e interação com objetos.
    *   **Isolamento Multi-ID:** Cada ponto de contacto possui um canal de dados independente, garantindo que o sistema nunca misture pontos de dedos diferentes.
*   **Expressividade Artística:**
    *   **Pincéis Realistas:** Mais de 12 tipos de pontas, incluindo *Gel, Fountain (Caneta de Tinteiro), Neon, Watercolor, Crayon e Airbrush*.
    *   **Motor Live de Latência Zero:** Utiliza buffers mutáveis isolados para renderizar traços em milissegundos, ignorando a latência da árvore de widgets do Flutter.
*   **Edição de Objetos e Texto:**
    *   **Editor WYSIWYG:** Suporte total a formatação rica, fontes Google Fonts e listas inteligentes.
    *   **Tabelas Dinâmicas:** Lógica avançada de união de células (Merge/Span) e redimensionamento tátil de alta precisão.
    *   **Modo de Transformação Declarativo:** Sistema de proteção que exige ativação explícita para mover ou redimensionar objetos, evitando erros durante a escrita.
*   **Tecnologia de Apagamento Híbrido:**
    *   **Borracha Mágica (Objetos):** Remove instantaneamente objetos inteiros (traços, tabelas, imagens) ao contacto, com suporte inteligente a eliminação de grupos selecionados.
    *   **Borracha de Precisão (Pixels):** Apaga segmentos específicos de traços através de um motor de fragmentação de curvas de Bezier em tempo real.
    *   **Feedback Visual Dinâmico:** Cursor circular com mira central que reflete exatamente a área de atuação da borracha de pixels.
    *   **Espessura Variável:** Controlo total sobre o diâmetro de apagamento (1px a 30px), independente da espessura da caneta.
    *   **Limpeza de Página:** Função de "Vassoura" que limpa a folha inteira instantaneamente, preservando o histórico para recuperação (Undo).


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
