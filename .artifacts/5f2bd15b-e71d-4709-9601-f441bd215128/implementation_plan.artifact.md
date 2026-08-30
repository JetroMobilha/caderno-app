# Implementation Plan - Split Trash Access for Subjects and Notebooks

Separate the "Trash" (Lixeira) access into specific contexts for Subjects and Notebooks.

## Proposed Changes

### UI Screens

#### [MODIFY] [trash_screen.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/trash/views/trash_screen.dart)
- Add `initialTabIndex` parameter to the constructor.
- Initialize `_tabController` with the provided index in `initState`.

#### [MODIFY] [notebooks_list_screen.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/notebooks/views/notebooks_list_screen.dart)
- Add a "Lixeira" icon button in the `AppBar` actions.
- Navigate to `TrashScreen(initialTabIndex: 1)` (Notebooks tab) when clicked.

### UI Components

#### [MODIFY] [drawer_subjects_list.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/shared/widgets/drawer/drawer_subjects_list.dart)
- Add a "Lixeira" icon button in the header row, next to the Archive toggle.
- Navigate to `TrashScreen(initialTabIndex: 0)` (Subjects tab) when clicked.
- Remove the "Lixeira" `ListTile` from the bottom of the drawer.

## Verification Plan

### Manual Verification
- Open the Drawer:
    - Verify that the "Lixeira" button is in the header.
    - Verify that the bottom "Lixeira" item is gone.
    - Click the trash button and verify it opens `TrashScreen` on the "Pastas" tab.
- Navigate to a Notebook list:
    - Verify that a "Lixeira" button is in the `AppBar`.
    - Click it and verify it opens `TrashScreen` on the "Cadernos" tab.
