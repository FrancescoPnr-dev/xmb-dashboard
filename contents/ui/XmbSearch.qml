/*
 * XmbSearch — minimal type-to-search (KRunner) for the dashboard.
 *
 * Hidden until the user types a letter/digit; then a single query line appears at the TOP
 * (not centred) with text-only results, using the SAME Kirigami.Heading font as the
 * dashboard's category/app labels. Enter/click runs the selected result; Esc or emptying
 * the query (backspace) exits and returns focus to the dashboard. Backed by
 * org.kde.milou ResultsModel (KRunner).
 *
 * Anchor to fill the dashboard. Invisible and non-interactive until active.
 */
import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.milou as Milou

FocusScope {
    id: search

    property bool active: false
    signal launched()    // a result was run -> dashboard should close
    signal closed()      // search dismissed -> return focus to the dashboard

    function start(ch) {
        input.text = ch
        active = true
        input.forceActiveFocus()
        input.cursorPosition = input.text.length
    }
    function stop() {
        if (!active) return
        active = false
        input.text = ""
        list.currentIndex = 0
        search.closed()
    }
    function runCurrent() {
        if (list.count > 0 && list.currentIndex >= 0
                && rmodel.run(rmodel.index(list.currentIndex, 0)))
            search.launched()
        search.stop()
    }

    visible: active
    opacity: active ? 1.0 : 0.0
    Behavior on opacity { NumberAnimation { duration: 120 } }

    Milou.ResultsModel { id: rmodel; queryString: input.text; limit: 10 }

    // same font as the dashboard labels (category = level 3, app = level 4)
    Kirigami.Heading { id: queryFont; level: 3; visible: false }

    // Left click outside the query/results dismisses the search (not the dashboard).
    // Middle (wheel) click anywhere runs the highlighted result.
    MouseArea {
        anchors.fill: parent
        enabled: search.active
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.MiddleButton) search.runCurrent()
            else search.stop()
        }
    }

    // While searching, the wheel moves the SELECTION (kept centred, XMB-style) and is
    // fully consumed here, so it never reaches the XMB's app column underneath.
    WheelHandler {
        enabled: search.active
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: (event) => {
            if (event.angleDelta.y > 0) list.decrementCurrentIndex()
            else if (event.angleDelta.y < 0) list.incrementCurrentIndex()
        }
    }

    Column {
        anchors.top: parent.top
        anchors.topMargin: Math.round(search.height * 0.06)
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.round(search.width * 0.5)
        spacing: Math.round(search.height * 0.012)

        TextInput {
            id: input
            width: parent.width
            horizontalAlignment: TextInput.AlignHCenter
            color: "white"
            font: queryFont.font
            selectByMouse: true
            onTextEdited: if (text.length === 0) search.stop()
            Keys.onEscapePressed: search.stop()
            Keys.onReturnPressed: search.runCurrent()
            Keys.onEnterPressed: search.runCurrent()
            Keys.onUpPressed: list.decrementCurrentIndex()
            Keys.onDownPressed: list.incrementCurrentIndex()

            Rectangle {   // subtle underline
                anchors.bottom: parent.bottom
                anchors.bottomMargin: -Math.round(search.height * 0.006)
                width: parent.width
                height: 1
                color: Qt.rgba(1, 1, 1, 0.22)
            }
        }

        ListView {
            id: list
            property int rowHeight: Math.round(search.height * 0.05)
            width: parent.width
            // compact, grows with the results, anchored right below the search bar
            height: Math.min(list.count, 9) * list.rowHeight
            clip: true
            model: rmodel
            currentIndex: 0
            interactive: false              // wheel/keys drive the selection, no drag-flick
            keyNavigationEnabled: false

            // Current pinned near the TOP (just under the bar); the rest glide under it
            // (XMB feel). Not centred on the screen.
            preferredHighlightBegin: 0
            preferredHighlightEnd: 0
            highlightRangeMode: ListView.StrictlyEnforceRange
            highlightMoveDuration: 220
            highlightMoveVelocity: -1
            boundsBehavior: Flickable.StopAtBounds

            delegate: Kirigami.Heading {
                id: d
                required property var model
                required property int index
                level: 4
                width: ListView.view ? ListView.view.width : 0
                height: list.rowHeight
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: d.model.display
                elide: Text.ElideRight
                color: "white"
                // centred item bright, neighbours fade out (XMB)
                opacity: 1.0 - Math.min(0.72, Math.abs(d.index - list.currentIndex) * 0.26)
                Behavior on opacity { NumberAnimation { duration: 120 } }

                TapHandler {
                    onTapped: { list.currentIndex = d.index; search.runCurrent() }
                }
            }
        }
    }
}
