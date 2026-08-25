# Fix Test Errors and Enhance Testability

This plan addresses the compilation and runtime errors in the test suite following the modularization and Riverpod 2.0 refactor. We will also improve the testability of the `AuthController` and other components by properly using Riverpod's dependency injection.

## Proposed Changes

### [Core - Dependency Injection]

#### [NEW] [auth_providers.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/auth/providers/auth_providers.dart)
- Define `authRepositoryProvider`.
- Define `appDatabaseProvider`.

#### [MODIFY] [auth_controller.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/auth/controllers/auth_controller.dart)
- Update `build()` to use `ref.watch` for `AuthRepository` and `AppDatabase`.
- Remove manual instantiation of dependencies.

### [Auth Feature - Tests]

#### [MODIFY] [auth_controller_test.dart](file:///C:/Users/HP/StudioProjects/caderno-app/test/features/auth/controllers/auth_controller_test.dart)
- Update `authProvider.overrideWith` to match `NotifierProvider` signature.
- Override `authRepositoryProvider` and `appDatabaseProvider` with mocks.
- Fix method calls to use `container.read(authProvider.notifier)`.
- Fix property access to use `container.read(authProvider)`.

### [Subjects Feature - Tests]

#### [MODIFY] [subjects_controller_test.dart](file:///C:/Users/HP/StudioProjects/caderno-app/test/features/subjects/controllers/subjects_controller_test.dart)
- Update `authProvider` override logic.
- Fix any other broken references due to modularization.

### [Canvas Feature - Tests]

#### [DELETE] [canvas_controller_test.dart](file:///C:/Users/HP/StudioProjects/caderno-app/test/features/canvas/controllers/canvas_controller_test.dart)
- Remove as the controller no longer exists.

#### [NEW] [canvas_document_test.dart](file:///C:/Users/HP/StudioProjects/caderno-app/test/features/canvas/providers/canvas_document_test.dart)
- Create new tests for `CanvasDocumentNotifier`.
- Verify stroke addition, page management, and undo/redo logic.

#### [NEW] [canvas_viewport_test.dart](file:///C:/Users/HP/StudioProjects/caderno-app/test/features/canvas/providers/canvas_viewport_test.dart)
- Create new tests for `CanvasViewportNotifier`.
- Verify zoom, pan, and page index changes.

## Verification Plan

### Automated Tests
- ✅ Run `flutter test` on all modified/new test files.
- ✅ Ensure all tests pass and coverage is maintained for core logic.

### Manual Verification
- N/A (Focus is on fixing existing automated tests).
