# Multi Calendar settings

The widget ID is `thabetfy.multi-calendar`. Edit its entry in `~/.config/omarchy/shell.json`; changes apply without restarting the shell.

## One or two calendars, never more

- **One selected calendar:** the original compact calendar layout, with one date per cell, one optional week-number column, and one optional year-progress bar.
- **Two selected calendars:** one combined month grid, with two dates per cell, independently labeled week-number columns, and independently labeled year-progress bars.
- **Invalid configuration, including three calendars:** reject the complete selection. Keep the previous valid selection in the running widget and display a small warning. If there has been no valid selection since startup, fall back to the original Gregorian-only calendar.

The primary calendar controls the displayed month and navigation. Both calendars share the same real days, device timezone, weekday header, and week start. The primary date is the larger number in each cell; secondary dates and years use the secondary calendar's own language and digit preferences. The popup stays the original width and has no settings page or settings rows.

## Configuration

Settings are inline on the widget entry in `~/.config/omarchy/shell.json`. Example:

```json
{
  "id": "thabetfy.multi-calendar",
  "language": "system",
  "primaryCalendar": "hijri",
  "weekStartDay": "sunday",
  "calendars": [
    {
      "id": "hijri",
      "provider": "islamic-umalqura",
      "language": "ar",
      "digits": "latin",
      "format": "d MMMM yyyy",
      "verticalFormat": "dd\nMM\nyyyy",
      "showWeekNumbers": true,
      "showYearProgress": true
    },
    {
      "id": "gregorian",
      "provider": "gregorian",
      "language": "en",
      "format": "d MMMM yyyy",
      "showWeekNumbers": true,
      "showYearProgress": true
    }
  ],
  "format": "{hijri} · {gregorian}",
  "formatAlt": "{hijri:dd/MM/yyyy}\n{gregorian:dd/MM/yyyy}",
  "verticalFormat": "{hijri}\n—\n{gregorian}\n{time:HH\nmm}"
}
```

To select only one calendar, provide exactly one entry in `calendars` and set `primaryCalendar` to its ID, or omit `primaryCalendar`. Do not retain the ID of a calendar you removed. Omitting `calendars` and `primaryCalendar` preserves the original Gregorian-only default.

| Setting | Meaning |
| --- | --- |
| `calendars` | An array of **one or two** calendar entries. |
| `calendars[].id` | A unique local name used in format fields and `primaryCalendar`; lowercase letters, digits, `_` and `-`, starting with a letter, up to 40 characters. `time` is reserved. |
| `calendars[].provider` | A registered calendar algorithm. Initially `gregorian` or `islamic-umalqura`. |
| `calendars[].language` | `system`, `ar`, or `en`; defaults to the widget's `language`. Controls this calendar's names and numbers, not the shared grid's reading direction. |
| `calendars[].digits` | `locale` (default) or `latin`. |
| `calendars[].format` | This calendar's horizontal format, used by `{id}`; default `d MMMM yyyy`. |
| `calendars[].verticalFormat` | This calendar's vertical format, used by `{id}` on vertical bars; default `dd\nMM\nyyyy`. |
| `calendars[].showWeekNumbers` | Boolean, default `true`. Hiding it removes that column completely. |
| `calendars[].showYearProgress` | Boolean, default `true`. |
| `calendars[].weekRule` | `iso` or `calendar`. Defaults to ISO for Gregorian and calendar-relative for Umm al-Qura. |
| `primaryCalendar` | The selected entry ID that controls the month and main date; defaults to the first selected entry. |
| `language` | Shared UI language and direction: `system` (default), `ar`, or `en`. |
| `weekStartDay` | Shared week start, using the original clock setting; defaults to the UI locale. |
| `format` | Horizontal bar pattern. |
| `formatAlt` | Extra horizontal pattern included in the right-click cycle. |
| `verticalFormat` | Sidebar pattern; use `\n` to stack lines. |
| `verticalFormatAlt` | Extra sidebar pattern included in the right-click cycle. |

The original `format`, `formatAlt`, `verticalFormat`, `verticalFormatAlt`, `birthYear`, and `lifeExpectancy` settings remain available. If a top-level format is specified, it takes precedence over the generated label. Without one, an explicit single selection uses that entry's format; a double selection combines both entries. The list is displayed primary-first without changing the user's JSON array.

<a id="format-reference"></a>

### Format reference · مرجع التنسيقات

يمكن دمج الرموز بأي ترتيب؛ هذه قائمة بكل الرموز المدعومة، وليست حصرًا لكل التركيبات الممكنة. تختلف أسماء الأيام والشهور والأرقام حسب إعدادات اللغة والأرقام لكل تقويم.

Combine the tokens in any order. These tables list every supported token, not every possible combination. Names and digits follow each calendar's settings. Tokens are case-sensitive: `MM` is the month; `mm` is minutes.

Examples below use **Thursday 19 November 2026 / 9 Jumada al-Akhirah 1448, at 13:05:09.120**, with English names and Latin digits.

#### Calendar and time fields · حقول التقويم والوقت

| Field / pattern · الحقل أو النمط | Meaning · المعنى |
| --- | --- |
| `d MMMM yyyy` | A plain pattern uses the primary calendar · النمط دون أقواس يستخدم التقويم الأساسي. |
| `{hijri}` | Use the selected entry's `format`, or its `verticalFormat` on a sidebar · تنسيق التقويم المحدد حسب اتجاه الشريط. |
| `{gregorian}` | Same rule for the entry named `gregorian` · القاعدة نفسها للتقويم المسمى `gregorian`. |
| `{hijri:d MMMM}` | Override the pattern for this field only · تخصيص نمط هذا الحقل فقط. |
| `{gregorian:dd/MM/yyyy}` | Format the Gregorian entry independently · تنسيق الميلادي بشكل مستقل. |
| `{time}` | Local time: `HH:mm` horizontally, `HH\nmm` vertically · الوقت المحلي حسب اتجاه الشريط. |
| `{time:h:mm AP}` | Local time with an explicit time pattern · وقت محلي بنمط مخصص. |

`hijri` and `gregorian` are entry IDs, not provider names; replace them if you renamed your entries. An unselected calendar field displays `—` without loading anything. `{time:…}` uses the primary calendar's locale but does not depend on its conversion range.

When a format contains fields, **everything outside the fields is literal text**. Write `{time:HH:mm} · {hijri:dd/MM}`, not `HH:mm · {hijri:dd/MM}`. Per-calendar `format` and `verticalFormat` accept plain patterns only, not `{…}` fields.

#### Date tokens · رموز التاريخ

| Token · الرمز | Meaning · المعنى | Gregorian · الميلادي | Hijri · الهجري |
| --- | --- | --- | --- |
| `d` | Day · اليوم | `19` | `9` |
| `dd` | Two-digit day · اليوم بخانتين | `19` | `09` |
| `ddd` | Short weekday · اسم اليوم المختصر | `Thu` | `Thu` |
| `dddd` | Full weekday · اسم اليوم كاملًا | `Thursday` | `Thursday` |
| `M` | Month number · رقم الشهر | `11` | `6` |
| `MM` | Two-digit month · الشهر بخانتين | `11` | `06` |
| `MMM` | Short month name · اسم الشهر المختصر | `Nov` | `Jumada al-Akhirah` |
| `MMMM` | Full month name · اسم الشهر كاملًا | `November` | `Jumada al-Akhirah` |
| `yy` | Two-digit year · السنة بخانتين | `26` | `48` |
| `yyyy` | Four-digit year · السنة بأربع خانات | `2026` | `1448` |
| `ww` | Two-digit week number, using this entry's `weekRule` · رقم الأسبوع حسب قاعدة التقويم | `47` (ISO) | `23` (calendar-relative) |

Hijri `MMM` and `MMMM` currently use the same bundled month name. `ww` is a plugin extension for calendar patterns, not a time token; use `{gregorian:ww}` or `{hijri:ww}`, not `{time:ww}`.

#### Time tokens · رموز الوقت

Use these in plain patterns, calendar fields or `{time:…}`. Time always uses the device's local timezone.

| Token · الرمز | Meaning · المعنى | Example · مثال |
| --- | --- | --- |
| `H` | 24-hour hour · الساعة بنظام 24 | `13` |
| `HH` | Two-digit 24-hour hour · الساعة بخانتين بنظام 24 | `13` |
| `h` | Hour; 12-hour only with an AM/PM token · الساعة؛ نظام 12 عند وجود رمز الفترة | `13`, or `1` in `h AP` |
| `hh` | Two-digit version of `h` · الساعة بخانتين | `13`, or `01` in `hh AP` |
| `m` | Minutes · الدقائق | `5` |
| `mm` | Two-digit minutes · الدقائق بخانتين | `05` |
| `s` | Seconds · الثواني | `9` |
| `ss` | Two-digit seconds · الثواني بخانتين | `09` |
| `z`, `zz` | Fractional seconds, trailing zeroes omitted · جزء الثانية دون أصفار النهاية | `12` for `.120` |
| `zzz` | Fractional seconds, always three digits · جزء الثانية بثلاث خانات | `120` for `.120` |
| `AP`, `A` | Uppercase AM/PM · فترة اليوم بأحرف كبيرة | `PM` |
| `ap`, `a` | Lowercase AM/PM · فترة اليوم بأحرف صغيرة | `pm` |
| `Ap`, `aP` | AM/PM in the locale's original case · فترة اليوم كما تحددها اللغة | `PM` in English |
| `t` | Local timezone abbreviation · اختصار المنطقة الزمنية | e.g. `UTC` |
| `tt` | UTC offset without a colon · فرق التوقيت دون نقطتين | e.g. `+0300` |
| `ttt` | UTC offset with a colon · فرق التوقيت مع نقطتين | e.g. `+03:00` |
| `tttt` | Long timezone name · اسم المنطقة الزمنية كاملًا | Depends on the system and locale |

`h:mm` alone displays `13:05`; `h:mm AP` displays `1:05 PM`. `HH:mm AP` stays `13:05 PM`. AM/PM text is localized (for example, `ص` / `م` in Arabic), and timezone names depend on Qt and the system.

The clock ticks once a second only when an active pattern requests `s` or `ss`; otherwise it ticks once a minute. Millisecond tokens format the sampled time, not a continuously updating millisecond clock.

#### Text and line breaks · النص والأسطر

| Syntax · الصيغة | Meaning · المعنى | Example pattern → output · مثال |
| --- | --- | --- |
| `'text'` | Literal text inside a plain pattern or field · نص حرفي داخل النمط | `'Time' HH:mm` → `Time 13:05` |
| `''` | One apostrophe · علامة اقتباس مفردة | `hh 'o''clock' AP` → `01 o'clock PM` |
| `\n` in JSON | Start a new line · سطر جديد | `{time:HH\nmm}` → `13`<br>`05` |
| Spaces, `/`, `-`, `:`, `·`, `—` | Separators · فواصل | `dd/MM/yyyy` → `19/11/2026` for Gregorian |

For narrow sidebars, put day, month and year on separate lines instead of squeezing a full date onto one line.

#### All built-in right-click presets · جميع التنسيقات الجاهزة بالنقر الأيمن

Plain patterns use the primary calendar. This table shows a Gregorian primary; select Hijri as primary to use its date names, numbers and week rule instead.

| Horizontal pattern · النمط الأفقي | Example · مثال |
| --- | --- |
| `dddd HH:mm` | `Thursday 13:05` |
| `dddd h:mm AP` | `Thursday 1:05 PM` |
| `dddd HH:mm:ss` | `Thursday 13:05:09` |
| `dddd h:mm:ss AP` | `Thursday 1:05:09 PM` |
| `HH:mm` | `13:05` |
| `h:mm AP` | `1:05 PM` |
| `ddd d MMM HH:mm` | `Thu 19 Nov 13:05` |
| `ddd d MMM h:mm AP` | `Thu 19 Nov 1:05 PM` |
| `d MMMM 'W'ww yyyy` | `19 November W47 2026` |
| `yyyy-MM-dd HH:mm` | `2026-11-19 13:05` |
| `d` | `19` |
| `d MMMM` | `19 November` |
| `d MMMM yyyy` | `19 November 2026` |
| `dddd d MMMM yyyy` | `Thursday 19 November 2026` |
| `d MMMM HH:mm` | `19 November 13:05` |
| `d MMMM h:mm AP` | `19 November 1:05 PM` |

| Sidebar pattern · نمط الشريط الجانبي | Example, one line per part · مثال |
| --- | --- |
| `HH\n—\nmm` | `13`<br>`—`<br>`05` |
| `h\n—\nmm\nAP` | `1`<br>`—`<br>`05`<br>`PM` |
| `dd\nMMM\n'W'ww\n''yy` | `19`<br>`Nov`<br>`W47`<br>`'26` |
| `HH\nmm` | `13`<br>`05` |

With two selected calendars, these extra presets are generated using the actual IDs in primary-first order. For a Hijri primary with IDs `hijri` and `gregorian`:

| Bar · الشريط | Generated pattern · النمط المضاف |
| --- | --- |
| Horizontal · أفقي | `{hijri:d MMMM} · {gregorian:d MMMM}` |
| Horizontal, two lines · أفقي بسطرين | `{hijri:dd/MM/yyyy}\n{gregorian:dd/MM/yyyy}` |
| Sidebar · جانبي | `{hijri:dd\nMM\nyyyy}\n—\n{gregorian:dd\nMM\nyyyy}` |

The cycle also includes your current and alternate patterns, without duplicates. Right-clicking saves the chosen pattern to `format` or `verticalFormat`.

To separate time and dates into different bar positions, use separately named plugin copies with their own IDs. Do not repeat the same widget ID for independently writable entries: Omarchy's settings API updates every matching ID.

### Week-number conventions and ranges

Gregorian ISO weeks use the Thursday in each displayed row, preserving the original clock's convention even when a week starts on Sunday. Calendar-relative weeks are seven-day blocks from that calendar's New Year, read at the row's fourth day; they are **not ISO weeks**. Hover a column heading to see its calendar and rule. Each year-progress bar measures whole elapsed days in its own current calendar year, independent of the browsed month.

Umm al-Qura supports 1343–1500 AH (1924-08-01 through 2077-11-16). Outside its range, its dates and progress read `—` rather than inventing dates or percentages. Gregorian dates remain usable; Umm al-Qura-primary navigation stops at its range boundaries. Religious observance may differ according to local moon sighting. See `NOTICE` for attribution.

The bundled month-start table matches the credited `hijridate` source. Other implementations, including ICU, can return different historical and future dates; this widget does not promise ICU-equivalent results.

## Controls

Left-click opens the popup; right-click cycles the bar format; middle-click opens the original timezone picker. Arrows and the wheel browse months, Up/Down browse years, Enter or `T` returns to today, `W` toggles Sunday/Monday week starts, and Escape closes. The original optional life-progress controls are preserved. Calendar choices and display preferences are configured in JSON, not in the popup.

## Adding a provider

### Selecting a calendar that is already supported

Edit the widget's `calendars` list in `~/.config/omarchy/shell.json`. Currently the registered providers are `gregorian` and `islamic-umalqura`. Choose one or two; the entry `id` is your local format alias, not a new calendar algorithm. Update `primaryCalendar` and any format fields when removing or renaming an entry.

### Implementing a new calendar type

A new type, such as Persian or Hebrew, currently requires developer work. Adding `"provider": "persian"` to JSON alone will be rejected; there is no provider download or installation API.

Work in a checkout of this repository, not `/usr/share/omarchy/`. The installed plugin is in `~/.config/omarchy/plugins/thabetfy.multi-calendar/`; back up local edits before updating it.

1. Bundle a reviewed, offline conversion implementation in the plugin directory. Preserve its license and attribution. Convert through the same integer Julian day numbers as the existing providers, not local-midnight timestamps.
2. Register it under a unique provider key in `Calendars.js`'s `createRegistry()`. If its math is in a separate JS file, import it in `CalendarContext.qml`, pass it into `createRegistry()`, and update the registry construction in the Node and Qt tests as well. Use the existing providers as templates.
3. Supply the provider methods and labels below. Add its calendar names, short names and month names to both `i18n/en.json` and `i18n/ar.json`.
4. Extend `tests/calendar-test.sh` with independently known dates, conversion round-trips, leap-month/year cases, range boundaries, navigation, and both primary/secondary grid positions. Run `bash tools/check.sh` on Omarchy.
5. Only after registration and testing, select the new provider in `shell.json`. Keep at most two selected calendars and use the entry's `id` in bar format fields.

Each provider supplies:

| Member | Contract |
| --- | --- |
| `fromDay(julianDay)` | Return `{ year, month, day }`, using one-based month/day values, or `null` outside the supported range. |
| `toDay(year, month, day)` | Return an integer Julian day number, or `null` for an invalid or unsupported date. |
| `monthsInYear(year)` | Return the calendar's actual month count, or `0` for an unsupported year. Do not assume every year has twelve months. |
| `stepMonth(year, month, delta)` | Return `{ year, month }` after stepping; stay at the current month if the target is outside the supported range. |
| `yearBounds(year)` | Return `{ start, end }` Julian days with an inclusive start and exclusive end, or `null` for an unsupported year. |
| `nameKey`, `shortNameKey` | Translation keys for the calendar's full and short names. |
| `defaultWeekRule` | `"calendar"` for seven-day blocks from this calendar's New Year, or `"iso"` for Gregorian ISO weeks. |
| `monthNameKey(month)` | For non-Gregorian month names, return a translation key for the month. |

For example, **after a Persian provider has been implemented and registered**, the widget entry could contain:

```json
{
  "id": "thabetfy.multi-calendar",
  "primaryCalendar": "persian",
  "calendars": [
    { "id": "persian", "provider": "persian", "language": "en" },
    { "id": "gregorian", "provider": "gregorian", "language": "en" }
  ],
  "format": "{persian:dd MMMM} · {time:HH:mm} · {gregorian:dd MMMM}"
}
```

The grid and formatter consume this interface instead of checking calendar names. Year navigation asks the provider for its month count; a future provider may have leap months. More provider types may be registered, but the visible selection is always capped at two. No remote code, automatic provider downloads, extra dependencies, services, telemetry, or location access are involved.

## Compatibility and checks

Older local previews that used `primaryCalendar: "hijri"` or `"gregorian"` without a `calendars` list keep their two-calendar selection. Explicit lists use the validation rules above. This plugin does not overwrite `omarchy.clock` or an older `thabetfy.hijri-calendar` plugin.

Inspect the accepted selection without opening the popup:

```sh
omarchy-shell thabetfy.multi-calendar status
```

```sh
bash tests/calendar-test.sh
node --test tests/*.test.cjs
```

The calendar test also compares formatting against Qt using Qt 6 `qmltestrunner` when it is installed, running offscreen without opening desktop windows. The full local check is `bash tools/check.sh`.
