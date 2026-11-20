pragma ComponentBehavior: Bound

import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui as Ui
import "Model.js" as Model

// The clock's calendar popup: a month grid with ISO week numbers, built to
// sit beside the weather panel — same hero-over-detail composition, same
// spacing scale, same small-caps labels.
//
// The grid is a read-out rather than a picker: today is the only marked
// day, and the only thing that moves is which month is on screen —
// chevrons, the scroll wheel, and the arrow keys all step it.
//
// BarWidget.qml owns the bar label and hands this panel the button to
// anchor against.
Ui.Panel {
  id: root
  moduleName: "omarchy.clock"
  ipcTarget: "omarchy.clock"
  manageIpc: false

  required property CalendarContext calendar
  readonly property PluginTranslations strings: calendar.strings
  readonly property bool multiple: calendar.multiple
  readonly property CalendarFormatter primaryFormatter: calendar.primaryFormatter
  readonly property CalendarFormatter secondaryFormatter: calendar.secondaryFormatter
  readonly property var weekCalendars: calendar.weekCalendars
  // These host interfaces are anonymous QObjects, not exported QML types.
  readonly property var fontTokens: Style.font
  readonly property var spacingTokens: Style.spacing
  readonly property var hostBar: bar

  property var anchorItem: null

  // The bar tracks the widget mounted in its slot — BarWidget.qml — not this
  // nested panel. Everything the bar identifies a panel by has to be that
  // widget: the popout coordinator (and with it the open-panel dot under the
  // pill) compares against `slot.activeItem`, and switchPanelFrom looks the
  // slot up the same way.
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root

  component CalendarContent: Ui.PanelKeyCatcher {
    property Ui.TextField bornField: null
    property Ui.TextField expectancyField: null
  }

  // ---- Today. The wall clock keeps this honest across midnight so the
  //      highlight rolls over without the panel being reopened.
  property date today: new Date()
  readonly property int todayDay: calendar.dayForDate(today)
  readonly property var todayCalendar: calendar.dateForDay(todayDay)

  // The month on screen. Stepping moves this and nothing else: the grid is
  // a read-out, not a picker, so there is no per-day cursor to keep in sync.
  property int viewYear: todayCalendar ? todayCalendar.year : 0
  property int viewMonth: todayCalendar ? todayCalendar.month : 1

  readonly property bool viewingCurrentMonth: todayCalendar !== null && viewYear === todayCalendar.year && viewMonth === todayCalendar.month

  // Pinned to today, not to the month being browsed — stepping through the
  // calendar does not change how much of the year is gone.
  readonly property var primaryProgress: calendar.progressFor(calendar.primary.id, todayDay)
  readonly property var secondaryProgress: calendar.calendars.length > 1
    ? calendar.progressFor(calendar.calendars[1].id, todayDay) : null

  // Memento mori, for anyone who goes looking: double-tapping the year bar
  // asks for a birth year and a life expectancy, and a second bar tracks one
  // against the other. A birth year rather than an age, so it keeps counting
  // on its own. Without one the bar stays hidden.
  readonly property int birthYear: Model.parseBirthYear(setting("birthYear", 0), today.getFullYear())
  readonly property int age: Model.ageFromBirthYear(birthYear, today.getFullYear())
  readonly property int lifeExpectancy: Model.parseLifeExpectancy(setting("lifeExpectancy", 0))
  readonly property real lifeDone: Model.lifeProgress(age, lifeExpectancy)
  readonly property int lifeDonePercent: Model.lifeProgressPercent(age, lifeExpectancy)
  property bool editingLife: false

  // Unset falls through to the locale's own first day, so a fresh install
  // starts out matching the rest of the desktop rather than a hardcoded
  // convention. Clicking the grid's "W" heading writes the choice back to
  // shell.json.
  readonly property int weekStart: Model.normalizedWeekStart(setting("weekStartDay", null), labelLocale.firstDayOfWeek)
  // Names and the default week start follow the Omarchy language rather than
  // the system locale, which only catches up at the next login.
  readonly property var labelLocale: Qt.locale(strings.formatLocale)
  // Qt's MMMM is the genitive form ("октября"), right beside a day but not
  // in a month heading, so the title takes the standalone name ("октябрь")
  // and lets each language order it against the year.
  readonly property string monthYearLabel: (strings.followsSystem ? Commons.I18n.t("clock.monthYear") : strings.t("date.month"))
    .arg(viewYear > 0 ? primaryFormatter.monthName({ year: viewYear, month: viewMonth }, false, true) : "—")
    .arg(viewYear > 0 ? primaryFormatter.number(viewYear) : "—")
  readonly property string nextWeekStartLabel: labelLocale.dayName(Model.toggledWeekStart(weekStart), Locale.LongFormat)
  readonly property var weekdays: Model.weekdayOrder(weekStart)
  readonly property var weeks: calendar.monthGrid(viewYear, viewMonth, weekStart, todayDay)

  readonly property string primaryKey: calendar.primary.id + ":" + calendar.primary.provider
  onPrimaryKeyChanged: goToToday()


  // Guarded so the widget renders before the bar is injected (the bar-widget
  // contract instantiates it bare).
  readonly property color contentForeground: root.hostBar ? root.hostBar.foreground : Commons.Color.foreground
  readonly property string contentFontFamily: root.hostBar ? root.hostBar.fontFamily : root.fontTokens.family

  readonly property int cellWidth: Style.space(52)
  readonly property int cellHeight: Style.space(multiple ? 40 : 34)
  readonly property int cellSpacing: Style.space(2)
  readonly property int weekColumnWidth: Style.space(multiple ? 24 : 32)
  readonly property int weekColumnsWidth: weekCalendars.length > 0
    ? weekCalendars.length * weekColumnWidth + (weekCalendars.length - 1) * cellSpacing : 0
  readonly property int gutterWidth: Style.space(14)

  function open() {
    refresh()
    root.controller.show()
  }

  function close() {
    // Dismissing the panel mid-edit would otherwise leave the inputs up,
    // waiting behind a closed popup for the next time it opens.
    if (root.editingLife) root.cancelEditingLife()
    root.controller.hide()
  }

  function toggle() {
    if (root.opened) root.close()
    else root.open()
  }

  function switchPanel(direction) {
    if (root.hostBar && typeof root.hostBar.switchPanelFrom === "function")
      return root.hostBar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  function refresh() {
    root.today = new Date()
    root.goToToday()
  }

  function goToToday() {
    if (!root.todayCalendar) return
    root.viewYear = root.todayCalendar.year
    root.viewMonth = root.todayCalendar.month
  }

  function moveMonth(delta) {
    var next = root.calendar.stepMonth(viewYear, viewMonth, delta)
    root.viewYear = next.year
    root.viewMonth = next.month
  }

  function moveYear(delta) {
    var next = root.calendar.stepYear(viewYear, viewMonth, delta)
    root.viewYear = next.year
    root.viewMonth = next.month
  }

  // Applied locally first so the panel redraws on the click itself; the
  // shell.json write comes back through the bar as the same value. With no
  // writable entry (the widget is not in the layout) it stays a session-only
  // preference rather than doing nothing. The host widget builds its own
  // entry when the label format is cycled, so it has to be kept in step or
  // it would write this key straight back out from a stale copy.
  function persistSettings(values) {
    var entry = { id: root.moduleName }
    for (let existing in root.settings) if (existing !== "id") entry[existing] = root.settings[existing]
    for (let key in values) entry[key] = values[key]

    root.settings = entry
    if (root.hostWidget && "settings" in root.hostWidget) root.hostWidget.settings = entry
    var hostShell = root.hostBar ? root.hostBar.shell : null
    if (hostShell && typeof hostShell.updateEntryInline === "function")
      hostShell.updateEntryInline(root.moduleName, entry)
  }

  function setWeekStart(day) {
    var next = Model.normalizedWeekStart(day, root.weekStart)
    if (next === root.weekStart) return
    persistSettings({ weekStartDay: Model.weekStartSettingName(next) })
  }

  function dateLabel(formatter, includeYear) {
    if (!formatter) return ""
    var pattern = includeYear ? "dddd d MMMM yyyy"
      : (formatter.followsSystem ? Commons.I18n.t("clock.dayMonthFormat") : formatter.strings.t("date.dayMonth"))
    return formatter.format(root.todayDay, root.today, pattern)
  }

  function startEditingLife() {
    root.editingLife = true
    Qt.callLater(function() {
      var content = panel.loadedContent as CalendarContent
      if (!content) return
      var bornField = content.bornField
      var expectancyField = content.expectancyField
      bornField.text = root.birthYear > 0 ? String(root.birthYear) : ""
      expectancyField.text = String(root.lifeExpectancy)
      bornField.selectAll()
      bornField.forceActiveFocus()
    })
  }

  function cancelEditingLife() {
    root.editingLife = false
    Qt.callLater(function() { if (panel.loadedContent) panel.loadedContent.forceActiveFocus() })
  }

  // Shared by both fields: Tab hops to the other one, Enter commits the pair,
  // Escape drops the lot.
  function handleLifeKey(event, other) {
    if (event.key === Qt.Key_Escape) {
      root.cancelEditingLife()
      event.accepted = true
    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
      root.commitLife()
      event.accepted = true
    } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
      other.selectAll()
      other.forceActiveFocus()
      event.accepted = true
    }
  }

  // Double-tapping the life bar puts it away again. The expectancy stays in
  // the config so setting a birth year again brings your own number back
  // rather than the default.
  function clearLife() {
    if (root.birthYear <= 0) return
    persistSettings({ birthYear: 0 })
  }

  function commitLife() {
    var content = panel.loadedContent as CalendarContent
    if (!content) return
    var bornField = content.bornField
    var expectancyField = content.expectancyField
    var born = Model.parseBirthYear(bornField.text, today.getFullYear())
    var span = Model.parseLifeExpectancy(expectancyField.text)
    if (born !== root.birthYear || span !== root.lifeExpectancy)
      persistSettings({ birthYear: born, lifeExpectancy: span })
    cancelEditingLife()
  }

  function toggleWeekStart() {
    setWeekStart(Model.toggledWeekStart(root.weekStart))
  }

  // English short day names, matching the rest of the interface.
  function weekdayLabel(weekday) {
    return String(labelLocale.dayName(weekday, Locale.ShortFormat)).toUpperCase()
  }

  function weekHint(entry) {
    var start = (strings.followsSystem ? Commons.I18n.t("clock.startWeeksOn") : strings.t("calendar.weekStart")).arg(root.nextWeekStartLabel)
    if (!root.multiple) return start
    var formatter = root.calendar.formatterFor(entry.id)
    if (!formatter) return ""
    return strings.t("calendar.weekColumn")
      .arg(formatter.name)
      .arg(strings.t(entry.weekRule === "iso" ? "calendar.isoWeeks" : "calendar.relativeWeeks"))
      .arg(start)
  }

  WallClock {
    id: clock
    onDateChanged: {
      if (Model.keyForDate(clock.date) === Model.keyForDate(root.today)) return
      var followToday = root.viewingCurrentMonth
      root.today = clock.date
      if (followToday) root.goToToday()
    }
  }

  Ui.KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    // Anchor under the widget rather than the middle of the bar, so the
    // popup follows wherever the widget is placed.
    centerOnBar: false
    focusTarget: panel.loadedContent
    contentWidth: panel.fittedContentWidth(Style.space(560))
    contentHeight: panel.fittedContentHeight(panel.loadedContentHeight)

    content: CalendarContent {
      id: keyCatcher
      bornField: bornInput
      expectancyField: expectancyInput
      implicitHeight: calendarColumn.implicitHeight
      anchors.fill: parent
      LayoutMirroring.enabled: root.strings.rightToLeft
      LayoutMirroring.childrenInherit: true
      blocked: root.editingLife
      onMoveRequested: function(dx, dy) {
        if (dx !== 0) root.moveMonth(dx)
        if (dy !== 0) root.moveYear(dy)
      }
      onActivateRequested: root.goToToday()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(t) {
        if (t === "[") root.moveMonth(-1)
        else if (t === "]") root.moveMonth(1)
        else if (t === "{") root.moveYear(-1)
        else if (t === "}") root.moveYear(1)
        else if (t === "t" || t === "T") root.goToToday()
        else if (t === "w" || t === "W") root.toggleWeekStart()
      }

      Flickable {
        id: calendarScroll
        anchors.fill: parent
        contentWidth: calendarColumn.width
        contentHeight: calendarColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height || contentWidth > width

        Column {
          id: calendarColumn
          // Never narrower than the grid. The popup width is capped to what
          // the screen allows, and a fixed seven-column grid would otherwise
          // lose its last days off the edge instead of scrolling.
          width: Math.max(calendarScroll.width, gridColumn.width)
          spacing: Style.space(8)

          // ---- Hero: today, centered. Once the view has stepped back
          //      it is also the way home — clicking the date you are
          //      looking for beats hunting for a reset button.
          Item {
            width: parent.width
            height: heroRow.height

            Row {
              id: heroRow
              anchors.horizontalCenter: parent.horizontalCenter
              spacing: Style.space(22)

              Text {
                id: heroIcon
                textFormat: Text.PlainText
                // Baseline-aligned, not center-aligned: "July 26" carries a
                // descender, so centering the two boxes leaves the icon
                // sitting visibly low against the digits.
                anchors.baseline: heroDate.baseline
                text: "󰃭"
                color: heroMouse.containsMouse
                  ? Style.hoverStateColor(root.contentForeground, Commons.Color.accent)
                  : root.contentForeground
                font.family: root.contentFontFamily
                // Decorative, and deliberately outside the Style.font.*
                // scale. Sized so the glyph reads at the cap height of the
                // date beside it rather than towering over it.
                font.pixelSize: root.multiple ? 32 : 48
              }

              Text {
                id: heroDate
                textFormat: Text.PlainText
                anchors.verticalCenter: parent.verticalCenter
                text: root.dateLabel(root.primaryFormatter, false)
                color: heroMouse.containsMouse
                  ? Style.hoverStateColor(root.contentForeground, Commons.Color.accent)
                  : root.contentForeground
                font.family: root.contentFontFamily
                font.pixelSize: root.multiple ? 38 : 52
                width: Math.min(implicitWidth, Math.max(1, calendarColumn.width - heroIcon.implicitWidth - heroRow.spacing))
                fontSizeMode: Text.HorizontalFit
                minimumPixelSize: 20
                font.bold: true
              }
            }

            MouseArea {
              id: heroMouse
              x: heroRow.x
              y: heroRow.y
              width: heroRow.width
              height: heroRow.height
              enabled: !root.viewingCurrentMonth
              hoverEnabled: enabled
              cursorShape: Qt.PointingHandCursor
              onClicked: root.goToToday()

              Ui.PanelToolTip {
                visible: heroMouse.containsMouse
                text: root.strings.followsSystem ? Commons.I18n.t("clock.backToToday") : root.strings.t("calendar.today")
                fontFamily: root.contentFontFamily
              }
            }
          }

          Text {
            visible: root.multiple
            width: parent.width
            textFormat: Text.PlainText
            text: root.secondaryFormatter ? root.dateLabel(root.secondaryFormatter, true) : ""
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            color: Qt.darker(root.contentForeground, 1.4)
            font.family: root.contentFontFamily
            font.pixelSize: root.fontTokens.bodySmall
          }

          // ---- Year progress, doubling as the rule under the hero:
          //      a plain hairline said nothing, and whole days done
          //      over days in the year says the same thing louder.
          Item {
            visible: root.calendar.primary.showYearProgress
            width: parent.width
            height: visible ? yearBlock.y + yearBlock.height : 0

            Item {
              id: yearBlock
              y: Style.space(6)
              anchors.horizontalCenter: parent.horizontalCenter
              width: gridColumn.width
              height: primaryYear.implicitHeight

              TapHandler {
                enabled: !root.editingLife
                onDoubleTapped: root.startEditingLife()
              }

              Row {
                visible: root.editingLife
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                spacing: Style.space(10)

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: root.strings.followsSystem ? Commons.I18n.t("clock.born") : root.strings.t("life.born")
                  textFormat: Text.PlainText
                  color: Qt.darker(root.contentForeground, 1.5)
                  font.family: root.contentFontFamily
                  font.pixelSize: root.fontTokens.bodySmall
                  font.letterSpacing: root.strings.rightToLeft ? 0 : 1
                }

                Ui.TextField {
                  id: bornInput
                  width: Style.space(70)
                  anchors.verticalCenter: parent.verticalCenter
                  placeholderText: root.strings.followsSystem ? Commons.I18n.t("clock.year") : root.strings.t("life.year")
                  foreground: root.contentForeground
                  font.family: root.contentFontFamily
                  inputMethodHints: Qt.ImhDigitsOnly

                  Keys.onPressed: function(event) { root.handleLifeKey(event, expectancyInput) }
                }

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  anchors.verticalCenterOffset: 0
                  leftPadding: Style.space(6)
                  text: root.strings.followsSystem ? Commons.I18n.t("clock.liveTo") : root.strings.t("life.expectancy")
                  textFormat: Text.PlainText
                  color: Qt.darker(root.contentForeground, 1.5)
                  font.family: root.contentFontFamily
                  font.pixelSize: root.fontTokens.bodySmall
                  font.letterSpacing: root.strings.rightToLeft ? 0 : 1
                }

                Ui.TextField {
                  id: expectancyInput
                  width: Style.space(60)
                  anchors.verticalCenter: parent.verticalCenter
                  placeholderText: "90"
                  foreground: root.contentForeground
                  font.family: root.contentFontFamily
                  inputMethodHints: Qt.ImhDigitsOnly

                  Keys.onPressed: function(event) { root.handleLifeKey(event, bornInput) }
                }
              }

              YearProgress {
                id: primaryYear
                visible: !root.editingLife
                anchors.fill: parent
                label: root.primaryFormatter.yearLabel(root.primaryProgress.year, root.multiple)
                percentage: root.primaryFormatter.percentage(root.primaryProgress.value)
                progress: root.primaryProgress.value === null ? 0 : root.primaryProgress.value
                supported: root.primaryProgress.value !== null
                foreground: root.contentForeground
                fontFamily: root.contentFontFamily
              }
            }
          }

          Item {
            visible: root.multiple && root.secondaryFormatter !== null && root.secondaryFormatter.entry.showYearProgress
            width: parent.width
            height: visible ? secondaryYear.implicitHeight : 0

            YearProgress {
              id: secondaryYear
              anchors.horizontalCenter: parent.horizontalCenter
              width: gridColumn.width
              label: root.secondaryFormatter && root.secondaryProgress ? root.secondaryFormatter.yearLabel(root.secondaryProgress.year, true) : ""
              percentage: root.secondaryFormatter && root.secondaryProgress ? root.secondaryFormatter.percentage(root.secondaryProgress.value) : ""
              progress: root.secondaryProgress && root.secondaryProgress.value !== null ? root.secondaryProgress.value : 0
              supported: root.secondaryProgress !== null && root.secondaryProgress.value !== null
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
            }
          }

          Text {
            visible: root.calendar.configurationError !== ""
            width: parent.width
            textFormat: Text.PlainText
            text: root.strings.t("calendar.invalid")
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            color: root.contentForeground
            font.family: root.contentFontFamily
            font.pixelSize: root.fontTokens.bodySmall
          }

          // ---- Memento mori. Only here once someone has gone looking and
          //      given an age; the same rail as the year above it, measured
          //      against a nominal lifetime.
          Item {
            visible: root.birthYear > 0
            width: parent.width
            height: visible ? lifeBlock.height : 0

            Item {
              id: lifeBlock
              anchors.horizontalCenter: parent.horizontalCenter
              width: gridColumn.width
              height: Math.max(lifeLabel.implicitHeight, Style.space(10))

              Text {
                id: lifeLabel
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                  text: root.strings.followsSystem ? Commons.I18n.t("clock.life") : root.strings.t("life.label")
                textFormat: Text.PlainText
                color: Qt.darker(root.contentForeground, 1.5)
                font.family: root.contentFontFamily
                  font.pixelSize: root.fontTokens.bodySmall
                font.letterSpacing: 1
              }

              Text {
                id: lifePercent
                textFormat: Text.PlainText
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                  text: root.strings.t("progress.percent").arg(root.strings.formatNumber(root.lifeDonePercent))
                color: root.contentForeground
                font.family: root.contentFontFamily
                  font.pixelSize: root.fontTokens.bodySmall
              }

              Rectangle {
                anchors.left: lifeLabel.right
                anchors.right: lifePercent.left
                anchors.leftMargin: Style.space(12)
                anchors.rightMargin: Style.space(12)
                anchors.verticalCenter: parent.verticalCenter
                height: Style.space(6)
                radius: Style.cornerRadius > 0 ? height / 2 : 0
                color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.12)

                Rectangle {
                  width: Math.round(parent.width * root.lifeDone)
                  height: parent.height
                  radius: parent.radius
                  color: Style.selectedStateColor(root.contentForeground, Commons.Color.accent)

                  Behavior on width { NumberAnimation { duration: Style.duration(160); easing.type: Easing.OutCubic } }
                }
              }

              TapHandler {
                onDoubleTapped: root.clearLife()
              }

              MouseArea {
                id: lifeMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton

                Ui.PanelToolTip {
                  visible: lifeMouse.containsMouse
                  text: root.strings.t("life.hint")
                  fontFamily: root.contentFontFamily
                }
              }
            }
          }

          // ---- Month grid: week numbers down a gutter on the left, then
          //      the seven day columns. Always six rows, so the popup is
          //      exactly as tall in February as it is in August.
          Item {
            width: parent.width
            height: gridColumn.y + gridColumn.height

            WheelHandler {
              onWheel: function(event) {
                // Horizontal wheels and touchpad side-scrolls report y === 0;
                // without this they would every one read as "next month".
                if (event.angleDelta.y === 0) return
                root.moveMonth(event.angleDelta.y > 0 ? -1 : 1)
              }
            }

            Column {
              id: gridColumn
              // The meter above is a solid rule; the grid needs room to
              // read as its own block rather than hanging off it.
              y: Style.space(18)
              anchors.horizontalCenter: parent.horizontalCenter
              spacing: Style.space(3)

              Row {
                id: headerRow
                spacing: root.cellSpacing

                // The week-number heading doubles as the week-start toggle.
                // It is the one control in the panel whose meaning is not
                // self-evident, so it carries a tooltip naming the day the
                // click will switch to.
                Repeater {
                  model: root.weekCalendars

                Rectangle {
                  id: weekHeading
                  required property var modelData
                  readonly property var formatter: root.calendar.formatterFor(modelData.id)
                  width: root.weekColumnWidth
                  height: Style.space(16)
                  radius: Style.cornerRadius
                  color: weekStartMouse.containsMouse
                    ? Style.hoverFillFor(root.contentForeground, Commons.Color.accent)
                    : "transparent"

                  Text {
                    anchors.centerIn: parent
                    textFormat: Text.PlainText
                    text: root.multiple ? (weekHeading.formatter ? weekHeading.formatter.shortName : "")
                      : (root.strings.followsSystem ? Commons.I18n.t("clock.weekShort") : root.strings.t("calendar.week"))
                    color: weekStartMouse.containsMouse
                      ? Style.hoverStateColor(root.contentForeground, Commons.Color.accent)
                      : Qt.darker(root.contentForeground, 1.9)
                    font.family: root.contentFontFamily
                    font.pixelSize: root.fontTokens.caption
                    font.letterSpacing: 1
                    font.bold: true
                  }

                  MouseArea {
                    id: weekStartMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleWeekStart()
                  }

                  Ui.PanelToolTip {
                    visible: weekStartMouse.containsMouse
                    text: root.weekHint(weekHeading.modelData)
                    fontFamily: root.contentFontFamily
                  }
                }
                }

                Item {
                  visible: root.weekCalendars.length > 0
                  width: root.gutterWidth
                  height: Style.space(16)
                }

                Repeater {
                  model: root.weekdays

                  Text {
                    textFormat: Text.PlainText
                    required property var modelData
                    width: root.cellWidth
                    height: Style.space(16)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: root.weekdayLabel(modelData)
                    color: Qt.darker(root.contentForeground, 1.5)
                    font.family: root.contentFontFamily
                    font.pixelSize: root.fontTokens.caption
                    font.letterSpacing: root.strings.rightToLeft ? 0 : 1
                    font.bold: true
                  }
                }
              }

              Repeater {
                model: root.weeks

                Row {
                  id: weekRow
                  required property var modelData
                  spacing: root.cellSpacing

                  Repeater {
                    model: weekRow.modelData.weekNumbers

                  Text {
                    required property var modelData
                    textFormat: Text.PlainText
                    width: root.weekColumnWidth
                    height: root.cellHeight
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: modelData.number === null ? "—" : root.calendar.numberFor(modelData.id, modelData.number)
                    color: Qt.darker(root.contentForeground, 1.9)
                    font.family: root.contentFontFamily
                    font.pixelSize: root.fontTokens.caption
                  }
                  }

                  Item {
                    visible: root.weekCalendars.length > 0
                    width: root.gutterWidth
                    height: root.cellHeight
                  }

                  Repeater {
                    model: weekRow.modelData.days

                    Rectangle {
                      id: dayCell
                      required property var modelData

                      width: root.cellWidth
                      height: root.cellHeight
                      radius: Style.cornerRadius
                      // Today is outlined, not filled: a lit-up block shouts
                      // over a grid this quiet.
                      color: "transparent"
                      border.width: modelData.today ? root.spacingTokens.hairline : 0
                      border.color: Style.normalBorderFor(root.contentForeground, Commons.Color.accent)

                      Column {
                        anchors.centerIn: parent
                        spacing: Style.space(1)

                        Text {
                          textFormat: Text.PlainText
                          anchors.horizontalCenter: parent.horizontalCenter
                          text: dayCell.modelData.dates[0].date ? root.primaryFormatter.number(dayCell.modelData.dates[0].date.day) : "—"
                          color: dayCell.modelData.inMonth
                            ? (dayCell.modelData.weekend ? Qt.darker(root.contentForeground, 1.45) : root.contentForeground)
                            : Qt.darker(root.contentForeground, 2.2)
                          font.family: root.contentFontFamily
                          font.pixelSize: root.fontTokens.body
                          font.bold: dayCell.modelData.today
                        }

                        Text {
                          visible: root.multiple
                          textFormat: Text.PlainText
                          anchors.horizontalCenter: parent.horizontalCenter
                          text: root.secondaryFormatter && dayCell.modelData.dates.length > 1 && dayCell.modelData.dates[1].date
                            ? root.secondaryFormatter.number(dayCell.modelData.dates[1].date.day) : "—"
                          color: dayCell.modelData.inMonth ? Qt.darker(root.contentForeground, 1.6) : Qt.darker(root.contentForeground, 2.2)
                          font.family: root.contentFontFamily
                          font.pixelSize: root.fontTokens.caption
                        }
                      }
                    }
                  }
                }
              }
            }

            // Hairline down the week-number gutter, drawn only beside the
            // day rows so it does not cut through the header band. Placed
            // by x, so it follows the rows to the right edge when mirrored.
            Rectangle {
              visible: root.weekCalendars.length > 0
              readonly property real gutterOffset: root.weekColumnsWidth + root.cellSpacing + Math.round((root.gutterWidth - width) / 2)
              x: LayoutMirroring.enabled
                ? gridColumn.x + gridColumn.width - gutterOffset - width
                : gridColumn.x + gutterOffset
              y: gridColumn.y + headerRow.height + gridColumn.spacing
              width: root.spacingTokens.hairline
              height: gridColumn.height - headerRow.height - gridColumn.spacing
              color: root.contentForeground
              opacity: 0.1
            }
          }

          // ---- Month stepping, spanning the grid it drives. The chevrons
          //      sit on the grid's outer bounds, the same edges the year
          //      rail above uses, so the row reads as the panel's other
          //      full-width rail instead of a cluster floating in space.
          //      The label is centered and fixed-width, so it holds still
          //      from "MAY" to "SEPTEMBER".
          Item {
            width: parent.width
            height: monthNav.height

            Item {
              id: monthNav
              anchors.horizontalCenter: parent.horizontalCenter
              width: gridColumn.width
              height: monthLabel.implicitHeight + Style.space(10)

              Text {
                id: monthLabel
                textFormat: Text.PlainText
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                // Fixed width so the chevrons hold still between a
                // "MAY 2026" and a "SEPTEMBER 2026".
                width: Math.max(1, parent.width - Style.space(90))
                horizontalAlignment: Text.AlignHCenter
                text: root.monthYearLabel.toUpperCase()
                color: Qt.darker(root.contentForeground, 1.4)
                font.family: root.contentFontFamily
                font.pixelSize: root.fontTokens.body
                fontSizeMode: Text.HorizontalFit
                minimumPixelSize: 10
                font.letterSpacing: root.strings.rightToLeft ? 0 : 1
              }

              Ui.PanelActionButton {
                // Pulled out by the button's own padding so the glyph, not
                // its hit box, lines up with the "2026" on the year rail.
                anchors.left: parent.left
                anchors.leftMargin: -Style.space(8)
                anchors.verticalCenter: parent.verticalCenter
                // Previous points back along the reading direction.
                iconText: root.strings.rightToLeft ? "󰅂" : "󰅁"
                tooltipText: root.strings.followsSystem ? Commons.I18n.t("clock.previousMonth") : root.strings.t("calendar.previous")
                foreground: root.contentForeground
                fontFamily: root.contentFontFamily
                onClicked: root.moveMonth(-1)
              }

              Ui.PanelActionButton {
                anchors.right: parent.right
                anchors.rightMargin: -Style.space(8)
                anchors.verticalCenter: parent.verticalCenter
                iconText: root.strings.rightToLeft ? "󰅁" : "󰅂"
                tooltipText: root.strings.followsSystem ? Commons.I18n.t("clock.nextMonth") : root.strings.t("calendar.next")
                foreground: root.contentForeground
                fontFamily: root.contentFontFamily
                onClicked: root.moveMonth(1)
              }
            }
          }

        }
      }
    }
  }
}
