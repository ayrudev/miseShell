pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

Item {
  id: barContent

  required property string screenName
  required property int edgePadding
  required property color frameColor
  required property string clockText

  // Match this bar to its Hyprland monitor so the highlight is per screen.
  readonly property HyprlandMonitor hyprMonitor: Hyprland.monitors.values.find(output => output.name === barContent.screenName) ?? null

  Row {
    anchors.left: parent.left
    anchors.leftMargin: barContent.edgePadding
    anchors.verticalCenter: parent.verticalCenter
    spacing: 4

    Repeater {
      model: 5

      delegate: Rectangle {
        id: button

        required property int index
        readonly property int workspaceNumber: index + 1
        readonly property bool selected: barContent.hyprMonitor?.activeWorkspace?.id === workspaceNumber

        width: 22
        height: barContent.height - 8
        radius: 5
        color: selected ? "#cba6f7" : "transparent"

        Text {
          anchors.centerIn: parent
          text: button.workspaceNumber.toString()
          color: button.selected ? barContent.frameColor : "#cdd6f4"
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor

          onClicked: {
            const number = button.workspaceNumber;

            // Switch by number so a click can open a workspace that doesn't exist yet.
            if (Hyprland.usingLua) {
              Hyprland.dispatch(`hl.dsp.focus({ workspace = "${number}" })`);
            } else {
              Hyprland.dispatch(`workspace ${number}`);
            }
          }
        }
      }
    }
  }

  Text {
    anchors.centerIn: parent
    text: barContent.clockText
    color: "#cdd6f4"
  }

  Row {
    anchors.right: parent.right
    anchors.rightMargin: barContent.edgePadding
    anchors.verticalCenter: parent.verticalCenter
    spacing: 12

    Text {
      color: "#cdd6f4"

      text: {
        const sink = Pipewire.defaultAudioSink;

        if (!sink?.ready || !sink.audio) {
          return "Vol —";
        }

        if (sink.audio.muted) {
          return "Muted";
        }

        return `Vol ${Math.round(sink.audio.volume * 100)}%`;
      }
    }

    Text {
      readonly property UPowerDevice battery: UPower.displayDevice

      // Hide the label until UPower reports a present battery.
      visible: battery.ready && battery.type === UPowerDeviceType.Battery && battery.isPresent

      color: "#cdd6f4"
      text: visible ? `Bat ${Math.round(battery.percentage * 100)}%` : ""
    }
  }
}
