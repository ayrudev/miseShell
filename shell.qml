pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import QtQuick.Effects

Scope {
  id: root

  readonly property int frameThickness: 10
  readonly property int barHeight: 30
  readonly property int cornerRadius: 16
  readonly property color frameColor: "#1e1e2e"

  // An invisible panel that reserves space along one screen edge.
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

      // Top edge reservation
      EdgeReservation {
        screen: monitor.modelData
        anchors.top: true
        exclusiveZone: root.frameThickness
      }

      // Left edge reservation
      EdgeReservation {
        screen: monitor.modelData
        anchors.left: true
        exclusiveZone: root.frameThickness
      }

      // Right edge reservation
      EdgeReservation {
        screen: monitor.modelData
        anchors.right: true
        exclusiveZone: root.frameThickness
      }

      // Bottom bar reservation
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

        // The empty surface lets all pointer input through.
        mask: Region {}

        // The opaque part of this stencil defines the opening.
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

        // Paint the frame, then cut the rounded opening out of it.
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
      }
    }
  }
}
