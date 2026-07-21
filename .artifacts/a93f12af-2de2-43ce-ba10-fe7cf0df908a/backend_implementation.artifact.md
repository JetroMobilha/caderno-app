# Guia de Implementação: Backend Laravel (IA & OCR)

Como o servidor Laravel está num projeto separado, segue este guia com o código necessário para suportar o Assistente IA e a Sincronização de OCR.

## 1. Base de Dados
Cria uma nova migração para adicionar a coluna `extracted_text` à tabela `pages`.

```php
// php artisan make:migration add_extracted_text_to_pages_table
public function up() {
    Schema::table('pages', function (Blueprint $table) {
        $table->text('extracted_text')->nullable()->after('footer_data');
    });
}
```

## 2. Modelo `Page.php`
Atualiza o array `$fillable` no ficheiro `app/Models/Page.php`.

```php
protected $fillable = [
    'notebook_id',
    'page_number',
    'is_landscape',
    'header_data',
    'footer_data',
    'extracted_text', // 🧠 Adicionar esta linha
    'stroke_data',
    'text_data',
    'image_data',
];
```

## 3. Sincronização (`SyncController.php`)
No método `pushPages`, garante que o `extracted_text` enviado pelo Flutter é guardado.

```php
foreach ($clientPages as $pageData) {
    // ... lógica existente ...
    $page->extracted_text = $pageData['extracted_text'] ?? $page->extracted_text;
    $page->save();
}
```

## 4. Assistente IA (`AIAssistantController.php`) [NOVO]
Cria este controlador para lidar com as rotas que o Flutter já está a chamar.

```php
namespace App\Http\Controllers;

use App\Models\Page;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class AIAssistantController extends Controller {

    public function search(Request $request) {
        $query = $request->query;
        $notebookId = $request->notebook_id;

        $results = Page::where('extracted_text', 'LIKE', "%{$query}%")
            ->when($notebookId, fn($q) => $q->where('notebook_id', $notebookId))
            ->get()
            ->map(fn($p) => [
                'text' => Str::limit($p->extracted_text, 150),
                'notebook_id' => $p->notebook_id,
                'page_number' => $p->page_number,
                'confidence' => 0.95
            ]);

        return response()->json(['results' => $results]);
    }

    public function summarize(Request $request) {
        $page = Page::findOrFail($request->page_id);

        // Exemplo: Integração com OpenAI/Gemini ou processamento básico
        $summary = "Resumo automático: " . Str::words($page->extracted_text, 30);

        return response()->json(['summary' => $summary]);
    }
}
```

## 5. Rotas (`api.php`)
Regista as rotas no grupo autenticado.

```php
Route::middleware('auth:sanctum')->group(function () {
    // ...
    Route::post('/ai/search', [AIAssistantController::class, 'search']);
    Route::post('/ai/summarize', [AIAssistantController::class, 'summarize']);
});
```
