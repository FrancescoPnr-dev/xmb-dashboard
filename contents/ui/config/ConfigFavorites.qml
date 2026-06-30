/*
 * ConfigFavorites.qml — "Favorites" settings page.
 *
 * Lets the user build the dashboard's Favourites category by picking from ALL installed
 * applications. The chosen apps are stored (by favouriteId) in the `favorites` config key;
 * this is the widget's OWN list, independent of the system favourites. Starts empty.
 *
 * Uses ScrollViewKCM (not SimpleKCM): a ListView needs a view that fills the page, not the
 * implicit-height content area SimpleKCM gives (which would leave the list invisible).
 */
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.private.kicker as Kicker
import org.kde.kitemmodels as KItemModels

KCM.ScrollViewKCM {
    id: page

    // Contract with the config system (StringList of favouriteIds).
    property var cfg_favorites: []
    property var cfg_favoritesDefault: []

    function isFav(favId) { return (cfg_favorites || []).indexOf(favId) !== -1 }
    function toggleFav(favId, on) {
        var arr = (cfg_favorites || []).slice()
        var i = arr.indexOf(favId)
        if (on && i === -1) arr.push(favId)
        else if (!on && i !== -1) arr.splice(i, 1)
        cfg_favorites = arr
    }

    // Flat list of all installed applications.
    Kicker.RootModel {
        id: allApps
        autoPopulate: true
        showAllApps: true
        showAllAppsCategorized: false
        showRecentApps: false
        showRecentDocs: false
        showRecentFolders: false
        showPowerSession: false
        showFavoritesPlaceholder: false
        showSeparators: false
        appNameFormat: 0
        onCountChanged: page.appsFlat = allApps.modelForRow(0)
    }
    property var appsFlat: null
    Component.onCompleted: appsFlat = allApps.modelForRow(0)

    KItemModels.KSortFilterProxyModel {
        id: filtered
        sourceModel: page.appsFlat
        filterRoleName: "display"
        filterString: searchField.text
        filterCaseSensitivity: Qt.CaseInsensitive
        sortRoleName: "display"
        sortOrder: Qt.AscendingOrder
    }

    header: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing
        QQC2.Label {
            Layout.fillWidth: true
            text: i18n("Pick the applications to show in the dashboard's Favorites category.")
            wrapMode: Text.WordWrap
            opacity: 0.8
        }
        Kirigami.SearchField {
            id: searchField
            Layout.fillWidth: true
            placeholderText: i18n("Search applications…")
        }
    }

    view: ListView {
        id: appList
        model: filtered
        clip: true
        reuseItems: true

        // Plain Item delegate: a Control (ItemDelegate/CheckDelegate) has its own FINAL
        // `display` property that collides with the model's "display" role.
        delegate: Item {
            id: row
            required property string display
            required property var decoration
            required property string favoriteId
            width: ListView.view.width
            height: rowLayout.implicitHeight + Kirigami.Units.smallSpacing * 2

            Rectangle {
                anchors.fill: parent
                color: Kirigami.Theme.highlightColor
                opacity: rowHover.hovered ? 0.15 : 0.0
            }
            HoverHandler { id: rowHover }
            TapHandler { onTapped: favCheck.toggle() }

            RowLayout {
                id: rowLayout
                anchors.fill: parent
                anchors.leftMargin: Kirigami.Units.largeSpacing
                anchors.rightMargin: Kirigami.Units.largeSpacing
                anchors.topMargin: Kirigami.Units.smallSpacing
                anchors.bottomMargin: Kirigami.Units.smallSpacing
                spacing: Kirigami.Units.smallSpacing
                Kirigami.Icon {
                    source: row.decoration
                    Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                }
                QQC2.Label {
                    text: row.display
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                QQC2.CheckBox {
                    id: favCheck
                    checked: page.isFav(row.favoriteId)
                    onToggled: page.toggleFav(row.favoriteId, checked)
                }
            }
        }

        QQC2.Label {
            anchors.centerIn: parent
            width: parent.width * 0.8
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            visible: appList.count === 0
            text: i18n("No applications found.")
            opacity: 0.6
        }
    }
}
