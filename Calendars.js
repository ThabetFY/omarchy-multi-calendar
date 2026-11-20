// Calendar providers and layout data. All dates use integer Julian day numbers,
// not local-midnight timestamps, so DST cannot duplicate or omit a grid cell.
// Add trusted, bundled providers to createRegistry; configuration never loads code.

function integer(value) {
  return typeof value === "number" && isFinite(value) && Math.floor(value) === value
}

function weekday(day) {
  return ((day + 1) % 7 + 7) % 7
}

function createRegistry(hijri) {
  var registry = {}
  registry.gregorian = {
    nameKey: "calendar.gregorian",
    shortNameKey: "calendar.gregorianShort",
    defaultWeekRule: "iso",
    fromDay: function(day) {
      if (!integer(day)) return null
      var date = hijri.jdnToGregorian(day)
      return date.year >= 1 && date.year <= 9999 ? date : null
    },
    toDay: function(year, month, day) {
      if (!integer(year) || !integer(month) || !integer(day) ||
          year < 1 || year > 9999 || month < 1 || month > 12 || day < 1 || day > 31) return null
      var result = hijri.gregorianToJdn(year, month, day)
      var check = hijri.jdnToGregorian(result)
      return check.year === year && check.month === month && check.day === day ? result : null
    },
    monthsInYear: function(year) { return integer(year) && year >= 1 && year <= 9999 ? 12 : 0 },
    stepMonth: function(year, month, delta) {
      var total = year * 12 + month - 1 + delta
      var nextYear = Math.floor(total / 12)
      return integer(total) && nextYear >= 1 && nextYear <= 9999
        ? { year: nextYear, month: total - nextYear * 12 + 1 } : { year: year, month: month }
    },
    yearBounds: function(year) {
      if (!integer(year) || year < 1 || year > 9999) return null
      return { start: hijri.gregorianToJdn(year, 1, 1), end: hijri.gregorianToJdn(year + 1, 1, 1) }
    },
    isoWeek: function(day) {
      var thursday = day + 4 - (weekday(day) || 7)
      var year = hijri.jdnToGregorian(thursday).year
      return Math.floor((thursday - hijri.gregorianToJdn(year, 1, 1)) / 7) + 1
    }
  }
  registry["islamic-umalqura"] = {
    nameKey: "calendar.hijri",
    shortNameKey: "calendar.hijriShort",
    defaultWeekRule: "calendar",
    monthNameKey: function(month) { return "month." + month },
    fromDay: function(day) {
      if (!integer(day)) return null
      var date = hijri.jdnToGregorian(day)
      return hijri.hijriFromGregorian(date.year, date.month, date.day)
    },
    toDay: function(year, month, day) {
      var date = hijri.hijriToGregorianDate(year, month, day)
      return date ? hijri.gregorianToJdn(date.year, date.month, date.day) : null
    },
    monthsInYear: function(year) { return hijri.hijriDaysInYear(year) > 0 ? 12 : 0 },
    stepMonth: hijri.stepHijriMonth,
    yearBounds: function(year) {
      var date = hijri.hijriToGregorianDate(year, 1, 1)
      if (!date) return null
      var start = hijri.gregorianToJdn(date.year, date.month, date.day)
      return { start: start, end: start + hijri.hijriDaysInYear(year) }
    }
  }
  return registry
}

function hasProvider(registry, id) {
  return typeof id === "string" && Object.prototype.hasOwnProperty.call(registry, id)
}

function normalizeSettings(settings, registry, languageCodes) {
  settings = settings || {}
  if (typeof settings !== "object" || Array.isArray(settings))
    return { ok: false, error: "Calendar settings must be an object." }
  var languages = languageCodes || ["ar", "en"]
  var inheritedLanguage = settings.language === "system" || languages.indexOf(settings.language) !== -1 ? settings.language : "system"
  var explicit = Object.prototype.hasOwnProperty.call(settings, "calendars")
  var entries = settings.calendars
  var primary = settings.primaryCalendar
  if (!explicit) {
    // The old dual-calendar preview used primaryCalendar. A stock clock with
    // neither key stays a single Gregorian calendar, matching upstream.
    entries = primary === "hijri" || primary === "gregorian"
      ? [{ id: primary, provider: primary === "hijri" ? "islamic-umalqura" : "gregorian" },
         { id: primary === "hijri" ? "gregorian" : "hijri", provider: primary === "hijri" ? "gregorian" : "islamic-umalqura" }]
      : [{ id: "gregorian", provider: "gregorian" }]
  }
  if (!Array.isArray(entries) || entries.length < 1 || entries.length > 2)
    return { ok: false, error: "Select one or two calendars." }
  var result = []
  var ids = []
  for (var i = 0; i < entries.length; i++) {
    var entry = entries[i]
    if (!entry || typeof entry !== "object" || Array.isArray(entry) ||
        typeof entry.id !== "string" || !/^[a-z][a-z0-9_-]{0,39}$/.test(entry.id) ||
        ["time", "constructor", "prototype", "__proto__"].indexOf(entry.id) !== -1 ||
        ids.indexOf(entry.id) !== -1)
      return { ok: false, error: "Calendar IDs must be safe, unique names; time is reserved." }
    if (!hasProvider(registry, entry.provider))
      return { ok: false, error: "Unknown calendar provider." }
    var language = entry.language === undefined ? inheritedLanguage : entry.language
    if (language !== "system" && languages.indexOf(language) === -1)
      return { ok: false, error: "Unknown calendar language." }
    for (var b = 0; b < 2; b++) {
      var option = ["showWeekNumbers", "showYearProgress"][b]
      if (entry[option] !== undefined && typeof entry[option] !== "boolean")
        return { ok: false, error: "Calendar visibility settings must be booleans." }
    }
    for (var f = 0; f < 2; f++) {
      var formatKey = ["format", "verticalFormat"][f]
      if (entry[formatKey] !== undefined &&
          (typeof entry[formatKey] !== "string" || entry[formatKey].length < 1 || entry[formatKey].length > 256 ||
           /[{}]/.test(entry[formatKey])))
        return { ok: false, error: "Per-calendar formats must be plain date/time patterns of 1–256 characters." }
    }
    var rule = entry.weekRule === undefined ? registry[entry.provider].defaultWeekRule : entry.weekRule
    if (rule !== "iso" && rule !== "calendar")
      return { ok: false, error: "Week numbering must use iso or calendar." }
    if (entry.digits !== undefined && entry.digits !== "locale" && entry.digits !== "latin")
      return { ok: false, error: "Digits must use locale or latin." }
    result.push({
      id: entry.id,
      provider: entry.provider,
      language: language,
      digits: entry.digits || "locale",
      format: entry.format || "d MMMM yyyy",
      verticalFormat: entry.verticalFormat || "dd\nMM\nyyyy",
      showWeekNumbers: entry.showWeekNumbers !== false,
      showYearProgress: entry.showYearProgress !== false,
      weekRule: rule
    })
    ids.push(entry.id)
  }
  if (primary === undefined || primary === null || primary === "") primary = result[0].id
  if (ids.indexOf(primary) === -1) return { ok: false, error: "The primary calendar must be selected." }
  if (result[0].id !== primary) result.reverse()
  return { ok: true, value: { calendars: result, primaryCalendar: primary, explicit: explicit } }
}

function acceptSettings(previous, settings, registry, languages) {
  var checked = normalizeSettings(settings, registry, languages)
  if (checked.ok) return { config: checked.value, error: "" }
  var fallback = previous || normalizeSettings({}, registry, languages).value
  return { config: fallback, error: checked.error }
}

function progress(registry, entry, day) {
  if (!entry || !hasProvider(registry, entry.provider))
    return { id: entry ? entry.id : "", year: null, value: null }
  var provider = registry[entry.provider]
  var date = provider.fromDay(day)
  var bounds = date ? provider.yearBounds(date.year) : null
  return {
    id: entry.id,
    year: date ? date.year : null,
    value: bounds ? Math.max(0, Math.min(1, (day - bounds.start) / (bounds.end - bounds.start))) : null
  }
}

function weekNumber(registry, entry, rowStart, weekStart) {
  if (entry.weekRule === "iso") {
    var thursday = rowStart + (4 - weekStart + 7) % 7
    return registry.gregorian.isoWeek(thursday)
  }
  // Calendar-relative, not ISO: seven-day blocks from the calendar's New
  // Year, read at the fourth day of the displayed row, including year edges.
  var provider = registry[entry.provider]
  var anchor = rowStart + 3
  var date = provider.fromDay(anchor)
  var bounds = date ? provider.yearBounds(date.year) : null
  return bounds ? Math.floor((anchor - bounds.start) / 7) + 1 : null
}

function monthGrid(registry, config, year, month, weekStart, today) {
  var primary = registry[config.calendars[0].provider]
  var first = primary.toDay(year, month, 1)
  if (first === null) return []
  var start = ((Math.round(weekStart) % 7) + 7) % 7
  var cursor = first - (weekday(first) - start + 7) % 7
  var weeks = []
  for (var w = 0; w < 6; w++) {
    var rowStart = cursor
    var days = []
    for (var d = 0; d < 7; d++, cursor++) {
      var parts = config.calendars.map(function(entry) {
        return { id: entry.id, date: registry[entry.provider].fromDay(cursor) }
      })
      var main = parts[0].date
      days.push({
        key: String(cursor),
        dayNumber: cursor,
        dates: parts,
        weekday: weekday(cursor),
        inMonth: main !== null && main.year === year && main.month === month,
        weekend: weekday(cursor) === 0 || weekday(cursor) === 6,
        today: cursor === today
      })
    }
    weeks.push({
      days: days,
      weekNumbers: config.calendars.filter(function(entry) { return entry.showWeekNumbers }).map(function(entry) {
        return { id: entry.id, number: weekNumber(registry, entry, rowStart, start) }
      })
    })
  }
  return weeks
}

function stepYear(provider, year, month, delta) {
  // Month count belongs to the provider, not the UI: future leap-month
  // calendars need not have twelve months or preserve the same month index.
  var target = year + delta
  var count = provider.monthsInYear(target)
  return count > 0 ? { year: target, month: Math.min(month, count) } : { year: year, month: month }
}

function formatPattern(pattern, tokenValue) {
  var text = String(pattern).slice(0, 256)
  var output = ""
  var quoted = false
  for (var i = 0; i < text.length;) {
    if (text.charAt(i) === "'") {
      if (text.charAt(i + 1) === "'") {
        output += "'"
        i += 2
      } else {
        quoted = !quoted
        i++
      }
    } else {
      var match = quoted ? null : /^(dddd|ddd|dd|d|MMMM|MMM|MM|M|yyyy|yy|ww|HH|H|hh|h|mm|m|ss|s|zzz|zz|z|tttt|ttt|tt|t|AP|ap|Ap|aP|A|a)/.exec(text.slice(i))
      output += match ? tokenValue(match[0]) : text.charAt(i)
      i += match ? match[0].length : 1
    }
  }
  return output
}

function formatDate(registry, entry, day, time, pattern, labels) {
  var provider = registry[entry.provider]
  var date = provider.fromDay(day)
  var hour = time.getHours()
  // Qt's h/hh use 24-hour time unless an unquoted AM/PM token is present.
  var twelveHour = /[Aa]/.test(String(pattern).slice(0, 256).replace(/'[^']*'?/g, ""))
  var number = function(value, width) {
    var result = labels.number(value)
    for (var length = String(value).length; length < (width || 1); length++)
      result = labels.number(0) + result
    return result
  }
  return formatPattern(pattern, function(token) {
    switch (token) {
      case "HH": return number(hour, 2)
      case "H": return number(hour)
      case "hh": return number(twelveHour ? hour % 12 || 12 : hour, 2)
      case "h": return number(twelveHour ? hour % 12 || 12 : hour)
      case "mm": return number(time.getMinutes(), 2)
      case "m": return number(time.getMinutes())
      case "ss": return number(time.getSeconds(), 2)
      case "s": return number(time.getSeconds())
      case "z": case "zz": case "zzz":
        var fraction = time.getMilliseconds()
        var width = 3
        if (token !== "zzz")
          while (width > 1 && fraction % 10 === 0) { fraction /= 10; width-- }
        return number(fraction, width)
      case "AP": case "A": return labels.period(hour).toUpperCase()
      case "ap": case "a": return labels.period(hour).toLowerCase()
      case "Ap": case "aP": return labels.period(hour)
      case "t": case "tt": case "ttt": case "tttt": return labels.timeZone(token)
    }
    if (!date) return "—"
    switch (token) {
      case "dddd": return labels.weekday(weekday(day), false)
      case "ddd": return labels.weekday(weekday(day), true)
      case "d": return number(date.day)
      case "dd": return number(date.day, 2)
      case "M": return number(date.month)
      case "MM": return number(date.month, 2)
      case "MMM": return labels.month(date, true)
      case "MMMM": return labels.month(date, false)
      case "yyyy": return number(date.year, 4)
      case "yy": return number(date.year % 100, 2)
      case "ww":
        var bounds = provider.yearBounds(date.year)
        var week = entry.weekRule === "iso" ? registry.gregorian.isoWeek(day)
          : (bounds ? Math.floor((day - bounds.start) / 7) + 1 : null)
        return week === null ? "—" : number(week, 2)
    }
    return token
  })
}

if (typeof module !== "undefined") {
  module.exports = {
    createRegistry: createRegistry,
    normalizeSettings: normalizeSettings,
    acceptSettings: acceptSettings,
    progress: progress,
    monthGrid: monthGrid,
    stepYear: stepYear,
    formatDate: formatDate,
    weekday: weekday
  }
}
