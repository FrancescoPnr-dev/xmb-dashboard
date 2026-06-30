/*
 * WaveBackgroundFallback
 * ----------------------
 * Shown when ShaderEffect is unavailable (e.g. the Qt Quick software backend, where
 * custom shaders don't run). A static deep-blue vertical gradient matching the demo's
 * default background — so the dashboard always opens. Exposes the SAME property set as
 * WaveBackground.qml so Dashboard can bind either without special-casing (the wave-only
 * properties are simply unused here).
 */
import QtQuick

Item {
    id: root

    property bool animating: true

    // gradient (demo 'default' preset, resolveBackgroundGradient)
    property real colorR: 37
    property real colorG: 89
    property real colorB: 179
    property real gradientTopMul: 0.09
    property real gradientBotMul: 0.62

    // wave/particle uniforms (unused in the fallback, declared so bindings succeed)
    property real flowSpeed: 0.18
    property real bandAmplitude: 0.200
    property real waveHeightScale: 0.5
    property real waveSoftClip: 0.22
    property real tension: 0.12
    property real fresnelPower: 4.0
    property real fresnelScale: 0.5
    property real waveOpacity: 0.7
    property real brightness: 0.98
    property real rowCount: 48
    property real pFlowSpeed: 0.18
    property real pOpacity: 0.75
    property real pSizeBase: 2.6
    property real pSizeVar: 1.5
    property real pDensity: 1.0

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            // top = colorRGB*topMul (B*1.2), bottom = colorRGB*botMul  (demo default)
            GradientStop {
                position: 0.0
                color: Qt.rgba((root.colorR / 255) * root.gradientTopMul,
                               (root.colorG / 255) * root.gradientTopMul,
                               (root.colorB / 255) * root.gradientTopMul * 1.2, 1.0)
            }
            GradientStop {
                position: 1.0
                color: Qt.rgba((root.colorR / 255) * root.gradientBotMul,
                               (root.colorG / 255) * root.gradientBotMul,
                               (root.colorB / 255) * root.gradientBotMul, 1.0)
            }
        }
    }
}
