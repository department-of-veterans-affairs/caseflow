# frozen_string_literal: true

class OrganizationsUser < CaseflowRecord
  belongs_to :organization
  belongs_to :user

  has_one :judge_team_role, class_name: "::JudgeTeamRole", dependent: :destroy

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
      if removing_judge_from_their_judgeteam?(user, organization)
        fail Caseflow::Error::ActionForbiddenError, message: COPY::JUDGE_TEAM_DEADMIN_JUDGE_ERROR
      end
      existing_record(user, organization)&.update!(admin: false)
    end

    def remove_user_from_organization(user, organization)
      # mwagner - Won't this prevent BVA from removing extra judges right now?
      if removing_judge_from_their_judgeteam?(user, organization)
        fail Caseflow::Error::ActionForbiddenError, message: COPY::JUDGE_TEAM_REMOVE_JUDGE_ERROR
      end
      existing_record(user, organization)&.destroy
    end

    def existing_record(user, organization)
      find_by(organization_id: organization.id, user_id: user.id)
    end

    def enable_decision_drafting(user, organization)
      org_user = existing_record(user, organization)
      return nil unless org_user&.judge_team_role && FeatureToggle.enabled?(:judge_admin_scm)
      if org_user.judge_team_role.is_a?(JudgeTeamLead)
        fail Caseflow::Error::ActionForbiddenError, message: COPY::JUDGE_TEAM_ATTORNEY_RIGHTS_ERROR
      else
        org_user.judge_team_role.update!(type: DecisionDraftingAttorney)
      end
    end

    def disable_decision_drafting(user, organization)
      org_user = existing_record(user, organization)
      return nil unless org_user&.judge_team_role && FeatureToggle.enabled?(:judge_admin_scm)
      if org_user.judge_team_role.is_a?(JudgeTeamLead)
        fail Caseflow::Error::ActionForbiddenError, message: COPY::JUDGE_TEAM_ATTORNEY_RIGHTS_ERROR
      else
        org_user.judge_team_role.update!(type: nil)
      end
    end

    def judge_team_has_admin?(organization)
      organization.is_a?(JudgeTeam) && !!organization.admin
    end

    private

    def removing_judge_from_their_judgeteam?(user, organization)
      organization.is_a?(JudgeTeam) && organization.judge.eql?(user)
    end
  end
end
