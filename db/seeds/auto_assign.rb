# frozen_string_literal: true

module Seeds
  class AutoAssign < Base
    def seed!
      create_auto_assign_permissions
      create_auto_assign_users
    end

    private

    def create_auto_assign_permissions
      OrganizationPermission.valid_permission_names.each do |permission|
        OrganizationPermission.find_or_create_by(permission: permission, organization: InboundOpsTeam.singleton) do |p|
          p.description = Faker::Fantasy::Tolkien.poem
          p.enabled = true
        end
      end
    end

    def create_auto_assign_users
      user = User.find_or_create_by(css_id: "INBOUND_OPS_TEAM_MAIL_INTAKE_USER_QB") do |u|
        u.station_id = 101
        u.full_name = "Tom Brady"
        u.roles = ["Mail Intake"]
      end
      org_user = OrganizationsUser.find_or_create_by!(organization: InboundOpsTeam.singleton, user: user)

      OrganizationPermission.all.each do |permission|
        OrganizationUserPermission
          .find_or_create_by(organization_permission: permission, organizations_user: org_user) do |op|
          op.permitted = true
        end
      end
    end
  end
end
