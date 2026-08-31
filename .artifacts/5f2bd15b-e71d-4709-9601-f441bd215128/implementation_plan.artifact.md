# Implementation Plan - Align Backend and App for Shared Notebooks

Ensure the server correctly handles roles and personal states (archive/favorite) for shared notebooks, consistent with the app's database structure.

## User Review Required

> [!IMPORTANT]
> This plan includes modifications to the **Backend (Laravel)** to fix a bug where editors were being downgraded to viewers and to support personal archive/favorite states for shared users.

## Proposed Changes

### Backend (Laravel)

#### [NEW] [Migration](file:///C:/xampp/htdocs/caderno-backend/database/migrations/2026_08_30_020000_add_archive_and_favorite_to_notebook_user.php)
- Add `is_archived` and `is_favorite` boolean columns to the `notebook_user` pivot table.

#### [MODIFY] [SyncController.php](file:///C:/xampp/htdocs/caderno-backend/app/Http/Controllers/Api/SyncController.php)
- **`pushNotebooks`**:
    - Separate update logic:
        - If owner: Update the `notebooks` table (title, color, etc., and owner's archive/favorite state).
        - If shared user: Update the `notebook_user` pivot table for the user's specific archive/favorite state.
    - Fix `role` mapping in `server_updates` to fetch from the pivot table.
- **`pullNotebooks`**:
    - Fix `role` calculation to fetch from the pivot table instead of hardcoding `viewer`.
    - Map `is_archived` and `is_favorite` from the pivot table if the user is not the owner.

### Frontend (App)

#### [MODIFY] [sync_service.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/core/network/sync_service.dart)
- Ensure that when processing `server_updates` or `pullNotebooks` data, the app uses the `role` provided by the server to decide whether to update the main `notebooks` table or the `notebook_user` pivot table. (Partially done, but needs verification).

## Verification Plan

### Automated Tests
- Run `php artisan migrate` on the backend.
- Perform a sync on the app and check the logs for "Ciclo concluído".

### Manual Verification
1. **Role Correction**: Log in as a user who is an `editor` of a notebook. Perform a full PULL. Verify that the toolbar remains visible (not downgraded to `viewer`).
2. **Shared State Sync**: Archive a shared notebook on Device A. Sync. Check Device B (same user). Verify it appears in the archive.
3. **Owner Integrity**: Archive a shared notebook as an `editor`. Verify that the **Owner** still sees it as active on their device.
