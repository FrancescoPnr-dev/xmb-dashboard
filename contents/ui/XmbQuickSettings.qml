/*
 * XmbQuickSettings — centre of the top reveal bar: Brightness, Volume, Network.
 *
 * Plain-text labels (XMB style, no icons). Hovering an item shows its current value and
 * lets the WHEEL adjust it: brightness via org.kde.Solid.PowerManagement BrightnessControl
 * (DBus), volume via wpctl (the default sink). Network is click-only -> opens the system
 * network settings. The wheel is consumed here so it never scrolls the XMB underneath.
 */
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import org.kde.plasma.plasma5support as P5Support

Item {
    id: qs

    property int labelSize: 18
    property bool active: false
    readonly property bool hovered: bandHover.hovered    // whole band, no gaps
    signal closeRequested()

    // Whole-band hover (covers the gaps between labels) -> blurs the XMB and enables the
    // wheel. The actual WheelHandler lives on the fullscreen bar root (like the search
    // overlay), and calls wheelStep() to drive whichever item is under the pointer.
    HoverHandler { id: bandHover }
    function wheelStep(up) {
        if (briHover.hovered) qs.briStep(up)
        else if (volHover.hovered) qs.volStep(up)
    }

    property int volPct: -1
    property int briPct: -1
    property int _briRaw: 0
    property int _briMax: 0

    // Real size (a bare Item does NOT adopt implicitWidth/Height), padded so the hover
    // band and the wheel cover the whole area including the gaps between labels.
    implicitWidth: rowL.implicitWidth + Math.round(labelSize * 2.6)
    implicitHeight: rowL.implicitHeight + Math.round(labelSize * 1.2)
    width: implicitWidth
    height: implicitHeight

    readonly property string briBase: "org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement/Actions/BrightnessControl"
    readonly property string volReadCmd: "wpctl get-volume @DEFAULT_AUDIO_SINK@"
    property string briReadCmd: "echo BRI_READ $(qdbus6 " + briBase + " brightness) $(qdbus6 " + briBase + " brightnessMax)"

    P5Support.DataSource {
        id: exec
        engine: "executable"
        onNewData: (src, data) => {
            var out = ((data["stdout"] || "") + "").trim()
            if (src.indexOf("get-volume") !== -1) {
                var m = out.match(/([0-9]*\.?[0-9]+)/)
                if (m) qs.volPct = Math.round(parseFloat(m[1]) * 100)
            } else if (src.indexOf("BRI_READ") !== -1) {
                var p = out.replace("BRI_READ", "").trim().split(/\s+/)
                if (p.length >= 2) {
                    qs._briRaw = parseInt(p[0]); qs._briMax = parseInt(p[1])
                    qs.briPct = qs._briMax > 0 ? Math.round(qs._briRaw * 100 / qs._briMax) : -1
                }
            }
            exec.disconnectSource(src)
        }
    }
    function run(c) { exec.connectSource(c) }
    function readAll() { run(volReadCmd); run(briReadCmd) }
    onActiveChanged: if (active) readAll()

    Timer { id: volReread; interval: 120; onTriggered: qs.run(qs.volReadCmd) }
    function volStep(up) {
        run("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%" + (up ? "+" : "-"))
        volReread.restart()
    }
    function briStep(up) {
        if (qs._briMax <= 0) return
        var step = Math.max(1, Math.round(qs._briMax * 0.05))
        var v = Math.max(0, Math.min(qs._briMax, qs._briRaw + (up ? step : -step)))
        qs._briRaw = v
        qs.briPct = Math.round(v * 100 / qs._briMax)
        run("qdbus6 " + briBase + " setBrightnessSilent " + v)
    }

    RowLayout {
        id: rowL
        anchors.centerIn: parent
        spacing: Math.round(qs.labelSize * 2.2)

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true; shadowColor: Qt.rgba(0, 0, 0, 0.7)
            shadowBlur: 0.7; shadowVerticalOffset: 1
        }

        // ---- Brightness ----
        ColumnLayout {
            spacing: 1
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: i18n("Brightness"); color: "white"
                opacity: briHover.hovered ? 1.0 : 0.74
                font.pixelSize: qs.labelSize; font.weight: Font.Light; font.letterSpacing: 1
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: qs.briPct >= 0 ? qs.briPct + "%" : "—"
                color: "white"; opacity: briHover.hovered ? 0.9 : 0.0
                Behavior on opacity { NumberAnimation { duration: 120 } }
                font.pixelSize: Math.round(qs.labelSize * 0.8); font.weight: Font.Light
            }
            HoverHandler { id: briHover; cursorShape: Qt.PointingHandCursor }
        }

        // ---- Volume ----
        ColumnLayout {
            spacing: 1
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: i18n("Volume"); color: "white"
                opacity: volHover.hovered ? 1.0 : 0.74
                font.pixelSize: qs.labelSize; font.weight: Font.Light; font.letterSpacing: 1
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: qs.volPct >= 0 ? qs.volPct + "%" : "—"
                color: "white"; opacity: volHover.hovered ? 0.9 : 0.0
                Behavior on opacity { NumberAnimation { duration: 120 } }
                font.pixelSize: Math.round(qs.labelSize * 0.8); font.weight: Font.Light
            }
            HoverHandler { id: volHover; cursorShape: Qt.PointingHandCursor }
        }

        // ---- Network (click only) ----
        ColumnLayout {
            spacing: 1
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: i18n("Network"); color: "white"
                opacity: netHover.hovered ? 1.0 : 0.74
                font.pixelSize: qs.labelSize; font.weight: Font.Light; font.letterSpacing: 1
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: i18n("Settings")
                color: "white"; opacity: netHover.hovered ? 0.9 : 0.0
                Behavior on opacity { NumberAnimation { duration: 120 } }
                font.pixelSize: Math.round(qs.labelSize * 0.8); font.weight: Font.Light
            }
            HoverHandler { id: netHover; cursorShape: Qt.PointingHandCursor }
            TapHandler {
                onTapped: { qs.run("kcmshell6 kcm_networkmanagement"); qs.closeRequested() }
            }
        }
    }
}
