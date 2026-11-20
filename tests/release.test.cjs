const assert = require("node:assert/strict")
const fs = require("node:fs")
const path = require("node:path")
const test = require("node:test")
const root = path.join(__dirname, "..")
const read = name => fs.readFileSync(path.join(root, name), "utf8")

test("the standalone manifest points to a local bar widget", () => {
  const manifest = JSON.parse(read("manifest.json"))
  assert.equal(manifest.schemaVersion, 1)
  assert.equal(manifest.id, "thabetfy.multi-calendar")
  assert.match(manifest.version, /^\d+\.\d+\.\d+$/)
  assert.deepEqual(manifest.kinds, ["bar-widget"])
  assert.equal(manifest.barWidget.allowMultiple, false)
  for (const entry of Object.values(manifest.entryPoints)) {
    assert.equal(path.isAbsolute(entry), false)
    assert.equal(entry.split(/[\\/]/).includes(".."), false)
    assert.ok(fs.statSync(path.join(root, entry)).isFile())
  }
  assert.match(read(manifest.entryPoints.barWidget), /moduleName: "thabetfy\.multi-calendar"/)
})

test("catalogs agree on keys and placeholders", () => {
  const english = JSON.parse(read("i18n/en.json"))
  const languages = JSON.parse(read("i18n/languages.json"))
  for (const language of languages) {
    assert.match(language.code, /^[a-z]{2,3}(?:-[A-Za-z0-9]{2,8})*$/)
    const catalog = JSON.parse(read(`i18n/${language.code}.json`))
    assert.deepEqual(Object.keys(catalog).sort(), Object.keys(english).sort())
    for (const key of Object.keys(english)) {
      assert.equal(typeof catalog[key], "string", `${language.code}: ${key}`)
      assert.deepEqual((catalog[key].match(/%\d+/g) || []).sort(),
        (english[key].match(/%\d+/g) || []).sort(), `${language.code}: ${key}`)
    }
  }
})

test("release files retain credits and are not symlinks", () => {
  assert.match(read("LICENSE"), /Copyright \(c\) David Heinemeier Hansson/)
  assert.match(read("LICENSE"), /Copyright \(c\) Mohammed Alshehri/)
  assert.match(read("NOTICE"), /https:\/\/github.com\/dralshehri\/hijridate/)
  function inspect(directory) {
    for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
      if (entry.name === ".git") continue
      assert.equal(entry.isSymbolicLink(), false, entry.name)
      if (entry.isDirectory()) inspect(path.join(directory, entry.name))
    }
  }
  inspect(root)
})

test("dynamic text uses PlainText", () => {
  for (const file of ["BarWidget.qml", "Panel.qml", "YearProgress.qml"]) {
    for (const block of read(file).split(/\bText\s*\{/).slice(1))
      assert.match(block.split("}")[0], /textFormat:\s*Text\.PlainText/, file)
  }
})
