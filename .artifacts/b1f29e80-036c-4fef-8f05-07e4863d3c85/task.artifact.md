# Tarefas: Estabilização WebRTC e Presença

## Fase 1: Blindagem de Sinalização e Presença
- [x] Implementar Cooldown de Ofertas no `WebRTCService`
- [x] Simplificar estrutura SDP (forçar áudio-only)
- [x] Adicionar guarda de mudança de estado no `CanvasController`
- [x] Corrigir Reset de Bindings no `RealtimeService` (Fix Visibilidade)
- [x] Corrigir extração de UID no `RealtimeService` (Fix "null" member)
- [x] Integrar convite de voz no Modal (UI)
- [ ] Validar Fase 1 com logs reais entre dispositivos

## Fase 2: Robustez ICE e Hardware
- [x] Logar detalhes dos candidatos ICE (IPs) para diagnóstico
- [x] Implementar mecanismo de re-tentativa automática em caso de `IceConnectionState.failed`
- [ ] Verificar compatibilidade de microfone entre Windows e Android
