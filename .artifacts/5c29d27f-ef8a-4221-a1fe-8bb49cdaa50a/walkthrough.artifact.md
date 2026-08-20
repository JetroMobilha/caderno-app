# Walkthrough - Resiliência Offline e Colaboração Estruturada

Realizamos uma refatoração profunda para alinhar a aplicação com a filosofia **Offline-First**, otimizando a experiência para ambientes com internet instável (como Angola) e garantindo a ordem em salas colaborativas.

## Alterações Realizadas

### 🏗️ Gestão de Estrutura Server-Authoritative
No modo de colaboração, o servidor agora é o orquestrador. Isso evita que diferentes utilizadores tenham versões diferentes do caderno.
- [CanvasController](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/controllers/canvas_controller.dart): Refatorados `addNewPage` e `deletePage`.
- **Modo Colaboração:** Aguarda confirmação do servidor para garantir consistência global.

### 🎙️ Live Audio com Permissões e Voz Instantânea
Implementamos um sistema de controle de voz para evitar ruído e otimizámos a velocidade.
- **Voz Instantânea (1.0s):** Reduzimos a latência para o mínimo possível. A voz é transmitida em pacotes de 1 segundo, eliminando atrasos.
- **Permissões:** Apenas o dono, editores ou utilizadores autorizados podem transmitir áudio.

### 📖 Navegação e Gestão de Páginas
Melhorámos significativamente a forma como o utilizador interage com a estrutura do caderno.
- **Botão "Ver Páginas" na Toolbar:** Atalho rápido na barra de ferramentas principal para abrir a lista de folhas.
- **Drawer Premium:** Gaveta de páginas redesenhada com cabeçalho elegante, contador de folhas e metadados detalhados (ex: A4 • Pautada).
- **Indicador de Folha na AppBar:** Exibição clara de `Folha X / Y`.

### ☁️ Sincronização Resiliente (Estratégia Angola)
Otimizamos o tráfego de dados e a recuperação de falhas.
- **Background Sync:** Timer que sincroniza dados pendentes a cada 2 minutos se houver rede.
- **Upload com Retry Exponencial:** Retentativa inteligente para falhas de upload.
- **Media Offline-First:** Imagens guardadas localmente de imediato e carregadas em background.
- **Feedback Visual:** Ícone de nuvem na AppBar (🟢 Sincronizado, 🟠 Local).

## Como Verificar

1.  **Modo Offline:** Desligue a internet e use o caderno normalmente. Verifique o ícone laranja na AppBar.
2.  **Modo Colaboração:** Tente apagar uma página sem rede. A app deverá informar que a rede é necessária.
3.  **Voz:** Use dois aparelhos e note a rapidez da fala (intervalos de 1s).
4.  **Paginação:** Use o botão de páginas na Toolbar para navegar entre folhas.

> [!TIP]
> Esta arquitetura garante que o SyncScribe seja uma ferramenta de trabalho confiável mesmo em cenários de conectividade zero, transformando-se numa plataforma colaborativa poderosa assim que o sinal regressa.
