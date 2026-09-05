import QtQuick
import qs.Ui

BarWidget {
  id: root
  moduleName: "omanix.menu"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "\ue900"
    fontFamily: "omanix"
    horizontalMargin: 7.5
    onPressed: function(button) {
      if (!root.bar) return
      if (button === Qt.RightButton) root.bar.run("xdg-terminal-exec")
      else root.bar.run("omanix-shell shell toggle omanix.menu '{\"menu\":\"root\"}'")
    }
  }
}
