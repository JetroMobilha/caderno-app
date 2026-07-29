# Visão Geral do Projeto: Caderno Digital

Este projeto é um aplicativo de **Caderno Digital** desenvolvido em Flutter, projetado para oferecer uma experiência de escrita e desenho digital com suporte a colaboração em tempo real e reconhecimento de escrita manual.

## 🚀 Tecnologias Principais

| Categoria | Tecnologia |
| :--- | :--- |
| **Framework** | Flutter |
| **Gerência de Estado** | Riverpod |
| **Banco de Dados Local** | Drift (SQLite) - Offline-first |
| **Tempo Real** | Pusher (via `dart_pusher_channels`) |
| **Comunicação de Voz** | WebRTC (`flutter_webrtc`) |
| **IA / OCR** | Google ML Kit (Digital Ink Recognition) |
| **Armazenamento Seguro** | Flutter Secure Storage |

## 📂 Estrutura do Projeto (`lib/`)

O projeto segue uma arquitetura modular baseada em funcionalidades (`features`):

- **`core/`**: Infraestrutura básica.
  - `database/`: Definição do banco de dados Drift (`app_database.dart`).
  - `network/`: Serviços de sincronização, tempo real e WebRTC.
  - `services/`: OCR e outros serviços utilitários.
  - `theme/`: Estilização global do app.
- **`features/`**: Funcionalidades específicas do usuário.
  - **`canvas/`**: O "coração" do app. Gerencia traços (`Stroke`), blocos de texto, imagens e a lógica de colaboração na folha.
  - **`notebooks/`**: Gestão de cadernos.
  - **`subjects/`**: Organização por disciplinas.
  - **`auth/`**: Fluxos de login e registro.
  - **`agenda/`** & **`marketplace/`**: Funcionalidades adicionais de calendário e recursos.

## 🎨 Funcionalidades em Destaque no Canvas

- **Colaboração em Tempo Real**: Múltiplos usuários podem desenhar na mesma página simultaneamente.
- **Sincronização Adaptativa**: Suporte para seguir a tela de outro usuário (`follow user`) com transições suaves.
- **Offline-First**: Os dados são salvos localmente no SQLite primeiro e sincronizados com a nuvem quando há conexão.
- **OCR Integrado**: Transforma escrita manual em texto pesquisável em segundo plano.
- **Suporte Multimídia**: Inserção de imagens e blocos de texto dinâmicos.

## 🛠️ Fluxos de Trabalho Atuais
Estamos trabalhando no refinamento do `CanvasController`, garantindo a robustez da sincronização de traços e a correta manipulação de estados de colaboração.
