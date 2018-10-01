class AdvanceOnDocketMotion < ApplicationRecord
  belongs_to :people
  belongs_to :users

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
