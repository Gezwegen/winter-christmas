# 🎄 Animated Terminal Christmas Tree & Winter Landscape (Bash ASCII Art)

![Bash](https://img.shields.io/badge/Language-Pure_Bash-4EAA25?logo=gnu-bash&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Linux_%7C_macOS_%7C_WSL-blue)
![License](https://img.shields.io/badge/License-CC_BY--NC--SA_4.0-red)

A full-screen, zero-dependency **animated ASCII Christmas tree and winter landscape** written in pure Bash. Turn any Linux, macOS, or Windows WSL terminal into an interactive holiday screensaver with falling snow, Santa's sleigh, Northern Lights, and fireworks—runnable in one command via `curl`.

<p align="center>
  <img width="1280" height="720" alt="demo-small" src="https://github.com/user-attachments/assets/d9558c94-77b7-4bf0-a08f-afe4ba8b3cae" />
</p>

## ✨ Features

- **Full-Terminal Auto-Scaling:** Dynamically adapts to your terminal window dimensions (`SIGWINCH` support).
- **Interactive Lighting Modes:** Cycle between *Rainbow Spiral*, *Classic Warm Gold*, *Frozen Ice Blue*, and *Disco Sparkle* tree ornaments.
- **Santa's Sleigh & Galloping Reindeer:** Multi-frame animated reindeer team flying across a crescent moon and dropping parachuting gifts.
- **Living Winter Village:** Features a shimmering Aurora Borealis, an animated waving snowman, a glowing antique streetlamp, and a 2-story winter lodge with a flickering fireplace and rising chimney smoke.
- **Blizzard & Fireworks Engine:** Toggle high-wind snowstorms or launch multi-stage ASCII fireworks in the night sky on demand.

## 🚀 Run Instantly via Curl (No Installation Required)

Paste this one-liner into any terminal to stream and launch the animation immediately:

```bash
curl -sL https://raw.githubusercontent.com/gezwegen/winter-christmas/main/winter_christmas.sh | bash
```

Customize the bottom marquee message and snowflake density when streaming:

```bash
curl -sL https://raw.githubusercontent.com/gezwegen/winter-christmas/main/winter_christmas.sh | bash -s -- -m "HAPPY HOLIDAYS FROM LINUX!" -s 120
```

## 📦 Download & Run Locally

```bash
git clone https://github.com/gezwegen/winter-christmas.git
cd winter-christmas
chmod +x winter_christmas.sh
./winter_christmas.sh
```

## ⌨️ Interactive Keyboard Controls

Press any of these keys while the terminal animation is running:

- **`L`** — Cycle Christmas tree lighting modes (*Rainbow*, *Classic*, *Frozen*, *Sparkle*)
- **`B`** — Toggle Blizzard Mode (high wind & fast diagonal snowfall)
- **`F`** — Launch an ASCII firework burst
- **`H`** — Show or hide the bottom controls HUD
- **`Q`** — Quit cleanly and restore your terminal cursor
