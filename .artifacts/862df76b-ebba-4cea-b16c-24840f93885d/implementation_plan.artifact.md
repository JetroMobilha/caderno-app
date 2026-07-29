# Centralize and Update Network Configurations

The user provided updated connection details for the backend services. The main site is on HTTPS (port 9000), while alternative HTTP access and Laravel Reverb are on specific IP/ports. This plan aims to centralize these configurations to make the app more maintainable and ensure it uses the correct, most secure endpoints.

## User Review Required

> [!IMPORTANT]
> I will centralize the network configurations in a new file `lib/core/network/api_config.dart`.
> I am assuming that `https://appcaderno.duckdns.org:9000/api` should be the preferred endpoint for ALL HTTP requests (including broadcasting auth) because it provides HTTPS.
> I will keep the IP `35.205.132.251` and port `6001` for Laravel Reverb (WebSocket) as specified.

## Proposed Changes

### Core Network

#### [NEW] [api_config.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/core/network/api_config.dart)
Create a centralized configuration class for all API and Realtime endpoints.

#### [MODIFY] [api_service.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/core/network/api_service.dart)
Update to use `ApiConfig` for `baseUrl` and `baseUrlImagem`.

#### [MODIFY] [realtime_service.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/core/network/realtime_service.dart)
Update to use `ApiConfig` for Reverb host, port, and the broadcasting authorization endpoint.

### Features

#### [MODIFY] [canvas_repository.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/repositories/canvas_repository.dart)
Update hardcoded upload URL to use `ApiConfig`.

## Verification Plan

### Manual Verification
- Verify that the app still connects to the API (Login/Logout).
- Verify that Realtime features (collaborative drawing, presence) still work.
- Check the debug logs to ensure requests are hitting the correct ports (9000 for API/Auth, 6001 for WS).
