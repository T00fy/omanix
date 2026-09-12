import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

// Omanix-owned per-monitor variant of the upstream omanix.workspaces widget.
// Used only when omanix.hyprland.uniqueWorkspacePerMonitor = true. It lives
// OUTSIDE the vendored Omarchy tree (installed into the shell at package time)
// so re-vendoring upstream never conflicts with it, and the upstream
// omanix.workspaces widget stays byte-for-byte identical for shared mode.
//
// Each bar reflects ONLY its own monitor: labels 1-5 map to that monitor's real
// workspace ids (base + N, base looked up from the Nix-injected monitorBases),
// and the active dot follows this monitor's own activeWorkspace rather than the
// single global focused workspace.
BarWidget {
  id: root
  moduleName: "omanix.workspaces-per-monitor"

  // name -> workspace id base, injected from Nix (matches monitors.nix /
  // OMANIX_MONITOR_MAP). This bar's base is resolved by its own screen name.
  readonly property var monitorBases: root.setting("monitorBases", ({}))
  readonly property var qsScreen: QsWindow.window ? QsWindow.window.screen : null

  readonly property int wsBase: {
    var name = root.qsScreen ? root.qsScreen.name : ""
    var b = (root.monitorBases && name) ? root.monitorBases[name] : undefined
    return (b === undefined || b === null) ? 0 : b
  }

  function hyprMonitor() {
    if (!root.qsScreen) return null
    var name = root.qsScreen.name
    var mons = Hyprland.monitors.values
    for (var i = 0; i < mons.length; i++) {
      if (mons[i] && mons[i].name === name) return mons[i]
    }
    return null
  }

  // This monitor's own active workspace id (not the global focused one).
  readonly property var thisMonitor: root.hyprMonitor()
  readonly property int activeId: thisMonitor && thisMonitor.activeWorkspace
    ? thisMonitor.activeWorkspace.id : -1

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].id === id) return values[i]
    }

    return null
  }

  // Labels 1-5 plus any occupied workspace that belongs to this monitor's own
  // id range (base+1 .. base+10), shown as its label (id - base).
  function workspaceLabels() {
    var ids = [1, 2, 3, 4, 5]
    var values = Hyprland.workspaces.values
    var base = root.wsBase

    for (var i = 0; i < values.length; i++) {
      var label = values[i].id - base
      if (label > 0 && label <= 10 && ids.indexOf(label) === -1) ids.push(label)
    }

    ids.sort(function(left, right) { return left - right })
    return ids
  }

  function focusWorkspace(id) {
    if (!root.bar) return
    root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ workspace = \"" + id + "\" })"))
  }

  readonly property real trailingGap: root.vertical ? 0 : Style.spaceReal(1.5)

  implicitWidth: grid.implicitWidth + trailingGap
  implicitHeight: grid.implicitHeight

  GridLayout {
    id: grid
    anchors.fill: parent
    anchors.rightMargin: root.trailingGap
    columns: root.vertical ? 1 : root.workspaceLabels().length
    columnSpacing: root.vertical ? 0 : Style.space(1)
    rowSpacing: root.vertical ? Style.space(2) : 0

    Repeater {
      model: root.workspaceLabels()

      WidgetButton {
        required property int modelData

        readonly property int realId: modelData + root.wsBase
        readonly property var workspace: root.workspaceById(realId)
        readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
        readonly property bool focused: root.activeId === realId

        bar: root.bar
        text: focused ? "\uDB85\uDCFB" : (modelData === 10 ? "0" : String(modelData))
        opacity: occupied || focused ? 1 : 0.5
        horizontalMargin: 6
        verticalPadding: 6
        fixedWidth: root.vertical ? root.barSize : Style.space(20)
        fixedHeight: root.barSize
        onPressed: function() { root.focusWorkspace(realId) }
      }
    }
  }
}
