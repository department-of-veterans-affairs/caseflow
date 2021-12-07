# frozen_string_literal: true

class HearingIssueNote < CaseflowRecord
  belongs_to :request_issue
  belongs_to :hearing

  delegate :docket_name, to: :hearing
  delegate :diagnostic_code, to: :request_issue
  delegate :description, to: :request_issue
  delegate :notes, to: :request_issue
  delegate :benefit_type, to: :request_issue

  alias program benefit_type

  def to_hash
    serializable_hash(
      methods: [:docket_name, :diagnostic_code, :description, :notes, :program],
      include: [hearing: { methods: [:external_id] }]
    )
  end
end

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: hearing_issue_notes
#
#  id               :bigint           not null, primary key
#  allow            :boolean          default(FALSE)
#  deny             :boolean          default(FALSE)
#  dismiss          :boolean          default(FALSE)
#  remand           :boolean          default(FALSE)
#  reopen           :boolean          default(FALSE)
#  worksheet_notes  :string
#  created_at       :datetime
#  updated_at       :datetime         indexed
#  hearing_id       :bigint           not null, indexed
#  request_issue_id :bigint           not null, indexed
#
# Foreign Keys
#
#  fk_rails_9386e8e2ab  (hearing_id => hearings.id)
#  fk_rails_e9f8d88657  (request_issue_id => request_issues.id)
#
