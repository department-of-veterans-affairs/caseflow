# frozen_string_literal: true

class Events::DecisionReviewUpdated::DecisionReviewUpdatedAudit
  def initialize(event:, parser:)
    @event = event
    @parser = parser
  end

  def call!
    audit_updated_request_issue
    audit_added_request_issue
    audit_removed_request_issue
    audit_withdrawn_request_issue
    audit_ineligible_to_eligible_request_issue
    audit_eligible_to_ineligible_request_issue
    audit_ineligible_to_ineligible_request_issue
  end

  def audit_updated_request_issue
    @parser.updated_issues.each do |request_issue_data|
      request_issue = find_request_issue(request_issue_data)
      EventRecord.create!(
        event: @event,
        evented_record: request_issue,
        info: { update_type: "U", record_data: request_issue }
      )
    end
  end

  def audit_added_request_issue
    @parser.added_issues.each do |request_issue_data|
      request_issue = find_request_issue(request_issue_data)
      EventRecord.create!(
        event: @event,
        evented_record: request_issue,
        info: { update_type: "A", record_data: request_issue, event_data: request_issue_data }
      )
    end
  end

  def audit_removed_request_issue
    @parser.removed_issues.each do |request_issue_data|
      request_issue = find_request_issue(request_issue_data)
      EventRecord.create!(
        event: @event,
        evented_record: request_issue,
        info: { update_type: "R", record_data: request_issue, event_data: request_issue_data }
      )
    end
  end

  def audit_ineligible_to_eligible_request_issue
    @parser.ineligible_to_eligible_issues.each do |request_issue_data|
      request_issue = find_request_issue(request_issue_data)
      EventRecord.create!(
        event: @event,
        evented_record: request_issue,
        info: { update_type: "I2E", record_data: request_issue, event_data: request_issue_data }
      )
    end
  end

  def audit_eligible_to_ineligible_request_issue
    @parser.eligible_to_ineligible_issues.each do |request_issue_data|
      request_issue = find_request_issue(request_issue_data)
      EventRecord.create!(
        event: @event,
        evented_record: request_issue,
        info: { update_type: "E2I", record_data: request_issue, event_data: request_issue_data }
      )
    end
  end

  def audit_ineligible_to_ineligible_request_issue
    @parser.ineligible_to_ineligible_issues.each do |request_issue_data|
      request_issue = find_request_issue(request_issue_data)
      EventRecord.create!(
        event: @event,
        evented_record: request_issue,
        info: { update_type: "I2I", record_data: request_issue, event_data: request_issue_data }
      )
    end
  end

  def audit_withdrawn_request_issue
    @parser.withdrawn_issues.each do |request_issue_data|
      request_issue = find_request_issue(request_issue_data)
      EventRecord.create!(
        event: @event,
        evented_record: request_issue,
        info: { update_type: "W", record_data: request_issue, event_data: request_issue_data }
      )
    end
  end

  def find_request_issue(request_issues_data)
    RequestIssue.find_by(reference_id: request_issues_data[:reference_id]) ||
      fail(Caseflow::Error::DecisionReviewUpdateMissingIssueError, request_issues_data[:reference_id])
  end
end
