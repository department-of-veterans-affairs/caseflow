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
