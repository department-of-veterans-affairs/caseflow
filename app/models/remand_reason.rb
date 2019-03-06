# frozen_string_literal: true

class RemandReason < ApplicationRecord
  validates :code, inclusion: { in: Constants::AMA_REMAND_REASONS_BY_ID.values.map(&:keys).flatten }
  validates :post_aoj, inclusion: { in: [true, false] }
  # This will be removed
  belongs_to :request_issue
  belongs_to :decision_issue
end
