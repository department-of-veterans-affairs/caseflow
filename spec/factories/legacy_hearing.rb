# frozen_string_literal: true

FactoryBot.define do
  factory :legacy_hearing do
    transient do
      hearing_day { create(:hearing_day) }
    end

    scheduled_for { hearing_day.scheduled_for }

    transient do
      case_hearing { create(:case_hearing, user: user, hearing_date: scheduled_for, vdkey: hearing_day.id) }
    end

    appeal do
      create(:legacy_appeal, vacols_case: create(:case_with_form_9, case_issues:
        [create(:case_issue), create(:case_issue)], case_hearings: [case_hearing]))
    end

    vacols_id { case_hearing.hearing_pkseq }

    trait :with_tasks do
      after(:create) do |hearing, _evaluator|
        create(:hearing_task_association, hearing: hearing, hearing_task: create(:hearing_task, appeal: hearing.appeal))
        create(:disposition_task, parent: hearing.hearing_task_association.hearing_task, appeal: hearing.appeal)
      end
    end
  end
end
