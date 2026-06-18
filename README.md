# 🌐 Zyro Browser 🚀

<p align="center">
  <img src="animation.svg" width="100%" alt="Zyro Browser Architecture Banner">
</p>

<p align="center">
  <img src="badges.svg" width="100%" alt="Zyro Tech Stack Badges">
</p>

**Zyro Browser** is a premium, high-performance, real-time web browser styled around a futuristic Cyber-Bento design. Featuring a decentralized, sandboxed extension engine, system-level content blockers, and an adaptive video extraction system powered by a companion Node.js backend. It unites a high-fidelity **Flutter Mobile Client** and a high-performance **Node.js/FFmpeg Microservice** into a singular, cohesive surfing environment.

[Explore Frontend](file:///d:/zyro/zyro-frontend) • [Explore Backend](file:///d:/zyro/zyro-backend) • [View Architecture](#-architecture-overview)

---

## 🌌 Key Highlights & Modules

### 📱 Cyber-Bento UI Shell ("zyro-frontend")
The user interface follows a modern dark/light system designed to stand out, leveraging premium glassmorphism, depth-based layout, and a floating Bento Dock navigation unit.
1. **Interactive Bento Dock Navigation**:
   - Floating navigation bar at the bottom of the viewport with responsive context actions (Back, Forward, Refresh, Home, Tabs Panel).
   - Glassmorphic backdrop blurring (`backdrop-filter`) styled with cyber-neon contours.
2. **Multiplexed Tab Manager**:
   - Handles multi-tab surfing state using Flutter's `provider` pattern.
   - Dedicated dashboard sheets to list open viewports, create new instances, or clean up active sessions.
3. **Advanced History & Bookmarks**:
   - Local sqlite/file persistent records tracking browsing histories and favorites.
   - Easy action chips allowing instant jumps back into previous domains.

### 🛡️ Sandboxed Extension & Ad-Blocker Core
The system features a custom modular registry (`ExtensionManager`) allowing dynamic script injection and network-level content filters.
1. **Pre-installed Ad-Blocker**:
   - Multi-layer blocking mechanism integrating `ContentBlocker` rules directly within the WebView engine to stop advertisements, tracker pixels, and promotional scripts on-the-fly.
   - CSS/JS rules injection that formats layouts post-load, providing a clean ad-free environment.
2. **Video Sniffer & Extractor Extension**:
   - Background analyzer that scans incoming network requests, intercepts video stream sources, and renders a floating Download Option HUD when a valid stream is discovered.

### ⚙️ Companion Media Extraction Pipeline ("zyro-backend")
A high-performance media parsing server that communicates with the Flutter client to transcode, download, and distribute media assets.
1. **Adaptive Media Resolution**:
   - Uses `youtube-dl-exec` underneath to fetch and analyze page schemas, resolving direct high-quality video and audio stream links.
2. **FFmpeg Transcoding Pipeline**:
   - Interlinks audio and video streams and merges them dynamically using a `fluent-ffmpeg` worker queue to create a unified `.mp4` file.
3. **Static File Server**:
   - Hosts static downloads, allowing the Flutter UI client to play the extracted videos locally or trigger local mobile saves.

---

## 🧭 Architecture Overview

The interaction flow between the sandboxed client, the extension engine, and the video downloader microservice is structured as follows:

<p align="center">
  <img src="architecture.svg" width="100%" alt="Zyro Browser Core Architecture Flow">
</p>

*✨ Live data-flow animation — glowing dots travel the connector lines to show requests, messages, and files moving through the system in real time.*

---

## 📦 Detailed Project Structure

### 📱 [Frontend - zyro-frontend](file:///d:/zyro/zyro-frontend)
Contains the Flutter application logic and Cyber-Bento styling:
*   [lib/core/](file:///d:/zyro/zyro-frontend/lib/core): Core infrastructure classes.
    *   [tab_manager.dart](file:///d:/zyro/zyro-frontend/lib/core/tab_manager.dart): Multiplexes browser tabs using a state provider.
    *   [webview_wrapper.dart](file:///d:/zyro/zyro-frontend/lib/core/webview_wrapper.dart): Configures the underlying viewport, handles user gestures, and links JavaScript channels.
    *   [extension_manager.dart](file:///d:/zyro/zyro-frontend/lib/core/extension_manager.dart): Oversees external scripts and manages adblocking filters.
    *   [browser_data_manager.dart](file:///d:/zyro/zyro-frontend/lib/core/browser_data_manager.dart): Stores History, Bookmarks, and Downloads local databases.
*   [lib/app/](file:///d:/zyro/zyro-frontend/lib/app): Interface views and design modules.
    *   `screens/`: Dashboard sheets for Browser viewports, Bookmarks records, History sheets, and Extensions registry.
    *   `widgets/`: Cyber-Bento glassmorphism structures, neon indicators, dynamic badges.
*   [lib/features/](file:///d:/zyro/zyro-frontend/lib/features): Subsystems including media player controls and download managers.

### ⚙️ [Backend - zyro-backend](file:///d:/zyro/zyro-backend)
Provides media parsing and transcoding services:
*   [src/server.js](file:///d:/zyro/zyro-backend/src/server.js): Root setup configuration, serving assets and routing API controllers.
*   [src/routes/download.routes.js](file:///d:/zyro/zyro-backend/src/routes/download.routes.js): Mapping routes for requests:
    *   `POST /api/video/metadata`: Resolves page source to retrieve details (Thumbnails, Audio/Video Streams).
    *   `POST /api/video/download`: Dispatches background download pipeline worker.
    *   `GET /api/video/status/:taskId`: Returns download status, transfer rate, and percentage.
*   [src/services/](file:///d:/zyro/zyro-backend/src/services): Interacts with stream parsing binaries and file paths.
    *   `fileManager.service.js`: Manages directory generation and cleanup operations.
    *   `downloadQueue.service.js`: Resolves stream endpoints and pipes them through FFmpeg.

---

## 🛠️ Technology Stack & Dependencies

| Component | Technology | Purpose |
| :--- | :--- | :--- |
| **Frontend UI Shell** | **Flutter SDK (Dart)** | Immersive, high-performance cross-platform application |
| | **Provider** | State management, caching, and multi-tab reactivity |
| | **InAppWebView** | Native browser viewport substrate & JS hooks |
| | **Google Fonts** | Outfit & Inter typography configurations |
| | **Lucide Icons** | Premium neon vector icons library |
| **Backend Core** | **Node.js (Express)** | Media stream resolution microservice |
| | **youtube-dl-exec** | Page schema analysis and stream extraction |
| | **fluent-ffmpeg** | Dynamic video/audio stream muxer and transcoder |
| | **CORS & Express Static** | Asset hosting and cross-origin resource sharing |

---

## 🚀 Installation & Running

### Prerequisites
- **Node.js (v18+)**
- **FFmpeg** (Ensure binary is added to your system environment `PATH`)
- **Flutter SDK (v3.0+)**
- Android Emulator, iOS Simulator, or Physical device connected with USB debugging enabled.

---

### 1️⃣ Run Backend Microservice

1. Navigate to the backend folder:
   ```bash
   cd zyro-backend
   ```
2. Install package dependencies:
   ```bash
   npm install
   ```
3. Run backend on Development mode (Default port: 3000):
   ```bash
   npm run dev
   ```

---

### 2️⃣ Run Flutter Frontend Client

1. Verify minimum SDK requirements in `build.gradle.kts` (configured to `minSdkVersion 21`).
2. Navigate to the frontend folder:
   ```bash
   cd zyro-frontend
   ```
3. Retrieve packages and configure imports:
   ```bash
   flutter pub get
   ```
4. Execute application on the active simulator or connected device:
   ```bash
   flutter run
   ```

---

## 📜 Advanced Settings & WebView Tweaks

To deliver a flawless user experience, several key enhancements were configured in the underlying WebView core:
- **Popups & Redirects**: Enabled `javaScriptCanOpenWindowsAutomatically` and `supportMultipleWindows` settings. This allows search results and external redirects to open smoothly within the sandbox.
- **Address Bar Centering**: Integrated `TextAlignVertical.center` and `isCollapsed: true` styling inside the Flutter search field. This keeps the active URL aligned perfectly in the bar.
- **Dynamic Splash**: Employs a text-based, platform-independent splash loader to prevent runtime filesystem errors during initial device checks.

---

## 👨‍💻 Developer & Contact Info

Feel free to connect or reach out for inquiries, feedback, or collaborations:

- **GitHub Profile**: [@ashish6298](https://github.com/ashish6298)
- **LinkedIn Profile**: [Ashish Goswami](https://www.linkedin.com/in/ashish-goswami-58797a24a/)
- **Developer Portfolio**: [ashishgoswami.dev](https://portfolio-omega-sand-67.vercel.app/)
- **Email Contact**: [ashishgoswami1013@gmail.com](mailto:ashishgoswami1013@gmail.com)

---

<div align="center">
  <sub>Created &amp; Optimized with 🌐 &amp; 🧬 by Antigravity</sub>
</div>
