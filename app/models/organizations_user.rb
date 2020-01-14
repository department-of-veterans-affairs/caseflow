# frozen_string_literal: true

class OrganizationsUser < ApplicationRecord
  belongs_to :organization
  belongs_to :user

  has_one :judge_team_role, class_name: "::JudgeTeamRole", dependent: :destroy

  scope :non_admin, -> { where(admin: false) }

  # Deprecated: add_user_to_organization(user, organization)
  # Use instead: organization.add_user(user)

  def self.make_user_admin(user, organization)
    org_user = OrganizationsUser.existing_record(user, organization)
    org_user = organization.add_user(user) unless org_user
    org_user.update!(admin: true)
  end

  def self.remove_admin_rights_from_user(user, organization)
    existing_record(user, organization)&.update!(admin: false)
  end

  def self.remove_user_from_organization(user, organization)
    if organization.is_a?(JudgeTeam) && organization.judge.eql?(user)
      fail Caseflow::Error::ActionForbiddenError, message: COPY::JUDGE_TEAM_REMOVE_JUDGE_ERROR
    end

    existing_record(user, organization).destroy
  end

  def self.existing_record(user, organization)
    find_by(organization_id: organization.id, user_id: user.id)
  end

  def self.modify_decision_drafting(user, organization)
    org_user = existing_record(user, organization)
    return nil unless org_user.judge_team_role && FeatureToggle.enabled?(:use_judge_team_role)
    if org_user.judge_team_role.is_a?(JudgeTeamLead)
      fail Caseflow::Error::ActionForbiddenError, message: COPY::JUDGE_TEAM_ATTORNEY_RIGHTS_ERROR
    elsif org_user.judge_team_role.is_a?(DecisionDraftingAttorney)
      org_user.judge_team_role.update!(type: nil)
    else
      org_user.judge_team_role.update!(type: DecisionDraftingAttorney)
    end
  end

end

