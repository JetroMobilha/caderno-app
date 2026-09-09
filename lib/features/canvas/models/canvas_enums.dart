enum ToolMode { draw, highlighter, pan, select, lasso, text, table, eraser, pixelEraser, insertImage, imageEdit, organizer, video, fileAnchor }

enum BrushType { 
  gel,          // Técnica/Precisão
  fountain,     // Tinteiro (Velocidade)
  pencil,       // Grafite/Esboço
  marker,       // Marcador Chanfrado
  watercolor,   // Aguarela
  crayon,       // Giz
  airbrush,     // Aerógrafo
  neon,         // Brilho/Glow
  calligraphy,  // Pena achatada
  ribbon,       // Fita Dupla
  fineliner,    // 🚀 v1.10: Traço constante técnico
  monoline      // 🚀 v1.10: Redonda e lisa (Lettering)
}

enum ListType { none, bullet, numbered, checklist } // 🚀 v3.4

enum InlineTarget { none, block, title, footer }

enum TableCellType { text, number, date, time, checkbox, link, image }

enum TextEditCategory { basics, format, organize, structure, box } // 🚀 v10.12
enum TableEditCategory { structure, cell, style, actions } // 🚀 v10.12
enum GeneralEditCategory { transform, style, actions } // 🚀 v10.23
enum EraserEditCategory { mode, actions } // 🚀 v10.24

/// 🚀 v10.15: Estilos de Geometria de Traço
enum LineStyle { continuous, dashed, dotted }

/// 🚀 v10.16: Modos de Palm Rejection
enum PalmRejectionMode { auto, enabled, disabled }

/// 🚀 v10.0: Estados explícitos de interação com o canvas.
enum CanvasInteractionStateMode {
  idle,           // Neutro
  drawing,        // A desenhar traços
  selecting,      // A criar rect de seleção
  lassoSelecting, // A usar o laço
  moving,         // A mover objetos
  transforming,   // A redimensionar/rotacionar
  textEditing,    // Teclado aberto num bloco
  tableEditing,   // Foco numa célula ou estrutura
  panning,        // A mover a folha inteira
  inserting       // Modo de inserção rápida
}
