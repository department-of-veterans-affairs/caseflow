# frozen_string_literal: true

class Generators::Vacols::Case
  class << self
    def generate_pkseq
      SecureRandom.random_number(99_999_999)
    end

    # rubocop:disable Metrics/MethodLength
    def case_attrs
      {
        bfkey: "877483",
        bfddec: "2017-11-28 00:00:00 UTC",
        bfcorkey: generate_pkseq,
        bfcorlid: "626343664S",
        bfdcn: nil,
        bfdocind: nil,
        bfpdnum: nil,
        bfdpdcn: nil,
        bforgtic: nil,
        bfdorg: "2017-06-30 00:00:00 UTC",
        bfdthurb: nil,
        bfdnod: "1995-09-11 00:00:00 UTC",
        bfdsoc: "1995-10-14 00:00:00 UTC",
        bfd19: "1995-11-20 00:00:00 UTC",
        bf41stat: "2017-05-24 00:00:00 UTC",
        bfmstat: nil,
        bfmpro: "REM",
        bfdmcon: nil,
        bfregoff: "RO14",
        bfissnr: 0,
        bfrdmref: "D",
        bfcasev: "02",
        bfcaseva: nil,
        bfcasevb: nil,
        bfcasevc: nil,
        bfboard: "SBODE",
        bfbsasgn: nil,
        bfattid: "1286",
        bfdasgn: nil,
        bfcclkid: "8927941",
        bfdqrsnt: nil,
        bfdlocin: "2017-11-30 09:01:21 UTC",
        bfdloout: "2017-11-30 09:01:21 UTC",
        bfstasgn: nil,
        bfcurloc: "98",
        bfnrcopy: nil,
        bfmemid: "909",
        bfdmem: nil,
        bfnrci: nil,
        bfcallup: nil,
        bfcallyymm: nil,
        bfhines: "42",
        bfdcfld1: nil,
        bfdcfld2: nil,
        bfdcfld3: nil,
        bfac: "1",
        bfdc: "3",
        bfha: "1",
        bfic: nil,
        bfio: nil,
        bfms: nil,
        bfoc: "N",
        bfsh: nil,
        bfso: "D",
        bfhr: "1",
        bfst: "P",
        bfdrodec: "1994-09-12 00:00:00 UTC",
        bfssoc1: "1996-10-11 00:00:00 UTC",
        bfssoc2: "2017-04-24 00:00:00 UTC",
        bfssoc3: nil,
        bfssoc4: nil,
        bfssoc5: nil,
        bfdtb: nil,
        bftbind: nil,
        bfdcue: nil,
        bfddvin: nil,
        bfddvout: nil,
        bfddvwrk: nil,
        bfddvdsp: nil,
        bfddvret: nil,
        bfddro: nil,
        bfdroid: nil,
        bfdrortr: nil,
        bfro1: "RO97",
        bflot: nil,
        bfbox: nil,
        bfdtbready: nil,
        bfarc: nil,
        bfdarcin: nil,
        bfdarcout: nil,
        bfarcdisp: nil,
        bfsub: nil,
        bfrocdoc: nil,
        bfdrocket: nil,
        bfdcertool: "2017-05-24 00:00:00 UTC"
      }
    end
    # rubocop:enable Metrics/MethodLength

    def create(attrs = {})
      custom_case_attrs = attrs[:case_attrs].nil? ? {} : attrs[:case_attrs]
      custom_case_attrs = case_attrs.merge(custom_case_attrs)

      # Commit dependencies
      folder_attrs = attrs[:folder_attrs].nil? ? {} : attrs[:folder_attrs]
      folder_attrs[:ticknum] = custom_case_attrs[:bfkey]
      Generators::Vacols::Folder.create(folder_attrs)

      representative_attrs = attrs[:representative_attrs].nil? ? {} : attrs[:representative_attrs]
      representative_attrs[:repkey] = custom_case_attrs[:bfkey]
      Generators::Vacols::Representative.create(representative_attrs)

      correspondent_attrs = attrs[:correspondent_attrs].nil? ? {} : attrs[:correspondent_attrs]
      correspondent_attrs[:stafkey] = custom_case_attrs[:bfcorkey]
      Generators::Vacols::Correspondent.create(correspondent_attrs)

      note_attrs = attrs[:note_attrs].nil? ? {} : attrs[:note_attrs]
      note_attrs[:tsktknm] = custom_case_attrs[:bfkey]
      Generators::Vacols::Note.create(note_attrs)

      decass_attrs = attrs[:decass_attrs].nil? ? {} : attrs[:decass_attrs]
      decass_attrs[:defolder] = custom_case_attrs[:bfkey]
      Generators::Vacols::Decass.create(decass_attrs)

      # One to many relationships

      # Default to two issues
      case_issue_attrs = attrs[:case_issue_attrs].nil? ? [{}, {}] : attrs[:case_issue_attrs]
      case_issue_attrs.each { |issue| issue[:isskey] = custom_case_attrs[:bfkey] }
      Generators::Vacols::CaseIssue.create(case_issue_attrs)

      # Default to zero hearings
      case_hearing_attrs = attrs[:case_hearing_attrs].nil? ? [] : attrs[:case_hearing_attrs]
      case_hearing_attrs.each { |hearing| hearing[:folder_nr] = custom_case_attrs[:bfkey] }
      Generators::Vacols::CaseHearing.create(case_hearing_attrs)

      staff_attrs = attrs[:staff_attrs].nil? ? {} : attrs[:staff_attrs]
      staff_attrs[:slogid] = custom_case_attrs[:bfcurloc]
      Generators::Vacols::Staff.create(staff_attrs)

      VACOLS::Case.create(custom_case_attrs)
    end
  end
end
