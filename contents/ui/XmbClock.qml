import QtQuick
import QtQuick.Effects

Text {
    id: clock

    property var now: new Date()
    property int pixelSize: 30

    function two(n) { return n < 10 ? "0" + n : "" + n }
    text: {
        var d = clock.now
        var h = d.getHours()
        var ap = h < 12 ? "AM" : "PM"
        var h12 = h % 12
        if (h12 === 0) h12 = 12
        return (d.getMonth() + 1) + "/" + d.getDate() + "   " + h12 + ":" + two(d.getMinutes()) + " " + ap
    }

    color: "#ffffff"
    opacity: 0.92
    font.pixelSize: clock.pixelSize
    font.weight: Font.Light
    font.letterSpacing: 1

    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Qt.rgba(0, 0, 0, 0.55)
        shadowBlur: 0.6
        shadowVerticalOffset: 1
        shadowHorizontalOffset: 0
    }

    Timer {
        interval: 1000
        running: clock.visible
        repeat: true
        onTriggered: clock.now = new Date()
    }
}
