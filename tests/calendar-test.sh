#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/helpers.sh"

run_node_test <<'JS'
const calendar = requireFromRoot('Model.js')

// ---- week start resolution
assertEqual(calendar.normalizedWeekStart('monday', 0), 1, 'calendar reads a named week start')
assertEqual(calendar.normalizedWeekStart('SUN', 1), 0, 'calendar reads an abbreviated week start')
assertEqual(calendar.normalizedWeekStart(6, 1), 6, 'calendar reads a numeric week start')
assertEqual(calendar.normalizedWeekStart(null, 0), 0, 'calendar falls back to the locale first day')
assertEqual(calendar.normalizedWeekStart('garbage', 0), 0, 'calendar falls back when the setting is unparseable')
assertEqual(calendar.normalizedWeekStart(undefined, undefined), 1, 'calendar defaults to Monday without a locale')

assertEqual(calendar.weekStartSettingName(0), 'sunday', 'calendar persists Sunday by name')
assertEqual(calendar.weekStartSettingName(1), 'monday', 'calendar persists Monday by name')

assertEqual(calendar.toggledWeekStart(1), 0, 'calendar toggles Monday to Sunday')
assertEqual(calendar.toggledWeekStart(0), 1, 'calendar toggles Sunday to Monday')
assertEqual(calendar.toggledWeekStart(6), 1, 'calendar toggles an exotic week start to Monday')

assertDeepEqual(calendar.weekdayOrder(1), [1, 2, 3, 4, 5, 6, 0], 'calendar orders weekdays from Monday')
assertDeepEqual(calendar.weekdayOrder(0), [0, 1, 2, 3, 4, 5, 6], 'calendar orders weekdays from Sunday')

// ---- ISO week numbers, matching the clock widget's 'ww' token
assertEqual(calendar.isoWeek(2026, 0, 1), 1, 'calendar numbers a Thursday January 1 as week 1')
assertEqual(calendar.isoWeek(2021, 0, 1), 53, 'calendar numbers early January into the previous ISO year')
assertEqual(calendar.isoWeek(2026, 11, 31), 53, 'calendar numbers the last week of a long year')
assertEqual(calendar.isoWeek(2026, 6, 26), 30, 'calendar numbers a midsummer Sunday')

// ---- day-of-year arithmetic behind the hero stats
assertEqual(calendar.dayOfYear(2026, 6, 26), 207, 'calendar counts the day of the year')
assertEqual(calendar.yearProgressPercent(2026, 0, 1), 0, 'calendar starts the year at zero percent done')
assertEqual(calendar.yearProgressPercent(2026, 6, 26), 56, 'calendar reports the share of the year behind you')
assertEqual(calendar.yearProgressPercent(2026, 11, 31), 100, 'calendar finishes the year at a hundred percent')
assertEqual(calendar.yearProgressPercent(2024, 11, 31), 100, 'calendar finishes a leap year too')

// ---- memento mori
// A birth year rather than an age, so the bar keeps counting on its own.
assertEqual(calendar.parseBirthYear('1979', 2026), 1979, 'calendar reads a birth year')
assertEqual(calendar.parseBirthYear(1979, 2026), 1979, 'calendar reads a numeric birth year')
assertEqual(calendar.parseBirthYear(' 1979 ', 2026), 1979, 'calendar trims a birth year')
assertEqual(calendar.parseBirthYear('2026', 2026), 2026, 'calendar accepts the current year')
assertEqual(calendar.parseBirthYear('2027', 2026), 0, 'calendar rejects a birth year in the future')
assertEqual(calendar.parseBirthYear('1905', 2026), 0, 'calendar rejects an implausibly distant birth year')
assertEqual(calendar.parseBirthYear('79', 2026), 0, 'calendar rejects a two-digit year')
assertEqual(calendar.parseBirthYear('', 2026), 0, 'calendar treats a blank birth year as unset')
assertEqual(calendar.parseBirthYear('abc', 2026), 0, 'calendar treats a non-numeric birth year as unset')
assertEqual(calendar.parseBirthYear(0, 2026), 0, 'calendar treats a cleared birth year as unset')

assertEqual(calendar.ageFromBirthYear('1979', 2026), 47, 'calendar derives an age from a birth year')
assertEqual(calendar.ageFromBirthYear('1979', 2027), 48, 'calendar keeps counting as the years pass')
assertEqual(calendar.ageFromBirthYear('2026', 2026), 0, 'calendar makes someone born this year zero')
assertEqual(calendar.ageFromBirthYear('', 2026), 0, 'calendar derives no age without a birth year')

assertEqual(calendar.parseAge('47'), 47, 'calendar reads an age')
assertEqual(calendar.parseAge(47), 47, 'calendar reads a numeric age')
assertEqual(calendar.parseAge(' 47 '), 47, 'calendar trims an age')
assertEqual(calendar.parseAge(''), 0, 'calendar treats a blank age as unset')
assertEqual(calendar.parseAge('0'), 0, 'calendar treats zero as unset')
assertEqual(calendar.parseAge('-3'), 0, 'calendar treats a negative age as unset')
assertEqual(calendar.parseAge('121'), 0, 'calendar treats an implausible age as unset')
assertEqual(calendar.parseAge('abc'), 0, 'calendar treats a non-numeric age as unset')
assertEqual(calendar.parseAge('4.5'), 0, 'calendar treats a fractional age as unset')
assertEqual(calendar.parseLifeExpectancy('65'), 65, 'calendar reads a life expectancy')
assertEqual(calendar.parseLifeExpectancy(''), 90, 'calendar defaults the life expectancy to ninety')
assertEqual(calendar.parseLifeExpectancy(0), 90, 'calendar defaults an unset life expectancy')
assertEqual(calendar.parseLifeExpectancy('abc'), 90, 'calendar defaults a non-numeric life expectancy')
assertEqual(calendar.parseLifeExpectancy('200'), 90, 'calendar defaults an implausible life expectancy')

assertEqual(calendar.lifeProgressPercent(45, 90), 50, 'calendar measures a life against the expectancy given')
assertEqual(calendar.lifeProgressPercent(45, 65), 69, 'calendar honours a shorter expectancy')
assertEqual(calendar.lifeProgressPercent(45, ''), 50, 'calendar falls back to ninety when no expectancy is set')
assertEqual(calendar.lifeProgressPercent(90, 90), 100, 'calendar fills the life bar at the expectancy')
assertEqual(calendar.lifeProgressPercent(80, 65), 100, 'calendar never overfills the life bar')
assertEqual(calendar.lifeProgressPercent(0, 90), 0, 'calendar leaves the life bar empty when no age is set')
assertEqual(calendar.daysInYear(2024), 366, 'calendar knows leap years are longer')
assertEqual(calendar.daysInYear(2026), 365, 'calendar knows common years')

// ---- month grid
const july = calendar.monthGrid(2026, 6, 1, '2026-07-26')
assertEqual(july.length, 6, 'calendar always draws six week rows')
assert(july.every(week => week.days.length === 7), 'calendar always draws seven day columns')
assertDeepEqual(july.map(week => week.week), [27, 28, 29, 30, 31, 32], 'calendar numbers every row by ISO week')
assertDeepEqual(july[0].days.map(day => day.day), [29, 30, 1, 2, 3, 4, 5], 'calendar pads the first row with the previous month')
assertDeepEqual(july[0].days.map(day => day.inMonth), [false, false, true, true, true, true, true], 'calendar marks padding days as outside the month')
assertDeepEqual(july[0].days.map(day => day.weekend), [false, false, false, false, false, true, true], 'calendar marks Saturday and Sunday as the weekend')

assertDeepEqual(
  july.flatMap(week => week.days).filter(day => day.today).map(day => day.key),
  ['2026-07-26'],
  'calendar marks exactly one cell as today'
)
assert(july.flatMap(week => week.days).every(day => day.cursor === undefined), 'calendar grid carries no selection state')

// Both conventions land on the same ISO week numbers, because every row is
// numbered by the ISO week owning its Thursday.
const julySunday = calendar.monthGrid(2026, 6, 0, '')
assertDeepEqual(julySunday[0].days.map(day => day.day), [28, 29, 30, 1, 2, 3, 4], 'calendar shifts the grid for a Sunday week start')
assertDeepEqual(julySunday.map(week => week.week), [27, 28, 29, 30, 31, 32], 'calendar keeps ISO week numbers across week starts')

const januarySunday = calendar.monthGrid(2021, 0, 0, '')
assertEqual(januarySunday[0].week, 53, 'calendar carries the previous ISO year into a straddling first row')

// Zones that start DST at 00:00 have a calendar day with no local midnight, and
// the engines disagree about which side of the gap it falls on: V4 resolves it
// backward onto the previous date, V8 forward. Node therefore cannot see the
// duplicated day the shell draws, so pin the property that makes the question
// moot -- the grid is walked in UTC and never asks for a wall clock.
const RealDate = Date
class LocalTimeIsForbidden extends RealDate {
  constructor(...args) {
    if (args.length > 1) throw new Error('built a Date from local components')
    super(...args)
  }
  getFullYear() { throw new Error('read the local year') }
  getMonth() { throw new Error('read the local month') }
  getDate() { throw new Error('read the local day') }
  getDay() { throw new Error('read the local weekday') }
  setDate() { throw new Error('stepped the local day') }
}

function withoutLocalTime(build) {
  global.Date = LocalTimeIsForbidden
  try {
    return { value: build(), localTimeUse: '' }
  } catch (error) {
    return { value: null, localTimeUse: error.message }
  } finally {
    global.Date = RealDate
  }
}

const september = withoutLocalTime(() => calendar.monthGrid(2026, 8, 0, ''))
assertEqual(september.localTimeUse, '', 'calendar builds the month grid without reading local time')
assertDeepEqual(
  september.value.slice(0, 2).flatMap(week => week.days).map(day => day.day),
  [30, 31, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
  'calendar runs September 2026 straight through the Chilean DST midnight'
)

const stepped = withoutLocalTime(() => calendar.stepMonth(2026, 8, 1))
assertEqual(stepped.localTimeUse, '', 'calendar steps months without reading local time')
assertDeepEqual(stepped.value, { year: 2026, month: 9 }, 'calendar steps from September to October')

// Samoa skipped 30 December 2011 outright, a gap even V8 cannot paper over.
const previousTZ = process.env.TZ
process.env.TZ = 'Pacific/Apia'
const apia = calendar.monthGrid(2011, 11, 1, '')
if (previousTZ === undefined) delete process.env.TZ
else process.env.TZ = previousTZ
assertDeepEqual(apia[4].days.map(day => day.day), [26, 27, 28, 29, 30, 31, 1], 'calendar keeps a day the local zone skipped')

// ---- tick scheduling across a daylight-saving fold
// The fold instants are the second pass through the repeated hour (02:30:15
// CET, 01:30:15 EST), where a delay worked out on local wall time lands an
// hour back and goes negative.
for (const [zone, at, minute, second] of [
  ['Europe/Berlin', '2026-10-25T01:30:15Z', 45000, 1000],
  ['America/New_York', '2026-11-01T06:30:15Z', 45000, 1000],
  ['Europe/Berlin', '2026-10-26T11:00:15.250Z', 44750, 750],
]) {
  process.env.TZ = zone
  const now = Date.parse(at)
  assertEqual(calendar.msUntilNextTick(now, 60000), minute, `clock waits for the next minute at ${at} in ${zone}`)
  assertEqual(calendar.msUntilNextTick(now, 1000), second, `clock waits for the next second at ${at} in ${zone}`)
}
if (previousTZ === undefined) delete process.env.TZ
else process.env.TZ = previousTZ

// ---- stepping
assertDeepEqual(calendar.stepMonth(2026, 0, 1), { year: 2026, month: 1 }, 'calendar steps to the next month')
assertDeepEqual(calendar.stepMonth(2026, 0, -1), { year: 2025, month: 11 }, 'calendar steps back across the new year')
assertDeepEqual(calendar.stepMonth(2026, 11, 1), { year: 2027, month: 0 }, 'calendar steps forward across the new year')
assertDeepEqual(calendar.stepMonth(2026, 6, 12), { year: 2027, month: 6 }, 'calendar steps a whole year at a time')

assertEqual(calendar.dateKey(2026, 0, 5), '2026-01-05', 'calendar zero-pads date keys')
assertEqual(calendar.keyForDate(new Date(2026, 6, 26)), '2026-07-26', 'calendar keys a Date the same way')

// ---- bar label format ring
// The order must not depend on which entry is current: cycling writes the
// result back to shell.json, so a self-reordering ring would ping-pong.
const ring = calendar.clockFormatRing('dddd HH:mm', "d MMMM 'W'ww yyyy", calendar.clockFormats(false))
assertDeepEqual(ring, calendar.clockFormats(false), 'clock rings the stock presets in their own order')
assertEqual(new Set(ring).size, ring.length, 'clock never offers the same format twice')

assertDeepEqual(
  calendar.clockFormatRing("d MMMM 'W'ww yyyy", 'dddd HH:mm', calendar.clockFormats(false)),
  ring,
  'clock keeps the ring order steady as the current format moves through it'
)
assertDeepEqual(
  calendar.clockFormatRing('HH:mm:ss', '', ['HH:mm', 'dddd HH:mm']),
  ['HH:mm', 'dddd HH:mm', 'HH:mm:ss'],
  'clock appends a hand-written format to the end of the ring'
)
assertDeepEqual(calendar.clockFormatRing('', '', []), ['HH:mm'], 'clock keeps a usable format when nothing is configured')

assertEqual(calendar.nextClockFormat(ring, ring[0]), ring[1], 'clock steps to the next format')
assertEqual(calendar.nextClockFormat(ring, ring[ring.length - 1]), ring[0], 'clock wraps the format ring')
assertEqual(calendar.nextClockFormat(ring, 'HH:mm:ss'), ring[0], 'clock starts at the top from a format outside the ring')
assertEqual(
  calendar.nextClockFormat(ring, 'dddd HH:mm'),
  'dddd h:mm AP',
  'clock reaches an AM/PM twin in one right click'
)
assertEqual(calendar.isoWeekLiteral(2026, 0, 5), '02', 'clock zero-pads the ISO week token')

// ---- seconds detection, which decides how often the widget's clock ticks
assert(calendar.clockNeedsSeconds('dddd HH:mm:ss'), 'clock sees seconds in the live preset')
assert(calendar.clockNeedsSeconds('h:mm:ss AP'), 'clock sees seconds in an AM/PM format')
assert(!calendar.clockNeedsSeconds('dddd HH:mm'), 'clock sees no seconds in a minute format')
assert(!calendar.clockNeedsSeconds("d MMMM 'W'ww yyyy"), 'clock sees no seconds in the long date format')
assert(!calendar.clockNeedsSeconds("dd\nMMM\n'W'ww\n''yy"), 'clock sees no seconds in the stacked date format')
assert(!calendar.clockNeedsSeconds("HH:mm 'since'"), 'clock reads an s inside a quoted literal as text')
// Qt reads an opening quote with no closing one as a literal running to the end
// of the format, so "HH:mm 'sec" prints "09:39 sec" and never a second count.
assert(!calendar.clockNeedsSeconds("HH:mm 'sec"), 'clock reads an unterminated literal as text to the end')
assert(!calendar.clockNeedsSeconds("HH:mm's"), 'clock reads a trailing unterminated literal as text')
// The doubled quote is a literal apostrophe rather than an empty literal, so
// the s after it is still the seconds token: Qt prints "'23".
assert(calendar.clockNeedsSeconds("''s"), 'clock still sees seconds after an escaped apostrophe')
assert(!calendar.clockNeedsSeconds(''), 'clock sees no seconds in an empty format')
assert(!calendar.clockNeedsSeconds(null), 'clock sees no seconds in a missing format')

// ---- Umm al-Qura conversion and the combined calendar
const hijri = requireFromRoot('Hijri.js')
for (const [gregorian, expected] of [
  [[1924, 8, 1], [1343, 1, 1]],
  [[2024, 3, 11], [1445, 9, 1]],
  [[2025, 3, 1], [1446, 9, 1]],
  [[2026, 2, 18], [1447, 9, 1]],
  [[2026, 11, 19], [1448, 6, 9]],
  [[2077, 11, 16], [1500, 12, 30]]
]) {
  const result = hijri.hijriFromGregorian(...gregorian)
  assertDeepEqual([result.year, result.month, result.day], expected, `calendar converts ${gregorian.join('-')} to Umm al-Qura`)
}

let conversionError = ''
for (let epoch = Date.UTC(1924, 7, 1); epoch <= Date.UTC(2077, 10, 16); epoch += 86400000) {
  const date = new Date(epoch)
  const g = [date.getUTCFullYear(), date.getUTCMonth() + 1, date.getUTCDate()]
  const h = hijri.hijriFromGregorian(...g)
  const back = h && hijri.hijriToGregorianDate(h.year, h.month, h.day)
  if (!back || JSON.stringify([back.year, back.month, back.day]) !== JSON.stringify(g)) {
    conversionError = g.join('-')
    break
  }
}
assertEqual(conversionError, '', 'every supported day round-trips through Hijri without local time')
for (const invalid of [[1924, 7, 31], [2077, 11, 17], [2026, 2, 30], [2026, 13, 1], [NaN, 1, 1]])
  assertEqual(hijri.hijriFromGregorian(...invalid), null, `calendar rejects invalid Gregorian date ${invalid}`)
assertEqual(hijri.hijriToGregorianDate(1501, 1, 1), null, 'calendar rejects dates after the table sentinel')
const multi = requireFromRoot('Calendars.js')
const providers = multi.createRegistry(hijri)
const gregorianEntry = {id: 'gregorian', provider: 'gregorian', language: 'en'}
const hijriEntry = {id: 'hijri', provider: 'islamic-umalqura', language: 'ar'}
const one = multi.normalizeSettings({calendars: [gregorianEntry]}, providers).value
const two = multi.normalizeSettings({calendars: [gregorianEntry, hijriEntry], primaryCalendar: 'hijri'}, providers).value
const pairSettings = {calendars: [gregorianEntry, hijriEntry]}
assertEqual(one.calendars.length, 1, 'one selected calendar stays single')
assertDeepEqual(two.calendars.map(entry => entry.id), ['hijri', 'gregorian'], 'the primary calendar is displayed first')
assertDeepEqual(two.calendars.map(entry => entry.language), ['ar', 'en'], 'each calendar keeps its own language')
assertEqual(multi.normalizeSettings({}, providers).value.calendars.length, 1, 'a stock clock remains Gregorian-only')
assertEqual(multi.normalizeSettings({primaryCalendar: 'hijri'}, providers).value.calendars.length, 2, 'the old preview selection is preserved')
for (const [bad, description] of [
  [{calendars: []}, 'an empty selection'],
  [{calendars: [gregorianEntry, hijriEntry, {...gregorianEntry, id: 'third'}]}, 'a third calendar'],
  [{calendars: [gregorianEntry, gregorianEntry]}, 'duplicate instance IDs'],
  [{calendars: [{id: 'time', provider: 'gregorian'}]}, 'the reserved time field'],
  [{calendars: [{id: '../private', provider: 'gregorian'}]}, 'a path-shaped calendar ID'],
  [{calendars: [{...hijriEntry, provider: 'constructor'}]}, 'an unregistered provider'],
  [{calendars: [{...hijriEntry, language: '../../private'}]}, 'an unsafe language'],
  [{calendars: [{...hijriEntry, showWeekNumbers: 'false'}]}, 'a non-boolean visibility option'],
  [{calendars: [{...hijriEntry, format: '{gregorian:d}'}]}, 'nested templates in a per-calendar pattern'],
  [{calendars: [gregorianEntry], primaryCalendar: 'hijri'}, 'an unselected primary calendar']
]) {
  const original = JSON.stringify(bad)
  const result = multi.acceptSettings(two, bad, providers)
  assert(result.error.length > 0 && result.config === two, `calendar rejects ${description} without replacing the valid selection`)
  assertEqual(JSON.stringify(bad), original, `validating ${description} does not mutate user settings`)
}
assertEqual(multi.acceptSettings(null, {calendars: []}, providers).config.calendars[0].provider,
  'gregorian', 'an invalid first configuration falls back to a usable original calendar')
assertDeepEqual(multi.monthGrid(providers, two, 1501, 1, 0, 0), [], 'calendar does not build a grid outside the provider range')

let gridError = ''
for (let year = 1343; year <= 1500 && !gridError; year++) {
  for (let month = 1; month <= 12 && !gridError; month++) {
    for (const start of [0, 1, 6]) {
      const today = providers['islamic-umalqura'].toDay(year, month, 1)
      const grid = multi.monthGrid(providers, two, year, month, start, today)
      const cells = grid.flatMap(week => week.days)
      const active = cells.filter(day => day.inMonth)
      if (grid.length !== 6 || cells.length !== 42 || cells.filter(day => day.today).length !== 1 ||
          active.length !== hijri.hijriDaysInMonth(year, month) ||
          !grid.every(week => week.weekNumbers.length === 2) ||
          !active.every((day, index) => day.dates[0].date.day === index + 1) ||
          !cells.every((day, index) => {
            if (day.weekday !== (start + index) % 7) return false
            const g = day.dates[1].date
            const h = day.dates[0].date
            return day.dayNumber === providers.gregorian.toDay(g.year, g.month, g.day) &&
              (!h || day.dayNumber === providers['islamic-umalqura'].toDay(h.year, h.month, h.day))
          })) gridError = `${year}-${month}, week start ${start}`
    }
  }
}
assertEqual(gridError, '', 'all Hijri grids align both calendars, including padding and table boundaries')
const day19 = providers.gregorian.toDay(2026, 11, 19)
const gregorianPair = multi.normalizeSettings(pairSettings, providers).value
const dualNovember = multi.monthGrid(providers, gregorianPair, 2026, 11, 0, day19)
const dualToday = dualNovember.flatMap(week => week.days).find(day => day.today)
assertDeepEqual(dualToday.dates.map(entry => entry.date.day), [19, 9], 'Gregorian-primary grid pairs November 19 with Jumada 9')
assertDeepEqual(dualNovember[2].weekNumbers.map(entry => entry.number), [47, 23], 'both calendar week columns describe the same physical row')
for (const [year, month, start] of [[2026, 7, 1], [2021, 1, 0], [2026, 9, 0], [2011, 12, 1]]) {
  const original = calendar.monthGrid(year, month - 1, start, '')
  const single = multi.monthGrid(providers, one, year, month, start, 0)
  assertDeepEqual(single.map(week => week.weekNumbers[0].number), original.map(week => week.week),
    `single-calendar week numbers match the original in ${year}-${month}`)
  assertDeepEqual(single.flatMap(week => week.days).map(day => day.dates[0].date.day),
    original.flatMap(week => week.days).map(day => day.day), `single-calendar dates match the original in ${year}-${month}`)
  assert(single.every(week => week.days.every(day => day.dates.length === 1)),
    `a single-calendar grid has no hidden second date in ${year}-${month}`)
}
const hidden = multi.normalizeSettings({calendars: [gregorianEntry, {...hijriEntry, showWeekNumbers: false, showYearProgress: false}]}, providers).value
assertEqual(multi.monthGrid(providers, hidden, 2026, 11, 0, day19)[0].weekNumbers.length, 1,
  'a hidden week column does not take a second slot')
const outside = multi.monthGrid(providers, gregorianPair, 2200, 1, 0, 0)
assert(outside.length === 6 && outside.every(week => week.days.every(day => day.dates[1].date === null)),
  'an out-of-range secondary calendar does not break the primary grid')
const january1 = providers.gregorian.toDay(2026, 1, 1)
const gregorianProgress = multi.progress(providers, gregorianPair.calendars[0], january1)
const hijriProgress = multi.progress(providers, gregorianPair.calendars[1], january1)
assertEqual(gregorianProgress.value, 0, 'Gregorian year progress starts on its own New Year')
assert(hijriProgress.value > 0 && hijriProgress.value < 1 && hijriProgress.year !== gregorianProgress.year,
  'the second year bar uses its own calendar year and bounds')
assertEqual(multi.progress(providers, two.calendars[0], providers['islamic-umalqura'].toDay(1448, 1, 1)).value,
  0, 'Hijri year progress starts on Muharram 1')
assertEqual(multi.progress(providers, two.calendars[0], providers.gregorian.toDay(2200, 1, 1)).value,
  null, 'out-of-range progress is unavailable, not a fabricated zero percent')
assertDeepEqual(multi.progress(providers, undefined, day19), {id: '', year: null, value: null},
  'a retiring calendar has an unavailable progress readout instead of a null object')
assertDeepEqual(hijri.stepHijriMonth(1343, 1, -1), {year: 1343, month: 1}, 'Hijri navigation stops at the first month')
assertDeepEqual(hijri.stepHijriMonth(1500, 12, 1), {year: 1500, month: 12}, 'Hijri navigation stops at the last month')
assertDeepEqual(providers.gregorian.stepMonth(1, 1, 1), {year: 1, month: 2}, 'calendar navigation does not turn year 1 into 1901')
assertDeepEqual(multi.stepYear({monthsInYear: year => year === 2027 ? 13 : 12}, 2026, 12, 1),
  {year: 2027, month: 12}, 'year navigation asks the provider for its month count')
assertDeepEqual(multi.stepYear({monthsInYear: () => 12}, 2027, 13, -1),
  {year: 2026, month: 12}, 'year navigation clamps a leap month when the target year has fewer months')

const fs = require('fs')
const readCatalog = code => JSON.parse(fs.readFileSync(path.join(root, `i18n/${code}.json`), 'utf8'))
const en = readCatalog('en')
const ar = readCatalog('ar')
assertDeepEqual(Object.keys(en).sort(), Object.keys(ar).sort(), 'calendar translates the same controls into Arabic and English')
assert(Object.keys(en).every(key => JSON.stringify((en[key].match(/%\d/g) || []).sort()) ===
  JSON.stringify((ar[key].match(/%\d/g) || []).sort())), 'calendar translations preserve placeholders')
const november19 = new Date(2026, 10, 19, 13, 5, 9)
const labels = catalog => ({
  number: String,
  weekday: (day, short) => catalog['weekday.' + (short ? 'short.' : '') + day],
  month: parts => catalog['month.' + parts.month],
  period: hour => catalog[hour < 12 ? 'time.am' : 'time.pm']
})
const formatHijri = (pattern, catalog = en) => multi.formatDate(providers, two.calendars[0], day19, november19, pattern, labels(catalog))
assertEqual(formatHijri('dddd d MMMM yyyy'), 'Thursday 9 Jumada al-Akhirah 1448', 'calendar formats English Hijri names')
assertEqual(formatHijri('dddd d MMMM yyyy', ar), 'الخميس 9 جمادى الآخرة 1448', 'calendar formats Arabic Hijri names')
assertEqual(formatHijri('d'), '9', 'calendar supports a day-only bar')
assertEqual(formatHijri('dd/MM/yyyy HH:mm:ss'), '09/06/1448 13:05:09', 'calendar combines Hijri dates with 24-hour time')
assertEqual(formatHijri('d MMMM h:mm AP'), '9 Jumada al-Akhirah 1:05 PM', 'calendar combines Hijri names with 12-hour time')
assertEqual(formatHijri('HH\nmm\nss'), '13\n05\n09', 'calendar supports vertical 24-hour time with seconds')
assertEqual(formatHijri('h\nmm\nAP'), '1\n05\nPM', 'calendar supports vertical 12-hour time')
assertEqual(formatHijri('h:mm'), '13:05', 'calendar uses 24-hour h without an AM/PM field, matching Qt')
assertEqual(formatHijri("hh:mm 'AP'"), '13:05 AP', 'a quoted AM/PM field does not enable 12-hour time')
assertEqual(formatHijri("HH:mm 'since"), '13:05 since', 'calendar preserves unterminated literal formats')
assertEqual(formatHijri("''s"), "'9", 'calendar preserves escaped apostrophes before seconds')
const sunday = providers.gregorian.toDay(2026, 11, 22)
assertEqual(multi.formatDate(providers, one.calendars[0], sunday, november19, 'ww', labels(en)), '47',
  'the bar ISO week describes its own date, not the next Thursday')
const markup = {...en, 'month.6': '<img src="https://example.invalid/tracker">'}
assertEqual(formatHijri('MMMM', markup), markup['month.6'], 'markup-shaped names stay data for PlainText labels')
assertEqual(multi.formatDate(providers, two.calendars[0], providers.gregorian.toDay(2200, 1, 1), november19,
  'HH:mm', labels(en)), '13:05', 'time works even when a calendar date is outside its range')
const language = requireFromRoot('Language.js')
const languages = language.parseRegistry(fs.readFileSync(path.join(root, 'i18n/languages.json'), 'utf8'))
assertEqual(language.preference('../../private', languages), 'system', 'calendar rejects unsafe language paths')
assertEqual(language.lookup('calendar.today', {}, {}, en), 'Back to today', 'calendar falls back to English')
const calendarField = (kind, pattern) => kind === 'hijri'
  ? formatHijri(pattern) : '19/11/2026'
assertEqual(calendar.formatCalendarTemplate('{hijri:dd/MM/yyyy}\n{gregorian:dd/MM/yyyy}', calendarField),
  '09/06/1448\n19/11/2026', 'clock stacks both calendars using format fields')
assertEqual(calendar.formatCalendarTemplate('{hijri:dd\nMM\nyyyy}\n—\n{gregorian:dd/MM/yyyy}', calendarField),
  '09\n06\n1448\n—\n19/11/2026', 'vertical clock supports multiline patterns in both calendar fields')
assertEqual(calendar.formatCalendarTemplate('HH:mm', calendarField), null, 'ordinary clock formats keep their original path')
assertEqual(calendar.formatCalendarTemplate('{unknown:d}', () => '—'), '—', 'an unknown calendar field can be reported without loading code')
assertEqual(calendar.formatCalendarTemplate('{hijri}', (id, pattern) => id + ':' + pattern), 'hijri:',
  'a shorthand field uses its independently configured calendar format')
assert(!calendar.clockNeedsSeconds('{persian:dd/MM/yyyy}'), 'a calendar identifier containing s does not enable second ticks')
assert(calendar.clockNeedsSeconds('{gregorian:dd/MM/yyyy}\n{time:HH:mm:ss}'), 'explicit time seconds enable second ticks')
assert(calendar.clockNeedsSeconds('{custom}', () => 'HH:mm:ss'), 'shorthand calendar formats can request second ticks')
assert(!calendar.clockNeedsSeconds('{time:HH:mm}\nseconds'), 'literal text outside fields does not enable second ticks')
JS

# Compare the calendar formatter with the real Qt formatter, not a JS imitation.
qml_test_runner=""
for candidate in /usr/lib/qt6/bin/qmltestrunner /usr/lib/qt6/qmltestrunner; do
  if [[ -x $candidate ]]; then
    qml_test_runner=$candidate
    break
  fi
done

if [[ -n $qml_test_runner ]]; then
  output=$(QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software "$qml_test_runner" \
    -input "$SHELL_TEST_DIR/clock/qml" -o -,txt 2>&1) ||
    fail "calendar formats remain compatible with Qt" "$output"
  pass "calendar formats remain compatible with Qt"
else
  skip "qt6 qmltestrunner not found; skipping clock format compatibility"
fi
