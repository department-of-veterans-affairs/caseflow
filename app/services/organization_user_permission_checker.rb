# frozen_string_literal: true

class OrganizationUserPermissionChecker
  def can_do_all?(permissions:, organization:, user:)
    permissions.each do |permission|
      return false if !can?(
        permission_name: permission,
        organization: organization,
        user: user
      )
    end

    true
  end

  # Checks if a user possesses the permission and has the permitted flag enabled
  # permission_name - a string pulled off a OrganizationPermission.permission attribute
  # organization - an organization object
  # user - an OrganizationUser object
  def can?(permission_name:, organization:, user:)
    org_permission = organization_permission(organization, permission_name)
    return false if org_permission.blank?

    org_user = organization_user(organization, user)
    return false if org_user.blank?

    OrganizationUserPermission.find_by(
      organization_permission: org_permission,
      organizations_user: org_user,
      permitted: true
    ).present?
  end

  private

  def organization_permission(organization, permission_name)
    OrganizationPermission.find_by(
      organization: organization,
      permission: permission_name,
      enabled: true
    )
  end

  def organization_user(organization, user)
    OrganizationsUser.find_by(
      organization: organization,
      user: user
    )
  end
end
