class Generators::Vacols::Case
  class << self
    def case_attrs
      {bfkey: 877483,
       bfddec: "2017-11-28 00:00:00 UTC",
       bfcorkey: "CK168505",
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
       bfcasev: 2,
       bfcaseva: nil,
       bfcasevb: nil,
       bfcasevc: nil,
       bfboard: "SBODE",
       bfbsasgn: nil,
       bfattid: 1286,
       bfdasgn: nil,
       bfcclkid: 8927941,
       bfdqrsnt: nil,
       bfdlocin: "2017-11-30 09:01:21 UTC",
       bfdloout: "2017-11-30 09:01:21 UTC",
       bfstasgn: nil,
       bfcurloc: 98,
       bfnrcopy: nil,
       bfmemid: 909,
       bfdmem: nil,
       bfnrci: nil,
       bfcallup: nil,
       bfcallyymm: nil,
       bfhines: 42,
       bfdcfld1: nil,
       bfdcfld2: nil,
       bfdcfld3: nil,
       bfac: 1,
       bfdc: 3,
       bfha: 1,
       bfic: nil,
       bfio: nil,
       bfms: nil,
       bfoc: "N",
       bfsh: nil,
       bfso: "D",
       bfhr: 1,
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
       bfdcertool: "2017-05-24 00:00:00 UTC"}
    end

    def create(attrs = {})
      case_attrs.merge(attrs["case_attrs"])

      VACOLS::Case.create(case_attrs)

      # Commit dependencies
      VACOLS::Folder.create(attrs["folder_attrs"])
      VACOLS::Representative.create(attrs["representative_attrs"])
      VACOLS::Correspondent.create(attrs["correspondent_attrs"])
      VACOLS::CaseIssue.create(attrs["case_issue_attrs"])
      VACOLS::Note.create(attrs["note_attrs"])
      VACOLS::CaseHearing.create(attrs["case_hearing_attrs"])
      VACOLS::Decass.create(attrs["decass_attrs"])
      VACOLS::Staff.create(attrs["staff_attrs"])
    end
  end
end