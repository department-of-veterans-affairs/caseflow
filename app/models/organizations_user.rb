# frozen_string_literal: true

class OrganizationsUser < ApplicationRecord
  belongs_to :organization
  belongs_to :user

  has_one :judge_team_role, class_name: "::JudgeTeamRole", dependent: :destroy

  scope :non_admin, -> { where(admin: false) }

  # Deprecated: add_user_to_organization(user, organization)
  # Use instead: organization.add_user(user)

  def self.make_user_admin(user, organization)
    organization.add_user(user).tap do |org_user|
      org_user.update!(admin: true)
    end
  end

  def self.remove_admin_rights_from_user(user, organization)
    existing_record(user, organization)&.update!(admin: false)
  end

  def self.remove_user_from_organization(user, organization)
    existing_record(user, organization).destroy
  end

  def self.existing_record(user, organization)
    find_by(organization_id: organization.id, user_id: user.id)
  end
end
