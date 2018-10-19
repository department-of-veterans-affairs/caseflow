class OrganizationsUser < ApplicationRecord
  belongs_to :organization
  belongs_to :user

  def self.add_user_to_organization(user, organization)
    create(organization_id: organization.id, user_id: user.id)
  end

  def self.remove_user_from_organization(user, organization)
    find_by(organization_id: organization.id, user_id: user.id).destroy
  end
end
