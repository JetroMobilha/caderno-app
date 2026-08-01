<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Jobs\ProcessPageOcr;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use App\Models\Subject;
use App\Models\Notebook;
use App\Models\Page;
use App\Events\SyncRequested;

class SyncController extends Controller
{
    // ... [Códigos de Subject mantêm-se iguais] ...

    public function pushNotebooks(Request $request)
    {
        $user = $request->user();
        $clientNotebooks = $request->input('notebooks', []);
        $syncedNotebooks = [];

        foreach ($clientNotebooks as $notebookData) {
            if (!empty($notebookData['is_deleted']) && $notebookData['is_deleted'] == 1) {
                if (!empty($notebookData['server_id'])) {
                    $notebook = Notebook::where('id', $notebookData['server_id'])->first();
                    if ($notebook && $notebook->subject->user_id == $user->id) $notebook->delete();
                }
                continue;
            }

           $notebook = Notebook::updateOrCreate(
                ['id' => $notebookData['server_id'] ?? null],
                [
                    'subject_id'  => $notebookData['subject_id'] ?? null,
                    'title'       => !empty($notebookData['title']) ? trim($notebookData['title']) : '', // 🚀 Permite título vazio
                    'cover_type'  => !empty($notebookData['cover_type']) ? $notebookData['cover_type'] : 'color',
                    'color'       => !empty($notebookData['color']) ? $notebookData['color'] : '#3b82f6',
                    'line_type'   => !empty($notebookData['line_type']) ? $notebookData['line_type'] : 'ruled', // 🚀 CORRIGIDO: Flutter usa 'ruled'
                    'paper_size'  => !empty($notebookData['paper_size']) ? $notebookData['paper_size'] : 'A4',
                ]
            );

            $syncedNotebooks[] = ['client_id' => $notebookData['id'], 'server_id' => $notebook->id];
        }

        if($syncedNotebooks) SyncRequested::dispatch($user->id);
        return response()->json(['message' => 'Cadernos processados.', 'synced_notebooks' => $syncedNotebooks]);
    }

    public function pushPages(Request $request)
    {
        $user = $request->user();
        $clientPages = $request->input('pages', []);
        $syncedPages = [];

        foreach ($clientPages as $pageData) {
            $page = Page::where('notebook_id', $pageData['notebook_id'])
                        ->where('page_number', $pageData['page_number'])
                        ->first() ?? new Page([
                            'notebook_id' => $pageData['notebook_id'],
                            'page_number' => $pageData['page_number']
                        ]);

            $newStrokes = $this->parseClientArray($pageData['stroke_data'] ?? []);
            $mergedStrokes = Page::mergeJsonItems($page->stroke_data, $newStrokes);
            $page->stroke_data = json_encode($mergedStrokes, JSON_UNESCAPED_UNICODE);

            $newTexts = $this->parseClientArray($pageData['text_data'] ?? []);
            $page->text_data = json_encode(Page::mergeJsonItems($page->text_data, $newTexts), JSON_UNESCAPED_UNICODE);

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
            $page->image_data = json_encode(Page::mergeJsonItems($page->image_data, $processedImages), JSON_UNESCAPED_UNICODE);

            $page->is_landscape = !empty($pageData['is_landscape']) ? 1 : 0;

            // 🚀 CORREÇÃO: Usar strings diretas para o Flutter ler sem JSON
            $page->header_data = $pageData['header_data'] ?? '';
            $page->footer_data = $pageData['footer_data'] ?? '';

            $page->extracted_text = !empty($pageData['extracted_text']) ? (string) $pageData['extracted_text'] : null;
            $page->save();

            if (!empty($newStrokes) && empty($page->extracted_text)) {
                ProcessPageOcr::dispatch($page->id, $pageData['language'] ?? null)->onQueue('ocr');
            }

            $syncedPages[] = [
                'client_id'   => $pageData['client_id'] ?? null,
                'server_id'   => $page->id,
                'page_number' => $page->page_number
            ];
        }

        SyncRequested::dispatch($user->id);
        return response()->json(['message' => 'Páginas salvas.', 'synced_pages' => $syncedPages]);
    }

    // ... [Restantes métodos mantêm-se iguais] ...
}
