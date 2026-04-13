# KeyMute

**One shortcut to mute your mic. Every app. Instantly.**

No windows. No Dock icon. No settings screens. Just a menu bar icon, a keyboard shortcut, and CoreAudio doing the work at the OS level.

![macOS](https://img.shields.io/badge/macOS-13%2B-000?style=flat-square&logo=apple&logoColor=white)
![Binary](https://img.shields.io/badge/Binary-~700KB-2ea44f?style=flat-square)
![RAM](https://img.shields.io/badge/Idle_RAM-~15MB-blue?style=flat-square)
![Shortcut](https://img.shields.io/badge/Default-%E2%8C%98%E2%87%A50-7B61FF?style=flat-square)

---

## The problem

You're screen-sharing. Someone asks a question. You need to mute — fast.

Zoom's mute is in one corner. Meet's is in another. Teams hides it behind a toolbar. And if you're presenting from a different app, you have to alt-tab back just to click a button everyone on the call can see you hunting for.

## The fix

```bash
curl -fsSL https://raw.githubusercontent.com/ankitaniket/KeyMute/main/install.sh | bash
```

Press **`⌘⇧0`**. Done. Your mic is muted at the **operating system level** — Zoom, Meet, Teams, browsers, everything hears silence instantly.

Press it again to unmute. That's the whole app.

---

## Why developers pick this over alternatives

### ~15 MB idle. Not 150.

No windows. No SwiftUI settings screens. No Dock icon. The entire UI is a single `NSStatusItem` and a lightweight `NSMenu`. There's no `NSWindow` allocated at runtime, no view hierarchy sitting in memory doing nothing.

Most "simple" menu bar apps ship a full settings window, a SwiftUI runtime, and an `NSHostingView` — even if you open settings once a month. That's 50-150 MB of idle RAM for a mute button. KeyMute stays at **~15 MB** because it doesn't load what it doesn't need.

### ~700 KB binary. Not 50 MB.

Pure AppKit + CoreAudio. No Electron. No web views. No bundled runtimes. The entire app is smaller than most favicons.

### OS-level mute, not app-level

KeyMute writes `kAudioDevicePropertyMute` on the system input device via CoreAudio. This is the same property macOS reads in **System Settings > Sound > Input**. Every app using the mic — Zoom, Meet, Teams, Chrome, OBS, anything — immediately reads silence. No per-app integration, no accessibility hacks.

### No Accessibility permission needed

Global shortcut uses Carbon `RegisterEventHotKey` (via [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts)). No Input Monitoring. No Accessibility prompt. Just Microphone permission on first use.

### It stays out of your way

- No Dock icon (runs as `LSUIElement`)
- No main window
- Toast HUD is `sharingType = .none` — invisible to screen share viewers
- Launch at login via `SMAppService` — set once, forget forever

---

## Features

| Feature | Details |
|---|---|
| **System-wide mute** | Works across all apps simultaneously |
| **Global shortcut** | Default `⌘⇧0`, fully customizable |
| **Force Mute / Unmute** | Separate shortcuts for scripting or Stream Deck |
| **Menu bar icon** | Adaptive, Colorful, or Monochrome styles |
| **Toast HUD** | "Muted" / "Unmuted" confirmation, hidden from screen share |
| **Device picker** | Pin a specific mic or follow system default |
| **Per-device memory** | Remembers mute state per audio device |
| **Auto-mute on Focus** | Mutes when macOS DND / Focus turns on |
| **Auto-mute on sleep** | Mutes when you close the lid |
| **Launch at login** | Modern `SMAppService` API |
| **Auto-update** | Built-in via Sparkle |
| **"MUTED" label** | Optional text next to the menu bar icon |

---

## Install

### One-liner (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/ankitaniket/KeyMute/main/install.sh | bash
```

Downloads the latest DMG, installs to `/Applications`, strips quarantine, launches. No Gatekeeper warnings.

### Manual

1. Download **Mutify-x.y.z.dmg** from [Releases](https://github.com/ankitaniket/KeyMute/releases)
2. Drag to Applications
3. Right-click > Open (first time only, for Gatekeeper)
4. Allow Microphone permission when prompted

---

## How it works

```
⌘⇧0  →  CoreAudio: kAudioDevicePropertyMute = 1  →  Every app hears silence
```

That's it. One `AudioObjectSetPropertyData` call on the default input device. The OS propagates the mute to every process reading from that device. CoreAudio property listeners keep the icon in sync if something else changes the mute state.

---

## Permissions

| Permission | Required | Reason |
|---|---|---|
| Microphone | Yes | CoreAudio mute writes are TCC-gated |
| Accessibility | No | Carbon hotkeys don't need it |
| Screen Recording | No | Nothing is captured |
| Input Monitoring | No | Scoped hotkeys, not raw keystrokes |

---

## Requirements

- macOS 13 Ventura or later
- That's it

---

[Releases](https://github.com/ankitaniket/KeyMute/releases) · [Report an issue](https://github.com/ankitaniket/KeyMute/issues)

Copyright 2026 Ankit Aniket. All rights reserved.
