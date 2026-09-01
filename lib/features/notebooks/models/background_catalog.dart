import 'package:flutter/material.dart';
import 'notebook_configuration.dart';

class BackgroundCategory {
  final String id;
  final String label;
  final IconData icon;
  final List<BackgroundOption> options;

  const BackgroundCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.options,
  });
}

class BackgroundOption {
  final String id;
  final String label;
  final BackgroundConfig config;

  const BackgroundOption({
    required this.id,
    required this.label,
    required this.config,
  });
}

class BackgroundCatalog {
  static List<BackgroundCategory> get categories => [
    BackgroundCategory(
      id: 'basic',
      label: 'Básicos',
      icon: Icons.article_outlined,
      options: [
        BackgroundOption(id: 'white', label: 'Branco', config: BackgroundConfig(type: 'blank', color: '#FFFFFF')),
        BackgroundOption(id: 'cream', label: 'Creme', config: BackgroundConfig(type: 'blank', color: '#FFFDD0')),
        BackgroundOption(id: 'ivory', label: 'Marfim', config: BackgroundConfig(type: 'blank', color: '#FFFFF0')),
        BackgroundOption(id: 'light_grey', label: 'Cinza claro', config: BackgroundConfig(type: 'blank', color: '#F5F5F5')),
        BackgroundOption(id: 'black', label: 'Preto', config: BackgroundConfig(type: 'blank', color: '#121212')),
      ],
    ),
    BackgroundCategory(
      id: 'writing',
      label: 'Escrita',
      icon: Icons.edit_note_rounded,
      options: [
        BackgroundOption(id: 'ruled_medium', label: 'Linhas médias', config: BackgroundConfig(type: 'lines', spacing: 8.0)),
        BackgroundOption(id: 'ruled_wide', label: 'Linhas largas', config: BackgroundConfig(type: 'lines', spacing: 10.0)),
        BackgroundOption(id: 'ruled_narrow', label: 'Linhas estreitas', config: BackgroundConfig(type: 'lines', spacing: 6.0)),
        BackgroundOption(id: 'ruled_margin', label: 'Pautado com margem', config: BackgroundConfig(type: 'lines', spacing: 8.0, showRedMargin: true)),
        BackgroundOption(id: 'calligraphy', label: 'Caligrafia', config: BackgroundConfig(type: 'calligraphy', spacing: 10.0)),
      ],
    ),
    BackgroundCategory(
      id: 'grid',
      label: 'Quadriculados',
      icon: Icons.grid_4x4_rounded,
      options: [
        BackgroundOption(id: 'grid_5mm', label: 'Quadriculado 5mm', config: BackgroundConfig(type: 'grid', spacing: 5.0)),
        BackgroundOption(id: 'grid_10mm', label: 'Quadriculado 10mm', config: BackgroundConfig(type: 'grid', spacing: 10.0)),
        BackgroundOption(id: 'grid_1mm', label: 'Quadriculado 1mm', config: BackgroundConfig(type: 'grid', spacing: 1.0)),
        BackgroundOption(id: 'isometric', label: 'Isométrico', config: BackgroundConfig(type: 'engineering', subType: 'isometric', spacing: 10.0)),
      ],
    ),
    BackgroundCategory(
      id: 'math',
      label: 'Matemática',
      icon: Icons.functions_rounded,
      options: [
        BackgroundOption(id: 'cartesian', label: 'Plano Cartesiano', config: BackgroundConfig(type: 'math', subType: 'cartesian', spacing: 20.0)),
        BackgroundOption(id: 'polar', label: 'Grade Polar', config: BackgroundConfig(type: 'math', subType: 'polar', spacing: 20.0)),
        BackgroundOption(id: 'logarithmic', label: 'Papel Logarítmico', config: BackgroundConfig(type: 'math', subType: 'log', spacing: 10.0)),
      ],
    ),
    BackgroundCategory(
      id: 'engineering',
      label: 'Engenharia',
      icon: Icons.architecture_rounded,
      options: [
        BackgroundOption(id: 'millimeter', label: 'Milimetrado', config: BackgroundConfig(type: 'engineering', subType: 'millimeter', spacing: 1.0)),
        BackgroundOption(id: 'circuit', label: 'Circuitos', config: BackgroundConfig(type: 'engineering', subType: 'circuit', spacing: 10.0)),
        BackgroundOption(id: 'technical_grid', label: 'Técnico', config: BackgroundConfig(type: 'engineering', subType: 'technical', spacing: 5.0)),
      ],
    ),
    BackgroundCategory(
      id: 'music',
      label: 'Música',
      icon: Icons.music_note_rounded,
      options: [
        BackgroundOption(id: 'staff', label: 'Pentagrama', config: BackgroundConfig(type: 'music', subType: 'staff', spacing: 10.0)),
        BackgroundOption(id: 'piano', label: 'Partitura Piano', config: BackgroundConfig(type: 'music', subType: 'piano', spacing: 10.0)),
        BackgroundOption(id: 'guitar', label: 'Tablatura Guitarra', config: BackgroundConfig(type: 'music', subType: 'guitar', spacing: 8.0)),
      ],
    ),
    BackgroundCategory(
      id: 'planning',
      label: 'Planeamento',
      icon: Icons.calendar_month_rounded,
      options: [
        BackgroundOption(id: 'daily', label: 'Diário', config: BackgroundConfig(type: 'planning', subType: 'daily')),
        BackgroundOption(id: 'weekly', label: 'Semanal', config: BackgroundConfig(type: 'planning', subType: 'weekly')),
        BackgroundOption(id: 'todo', label: 'Lista de tarefas', config: BackgroundConfig(type: 'planning', subType: 'todo')),
        BackgroundOption(id: 'kanban', label: 'Kanban', config: BackgroundConfig(type: 'planning', subType: 'kanban')),
      ],
    ),
    BackgroundCategory(
      id: 'study',
      label: 'Estudos',
      icon: Icons.school_rounded,
      options: [
        BackgroundOption(id: 'cornell', label: 'Cornell Notes', config: BackgroundConfig(type: 'study', subType: 'cornell', spacing: 8.0)),
        BackgroundOption(id: 'summary', label: 'Resumo', config: BackgroundConfig(type: 'study', subType: 'summary')),
        BackgroundOption(id: 'mindmap', label: 'Mapa mental', config: BackgroundConfig(type: 'study', subType: 'mindmap')),
      ],
    ),
    BackgroundCategory(
      id: 'special',
      label: 'Templates',
      icon: Icons.extension_rounded,
      options: [
        BackgroundOption(id: 'checklist', label: 'Checklist', config: BackgroundConfig(type: 'special', subType: 'checklist')),
        BackgroundOption(id: 'meeting_notes', label: 'Notas de Reunião', config: BackgroundConfig(type: 'business', subType: 'meeting')),
        BackgroundOption(id: 'financial', label: 'Razão Contabilístico', config: BackgroundConfig(type: 'accounting', subType: 'ledger')),
      ],
    ),
  ];
}
