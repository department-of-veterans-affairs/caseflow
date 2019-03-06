# frozen_string_literal: true

FactoryBot.define do
  factory :priorloc, class: VACOLS::Priorloc do
    sequence(:lockey)
  end
end
