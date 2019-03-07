# frozen_string_literal: true

FactoryBot.define do
  factory :hearing do
    appeal { create(:appeal, :hearing_docket) }
    uuid { SecureRandom.uuid }
    hearing_day { create(:hearing_day) }
    scheduled_time { "8:30AM" }

    after(:create) do |hearing, _evaluator|
      create(:hearing_task_association, hearing: hearing, hearing_task: create(:hearing_task, appeal: hearing.appeal))
      create(:disposition_task, parent: hearing.hearing_task_association.hearing_task, appeal: hearing.appeal)
    end
  end
end
