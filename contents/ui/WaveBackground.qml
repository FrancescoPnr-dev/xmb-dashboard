/*
 * WaveBackground
 * --------------
 * Native Qt6 port of the linkev/PlayStation-3-XMB `ps3xmbwave` demo (MIT), translated
 * 1:1 from the demo's own method (read from spline.js). THREE layers, drawn in order,
 * exactly like the demo:
 *
 *   1. Gradient  — fullscreen ShaderEffect, smoothstep gradient (spline.js bgProg).
 *   2. Wave      — a ShaderEffect over a GridMesh (the demo's 100x100 displaced grid):
 *                  xmbwave.vert displaces each VERTEX (spline.js waveProg vertex),
 *                  xmbwave.frag does the cross(dFdx,dFdy) fresnel (waveProg fragment).
 *                  This is the GPU-efficient method — the wave is computed per vertex
 *                  (~10k), NOT per screen pixel, so it no longer pins the GPU.
 *   3. Particles — fullscreen additive sparkles (cheap fixed 3x3 hash, not a loop).
 *
 * All wave parameters are uniforms with the demo's spline-settings.js defaults, so the
 * default appearance matches the demo. Dashboard binds the meaningful subset; if
 * ShaderEffect is unavailable Dashboard falls back to WaveBackgroundFallback.qml.
 */
import QtQuick

Item {
    id: root

    // real-seconds clock (demo dtSec accumulator)
    property real time: 0
    property bool animating: true

    // ---- gradient (resolveBackgroundGradient, 'default' RGB preset) ----
    property real colorR: 37
    property real colorG: 89
    property real colorB: 179
    property real gradientTopMul: 0.09
    property real gradientBotMul: 0.62
    readonly property vector4d colorStart: Qt.vector4d((colorR / 255) * gradientTopMul,
                                                       (colorG / 255) * gradientTopMul,
                                                       (colorB / 255) * gradientTopMul * 1.2, 1.0)
    readonly property vector4d colorEnd: Qt.vector4d((colorR / 255) * gradientBotMul,
                                                     (colorG / 255) * gradientBotMul,
                                                     (colorB / 255) * gradientBotMul, 1.0)
    property vector4d gdir: Qt.vector4d(0, 1, 0, 0)   // [0,1] vertical, y-down
    property real tMin: 0.0
    property real tSpan: 1.0

    // ---- wave dynamics (spline-settings.js defaults) ----
    property real flowSpeed: 0.18
    property real timeStep: 1.0
    property real rePipelineBlend: 0.45
    property real bandAmplitude: 0.200
    property real bandSecondaryFreq: 7.0
    property real bandSecondaryAmp: 0.025
    property real tension: 0.12
    property real splineLength: 0.306001
    property real spacing: 407.658
    property real perturbation: 0.0998587
    property real perturbationScale: 0.07
    property real travelSpeed1: 0.25
    property real travelAmp1: 0.014
    property real travelSpeed2: 0.15
    property real travelAmp2: 0.008
    property real waveCosAmp: 0.09
    property real waveBias: -0.1
    property real waveHeightScale: 0.5
    property real waveSoftClip: 0.22
    property real damping: 0.0001
    property real ffdScale1X: 5.67726
    property real ffdScale2Z: 2.88782
    property real ffdYAmp: 0.05
    property real ffdZAmp: 0.06
    property real zDetailScale: 0.08

    // ---- wave shading (spline-settings.js defaults) ----
    property real fresnelPower: 4.0
    property real fresnelScale: 0.5
    property real waveOpacity: 0.7
    property real brightness: 0.98
    property int  rowCount: 100        // GridMesh depth rows (demo mesh res 100)

    // ---- particles ----
    property bool particlesEnabled: true
    property real pFlowSpeed: 0.8
    property real pOpacity: 0.9
    property real pSizeBase: 1.0     // fixed standard (no longer user-adjustable)
    property real pSizeVar: 1.5      // fixed standard (no longer user-adjustable)
    property real pDensity: 1.0

    FrameAnimation {
        running: root.animating && root.visible
        onTriggered: root.time += frameTime
    }

    // ---- LAYER 1: background gradient ----
    ShaderEffect {
        anchors.fill: parent
        blending: false
        fragmentShader: "shaders/xmbgradient.frag.qsb"
        property real tMin: root.tMin
        property real tSpan: root.tSpan
        property vector4d colorStart: root.colorStart
        property vector4d colorEnd: root.colorEnd
        property vector4d gdir: root.gdir
    }

    // ---- LAYER 2: the displaced wave mesh ----
    ShaderEffect {
        anchors.fill: parent
        blending: true
        cullMode: ShaderEffect.NoCulling
        mesh: GridMesh { resolution: Qt.size(96, Math.max(8, root.rowCount)) }
        vertexShader: "shaders/xmbwave.vert.qsb"
        fragmentShader: "shaders/xmbwave.frag.qsb"

        // MSAA: render the mesh into a multisampled offscreen buffer so the filament
        // (triangle/fold) edges are antialiased instead of stair-stepped.
        layer.enabled: true
        layer.samples: 4
        layer.smooth: true

        property real time: root.time
        property real flowSpeed: root.flowSpeed
        property real timeStep: root.timeStep
        property real rePipelineBlend: root.rePipelineBlend
        property real bandAmplitude: root.bandAmplitude
        property real bandSecondaryFreq: root.bandSecondaryFreq
        property real bandSecondaryAmp: root.bandSecondaryAmp
        property real tension: root.tension
        property real splineLength: root.splineLength
        property real spacing: root.spacing
        property real perturbation: root.perturbation
        property real perturbationScale: root.perturbationScale
        property real travelSpeed1: root.travelSpeed1
        property real travelAmp1: root.travelAmp1
        property real travelSpeed2: root.travelSpeed2
        property real travelAmp2: root.travelAmp2
        property real waveCosAmp: root.waveCosAmp
        property real waveBias: root.waveBias
        property real waveHeightScale: root.waveHeightScale
        property real waveSoftClip: root.waveSoftClip
        property real damping: root.damping
        property real ffdScale1X: root.ffdScale1X
        property real ffdScale2Z: root.ffdScale2Z
        property real ffdYAmp: root.ffdYAmp
        property real ffdZAmp: root.ffdZAmp
        property real zDetailScale: root.zDetailScale
        property real fresnelPower: root.fresnelPower
        property real fresnelScale: root.fresnelScale
        property real waveOpacity: root.waveOpacity
        property real brightness: root.brightness
    }

    // ---- LAYER 3: additive sparkles ----
    ShaderEffect {
        anchors.fill: parent
        visible: root.particlesEnabled        // particles on/off
        blending: true
        fragmentShader: "shaders/xmbparticles.frag.qsb"
        property real time: root.time
        property real pFlowSpeed: root.pFlowSpeed
        property real pOpacity: root.pOpacity
        property real pSizeBase: root.pSizeBase
        property real pSizeVar: root.pSizeVar
        property real pDensity: root.pDensity
    }
}
