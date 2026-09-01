import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'notebook_configuration.dart';

enum NotebookTemplateType {
  blank,
  school,
  university,
  study,
  engineering,
  accounting,
  laboratory,
  drawing,
  music,
  planner,
  project,
  meeting,
  diary,
  custom,
}

class NotebookTemplateConfig {
  final String label;
  final String description;
  final IconData icon;
  final Color suggestedColor;
  final NotebookConfiguration config;

  const NotebookTemplateConfig({
    required this.label,
    required this.description,
    required this.icon,
    required this.suggestedColor,
    required this.config,
  });

  static Map<NotebookTemplateType, NotebookTemplateConfig> get templates => {
    NotebookTemplateType.blank: NotebookTemplateConfig(
      label: 'Em branco',
      description: 'Um começo limpo para qualquer projeto.',
      icon: Icons.note_outlined,
      suggestedColor: Colors.grey,
      config: NotebookConfiguration(
        page: PageConfig(width: 210, height: 297, unit: 'mm', orientation: 'portrait'),
        background: BackgroundConfig(type: 'blank'),
        margins: MarginsConfig(top: 0, right: 0, bottom: 0, left: 0),
        header: HeaderFooterConfig(enabled: false),
        footer: HeaderFooterConfig(enabled: false),
        numbering: NumberingConfig(enabled: false),
      ),
    ),
    NotebookTemplateType.school: NotebookTemplateConfig(
      label: 'Escolar',
      description: 'Ideal para o ensino básico e secundário.',
      icon: Icons.school_outlined,
      suggestedColor: Colors.blue,
      config: NotebookConfiguration(
        page: PageConfig(width: 210, height: 297, unit: 'mm', orientation: 'portrait'),
        background: BackgroundConfig(type: 'lines', spacing: 8.0),
        margins: MarginsConfig(top: 20, right: 20, bottom: 20, left: 30),
        header: HeaderFooterConfig(enabled: true, fields: ['Disciplina', 'Professor', 'Aluno', 'Turma', 'Data', 'Tema']),
        footer: HeaderFooterConfig(enabled: false),
        numbering: NumberingConfig(enabled: true, format: '1', position: 'bottom-right'),
        defaultPageTemplate: 'school-normal',
      ),
    ),
    NotebookTemplateType.university: NotebookTemplateConfig(
      label: 'Universitário',
      description: 'Estrutura robusta para apontamentos complexos.',
      icon: Icons.account_balance_outlined,
      suggestedColor: const Color(0xFF0F4C5C),
      config: NotebookConfiguration(
        page: PageConfig(width: 210, height: 297, unit: 'mm', orientation: 'portrait'),
        background: BackgroundConfig(type: 'lines', spacing: 7.0),
        margins: MarginsConfig(top: 25, right: 20, bottom: 25, left: 25),
        header: HeaderFooterConfig(enabled: true, fields: ['Disciplina', 'Professor', 'Semestre', 'Curso', 'Data', 'Tema']),
        footer: HeaderFooterConfig(enabled: true, fields: ['Instituição']),
        numbering: NumberingConfig(enabled: true, format: '1', position: 'bottom-right'),
      ),
    ),
    NotebookTemplateType.diary: NotebookTemplateConfig(
      label: 'Diário',
      description: 'Espaço íntimo para reflexões diárias.',
      icon: Icons.auto_stories_outlined,
      suggestedColor: const Color(0xFF8B4513),
      config: NotebookConfiguration(
        page: PageConfig(width: 148, height: 210, unit: 'mm', orientation: 'portrait'), // A5
        background: BackgroundConfig(type: 'lines', spacing: 9.0),
        margins: MarginsConfig(top: 30, right: 25, bottom: 30, left: 25),
        header: HeaderFooterConfig(enabled: true, fields: ['Data']),
        footer: HeaderFooterConfig(enabled: false),
        numbering: NumberingConfig(enabled: false),
      ),
    ),
    NotebookTemplateType.planner: NotebookTemplateConfig(
      label: 'Agenda',
      description: 'Organize as suas tarefas e compromissos.',
      icon: Icons.calendar_today_outlined,
      suggestedColor: Colors.teal,
      config: NotebookConfiguration(
        page: PageConfig(width: 210, height: 297, unit: 'mm', orientation: 'portrait'),
        background: BackgroundConfig(type: 'dots', spacing: 5.0),
        margins: MarginsConfig(top: 15, right: 15, bottom: 15, left: 15),
        header: HeaderFooterConfig(enabled: true, fields: ['Data', 'Prioridade']),
        footer: HeaderFooterConfig(enabled: false),
        numbering: NumberingConfig(enabled: false),
      ),
    ),
    NotebookTemplateType.accounting: NotebookTemplateConfig(
      label: 'Contabilidade',
      description: 'Grelhas precisas para registos financeiros.',
      icon: Icons.calculate_outlined,
      suggestedColor: Colors.indigo,
      config: NotebookConfiguration(
        page: PageConfig(width: 297, height: 210, unit: 'mm', orientation: 'landscape'),
        background: BackgroundConfig(type: 'grid', spacing: 5.0),
        margins: MarginsConfig(top: 20, right: 20, bottom: 20, left: 20),
        header: HeaderFooterConfig(enabled: true, fields: ['Empresa', 'Balanço', 'Data']),
        footer: HeaderFooterConfig(enabled: true, fields: ['Total']),
        numbering: NumberingConfig(enabled: true, format: '1', position: 'bottom-right'),
      ),
    ),
    NotebookTemplateType.project: NotebookTemplateConfig(
      label: 'Projeto',
      description: 'Gestão de tarefas, prazos e responsáveis.',
      icon: Icons.assignment_outlined,
      suggestedColor: Colors.orange,
      config: NotebookConfiguration(
        page: PageConfig(width: 210, height: 297, unit: 'mm', orientation: 'portrait'),
        background: BackgroundConfig(type: 'dots', spacing: 6.0),
        margins: MarginsConfig(top: 20, right: 20, bottom: 20, left: 20),
        header: HeaderFooterConfig(enabled: true, fields: ['Projeto', 'Responsável', 'Data', 'Versão']),
        footer: HeaderFooterConfig(enabled: false),
        numbering: NumberingConfig(enabled: true, format: '1', position: 'bottom-right'),
      ),
    ),
    NotebookTemplateType.meeting: NotebookTemplateConfig(
      label: 'Reunião',
      description: 'Registe atas, decisões e próximos passos.',
      icon: Icons.groups_outlined,
      suggestedColor: const Color(0xFF2C3E50),
      config: NotebookConfiguration(
        page: PageConfig(width: 210, height: 297, unit: 'mm', orientation: 'portrait'),
        background: BackgroundConfig(type: 'blank'),
        margins: MarginsConfig(top: 25, right: 20, bottom: 25, left: 25),
        header: HeaderFooterConfig(enabled: true, fields: ['Título', 'Data', 'Local', 'Participantes']),
        footer: HeaderFooterConfig(enabled: false),
        numbering: NumberingConfig(enabled: true, format: '1', position: 'bottom-right'),
      ),
    ),
    NotebookTemplateType.drawing: NotebookTemplateConfig(
      label: 'Desenho',
      description: 'Papel de alta qualidade para artistas.',
      icon: Icons.palette_outlined,
      suggestedColor: Colors.pink,
      config: NotebookConfiguration(
        page: PageConfig(width: 297, height: 420, unit: 'mm', orientation: 'landscape'), // A3
        background: BackgroundConfig(type: 'blank'),
        margins: MarginsConfig(top: 0, right: 0, bottom: 0, left: 0),
        header: HeaderFooterConfig(enabled: false),
        footer: HeaderFooterConfig(enabled: false),
        numbering: NumberingConfig(enabled: false),
      ),
    ),
    NotebookTemplateType.study: NotebookTemplateConfig(
      label: 'Estudo',
      description: 'Modelo versátil para diversos métodos de aprendizagem.',
      icon: Icons.auto_stories_rounded,
      suggestedColor: Colors.amber.shade800,
      config: NotebookConfiguration(
        page: PageConfig(width: 210, height: 297, unit: 'mm', orientation: 'portrait'),
        background: BackgroundConfig(type: 'lines', spacing: 8.0),
        margins: MarginsConfig(top: 20, right: 20, bottom: 20, left: 25),
        header: HeaderFooterConfig(enabled: true, fields: ['Disciplina', 'Tema', 'Data']),
        footer: HeaderFooterConfig(enabled: false),
        numbering: NumberingConfig(enabled: true, format: '1', position: 'bottom-right'),
        defaultPageTemplate: 'study-normal',
      ),
    ),
    NotebookTemplateType.engineering: NotebookTemplateConfig(
      label: 'Engenharia',
      description: 'Milimetrado para esquemas, cálculos e diagramas.',
      icon: Icons.architecture_outlined,
      suggestedColor: const Color(0xFF1F4E79),
      config: NotebookConfiguration(
        page: PageConfig(width: 210, height: 297, unit: 'mm', orientation: 'portrait'),
        background: BackgroundConfig(type: 'engineering', subType: 'millimeter', spacing: 1.0),
        margins: MarginsConfig(top: 15, right: 15, bottom: 15, left: 15),
        header: HeaderFooterConfig(enabled: true, fields: ['Projeto', 'Equipamento', 'Data', 'Revisão']),
        footer: HeaderFooterConfig(enabled: true, fields: ['Escala']),
        numbering: NumberingConfig(enabled: true, format: '1', position: 'bottom-right'),
      ),
    ),
    NotebookTemplateType.accounting: NotebookTemplateConfig(
      label: 'Contabilidade',
      description: 'Grelhas precisas para registos financeiros.',
      icon: Icons.calculate_outlined,
      suggestedColor: Colors.indigo,
      config: NotebookConfiguration(
        page: PageConfig(width: 297, height: 210, unit: 'mm', orientation: 'landscape'),
        background: BackgroundConfig(type: 'grid', spacing: 5.0),
        margins: MarginsConfig(top: 20, right: 20, bottom: 20, left: 20),
        header: HeaderFooterConfig(enabled: true, fields: ['Empresa', 'Balanço', 'Data']),
        footer: HeaderFooterConfig(enabled: true, fields: ['Total']),
        numbering: NumberingConfig(enabled: true, format: '1', position: 'bottom-right'),
      ),
    ),
    NotebookTemplateType.laboratory: NotebookTemplateConfig(
      label: 'Laboratório',
      description: 'Estrutura para experiências e relatórios técnicos.',
      icon: Icons.science_outlined,
      suggestedColor: Colors.green.shade700,
      config: NotebookConfiguration(
        page: PageConfig(width: 210, height: 297, unit: 'mm', orientation: 'portrait'),
        background: BackgroundConfig(type: 'grid', spacing: 5.0),
        margins: MarginsConfig(top: 20, right: 20, bottom: 20, left: 20),
        header: HeaderFooterConfig(enabled: true, fields: ['Experiência', 'Objetivo', 'Professor', 'Data']),
        footer: HeaderFooterConfig(enabled: false),
        numbering: NumberingConfig(enabled: true, format: '1', position: 'bottom-right'),
      ),
    ),
    NotebookTemplateType.drawing: NotebookTemplateConfig(
      label: 'Desenho',
      description: 'Papel de alta qualidade para artistas e esboços.',
      icon: Icons.palette_outlined,
      suggestedColor: Colors.pink,
      config: NotebookConfiguration(
        page: PageConfig(width: 297, height: 420, unit: 'mm', orientation: 'landscape'), // A3
        background: BackgroundConfig(type: 'blank'),
        margins: MarginsConfig(top: 0, right: 0, bottom: 0, left: 0),
        header: HeaderFooterConfig(enabled: false),
        footer: HeaderFooterConfig(enabled: false),
        numbering: NumberingConfig(enabled: false),
      ),
    ),
    NotebookTemplateType.music: NotebookTemplateConfig(
      label: 'Música',
      description: 'Pentagramas para composição e estudo musical.',
      icon: Icons.music_note_outlined,
      suggestedColor: Colors.deepPurple,
      config: NotebookConfiguration(
        page: PageConfig(width: 210, height: 297, unit: 'mm', orientation: 'portrait'),
        background: BackgroundConfig(type: 'music', subType: 'staff', spacing: 2.0),
        margins: MarginsConfig(top: 25, right: 20, bottom: 25, left: 20),
        header: HeaderFooterConfig(enabled: true, fields: ['Compositor', 'Instrumento', 'Data']),
        footer: HeaderFooterConfig(enabled: false),
        numbering: NumberingConfig(enabled: true, format: '1', position: 'bottom-right'),
      ),
    ),
    NotebookTemplateType.planner: NotebookTemplateConfig(
      label: 'Agenda',
      description: 'Organize o seu tempo, tarefas e hábitos.',
      icon: Icons.calendar_today_outlined,
      suggestedColor: Colors.teal,
      config: NotebookConfiguration(
        page: PageConfig(width: 210, height: 297, unit: 'mm', orientation: 'portrait'),
        background: BackgroundConfig(type: 'dots', spacing: 5.0),
        margins: MarginsConfig(top: 15, right: 15, bottom: 15, left: 15),
        header: HeaderFooterConfig(enabled: true, fields: ['Data', 'Prioridade']),
        footer: HeaderFooterConfig(enabled: false),
        numbering: NumberingConfig(enabled: false),
      ),
    ),
    NotebookTemplateType.project: NotebookTemplateConfig(
      label: 'Projeto',
      description: 'Acompanhamento de planos, tarefas e prazos.',
      icon: Icons.assignment_outlined,
      suggestedColor: Colors.orange,
      config: NotebookConfiguration(
        page: PageConfig(width: 210, height: 297, unit: 'mm', orientation: 'portrait'),
        background: BackgroundConfig(type: 'dots', spacing: 6.0),
        margins: MarginsConfig(top: 20, right: 20, bottom: 20, left: 20),
        header: HeaderFooterConfig(enabled: true, fields: ['Projeto', 'Responsável', 'Data', 'Versão']),
        footer: HeaderFooterConfig(enabled: false),
        numbering: NumberingConfig(enabled: true, format: '1', position: 'bottom-right'),
      ),
    ),
    NotebookTemplateType.meeting: NotebookTemplateConfig(
      label: 'Reunião',
      description: 'Registe atas, participantes e decisões.',
      icon: Icons.groups_outlined,
      suggestedColor: const Color(0xFF2C3E50),
      config: NotebookConfiguration(
        page: PageConfig(width: 210, height: 297, unit: 'mm', orientation: 'portrait'),
        background: BackgroundConfig(type: 'blank'),
        margins: MarginsConfig(top: 25, right: 20, bottom: 25, left: 25),
        header: HeaderFooterConfig(enabled: true, fields: ['Título', 'Data', 'Local', 'Participantes']),
        footer: HeaderFooterConfig(enabled: false),
        numbering: NumberingConfig(enabled: true, format: '1', position: 'bottom-right'),
      ),
    ),
    NotebookTemplateType.diary: NotebookTemplateConfig(
      label: 'Diário',
      description: 'Espaço íntimo para reflexão e ideias pessoais.',
      icon: Icons.auto_stories_outlined,
      suggestedColor: const Color(0xFF8B4513),
      config: NotebookConfiguration(
        page: PageConfig(width: 148, height: 210, unit: 'mm', orientation: 'portrait'), // A5
        background: BackgroundConfig(type: 'lines', spacing: 9.0),
        margins: MarginsConfig(top: 30, right: 25, bottom: 30, left: 25),
        header: HeaderFooterConfig(enabled: true, fields: ['Data']),
        footer: HeaderFooterConfig(enabled: false),
        numbering: NumberingConfig(enabled: false),
      ),
    ),
    NotebookTemplateType.custom: NotebookTemplateConfig(
      label: 'Personalizado',
      description: 'Construa o seu próprio modelo do zero.',
      icon: Icons.settings_suggest_outlined,
      suggestedColor: Colors.blueGrey,
      config: NotebookConfiguration.defaultBlank(),
    ),
  };
}
