import QtQuick
import "Model.js" as Model
import "Hijri.js" as Hijri
import "Calendars.js" as Calendars

// Shared by the bar label and its popup, so a bad live config cannot make them
// disagree. Reject the whole calendar selection rather than silently dropping
// an unsupported third calendar.
QtObject {
  id: root
  property var settings: ({})
  property PluginTranslations strings: PluginTranslations {
    requestedLanguage: String(root.settings.language || "system")
  }
  readonly property var registry: Calendars.createRegistry(Hijri)
  property var config: Calendars.normalizeSettings({}, registry).value
  property string configurationError: ""
  readonly property var calendars: config.calendars
  readonly property var primary: calendars[0]
  readonly property bool multiple: calendars.length === 2
  readonly property var weekCalendars: calendars.filter(function(entry) { return entry.showWeekNumbers })
  readonly property var progressCalendars: calendars.filter(function(entry) { return entry.showYearProgress })
  readonly property var primaryFormatter: first
  readonly property var secondaryFormatter: multiple ? second : null

  property CalendarFormatter first: CalendarFormatter {
    registry: root.registry
    entry: root.calendars[0]
  }
  property CalendarFormatter second: CalendarFormatter {
    registry: root.registry
    entry: root.calendars[root.calendars.length - 1]
  }

  function accept() {
    var next = Calendars.acceptSettings(root.config, root.settings, root.registry)
    if (next.error && next.error !== root.configurationError)
      console.warn("Multi Calendar: " + next.error + " Keeping the previous valid selection.")
    root.configurationError = next.error
    if (JSON.stringify(root.config) !== JSON.stringify(next.config)) root.config = next.config
  }

  onSettingsChanged: accept()
  Component.onCompleted: accept()

  function formatterFor(id) {
    // Derived bindings such as multiple can still hold the old value while
    // Qt is removing delegates. Check IDs and bounds on one current snapshot.
    var selected = root.config.calendars
    if (id === selected[0].id) return root.first
    if (selected.length > 1 && id === selected[1].id) return root.second
    return null
  }

  function numberFor(id, value) {
    // A retiring Repeater delegate can still render its old calendar ID
    // after the selection changed, before Qt removes the old model.
    var formatter = formatterFor(id)
    return formatter ? formatter.number(value) : ""
  }

  function dayForDate(date) {
    return root.registry.gregorian.toDay(date.getFullYear(), date.getMonth() + 1, date.getDate())
  }

  function dateForDay(day) {
    return root.registry[root.primary.provider].fromDay(day)
  }

  function monthGrid(year, month, weekStart, today) {
    return Calendars.monthGrid(root.registry, root.config, year, month, weekStart, today)
  }

  function progressFor(id, today) {
    // Calculate from the accepted data, not the formatter QObjects: their
    // entry bindings need not have updated yet during a selection change.
    var entry = root.config.calendars.filter(function(candidate) { return candidate.id === id })[0]
    return Calendars.progress(root.registry, entry, today)
  }

  function stepMonth(year, month, delta) {
    return root.registry[root.primary.provider].stepMonth(year, month, delta)
  }

  function stepYear(year, month, delta) {
    return Calendars.stepYear(root.registry[root.primary.provider], year, month, delta)
  }

  function configuredFormat(vertical) {
    var key = vertical ? "verticalFormat" : "format"
    if (typeof settings[key] === "string" && settings[key].length > 0)
      return settings[key].slice(0, 1024)
    if (!root.config.explicit) return vertical ? "HH\n—\nmm" : "dddd HH:mm"
    if (!root.multiple) return root.primary[key]
    return root.calendars.map(function(entry) { return "{" + entry.id + "}" }).join(vertical ? "\n—\n" : " · ")
  }

  function formats(vertical) {
    var formats = Model.clockFormats(vertical)
    if (root.multiple) {
      formats.push(root.calendars.map(function(entry) {
        return "{" + entry.id + ":" + (vertical ? "dd\nMM\nyyyy" : "d MMMM") + "}"
      }).join(vertical ? "\n—\n" : " · "))
      if (!vertical)
        formats.push(root.calendars.map(function(entry) { return "{" + entry.id + ":dd/MM/yyyy}" }).join("\n"))
    }
    return formats
  }

  function needsSeconds(pattern, vertical) {
    return Model.clockNeedsSeconds(pattern, function(id) {
      if (id === "time") return vertical ? "HH\nmm" : "HH:mm"
      var formatter = root.formatterFor(id)
      return formatter ? formatter.entry[vertical ? "verticalFormat" : "format"] : ""
    })
  }

  function formatted(date, pattern, vertical) {
    var day = dayForDate(date)
    var combined = Model.formatCalendarTemplate(pattern, function(id, fieldPattern) {
      // Time is independent of calendar range, provider, or selected aliases.
      if (id === "time")
        return date.toLocaleTimeString(root.first.locale, fieldPattern || (vertical ? "HH\nmm" : "HH:mm"))
      var formatter = root.formatterFor(id)
      if (!formatter) return "—"
      return formatter.format(day, date, fieldPattern || formatter.entry[vertical ? "verticalFormat" : "format"])
    })
    return combined === null ? root.first.format(day, date, pattern) : combined
  }
}
