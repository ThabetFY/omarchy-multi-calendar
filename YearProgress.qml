import QtQuick
import qs.Commons
import qs.Commons as Commons

Item {
  id: root
  property string label: ""
  property string percentage: ""
  property real progress: 0
  property bool supported: true
  property color foreground: Commons.Color.foreground
  readonly property var fontTokens: Style.font
  property string fontFamily: root.fontTokens.family
  implicitHeight: Math.max(yearLabel.implicitHeight, Style.space(10))

  Text {
    id: yearLabel
    textFormat: Text.PlainText
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    text: root.label
    width: Math.min(implicitWidth, parent.width * 0.5)
    elide: Text.ElideRight
    color: Qt.darker(root.foreground, 1.5)
    font.family: root.fontFamily
    font.pixelSize: root.fontTokens.bodySmall
  }

  Text {
    id: percent
    textFormat: Text.PlainText
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    text: root.percentage
    color: root.foreground
    font.family: root.fontFamily
    font.pixelSize: root.fontTokens.bodySmall
  }

  Rectangle {
    anchors.left: yearLabel.right
    anchors.right: percent.left
    anchors.leftMargin: Style.space(12)
    anchors.rightMargin: Style.space(12)
    anchors.verticalCenter: parent.verticalCenter
    height: Style.space(6)
    radius: Style.cornerRadius > 0 ? height / 2 : 0
    color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.12)
    visible: root.supported

    Rectangle {
      width: Math.round(parent.width * root.progress)
      height: parent.height
      radius: parent.radius
      color: Style.selectedStateColor(root.foreground, Commons.Color.accent)
      Behavior on width { NumberAnimation { duration: Style.duration(160); easing.type: Easing.OutCubic } }
    }
  }
}
