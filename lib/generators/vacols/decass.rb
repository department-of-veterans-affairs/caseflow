# frozen_string_literal: true

class Generators::VACOLS::Decass
  class << self
    # rubocop:disable Metrics/MethodLength
    def decass_attrs
      {
        defolder: 877_483,
        deatty: "1286",
        deteam: "SB",
        depdiff: "2",
        defdiff: "3",
        deassign: "2017-10-27 00:00:00 UTC",
        dereceive: "2017-11-17 00:00:00 UTC",
        dehours: nil,
        deprod: "DRM",
        detrem: "Y",
        dearem: nil,
        deoq: "5",
        deadusr: "AABSHIRE",
        deadtim: "2017-10-27 00:00:00 UTC",
        deprogrev: nil,
        deatcom: nil,
        debmcom: "Illum voluptatem consectetur molestiae maiores commodi est est optio.",
        demdusr: "AABSHIRE",
        demdtim: "2017-11-21 00:00:00 UTC",
        delock: "Y",
        dememid: "909",
        decomp: "2017-11-21 00:00:00 UTC",
        dedeadline: "2017-12-07 13:27:16 UTC",
        deicr: 7.8,
        defcr: 11.8,
        deqr1: nil,
        deqr2: nil,
        deqr3: nil,
        deqr4: nil,
        deqr5: nil,
        deqr6: nil,
        deqr7: nil,
        deqr8: nil,
        deqr9: nil,
        deqr10: nil,
        deqr11: nil,
        dedocid: nil,
        derecommend: "Y"
      }
    end
    # rubocop:enable Metrics/MethodLength

    def create(attrs = {})
      attrs = decass_attrs.merge(attrs)

      VACOLS::Decass.create(attrs)
    end
  end
end
