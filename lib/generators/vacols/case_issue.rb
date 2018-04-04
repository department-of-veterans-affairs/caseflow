class Generators::Vacols::CaseIssue
  class << self
    def case_issue_attrs
      {isskey: 877483,
       issseq: 8,
       issprog: 2,
       isscode: 12,
       isslev1: 4,
       isslev2: 5202,
       isslev3: nil,
       issdc: 3,
       issdcls: "2017-11-28 00:00:00 UTC",
       issadtime: "2017-11-17 16:31:59 UTC",
       issaduser: "RRAU",
       issmdtime: "2017-11-28 00:00:00 UTC",
       issmduser: "FBEAHAN",
       issdesc: "Illum voluptatem consectetur molestiae maiores commodi est est optio.",
       isssel: nil,
       issgr: nil,
       issdev: nil}
    end

    def create(attrs = {})
      case_issue_attrs.merge(attrs)

      VACOLS::CaseIssue.create(case_issue_attrs)
      end
  end
end