import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami
import QtQuick.Layouts

PlasmoidItem {
    id: root
    property bool boostEnabled: true
    property bool ready: false

    Plasma5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []

        onNewData: (sourceName, data) => {
            if (sourceName.indexOf("is-enabled") !== -1) {
                var out = (data["stdout"] || "").trim()
                root.boostEnabled = (out === "enabled")
                root.ready = true
            }
            disconnectSource(sourceName)
        }
    }

    function refresh() {
        exec.connectSource("/usr/local/bin/turbo-boost is-enabled")
    }

    function toggle() {
        var newState = !root.boostEnabled
        root.boostEnabled = newState
        exec.connectSource("/usr/local/bin/turbo-boost " + (newState ? "on" : "off"))
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: root.refresh()

    compactRepresentation: MouseArea {
        id: compactRoot
        Layout.minimumWidth: icon.implicitWidth + Kirigami.Units.smallSpacing * 2
        Layout.minimumHeight: icon.implicitHeight + Kirigami.Units.smallSpacing * 2
        Layout.preferredWidth: Layout.minimumWidth

        onClicked: root.expanded = !root.expanded

        Kirigami.Icon {
            id: icon
            anchors.centerIn: parent
            width: Kirigami.Units.iconSizes.small
            height: width
            source: root.boostEnabled
                ? "battery-profile-performance-symbolic"
                : "battery-profile-powersave-symbolic"
        }
    }

    fullRepresentation: Item {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 12
        Layout.preferredWidth: Layout.minimumWidth
        Layout.maximumWidth: Layout.minimumWidth

        Layout.minimumHeight: fullColumn.implicitHeight + Kirigami.Units.largeSpacing * 2
        Layout.preferredHeight: Layout.minimumHeight
        Layout.maximumHeight: Layout.minimumHeight

        ColumnLayout {
            id: fullColumn
            anchors.centerIn: parent
            spacing: Kirigami.Units.largeSpacing

            PlasmaComponents.Label {
                Layout.alignment: Qt.AlignHCenter
                text: root.ready
                    ? "CPU boost: " + (root.boostEnabled ? "enabled" : "disabled")
                    : "CPU boost: …"
                font.bold: true
            }

            PlasmaComponents.Switch {
                Layout.alignment: Qt.AlignHCenter
                checked: root.boostEnabled
                onToggled: root.toggle()
            }
        }
    }
}
