class LegacyIssueOptin < ApplicationRecord
  include Asyncable

  belongs_to :request_issue
end
