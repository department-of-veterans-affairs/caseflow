# frozen_string_literal: true

FactoryBot.define do
  factory :hearing do
    transient do
      regional_office { nil }
      adding_user { association(:user) }
    end
    appeal { association(:appeal, :hearing_docket) }
    judge { association(:user, roles: ["Hearing Prep"]) }
    uuid { SecureRandom.uuid }
    hearing_day do
      association(
        :hearing_day,
        regional_office: regional_office,
        scheduled_for: Time.zone.today,
        judge: judge,
        request_type: regional_office.nil? ? "C" : "V",
        created_by: adding_user,
        updated_by: adding_user
      )
    end
    hearing_location do
      if regional_office.present?
        association(:hearing_location, regional_office: regional_office)
      end
    end
    scheduled_time { "8:30AM" }
    created_by { adding_user }
    updated_by { adding_user }
    virtual_hearing { nil }

    trait :held do
      disposition { Constants.HEARING_DISPOSITION_TYPES.held }
    end

    trait :with_tasks do
      after(:create) do |hearing, _evaluator|
        create(:hearing_task_association,
               hearing: hearing,
               hearing_task: create(:hearing_task, appeal: hearing.appeal))
        create(:assign_hearing_disposition_task,
               parent: hearing.hearing_task_association.hearing_task,
               appeal: hearing.appeal)
      end
    end
  end
end
