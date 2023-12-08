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
      User.joins("LEFT JOIN organizations_users ON users.id = organizations_users.user_id")
        .joins("LEFT JOIN organizations ON organizations_users.organization_id = organizations.id")
        .where("users.status != ? OR (users.id IN (?) OR (organizations_users.admin = '1'
      AND organizations.type = 'JudgeTeam'
      AND organizations.status <> 'active') )", "active", non_admin_users_of_judge_teams)
        .map { |user| { id: user.id, css_id: user.css_id } }.uniq
    end

    def non_admin_users_of_judge_teams
      JudgeTeam.all.map(&:non_admins).flatten.map(&:id)
    end
  end
end
