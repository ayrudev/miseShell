pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import QtQuick.Effects
import Quickshell.Services.Pipewire

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

  // Track the current output so Quickshell can read its volume and mute state.
  PwObjectTracker {
    objects: [Pipewire.defaultAudioSink]
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
        Bar {
          id: barContent

          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          height: root.barHeight

          screenName: monitor.modelData.name
          edgePadding: root.frameThickness
          frameColor: root.frameColor
          clockText: Qt.formatDateTime(systemClock.date, "hh:mm")
        }
      }
    }
  }
}
