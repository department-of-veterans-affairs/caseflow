# frozen_string_literal: true

module Seeds
  class OrganizationUserPermissions
    def seed!
      create_inbound_ops_team_superuser_permissions
    end
    private

    def create_inbound_ops_team_superuser_permissions
      superuser_permission = OrganizationPermission.find_by(permission: 'superuser', organization_id: InboundOpsTeam.singleton.id)

      OrganizationUserPermission.find_or_create_by!(
        organization_permission: superuser_permission,
        organizations_user: OrganizationsUser.find_by(user_id: 72),
        permitted: true
      )
      OrganizationUserPermission.find_or_create_by!(
        organization_permission: superuser_permission,
        organizations_user: OrganizationsUser.find_by(user_id: 73),
        permitted: true
      )
    end
  end
end
