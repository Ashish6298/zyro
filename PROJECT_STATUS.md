# Zyro Browser - Project Intelligence (Phase 1 Conclusion)

This document serves as the persistent memory for the Zyro Browser project, summarizing the architecture, decisions, and state as of Phase 1 completion.

## 🧠 Core Architecture
- **Tab State**: Managed via `TabManager` (Provider) and `TabModel`. Each tab has its own `InAppWebViewController` and state (e.g., `isDesktopMode`).
- **WebView Layer**: `WebViewWrapper` handles the underlying engine. It includes custom `InAppWebViewSettings` to fix navigation bugs and support complex web events.
- **UI System**: A custom "Cyber-Bento" design language.
  - **GlassContainer**: Reusable glassmorphism component.
  - **Bento Dock**: Floating bottom nav with specialized context buttons.
  - **CyberMenu**: A grid-based modal for advanced browser actions.

## 🛠️ Configuration & Dependencies
- **Android**: `minSdkVersion 21` (configured in `build.gradle.kts`).
- **Dependencies**: `flutter_inappwebview`, `provider`, `google_fonts`, `lucide_icons`, `uuid`.

## 📜 Phase 1 Key Fixes
- **Interaction Fix**: Enabled `javaScriptCanOpenWindowsAutomatically` and `supportMultipleWindows` to allow search results and complex portal links to function.
- **Centering Fix**: Applied `TextAlignVertical.center` and `isCollapsed: true` to the address bar to ensure the URL doesn't float upside.
- **Splash Fix**: Switched to text-only animations to prevent runtime `File` errors.

## 🚀 Future Roadmap (Phase 2)
1. **Extension Engine**: 
   - Implement `manifest.json` parser.
   - Build a sandboxed JavaScript injection bridge in `ScriptEngine`.
   - Create local storage for extension states.
2. **Context Persistence**: 
   - Integrate `shared_preferences` or `sqflite` to persist tabs across app restarts.
3. **Advanced UI**: 
   - History and Bookmarks management screens.

---
*Created by Antigravity on 2026-04-10*
