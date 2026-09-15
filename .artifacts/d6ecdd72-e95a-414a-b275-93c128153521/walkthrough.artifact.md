# Walkthrough - Restauração e Persistência de Imagens (v10.35)

Corrigimos a falha estrutural que causava o desaparecimento de imagens, garantindo que o novo sistema de recorte é persistente e robusto.

## Mudanças Principais

### 1. Evolução do Esquema (Database v32)
- **Suporte Nativo a Recorte**: A base de dados SQLite agora possui uma coluna dedicada para armazenar as coordenadas de corte de cada imagem. Isto resolve o erro de dessincronização que impedia a gravação de novos ficheiros.
- **Migração Transparente**: O sistema atualiza-se automaticamente ao iniciar, preservando todos os cadernos e notas existentes.

### 2. Ciclo de Vida do Objeto Completo
- **Metadados Preservados**: Refinámos o serviço de base de dados para garantir que propriedades como 'Bloqueio' (Lock), 'Visibilidade' e 'Pai do Grupo' são lidas corretamente do disco.

## Resultados
- **Estabilidade Restaurada**: A inserção de imagens via galeria ou câmara volta a funcionar a 100%.
- **Edição Duradoura**: Os recortes imersivos criados na versão v10.34 agora sobrevivem ao encerramento da aplicação.

> [!IMPORTANT]
> Se tinhas imagens que desapareceram na versão anterior, elas deverão reaparecer agora. Caso contrário, podes inseri-las novamente com a garantia de que ficarão guardadas permanentemente!
