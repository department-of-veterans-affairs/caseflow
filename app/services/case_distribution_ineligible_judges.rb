# frozen_string_literal: true

class CaseDistributionIneligibleJudges
  class << self
    def ineligible_vacols_judges
      VACOLS::Staff.where("(STAFF.SVLJ IS NOT NULL OR STAFF.SATTYID IS NOT NULL) AND ((STAFF.SACTIVE = 'I') OR
     (STAFF.SVLJ IS NULL OR STAFF.SVLJ NOT IN ('A', 'J')))").map do |staff|
        { sattyid: staff.sattyid, sdomainid: staff.sdomainid, svlj: staff.svlj }
      end
    end

    def ineligible_caseflow_judges
      User.inactive.map { |user| { id: user.id, css_id: user.css_id } }.uniq
    end

    def vacols_judges_with_caseflow_records
      ineligible_vacols_judges.map do |hash|
        next hash if hash[:sdomainid].nil?

        caseflow_user = User.find_by_css_id(hash[:sdomainid])
        next hash unless caseflow_user

        hash.merge!({ id: caseflow_user.id, css_id: caseflow_user.css_id })
      end
    end

    def caseflow_judges_with_vacols_records
      ineligible_caseflow_judges.map do |hash|
        vacols_staff = VACOLS::Staff.find_by(sdomainid: hash[:css_id])
        next hash unless vacols_staff

        hash.merge!({ sattyid: vacols_staff.sattyid, sdomainid: vacols_staff.sdomainid, svlj: vacols_staff.svlj })
      end
    end
  end
end
