module DescriptionCharacterMap
  # contested issue description pattern
  DESCRIPTION_CHARACTER_BLACKLIST = /[^a-zA-Z0-9\s.\-_|\/\\@#~=%,;?!'"`():$+*^\[\]&><{}]/.freeze

  # contested issue description replacement list
  DESCRIPTION_CHARACTER_MAP = [
    { invalid: "\u{2014}", valid: "-" },
    { invalid: "\u{2013}", valid: "-" },
    { invalid: "\u{00F6}", valid: "o" },
    { invalid: "\u{00D4}", valid: "O" },
    { invalid: "\u{00C2}", valid: "A" },
    { invalid: "\u{00E2}", valid: "a" },
    { invalid: "\u{0080}", valid: "E" },
    { invalid: "\u{0099}", valid: "TM" },
    { invalid: "\u{2026}", valid: "..." },
    { invalid: "\u{2022}", valid: "*" },
    { invalid: "\u{00E9}", valid: "e" },
    { invalid: "\u{00E8}", valid: "e" },
    { invalid: "\u{FFFD}", valid: "?" },
    { invalid: "\u{00BD}", valid: "1/2" },
    { invalid: "\u{00C3}", valid: "A" },
    { invalid: "\u{00A9}", valid: "(c)" },
    { invalid: "\u{00B0}", valid: "*" },
    { invalid: "\u{009C}", valid: "oe" },
    { invalid: "\u{009D}", valid: " " },
    { invalid: "\u{0093}", valid: "\"" },
    { invalid: "\u{0098}", valid: "~" },
    { invalid: "\u{00F3}", valid: "o" },
    { invalid: "\u{00B7}", valid: "*" },
    { invalid: "\u{0095}", valid: "*" },
    { invalid: "\u{0097}", valid: "-" },
    { invalid: "\u{00BF}", valid: "?" },
    { invalid: "\u{F020}", valid: "" },
    { invalid: "\u{00A3}", valid: "L" },
    { invalid: "\u{F0D8}", valid: "" },
    { invalid: "\u{00A5}", valid: "Y" },
    { invalid: "\u{203A}", valid: ">" },
    { invalid: "\u{F0B7}", valid: "" },
    { invalid: "\u{2010}", valid: "-" },
    { invalid: "\u{00BE}", valid: "3/4" },
    { invalid: "\u{00E6}", valid: "ae" },
    { invalid: "\u{E8E4}", valid: "" },
    { invalid: "\u{25CF}", valid: "*" },
    { invalid: "\u{200B}", valid: "" },
    { invalid: "\u{2019}", valid: "'" },
    { invalid: "\u{201C}", valid: "\"" },
    { invalid: "\u{201D}", valid: "\"" }
  ].freeze
end
