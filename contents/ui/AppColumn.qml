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
    readonly property real listSpacing: Math.round(iconSize * 0.30)

    // Category-row geometry (in this column's coords, which share content's origin),
    // so apps scrolled ABOVE the selection can be lifted clear of the category icon.
    property real categoryCenterY: 0
    property int  categoryIconSize: 112

    // Focused app icon is just a touch larger than the dimmed neighbours — a few px,
    // not a category-sized jump.
    readonly property real selectedAppScale: 1.15

    // Extra upward lift applied to every app above the selected one, so the first of
    // them sits just above the category icon (the rest stack above it normally). This
    // opens the PS3 "gap" at the category row: above-apps jump over it, never overlap.
    readonly property real aboveGap: {
        var naturalAboveCenter = intersectionY - (cellHeight + listSpacing)
        var categoryTop = categoryCenterY - categoryIconSize / 2
        var desiredAboveCenter = categoryTop - cellHeight / 2 - Math.round(iconSize * 0.25)
        return Math.max(0, naturalAboveCenter - desiredAboveCenter)
    }

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

    // When the selected category changes, select the FIRST app and pin it at the cross
    // (the intersection), with empty space above and the rest flowing down — like the
    // PS3, where entering a category lands you on its first item. NOTE: we snap index 0
    // to the highlight position, NOT positionViewAtBeginning(): the latter parks index 0
    // at the very TOP of the view, which fights StrictlyEnforceRange and leaves a
    // mid-list app sitting at the cross instead of the first one.
    onModelChanged: {
        list.currentIndex = 0
        list.positionViewAtIndex(0, ListView.SnapPosition)
        fade.restart()
    }

    ListView {
        id: list
        anchors.fill: parent
        spacing: column.listSpacing
        currentIndex: 0
        keyNavigationEnabled: false
        // Non-interactive on purpose: an interactive ListView would consume the wheel
        // with its own inertial flick, so a fast scroll overshoots by several apps and
        // StrictlyEnforceRange snaps to an imprecise landing. Instead the wheel is driven
        // step-by-step by Dashboard's WheelHandler (one app per notch). Same reasoning as
        // CategoryBar, which deliberately avoids any Flickable. wheelLocked is handled by
        // that WheelHandler's `enabled` gate.
        interactive: false

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
            // Apps above the selection jump over the category and stack above it.
            extraTranslateY: index < list.currentIndex ? -column.aboveGap : 0
            // Focused app icon grows close to the category icon's size.
            selectedScale: column.selectedAppScale
            // Slow PS3 "breathing" glow on the focused app's name.
            glowWhenSelected: true

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
