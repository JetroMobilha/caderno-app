# Walkthrough - Network Centralization and IP Update

I have centralized the network configurations and updated the app to use the IP-based endpoints as requested for testing.

## Changes Made

### Core Network

#### [api_config.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/core/network/api_config.dart)
Created a new configuration file to manage all endpoints. It currently points to:
- **API**: `http://35.205.132.251:8080/api`
- **Storage**: `http://35.205.132.251:8080/storage/`
- **Reverb Host**: `35.205.132.251`
- **Reverb Port**: `6001`
- **Auth Endpoint**: `http://35.205.132.251:8080/api/broadcasting/auth`

> [!TIP]
> This file also contains the domain-based URLs (`https://appcaderno.duckdns.org:9000`), making it very easy to switch back once the HTTPS certificate/account issue is resolved.

#### [api_service.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/core/network/api_service.dart)
Updated to use `ApiConfig.baseUrl` and `ApiConfig.storageUrl`.

#### [realtime_service.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/core/network/realtime_service.dart)
Updated Reverb connection and authorization endpoints to use `ApiConfig`.

### Features

#### [canvas_repository.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/repositories/canvas_repository.dart)
Updated the image upload logic to use the centralized `ApiConfig.baseUrl`.

## Verification Results
- All hardcoded instances in the active codebase have been replaced with `ApiConfig` references.
- The app is now configured to hit port `8080` for API/Auth and `6001` for WebSocket (Reverb) using the IP `35.205.132.251`.
