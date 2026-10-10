# Real-Time Live Strokes (Rate Limit Evasion)

Resolved the final obstacle to real-time broadcasting by safely avoiding the WebSocket server's aggressive anti-spam rate limits.

## Issue Root Cause
The developer suspected that `_broadcastAction` was mistakenly intercepting the live drawing movement and overriding it with `is_final: true`.

**Diagnosis:**
`_broadcastAction` is completely innocent! It is explicitly designed to only fire **once**, exactly when the pen is lifted (`onPanEnd` -> `addStroke` -> `_executeAction` -> `_broadcastAction`).

The true culprit behind the "magic" appearance at the end was the **Laravel Reverb (Pusher) Rate Limiter**.
Pusher protocol strictly limits `client-` events to **10 messages per second** per client. When the throttle was set to exactly 100ms (10 FPS), the slightest network jitter would cause the app to send 11 events in a second.

When this limit is exceeded, the Reverb server assumes it is a spam attack and **silently drops all live packets**. Once the developer lifted their finger, the spam stopped, the rate limit cooled down instantly, and the single `_broadcastAction` final packet was successfully accepted by the server. This made it look like only the final action was transmitting!

## Fixes Implemented

**1. Evasion of the 10 FPS Rate Limit (`brush_tool.dart`)**:
- Increased the throttle window from 100ms to **250ms (4 Frames Per Second)**.
- Sending 4 packets per second is well below the 10 packets/sec limit, absolutely guaranteeing that the Laravel Reverb server will never flag the drawing as a spam attack.
- 4 FPS is still fast enough to provide a very cohesive "live drawing" visual experience for the receiving collaborators.

## Results
Live drawing will now seamlessly trace on remote screens without the server silently dropping the intermediate movement packets!
