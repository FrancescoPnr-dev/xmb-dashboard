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
import QtQuick.Effects
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
    property bool manageScreenEdges: false  // disable system screen edges while open

    // --- XMB wave background (ps3xmbwave port), injected from Plasmoid.configuration.
    //     Defaults mirror the demo (spline-settings.js / particles-settings.js). ---
    property real waveFlowSpeed: 0.25
    property real waveBandAmplitude: 0.20
    property real waveHeightScale: 0.5
    property real waveSoftClip: 0.22
    property real waveTension: 0.12
    property real waveFresnelPower: 4.0
    property real waveFresnelScale: 0.5
    property real waveOpacity: 0.7
    property real waveBrightness: 0.98
    property int  waveRowCount: 200
    property int  waveColorMonth: 0
    property int  waveColorR: 37
    property int  waveColorG: 89
    property int  waveColorB: 179
    property real waveGradientTopMul: 0.09
    property real waveGradientBotMul: 0.62
    property bool waveParticlesEnabled: true
    property int  waveParticleCount: 2000
    property real waveParticleOpacity: 0.9
    property real waveParticleFlowSpeed: 0.8

    // The committed category (drives the app column). Updated only on a real
    // selection — keyboard, click, or a settled hot-zone snap — NOT on every frame
    // of a glide, so the app list does not reload while the bar is scrolling.
    property int committedIndex: 0

    // Rebuilt whenever the model or the hidden list changes.
    property var categories: []

    // --- window setup ---
    // Unique title: matched by the KWin "keep above" rule (install-kwin-rule.sh) so the
    // overlay stays above a revealing auto-hide panel.
    title: "XMB Dashboard"
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

    // Disables Plasma's own screen-EDGE actions while the overlay is up (restores on
    // close), so the dashboard can own the edges. Corners stay active.
    EdgeGuard { id: edgeGuard }

    function open() {
        console.log("XMB: Dashboard.open() called")
        autoCloseArmed = false
        everActive = false
        if (dashboard.manageScreenEdges)
            edgeGuard.disableSystemEdges()
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
        edgeGuard.restoreSystemEdges()
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
            // Stable, locale-independent key for persistence (the freedesktop icon
            // name, e.g. "applications-games-symbolic"). Falls back to the display
            // name only if a category exposes no icon.
            readonly property string key: decoration ? String(decoration) : display
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
            if (hiddenCategories.indexOf(o.key) !== -1)
                continue
            arr.push({ name: o.name, icon: o.icon, key: o.key, sourceRow: i })
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

    // Animated XMB wave backdrop (Qt6 ShaderEffect port of the linkev/PlayStation-3-XMB
    // ps3xmbwave demo). Loaded through a Loader so that if ShaderEffect is unavailable
    // (Qt Quick software backend) we fall back to a flat gradient and the dashboard still
    // opens. backgroundOpacity dims the whole backdrop over the desktop.
    Loader {
        id: backgroundLoader
        anchors.fill: parent
        opacity: dashboard.backgroundOpacity
        Behavior on opacity { NumberAnimation { duration: 150 } }
        source: Qt.resolvedUrl("WaveBackground.qml")

        onStatusChanged: {
            if (status === Loader.Error) {
                console.warn("XMB: ShaderEffect unavailable, using gradient fallback")
                source = Qt.resolvedUrl("WaveBackgroundFallback.qml")
            }
        }
        onLoaded: {
            item.animating = Qt.binding(function() { return dashboard.visible })
            // wave
            item.flowSpeed = Qt.binding(function() { return dashboard.waveFlowSpeed })
            item.bandAmplitude = Qt.binding(function() { return dashboard.waveBandAmplitude })
            item.waveHeightScale = Qt.binding(function() { return dashboard.waveHeightScale })
            item.waveSoftClip = Qt.binding(function() { return dashboard.waveSoftClip })
            item.tension = Qt.binding(function() { return dashboard.waveTension })
            item.fresnelPower = Qt.binding(function() { return dashboard.waveFresnelPower })
            item.fresnelScale = Qt.binding(function() { return dashboard.waveFresnelScale })
            item.waveOpacity = Qt.binding(function() { return dashboard.waveOpacity })
            item.brightness = Qt.binding(function() { return dashboard.waveBrightness })
            item.rowCount = Qt.binding(function() { return dashboard.waveRowCount })
            // gradient / colour
            if (item.hasOwnProperty("colorMonth"))
                item.colorMonth = Qt.binding(function() { return dashboard.waveColorMonth })
            item.colorR = Qt.binding(function() { return dashboard.waveColorR })
            item.colorG = Qt.binding(function() { return dashboard.waveColorG })
            item.colorB = Qt.binding(function() { return dashboard.waveColorB })
            item.gradientTopMul = Qt.binding(function() { return dashboard.waveGradientTopMul })
            item.gradientBotMul = Qt.binding(function() { return dashboard.waveGradientBotMul })
            // particles
            if (item.hasOwnProperty("particlesEnabled"))
                item.particlesEnabled = Qt.binding(function() { return dashboard.waveParticlesEnabled })
            if (item.hasOwnProperty("pDensity"))
                item.pDensity = Qt.binding(function() { return dashboard.waveParticleCount / 2000.0 })
            item.pOpacity = Qt.binding(function() { return dashboard.waveParticleOpacity })
            item.pFlowSpeed = Qt.binding(function() { return dashboard.waveParticleFlowSpeed })
        }
    }

    FocusScope {
        id: content
        anchors.fill: parent
        focus: true

        // Light blur over the XMB cross while the search, the top-bar power list, or a
        // top-bar quick setting is active. Animated for a soft fade in/out; the layer is
        // disabled once fully faded so there's no cost when idle.
        readonly property bool blurWanted: searchOverlay.active || topBar.powerExpanded || topBar.contentHovered
        property real blurAmt: blurWanted ? 0.45 : 0.0
        Behavior on blurAmt { NumberAnimation { duration: 260; easing.type: Easing.InOutQuad } }
        layer.enabled: blurAmt > 0.001
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: content.blurAmt
            blurMax: 24
            brightness: -0.08 * (content.blurAmt / 0.45)
        }

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
            // Don't let the wheel scroll the app list while the top bar (quick settings)
            // is under the pointer — the wheel adjusts those instead.
            wheelLocked: topBar.contentHovered
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

        // Type-to-search: a printable letter/digit (no modifiers) opens the minimal
        // KRunner overlay and seeds it with that character. Nav keys (empty text) fall
        // through to the handlers above.
        Keys.onPressed: (event) => {
            if (!searchOverlay.active
                    && event.text.length === 1 && event.text.trim().length === 1
                    && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) {
                searchOverlay.start(event.text)
                event.accepted = true
            }
        }

        // Scroll wheel: vertical -> apps, horizontal -> categories. Disabled while the
        // search overlay is active, so the wheel scrolls the results, not the app column.
        WheelHandler {
            enabled: !searchOverlay.active && !topBar.contentHovered
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: (event) => {
                if (event.angleDelta.y < 0)       appColumn.down()
                else if (event.angleDelta.y > 0)  appColumn.up()
                if (event.angleDelta.x < 0)       categoryBar.goNext()
                else if (event.angleDelta.x > 0)  categoryBar.goPrev()
            }
        }
    }

    // PS3-style system date + time, top-right.
    XmbClock {
        z: 100
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Math.round(dashboard.height * 0.06)
        anchors.rightMargin: Math.round(dashboard.width * 0.025)
        pixelSize: Math.max(20, Math.round(dashboard.height * 0.026))
    }

    // Top-edge reveal: XMB system bar (Power for now). Self-contained, independent of
    // Plasma's screen edges.
    XmbTopBar {
        id: topBar
        anchors.fill: parent
        z: 90
        onActionTriggered: dashboard.close()
    }

    // Type-to-search (KRunner), minimal and centred. Opened by typing (see content above).
    XmbSearch {
        id: searchOverlay
        anchors.fill: parent
        z: 110
        onLaunched: dashboard.close()
        onClosed: content.forceActiveFocus()
    }
}
