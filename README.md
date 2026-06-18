# 🌐 Zyro Browser 🚀

<p align="center">
  <img src="animation.svg" width="100%" alt="Zyro Browser Architecture Banner">
</p>

<p align="center">
  <img src="badges.svg" width="100%" alt="Zyro Tech Stack Badges">
</p>

**Zyro Browser** is a premium, high-performance, real-time web browser styled around a futuristic Cyber-Bento design. Featuring a decentralized, sandboxed extension engine, system-level content blockers, and an adaptive video extraction system powered by a companion Node.js backend. It unites a high-fidelity **Flutter Mobile Client** and a high-performance **Node.js/FFmpeg Microservice** into a singular, cohesive surfing environment.

<br></br>

## 🌌 Core Modules

<table>
<tr>
<td width="33%" valign="top">

### 📱 Cyber-Bento UI

A futuristic browser interface designed around glassmorphism, fluid navigation, and premium mobile usability.

#### ✨ Features

* Floating Bento Dock Navigation
* Multi-Tab Browser Management
* Modern Dark & Light Themes
* Glassmorphic UI Components
* Smart History Tracking
* Persistent Bookmarks System
* Quick Navigation Actions
* Responsive Mobile Experience

</td>

<td width="33%" valign="top">

### 🛡️ Extension Engine

A sandboxed extension ecosystem built for security, customization, and real-time browser enhancements.

#### ✨ Features

* Dynamic Extension Registry
* Script Injection Framework
* Network-Level Content Filters
* Built-In Ad Blocker
* Tracker & Popup Protection
* CSS/JS Page Cleanup
* Floating Download HUD
* Real-Time Stream Detection

</td>

<td width="33%" valign="top">

### ⚙️ Media Pipeline

A dedicated Node.js media backend responsible for extraction, transcoding, and file delivery.

#### ✨ Features

* Adaptive Resolution Detection
* Video & Audio Stream Analysis
* FFmpeg Processing Pipeline
* Automatic Stream Merging
* Background Download Queue
* Static Download Hosting
* Local Playback Support
* Device Storage Integration

</td>
</tr>
</table>



<br> </br>
### 🚀 What Makes Zyro Different?

| Capability               | Description                                                               |
| ------------------------ | ------------------------------------------------------------------------- |
| 🎨 Cyber-Bento Design    | Premium futuristic interface inspired by modern operating systems         |
| 🛡️ Native Ad Blocking   | Blocks ads, trackers, and intrusive scripts directly inside the WebView   |
| 🎬 Smart Video Detection | Detects playable media streams and exposes download options automatically |
| ⚡ High Performance       | Flutter frontend paired with a lightweight Node.js backend                |
| 🔌 Extension Ecosystem   | Custom sandboxed extension framework designed for future expansion        |
| 📥 Media Downloads       | Download, process, store, and play media directly from the browser        |

✨ Zyro Browser combines a modern browser engine, a customizable extension platform, and a powerful media processing pipeline into a single seamless experience.


<br></br>
## 🧭 Architecture Overview

The interaction flow between the sandboxed client, the extension engine, and the video downloader microservice is structured as follows:

<p align="center">
  <img src="architecture.svg" width="100%" alt="Zyro Browser Core Architecture Flow">
</p>

*✨ Live data-flow animation — glowing dots travel the connector lines to show requests, messages, and files moving through the system in real time.*

<br></br>

## 📦 Project Structure

```text
zyro/
│
├── 📱 zyro-frontend/
│   │
│   ├── lib/
│   │   ├── core/
│   │   │   ├── tab_manager.dart
│   │   │   ├── webview_wrapper.dart
│   │   │   ├── extension_manager.dart
│   │   │   └── browser_data_manager.dart
│   │   │
│   │   ├── app/
│   │   │   ├── screens/
│   │   │   └── widgets/
│   │   │
│   │   └── features/
│   │       ├── downloads/
│   │       ├── media_player/
│   │       └── browser_extensions/
│   │
│   ├── assets/
│   ├── android/
│   ├── ios/
│   └── pubspec.yaml
│
├── ⚙️ zyro-backend/
│   │
│   ├── src/
│   │   ├── routes/
│   │   │   └── download.routes.js
│   │   │
│   │   ├── services/
│   │   │   ├── fileManager.service.js
│   │   │   └── downloadQueue.service.js
│   │   │
│   │   └── server.js
│   │
│   ├── downloads/
│   ├── temp/
│   └── package.json
│
├── architecture.svg
├── animation.svg
├── badges.svg
└── README.md
```

### 📱 Frontend (Flutter)

| Module         | Purpose                                             |
| -------------- | --------------------------------------------------- |
| `core/`        | Browser engine, tab management, extensions, storage |
| `app/screens/` | Browser pages, settings, bookmarks, downloads       |
| `app/widgets/` | Cyber-Bento UI components and reusable widgets      |
| `features/`    | Media player, downloads, extension modules          |
| `assets/`      | Icons, animations, images, and UI resources         |

---

### ⚙️ Backend (Node.js)

| Module       | Purpose                                              |
| ------------ | ---------------------------------------------------- |
| `server.js`  | Express application entry point                      |
| `routes/`    | API endpoints for metadata and downloads             |
| `services/`  | Stream extraction, queue processing, file management |
| `downloads/` | Completed media storage                              |
| `temp/`      | Temporary processing and FFmpeg workspace            |

---

### 🔥 Core Components

| Component              | Responsibility                                  |
| ---------------------- | ----------------------------------------------- |
| `TabManager`           | Multi-tab browser session management            |
| `WebViewWrapper`       | WebView configuration and JS bridge integration |
| `ExtensionManager`     | Ad-blocking and extension execution             |
| `BrowserDataManager`   | History, bookmarks, downloads persistence       |
| `DownloadQueueService` | Media extraction and processing workflow        |
| `FileManagerService`   | File creation, cleanup, and storage management  |

💡 The architecture is intentionally split into a lightweight Flutter client and a dedicated Node.js media-processing backend, ensuring smooth browsing performance while handling media extraction and transcoding separately.

<br></br>
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

<br></br>
## ⚡ Browser Engine Optimizations

Behind the scenes, Zyro Browser includes a collection of performance, stability, and usability enhancements designed to create a smoother browsing experience across all supported devices.

<table>
<tr>
<td width="33%" valign="top">

### 🌐 Navigation Engine

* Seamless popup handling
* Multi-window support
* Improved redirect management
* Better compatibility with modern websites

</td>

<td width="33%" valign="top">

### 🎯 User Experience

* Optimized address bar alignment
* Consistent navigation behavior
* Responsive interaction feedback
* Smooth viewport transitions

</td>

<td width="33%" valign="top">

### 🚀 Performance & Stability

* Fast application startup
* Lightweight splash initialization
* Reduced runtime overhead
* Improved session reliability

</td>

</tr>
</table>

💡 These optimizations work behind the scenes to ensure faster page rendering, smoother navigation, better compatibility, and a more reliable browsing experience.


<br></br>
## 👨‍💻 Developer

<div align="center">

### Ashish Goswami

<br/>

<p align="center">

<a href="mailto:ashishgoswami1013@gmail.com">
<img src="https://img.icons8.com/fluency/48/gmail-new.png" width="40"/>
</a>


<a href="https://www.linkedin.com/in/ashish-goswami-58797a24a">
<img src="https://img.icons8.com/fluency/48/linkedin.png" width="40"/>
</a>

<a href="https://www.instagram.com/a.s.h.i.s.h__g.o.s.w.a.m.i">
<img src="https://img.icons8.com/fluency/48/instagram-new.png" width="40"/>
</a>

<a href="https://portfolio-omega-sand-67.vercel.app">
<img src="https://img.icons8.com/fluency/48/domain.png" width="40"/>
</a>

</p>

<br/>

*"Passionate about building modern applications, browser technologies, and user-focused digital products."*

</div>

---


<div align="center">

<img src="https://capsule-render.vercel.app/api?type=rect&color=0:5B8FB9,50:B6EADA,100:301E67&height=3&section=footer" width="220"/>

<br/>

<sub>
🌐 Built with Flutter, Node.js & FFmpeg • Crafted by Ashish Goswami
</sub>

</div>


