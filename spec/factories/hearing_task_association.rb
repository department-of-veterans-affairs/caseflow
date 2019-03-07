# frozen_string_literal: true

FactoryBot.define do
  factory :hearing_task_association, class: HearingTaskAssociation do
    hearing_task { create(:hearing_task) }
    hearing { create(:hearing) }
  end
end
