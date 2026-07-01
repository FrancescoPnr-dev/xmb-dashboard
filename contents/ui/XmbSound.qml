// SPDX-FileCopyrightText: 2026 Francesco Panarese
// SPDX-License-Identifier: GPL-3.0-only
// One-shot sound player for UI feedback (the navigation tick).
// WAV goes through SoundEffect (low latency, clean retrigger); anything else via
// MediaPlayer. play() restarts from the start; empty source = silent.
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
