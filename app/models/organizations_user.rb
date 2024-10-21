# frozen_string_literal: true

class OrganizationsUser < CaseflowRecord
  belongs_to :organization
  belongs_to :user

  scope :non_admin, -> { where(admin: false) }

  scope :admin, -> { where(admin: true) }

  class << self
    def make_user_admin(user, organization)
      organization_user = OrganizationsUser.existing_record(user, organization) || organization.add_user(user)
      if OrganizationsUser.judge_team_has_admin?(organization)
        fail(Caseflow::Error::ActionForbiddenError, message: COPY::JUDGE_TEAM_ADMIN_ERROR)
      else
        organization_user.tap do |org_user|
          org_user.update!(admin: true)
        end
      end
    end

    def remove_admin_rights_from_user(user, organization)
      if user_is_judge_of_team?(user, organization)
        fail Caseflow::Error::ActionForbiddenError, message: COPY::JUDGE_TEAM_DEADMIN_JUDGE_ERROR
      end

      existing_record(user, organization)&.update!(admin: false)
    end

    def remove_user_from_organization(user, organization)
      if user_is_judge_of_team?(user, organization)
        fail Caseflow::Error::ActionForbiddenError, message: COPY::JUDGE_TEAM_REMOVE_JUDGE_ERROR
      end

      existing_record(user, organization)&.destroy
    end

    def existing_record(user, organization)
      find_by(organization_id: organization.id, user_id: user.id)
    end

    def judge_team_has_admin?(organization)
      organization.is_a?(JudgeTeam) && !!organization.admin
    end

    def user_is_judge_of_team?(user, organization)
      organization.is_a?(JudgeTeam) && organization.judge.eql?(user)
    end
  end
end
