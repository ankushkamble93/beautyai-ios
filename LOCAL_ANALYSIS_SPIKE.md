# Local-First Skin Analysis Spike (iOS)

## Goal
Reduce recurring cloud inference costs by running free on-device analysis first, and only call cloud AI when local confidence is low.

## Free-first options reviewed

1. Apple Vision face landmarks (built-in, free runtime)
   - URL: https://developer.apple.com/documentation/vision/vndetectfacelandmarksrequest
   - Use: face geometry alignment (front/left/right), area-level metrics, confidence gating.
   - Cost: no per-request fee.

2. Optional on-device Core ML model (free runtime once bundled)
   - Example repos:
     - https://github.com/chase-robbins/CoreML-Acne-Detection-Model
     - https://github.com/aryansk/SkinCare.ai
   - Use: increase precision/confidence for acne-like classes.
   - Cost: no per-request fee (compute runs on user device).

3. MediaPipe Face Mesh (open source, local)
   - URL: https://github.com/google-ai-edge/mediapipe/wiki/MediaPipe-Face-Mesh
   - Use: denser landmarks for finer region warping.
   - Cost: no per-request fee.
   - Trade-off: heavier integration complexity vs Vision.

## Decision
Implement now:
- Vision-first local analysis + confidence score
- optional Core ML inference hook if a bundled model exists
- cloud escalation only below confidence threshold

## Implemented in code
- `Nura/Managers/LocalSkinAnalysisService.swift`
- `Nura/Managers/SkinAnalysisManager.swift` (embedded local service)
  - Face detection + landmarks with Vision
  - Per-region metrics (acne/oil/dryness proxies)
  - Local condition generation + skin score
  - Optional Core ML request (if `.mlmodelc` exists in bundle)
  - Confidence-based cloud escalation signal

- `Nura/Managers/SkinAnalysisManager.swift`
  - Runs local analysis first
  - Skips cloud call when local confidence is high
  - Uses cloud only when local confidence is low
  - Falls back to local result if cloud call fails
  - Marks provider as `hybrid-local-cloud` when both are used

- `Nura/Models/DataModels.swift`
  - Added providers:
    - `vision-local`
    - `coreml-local`
    - `hybrid-local-cloud`

## Next step for more precision
Bundle a segmentation/detection Core ML model and map output masks to affected areas for per-pixel overlays.
