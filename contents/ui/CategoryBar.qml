/*
 * CategoryBar
 * -----------
 * Horizontal arm of the XMB cross.
 *
 * ONE source of truth: `position`, a fractional index in category units. It drives
 * layout, emphasis and selection. There is deliberately NO ListView/Flickable here
 * — the bar is a plain strip of items translated by `position`. That removes the
 * Flickable's inertial momentum, which was the real cause of the reversal overshoot:
 * velocity could pile up against the end-of-list bound and discharge in a burst.
 * Here `position` is hard-clamped to [0, count-1] and is integrated directly, so
 * there is no stored velocity — reversing direction just integrates the other way
 * from the clamped value, one category at a time.
 *
 * Motion sources are mutually exclusive and never fight:
 *   - keyboard / click / wheel -> a NumberAnimation glides `position` to an integer
 *     (OutCubic), committing the selection immediately.
 *   - mouse edge hot zones -> a FrameAnimation integrates `position` at a
 *     distance-based speed (px/s converted to index/s, scaled by the frame delta,
 *     so it is refresh-rate independent), with a magnetic notch that slows the
 *     glide near each category centre; leaving the zone snaps to the nearest
 *     category (OutCubic) and commits.
 */
import QtQuick

Item {
    id: bar

    // --- model & geometry ---
    property var model
    readonly property int count: model ? model.length : 0
    property int iconSize: 112
    property real intersectionX: width * 0.30      // fixed cross point (x)

    readonly property int cellWidth: Math.round(iconSize * 2.0)
    readonly property int cellHeight: Math.round(iconSize * 1.7)
    readonly property int cellSpacing: Math.round(iconSize * 0.25)
    readonly property int step: cellWidth + cellSpacing   // distance between detents

    height: cellHeight

    // --- THE single source of truth ---
    property real position: 0
    readonly property int currentIndex: count > 0
        ? Math.max(0, Math.min(count - 1, Math.round(position))) : 0
    onCountChanged: position = Math.max(0, Math.min(Math.max(0, count - 1), position))

    // --- pointer, in screen coords (bar spans the full width at x=0) ---
    property real pointerX: 0
    property real pointerY: 0
    property bool pointerActive: false

    // --- vertical activation band: hot zones fire only at the category-row height ---
    property real bandCenterY: 0
    property real bandHeight: 360

    // --- feel parameters (exposed in the config page) ---
    // Left/right hot zones are sized independently (the XMB cross sits off-centre
    // to the left, so the comfortable edge widths differ per side).
    property real hotZoneFractionLeft: 0.15
    property real hotZoneFractionRight: 0.15
    property real minScrollSpeed: 150       // px/s just inside the threshold
    property real maxScrollSpeed: 2600      // px/s at the extreme edge
    property int  snapDuration: 220         // ms, glide/snap animation
    property real magneticStrength: 0.7     // 0 = none .. ~1 = strong glue near centres

    readonly property real speedCurveExponent: 2.5   // gentle near threshold, fast at edge
    readonly property real magneticSharpness: 2.2    // notch sharpness around a detent
    readonly property real maxFrameDt: 0.05          // cap per-frame step (s)

    signal committed(int index)

    // ---- hot-zone sensing -> direction + eased, distance-based speed ----
    // A zone fires only when the cursor is BOTH near a left/right edge AND inside
    // the vertical band around the category row.
    readonly property bool withinBand: pointerActive
        && (bandHeight <= 0 || Math.abs(pointerY - bandCenterY) <= bandHeight / 2)
    readonly property real hotZonePxLeft:  Math.max(1, width * hotZoneFractionLeft)
    readonly property real hotZonePxRight: Math.max(1, width * hotZoneFractionRight)
    readonly property real depthRight: withinBand ? Math.max(0, (pointerX - (width - hotZonePxRight)) / hotZonePxRight) : 0
    readonly property real depthLeft:  withinBand ? Math.max(0, (hotZonePxLeft - pointerX) / hotZonePxLeft) : 0
    readonly property int  scrollDirection: depthRight > 0 ? 1 : (depthLeft > 0 ? -1 : 0)
    readonly property real depth: Math.min(1, Math.max(depthRight, depthLeft))
    readonly property real scrollSpeed: scrollDirection === 0 ? 0
        : minScrollSpeed + (maxScrollSpeed - minScrollSpeed) * Math.pow(depth, speedCurveExponent)

    readonly property bool scrolling: scrollDirection !== 0 && count > 1

    // While scrolling via the mouse hot zones, commit each category the instant it
    // becomes current (as the keyboard does), so the app column loads its icons live
    // instead of waiting for the settle/snap. Gated on `scrolling` so it never fires
    // during keyboard/click glides (those commit through selectIndex).
    onCurrentIndexChanged: if (scrolling) committed(currentIndex)

    onScrollingChanged: {
        if (scrolling)
            glide.stop()            // hand control to the frame driver
        else
            snapToNearest()         // settle on the nearest category and commit
    }

    // Magnetic notch: scales the glide speed down toward a floor at a detent centre
    // (absPhase 0) and up to full speed between detents (absPhase 0.5). The floor
    // stays > 0 so the bar keeps creeping; the real settle is the snap on exit.
    function notchFactor(absPhase) {
        var floor = 1.0 - Math.max(0, Math.min(0.95, magneticStrength))
        var t = Math.min(1, absPhase / 0.5)
        return floor + (1.0 - floor) * Math.pow(t, magneticSharpness)
    }

    // Frame driver: integrate `position` in index-units per second. Refresh-rate
    // independent (multiplied by the real frame delta) and hard-clamped to the ends,
    // so it can neither overshoot nor accumulate momentum.
    FrameAnimation {
        running: bar.scrolling
        onTriggered: bar.advance(frameTime)
    }
    function advance(dt) {
        if (count <= 1 || scrollSpeed <= 0)
            return
        dt = Math.min(dt, maxFrameDt)
        var phase = position - Math.round(position)          // -0.5 .. 0.5
        var vIndex = (scrollSpeed / step) * scrollDirection * notchFactor(Math.abs(phase))
        position = Math.max(0, Math.min(count - 1, position + vIndex * dt))
    }

    // ---- discrete glide (keyboard / click / snap) ----
    property bool _commitOnGlideEnd: false
    NumberAnimation {
        id: glide
        target: bar
        property: "position"
        easing.type: Easing.OutCubic
        onFinished: {
            if (bar._commitOnGlideEnd) {
                bar._commitOnGlideEnd = false
                bar.committed(bar.currentIndex)
            }
        }
    }
    function animateTo(target, dur) {
        glide.stop()
        glide.from = position
        glide.to = Math.max(0, Math.min(count - 1, target))
        glide.duration = dur
        glide.start()
    }
    function snapToNearest() {
        if (count <= 0)
            return
        _commitOnGlideEnd = true
        animateTo(Math.round(position), snapDuration)
    }
    function selectIndex(i) {
        i = Math.max(0, Math.min(count - 1, i))
        _commitOnGlideEnd = false
        animateTo(i, snapDuration)
        committed(i)                // keyboard / click commit immediately
    }
    function goPrev() { selectIndex(currentIndex - 1) }
    function goNext() { selectIndex(currentIndex + 1) }

    // ---- visuals: a strip translated so item[position] sits at the intersection ----
    Item {
        id: strip
        y: 0
        height: bar.cellHeight
        x: bar.intersectionX - bar.cellWidth / 2 - bar.position * bar.step

        Repeater {
            model: bar.model
            XmbItemDelegate {
                required property var modelData
                required property int index

                x: index * bar.step
                width: bar.cellWidth
                height: bar.cellHeight
                labelBelow: true
                interactive: false        // no hand cursor / no click on categories
                iconSize: bar.iconSize
                iconSource: modelData.icon
                label: modelData.name
                selected: index === bar.currentIndex
                // Fractional distance => smooth fade as the bar glides past.
                neighbourDistance: Math.abs(index - bar.position)

                // Categories are navigated ONLY via the edge hot zones (and the
                // keyboard); clicking a category does not select it.
            }
        }
    }
}
