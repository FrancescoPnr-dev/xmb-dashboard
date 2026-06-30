/*
 * XmbItemDelegate
 * ----------------
 * Reusable icon + label cell used by BOTH the horizontal category bar and the
 * vertical app column. It owns the XMB "focus emphasis": the selected item is
 * large and fully opaque, neighbours shrink and fade with distance. All of that
 * is animated here (single place) via Behavior, so every view gets the same feel.
 *
 * The parent view is responsible only for telling us whether we are `selected`
 * and how far we are from the selection (`neighbourDistance`); it never animates.
 */
import QtQuick
import QtQuick.Effects
import org.kde.kirigami as Kirigami

Item {
    id: delegate

    // --- inputs from the view ---
    property var iconSource: ""          // icon name (string) or QIcon from the model
    property string label: ""
    property int iconSize: 64            // px of the icon at full (selected) size
    property bool selected: false
    property int neighbourDistance: 0    // 0 = selected, 1 = adjacent, ...
    property bool labelBelow: true       // true: category style (label under icon)
                                         // false: app style (label to the right)
    property bool interactive: true      // false: no hover cursor / no click emission
                                         // (categories are driven by the hot zones)

    signal clicked()

    // Emphasis: shrink + fade non-selected items. We scale (not resize) so the
    // layout spacing stays constant -> the classic XMB look where dimmed neighbours
    // leave visible gaps around the focused item.
    // Selected items pop to `selectedScale` (1.0 = unchanged, used by the category bar).
    // The app column raises it so the focused app icon grows close to — but not equal
    // to — the category icon, as on the PS3.
    property real selectedScale: 1.0
    property real emphasis: selected ? selectedScale : 0.66
    opacity: selected ? 1.0 : Math.max(0.30, 0.85 - neighbourDistance * 0.18)

    Behavior on emphasis { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Behavior on opacity  { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

    // PS3-style slow "breathing" glow on the focused item's label (enabled by the app
    // column). glowPulse drives the white halo's strength; it animates only while the
    // item is selected, so the category bar (glowWhenSelected = false) pays nothing.
    property bool glowWhenSelected: false
    property real glowPulse: 0.0
    SequentialAnimation on glowPulse {
        running: delegate.glowWhenSelected && delegate.selected
        loops: Animation.Infinite
        NumberAnimation { from: 0.30; to: 0.90; duration: 1500; easing.type: Easing.InOutSine }
        NumberAnimation { from: 0.90; to: 0.30; duration: 1500; easing.type: Easing.InOutSine }
    }

    // The app delegate spans the WHOLE column width (icon on the left, label far to
    // the right), so scaling around the delegate centre (the default) would swing the
    // shrunken icons sideways — the non-selected apps drift off to the side of their
    // category instead of stacking under it. We therefore scale around the ICON's
    // centre for the app style, so every app icon stays on the category's vertical
    // line (as on the real PS3). The category style keeps the delegate centre.
    // Optional vertical lift (px). The app column uses it so apps that scroll ABOVE
    // the selected one clear the category icon and stack above it (PS3 style) instead
    // of sliding over it. Animated, so the app "jumps over" the category as it rises.
    // Stays 0 for the category bar.
    property real extraTranslateY: 0
    Behavior on extraTranslateY { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

    transform: [
        Scale {
            origin.x: delegate.labelBelow ? delegate.width / 2 : delegate.iconSize / 2
            origin.y: delegate.height / 2
            xScale: delegate.emphasis
            yScale: delegate.emphasis
        },
        Translate { y: delegate.extraTranslateY }
    ]

    // ---- category layout: icon with a label underneath ----
    Column {
        visible: delegate.labelBelow
        anchors.centerIn: parent
        // Keep the category name tucked under its icon (not drifting toward the app row).
        spacing: Math.round(delegate.iconSize * 0.02)

        Kirigami.Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            width: delegate.iconSize
            height: delegate.iconSize
            source: delegate.iconSource
            // Crisp at the focused size even while scaled up/down a touch.
            smooth: true
        }
        Kirigami.Heading {
            anchors.horizontalCenter: parent.horizontalCenter
            level: 3
            text: delegate.label
            color: "white"
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            width: Math.min(implicitWidth, delegate.iconSize * 2.2)
        }
    }

    // ---- app layout: icon on the left, label to the right ----
    Row {
        visible: !delegate.labelBelow
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        spacing: Math.round(delegate.iconSize * 0.35)

        Kirigami.Icon {
            anchors.verticalCenter: parent.verticalCenter
            width: delegate.iconSize
            height: delegate.iconSize
            source: delegate.iconSource
            smooth: true
        }
        Kirigami.Heading {
            anchors.verticalCenter: parent.verticalCenter
            level: 4
            text: delegate.label
            color: "white"
            elide: Text.ElideRight
            width: Math.min(implicitWidth, 420)

            // Soft white halo whose strength breathes slowly, like the PS3's focused
            // item. The text stays crisp: MultiEffect draws the blurred glow behind the
            // sharp source. Only active on the selected app (glowWhenSelected).
            layer.enabled: delegate.glowWhenSelected && delegate.selected
            layer.effect: MultiEffect {
                autoPaddingEnabled: true
                blurMax: 32
                shadowEnabled: true
                shadowColor: "white"
                shadowBlur: 1.0
                shadowVerticalOffset: 0
                shadowHorizontalOffset: 0
                shadowOpacity: delegate.glowPulse
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        // Always present so a click is swallowed here (e.g. category clicks do not
        // fall through and close the dashboard), but the hover cursor and the
        // click action only apply when the delegate is interactive.
        hoverEnabled: delegate.interactive
        cursorShape: delegate.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (delegate.interactive) delegate.clicked()
    }
}
