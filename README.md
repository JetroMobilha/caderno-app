# caderno--app

Um caderno digital focado em produtividade, permitindo escrita manual fluida, emulação de folhas reais e colaboração em tempo real.

## 🚀 Tecnologias Utilizadas
* Frontend: Flutter (Dart)
* Backend: Laravel (PHP) + Banco de Dados Relacional (MySQL/PostgreSQL)
* Colaboração em Tempo Real: Laravel Reverb (WebSockets)
* Reconhecimento de Escrita (OCR): Google ML Kit

## 🎯 Objetivos do MVP (Produto Mínimo Viável)
* Desenho livre e escrita manual num canvas otimizado.
* Criação e organização de disciplinas e cadernos.
* Sincronização em nuvem e funcionamento offline.
* Partilha de folhas em tempo real com outros utilizadores.

* # 📱 SyncScribe - Frontend (Flutter)

Este é o repositório da aplicação móvel.

📚 **Documentação Central**
Toda a documentação sobre como instalar o projeto, a arquitetura da base de dados e os endpoints da API encontra-se na Wiki principal do nosso Backend.
👉 [Clica aqui para aceder à Wiki do Projeto](https://github.com/JetroMobilha/caderno--backend/wiki)


## Fase 1: Setup e Autenticação (UI)

* Issue 1: Inicializar projeto Flutter, organizar arquitetura de pastas (ex: lib/features, lib/core) e limpar a app de contador padrão.

* Issue 2: Configurar um sistema de rotas (ex: biblioteca go_router).

* Issue 3: Configurar a biblioteca de gestão de estado (ex: Provider, Riverpod ou Bloc).

* Issue 4: Desenhar e programar a UI do ecrã de Login e Registo.

* Issue 5: Instalar o flutter_secure_storage para guardar o token do Sanctum localmente e de forma segura.

* Issue 6: Ligar o ecrã de Login/Registo à API do Laravel e implementar a lógica de sessão ativa.

## Fase 2: Gestão de Cadernos e Offline-First

* Issue 7: Desenhar e programar a UI da Dashboard (Lista de disciplinas e cadernos).

* Issue 8: Integrar a API do Laravel para buscar e exibir os cadernos do utilizador.

* Issue 9: Instalar e configurar uma base de dados local offline no Flutter (Isar ou Drift).

* Issue 10: Implementar lógica de caching: guardar os cadernos e disciplinas na base local para abrir a app sem internet.

* Issue 11: Desenhar o ecrã de "Criar Novo Caderno" com seletor de capas e cores.

## Fase 3: O Core do Projeto (O Canvas de Escrita)

* Issue 12: Criar a estrutura UI da "Folha" do caderno (App bar recolhível e paleta de ferramentas de desenho).

* Issue 13: Implementar o widget CustomPaint para criar a área de desenho livre.

* Issue 14: Criar a lógica para capturar os eventos de toque (PointerEvents) e desenhar linhas simples no ecrã.

* Issue 15: Adicionar seletor de cores, espessura do lápis e ferramenta de borracha à paleta.

* Issue 16: Converter os traços feitos no ecrã em objetos JSON locais (X, Y, cor, espessura) e guardá-los na base de dados offline (Isar/Drift).

## Fase 4: Sincronização e Magia

* Issue 17: Criar um serviço de "Sync" em background que deteta quando há internet e envia os traços novos (JSON) para a API do Laravel.

* Issue 18: Instalar o pacote laravel_echo no Flutter e configurar a ligação aos WebSockets do Laravel Reverb.

* Issue 19: Fazer o Flutter ouvir o evento StrokeCreated no WebSocket e redesenhar os traços que vêm de outros utilizadores na mesma folha.

* Issue 20: Investigar e adicionar a dependência do google_mlkit_digital_ink_recognition para preparar a funcionalidade de OCR (escrita para texto).