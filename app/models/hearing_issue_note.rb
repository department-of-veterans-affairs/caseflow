class HearingIssueNote < ApplicationRecord
  belongs_to :request_issue
  belongs_to :hearing

  def to_hash
    serializable_hash(include: [hearing: { methods: [:external_id] }])
  end
end
