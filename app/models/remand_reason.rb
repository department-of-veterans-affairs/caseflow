# frozen_string_literal: true

class RemandReason < ApplicationRecord
  self.ignored_columns = %w(request_issue_id)
  validates :code, inclusion: { in: Constants::AMA_REMAND_REASONS_BY_ID.values.map(&:keys).flatten }
  validates :post_aoj, inclusion: { in: [true, false] }
  belongs_to :decision_issue
end
