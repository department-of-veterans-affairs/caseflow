class HearingIssueNote < ApplicationRecord
  belongs_to :request_issue
  belongs_to :hearing

  delegate :docket_name, to: :hearing

  def to_hash
    serializable_hash(
      methods: :docket_name,
      include: [hearing: { methods: [:external_id] }]
    )
  end
end
