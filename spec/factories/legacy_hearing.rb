# frozen_string_literal: true

FactoryBot.define do
  factory :legacy_hearing do
    transient do
      regional_office { nil }
      hearing_day do
        create(:hearing_day,
               regional_office: regional_office,
               request_type: regional_office.nil? ? "C" : "V")
      end
    end

    hearing_location do
      if regional_office.present?
        venue = LegacyHearing.venues[regional_office]
        HearingLocation.create(name: venue[:label])
      end
    end

    scheduled_for { hearing_day.scheduled_for }

    transient do
      case_hearing do
        create(
          :case_hearing,
          user: user,
          hearing_date: VacolsHelper.format_datetime_with_utc_timezone(scheduled_for),
          vdkey: hearing_day.id
        )
      end
    end

    appeal do
      create(:legacy_appeal, closest_regional_office: regional_office, vacols_case:
        create(:case_with_form_9, case_issues:
        [create(:case_issue), create(:case_issue)], bfregoff: regional_office, case_hearings: [case_hearing]))
    end

    vacols_id { case_hearing.hearing_pkseq }

    trait :with_tasks do
      after(:create) do |hearing, _evaluator|
        create(:hearing_task_association, hearing: hearing, hearing_task: create(:hearing_task, appeal: hearing.appeal))
        create(:assign_hearing_disposition_task, parent: hearing.hearing_task_association.hearing_task, appeal: hearing.appeal)
      end
    end
  end
end
