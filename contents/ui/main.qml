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

    property int currentMaxKHz: 0
    property int cpuMaxKHz: 0
    property int nominalMHz: 0

    Plasmoid.icon: root.boostEnabled
    ? "battery-profile-performance-symbolic"
    : "battery-profile-powersave-symbolic"

    Plasma5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            if (sourceName.indexOf("info") !== -1) {
                var out = (data["stdout"] || "").trim()
                var parts = out.split(" ")
                if (parts.length >= 4) {
                    root.boostEnabled = (parts[0] === "enabled")
                    root.currentMaxKHz = parseInt(parts[1])
                    root.cpuMaxKHz = parseInt(parts[2])
                    root.nominalMHz = parseInt(parts[3])
                }
                root.ready = true
            }
            disconnectSource(sourceName)
        }
    }

    function refresh() {
        exec.connectSource("/usr/local/bin/turbo-boost info")
    }

    function toggle() {
        var newState = !root.boostEnabled
        root.boostEnabled = newState
        exec.connectSource("/usr/local/bin/turbo-boost " + (newState ? "on" : "off"))
        refreshTimer.start()
    }

    Timer {
        id: refreshTimer
        interval: 500
        repeat: false
        onTriggered: root.refresh()
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: root.refresh()

    compactRepresentation: Item {
        id: compactRoot

        // Ancho forzado para ensanchar la hitbox
        Layout.minimumWidth: Kirigami.Units.gridUnit * 1.8
        Layout.preferredWidth: Layout.minimumWidth

        Kirigami.Icon {
            anchors.centerIn: parent
            width: compactRoot.height
            height: compactRoot.height
            source: Plasmoid.icon
            active: mouseArea.containsMouse
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.expanded = !root.expanded
        }
    }

    fullRepresentation: Item {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 14
        Layout.preferredWidth: Layout.minimumWidth
        Layout.maximumWidth: Layout.minimumWidth
        Layout.minimumHeight: fullColumn.implicitHeight + Kirigami.Units.largeSpacing * 2
        Layout.preferredHeight: Layout.minimumHeight
        Layout.maximumHeight: Layout.minimumHeight

        ColumnLayout {
            id: fullColumn
            anchors.centerIn: parent
            spacing: Kirigami.Units.smallSpacing

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

            PlasmaComponents.Label {
                Layout.alignment: Qt.AlignHCenter
                visible: root.ready
                text: "Current: " + (root.currentMaxKHz / 1000000).toFixed(2) + " GHz"
                opacity: 0.8
            }

            PlasmaComponents.Label {
                Layout.alignment: Qt.AlignHCenter
                visible: root.ready
                text: "Base: " + (root.nominalMHz > 0 ? (root.nominalMHz / 1000).toFixed(2) + " GHz" : "N/A")
                + "  |  Max: " + (root.cpuMaxKHz / 1000000).toFixed(2) + " GHz"
                opacity: 0.8
            }
        }
    }
}
