/*
 * XmbTopBar — top-edge reveal of the XMB system functions (text only, no background).
 *
 * Self-contained, independent of Plasma's system screen edges. A thin trigger strip at
 * the very top of the (fullscreen) dashboard reveals, top-LEFT, a minimal chevron `›`.
 * Clicking it expands the Power actions (org.kde.plasma.private.sessions) as a VERTICAL
 * list of plain-text labels (same light XMB styling as the clock); the dashboard blurs
 * behind them (driven by `powerExpanded`, like the search). Clicking again — or the bar
 * auto-hiding 1.5 s after the pointer leaves — collapses it. No icons, no panel.
 *
 * Anchor to fill the dashboard; transparent and non-interactive until revealed.
 */
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import org.kde.plasma.private.sessions as Sessions

Item {
    id: root

    signal actionTriggered()

    property bool revealed: false
    property bool powerExpanded: false
    property int labelSize: Math.max(16, Math.round(height * 0.021))
    // true while the pointer is over the bar's interactive content (chevron/power/quick),
    // used by the dashboard to blur the XMB and route the wheel to the quick settings.
    readonly property bool contentHovered: chevronHover.hovered || powerHover.hovered || quick.hovered

    onRevealedChanged: if (!revealed) powerExpanded = false

    Sessions.SessionManagement { id: session }

    // Wheel routing for the quick settings — SAME approach as the search overlay: a
    // WheelHandler on the FULLSCREEN bar root (above the XMB), enabled while a quick
    // setting is hovered, so the wheel adjusts it and never reaches the app list below.
    WheelHandler {
        enabled: quick.hovered
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: (event) => quick.wheelStep(event.angleDelta.y > 0)
    }

    function stillHovered() {
        return topTrigger.hovered || chevronHover.hovered || powerHover.hovered || quick.hovered
    }
    function maybeHide() {
        if (!stillHovered()) hideTimer.restart()
    }
    Timer {
        id: hideTimer
        interval: 1500   // hardcoded 1.5 s before autohide once the cursor leaves
        onTriggered: if (!root.stillHovered()) root.revealed = false
    }

    // ---- minimal chevron, top-LEFT ----
    Item {
        id: chevronBox
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: Math.round(root.height * 0.02) + (root.revealed ? 0 : -8)
        anchors.leftMargin: Math.round(root.width * 0.03)
        Behavior on anchors.topMargin { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        width: Math.round(root.labelSize * 2.2)
        height: width

        visible: root.revealed || opacity > 0.01
        opacity: root.revealed ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 160 } }

        HoverHandler { id: chevronHover; onHoveredChanged: root.maybeHide() }

        Text {
            anchors.centerIn: parent
            text: "›"   // ›
            color: "white"
            opacity: chevronHover.hovered || root.powerExpanded ? 1.0 : 0.78
            Behavior on opacity { NumberAnimation { duration: 120 } }
            font.pixelSize: Math.round(root.labelSize * 1.7)
            font.weight: Font.Light
            rotation: root.powerExpanded ? 90 : 0    // › -> v when open
            Behavior on rotation { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true; shadowColor: Qt.rgba(0, 0, 0, 0.7)
                shadowBlur: 0.7; shadowVerticalOffset: 1
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.powerExpanded = !root.powerExpanded
        }
    }

    // ---- power actions: VERTICAL list under the chevron ----
    ColumnLayout {
        id: powerCol
        anchors.top: chevronBox.bottom
        anchors.left: chevronBox.left
        anchors.topMargin: Math.round(root.labelSize * 0.4)
        anchors.leftMargin: Math.round(root.labelSize * 0.3)
        spacing: Math.round(root.labelSize * 0.9)

        visible: root.powerExpanded || powerCol.opacity > 0.01
        opacity: root.powerExpanded ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 160 } }

        HoverHandler { id: powerHover; onHoveredChanged: root.maybeHide() }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true; shadowColor: Qt.rgba(0, 0, 0, 0.7)
            shadowBlur: 0.7; shadowVerticalOffset: 1
        }

        Repeater {
            model: [
                { label: i18n("Lock"),      act: "lock",     on: session.canLock },
                { label: i18n("Log out"),   act: "logout",   on: session.canLogout },
                { label: i18n("Sleep"),     act: "suspend",  on: session.canSuspend },
                { label: i18n("Restart"),   act: "reboot",   on: session.canReboot },
                { label: i18n("Shut down"), act: "shutdown", on: session.canShutdown }
            ]
            delegate: Text {
                id: btn
                required property var modelData
                visible: modelData.on
                text: modelData.label
                color: "white"
                opacity: itemHover.hovered ? 1.0 : 0.74
                Behavior on opacity { NumberAnimation { duration: 120 } }
                font.pixelSize: root.labelSize
                font.weight: Font.Light
                font.letterSpacing: 1

                HoverHandler { id: itemHover; cursorShape: Qt.PointingHandCursor }
                TapHandler {
                    onTapped: {
                        switch (btn.modelData.act) {
                        case "lock":     session.lock(); break
                        case "logout":   session.requestLogout(); break
                        case "suspend":  session.suspend(); break
                        case "reboot":   session.requestReboot(); break
                        case "shutdown": session.requestShutdown(); break
                        }
                        root.actionTriggered()
                    }
                }
            }
        }
    }

    // ---- centre: quick settings (brightness / volume / network) ----
    XmbQuickSettings {
        id: quick
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Math.round(root.height * 0.02) + (root.revealed ? 0 : -8)
        Behavior on anchors.topMargin { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        labelSize: root.labelSize
        active: root.revealed
        visible: root.revealed || opacity > 0.01
        opacity: root.revealed ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 160 } }
        onCloseRequested: root.actionTriggered()
        onHoveredChanged: root.maybeHide()   // re-arm autohide on enter/leave
    }

    // ---- thin trigger strip pinned to the very top edge ----
    Item {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 8
        HoverHandler {
            id: topTrigger
            onHoveredChanged: if (hovered) root.revealed = true; else root.maybeHide()
        }
    }
}
