# 🎄 Terminal Winter Christmas

A full-terminal animated ASCII winter landscape in pure Bash featuring:
- **Shimmering Northern Lights** across the top of the sky
- **Santa's Sleigh & 3 Galloping Reindeer** flying across the crescent moon and dropping parachuting gifts
- **3-Tiered Giant Pine Tree** with 4 selectable lighting modes
- **Animated Waving Snowman**, antique streetlamp, and a 2-story winter lodge with flickering fireplace and rising chimney smoke
- **Dynamic Fireworks & Blizzard Mode** with full terminal resize support

## 🚀 Quick Run (No Installation)

Stream and run directly in your terminal:

```bash
curl -sL [https://raw.githubusercontent.com/gezwegen/winter-christmas/main/winter_christmas.sh](https://raw.githubusercontent.com/gezwegen/winter-christmas/main/winter_christmas.sh) | bash
```

Pass custom arguments when streaming (such as a custom banner message or snow count):

```bash
curl -sL [https://raw.githubusercontent.com/gezwegen/winter-christmas/main/winter_christmas.sh](https://raw.githubusercontent.com/gezwegen/winter-christmas/main/winter_christmas.sh) | bash -s -- -m "HAPPY HOLIDAYS!" -s 120
```

## 📦 Download & Run Locally

```bash
curl -sLO [https://raw.githubusercontent.com/gezwegen/winter-christmas/main/winter_christmas.sh](https://raw.githubusercontent.com/gezwegen/winter-christmas/main/winter_christmas.sh)
chmod +x winter_christmas.sh
./winter_christmas.sh
```

## ⌨️ Interactive Controls

While the animation is running, press:
- **L** — Cycle Tree Light Modes (*Rainbow*, *Classic*, *Frozen*, *Sparkle*)
- **B** — Toggle Blizzard Mode (high wind & heavy snow)
- **F** — Launch a Firework burst
- **H** — Show / Hide the bottom controls HUD
- **Q** — Quit cleanly
