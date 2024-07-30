# frozen_string_literal: true

FactoryBot.define do
  factory :priorloc, class: VACOLS::Priorloc do
    sequence(:lockey)

    before(:create) do |loc, evaluator|
      loc.locdout = VacolsHelper.format_datetime_with_utc_timezone(evaluator.locdout) if evaluator.locdout
      loc.locdin = VacolsHelper.format_datetime_with_utc_timezone(evaluator.locdin) if evaluator.locdin
    end
  end
end
