# frozen_string_literal: true

module Seeds
  class CorrespondenceAutoAssign < Base
    def seed!
      create_auto_assign_permissions
      create_inbound_ops_team_nod_user
      create_inbound_ops_team_auto_assign_user
      create_inbound_ops_team_user_with_no_permissions
      create_inbound_ops_team_supervisor
      create_inbound_ops_team_superuser
      create_mail_team_user
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

    def create_inbound_ops_team_auto_assign_user
      users_info = [
        { css_id: "INBOUND_OPS_TEAM_MAIL_INTAKE_USER_AUTO_ASSIGN_A1", full_name: "Ember Sky" },
        { css_id: "INBOUND_OPS_TEAM_MAIL_INTAKE_USER_AUTO_ASSIGN_A2", full_name: "Aspen Ridge" },
        { css_id: "INBOUND_OPS_TEAM_MAIL_INTAKE_USER_AUTO_ASSIGN_A3", full_name: "Clover Haven" },
        { css_id: "INBOUND_OPS_TEAM_MAIL_INTAKE_USER_AUTO_ASSIGN_A4", full_name: "Blaze Hill" }
      ]
      users_info.map do |user_info|
        new_user = create_user(user_info)
        org_user = OrganizationsUser.find_or_create_by!(organization: InboundOpsTeam.singleton, user: new_user)
        auto_assign = OrganizationPermission.find_by(organization: InboundOpsTeam.singleton, permission: "auto_assign")
        OrganizationUserPermission.find_or_create_by!(
          organization_permission: auto_assign,
          organizations_user: org_user
        ) do |op|
          op.permitted = true
        end
      end
    end

    def create_inbound_ops_team_supervisor
      users_info = [
        { css_id: "INBOUND_OPS_TEAM_ADMIN_USER_S1", full_name: "Caleb Mitchell" },
        { css_id: "INBOUND_OPS_TEAM_ADMIN_USER_S2", full_name: "Scarlett Reed" },
        { css_id: "INBOUND_OPS_TEAM_ADMIN_USER_S3", full_name: "Elijah Turner" }
      ]
      users_info.map do |user_info|
        user = User.find_or_create_by!(
          station_id: 101,
          css_id: user_info[:css_id],
          full_name: user_info[:full_name],
          roles: ["Mail Intake"]
        )
        InboundOpsTeam.singleton.add_user(user)
        OrganizationsUser.make_user_admin(user, InboundOpsTeam.singleton)
      end
    end

    def create_inbound_ops_team_user_with_no_permissions
      users_info = [
        { css_id: "INBOUND_OPS_TEAM_MAIL_INTAKE_USER_NP1", full_name: "Noah Taylor" },
        { css_id: "INBOUND_OPS_TEAM_MAIL_INTAKE_USER_NP2", full_name: "Emma Brown" },
        { css_id: "INBOUND_OPS_TEAM_MAIL_INTAKE_USER_NP3", full_name: "Benjamin Anderson" },
        { css_id: "INBOUND_OPS_TEAM_MAIL_INTAKE_USER_NP4", full_name: "Ava Martinez" },
        { css_id: "INBOUND_OPS_TEAM_MAIL_INTAKE_USER_NP5", full_name: "Liam Miller" }
      ]
      users_info.map do |user_info|
        new_user = User.find_or_create_by!(
          station_id: 101,
          css_id: user_info[:css_id],
          full_name: user_info[:full_name],
          roles: ["Mail Intake"]
        )
        OrganizationsUser.find_or_create_by!(organization: InboundOpsTeam.singleton, user: new_user)
      end
    end

    def create_inbound_ops_team_superuser
      users_info = [
        { css_id: "INBOUND_OPS_TEAM_SUPERUSER1", full_name: "Willow Green" },
        { css_id: "INBOUND_OPS_TEAM_SUPERUSER2", full_name: "Jasper Bloom" },
        { css_id: "INBOUND_OPS_TEAM_SUPERUSER3", full_name: "Luna Meadows" }
      ]
      users_info.map do |user_info|
        new_user = User.find_or_create_by!(
          station_id: 101,
          css_id: user_info[:css_id],
          full_name: user_info[:full_name],
          roles: ["Mail Intake"]
        )
        InboundOpsTeam.singleton.add_user(new_user)
        superuser_permission = OrganizationPermission.find_by(permission: 'superuser', organization_id: InboundOpsTeam.singleton.id)
        OrganizationUserPermission.find_or_create_by!(
          organization_permission: superuser_permission,
          organizations_user: OrganizationsUser.find_by(user_id: new_user.id),
          permitted: true
        )
      end
    end

    def create_mail_team_user
      users_info = [
        { css_id: "MAIL_TEAM_USER_U1", full_name: "Cedar Rain" },
        { css_id: "MAIL_TEAM_USER_U2", full_name: "Ivy Stone" },
        { css_id: "MAIL_TEAM_USER_U3", full_name: "Ocean Breeze" }
      ]
      users_info.map do |user_info|
        new_user = User.find_or_create_by!(
          station_id: 101,
          css_id: user_info[:css_id],
          full_name: user_info[:full_name],
          roles: ["Mail Intake"]
        )
        MailTeam.singleton.add_user(new_user)
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
