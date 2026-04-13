# KeyMute

A tiny, always-on macOS menu bar app that mutes and unmutes your microphone
**system-wide** with a single global keyboard shortcut.

Built so you can silence yourself instantly during Zoom / Google Meet / Microsoft
Teams calls — even while screen-sharing — without ever leaving the app you're in.

![macOS](https://img.shields.io/badge/macOS-13%2B-000?style=flat-square&logo=apple&logoColor=white)
![Size](https://img.shields.io/badge/Size-~700KB-2ea44f?style=flat-square)
![Shortcut](https://img.shields.io/badge/Default%20Shortcut-%E2%8C%98%E2%87%A50-7B61FF?style=flat-square)

> Default shortcut: **`⌘⇧0`** · Footprint: **~700 KB** · No Dock icon, no clutter.

---

## Install in one command

> [!TIP]
> **The easiest way — no Xcode, no drag-and-drop, no Gatekeeper warnings.**

```bash
curl -fsSL https://raw.githubusercontent.com/ankitaniket/KeyMute/main/install.sh | bash
```

That's it. The mic icon will appear in your menu bar — press **`⌘⇧0`** to toggle.

<details>
<summary><b>What this command does</b></summary>

1. Looks up the latest release tag (`v1.0.0`, `v1.0.1`, …)
2. Downloads the latest `.dmg` from GitHub Releases
3. Mounts the DMG
4. Quits any running Mutify
5. Copies `Mutify.app` into `/Applications`
6. **Strips the macOS quarantine attribute** — this is what kills the
   *"Apple cannot verify…"* / *"damaged"* warnings
7. Verifies the code signature
8. Unmounts the DMG and launches Mutify

No clicks. No drag. No "damaged". No "Apple cannot verify".

</details>

> [!IMPORTANT]
> **Requires macOS 13 Ventura or later.** Nothing else — `curl`, `hdiutil`, and
> `xattr` are all built into macOS.

### Manual install (DMG)

If you'd rather drag-and-drop:

1. Grab the latest **`Mutify-x.y.z.dmg`** from the [Releases page](https://github.com/ankitaniket/KeyMute/releases).
2. Open it → drag **Mutify.app** → **Applications** folder.
3. **Right-click** Mutify in Applications → **Open** → click **Open** in the
   Gatekeeper dialog. (Or run `xattr -dr com.apple.quarantine /Applications/Mutify.app`
   in Terminal first to skip the dialog entirely.)
4. On first toggle, click **Allow** when macOS asks for Microphone permission.

---

## Why?

Every video conferencing app has its own mute button, and they're all in
different places. When you're sharing your screen — running a demo, walking
through code, presenting slides — reaching for the in-app mute button is
awkward, slow, and visible to everyone watching.

KeyMute gives you **one shortcut that works everywhere**. Press it from any app,
in any state, and your microphone is muted at the **operating system level** —
which means Zoom, Meet, Teams, the browser, and every other app instantly see
silence.

---

## Features

- **System-wide mute** — works regardless of which app is using the mic.
- **Global shortcut** — default `⌘⇧0`, fully customizable in Settings.
- **Always-present menu bar icon** — flips between mic and red muted icon so you always know your status at a glance.
- **Bottom-right toast HUD** — shows "Muted" / "Unmuted" for ~1.2 s as visual confirmation.
- **Hidden from screen sharing** — the toast window has `sharingType = .none`, so meeting participants never see your "Muted" toasts on a shared screen. Only you do.
- **Launch at login** — toggleable from Settings, uses Apple's modern `SMAppService` API.
- **Input device picker** — pin a specific mic or follow the system default. Per-device mute state is remembered.
- **Force Mute / Force Unmute shortcuts** — separate shortcuts in addition to toggle, for scripting or Stream Deck.
- **Auto-mute on Focus mode** — automatically mute when macOS Focus / Do Not Disturb turns on.
- **Auto-mute on sleep** — automatically mute when your Mac goes to sleep (closing the lid).
- **Three icon styles** — Adaptive, Colorful, or Monochrome.
- **Optional "MUTED" label** — show "MUTED" text next to the icon when muted.
- **Built-in auto-update** — Check for Updates from the menu bar, powered by Sparkle.
- **Stays in sync** — listens to CoreAudio property changes, so muting from System Settings updates the app in real time.
- **Lightweight** — final binary is **~700 KB**. No Electron, no runtime.

---

## How it works

KeyMute mutes your microphone at the **operating system level** using CoreAudio's
`kAudioDevicePropertyMute` on the default input device. This is equivalent to
flipping the input mute switch in **System Settings → Sound → Input** — except it
happens instantly from a keyboard shortcut.

Because the mute is applied at the *device* level (not per-app), **every
application using the mic immediately reads silence**, including conferencing apps
that have their own software mute UIs. Zoom / Meet / Teams will visually reflect
the muted state too.

---

## First launch

1. A mic icon appears in your menu bar. **No Dock icon.**
2. Press `⌘⇧0` — macOS will pop a **Microphone permission** dialog. Click **Allow**.
3. Press `⌘⇧0` again — the icon flips to red muted, and a "Muted" toast
   fades in at the bottom-right of your screen.
4. Press it again to unmute.

**Click** the menu bar icon to:
- Toggle mute
- Pick input device
- Configure keyboard shortcuts
- Access all settings
- Check for updates
- Quit the app

---

## Permissions

| Permission           | Required? | Why                                                                                               |
| -------------------- | --------- | ------------------------------------------------------------------------------------------------- |
| **Microphone**       | Yes       | macOS gates writes to CoreAudio mute on input devices behind TCC. Prompted on first toggle.       |
| **Accessibility**    | No        | Uses Carbon hotkeys, which don't need Accessibility.                                              |
| **Screen Recording** | No        | Never captures your screen.                                                                       |
| **Input Monitoring** | No        | Carbon hotkeys are scoped, not raw keystrokes.                                                    |

---

## License

All rights reserved. Copyright 2026 Ankit Aniket.

---

## Links

- [Releases](https://github.com/ankitaniket/KeyMute/releases)
- [Report an issue](https://github.com/ankitaniket/KeyMute/issues)
