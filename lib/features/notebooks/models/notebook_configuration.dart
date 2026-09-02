import 'dart:convert';

class NotebookConfiguration {
  final PageConfig page;
  final BackgroundConfig background;
  final MarginsConfig margins;
  final HeaderFooterConfig header;
  final HeaderFooterConfig footer;
  final NumberingConfig numbering;
  final String defaultPageTemplate;

  NotebookConfiguration({
    required this.page,
    required this.background,
    required this.margins,
    required this.header,
    required this.footer,
    required this.numbering,
    this.defaultPageTemplate = 'normal',
  });

  factory NotebookConfiguration.fromJson(Map<String, dynamic> json) {
    return NotebookConfiguration(
      page: PageConfig.fromJson(json['page'] ?? {}),
      background: BackgroundConfig.fromJson(json['background'] ?? {}),
      margins: MarginsConfig.fromJson(json['margins'] ?? {}),
      header: HeaderFooterConfig.fromJson(json['header'] ?? {}),
      footer: HeaderFooterConfig.fromJson(json['footer'] ?? {}),
      numbering: NumberingConfig.fromJson(json['numbering'] ?? {}),
      defaultPageTemplate: json['default_page_template'] ?? 'normal',
    );
  }

  Map<String, dynamic> toJson() => {
    'page': page.toJson(),
    'background': background.toJson(),
    'margins': margins.toJson(),
    'header': header.toJson(),
    'footer': footer.toJson(),
    'numbering': numbering.toJson(),
    'default_page_template': defaultPageTemplate,
  };

  String toJsonString() => jsonEncode(toJson());

  factory NotebookConfiguration.defaultBlank() => NotebookConfiguration(
    page: PageConfig(width: 210, height: 297, unit: 'mm', orientation: 'portrait', paperSize: 'A4'),
    background: BackgroundConfig(type: 'blank'),
    margins: MarginsConfig(top: 0, right: 0, bottom: 0, left: 0),
    header: HeaderFooterConfig(enabled: false),
    footer: HeaderFooterConfig(enabled: false),
    numbering: NumberingConfig(enabled: false),
  );
}

class PageConfig {
  final double width;
  final double height;
  final String unit;
  final String orientation;
  final bool isInfinite; 
  final String paperSize; // 🚀 TRANSFORMADO EM CAMPO

  PageConfig({
    required this.width, 
    required this.height, 
    this.unit = 'mm', 
    this.orientation = 'portrait',
    this.isInfinite = false,
    this.paperSize = 'A4',
  });

  factory PageConfig.fromJson(Map<String, dynamic> json) {
    final double w = (json['width'] ?? 210).toDouble();
    final double h = (json['height'] ?? 297).toDouble();
    
    return PageConfig(
      width: w,
      height: h,
      unit: json['unit'] ?? 'mm',
      orientation: json['orientation'] ?? 'portrait',
      isInfinite: json['is_infinite'] == true || json['is_infinite'] == 1,
      paperSize: json['paper_size'] ?? _inferPaperSize(w, h),
    );
  }

  Map<String, dynamic> toJson() => {
    'width': width, 
    'height': height, 
    'unit': unit, 
    'orientation': orientation,
    'is_infinite': isInfinite ? 1 : 0,
    'paper_size': paperSize,
  };

  static String _inferPaperSize(double width, double height) {
    final double w = width < height ? width : height;
    final double h = width < height ? height : width;

    if (w == 841 && h == 1189) return 'A0';
    if (w == 594 && h == 841) return 'A1';
    if (w == 420 && h == 594) return 'A2';
    if (w == 297 && h == 420) return 'A3';
    if (w == 210 && h == 297) return 'A4';
    if (w == 148 && h == 210) return 'A5';
    
    return 'A4';
  }
}

class BackgroundConfig {
  final String type; // 'blank', 'lines', 'grid', 'dots', 'math', 'engineering', 'music', 'design', 'planning', 'study', 'business', 'accounting', 'personal', 'maps', 'science', 'architecture', 'calligraphy', 'special'
  final String? subType; // ex: 'cartesian', 'staff', 'cornell', 'isometry'
  final double spacing;
  final String? color; // Background color
  final String? lineColor; // Grid/Line color
  final String? marginColor;
  final bool showRedMargin;
  final double opacity;
  final double lineWidth; // 🚀 NOVO

  BackgroundConfig({
    required this.type,
    this.subType,
    this.spacing = 8.0,
    this.color,
    this.lineColor,
    this.marginColor,
    this.showRedMargin = false,
    this.opacity = 1.0,
    this.lineWidth = 0.3, // Padrão fino
  });

  factory BackgroundConfig.fromJson(Map<String, dynamic> json) => BackgroundConfig(
    type: json['type'] ?? 'blank',
    subType: json['sub_type'],
    spacing: (json['spacing'] ?? 8.0).toDouble(),
    color: json['color'],
    lineColor: json['line_color'],
    marginColor: json['margin_color'],
    showRedMargin: json['show_red_margin'] == true || json['show_red_margin'] == 1,
    opacity: (json['opacity'] ?? 1.0).toDouble(),
    lineWidth: (json['line_width'] ?? 0.3).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'type': type,
    'sub_type': subType,
    'spacing': spacing,
    'color': color,
    'line_color': lineColor,
    'margin_color': marginColor,
    'show_red_margin': showRedMargin,
    'opacity': opacity,
    'line_width': lineWidth,
  };
}

class MarginsConfig {
  final double top;
  final double right;
  final double bottom;
  final double left;

  MarginsConfig({this.top = 0, this.right = 0, this.bottom = 0, this.left = 0});

  factory MarginsConfig.fromJson(Map<String, dynamic> json) => MarginsConfig(
    top: (json['top'] ?? 0).toDouble(),
    right: (json['right'] ?? 0).toDouble(),
    bottom: (json['bottom'] ?? 0).toDouble(),
    left: (json['left'] ?? 0).toDouble(),
  );

  Map<String, dynamic> toJson() => {'top': top, 'right': right, 'bottom': bottom, 'left': left};
}

class HeaderFooterConfig {
  final bool enabled;
  final List<String> fields;
  final String? customText;

  HeaderFooterConfig({this.enabled = false, this.fields = const [], this.customText});

  factory HeaderFooterConfig.fromJson(Map<String, dynamic> json) => HeaderFooterConfig(
    enabled: json['enabled'] ?? false,
    fields: List<String>.from(json['fields'] ?? []),
    customText: json['custom_text'],
  );

  Map<String, dynamic> toJson() => {'enabled': enabled, 'fields': fields, 'custom_text': customText};
}

class NumberingConfig {
  final bool enabled;
  final String format; // 'numeric', 'counter', 'labeled', 'roman'
  final String position; // 'top-right', 'bottom-right', 'bottom-center'
  final int startFrom;

  NumberingConfig({
    this.enabled = false, 
    this.format = 'numeric', 
    this.position = 'bottom-right', 
    this.startFrom = 1
  });

  factory NumberingConfig.fromJson(Map<String, dynamic> json) => NumberingConfig(
    enabled: json['enabled'] ?? false,
    format: json['format']?.toString() ?? 'numeric', // 🚀 Forçar String
    position: json['position']?.toString() ?? 'bottom-right',
    startFrom: json['start_from'] ?? 1,
  );

  Map<String, dynamic> toJson() => {
    'enabled': enabled, 
    'format': format, 
    'position': position, 
    'start_from': startFrom
  };
}
