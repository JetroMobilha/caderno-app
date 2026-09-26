import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:uuid/uuid.dart';

import 'package:caderno_digital_app/features/notebooks/models/notebook_model.dart';
import 'package:caderno_digital_app/features/notebooks/models/notebook_configuration.dart';
import 'package:caderno_digital_app/features/notebooks/repositories/notebook_repository.dart';
import 'package:caderno_digital_app/features/canvas/repositories/canvas_repository.dart';
import 'package:caderno_digital_app/features/canvas/models/local_page_model.dart';
import 'package:caderno_digital_app/core/network/time_service.dart';

class PdfImportResult {
  final Notebook? notebook;
  final List<LocalPage> pages;
  final int pageCount;
  final String? error;

  PdfImportResult({
    this.notebook,
    this.pages = const [],
    this.pageCount = 0,
    this.error,
  });

  bool get isSuccess => error == null && pages.isNotEmpty;
}

class PdfImportService {
  final NotebookRepository _notebookRepository;
  final CanvasRepository _canvasRepository;

  PdfImportService(this._notebookRepository, this._canvasRepository);

  /// Seleciona um ficheiro PDF do dispositivo e renderiza cada página como fundo
  Future<PdfImportResult> importPdf({
    required int subjectId,
    int? subjectServerId,
    int? targetNotebookId,
    String? customTitle,
  }) async {
    try {
      final pickerResult = await FilePickerPlatform.instance.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (pickerResult.isEmpty) {
        return PdfImportResult(error: 'Nenhum arquivo selecionado.');
      }

      final PlatformFile pickedFile = pickerResult.first;
      String? pdfPath = pickedFile.path;
      if (pdfPath == null || pdfPath.isEmpty) {
        try {
          pdfPath = pickedFile.xFile.path;
        } catch (_) {}
      }

      final appDir = await getApplicationDocumentsDirectory();
      final pdfId = const Uuid().v4();

      // Copiar PDF original para armazenamento interno
      final savedPdfPath = '${appDir.path}/pdf_imports/$pdfId.pdf';
      final savedPdfDir = Directory('${appDir.path}/pdf_imports');
      if (!await savedPdfDir.exists()) await savedPdfDir.create(recursive: true);

      if (pdfPath != null && pdfPath.isNotEmpty && File(pdfPath).existsSync()) {
        await File(pdfPath).copy(savedPdfPath);
      } else {
        Uint8List? bytes;
        try {
          bytes = await pickedFile.xFile.readAsBytes();
        } catch (_) {}

        if (bytes != null && bytes.isNotEmpty) {
          await File(savedPdfPath).writeAsBytes(bytes);
        } else {
          return PdfImportResult(error: 'Não foi possível aceder aos dados do PDF (caminho: $pdfPath).');
        }
      }

      // Criar diretório para salvar as imagens das páginas do PDF
      final pdfPagesDir = Directory('${appDir.path}/pdf_pages/$pdfId');
      if (!await pdfPagesDir.exists()) {
        await pdfPagesDir.create(recursive: true);
      }

      // Abrir o documento PDF usando pdfx
      debugPrint('📄 [PdfImportService] A abrir ficheiro PDF: $savedPdfPath');
      PdfDocument document;
      try {
        document = await PdfDocument.openFile(savedPdfPath);
      } catch (e) {
        debugPrint('⚠️ [PdfImportService] openFile falhou, a tentar abrir por bytes com openData: $e');
        final bytes = await File(savedPdfPath).readAsBytes();
        document = await PdfDocument.openData(bytes);
      }

      final int pageCount = document.pagesCount;

      if (pageCount == 0) {
        await document.close();
        return PdfImportResult(error: 'O arquivo PDF não contém páginas.');
      }

      final String documentTitle = customTitle?.isNotEmpty == true 
          ? customTitle! 
          : pickedFile.name.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');

      int notebookId = targetNotebookId ?? 0;
      Notebook? createdNotebook;
      int startingPageNumber = 1;

      if (targetNotebookId == null) {
        // Criar um NOVO Caderno
        final newNotebook = Notebook(
          subjectId: subjectId,
          title: documentTitle,
          description: 'Importado de ${pickedFile.name}',
          coverType: 'color',
          color: '#1A365D',
          templateType: 'blank',
        );
        notebookId = await _notebookRepository.insertNotebook(newNotebook);
        createdNotebook = newNotebook.copyWith(id: notebookId);
      } else {
        // Descobrir o número de página inicial se for importar num caderno existente
        final existingPages = await _canvasRepository.getPagesByNotebook(targetNotebookId, null);
        startingPageNumber = existingPages.length + 1;
      }

      final List<LocalPage> importedPages = [];

      for (int i = 1; i <= pageCount; i++) {
        final page = await document.getPage(i);
        
        // Renderizar a página em resolução otimizada (max 2.5x scale)
        final double scale = (page.width > 1800 || page.height > 1800) ? 1.5 : 2.5;
        final pageImage = await page.render(
          width: page.width * scale,
          height: page.height * scale,
          format: PdfPageImageFormat.png,
        );

        final String pageImgPath = '${pdfPagesDir.path}/page_$i.png';
        if (pageImage != null) {
          await File(pageImgPath).writeAsBytes(pageImage.bytes);
        } else {
          debugPrint('⚠️ [PdfImportService] Falha ao renderizar imagem da página $i');
        }

        String effectiveBgPath = pageImgPath;
        final int? notebookServerId = createdNotebook?.serverId ?? (targetNotebookId != null && targetNotebookId > 0 ? targetNotebookId : null);
        if (notebookServerId != null && notebookServerId > 0 && pageImage != null) {
          try {
            final String? remoteUrl = await _canvasRepository.uploadImage(
              notebookServerId,
              'pdf_page_${pdfId}_$i.png',
              pageImage.bytes,
            );
            if (remoteUrl != null && remoteUrl.isNotEmpty) {
              effectiveBgPath = remoteUrl;
              debugPrint('☁️ [PdfImportService] Upload do fundo da página $i concluído: $remoteUrl');
            }
          } catch (e) {
            debugPrint('⚠️ [PdfImportService] Não foi possível fazer upload imediato da página $i: $e');
          }
        }

        final bool isLandscape = page.width > page.height;
        final String paperSize = _detectPaperSize(page.width, page.height);

        final localPage = LocalPage(
          notebookId: notebookId,
          pageNumber: startingPageNumber + i - 1,
          isLandscape: isLandscape,
          paperSize: paperSize,
          lineType: 'blank',
          backgroundConfig: BackgroundConfig(type: 'blank', color: null),
          title: '$documentTitle - pág. $i',
          backgroundPdfPath: effectiveBgPath,
          updatedAt: TimeService().nowMs(),
        );

        final insertedId = await _canvasRepository.savePage(localPage, createdNotebook?.serverId);
        importedPages.add(localPage.copyWith(id: insertedId));

        await page.close();
      }

      await document.close();

      return PdfImportResult(
        notebook: createdNotebook,
        pages: importedPages,
        pageCount: pageCount,
      );
    } catch (e, stack) {
      debugPrint('🚨 [PdfImportService] Erro ao importar PDF: $e\n$stack');
      if (e.toString().contains('MissingPluginException')) {
        return PdfImportResult(
          error: 'O plugin nativo de PDF (pdfx) não está registrado no app em execução. Por favor, Pare (Stop) e Recompile (Run) a aplicação no Android Studio.',
        );
      }
      return PdfImportResult(
        error: 'Erro ao importar PDF: $e\n[Stack]: ${stack.toString().split('\n').take(3).join(' ')}',
      );
    }
  }

  /// Deteta automaticamente o formato da página do PDF (A0, A1, A2, A3, A4, A5 ou Custom)
  static String _detectPaperSize(double widthPt, double heightPt) {
    final double portraitWidthPt = widthPt < heightPt ? widthPt : heightPt;
    final double portraitHeightPt = widthPt < heightPt ? heightPt : widthPt;

    final double widthMm = portraitWidthPt * 0.352778;
    final double heightMm = portraitHeightPt * 0.352778;

    if ((widthMm - 841).abs() < 40 && (heightMm - 1189).abs() < 40) return 'A0';
    if ((widthMm - 594).abs() < 30 && (heightMm - 841).abs() < 30) return 'A1';
    if ((widthMm - 420).abs() < 20 && (heightMm - 594).abs() < 20) return 'A2';
    if ((widthMm - 297).abs() < 15 && (heightMm - 420).abs() < 15) return 'A3';
    if ((widthMm - 210).abs() < 10 && (heightMm - 297).abs() < 10) return 'A4';
    if ((widthMm - 148).abs() < 10 && (heightMm - 210).abs() < 10) return 'A5';

    return 'CUSTOM:${widthMm.round()}:${heightMm.round()}';
  }
}
