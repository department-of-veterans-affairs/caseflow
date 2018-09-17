class RemandReason < ApplicationRecord
  validates :code, inclusion: { in: Constants::AMA_REMAND_REASONS_BY_ID.values.map(&:keys).flatten }
  validates :request_issue, presence: true
  validates :post_aoj, inclusion: { in: [true, false] }
  belongs_to :request_issue
end
