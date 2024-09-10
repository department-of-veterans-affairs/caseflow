# frozen_string_literal: true

FactoryBot.define do
  factory :transcription do
    hearing
    task_number { "BVA2024001" }
  end
end
