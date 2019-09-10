# frozen_string_literal: true

class PostDecisionMotion < ApplicationRecord
  belongs_to :task, optional: false

  validates :disposition, presence: true
  validate :vacate_type_is_present_if_granted

  enum disposition: {
    granted: "granted",
    denied: "denied",
    withdrawn: "withdrawn",
    dismissed: "dismissed"
  }

  enum vacate_type: {
    straight_vacate_and_readjudication: "straight_vacate_and_readjudication",
    vacate_and_de_novo: "vacate_and_de_novo"
  }

  private

  def vacate_type_is_present_if_granted
    return unless granted?

    errors.add(:vacate_type, "is required for granted disposition") unless vacate_type
  end
end
