# frozen_string_literal: true

class Generators::VACOLS::Note
  class << self
    # rubocop:disable Metrics/MethodLength
    def note_attrs
      {
        tasknum: "877483D4",
        tsktknm: "877483",
        tskstfas: "JRAYNOR",
        tskactcd: "B",
        tskclass: "ACTIVE",
        tskrqact: "Illum voluptatem consectetur molestiae maiores commodi est est optio.",
        tskrspn: "Sapiente enim dolores id qui eveniet sequi.",
        tskdassn: "2017-07-11 00:00:00 UTC",
        tskdtc: 1,
        tskddue: "2017-07-12 00:00:00 UTC",
        tskdcls: "2017-07-11 00:00:00 UTC",
        tskstown: "JRAYNOR",
        tskstat: "C",
        tskownts: nil,
        tskclstm: nil,
        tskadusr: "JRAYNOR",
        tskadtm: "2017-07-11 00:00:00 UTC",
        tskmdusr: nil,
        tskmdtm: nil,
        tsactive: nil,
        tsspare1: nil,
        tsspare2: nil,
        tsspare3: nil,
        tsread1: nil,
        tsread: nil,
        tskorder: nil,
        tssys: nil
      }
    end
    # rubocop:enable Metrics/MethodLength

    def create(attrs = {})
      attrs = note_attrs.merge(attrs)

      VACOLS::Note.create(attrs)
    end
  end
end
