import QtQuick
import QtTest
import "../../../Calendars.js" as Calendars
import "../../../Hijri.js" as Hijri

TestCase {
  name: "CalendarQtFormats"

  function test_gregorianMatchesQt_data() {
    return [
      { tag: "24-hour h", pattern: "h:mm" },
      { tag: "24-hour hh", pattern: "hh:mm" },
      { tag: "12-hour AP", pattern: "h:mm AP" },
      { tag: "12-hour A", pattern: "hh:mm A" },
      { tag: "12-hour a", pattern: "h:mm a" },
      { tag: "12-hour mixed case", pattern: "h:mm Ap aP" },
      { tag: "24-hour with period", pattern: "HH:mm AP" },
      { tag: "quoted period", pattern: "h:mm 'AP'" },
      { tag: "escaped apostrophe", pattern: "hh:mm 'o''clock'" },
      { tag: "timezone", pattern: "HH:mm t tt ttt tttt" },
      { tag: "quoted timezone", pattern: "HH:mm 'tttt'" },
      { tag: "milliseconds", pattern: "ss.z zz zzz" },
      { tag: "compact", pattern: "yyyyMMddhhmmssAP" },
      { tag: "full date", pattern: "dddd d MMMM yyyy h:mm AP" }
    ]
  }

  function test_gregorianMatchesQt(data) {
    var registry = Calendars.createRegistry(Hijri)
    var entry = Calendars.normalizeSettings({}, registry).value.calendars[0]
    var locale = Qt.locale("en_US")
    var day = registry.gregorian.toDay(2026, 11, 19)
    for (var hour of [0, 13, 23]) {
      for (var ms of [0, 5, 42, 250]) {
        var date = new Date(2026, 10, 19, hour, 5, 9, ms)
        var labels = {
          number: String,
          weekday: function(value, shortName) { return locale.dayName(value, shortName ? Locale.ShortFormat : Locale.LongFormat) },
          month: function(parts, shortName) { return locale.monthName(parts.month - 1, shortName ? Locale.ShortFormat : Locale.LongFormat) },
          period: function(value) { return value < 12 ? locale.amText : locale.pmText },
          timeZone: function(token) { return date.toLocaleTimeString(locale, token) }
        }
        compare(Calendars.formatDate(registry, entry, day, date, data.pattern, labels),
          date.toLocaleString(locale, data.pattern), data.pattern + ", hour " + hour + ", ms " + ms)
      }
    }
  }
}
