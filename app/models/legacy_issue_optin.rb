class LegacyIssueOptin < ApplicationRecord
  include Asyncable

  belongs_to :review_request, polymorphic: true
  belongs_to :request_issue
end
