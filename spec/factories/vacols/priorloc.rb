# frozen_string_literal: true

FactoryBot.define do
  factory :priorloc, class: VACOLS::Priorloc do
    sequence(:lockey)

    before(:create) do |loc, evaluator|
      loc.locdout = evaluator.locdout.strftime("%Y-%m-%d %H:%M:%S %:z") if evaluator.locdout
      loc.locdin = evaluator.locdin.strftime("%Y-%m-%d %H:%M:%S %:z") if evaluator.locdin
    end
  end
end
