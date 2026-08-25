# Optimization and Rendering Isolation for Freehand Drawing

To guarantee a lightweight, high-performance drawing experience, we will implement strict rendering isolation. This ensures that high-frequency updates (drawing a line) only affect a tiny portion of the UI tree and don't trigger expensive full-screen repaints.

## Core Strategy

### 1. Rendering Layer Isolation (The "Stack" Strategy)
We will split the canvas into independent layers, each wrapped in its own `RepaintBoundary`. This prevents one layer's updates from forcing others to repaint.

1.  **Background Layer**: Draws paper lines/grids. Repaints ONLY when changing paper type.
2.  **Static Strokes Layer**: Draws finished strokes. Repaints ONLY when a stroke is committed (finger up) or deleted.
3.  **Active Stroke Layer**: Draws the line currently being traced by the finger. Repaints at 60-120fps.
4.  **Remote Cursors Layer**: Draws other users' pointers.

### 2. Fast-Track State Management
-   **Local Via**: Active drawing uses local `ValueNotifier` for zero-latency updates.
-   **Global Via (Riverpod 2.0)**: Once a stroke is finished, it is committed to the global state.
-   **Selective Watching**: Use `ref.watch(provider.select(...))` to ensure components only rebuild when their specific data changes.

### 3. Background Threading (Isolates)
-   All heavy operations (Database Save, JSON Serialization, Sync) will be moved off the main thread.

## Proposed Changes

### [Canvas Module - Rendering Optimization]

#### [MODIFY] [canvas_painter.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/widgets/canvas_painter.dart)
- Split `StaticNotebookPainter` into `BackgroundPainter` and `StrokesPainter`.
- This allows the background grid to be cached indefinitely.

#### [MODIFY] [drawing_layer.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/widgets/layers/drawing_layer.dart)
- Orchestrate the new layered approach using multiple `RepaintBoundary` and `CustomPaint` widgets.
- Ensure remote live strokes are also isolated.

#### [MODIFY] [interaction_layer.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/widgets/layers/interaction_layer.dart)
- Wrap the `ActiveStrokePainter`'s `CustomPaint` in a `RepaintBoundary`.
- Optimize `onPanUpdate` to minimize logic execution.

### [Auth & Global Module]

#### [MODIFY] [auth_controller.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/auth/controllers/auth_controller.dart)
- Convert to `Notifier<AuthState>` (Riverpod 2.0).
- Ensure auth status updates don't trigger wide UI rebuilds.

#### [DELETE] [canvas_controller.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/controllers/canvas_controller.dart)
- Remove the legacy bridge to eliminate redundant state propagation.

## User Review Required

> [!IMPORTANT]
> **Stroke Simplification**: I will implement a Ramer-Douglas-Peucker (RDP) algorithm during the commit phase. This reduces point count by ~70% without changing the look, which is essential to prevent "lag" as the notebook grows.

> [!TIP]
> By separating the **Background Layer**, we reduce the GPU work per frame during drawing by nearly 50%, as the grid lines are no longer redrawn every time the finger moves.

## Verification Plan

### Performance Metrics
- ✅ **FPS Stability**: Target 60fps constant during heavy drawing.
- ✅ **Repaint Count**: Use Flutter DevTools to verify that only the `ActiveStrokeLayer` repaints during a pan.
- ✅ **Memory Usage**: Verify that simplification keeps memory growth linear rather than exponential.

### Manual Verification
- ✅ **Paper Styles**: Change paper style and verify the background updates correctly.
- ✅ **Collaboration**: Verify remote strokes still appear in real-time without flickering.
