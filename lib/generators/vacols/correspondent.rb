# frozen_string_literal: true

class Generators::VACOLS::Correspondent
  class << self
    def generate_pkseq
      SecureRandom.random_number(99_999_999)
    end

    # rubocop:disable Metrics/MethodLength
    def correspondent_attrs
      {
        stafkey: generate_pkseq,
        susrpw: nil,
        susrsec: nil,
        susrtyp: "VETERAN",
        ssalut: "PhD",
        snamef: "Jared",
        snamemi: "P",
        snamel: "Maggio",
        slogid: "753737700S",
        stitle: "Miss",
        sorg: "Soluta consequatur et amet necessitatibus expedita",
        sdept: "Nemo asperiores doloremque dolor harum.",
        saddrnum: nil,
        saddrst1: "9038 Pearl Shore",
        saddrst2: nil,
        saddrcty: "Lindmouth",
        saddrstt: "MI",
        saddrcnty: "MNP",
        saddrzip: "82832",
        stelw: "1-569-001-4462 x6692",
        stelwex: "2089",
        stelfax: nil,
        stelh: nil,
        staduser: "ATSCONV",
        stadtime: "1999-05-28 00:00:00 UTC",
        stmduser: "RO14",
        stmdtime: "2017-05-24 00:00:00 UTC",
        stc1: nil,
        stc2: nil,
        stc3: nil,
        stc4: nil,
        snotes: nil,
        sorc1: nil,
        sorc2: nil,
        sorc3: nil,
        sorc4: nil,
        sactive: "A",
        ssys: nil,
        sspare1: "Cruickshank",
        sspare2: "Estel",
        sspare3: nil,
        sspare4: nil,
        ssn: nil,
        sfnod: nil,
        sdob: "1981-08-20 00:00:00 UTC",
        sgender: "M",
        shomeless: nil,
        stermill: nil,
        sfinhard: nil,
        sadvage: nil,
        smoh: nil,
        svsi: nil,
        spow: nil,
        sals: nil,
        spgwv: nil,
        sincar: nil
      }
    end
    # rubocop:enable Metrics/MethodLength

    def create(attrs = {})
      attrs = correspondent_attrs.merge(attrs)

      VACOLS::Correspondent.create(attrs)
    end
  end
end
