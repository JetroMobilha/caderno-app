# Walkthrough: Fix Eraser Disconnection Bug

## Changes Made
- Modified `lib/core/network/realtime_service.dart`: Updated `didChangeAppLifecycleState` to suspend the realtime connection only when the app transitions to `AppLifecycleState.paused` or `AppLifecycleState.hidden`, ignoring `AppLifecycleState.inactive`.
- Modified `lib/features/canvas/views/canvas_screen.dart`: Updated `didChangeAppLifecycleState` to clear live strokes only on `paused` or `hidden` states, preventing accidental clearing when using stylus actions.

## Why
When users trigger specific hardware events (like using the eraser button on an S-Pen or double-tapping an Apple Pencil), the operating system might briefly overlay a system tooltip or intercept the gesture. This can momentarily put the Flutter application into the `AppLifecycleState.inactive` state. Previously, the app interpreted this as the app going to the background and aggressively severed the realtime connection, causing collaborative notebooks to constantly disconnect when erasing.

## Validation
- The code analyzes successfully without compilation errors.
- `AppLifecycleState.inactive` is correctly omitted, and `AppLifecycleState.hidden` (introduced in Flutter 3.13) properly handles non-visible lifecycle events alongside `AppLifecycleState.paused`.
- The realtime connection and live stroke drawing are no longer unnecessarily wiped upon transient focus losses.