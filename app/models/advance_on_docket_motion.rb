# frozen_string_literal: true

class AdvanceOnDocketMotion < ApplicationRecord
  belongs_to :person
  belongs_to :user

  enum status: {
    granted: "granted",
    denied: "denied"
  }
  enum reason: {
    financial_distress: "financial_distress",
    age: "age",
    serious_illness: "serious_illness",
    other: "other"
  }
end
