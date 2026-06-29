/*
 * main.qml — plasmoid entry point.
 *
 * The widget shows a single button in the panel; clicking it (or triggering the
 * applet's global shortcut) toggles a separate fullscreen Window (Dashboard.qml).
 *
 * Activation wiring mirrors the native Application Dashboard (kicker's isDash mode,
 * plasma-desktop/applets/kicker/CompactRepresentation.qml + main.qml):
 *   - The button is the applet's representation (shown inline in the panel).
 *   - Plasmoid.activationTogglesExpanded is set to false, so Plasma does NOT try to
 *     toggle an expanded popup on click. With the default (true), Plasma's applet
 *     wrapper consumes the click for popup handling and our MouseArea.onClicked
 *     never fires — which is exactly the "clicking does nothing" bug.
 *   - The click and the Plasmoid.activated() signal both call dashboard.toggle().
 */
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    // Show the button inline in the panel; we never use a Plasma popup.
    preferredRepresentation: fullRepresentation
    fullRepresentation: buttonComponent

    Plasmoid.icon: Plasmoid.configuration.panelIcon

    Component.onCompleted: {
        // Critical: without this, Plasma intercepts the click to manage popup
        // expansion and our handlers never run. kicker does the same for isDash.
        if (Plasmoid.hasOwnProperty("activationTogglesExpanded")) {
            Plasmoid.activationTogglesExpanded = false
        }
    }

    // The fullscreen overlay, wired to the live configuration values.
    Dashboard {
        id: dashboard
        backgroundOpacity: Plasmoid.configuration.backgroundOpacity
        categoryIconSize: Plasmoid.configuration.categoryIconSize
        appIconSize: Plasmoid.configuration.appIconSize
        intersectionXFraction: Plasmoid.configuration.intersectionXFraction
        hiddenCategories: Plasmoid.configuration.hiddenCategories
        hotZoneFractionLeft: Plasmoid.configuration.hotZoneFractionLeft
        hotZoneFractionRight: Plasmoid.configuration.hotZoneFractionRight
        minScrollSpeed: Plasmoid.configuration.minScrollSpeed
        maxScrollSpeed: Plasmoid.configuration.maxScrollSpeed
        snapDuration: Plasmoid.configuration.snapDuration
        magneticStrength: Plasmoid.configuration.magneticStrength
        hotZoneBandHeight: Plasmoid.configuration.hotZoneBandHeight
    }

    // Global shortcut / standard activation path (keyboard, "activate" action).
    Connections {
        target: Plasmoid
        function onActivated() {
            console.log("XMB: Plasmoid.activated()")
            dashboard.toggle()
        }
    }

    // The panel button: an Item (so the panel can size it) containing the icon
    // and a fill MouseArea on top to catch clicks.
    Component {
        id: buttonComponent

        Item {
            id: button

            Layout.minimumWidth: Kirigami.Units.iconSizes.small
            Layout.minimumHeight: Kirigami.Units.iconSizes.small
            Layout.maximumWidth: Kirigami.Units.iconSizes.enormous
            Layout.maximumHeight: Kirigami.Units.iconSizes.enormous

            Kirigami.Icon {
                id: buttonIcon
                anchors.fill: parent
                source: Plasmoid.icon
                active: mouseArea.containsMouse
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                activeFocusOnTab: true

                Accessible.name: Plasmoid.title
                Accessible.role: Accessible.Button

                Keys.onReturnPressed: Plasmoid.activated()
                Keys.onEnterPressed: Plasmoid.activated()
                Keys.onSpacePressed: Plasmoid.activated()

                onClicked: {
                    console.log("XMB: panel icon clicked")
                    dashboard.toggle()
                }
            }
        }
    }
}
