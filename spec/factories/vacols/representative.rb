# frozen_string_literal: true

# Warning: VACOLS has a uniqueness constraint on repaddtime + repkey,
# and VACOLS/FACOLS DB both appear to have after insert hooks that
# set repaddtime to the current system date, so using FactoryBot
# to insert more than one REP record with the same repkey will
# result in a DB error.
# TODO: remove this hook for FACOLS if needed.

FactoryBot.define do
  factory :representative, class: VACOLS::Representative do
    repkey { sequence(:repkey) }
    reptype { "A" }
  end
end
