import QtQuick
import Quickshell.Io
import qs.Commons as Commons
import "Language.js" as Language

// One set of local catalogs serves both the shell language and explicit
// per-calendar overrides, with the same base-language and English fallbacks.
QtObject {
    id: root
    property string requestedLanguage: "system"
    readonly property var languages: Language.parseRegistry(registryFile.text())
    readonly property string preference: Language.preference(requestedLanguage, languages)
    readonly property bool followsSystem: preference === "system"
    readonly property string language: followsSystem ? Commons.I18n.language : preference
    readonly property string baseLanguage: language.split("-")[0]
    readonly property string formatLocale: followsSystem ? Commons.I18n.formatLocale : language.replace(/-/g, "_")
    readonly property bool rightToLeft: {
        if (root.followsSystem) return Commons.I18n.rightToLeft;
        for (let i = 0; i < languages.length; i++)
            if (languages[i].code === language) return languages[i].rtl;
        return false;
    }
    readonly property var selectedCatalog: Language.parseCatalog(selectedFile.text())
    readonly property var baseCatalog: Language.parseCatalog(baseFile.text())
    readonly property var englishCatalog: Language.parseCatalog(englishFile.text())

    function t(key) {
        return Language.lookup(key, selectedCatalog, baseCatalog, englishCatalog);
    }
    function formatNumber(value) {
        var locale = Qt.locale(formatLocale);
        locale.numberOptions = Locale.OmitGroupSeparator;
        return Number(value).toLocaleString(locale, "f", 0);
    }

    property FileView registryFile: FileView {
        path: Qt.resolvedUrl("i18n/languages.json")
        blockLoading: true
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
    }
    property FileView englishFile: FileView {
        path: Qt.resolvedUrl("i18n/en.json")
        blockLoading: true
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
    }
    property FileView selectedFile: FileView {
        path: root.language !== "en" ? Qt.resolvedUrl("i18n/" + root.language + ".json") : ""
        blockLoading: true
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
    }
    property FileView baseFile: FileView {
        path: root.baseLanguage !== root.language && root.baseLanguage !== "en"
            ? Qt.resolvedUrl("i18n/" + root.baseLanguage + ".json") : ""
        blockLoading: true
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
    }
}
