# frozen_string_literal: true

FactoryBot.define do
  factory :organization do
    type { Organization.name }

    sequence(:name) { |n| "ORG_#{n}" }
    sequence(:url) { |n| "org_queue_#{n}" }

    factory :vso, class: Vso do
      type { Vso.name }
    end

    factory :field_vso, class: FieldVso do
      type { FieldVso.name }
    end

    factory :private_bar, class: PrivateBar do
      type { PrivateBar.name }
    end

    factory :judge_team, class: JudgeTeam do
      type { JudgeTeam.name }

      # Note:
      # OrganizationsUser.make_user_admin(user, org) will call
      # org.add_user(user) and since org is a JudgeTeam,
      # this triggers the first user to be an admin.

      # for creating error state; error b/c lead should also be admin
      trait :incorrectly_has_nonadmin_judge_team_lead do
        after(:create) do |judge_team|
          judge_team.add_user(create(:user))
        end
      end

      trait :has_judge_team_lead_as_admin do
        after(:create) do |judge_team|
          OrganizationsUser.make_user_admin(create(:user), judge_team)
        end
      end
    end

    factory :bva do
      type { "Bva" }
    end

    factory :vha_program_office do
      type { VhaProgramOffice.name }
    end

    factory :vha_caregiver_support do
      type { VhaCaregiverSupport.name }
    end

    factory :vha_regional_office do
      type { VhaRegionalOffice }
      name { Constants.VISN_ORG_NAMES.visn_orgs.name.sample }
    end

    factory :education_emo do
      type { EducationEmo.name }
    end

    factory :education_rpo do
      type { EducationRpo.name }
    end

    factory :business_line, class: BusinessLine do
      type { "BusinessLine" }
    end

    factory :vre_business_line, class: BusinessLine do
      type { "BusinessLine" }
      name { Constants::BENEFIT_TYPES["voc_rehab"] }
    end

    factory :hearings_management do
      type { "HearingsManagement" }
      name { "Hearings Management" }
    end

    factory :inbound_ops_team, class: InboundOpsTeam do
      type { "InboundOpsTeam" }
      name { "Inbound Ops Team" }
      url { "inbound-ops-team" }
      trait :inbound_ops_team_permissions do
        after(:create) do |inbound_ops_team|
          create(
            :organization_permission,
            organization: inbound_ops_team,
            permission: "superuser",
            description: "Superuser: Split, Merge, and Reassign",
            default_for_admin: true,
            enabled: true
          )
          auto_assign = create(
            :organization_permission,
            organization: inbound_ops_team,
            permission: "auto_assign",
            description: "Auto-Assignment",
            enabled: true
          )
          create(
            :organization_permission,
            organization: inbound_ops_team,
            permission: "receive_nod_mail",
            description: "Receieve \"NOD Mail\"",
            parent_permission: auto_assign,
            enabled: true
          )
        end
      end
    end
  end
end
