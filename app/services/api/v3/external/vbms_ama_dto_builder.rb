# frozen_string_literal: true

# use for option 2 w/o jsonapi or fast_json serializer
# RequestIssue.for_vbms.includes(:decision_issues_for_vbms).where(veteran_participant_id: "574727696").as_json(root: true, include: :decision_issues_for_vbms)
class Api::V3::External::VbmsAmaDtoBuilder
  '''def initialize(veteran_participant_id)
    veteran_participant_id = veteran_participant_id.to_s
    {
      "veteran_participant_id": veteran_participant_id,
      "legacy_appeals_present": false,
      "data": build_request_issue_decision_issue_json(veteran_participant_id)
    }
  end

  private

  def build_request_issue_decision_issue_json(veteran_participant_id)
    request_issue_decision_issue_hash_array =
      RequestIssue.includes(:decision_issues)
        .where(veteran_participant_id: veteran_participant_id)
        .as_json(root: true, include: :decision_issues)

    format_request_issue_decision_issue_hash(request_issue_decision_issue_hash_array)
  end

  def format_request_issue_decision_issue_hash(request_issue_decision_issue_hash_array)

  end'''

end
