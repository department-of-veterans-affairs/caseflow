# frozen_string_literal: true

class Generators::VACOLS::Staff
  class << self
    # rubocop:disable Metrics/MethodLength
    def staff_attrs
      {
        stafkey: "98",
        susrpw: nil,
        susrsec: nil,
        susrtyp: nil,
        ssalut: nil,
        snamef: nil,
        snamemi: nil,
        snamel: "98 Advance Pending Intake",
        slogid: "DSUSER",
        stitle: nil,
        sorg: "98",
        sdept: nil,
        saddrnum: nil,
        saddrst1: nil,
        saddrst2: nil,
        saddrcty: nil,
        saddrstt: nil,
        saddrcnty: nil,
        saddrzip: nil,
        stelw: nil,
        stelwex: nil,
        stelfax: nil,
        stelh: nil,
        staduser: "SBARTELL",
        stadtime: "2017-12-05 00:00:00 UTC",
        stmduser: nil,
        stmdtime: nil,
        stc1: nil,
        stc2: nil,
        stc3: nil,
        stc4: nil,
        snotes: nil,
        sorc1: nil,
        sorc2: nil,
        sorc3: nil,
        sorc4: nil,
        sactive: "I",
        ssys: nil,
        sspare1: nil,
        sspare2: nil,
        sspare3: nil,
        smemgrp: nil,
        sfoiasec: nil,
        srptsec: nil,
        sattyid: nil,
        svlj: nil,
        sinvsec: nil,
        sdomainid: "DSUSER"
      }
    end
    # rubocop:enable Metrics/MethodLength

    def create(attrs = {})
      merged_attrs = staff_attrs.merge(attrs)

      VACOLS::Staff.create(merged_attrs)
    end
  end
end
