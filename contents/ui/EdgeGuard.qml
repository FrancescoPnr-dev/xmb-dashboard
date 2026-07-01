// KWin has no per-window edge API, so we toggle the global ElectricBorders
// setting while the dashboard is open and restore the user's real value on close.
import QtQuick
import org.kde.plasma.plasma5support as P5Support

Item {
    id: guard

    property string savedElectricBorders: ""
    property bool active: false

    P5Support.DataSource {
        id: exec
        engine: "executable"
        onNewData: (sourceName, data) => {
            var out = ((data["stdout"] || "") + "").trim()
            if (sourceName.indexOf("kreadconfig6") !== -1 && out.length > 0)
                guard.savedElectricBorders = out
            exec.disconnectSource(sourceName)
        }
    }
    function run(cmd) { exec.connectSource(cmd) }

    Component.onCompleted: run("kreadconfig6 --file kwinrc --group Windows --key ElectricBorders")

    function disableSystemEdges() {
        if (active) return
        active = true
        run("kwriteconfig6 --file kwinrc --group Windows --key ElectricBorders 0; qdbus6 org.kde.KWin /KWin reconfigure")
    }

    function restoreSystemEdges() {
        if (!active) return
        active = false
        // Never restore 0, or a crash mid-session would leave edges off; fall back to the default 2.
        var eb = guard.savedElectricBorders
        if (eb.length === 0 || eb === "0") eb = "2"
        run("kwriteconfig6 --file kwinrc --group Windows --key ElectricBorders " + eb + "; qdbus6 org.kde.KWin /KWin reconfigure")
    }

    Component.onDestruction: restoreSystemEdges()
}
