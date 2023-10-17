# frozen_string_literal: true

class Api::V3::VbmsIntake::Ama::VbmsAmaDtoBuilder
  attr_reader :json_response

  # TODO: add method for legacy
  def initialize(veteran_participant_id, page)
    veteran_participant_id = veteran_participant_id.to_s
    @json_response = {
      "page": page,
      "offset": 50,
      "total": total_request_issue_size(veteran_participant_id),
      "veteran_participant_id": veteran_participant_id,
      "legacy_appeals_present": false,
      "data": build_request_issue_decision_issue_json(veteran_participant_id, page)
    }.to_json
  end

  private

  def total_request_issue_size(veteran_participant_id)
    RequestIssue.where(veteran_participant_id: veteran_participant_id).size
  end

  def build_request_issue_decision_issue_json(veteran_participant_id, page)
    RequestIssue.for_vbms.includes(:decision_issues_for_vbms)
      .where(veteran_participant_id: veteran_participant_id)
      .page(page).as_json(root: true, include: :decision_issues_for_vbms).to_json
  end

end
