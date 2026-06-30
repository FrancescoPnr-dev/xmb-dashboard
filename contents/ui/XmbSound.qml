/*
 * XmbSound
 * --------
 * Tiny one-shot sound player for UI feedback (the navigation tick).
 *
 * Two engines, picked by file type: WAV goes through SoundEffect (low latency, clean
 * rapid retrigger — ideal for the tick), anything else (e.g. an mp3) through
 * MediaPlayer. `play()` restarts from the start each time, so holding a direction
 * ticks per step. `source` empty = silent (the "off" mode).
 */
import QtQuick
import QtMultimedia

Item {
    id: root

    property url source: ""
    property real volume: 0.6
    readonly property bool isWav: root.source.toString().toLowerCase().endsWith(".wav")

    SoundEffect {
        id: effect
        source: root.isWav ? root.source : ""
        volume: root.volume
    }

    MediaPlayer {
        id: player
        source: root.isWav ? "" : root.source
        audioOutput: AudioOutput { volume: root.volume }
    }

    function play() {
        if (root.source.toString() === "")
            return
        if (root.isWav) {
            effect.stop()
            effect.play()
        } else {
            player.stop()
            player.play()
        }
    }
}
