/*
 * ConfigGeneral.qml — the "General" page of the widget settings.
 *
 * Root is KCM.SimpleKCM (the canonical Plasma 6 config-page wrapper): it provides
 * scrolling and correct page margins, so the form never gets clipped or runs into
 * the dialog borders. Every control writes to cfg_<key>, which the config system
 * maps to the matching <entry> in contents/config/main.xml.
 */
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.private.kicker as Kicker

KCM.SimpleKCM {
    id: page

    // These aliases are the contract with the config system (cfg_<key>).
    property alias cfg_backgroundOpacity: opacitySlider.value
    property alias cfg_categoryIconSize: categorySizeSpin.value
    property alias cfg_appIconSize: appSizeSpin.value
    property alias cfg_intersectionXFraction: intersectionSlider.value
    property alias cfg_panelIcon: iconField.text
    property alias cfg_hotZoneFractionLeft: hotZoneLeftSlider.value
    property alias cfg_hotZoneFractionRight: hotZoneRightSlider.value
    property alias cfg_minScrollSpeed: minSpeedSpin.value
    property alias cfg_maxScrollSpeed: maxSpeedSpin.value
    property alias cfg_snapDuration: snapDurationSpin.value
    property alias cfg_magneticStrength: magneticSlider.value
    property alias cfg_hotZoneBandHeight: bandHeightSpin.value
    property alias cfg_manageScreenEdges: manageScreenEdgesCheck.checked

    // XMB wave background (ps3xmbwave port)
    property alias cfg_waveFlowSpeed: waveFlowSpeedSlider.value
    property alias cfg_waveBandAmplitude: waveBandAmpSlider.value
    property alias cfg_waveHeightScale: waveHeightScaleSlider.value
    property alias cfg_waveSoftClip: waveSoftClipSlider.value
    property alias cfg_waveTension: waveTensionSlider.value
    property alias cfg_waveFresnelPower: waveFresnelPowerSlider.value
    property alias cfg_waveFresnelScale: waveFresnelScaleSlider.value
    property alias cfg_waveOpacity: waveOpacitySlider.value
    property alias cfg_waveBrightness: waveBrightnessSlider.value
    property alias cfg_waveRowCount: waveRowCountSpin.value
    property alias cfg_waveColorMonth: monthCombo.currentIndex
    property alias cfg_waveColorR: waveColorRSlider.value
    property alias cfg_waveColorG: waveColorGSlider.value
    property alias cfg_waveColorB: waveColorBSlider.value
    property alias cfg_waveGradientTopMul: waveTopMulSlider.value
    property alias cfg_waveGradientBotMul: waveBotMulSlider.value
    property alias cfg_waveParticlesEnabled: particlesEnabledCheck.checked
    property alias cfg_waveParticleCount: waveParticleCountSpin.value
    property alias cfg_waveParticleOpacity: waveParticleOpacitySlider.value
    property alias cfg_waveParticleFlowSpeed: waveParticleFlowSpeedSlider.value

    // Navigation sound
    property alias cfg_navSoundMode: navSoundCombo.currentIndex
    property alias cfg_navSoundFile: navSoundFileField.text
    property alias cfg_navSoundVolume: navSoundVolumeSlider.value
    property alias cfg_ambientSoundEnabled: ambientEnabledCheck.checked
    property alias cfg_ambientSoundVolume: ambientVolumeSlider.value

    // StringList of hidden category names. Every cfg_<key> MUST be an alias so the
    // config system can auto-generate the matching cfg_<key>Default; a plain
    // `property var cfg_hiddenCategories` breaks that for ALL keys. So back it with
    // an alias to a hidden helper property.
    property alias cfg_hiddenCategories: hiddenCategoriesStore.value
    QtObject {
        id: hiddenCategoriesStore
        property var value: []
    }
    property var hiddenSet: cfg_hiddenCategories

    function toggleCategory(name, hide) {
        var arr = hiddenSet.slice()
        var idx = arr.indexOf(name)
        if (hide && idx === -1) arr.push(name)
        else if (!hide && idx !== -1) arr.splice(idx, 1)
        cfg_hiddenCategories = arr
        hiddenSet = arr
    }

    // Per-section "reset to defaults".
    //
    // The config loader only injects properties the page actually DECLARES, so the
    // cfg_<key>Default values are NOT auto-created just by referencing them — an
    // undeclared cfg_<key>Default reads back as `undefined`, and assigning that to a
    // slider/spinbox does nothing (which is why reset appeared to do nothing).
    // We therefore declare each default explicitly, mirroring contents/config/main.xml.
    // (Same approach already used for cfg_favoritesDefault in ConfigFavorites.qml.)
    // Keep these in sync with main.xml.
    property real cfg_backgroundOpacityDefault: 1.0
    property int  cfg_categoryIconSizeDefault: 112
    property int  cfg_appIconSizeDefault: 56
    property real cfg_intersectionXFractionDefault: 0.30
    property string cfg_panelIconDefault: "applications-all"

    property real cfg_hotZoneFractionLeftDefault: 0.15
    property real cfg_hotZoneFractionRightDefault: 0.15
    property int  cfg_hotZoneBandHeightDefault: 200
    property int  cfg_minScrollSpeedDefault: 1500
    property int  cfg_maxScrollSpeedDefault: 2600
    property int  cfg_snapDurationDefault: 220
    property real cfg_magneticStrengthDefault: 0.7

    property real cfg_waveFlowSpeedDefault: 0.45
    property real cfg_waveBandAmplitudeDefault: 0.2
    property real cfg_waveHeightScaleDefault: 0.5
    property real cfg_waveSoftClipDefault: 0.22
    property real cfg_waveTensionDefault: 0.12
    property real cfg_waveFresnelPowerDefault: 4.0
    property real cfg_waveFresnelScaleDefault: 0.5
    property real cfg_waveOpacityDefault: 0.7
    property real cfg_waveBrightnessDefault: 0.98
    property int  cfg_waveRowCountDefault: 200

    property int  cfg_waveColorMonthDefault: 13
    property int  cfg_waveColorRDefault: 37
    property int  cfg_waveColorGDefault: 89
    property int  cfg_waveColorBDefault: 179
    property real cfg_waveGradientTopMulDefault: 0.09
    property real cfg_waveGradientBotMulDefault: 0.62

    property bool cfg_waveParticlesEnabledDefault: true
    property int  cfg_waveParticleCountDefault: 2000
    property real cfg_waveParticleOpacityDefault: 1.0
    property real cfg_waveParticleFlowSpeedDefault: 0.8

    property int    cfg_navSoundModeDefault: 0
    property string cfg_navSoundFileDefault: ""
    property real   cfg_navSoundVolumeDefault: 0.5
    property bool   cfg_ambientSoundEnabledDefault: true
    property real   cfg_ambientSoundVolumeDefault: 0.5

    function resetAppearance() {
        cfg_backgroundOpacity = cfg_backgroundOpacityDefault
        cfg_categoryIconSize = cfg_categoryIconSizeDefault
        cfg_appIconSize = cfg_appIconSizeDefault
        cfg_intersectionXFraction = cfg_intersectionXFractionDefault
        cfg_panelIcon = cfg_panelIconDefault
    }
    function resetCategoryBar() {
        cfg_hotZoneFractionLeft = cfg_hotZoneFractionLeftDefault
        cfg_hotZoneFractionRight = cfg_hotZoneFractionRightDefault
        cfg_hotZoneBandHeight = cfg_hotZoneBandHeightDefault
        cfg_minScrollSpeed = cfg_minScrollSpeedDefault
        cfg_maxScrollSpeed = cfg_maxScrollSpeedDefault
        cfg_snapDuration = cfg_snapDurationDefault
        cfg_magneticStrength = cfg_magneticStrengthDefault
    }
    function resetWave() {
        cfg_waveFlowSpeed = cfg_waveFlowSpeedDefault
        cfg_waveBandAmplitude = cfg_waveBandAmplitudeDefault
        cfg_waveHeightScale = cfg_waveHeightScaleDefault
        cfg_waveSoftClip = cfg_waveSoftClipDefault
        cfg_waveTension = cfg_waveTensionDefault
        cfg_waveFresnelPower = cfg_waveFresnelPowerDefault
        cfg_waveFresnelScale = cfg_waveFresnelScaleDefault
        cfg_waveOpacity = cfg_waveOpacityDefault
        cfg_waveBrightness = cfg_waveBrightnessDefault
        cfg_waveRowCount = cfg_waveRowCountDefault
    }
    function resetWaveColour() {
        cfg_waveColorMonth = cfg_waveColorMonthDefault
        cfg_waveColorR = cfg_waveColorRDefault
        cfg_waveColorG = cfg_waveColorGDefault
        cfg_waveColorB = cfg_waveColorBDefault
        cfg_waveGradientTopMul = cfg_waveGradientTopMulDefault
        cfg_waveGradientBotMul = cfg_waveGradientBotMulDefault
    }
    function resetParticles() {
        cfg_waveParticlesEnabled = cfg_waveParticlesEnabledDefault
        cfg_waveParticleCount = cfg_waveParticleCountDefault
        cfg_waveParticleOpacity = cfg_waveParticleOpacityDefault
        cfg_waveParticleFlowSpeed = cfg_waveParticleFlowSpeedDefault
    }
    function resetSounds() {
        cfg_navSoundMode = cfg_navSoundModeDefault
        cfg_navSoundFile = cfg_navSoundFileDefault
        cfg_navSoundVolume = cfg_navSoundVolumeDefault
        cfg_ambientSoundEnabled = cfg_ambientSoundEnabledDefault
        cfg_ambientSoundVolume = cfg_ambientSoundVolumeDefault
    }

    Kirigami.FormLayout {
        id: form

        // ===================== Appearance =====================
        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Appearance")
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Background opacity:")
            QQC2.Slider {
                id: opacitySlider
                from: 0.2; to: 1.0; stepSize: 0.05
                Layout.preferredWidth: page.controlWidth
            }
            QQC2.Label {
                text: Math.round(opacitySlider.value * 100) + "%"
                Layout.minimumWidth: valueColumnWidth
                horizontalAlignment: Text.AlignRight
            }
        }

        QQC2.SpinBox {
            id: categorySizeSpin
            Kirigami.FormData.label: i18n("Category icon size (px):")
            from: 48; to: 256; stepSize: 8
        }

        QQC2.SpinBox {
            id: appSizeSpin
            Kirigami.FormData.label: i18n("App icon size (px):")
            from: 24; to: 160; stepSize: 4
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Cross position (from left):")
            QQC2.Slider {
                id: intersectionSlider
                from: 0.1; to: 0.5; stepSize: 0.01
                Layout.preferredWidth: page.controlWidth
            }
            QQC2.Label {
                text: Math.round(intersectionSlider.value * 100) + "%"
                Layout.minimumWidth: valueColumnWidth
                horizontalAlignment: Text.AlignRight
            }
        }

        QQC2.TextField {
            id: iconField
            Kirigami.FormData.label: i18n("Panel icon name:")
            Layout.preferredWidth: page.controlWidth
        }

        QQC2.Button {
            text: i18n("Reset section to defaults")
            icon.name: "edit-undo"
            onClicked: page.resetAppearance()
        }

        // ================== Behaviour ==================
        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Behaviour")
            Kirigami.FormData.isSection: true
        }

        QQC2.CheckBox {
            id: manageScreenEdgesCheck
            Kirigami.FormData.label: i18n("Screen edges:")
            text: i18n("Disable system edges while the dashboard is open")
        }

        // ================= Category bar (mouse) =================
        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Category bar (mouse)")
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Left hot-zone width:")
            QQC2.Slider {
                id: hotZoneLeftSlider
                from: 0.05; to: 0.45; stepSize: 0.01
                Layout.preferredWidth: page.controlWidth
            }
            QQC2.Label {
                text: Math.round(hotZoneLeftSlider.value * 100) + "%"
                Layout.minimumWidth: valueColumnWidth
                horizontalAlignment: Text.AlignRight
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Right hot-zone width:")
            QQC2.Slider {
                id: hotZoneRightSlider
                from: 0.05; to: 0.45; stepSize: 0.01
                Layout.preferredWidth: page.controlWidth
            }
            QQC2.Label {
                text: Math.round(hotZoneRightSlider.value * 100) + "%"
                Layout.minimumWidth: valueColumnWidth
                horizontalAlignment: Text.AlignRight
            }
        }

        QQC2.SpinBox {
            id: bandHeightSpin
            Kirigami.FormData.label: i18n("Hot-zone band height (px):")
            from: 80; to: 2000; stepSize: 20
        }

        QQC2.SpinBox {
            id: minSpeedSpin
            Kirigami.FormData.label: i18n("Min scroll speed (px/s):")
            from: 20
            // Freely selectable up to 100 px/s below the chosen max speed.
            to: Math.max(from, maxSpeedSpin.value - 100)
            stepSize: 10
            editable: true
        }

        QQC2.SpinBox {
            id: maxSpeedSpin
            Kirigami.FormData.label: i18n("Max scroll speed (px/s):")
            // Always stays at least 100 px/s above the min speed.
            from: minSpeedSpin.value + 100
            to: 8000
            stepSize: 50
            editable: true
        }

        QQC2.SpinBox {
            id: snapDurationSpin
            Kirigami.FormData.label: i18n("Snap animation (ms):")
            from: 60; to: 600; stepSize: 10
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Magnetic glue strength:")
            QQC2.Slider {
                id: magneticSlider
                from: 0.0; to: 0.95; stepSize: 0.05
                Layout.preferredWidth: page.controlWidth
            }
            QQC2.Label {
                text: Math.round(magneticSlider.value * 100) + "%"
                Layout.minimumWidth: valueColumnWidth
                horizontalAlignment: Text.AlignRight
            }
        }

        QQC2.Button {
            text: i18n("Reset section to defaults")
            icon.name: "edit-undo"
            onClicked: page.resetCategoryBar()
        }

        // ================== Wave background ==================
        // Ports the demo's Spline Controls (the impactful subset; ranges & defaults
        // from spline-settings.js). Remaining demo parameters keep the demo defaults
        // (set in WaveBackground.qml).
        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Wave background")
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Flow speed:")
            QQC2.Slider { id: waveFlowSpeedSlider; from: 0.0; to: 1.2; stepSize: 0.005; Layout.preferredWidth: page.controlWidth }
            QQC2.Label { text: waveFlowSpeedSlider.value.toFixed(3); Layout.minimumWidth: valueColumnWidth; horizontalAlignment: Text.AlignRight }
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Band amplitude:")
            QQC2.Slider { id: waveBandAmpSlider; from: 0.0; to: 0.6; stepSize: 0.002; Layout.preferredWidth: page.controlWidth }
            QQC2.Label { text: waveBandAmpSlider.value.toFixed(3); Layout.minimumWidth: valueColumnWidth; horizontalAlignment: Text.AlignRight }
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Wave height:")
            QQC2.Slider { id: waveHeightScaleSlider; from: 0.0; to: 1.0; stepSize: 0.005; Layout.preferredWidth: page.controlWidth }
            QQC2.Label { text: waveHeightScaleSlider.value.toFixed(3); Layout.minimumWidth: valueColumnWidth; horizontalAlignment: Text.AlignRight }
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Soft clip:")
            QQC2.Slider { id: waveSoftClipSlider; from: 0.05; to: 0.5; stepSize: 0.005; Layout.preferredWidth: page.controlWidth }
            QQC2.Label { text: waveSoftClipSlider.value.toFixed(3); Layout.minimumWidth: valueColumnWidth; horizontalAlignment: Text.AlignRight }
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Tension:")
            QQC2.Slider { id: waveTensionSlider; from: 0.0; to: 0.5; stepSize: 0.005; Layout.preferredWidth: page.controlWidth }
            QQC2.Label { text: waveTensionSlider.value.toFixed(3); Layout.minimumWidth: valueColumnWidth; horizontalAlignment: Text.AlignRight }
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Fresnel power:")
            QQC2.Slider { id: waveFresnelPowerSlider; from: 0.2; to: 8.0; stepSize: 0.05; Layout.preferredWidth: page.controlWidth }
            QQC2.Label { text: waveFresnelPowerSlider.value.toFixed(2); Layout.minimumWidth: valueColumnWidth; horizontalAlignment: Text.AlignRight }
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Fresnel scale:")
            QQC2.Slider { id: waveFresnelScaleSlider; from: 0.0; to: 2.0; stepSize: 0.01; Layout.preferredWidth: page.controlWidth }
            QQC2.Label { text: waveFresnelScaleSlider.value.toFixed(2); Layout.minimumWidth: valueColumnWidth; horizontalAlignment: Text.AlignRight }
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Wave opacity:")
            QQC2.Slider { id: waveOpacitySlider; from: 0.0; to: 1.0; stepSize: 0.005; Layout.preferredWidth: page.controlWidth }
            QQC2.Label { text: waveOpacitySlider.value.toFixed(3); Layout.minimumWidth: valueColumnWidth; horizontalAlignment: Text.AlignRight }
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Brightness:")
            QQC2.Slider { id: waveBrightnessSlider; from: 0.0; to: 2.0; stepSize: 0.01; Layout.preferredWidth: page.controlWidth }
            QQC2.Label { text: waveBrightnessSlider.value.toFixed(2); Layout.minimumWidth: valueColumnWidth; horizontalAlignment: Text.AlignRight }
        }
        QQC2.SpinBox {
            id: waveRowCountSpin
            Kirigami.FormData.label: i18n("Wave detail (rows):")
            from: 24; to: 200; stepSize: 4
        }

        QQC2.Button {
            text: i18n("Reset section to defaults")
            icon.name: "edit-undo"
            onClicked: page.resetWave()
        }

        // ================== Wave colour ==================
        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Wave colour")
            Kirigami.FormData.isSection: true
        }

        QQC2.ComboBox {
            id: monthCombo
            Kirigami.FormData.label: i18n("Colour preset:")
            // index: 0 = Automatic, 1..12 = month, 13 = Custom (RGB sliders)
            model: [i18n("Automatic (current month)"),
                    i18n("January"), i18n("February"), i18n("March"), i18n("April"),
                    i18n("May"), i18n("June"), i18n("July"), i18n("August"),
                    i18n("September"), i18n("October"), i18n("November"), i18n("December"),
                    i18n("Custom colour (RGB)")]
        }

        // RGB sliders apply only in Custom mode (index 13); otherwise the month preset wins.
        RowLayout {
            Kirigami.FormData.label: i18n("Colour R:")
            enabled: monthCombo.currentIndex === 13
            QQC2.Slider { id: waveColorRSlider; from: 0; to: 255; stepSize: 1; Layout.preferredWidth: page.controlWidth }
            QQC2.Label { text: Math.round(waveColorRSlider.value); Layout.minimumWidth: valueColumnWidth; horizontalAlignment: Text.AlignRight }
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Colour G:")
            enabled: monthCombo.currentIndex === 13
            QQC2.Slider { id: waveColorGSlider; from: 0; to: 255; stepSize: 1; Layout.preferredWidth: page.controlWidth }
            QQC2.Label { text: Math.round(waveColorGSlider.value); Layout.minimumWidth: valueColumnWidth; horizontalAlignment: Text.AlignRight }
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Colour B:")
            enabled: monthCombo.currentIndex === 13
            QQC2.Slider { id: waveColorBSlider; from: 0; to: 255; stepSize: 1; Layout.preferredWidth: page.controlWidth }
            QQC2.Label { text: Math.round(waveColorBSlider.value); Layout.minimumWidth: valueColumnWidth; horizontalAlignment: Text.AlignRight }
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Gradient top mul:")
            enabled: monthCombo.currentIndex === 13
            QQC2.Slider { id: waveTopMulSlider; from: 0.0; to: 0.3; stepSize: 0.005; Layout.preferredWidth: page.controlWidth }
            QQC2.Label { text: waveTopMulSlider.value.toFixed(3); Layout.minimumWidth: valueColumnWidth; horizontalAlignment: Text.AlignRight }
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Gradient bottom mul:")
            enabled: monthCombo.currentIndex === 13
            QQC2.Slider { id: waveBotMulSlider; from: 0.2; to: 1.2; stepSize: 0.005; Layout.preferredWidth: page.controlWidth }
            QQC2.Label { text: waveBotMulSlider.value.toFixed(3); Layout.minimumWidth: valueColumnWidth; horizontalAlignment: Text.AlignRight }
        }

        QQC2.Button {
            text: i18n("Reset section to defaults")
            icon.name: "edit-undo"
            onClicked: page.resetWaveColour()
        }

        // ================== Particles ==================
        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Particles")
            Kirigami.FormData.isSection: true
        }

        QQC2.CheckBox {
            id: particlesEnabledCheck
            Kirigami.FormData.label: i18n("Particles:")
            text: i18n("Enabled")
        }
        QQC2.SpinBox {
            id: waveParticleCountSpin
            Kirigami.FormData.label: i18n("Count:")
            from: 10; to: 4000; stepSize: 10
            editable: true
            enabled: particlesEnabledCheck.checked
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Opacity:")
            enabled: particlesEnabledCheck.checked
            QQC2.Slider { id: waveParticleOpacitySlider; from: 0.0; to: 1.0; stepSize: 0.01; Layout.preferredWidth: page.controlWidth }
            QQC2.Label { text: waveParticleOpacitySlider.value.toFixed(2); Layout.minimumWidth: valueColumnWidth; horizontalAlignment: Text.AlignRight }
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Flow speed:")
            enabled: particlesEnabledCheck.checked
            QQC2.Slider { id: waveParticleFlowSpeedSlider; from: 0.0; to: 3.0; stepSize: 0.01; Layout.preferredWidth: page.controlWidth }
            QQC2.Label { text: waveParticleFlowSpeedSlider.value.toFixed(2); Layout.minimumWidth: valueColumnWidth; horizontalAlignment: Text.AlignRight }
        }

        QQC2.Button {
            text: i18n("Reset section to defaults")
            icon.name: "edit-undo"
            onClicked: page.resetParticles()
        }

        // ================== Sounds ==================
        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Sounds")
            Kirigami.FormData.isSection: true
        }

        QQC2.ComboBox {
            id: navSoundCombo
            Kirigami.FormData.label: i18n("Navigation tick:")
            // Indices map to navSoundMode (0/1/2).
            model: [ i18n("XMB (default)"), i18n("Custom file…"), i18n("Off") ]
        }

        QQC2.TextField {
            id: navSoundFileField
            Kirigami.FormData.label: i18n("Custom sound file:")
            Layout.preferredWidth: page.controlWidth
            enabled: navSoundCombo.currentIndex === 1
            placeholderText: i18n("/path/to/sound.wav or .mp3")
        }
        QQC2.Label {
            Layout.preferredWidth: page.controlWidth
            visible: navSoundCombo.currentIndex === 1
            wrapMode: Text.WordWrap
            opacity: 0.7
            text: i18n("The original PS3 sound is not bundled (Sony copyright). Point this at your own local copy. WAV gives the lowest latency.")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Volume:")
            enabled: navSoundCombo.currentIndex !== 2
            QQC2.Slider { id: navSoundVolumeSlider; from: 0.0; to: 1.0; stepSize: 0.01; Layout.preferredWidth: page.controlWidth }
            QQC2.Label { text: Math.round(navSoundVolumeSlider.value * 100) + "%"; Layout.minimumWidth: valueColumnWidth; horizontalAlignment: Text.AlignRight }
        }

        QQC2.CheckBox {
            id: ambientEnabledCheck
            Kirigami.FormData.label: i18n("Background ambience:")
            text: i18n("Play a soft looping pad while the dashboard is open")
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Ambience volume:")
            enabled: ambientEnabledCheck.checked
            QQC2.Slider { id: ambientVolumeSlider; from: 0.0; to: 1.0; stepSize: 0.01; Layout.preferredWidth: page.controlWidth }
            QQC2.Label { text: Math.round(ambientVolumeSlider.value * 100) + "%"; Layout.minimumWidth: valueColumnWidth; horizontalAlignment: Text.AlignRight }
        }

        QQC2.Button {
            text: i18n("Reset section to defaults")
            icon.name: "edit-undo"
            onClicked: page.resetSounds()
        }

        // ================== Visible categories ==================
        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Visible categories")
            Kirigami.FormData.isSection: true
        }

        // Enumerate the real menu categories for the show/hide checkboxes.
        Kicker.RootModel {
            id: categoriesModel
            autoPopulate: true
            showAllApps: false
            showAllAppsCategorized: true
            showRecentApps: false
            showRecentDocs: false
            showRecentFolders: false
            showPowerSession: false
            showFavoritesPlaceholder: false
            showSeparators: false
        }

        Repeater {
            model: categoriesModel
            // Do NOT inject the model's "display" role as a property: QQC2.CheckBox
            // (via AbstractButton) already has a FINAL "display" property, which
            // would make the whole page fail to load. Read it through `model`.
            QQC2.CheckBox {
                required property var model
                required property int index
                // Persist the locale-independent icon-name key; show the translated label.
                readonly property string catKey: model.decoration ? String(model.decoration) : model.display
                text: model.display
                checked: page.hiddenSet.indexOf(catKey) === -1
                onToggled: page.toggleCategory(catKey, !checked)
            }
        }

        QQC2.Button {
            text: i18n("Show all categories")
            icon.name: "edit-undo"
            onClicked: { page.cfg_hiddenCategories = []; page.hiddenSet = [] }
        }
    }

    // Shared width for the slider value readouts so they line up in a neat column.
    readonly property int valueColumnWidth: Kirigami.Units.gridUnit * 2.5

    // Fixed width for the field controls (sliders, text fields). Using a bounded width
    // instead of Layout.fillWidth keeps the FormLayout's two-column block centred like
    // a standard KDE settings page, rather than stretching the controls edge to edge.
    readonly property int controlWidth: Kirigami.Units.gridUnit * 14
}
