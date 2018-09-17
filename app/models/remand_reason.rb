class RemandReason < ApplicationRecord
  validates :code#, inclusion: { in: Constants::ISSUE_DISPOSITIONS.keys.map(&:to_s) }
  validates :post_aoj, :request_issue, presence: true
  belongs_to :request_issue
end