# frozen_string_literal: true

FactoryBot.define do
  factory :priorloc, class: VACOLS::Priorloc do
    sequence(:lockey)

    before(:create) do |loc, evaluator|
      loc.locdout = VacolsHelper.normalize_vacols_datetime(evaluator.locdout) if evaluator.locdout
      loc.locdin = VacolsHelper.normalize_vacols_datetime(evaluator.locdin) if evaluator.locdin
    end
  end
end
