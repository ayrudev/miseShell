pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import QtQuick.Effects
import Quickshell.Hyprland

Scope {
  id: root

  readonly property int frameThickness: 10
  readonly property int barHeight: 30
  readonly property int cornerRadius: 16
  readonly property color frameColor: "#1e1e2e"

  // Every monitor's bar reads from this shared clock.
  SystemClock {
    id: systemClock
    precision: SystemClock.Minutes
  }

  // Reserve space for tiled windows while letting clicks pass through.
  component EdgeReservation: PanelWindow {
    color: "transparent"
    implicitWidth: 1
    implicitHeight: 1
    mask: Region {}
  }

  // Build one frame and one set of edge reservations per screen.
  Variants {
    model: Quickshell.screens

    Scope {
      id: monitor
      required property var modelData

      EdgeReservation {
        screen: monitor.modelData
        anchors.top: true
        exclusiveZone: root.frameThickness
      }

      EdgeReservation {
        screen: monitor.modelData
        anchors.left: true
        exclusiveZone: root.frameThickness
      }

      EdgeReservation {
        screen: monitor.modelData
        anchors.right: true
        exclusiveZone: root.frameThickness
      }

      EdgeReservation {
        screen: monitor.modelData
        anchors.bottom: true
        exclusiveZone: root.barHeight
      }

      // Shared drawing surface for the frame, bar, and future popups.
      PanelWindow {
        screen: monitor.modelData
        anchors {
          top: true
          bottom: true
          left: true
          right: true
        }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        // Accept pointer input inside the bottom bar and pass clicks through elsewhere.
        mask: Region {
          item: barContent
        }

        // Define the rounded opening used by the visual mask.
        Item {
          id: opening
          anchors.fill: parent
          visible: false
          layer.enabled: true

          Rectangle {
            x: root.frameThickness
            y: root.frameThickness
            width: Math.max(0, parent.width - 2 * root.frameThickness)
            height: Math.max(0, parent.height - root.frameThickness - root.barHeight)
            radius: root.cornerRadius
          }
        }

        // Paint the frame and use the inverted mask to cut out the opening.
        Rectangle {
          anchors.fill: parent
          color: root.frameColor
          layer.enabled: true
          layer.effect: MultiEffect {
            maskSource: opening
            maskEnabled: true
            maskInverted: true
          }
        }

        Item {
          id: barContent

          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          height: root.barHeight

          // Match this bar to its Hyprland monitor so the highlight is per screen.
          readonly property HyprlandMonitor hyprMonitor: Hyprland.monitors.values.find(output => output.name === monitor.modelData.name) ?? null

          Row {
            anchors.left: parent.left
            anchors.leftMargin: root.frameThickness
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
                  color: button.selected ? root.frameColor : "#cdd6f4"
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
            text: Qt.formatDateTime(systemClock.date, "hh:mm")
            color: "#cdd6f4"
          }
        }
      }
    }
  }
}
