# frozen_string_literal: true

class OrganizationsUser < ApplicationRecord
  belongs_to :organization
  belongs_to :user

  has_one :judge_team_role, class_name: "::JudgeTeamRole", dependent: :destroy

  after_create :inform_organization_user_added

  scope :non_admin, -> { where(admin: false) }

  def self.add_user_to_organization(user, organization)
    existing_record(user, organization) || create(organization_id: organization.id, user_id: user.id)
  end

  def self.make_user_admin(user, organization)
    add_user_to_organization(user, organization).tap do |org_user|
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

  def inform_organization_user_added
    organization.user_added_to_organization(self)
  end
end
