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
    // true while over interactive content; drives the XMB blur and wheel routing
    readonly property bool contentHovered: chevronHover.hovered || powerHover.hovered || quick.hovered

    onRevealedChanged: if (!revealed) powerExpanded = false

    Sessions.SessionManagement { id: session }

    // Handler sits on the fullscreen root so the wheel adjusts the setting and never reaches the app list below
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
        interval: 1500   // autohide delay after the cursor leaves
        onTriggered: if (!root.stillHovered()) root.revealed = false
    }

    // chevron, top-left
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
            text: "›"
            color: "white"
            opacity: chevronHover.hovered || root.powerExpanded ? 1.0 : 0.78
            Behavior on opacity { NumberAnimation { duration: 120 } }
            font.pixelSize: Math.round(root.labelSize * 1.7)
            font.weight: Font.Light
            rotation: root.powerExpanded ? 90 : 0
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

    // power actions
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

    // quick settings
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
        onHoveredChanged: root.maybeHide()
    }

    // trigger strip pinned to the top edge
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
