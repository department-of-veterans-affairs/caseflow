# frozen_string_literal: true

class PostDecisionMotion < ApplicationRecord
  belongs_to :task, required: true

  enum disposition: {
    granted: "granted",
    denied: "denied",
    withdrawn: "withdrawn",
    dismissed: "dismissed"
  }
end
