# Guia de Implementação: Laravel (Identidade de Páginas)

Para que a nova lógica de `clientId` funcione em pleno, o servidor Laravel precisa de suportar o armazenamento e a reconciliação baseada neste UUID.

## 1. Base de Dados (Migration)

Deve adicionar a coluna `client_id` à tabela `pages`. Recomenda-se que seja única dentro do contexto da aplicação (ou pelo menos indexada para performance).

```php
// No terminal: php artisan make:migration add_client_id_to_pages_table

public function up()
{
    Schema::table('pages', function (Blueprint $table) {
        $table->string('client_id')->nullable()->after('notebook_id')->index();
    });
}
```

## 2. Modelo (Model)

Atualize o modelo `Page.php` para permitir o preenchimento em massa (mass assignment).

```php
class Page extends Model
{
    protected $fillable = [
        'notebook_id',
        'page_number',
        'client_id', // 🆔 Adicionar aqui
        'header_data',
        'footer_data',
        'is_landscape',
        // ... outros campos
    ];
}
```

## 3. Lógica de Sincronização (Controller)

O ponto mais crítico é o **Push**. Em vez de procurar uma página apenas pelo número, deve usar o `client_id` como chave primária de reconciliação.

### No método de Push (ex: `SyncController@pushPages`):

```php
foreach ($request->pages as $pageData) {
    // 🚀 A MÁGICA: Tenta encontrar pelo clientId global
    $page = Page::where('client_id', $pageData['client_id'])->first();

    if (!$page) {
        // Se não existir pelo clientId, cria uma nova
        $page = new Page();
        $page->client_id = $pageData['client_id'];
    }

    // Atualiza os dados (Last-Write-Wins pode ser aplicado aqui também)
    $page->notebook_id = $pageData['notebook_id'];
    $page->page_number = $pageData['page_number'];
    $page->header_data = $pageData['header_data'];
    $page->footer_data = $pageData['footer_data'];
    $page->is_landscape = $pageData['is_landscape'];
    $page->updated_at = now(); // Ou o timestamp enviado pela app
    $page->save();
}
```

### No método de Pull:
Garanta que o `client_id` é devolvido no JSON para que as apps consigam mapear os dados do servidor de volta para os seus objetos locais.

```php
public function pullPages()
{
    $pages = Page::where(...)
        ->select('id', 'client_id', 'notebook_id', 'page_number', ...)
        ->get();

    return response()->json([
        'pages' => $pages,
        'server_time' => now()
    ]);
}
```

## Porquê isto é vital?
1.  **Deduplicação:** Se dois utilizadores criarem a "Página 1" offline, eles terão UUIDs diferentes. O servidor criará duas páginas.
2.  **Fusão:** Se eles estiverem a editar a **mesma** página (mesmo UUID), o servidor apenas atualizará o registo existente, mantendo a integridade do caderno.
