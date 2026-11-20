// Pure validation and catalog lookup for local calendar translations.
function parseCatalog(raw) {
    try {
        if (typeof raw !== "string" || raw.length > 65536) return {};
        var data = JSON.parse(raw);
        return data && typeof data === "object" && !Array.isArray(data) ? data : {};
    } catch (e) { return {}; }
}

function parseRegistry(raw) {
    try {
        if (typeof raw !== "string" || raw.length > 32768) return [];
        var data = JSON.parse(raw);
        if (!Array.isArray(data) || data.length > 100) return [];
        var result = [];
        for (var i = 0; i < data.length; i++) {
            var entry = data[i];
            if (!entry || typeof entry.code !== "string" || entry.code.length > 35 ||
                !/^[a-z]{2,3}(?:-[A-Za-z0-9]{2,8})*$/.test(entry.code) ||
                typeof entry.name !== "string" || !entry.name.trim() || entry.name.length > 120 ||
                typeof entry.rtl !== "boolean" ||
                result.some(function(existing) { return existing.code === entry.code; })) continue;
            result.push({ code: entry.code, name: entry.name, rtl: entry.rtl });
        }
        return result;
    } catch (e) { return []; }
}

function preference(value, languages) {
    return languages.some(function(entry) { return entry.code === value; }) ? value : "system";
}

function lookup(key, selected, base, english) {
    var layers = [selected, base, english];
    for (var i = 0; i < layers.length; i++) {
        var value = layers[i] && Object.prototype.hasOwnProperty.call(layers[i], key) ? layers[i][key] : null;
        if (typeof value === "string" && value.length) return value;
    }
    return key;
}

if (typeof module !== "undefined")
    module.exports = { parseCatalog: parseCatalog, parseRegistry: parseRegistry, preference: preference, lookup: lookup };
