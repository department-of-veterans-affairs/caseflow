# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    css_id { "CSSID#{generate :css_id}" }

    station_id { User::BOARD_STATION_ID }
    full_name { "Lauren Roth" }

    transient do
      vacols_uniq_id { nil }
    end

    factory :default_user do
      css_id { "DEFAULT_USER" }
      full_name { "Lauren Roth" }
      email { "test@example.com" }
      roles { ["Certify Appeal"] }
    end

    factory :hearings_coordinator do
      css_id { "BVATWARNER" }
      full_name { "Thomas Warner" }
      email { "thomas.warner@example.com" }
      roles { ["Assign Hearings"] }
    end

    factory :intake_user do
      css_id { "BVATWARNER" }
      full_name { "Sandra Warner" }
      email { "sandra.warner@example.com" }
      roles { ["Mail Intake"] }
    end

    factory :intake_admin_user do
      css_id { "INTAKEADMINUSER" }
      full_name { "Shirley Warner" }
      email { "shirley.warner@example.com" }
      roles { ["Admin Intake"] }
    end

    factory :inbound_ops_team_supervisor do
      after(:create) do |user|
        InboundOpsTeam.singleton.add_user(user)
        MailTeam.singleton.add_user(user)
        OrganizationsUser.find_or_create_by!(organization: InboundOpsTeam.singleton, user: user).update!(admin: true)
        User.authenticate!(user: current_user)
      end
    end

    factory :correspondence_auto_assignable_user do
      after(:create) do |u|
        # Member of InboundOpsTeam
        org_user = OrganizationsUser.find_or_create_by!(organization: InboundOpsTeam.singleton, user: u)

        org_permission = OrganizationPermission.find_or_create_by!(
          organization: InboundOpsTeam.singleton,
          permission: Constants.ORGANIZATION_PERMISSIONS.auto_assign
        ) do |op|
          op.enabled = true
          op.description = "Auto-Assignment"
        end

        # Has auto-assign permission
        OrganizationUserPermission.find_or_create_by!(
          organization_permission: org_permission,
          organizations_user: org_user
        ) do |oup|
          oup.permitted = true
        end
      end

      trait :super_user do
        after(:create) do |u|
          OrganizationsUser.find_or_create_by!(organization: InboundOpsTeam.singleton, user: u).update!(admin: true)
          permission = OrganizationPermission.find_or_create_by!(
            permission: Constants.ORGANIZATION_PERMISSIONS.superuser,
            organization: InboundOpsTeam.singleton,
            enabled: true,
            description: "Superuser: Split, Merge, Reassign"
          )

          OrganizationUserPermission.find_or_create_by!(
            organization_permission: permission,
            permitted: true,
            organizations_user: OrganizationsUser.find_or_create_by(user_id: u.id)
          )
        end
      end

      trait :nod_enabled do
        after(:create) do |u|
          org_user = OrganizationsUser.find_or_create_by!(organization: InboundOpsTeam.singleton, user: u)

          org_permission = OrganizationPermission.find_or_create_by!(
            organization: InboundOpsTeam.singleton,
            permission: Constants.ORGANIZATION_PERMISSIONS.receive_nod_mail
          ) do |op|
            op.enabled = true
            op.description = "Receive \"NOD Mail\""
          end

          OrganizationUserPermission.find_or_create_by!(
            organization_permission: org_permission,
            organizations_user: org_user
          ) do |oup|
            oup.permitted = true
          end
        end
      end
    end

    trait :inactive do
      status { "inactive" }
    end

    trait :vso_role do
      roles { ["VSO"] }
    end

    trait :admin_intake_role do
      roles { ["Mail Intake", "Admin Intake"] }
    end

    trait :judge do
      with_judge_team
      roles { ["Hearing Prep"] }
    end

    trait :judge_inactive do
      inactive
      with_inactive_judge_team
      roles { ["Hearing Prep"] }
    end

    trait :judge_with_appeals_excluded_from_affinity do
      with_appeals_excluded_from_affinity_judge_team
      roles { ["Hearing Prep"] }
    end

    trait :ama_only_judge do
      after(:create) do |judge|
        JudgeTeam.for_judge(judge)&.update(ama_only_push: true, ama_only_request: true) ||
          JudgeTeam.create_for_judge(judge, ama_only_push: true, ama_only_request: true)
      end

      roles { ["Hearing Prep"] }
    end

    trait :with_vacols_record do
      after(:create) do |user|
        create(:staff, user: user)
      end
    end

    trait :with_vacols_judge_record do
      after(:create) do |user|
        create(:staff, :judge_role, slogid: user.css_id, user: user)
      end
    end

    trait :with_inactive_vacols_judge_record do
      after(:create) do |user|
        create(:staff, :inactive_judge, slogid: user.css_id, user: user)
      end
    end

    trait :with_vacols_record_satty_id do
      after(:create) do |user|
        create(:staff, :has_sattyid, slogid: user.css_id, user: user)
      end
    end

    trait :with_judge_team do
      after(:create) do |judge|
        JudgeTeam.for_judge(judge) || JudgeTeam.create_for_judge(judge)
      end
    end

    # This team will not end up being searchable unless you chain .unscoped because of the org model default scope
    trait :with_inactive_judge_team do
      after(:create) do |judge|
        judge_team = JudgeTeam.for_judge(judge) || JudgeTeam.create_for_judge(judge)
        judge_team.inactive!
      end
    end

    trait :with_appeals_excluded_from_affinity_judge_team do
      after(:create) do |judge|
        judge_team = JudgeTeam.for_judge(judge) || JudgeTeam.create_for_judge(judge)
        judge_team.update!(exclude_appeals_from_affinity: true)
      end
    end

    trait :with_vacols_attorney_record do
      after(:create) do |user|
        create(:staff, :attorney_role, user: user)
      end
    end

    trait :with_vacols_acting_judge_record do
      after(:create) do |user|
        create(:staff, :attorney_judge_role, user: user)
      end
    end

    trait :with_vacols_titled_attorney_record do
      after(:create) do |user|
        create(:staff, :titled_attorney_role, user: user)
      end
    end

    trait :vlj_support_user do
      after(:create) do |user|
        Colocated.singleton.add_user(user)
      end
    end

    trait :cda_control_admin do
      after(:create) do |user|
        CDAControlGroup.singleton.add_user(user)
        OrganizationsUser.make_user_admin(user, CDAControlGroup.singleton)
      end
    end

    trait :vha_admin_user do
      after(:create) do |user|
        VhaBusinessLine.singleton.add_user(user)
        OrganizationsUser.make_user_admin(user, VhaBusinessLine.singleton)
      end
    end

    trait :vha_default_user do
      after(:create) do |user|
        VhaBusinessLine.singleton.add_user(user)
      end
    end

    trait :bva_intake_admin do
      after(:create) do |user|
        BvaIntake.singleton.add_user(user)
        OrganizationsUser.make_user_admin(user, BvaIntake.singleton)
      end
    end

    trait :team_admin do
      after(:create) do |user|
        existing_sysadmins = Functions.details_for("System Admin")[:granted] || []
        Functions.grant!("System Admin", users: existing_sysadmins + [user.css_id])
        Bva.singleton.add_user(user)
        OrganizationsUser.make_user_admin(user, Bva.singleton)
      end
    end

    trait :non_ssc_avlj_user do
      after(:create) do |user|
        create(:staff, :non_ssc_avlj, user: user)
      end
    end

    trait :ssc_avlj_user do
      after(:create) do |user|
        create(:staff, :ssc_avlj, user: user)
      end
    end

    trait :vlj_user do
      after(:create) do |user|
        create(:staff, :vlj, user: user)
      end
    end

    trait :inactive_non_ssc_avlj_user do
      after(:create) do |user|
        create(:staff, :inactive_non_ssc_avlj, user: user)
      end
    end

    after(:create) do |user, evaluator|
      if evaluator.vacols_uniq_id
        create(:staff, slogid: evaluator.vacols_uniq_id, user: user)
      end
    end
  end
end
