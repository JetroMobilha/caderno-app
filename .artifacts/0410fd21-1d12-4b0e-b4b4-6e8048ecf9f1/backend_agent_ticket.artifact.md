# 🎫 Ticket de Engenharia: Alinhamento Global e Identidade de Páginas

**Contexto:** Estamos a estabilizar a sincronização do Caderno Digital para suportar colaboração em larga escala sem perdas de dados e sem "páginas fantasma". A aplicação Flutter já gera UUIDs (`client_id`) e Timestamps (`updated_at`) em milissegundos.

---

## 1. Base de Dados (Migrations)

Adicionar `client_id` à tabela `pages`. Este campo deve ser indexado para reconciliação rápida.

```php
public function up()
{
    Schema::table('pages', function (Blueprint $table) {
        // Identidade global para evitar duplicados em sync offline-to-online
        $table->string('client_id')->nullable()->after('notebook_id')->index();
        // Timestamp de alta precisão para resolução de conflitos (Last-Write-Wins)
        $table->bigInteger('updated_at_ms')->nullable()->after('client_id');
    });
}
```

## 2. Lógica do Modelo (`App\Models\Page.php`)

Atualizar o método de fusão de JSON para ser "sensível ao tempo". O servidor deve arbitrar qual alteração é a mais recente.

```php
public static function mergeJsonItems($oldData, $newItems)
{
    $oldItems = is_array($oldData) ? $oldData : json_decode($oldData, true) ?? [];
    $newItems = is_array($newItems) ? $newItems : json_decode($newItems, true) ?? [];

    $merged = collect($oldItems)->keyBy('id');

    foreach ($newItems as $newItem) {
        $id = $newItem['id'] ?? null;
        if (!$id) continue;

        if ($merged->has($id)) {
            $oldItem = $merged->get($id);
            // 🚀 REGRA LWW: O maior timestamp (milissegundos) vence.
            $oldTime = $oldItem['updated_at'] ?? 0;
            $newTime = $newItem['updated_at'] ?? 0;

            if ($newTime >= $oldTime) {
                $merged->put($id, $newItem);
            }
        } else {
            $merged->put($id, $newItem);
        }
    }

    return $merged->values()->all();
}
```

## 3. Controlador de Sincronização (`SyncController.php`)

O método `pushPages` deve abandonar a busca por `page_number` e priorizar o `client_id`.

### Requisitos do `pushPages`:
1.  **Reconciliação:** `Page::where('client_id', $data['client_id'])->firstOrNew(...)`.
2.  **Segurança (Roles):** Impedir `push` se o `user->role` for `viewer`. Só `owner` e `editor` escrevem no histórico persistente.
3.  **Soft Delete:** Se `is_deleted == 1` no payload, executar `$page->delete()` baseado no `client_id`.
4.  **Broadcast:** Após o save, disparar o evento `SyncRequested` ou similar para avisar os outros clientes (se houver WebSocket ativo).

### Requisitos do `pullPages`:
1.  **Integridade:** Incluir sempre o `client_id` no JSON de saída.
2.  **Performance:** Manter a paginação (50 itens) para evitar estouro de memória em cadernos com centenas de páginas.

---

## 4. Resumo para o Agente Backend
- [ ] Criar migration para `client_id` e `updated_at_ms`.
- [ ] Ajustar `fillable` no Model `Page`.
- [ ] Refatorar `mergeJsonItems` para comparar timestamps.
- [ ] Alterar `pushPages` no Controller para usar o UUID como âncora de busca.
- [ ] Validar permissões de escrita por Role (Owner/Editor vs Viewer).
