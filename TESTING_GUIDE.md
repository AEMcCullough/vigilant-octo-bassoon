# Testing Guide: Vibe

Since you are on Windows, you have three primary ways to test and verify **Vibe** before submission.

## 1. Automated: GitHub Actions (Recommended)
This is the most "hands-off" way to verify that the code builds and the tests pass on a real Mac.
- **Set up**: Create a new private repository on GitHub.
- **Action**: Push the `vibe-app` folder to the repository.
- **Result**: Go to the **Actions** tab on GitHub. You will see a workflow running that generates the project, builds the app, and runs all [Unit and UI tests](file:///C:/Users/aemcc/.gemini/antigravity/scratch/vibe-app/VibeTests/VibeTests.swift).

## 2. Immediate: Swift Playgrounds (iPad/Mac)
If you have an iPad, you can test the code natively without a developer account.
- **Set up**: Download **Swift Playgrounds** from the App Store.
- **Action**: Create a new App project and copy-paste the code from `ContentView.swift`, `HapticsManager.swift`, and `PhysicsScene.swift`.
- **Result**: You will be able to feel the haptics and see the physics simulation live on your device.

## 3. Web-Preview (Visual & Conceptual)
I have created a **[preview.html](file:///C:/Users/aemcc/.gemini/antigravity/scratch/vibe-app/preview.html)** file in your project folder.
- **Action**: Open this file on your phone's browser.
- **Result**: It simulates the "Mercury" fluid physics and basic haptic pulses (dependent on browser support) to give you a feel for the UI/UX direction.

---
*Note: Real Core Haptics (.ahap files) can only be truly felt on physical iOS hardware (iPhone 8 or newer).*
