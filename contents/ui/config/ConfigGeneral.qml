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
                Layout.fillWidth: true
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
                Layout.fillWidth: true
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
            Layout.fillWidth: true
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
                Layout.fillWidth: true
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
                Layout.fillWidth: true
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
                Layout.fillWidth: true
            }
            QQC2.Label {
                text: Math.round(magneticSlider.value * 100) + "%"
                Layout.minimumWidth: valueColumnWidth
                horizontalAlignment: Text.AlignRight
            }
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
                text: model.display
                checked: page.hiddenSet.indexOf(model.display) === -1
                onToggled: page.toggleCategory(model.display, !checked)
            }
        }
    }

    // Shared width for the slider value readouts so they line up in a neat column.
    readonly property int valueColumnWidth: Kirigami.Units.gridUnit * 2.5
}
