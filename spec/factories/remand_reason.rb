# frozen_string_literal: true

FactoryBot.define do
  factory :ama_remand_reason, class: RemandReason do
    code { "incorrect_notice_sent" }
    post_aoj { true }
  end
end
