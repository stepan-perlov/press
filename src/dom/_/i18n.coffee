config = require("../config.coffee")

# Translation - the ContentEdit library provides basic translation support
# which is used both by the library itself and the associated ContentTools
# library.
_translations: {}

i18n = (s) ->
    # Look for a translation of the given string and return it, or if no
    # translation is found return the string unchanged.
    lang = config.LANGUAGE
    if _translations[lang] and
            _translations[lang][s]

        return _translations[lang][s]
    return s

i18n.addLanguage = (language, translations) ->
    # Add translations where `language` is a 2 digit ISO_639-1 code and
    # `translations` is an object containing a map of English strings and
    # their translated counterparts e.g {'Hello': 'Bonjour'}.
    _translations[language] = translations

module.exports = i18n
