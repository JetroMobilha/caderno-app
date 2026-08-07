# Guia de Implementação: Sincronização v7 (Relógios Lógicos)

Este documento contém as instruções para o agente do servidor (Laravel/PHP) atualizar a API e o banco de dados para suportar a arquitetura de **Relógios Lógicos (Lamport Clocks)** e o **Espaçamento Dinâmico**.

## 1. Migração de Banco de Dados

Crie uma migração para adicionar as colunas `line_spacing` e `version` às tabelas principais.

```php
// database/migrations/xxxx_xx_xx_update_sync_architecture_v7.php

public function up()
{
    // 1. Notebooks
    Schema::table('notebooks', function (Blueprint $table) {
        if (!Schema::hasColumn('notebooks', 'line_spacing')) {
            $table->decimal('line_spacing', 5, 2)->nullable()->default(28.00);
        }
        $table->bigInteger('version')->default(1);
    });

    // 2. Pages
    Schema::table('pages', function (Blueprint $table) {
        $table->bigInteger('version')->default(1);
    });

    // 3. Child Tables (Se existirem tabelas para strokes/texts/images individuais)
    // Se os dados estiverem em JSON na tabela 'pages', ignorar este passo.
    // Caso contrário, adicione a coluna 'version' a cada uma.
}
```

## 2. Modelos (Models)

Atualize os modelos `Notebook` e `Page` para incluir os novos campos e garantir que a versão é incrementada.

```php
// app/Models/Notebook.php e app/Models/Page.php

protected $fillable = [
    // ...
    'line_spacing',
    'version',
];
```

## 3. Lógica de Resolução de Conflitos (LWW Híbrido)

Ao receber um PUSH do cliente, o servidor deve utilizar a versão lógica como primeiro critério de desempate, seguido pelo timestamp físico.

### Requisito Crítico para Deleções (Tombstones):
O servidor **NUNCA** deve remover fisicamente um item se `is_deleted` for verdadeiro. Deve apenas marcar o registo como apagado e atualizar a sua versão/timestamp.

### Exemplo de Lógica no Controller (SyncController.php):

```php
public function pushPages(Request $request) {
    foreach ($request->pages as $incomingPage) {
        $localPage = Page::where('client_id', $incomingPage['client_id'])->first();

        if ($localPage) {
            // 🛡️ Regra de Ouro: Só atualizar se a versão recebida for maior
            // ou se for igual mas o timestamp for mais recente.
            $isIncomingNewer = ($incomingPage['version'] > $localPage->version) ||
                               ($incomingPage['version'] == $localPage->version &&
                                $incomingPage['updated_at'] > $localPage->updated_at);

            if ($isIncomingNewer) {
                $localPage->update([
                    'stroke_data' => $incomingPage['stroke_data'],
                    'text_data'   => $incomingPage['text_data'],
                    'image_data'  => $incomingPage['image_data'],
                    'version'     => $incomingPage['version'],
                    'updated_at'  => $incomingPage['updated_at'],
                    'deleted_at'  => $incomingPage['is_deleted'] ? now() : null,
                ]);
            }
        } else {
            // Criar nova página com a versão enviada pelo cliente
            Page::create($incomingPage);
        }
    }
}
```

## 4. Eventos em Tempo Real (Realtime)

Certifique-se de que o campo `version` é incluído nos payloads de broadcast. O servidor deve atuar apenas como um "relé" (pass-through), mas a validação de permissões deve garantir que o utilizador tem a role correta para o caderno.

> [!WARNING]
> Se o servidor interceptar e modificar dados (ex: sanitização), ele **deve** incrementar o campo `version` antes de enviar o broadcast aos outros clientes.

## 5. API Resources

Garanta que a `version` é retornada em todos os endpoints de `pull`.

```php
// app/Http/Resources/PageResource.php

public function toArray($request)
{
    return [
        'id' => $this->id,
        'client_id' => $this->client_id,
        'version' => (int) $this->version,
        'updated_at' => $this->updated_at,
        // ...
    ];
}
```
