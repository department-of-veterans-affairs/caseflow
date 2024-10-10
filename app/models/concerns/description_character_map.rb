# frozen_string_literal: true

module DescriptionCharacterMap
  # Invalid character pattern for contested / nonrating issue descriptions
  DESCRIPTION_CHARACTERS_BLACKLIST = /[^a-zA-Z0-9\s.\-_|\/\\@#~=%,;?!'"`():$+*^\[\]&><{}]/.freeze

  # Look up table for contested / nonrating issue description symbol replacement
  DESCRIPTION_CHARACTER_MAP = [
    { invalid: "\u00A7", valid: "S" },
    { invalid: "\u2014", valid: "-" },
    { invalid: "\u2013", valid: "-" },
    { invalid: "\u00F6", valid: "o" },
    { invalid: "\u00D4", valid: "O" },
    { invalid: "\u00C2", valid: "A" },
    { invalid: "\u00E2", valid: "a" },
    { invalid: "\u0080", valid: "E" },
    { invalid: "\u2122", valid: "TM" },
    { invalid: "\u2026", valid: "..." },
    { invalid: "\u2022", valid: "*" },
    { invalid: "\u00E9", valid: "e" },
    { invalid: "\u00E8", valid: "e" },
    { invalid: "\uFFFD", valid: "?" },
    { invalid: "\u00BD", valid: "1/2" },
    { invalid: "\u00C3", valid: "A" },
    { invalid: "\u00A9", valid: "(c)" },
    { invalid: "\u00B0", valid: "*" },
    { invalid: "\u009C", valid: "oe" },
    { invalid: "\u009D", valid: " " },
    { invalid: "\u0093", valid: "\"" },
    { invalid: "\u0098", valid: "~" },
    { invalid: "\u00F3", valid: "o" },
    { invalid: "\u00B7", valid: "*" },
    { invalid: "\u0095", valid: "*" },
    { invalid: "\u0097", valid: "-" },
    { invalid: "\u00BF", valid: "?" },
    { invalid: "\uF020", valid: "" },
    { invalid: "\u00A3", valid: "L" },
    { invalid: "\uF0D8", valid: "" },
    { invalid: "\u00A5", valid: "Y" },
    { invalid: "\u203A", valid: ">" },
    { invalid: "\uF0B7", valid: "" },
    { invalid: "\u2010", valid: "-" },
    { invalid: "\u00BE", valid: "3/4" },
    { invalid: "\u00E6", valid: "ae" },
    { invalid: "\uE8E4", valid: "" },
    { invalid: "\u25CF", valid: "*" },
    { invalid: "\u200B", valid: "" },
    { invalid: "\u2019", valid: "'" },
    { invalid: "\u201C", valid: "\"" },
    { invalid: "\u201D", valid: "\"" }
  ].freeze
end
