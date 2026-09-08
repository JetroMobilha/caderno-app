enum ToolMode { draw, highlighter, pan, select, lasso, text, table, eraser, pixelEraser, insertImage, imageEdit, organizer }

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
