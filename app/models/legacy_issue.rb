# frozen_string_literal: true

class LegacyIssue < CaseflowRecord
  belongs_to :request_issue
  has_one :legacy_issue_optin

  validates :request_issue, presence: true
end

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: legacy_issues
#
#  id                 :bigint           not null, primary key
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  request_issue_id   :bigint           not null, indexed
#  vacols_id          :string           not null
#  vacols_sequence_id :integer          not null
#
# Foreign Keys
#
#  fk_rails_e03544c254  (request_issue_id => request_issues.id)
#
