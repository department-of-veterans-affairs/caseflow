class Generators::Vacols::CaseHearing
  class << self
    def case_hearing_attrs
      {hearing_pkseq: 523478,
       hearing_type: "C",
       folder_nr: 877483,
       hearing_date: "2017-08-08 13:00:00 UTC",
       hearing_disp: "H",
       board_member: 909,
       notes1: "Eum iure dicta quis maiores nihil architecto sit vero.",
       team: "SB",
       room: 3,
       rep_state: "WI",
       mduser: "CTROMP",
       mdtime: "2017-08-08 00:00:00 UTC",
       reqdate: nil,
       clsdate: nil,
       recmed: 3,
       consent: "2017-09-21 00:00:00 UTC",
       conret: "2017-10-06 00:00:00 UTC",
       contapes: "A",
       tranreq: nil,
       transent: nil,
       wbtapes: nil,
       wbbackup: nil,
       wbsent: nil,
       recprob: nil,
       taskno: "17-284",
       adduser: "JRAYNOR",
       addtime: "2017-07-11 00:00:00 UTC",
       aod: "N",
       holddays: nil,
       vdkey: nil,
       repname: "Elta Keeling",
       vdbvapoc: "Ms. Sebastian Nitzsche 1-442-063-2557",
       vdropoc: "Mr. Virginie Rempel 250.328.0605 x5488",
       canceldate: nil,
       addon: nil}
    end

    def create(attrs = {})
      attrs = case_hearing_attrs.merge(attrs)
      VACOLS::CaseHearing.create(attrs)
    end
  end
end