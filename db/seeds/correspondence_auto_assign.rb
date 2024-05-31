# frozen_string_literal: true

module Seeds
  class CorrespondenceAutoAssign < Base
    def seed!
      create_auto_assign_permissions
      create_inbound_ops_team_nod_user
      create_inbound_ops_team_user
    end

    private

    def create_auto_assign_permissions
      OrganizationPermission.valid_permission_names.each do |permission|
        OrganizationPermission.find_or_create_by(
          permission: permission,
          organization: InboundOpsTeam.singleton
        ) do |perm|
          perm.enabled = true
          perm.description = Faker::Hipster.sentence
        end
      end
      OrganizationPermission.find_by(permission: "superuser").update!(
        description: "Superuser: Split, Merge, and Reassign",
        default_for_admin: true,
      )
      OrganizationPermission.find_by(permission: "auto_assign").update!(description: "Auto-Assignment")
      OrganizationPermission.find_by(permission: "receive_nod_mail").update!(
        description: "Receieve \"NOD Mail\"",
        parent_permission: OrganizationPermission.find_by(permission: "auto_assign")
      )
    end

    def create_inbound_ops_team_nod_user
      users_info = [
        { css_id: "INBOUND_OPS_TEAM_MAIL_INTAKE_USER_NOD1", full_name: "Alexandr Johnson" },
        { css_id: "INBOUND_OPS_TEAM_MAIL_INTAKE_USER_NOD2", full_name: "Sopia Williams" },
        { css_id: "INBOUND_OPS_TEAM_MAIL_INTAKE_USER_NOD3", full_name: "Etan Davis" },
        { css_id: "INBOUND_OPS_TEAM_MAIL_INTAKE_USER_NOD4", full_name: "Olia Smith" }
      ]
      users_info.map do |user_info|
        new_user = create_user(user_info)
        org_user = OrganizationsUser.find_or_create_by!(organization: InboundOpsTeam.singleton, user: new_user)
        receive_nod_mail = OrganizationPermission.find_by(
          organization: InboundOpsTeam.singleton,
          permission: "receive_nod_mail"
        )
        OrganizationUserPermission.find_or_create_by!(
          organization_permission: receive_nod_mail,
          organizations_user: org_user
        ) do |op|
          op.permitted = true
        end
      end
    end

    def create_user(user_info)
      User.find_or_create_by!(
        station_id: 101,
        css_id: user_info[:css_id],
        full_name: user_info[:full_name],
        roles: ["Mail Intake"]
      )
    end
  end
end
