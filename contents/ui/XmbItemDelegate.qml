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

    // Emphasis: shrink + fade non-selected items. We use `scale` (not a size
    // change) so the layout spacing stays constant -> the classic XMB look where
    // dimmed neighbours leave visible gaps around the focused item.
    scale: selected ? 1.0 : 0.66
    opacity: selected ? 1.0 : Math.max(0.30, 0.85 - neighbourDistance * 0.18)

    Behavior on scale   { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

    // ---- category layout: icon with a label underneath ----
    Column {
        visible: delegate.labelBelow
        anchors.centerIn: parent
        spacing: Math.round(delegate.iconSize * 0.12)

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
