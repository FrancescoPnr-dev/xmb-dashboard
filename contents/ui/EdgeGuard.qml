/*
 * EdgeGuard
 * ---------
 * While the dashboard is open, neutralise Plasma/KWin's own SCREEN-EDGE actions so the
 * dashboard can own the edges, then restore on close. KWin has no per-window API for
 * this, so we toggle the relevant GLOBAL setting only for the lifetime of the overlay
 * and restore the user's real value (read at load — no hard-coded assumptions). Screen
 * CORNERS live in a separate config group and are left untouched.
 *
 *   - Straight edges (switch-desktop-on-edge): kwinrc [Windows] ElectricBorders -> 0.
 *
 * NOTE: the bottom auto-hide PANEL is handled elsewhere — changing its hide mode does
 * NOT stop its edge reveal (plasmashell ignores the overlay window because it belongs
 * to the plasmashell process), so it needs a stacking/rule approach instead.
 */
import QtQuick
import org.kde.plasma.plasma5support as P5Support

Item {
    id: guard

    property string savedElectricBorders: ""    // captured at load
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
        // Crash-safety: never restore to the "disabled" value 0 (would leave the user's
        // edges off); fall back to the Plasma default (2 = switch desktop on edge).
        var eb = guard.savedElectricBorders
        if (eb.length === 0 || eb === "0") eb = "2"
        run("kwriteconfig6 --file kwinrc --group Windows --key ElectricBorders " + eb + "; qdbus6 org.kde.KWin /KWin reconfigure")
    }

    Component.onDestruction: restoreSystemEdges()
}
