# Fix: Eraser causing incorrect background state detection and disconnection

The bug is caused by the application incorrectly suspending connections and clearing the canvas states when the `AppLifecycleState` transitions to `inactive`.

When the user activates the eraser (e.g., using a stylus button, double-tapping an Apple Pencil, or triggering an interaction that might momentarily steal focus), the OS can put the Flutter app into an `AppLifecycleState.inactive` state. This state simply means the app is not the primary focus (e.g., split screen, notification shade pulled down, or a system tooltip), but it is NOT in the background or hidden.

Currently, both `RealtimeService` and `CanvasScreen` listen to the `inactive` state and aggressively disconnect the realtime session and clear live strokes.

## Proposed Changes

We will modify the `didChangeAppLifecycleState` methods to only trigger the suspend and cleanup actions when the app is actually in the background (`paused` or `hidden`), and ignore the `inactive` state.

### `lib/core/network/realtime_service.dart`

#### [MODIFY] `realtime_service.dart`
- In `didChangeAppLifecycleState`, remove the check for `AppLifecycleState.inactive` and replace it with `AppLifecycleState.hidden` (if available) or just remove it so it only suspends on `paused` and `hidden`.

### `lib/features/canvas/views/canvas_screen.dart`

#### [MODIFY] `canvas_screen.dart`
- In `didChangeAppLifecycleState`, remove the check for `AppLifecycleState.inactive` to prevent the canvas from clearing live strokes unintentionally.

## User Review Required

No breaking changes. This ensures that users on Samsung devices (with S-Pen) or iPad (with Apple Pencil) can erase without randomly being disconnected from the collaborative session.

## Verification Plan
- Run the modified code and manually verify that pulling down the notification shade or using the stylus eraser does not trigger the "App suspensa" or "App entrou em segundo plano" disconnections.