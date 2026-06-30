/*
 * AppColumn
 * ---------
 * The vertical arm of the XMB cross. Same technique as CategoryBar but vertical:
 * the current app is pinned to a fixed y (the intersection) and the list glides
 * up/down around it. When the category changes the whole model is swapped and we
 * cross-fade + reset to the top so there is no jarring long scroll.
 *
 * `model` is a kicker AbstractModel (rootModel.modelForRow(sourceRow)); its rows
 * expose the standard `display` (name) and `decoration` (icon) roles, plus
 * trigger(row, actionId, argument) to launch.
 */
import QtQuick

Item {
    id: column

    // --- inputs ---
    property int iconSize: 56
    property real intersectionY: height * 0.5    // fixed pin point (y of the cross)
    property alias model: list.model
    property alias currentIndex: list.currentIndex
    property alias count: list.count
    // When true, the list ignores wheel/drag (e.g. while the top bar's quick settings
    // are hovered, so the wheel adjusts those instead of scrolling the app list).
    property bool wheelLocked: false

    signal appLaunched()

    readonly property int cellHeight: Math.round(iconSize * 1.45)

    // Optional launch override: when set, called with the current row index instead of
    // model.trigger() (used by the Favourites category, whose ListModel has no trigger()).
    property var launchHandler: null

    // Navigation entry points used by Dashboard's key handler.
    function up()   { list.decrementCurrentIndex() }
    function down() { list.incrementCurrentIndex() }
    function launchCurrent() {
        if (list.currentIndex < 0)
            return
        if (column.launchHandler) {
            column.launchHandler(list.currentIndex)
            column.appLaunched()
        } else if (list.model) {
            list.model.trigger(list.currentIndex, "", null)
            column.appLaunched()
        }
    }

    // When the selected category changes, restart from the top and cross-fade in.
    onModelChanged: {
        list.currentIndex = 0
        list.positionViewAtBeginning()
        fade.restart()
    }

    ListView {
        id: list
        anchors.fill: parent
        spacing: Math.round(column.iconSize * 0.30)
        currentIndex: 0
        keyNavigationEnabled: false
        interactive: !column.wheelLocked

        // Pin the current app to the intersection; glide the rest around it.
        preferredHighlightBegin: column.intersectionY - column.cellHeight / 2
        preferredHighlightEnd: column.intersectionY - column.cellHeight / 2
        highlightRangeMode: ListView.StrictlyEnforceRange
        highlightMoveDuration: 240
        highlightMoveVelocity: -1
        boundsBehavior: Flickable.StopAtBounds

        delegate: XmbItemDelegate {
            // Standard Qt model roles exposed by the kicker AbstractModel.
            required property string display
            required property var decoration
            required property int index

            width: list.width
            height: column.cellHeight
            labelBelow: false                 // app style: icon left, name right
            iconSize: column.iconSize
            iconSource: decoration
            label: display
            selected: ListView.isCurrentItem
            // Hand cursor and click only on the centred app; non-centred apps
            // cannot be selected by the mouse (navigation is via the wheel).
            interactive: ListView.isCurrentItem
            neighbourDistance: Math.abs(index - list.currentIndex)

            onClicked: column.launchCurrent()   // only the centred app can fire this
        }

        NumberAnimation {
            id: fade
            target: list
            property: "opacity"
            from: 0.0; to: 1.0
            duration: 260
            easing.type: Easing.OutCubic
        }
    }
}
