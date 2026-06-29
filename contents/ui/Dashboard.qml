/*
 * Dashboard
 * ---------
 * The fullscreen, semi-transparent XMB overlay. It is a top-level frameless
 * Window (not a plasmoid popup) so it can cover the whole screen like the native
 * Application Dashboard. It hosts:
 *   - the kicker RootModel (same data source as Kickoff),
 *   - an Instantiator that turns the categorised top-level rows into a plain JS
 *     array (so hidden categories can be filtered and the app submodel reached
 *     by source row without QSortFilterProxyModel::mapToSource, which QML can't call),
 *   - the cross layout (CategoryBar + AppColumn) and all navigation.
 */
import QtQuick
import QtQuick.Window
import org.kde.plasma.private.kicker as Kicker

Window {
    id: dashboard

    // --- configuration, injected by main.qml from Plasmoid.configuration ---
    property real backgroundOpacity: 0.85
    property int categoryIconSize: 112
    property int appIconSize: 56
    property real intersectionXFraction: 0.30
    property var hiddenCategories: []

    // Category-bar mouse feel (see CategoryBar.qml).
    property real hotZoneFractionLeft: 0.15
    property real hotZoneFractionRight: 0.15
    property int  minScrollSpeed: 150
    property int  maxScrollSpeed: 2600
    property int  snapDuration: 220
    property real magneticStrength: 0.7
    property int  hotZoneBandHeight: 360   // px band around the category row (BUG3)

    // The committed category (drives the app column). Updated only on a real
    // selection — keyboard, click, or a settled hot-zone snap — NOT on every frame
    // of a glide, so the app list does not reload while the bar is scrolling.
    property int committedIndex: 0

    // Rebuilt whenever the model or the hidden list changes.
    property var categories: []

    // --- window setup ---
    width: Screen.width
    height: Screen.height
    color: "transparent"
    // Keep flags minimal: a fullscreen window already sits in KWin's fullscreen
    // layer (above the panel), so Qt.WindowStaysOnTopHint is unnecessary and, on
    // Wayland, the StaysOnTop + frameless + parentless combination can stop the
    // surface from mapping at all. Frameless alone is enough.
    flags: Qt.FramelessWindowHint
    transientParent: null
    visible: false

    // Auto-close when focus is lost — but ONLY after the window has actually
    // become active at least once. On Wayland the window does not get keyboard
    // focus synchronously after show(), so a naive "close when !active" check
    // fires during the open transition and the overlay closes instantly (the
    // user just sees "nothing happens"). everActive guards against that.
    property bool autoCloseArmed: false
    property bool everActive: false

    function open() {
        console.log("XMB: Dashboard.open() called")
        autoCloseArmed = false
        everActive = false
        dashboard.showFullScreen()
        dashboard.raise()
        dashboard.requestActivate()
        content.forceActiveFocus()
        armTimer.restart()
        console.log("XMB: after show -> visible=" + dashboard.visible
                    + " visibility=" + dashboard.visibility)
    }
    function close() {
        console.log("XMB: Dashboard.close() called")
        autoCloseArmed = false
        everActive = false
        dashboard.visible = false
    }
    function toggle() {
        console.log("XMB: Dashboard.toggle(), currently visible=" + dashboard.visible)
        dashboard.visible ? close() : open()
    }

    onVisibleChanged: console.log("XMB: Dashboard visibleChanged -> " + visible)

    onActiveChanged: {
        if (active) {
            everActive = true
        } else if (autoCloseArmed && everActive) {
            close()
        }
    }
    Timer {
        id: armTimer
        interval: 350
        onTriggered: dashboard.autoCloseArmed = true
    }

    // ---------------------------------------------------------------------
    // Data source: identical to Kickoff. showAllAppsCategorized => each
    // top-level row is an XDG menu category with its freedesktop icon, and
    // rootModel.modelForRow(i) is that category's app list.
    // ---------------------------------------------------------------------
    Kicker.RootModel {
        id: rootModel
        autoPopulate: true
        showAllApps: false
        showAllAppsCategorized: true
        showRecentApps: false
        showRecentDocs: false
        showRecentFolders: false
        showPowerSession: false
        showFavoritesPlaceholder: false
        showSeparators: false
        appNameFormat: 0            // 0 = application name only
        onCountChanged: Qt.callLater(dashboard.rebuildCategories)
    }

    // Non-visual mirror of the categories so we can read name + icon per source
    // row in plain JS (no QAbstractItemModel::index() needed).
    Instantiator {
        id: categorySource
        model: rootModel
        delegate: QtObject {
            required property string display
            required property var decoration
            readonly property string name: display
            readonly property var icon: decoration
        }
        onObjectAdded: Qt.callLater(dashboard.rebuildCategories)
        onObjectRemoved: Qt.callLater(dashboard.rebuildCategories)
    }

    onHiddenCategoriesChanged: rebuildCategories()

    function rebuildCategories() {
        var arr = []
        for (var i = 0; i < categorySource.count; i++) {
            var o = categorySource.objectAt(i)
            if (!o)
                continue
            if (hiddenCategories.indexOf(o.name) !== -1)
                continue
            arr.push({ name: o.name, icon: o.icon, sourceRow: i })
        }
        categories = arr
        // currentIndex is derived (read-only); CategoryBar self-clamps its position
        // on count change. We only clamp the committed index here.
        if (committedIndex > Math.max(0, arr.length - 1))
            committedIndex = Math.max(0, arr.length - 1)
    }

    // The committed category and its app submodel (app column follows committedIndex,
    // not the live bar position).
    readonly property var currentCategory:
        (committedIndex >= 0 && committedIndex < categories.length)
            ? categories[committedIndex] : null
    readonly property var appsModel:
        currentCategory ? rootModel.modelForRow(currentCategory.sourceRow) : null

    // ---------------------------------------------------------------------
    // Visuals
    // ---------------------------------------------------------------------

    // Dark semi-transparent backdrop. (Blur behind it would need the KWin blur
    // protocol, which a plain Window can't request on Wayland -- see README.)
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, dashboard.backgroundOpacity)
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    FocusScope {
        id: content
        anchors.fill: parent
        focus: true

        // The conceptual cross intersection (fixed, center-left like the PS3).
        readonly property real interX: width * dashboard.intersectionXFraction
        // The horizontal bar sits a little above centre; the selected app pins at
        // centre, so apps fan out above and below the bar without colliding with
        // the selected category icon. Tweak these two to taste.
        readonly property real barCenterY: height * 0.42
        readonly property real appPinY: height * 0.52

        // Click on empty space closes the dashboard.
        MouseArea {
            anchors.fill: parent
            onClicked: dashboard.close()
        }

        // Tracks the cursor across the whole overlay and feeds it to the category
        // bar's edge hot zones (passive: does not block clicks/hover on items).
        HoverHandler {
            id: pointerTracker
        }

        // Horizontal arm -------------------------------------------------
        CategoryBar {
            id: categoryBar
            width: parent.width
            y: content.barCenterY - height / 2
            intersectionX: content.interX
            iconSize: dashboard.categoryIconSize
            model: dashboard.categories
            z: 1

            // Mouse hot-zone feel.
            pointerX: pointerTracker.point.position.x
            pointerY: pointerTracker.point.position.y
            pointerActive: pointerTracker.hovered
            bandCenterY: content.barCenterY        // band is centred on the category row
            bandHeight: dashboard.hotZoneBandHeight
            hotZoneFractionLeft: dashboard.hotZoneFractionLeft
            hotZoneFractionRight: dashboard.hotZoneFractionRight
            minScrollSpeed: dashboard.minScrollSpeed
            maxScrollSpeed: dashboard.maxScrollSpeed
            snapDuration: dashboard.snapDuration
            magneticStrength: dashboard.magneticStrength

            // Commit -> the app column follows the chosen category.
            onCommitted: (index) => dashboard.committedIndex = index
        }

        // Vertical arm ---------------------------------------------------
        AppColumn {
            id: appColumn
            x: content.interX - dashboard.appIconSize / 2
            y: 0
            width: 480
            height: parent.height
            intersectionY: content.appPinY
            iconSize: dashboard.appIconSize
            model: dashboard.appsModel
            z: 2
            onAppLaunched: dashboard.close()
        }

        // Navigation -----------------------------------------------------
        // Keyboard nav is unchanged in behaviour: goPrev/goNext animate the bar
        // (strict range) and commit immediately, so the app column updates at once.
        Keys.onLeftPressed:  categoryBar.goPrev()
        Keys.onRightPressed: categoryBar.goNext()
        Keys.onUpPressed:    appColumn.up()
        Keys.onDownPressed:  appColumn.down()
        Keys.onReturnPressed: appColumn.launchCurrent()
        Keys.onEnterPressed:  appColumn.launchCurrent()
        Keys.onEscapePressed: dashboard.close()

        // Scroll wheel: vertical -> apps, horizontal -> categories.
        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: (event) => {
                if (event.angleDelta.y < 0)       appColumn.down()
                else if (event.angleDelta.y > 0)  appColumn.up()
                if (event.angleDelta.x < 0)       categoryBar.goNext()
                else if (event.angleDelta.x > 0)  categoryBar.goPrev()
            }
        }
    }
}
