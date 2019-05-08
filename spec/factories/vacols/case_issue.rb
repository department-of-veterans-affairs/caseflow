# frozen_string_literal: true

FactoryBot.define do
  factory :case_issue, class: VACOLS::CaseIssue do
    # we prefeace the key with ISSUE to distinguish issues created on their own from
    # issues associated with a particular case using the case factory's case_issues array
    sequence(:isskey) { |n| "ISSUE#{n}" }

    issseq { VACOLS::CaseIssue.generate_sequence_id(isskey) }

    issprog { "01" }
    isscode { "02" }
    issaduser { "user" }
    issadtime { Time.zone.now }

    transient do
      remand_reasons { [] }

      after(:create) do |issue, evaluator|
        evaluator.remand_reasons.each do |remand_reason|
          remand_reason.rmdkey = issue.isskey
          remand_reason.rmdissseq = issue.issseq
          remand_reason.save
        end
      end
    end

    transient do
      with_notes { false }
    end

    after(:create) do |issue, evaluator|
      issue.issdesc = "note for issue with id #{issue.id}" if evaluator.with_notes
    end

    trait :compensation do
      issprog { "02" }
      isscode { "15" }
      isslev1 { "04" }
      isslev2 { "5252" }
    end

    Constants::DIAGNOSTIC_CODE_DESCRIPTIONS.each_key do |diag_code|
      trait_name = Constants::DIAGNOSTIC_CODE_DESCRIPTIONS[diag_code]["status_description"]
      trait trait_name.parameterize.underscore.to_sym do
        issprog { "02" }
        isscode { "15" }
        isslev1 { "03" }
        isslev2 { diag_code }
      end
    end

    trait :education do
      issprog { "03" }
      isscode { "02" }
      isslev1 { "01" }
    end

    trait :disposition_remanded do
      issdc { "3" }
    end

    trait :disposition_manlincon_remand do
      issdc { "L" }
    end

    trait :disposition_vacated do
      issdc { "5" }
    end

    trait :disposition_merged do
      issdc { "M" }
    end

    trait :disposition_denied do
      issdc { "4" }
    end

    trait :disposition_allowed do
      issdc { "1" }
    end

    trait :disposition_advance_failure_to_respond do
      issdc { "G" }
    end

    trait :disposition_remand_failure_to_respond do
      issdc { "X" }
    end

    trait :disposition_granted_by_aoj do
      issdc { "B" }
    end

    trait :disposition_opted_in do
      issdc { "O" }
    end
  end
end
