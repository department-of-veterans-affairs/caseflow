# frozen_string_literal: true

FactoryBot.define do
  factory :legacy_appeal do
    transient do
      vacols_case { nil }
    end

    vacols_id { vacols_case&.bfkey }
    vbms_id { vacols_case&.bfcorlid }

    trait :with_schedule_hearing_tasks do
      after(:create) do |appeal, _evaluator|
        root_task = RootTask.find_or_create_by!(appeal: appeal, assigned_to: Bva.singleton)
        ScheduleHearingTask.create!(appeal: appeal, parent: root_task)
      end
    end

    trait :with_veteran do
      after(:create) do |legacy_appeal, evaluator|
        veteran = create(
          :veteran,
          file_number: legacy_appeal.veteran_file_number,
          first_name: "Bob",
          last_name: "Smith"
        )

        if evaluator.vacols_case
          evaluator.vacols_case.correspondent.snamef = veteran.first_name
          evaluator.vacols_case.correspondent.snamel = veteran.last_name
          evaluator.vacols_case.correspondent.ssalut = "PhD"
          evaluator.vacols_case.correspondent.save
        end
      end
    end
  end
end
