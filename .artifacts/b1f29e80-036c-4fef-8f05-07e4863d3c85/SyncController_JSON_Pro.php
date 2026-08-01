<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Page;
use App\Models\Notebook;
use Illuminate\Support\Facades\Storage;

class SyncController extends Controller
{
    /**
     * 🚀 Versão Pro para colunas JSON do MySQL
     */
    public function pushPages(Request $request)
    {
        $user = $request->user();
        $clientPages = $request->input('pages', []);
        $syncedPages = [];

        foreach ($clientPages as $pageData) {
            // Localiza ou cria a página
            $page = Page::firstOrNew([
                'notebook_id' => $pageData['notebook_id'],
                'page_number' => $pageData['page_number']
            ]);

            // 1. Metadados de Título (Header/Footer)
            // Como as colunas são JSON, o Laravel trata os arrays automaticamente se houver 'casts' no Model.
            $page->header_data = $pageData['header_data'] ?? ['title' => ''];
            $page->footer_data = $pageData['footer_data'] ?? ['title' => ''];
            $page->is_landscape = !empty($pageData['is_landscape']) ? 1 : 0;

            // 2. Conteúdo (Strokes/Texts)
            $newStrokes = $this->parseClientArray($pageData['stroke_data'] ?? []);
            $page->stroke_data = Page::mergeJsonItems($page->stroke_data, $newStrokes);

            $newTexts = $this->parseClientArray($pageData['text_data'] ?? []);
            $page->text_data = Page::mergeJsonItems($page->text_data, $newTexts);

            // 3. Imagens
            $incomingImages = $this->parseClientArray($pageData['image_data'] ?? []);
            $processedImages = [];
            foreach ($incomingImages as $img) {
                if (!empty($img['image_base64'])) {
                    $decoded = base64_decode($img['image_base64']);
                    $filename = 'img_' . uniqid() . '.png';
                    Storage::disk('public')->put('notebook_images/' . $filename, $decoded);
                    $img['image_path'] = asset('storage/notebook_images/' . $filename);
                    unset($img['image_base64']);
                }
                $processedImages[] = $img;
            }
            $page->image_data = Page::mergeJsonItems($page->image_data, $processedImages);

            $page->extracted_text = $pageData['extracted_text'] ?? null;
            $page->save();

            $syncedPages[] = [
                'client_id'   => $pageData['client_id'] ?? null,
                'server_id'   => $page->id,
                'page_number' => $page->page_number
            ];
        }

        return response()->json(['message' => 'Páginas sincronizadas com JSON.', 'synced_pages' => $syncedPages]);
    }

    private function parseClientArray($data) {
        if (is_array($data)) return $data;
        if (is_string($data)) return json_decode($data, true) ?? [];
        return [];
    }
}
