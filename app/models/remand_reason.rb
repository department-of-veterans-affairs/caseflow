class RemandReason < ApplicationRecord
  # validates :code, inclusion: { in: Constants::ISSUE_DISPOSITIONS.keys.map(&:to_s) }
  validates :request_issue, presence: true
  validates :post_aoj, inclusion: { in: [true, false] }
  belongs_to :request_issue
end
