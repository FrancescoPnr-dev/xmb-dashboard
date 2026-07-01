# XMB Dashboard

A fullscreen app launcher for KDE Plasma 6, inspired by the PlayStation 3 / PSP
**XrossMediaBar**. A panel icon opens a semi-transparent overlay with a horizontal
bar of app categories and the selected category's apps fanning out vertically —
navigable by keyboard, mouse wheel and mouse edges, with the classic wave
background, type-to-search and subtle sounds.

> Built and tested on Plasma 6.7 / Qt 6.

<!-- TODO: screenshot / gif -->

## Features

- XMB-style cross navigation (categories horizontal, apps vertical).
- Animated wave background with monthly colour presets and particles.
- Type anywhere to search (KRunner results).
- Mouse: wheel scrolls apps, screen edges scroll categories, middle-click launches
  the highlighted app.
- Navigation "tick" sound and an optional ambient background loop (both original,
  configurable, off by default where relevant).
- Lots of tunables in the settings: icon sizes, cross position, scroll feel,
  wave look, sounds, and which categories to show.

## Install

From the folder containing `metadata.json`:

```bash
# install
kpackagetool6 --type Plasma/Applet --install .
# update after changes
kpackagetool6 --type Plasma/Applet --upgrade .
# remove
kpackagetool6 --type Plasma/Applet --remove org.kde.plasma.xmbdashboard
```

Then add it from *Add Widgets…* and click its panel icon to open the dashboard.
For quick iteration during development, `plasmoidviewer --applet .` (from
`plasma-sdk`) loads straight from source.

## Usage

- **Arrows / wheel / screen edges** — move between apps and categories.
- **Enter or left-click** the highlighted app, or **middle-click anywhere** — launch it.
- **Start typing** — search; Enter or middle-click runs the top result.
- **Esc or click empty space** — close.

## Configuration

Right-click the widget → *Configure*. Sections for appearance, behaviour, the
mouse category bar, the wave background and colour, particles, sounds, and visible
categories. Each section has its own "reset to defaults".

## Credits & licence

- The wave background is a Qt/QML port of **[PlayStation-3-XMB]** by Mart (linkev),
  used under its MIT licence. That project in turn credits [Alphardex]'s CodePen
  prototype and Sony's original XMB design.
- All sounds are original synthesis (see `tools/`); no PlayStation audio is bundled.
- App data comes from Plasma's own menu model (the same one Kickoff uses).

Licensed under **GPL-3.0** (see the `LICENSES/` folder). The ported wave shaders keep
the required MIT attribution to the original author.

[PlayStation-3-XMB]: https://github.com/linkev/PlayStation-3-XMB
[Alphardex]: https://codepen.io/alphardex/pen/poPZNwE
