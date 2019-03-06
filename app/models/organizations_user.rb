# frozen_string_literal: true

class OrganizationsUser < ApplicationRecord
  belongs_to :organization
  belongs_to :user

  def self.add_user_to_organization(user, organization)
    existing_record(user, organization) || create(organization_id: organization.id, user_id: user.id)
  end

  def self.make_user_admin(user, organization)
    add_user_to_organization(user, organization).update!(admin: true)
  end

  def self.remove_user_from_organization(user, organization)
    existing_record(user, organization).destroy
  end

  def self.existing_record(user, organization)
    find_by(organization_id: organization.id, user_id: user.id)
  end
end
