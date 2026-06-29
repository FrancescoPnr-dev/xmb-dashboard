# XMB Dashboard — a PS3/PSP XrossMediaBar launcher for Plasma 6

A native KDE Plasma 6 plasmoid. A panel icon opens a fullscreen, semi-transparent
overlay that replicates the Sony **XrossMediaBar (XMB)**: a horizontal bar of app
**categories** with the selected one pinned at a fixed center-left "cross"
intersection, and the selected category's **apps** fanning out vertically around it.

Targets Plasma 6 / Qt 6 / KDE Frameworks 6. Verified on Plasma 6.7.1 / Qt 6.11.

---

## 1. Install / run / live-reload

All commands assume the package root is `~/KDEwidget` (the folder
containing `metadata.json`).

```bash
# First install (per-user):
kpackagetool6 --type Plasma/Applet --install ~/KDEwidget

# After editing files — reload the installed copy:
kpackagetool6 --type Plasma/Applet --upgrade ~/KDEwidget

# Remove it:
kpackagetool6 --type Plasma/Applet --remove org.kde.plasma.xmbdashboard
```

**Add it to the panel:** right-click the panel → *Add or Manage Widgets…* →
search **“XMB Dashboard”** → drag it onto the panel. Then click its icon (or the
widget) to open the dashboard.

**Live-reload loop while developing.** QML is read at applet load, so after an
`--upgrade` you must make Plasma re-read it:

```bash
kpackagetool6 --type Plasma/Applet --upgrade ~/KDEwidget \
  && kquitapp6 plasmashell ; kstart plasmashell
```

The fastest iteration tool is `plasmoidviewer` (package **plasma-sdk**, not
installed here by default):

```bash
sudo pacman -S plasma-sdk        # provides plasmoidviewer
plasmoidviewer --applet ~/KDEwidget        # loads straight from source, no install
```

You can also smoke-test the data/QML headlessly (no Plasma restart) with:

```bash
qmllint -I contents/ui contents/ui/*.qml contents/ui/config/*.qml
```

### Verifying the config page and the click at runtime

`qmllint` does **not** catch every error — notably "Cannot override FINAL
property" and "Cannot assign to non-existent property" are *runtime* errors. Two
ways to catch them without a full Plasma restart:

```bash
# 1) Actually load a page/component offscreen — this DOES surface FINAL/runtime errors.
#    (Ignore "i18n is not defined": i18n only exists inside the real Plasma context.)
QT_FORCE_STDERR_LOGGING=1 QT_QPA_PLATFORM=offscreen qml6 contents/ui/config/ConfigGeneral.qml
```

After installing, to confirm the panel click opens the overlay, watch the journal
while you click the icon — the widget logs each step with an `XMB:` prefix:

```bash
journalctl --user -t plasmashell -f      # then click the panel icon
# Expected on a successful open:
#   XMB: panel icon clicked
#   XMB: Dashboard.toggle(), currently visible=false
#   XMB: Dashboard.open() called
#   XMB: Dashboard visibleChanged -> true
#   XMB: after show -> visible=true visibility=5      (5 = Window.FullScreen)
```
If you see `panel icon clicked` but no `open()` → the click isn't reaching the
Dashboard. If you see `visible=true` immediately followed by `visibleChanged ->
false` → the overlay is opening then auto-closing (focus issue). If everything
logs `true` but nothing appears on screen → it's a Wayland surface-mapping issue.
Each branch points at a different fix.

---

## 2. How the XMB “cross” navigation is implemented

The cross is two `ListView`s in **`StrictlyEnforceRange`** highlight mode — that
single mechanism is what pins the selection to a fixed point and glides everything
else around it.

- **`CategoryBar.qml`** — a *horizontal* `ListView`. Setting
  `preferredHighlightBegin == preferredHighlightEnd == intersectionX - cellWidth/2`
  forces the **current** item to stay at that exact x (the cross intersection).
  When `currentIndex` changes, the view scrolls the whole bar so the new current
  item lands on that x, animated by `highlightMoveDuration` (+ easing). That is the
  authentic “bar slides, selection stays put” XMB motion.
- **`AppColumn.qml`** — the same idea *vertically*: the current app is pinned at
  `intersectionY` and the list scrolls up/down around it. Swapping the category
  swaps the whole model, so it resets to the top and cross-fades in.
- **`XmbItemDelegate.qml`** — the reusable icon+label cell. It owns the focus
  emphasis: the selected item is `scale 1.0 / opacity 1.0`, neighbours shrink and
  fade by distance from the selection, each animated with `Behavior on scale` /
  `Behavior on opacity` (`Easing.OutCubic`). Using `scale` (not a size change)
  keeps the layout spacing constant, so dimmed neighbours leave the classic XMB
  gaps.
- **`Dashboard.qml`** glues it together: it places the bar slightly above centre
  and pins the app column at centre (`barCenterY` / `appPinY` — tweak these two to
  move the cross), and routes keyboard / wheel into the two views.

**Where to tweak things later:**
- Cross horizontal position → `intersectionXFraction` (config) or `content.interX`.
- Vertical relationship of bar vs apps → `barCenterY` / `appPinY` in `Dashboard.qml`.
- Scroll feel → `highlightMoveDuration` in `CategoryBar.qml` / `AppColumn.qml`.
- Emphasis (how small/faded neighbours get) → the `scale`/`opacity` formulas in
  `XmbItemDelegate.qml`.

### Why `ListView`, not `PathView`
`PathView` is great for curved/looping paths, but pinning the current item to an
*exact pixel* and scrolling a straight line around it is more direct and
controllable with `ListView` + `StrictlyEnforceRange`. The result is the same
straight-line XMB glide with less fighting the path math. If you later want a
curved sweep, both views can be swapped for `PathView` with a `Path` + `PathAttribute`
driving `scale`/`opacity`.

## 3. Data source

`Dashboard.qml` uses **`org.kde.plasma.private.kicker` `RootModel`** — the exact
model Kickoff/Kicker use — with `showAllAppsCategorized: true`. Each top-level row
is then an XDG menu category (Internet, Multimedia, Office, Graphics, Games,
System, Utilities…) carrying its real freedesktop icon and translated name, and
`rootModel.modelForRow(i)` is that category’s app list. Apps are launched with
`appsModel.trigger(row, "", null)` — again identical to Kickoff. No manual
`.desktop` parsing and no hand-rolled category mapping: the system menu already
provides it.

## 4. Plasma 6 / Wayland gotchas hit & resolved

- **"Cannot override FINAL property" in the config page.** A `Repeater` delegate
  that is a `QQC2.CheckBox` must NOT declare `required property string display`
  to read the model's display role: `AbstractButton` already has a FINAL `display`
  property (the icon/text display enum), so the same-named delegate property makes
  the whole config page fail to load (and cascades into bogus "ConfigurationShortcuts
  does not have a property called cfg_…" errors). Fix: read the role through the
  `model` object instead — `required property var model` then `model.display`.
  `qmllint` does **not** flag this; load the page offscreen with `qml6` to catch it.
- **Filtering hidden categories without `mapToSource`.** A `KSortFilterProxyModel`
  can hide categories, but `QSortFilterProxyModel::mapToSource` is **not invokable
  from QML**, so you can’t recover the source row needed by `modelForRow()`.
  Resolution: drop the proxy on the hot path and use a non-visual `Instantiator`
  over `RootModel` to read each category’s name/icon and build a plain JS array of
  `{name, icon, sourceRow}`; hiding is a simple array filter and the source row is
  carried along.
- **Fullscreen overlay.** The native Application Dashboard (`kickerdash`) has no QML
  of its own — it just re-skins `org.kde.plasma.kicker`. For a standalone widget
  the robust path is a top-level frameless `Window` (`showFullScreen()`), detached
  via `transientParent: null`, with `Qt.WindowStaysOnTopHint`. It’s its own window,
  not a plasmoid popup.
- **Blur behind the overlay.** A plain `Window` can’t request the KWin blur effect
  on Wayland (no blur protocol from arbitrary client windows), so the backdrop is a
  configurable dark `Rectangle` alpha rather than a real blur. (A true blur would
  need a small C++ helper using `KWindowEffects`, or running as a proper
  containment.)
- **Auto-close vs. focus.** Calling `forceActiveFocus()` right after
  `showFullScreen()` briefly toggles window `active`, which would instantly dismiss
  the overlay. Resolution: arm the “close on deactivate” watcher ~300 ms *after*
  opening (`armTimer`).
- **Valid `RootModel` properties.** `showRecentContacts` / `showSystemActions` do
  **not** exist on this build’s `RootModel` and make the component fail to load;
  the real knobs are `showRecentApps/Docs/Folders`, `showPowerSession`,
  `showFavoritesPlaceholder`, `showSeparators` (and inherited `AppsModel` ones like
  `autoPopulate`, `sorted`, `appNameFormat`). Verify against
  `kickerplugin.qmltypes` if you add more.

## 5. Configuration

Right-click the widget → *Configure XMB Dashboard…*:
- Background opacity
- Category icon size / App icon size
- Cross horizontal position
- Panel icon name
- Per-category show/hide checkboxes (populated live from the real menu categories)

## Files

```
metadata.json                      Plasma 6 applet manifest
contents/config/main.xml           config keys (KConfigXT)
contents/config/config.qml         config page list
contents/ui/main.qml               panel icon + opens the overlay
contents/ui/Dashboard.qml          fullscreen window, data model, cross layout, navigation
contents/ui/CategoryBar.qml        horizontal arm of the cross
contents/ui/AppColumn.qml          vertical arm of the cross
contents/ui/XmbItemDelegate.qml    reusable icon+label cell with focus emphasis
contents/ui/config/ConfigGeneral.qml  settings page
```
