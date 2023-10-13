# frozen_string_literal: true

# use for option 2 w/o jsonapi or fast_json serializer
# RequestIssue.for_vbms.includes(:decision_issues_for_vbms).where(veteran_participant_id: "574727696").as_json(root: true, include: :decision_issues_for_vbms)
class Api::V3::External::VbmsAmaDtoBuilder
  attr_reader :json_response

  def initialize(veteran_participant_id)
    veteran_participant_id = veteran_participant_id.to_s
    @json_response = {
      "veteran_participant_id": veteran_participant_id,
      "legacy_appeals_present": false,
      "data": build_request_issue_decision_issue_json(veteran_participant_id)
    }.to_json
  end

  private

  def build_request_issue_decision_issue_json(veteran_participant_id)
    RequestIssue.for_vbms.includes(:decision_issues_for_vbms).where(veteran_participant_id: veteran_participant_id).page(1).as_json(root: true, include: :decision_issues_for_vbms).to_json
  end

end
