import 'package:flutter/material.dart';

class SubjectUtils {
  static IconData getSubjectIcon(String? iconName) {
    switch (iconName) {
      case 'school': return Icons.school_rounded;
      case 'science': return Icons.science_rounded;
      case 'math': return Icons.calculate_rounded;
      case 'language': return Icons.language_rounded;
      case 'history': return Icons.history_edu_rounded;
      case 'law': return Icons.gavel_rounded;
      case 'health': return Icons.medical_services_rounded;
      case 'psychology': return Icons.psychology_rounded;
      case 'business': return Icons.business_center_rounded;
      case 'analytics': return Icons.analytics_rounded;
      case 'workspaces': return Icons.workspaces_rounded;
      case 'team': return Icons.groups_rounded;
      case 'presentation': return Icons.present_to_all_rounded;
      case 'security': return Icons.security_rounded;
      case 'computer': return Icons.computer_rounded;
      case 'code': return Icons.code_rounded;
      case 'idea': return Icons.lightbulb_rounded;
      case 'art': return Icons.palette_rounded;
      case 'music': return Icons.music_note_rounded;
      case 'calendar': return Icons.calendar_month_rounded;
      case 'notes': return Icons.sticky_note_2_rounded;
      case 'folder': return Icons.folder_special_rounded;
      case 'sport': return Icons.sports_basketball_rounded;
      case 'book':
      default: return Icons.menu_book_rounded;
    }
  }
}
