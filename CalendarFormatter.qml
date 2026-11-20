import QtQuick
import "Calendars.js" as Calendars

// Locale and presentation belong here; providers contain only calendar math.
QtObject {
  id: root
  required property var registry
  required property var entry
  readonly property var provider: registry[entry.provider]
  readonly property var locale: Qt.locale(strings.formatLocale)
  readonly property string name: strings.t(provider.nameKey)
  readonly property string shortName: strings.t(provider.shortNameKey)
  readonly property string language: strings.language
  readonly property bool followsSystem: strings.followsSystem

  property PluginTranslations strings: PluginTranslations {
    requestedLanguage: root.entry.language
  }

  function number(value) {
    return entry.digits === "latin" ? String(value) : strings.formatNumber(value)
  }

  function monthName(date, shortName, standalone) {
    if (typeof provider.monthNameKey === "function") return strings.t(provider.monthNameKey(date.month))
    var length = shortName ? Locale.ShortFormat : Locale.LongFormat
    return standalone ? locale.standaloneMonthName(date.month - 1, length) : locale.monthName(date.month - 1, length)
  }

  function format(day, time, pattern) {
    return Calendars.formatDate(root.registry, root.entry, day, time, pattern, {
      number: function(value) { return root.number(value) },
      weekday: function(value, shortName) { return root.locale.dayName(value, shortName ? Locale.ShortFormat : Locale.LongFormat) },
      month: function(date, shortName) { return root.monthName(date, shortName, false) },
      period: function(hour) { return root.locale[hour < 12 ? "amText" : "pmText"] },
      timeZone: function(token) { return time.toLocaleTimeString(root.locale, token) }
    })
  }

  function monthLabel(year, month) {
    return strings.t("date.month").arg(monthName({ year: year, month: month }, false, true)).arg(number(year))
  }

  function yearLabel(year, includeName) {
    if (year === null) return includeName ? strings.t("calendar.yearLabel").arg(name).arg("—") : "—"
    return includeName ? strings.t("calendar.yearLabel").arg(name).arg(number(year)) : number(year)
  }

  function percentage(value) {
    return value === null ? "—" : strings.t("progress.percent").arg(number(Math.round(value * 100)))
  }
}
