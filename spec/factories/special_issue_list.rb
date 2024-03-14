# frozen_string_literal: true

FactoryBot.define do
  factory :special_issue_list do
    military_sexual_trauma { true }
    appeal_type { "Appeal" }
  end
end
