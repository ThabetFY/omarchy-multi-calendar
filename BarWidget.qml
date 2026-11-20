pragma ComponentBehavior: Bound

import QtQuick
import qs.Commons
import qs.Ui as Ui
import "Model.js" as Model

// Date/time label for the bar, and the host for the calendar popup.
//
// Left click reveals the calendar — asking "what is the date?" is what a
// click on a clock means — right click walks the common label formats, and
// middle click opens the timezone picker.
Ui.BarWidget {
  id: root
  moduleName: "thabetfy.multi-calendar"

  CalendarContext {
    id: calendar
    settings: root.settings
  }
  readonly property PluginTranslations strings: calendar.strings
  readonly property CalendarContext calendarContext: calendar
  readonly property Panel calendarPanel: panelLoader.item as Panel
  // Omarchy's token groups and scoped bar facade are anonymous QObjects.
  // Keep only these external interfaces dynamic; our popup is typed above.
  readonly property var fontTokens: Style.font
  readonly property var barTokens: Style.bar
  readonly property var hostBar: bar

  property date displayDate: clock.date

  readonly property string configuredFormat: calendar.configuredFormat(vertical)
  readonly property string configuredAltFormat: vertical
    ? setting("verticalFormatAlt", "dd\nMMM\n'W'ww\n''yy")
    : setting("formatAlt", "d MMMM 'W'ww yyyy")

  readonly property var formatRing: Model.clockFormatRing(configuredFormat, configuredAltFormat, calendar.formats(vertical))

  // What the bar shows is what shell.json stores, so a cycled format is the
  // format from then on rather than something that reverts on restart.
  readonly property string activeFormat: configuredFormat

  // A seconds label needs the clock to tick sixty times as often, and a
  // repaint a second is a price only the formats that print seconds pay.
  readonly property bool showsSeconds: calendar.needsSeconds(activeFormat, vertical)
  readonly property string displayText: formatted(displayDate)
  readonly property var verticalLines: displayText.split("\n")

  // Arabic fallback fonts can have taller lines than the bar's Latin font.
  // Measure the actual text instead of assuming a fixed line-height ratio.
  Text {
    id: stackedMeasure
    visible: false
    textFormat: Text.PlainText
    text: !root.vertical && root.verticalLines.length > 1 ? root.displayText : ""
    font.family: button.fontFamily
    font.pixelSize: root.fontTokens.body
  }

  function refresh() {
    displayDate = new Date()
    if (root.calendarPanel) root.calendarPanel.refresh()
  }

  function cycleFormat() {
    var current = String(configuredFormat)
    var next = Model.nextClockFormat(formatRing, current)
    if (next === "" || next === current) return

    var entry = { id: root.moduleName }
    for (let key in root.settings) if (key !== "id") entry[key] = root.settings[key]
    entry[root.vertical ? "verticalFormat" : "format"] = next

    // Applied locally first so the label changes on the click itself; the
    // shell.json write comes back through the bar as the same value.
    root.settings = entry
    // The host supplies a capability-scoped QObject, not a concrete Bar type.
    var hostShell = root.hostBar ? root.hostBar.shell : null
    if (hostShell && typeof hostShell.updateEntryInline === "function")
      hostShell.updateEntryInline(root.moduleName, entry)
  }

  function formatted(date) {
    return calendar.formatted(date, activeFormat, root.vertical)
  }

  // ---- Calendar popup. Shape contract for shell.summon/hide/toggle
  //      routing: Bar.findPanelWidget requires open/close/opened on the
  //      bar-widget root.
  readonly property bool opened: root.calendarPanel ? root.calendarPanel.opened : false

  function open() {
    if (root.calendarPanel) root.calendarPanel.open()
  }

  function close() {
    if (root.calendarPanel) root.calendarPanel.close()
  }

  function togglePanel() {
    if (root.calendarPanel) root.calendarPanel.toggle()
  }

  function toggleWeekStart() {
    if (root.calendarPanel) root.calendarPanel.toggleWeekStart()
  }

  // The clock fills more slot than it paints a mark for, at both
  // orientations: horizontally it is a text label in a padded slot, so the
  // dot takes the label width; vertically it is a stack of icon-sized lines,
  // so the dot takes one line — the same mark every icon widget gets, rather
  // than a rule running the height of the whole stack.
  readonly property real openPanelIndicatorWidth: button.labelWidth
  readonly property real openPanelIndicatorHeight: Math.max(Style.space(10), Math.round(root.barTokens.iconSlot * 0.55))

  // Forwarded so this widget can stand in for the panel as the bar's popout
  // identity: Bar.requestPopout prefers closeForPopoutSwitch over close, and
  // KeyboardPanel reads popoutSwitchClosing back off its owner.
  readonly property bool popoutSwitchClosing: root.calendarPanel ? root.calendarPanel.popoutSwitchClosing : false

  function closeForPopoutSwitch() {
    if (root.calendarPanel) root.calendarPanel.closeForPopoutSwitch()
  }

  function injectPanel() {
    var target = root.calendarPanel
    if (!target) return
    target.bar = root.bar
    target.settings = root.settings
    target.anchorItem = button
    target.hostWidget = root
    target.moduleName = root.moduleName
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  WallClock {
    id: clock
    step: root.showsSeconds ? 1000 : 60000
    onDateChanged: root.displayDate = date
  }

  Loader {
    id: panelLoader
    active: true
    sourceComponent: Panel {
      calendar: root.calendarContext
    }
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  ShellIpc {
    target: root.moduleName

    function refresh(): void { root.broadcast("refresh") }
    function status(): string {
      return JSON.stringify({
        calendars: calendar.calendars,
        primaryCalendar: calendar.primary.id,
        weekColumns: calendar.weekCalendars.length,
        progressBars: calendar.progressCalendars.length,
        configurationError: calendar.configurationError,
        displayText: root.displayText,
        opened: root.opened
      })
    }
    function cycleFormat(): void { root.cycleFormat() }
    function toggleWeekStart(): void { root.toggleWeekStart() }
    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.togglePanel() }
  }

  Ui.WidgetButton {
    id: button
    anchors.fill: root
    bar: root.bar
    text: root.vertical ? "" : root.displayText
    labelVisible: !root.vertical
    hasVisualContent: root.vertical ? root.verticalLines.length > 0 : button.text !== ""
    fixedHeight: root.vertical ? root.verticalLines.length * root.barTokens.iconSlot : -1
    horizontalMargin: 8.75
    verticalPadding: 8.75
    fontSize: !root.vertical && root.verticalLines.length > 1
      ? Math.min(root.fontTokens.body, root.fontTokens.body * Math.max(1, button.height - Style.space(6))
        / Math.max(1, stackedMeasure.implicitHeight))
      : root.fontTokens.body
    tooltipText: root.strings.followsSystem ? I18n.t("clock.toggleFormat") : root.strings.t("calendar.formatHint")
    // The clock is text to read, not an icon to press, so a click never
    // shrinks it; the format it cycles to, or the panel it opens, is feedback.
    pressFeedbackButtons: Qt.NoButton

    onPressed: function(b) {
      if (b === Qt.RightButton) root.cycleFormat()
      else if (b === Qt.MiddleButton) {
        if (root.hostBar && typeof root.hostBar.run === "function") root.hostBar.run("omarchy-menu-timezone")
      }
      else root.togglePanel()
    }

    Column {
      visible: root.vertical
      anchors.fill: parent

      Repeater {
        model: root.verticalLines

        Text {
          required property string modelData
          textFormat: Text.PlainText
          width: button.width
          height: root.barTokens.iconSlot
          text: modelData
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
          font.family: button.fontFamily
          font.pixelSize: button.fontSize
          fontSizeMode: Text.HorizontalFit
          minimumPixelSize: 8
          color: button.foreground
        }
      }
    }
  }
}
