# frozen_string_literal: true

module IssueUpdater
  extend ActiveSupport::Concern

  def update_issue_dispositions_in_caseflow!
    return unless appeal

    # We will always delete and re-create decision issues on attorney/judge checkout
    appeal.decision_issues.each(&:soft_delete)
    create_decision_issues!
    fail_if_not_all_request_issues_have_decision!
    fail_if_appeal_has_no_decision_issues!
  rescue ActiveRecord::RecordInvalid => error
    raise Caseflow::Error::AttorneyJudgeCheckoutError, message: error.message
  end

  def update_issue_dispositions_in_vacols!
    fail_if_invalid_issues_attrs!

    (issues || []).each do |issue_attrs|
      Issue.update_in_vacols!(
        vacols_id: vacols_id,
        vacols_sequence_id: issue_attrs[:id],
        issue_attrs: {
          vacols_user_id: modifying_user,
          disposition: issue_attrs[:disposition],
          disposition_date: VacolsHelper.local_date_with_utc_timezone,
          readjudication: issue_attrs[:readjudication],
          remand_reasons: issue_attrs[:remand_reasons]
        }
      )
    end
  end

  private

  def create_decision_issues!
    issues.each do |issue_attrs|
      request_issues = appeal.request_issues.active_or_withdrawn.where(id: issue_attrs[:request_issue_ids])
      next if request_issues.empty?

      decision_issue = DecisionIssue.create!(
        disposition: issue_attrs[:disposition],
        description: issue_attrs[:description],
        benefit_type: issue_attrs[:benefit_type],
        diagnostic_code: issue_attrs[:diagnostic_code].presence,
        participant_id: appeal.veteran.participant_id,
        decision_review: appeal,
        caseflow_decision_date: appeal.decision_document&.decision_date
      )

      request_issues.each do |request_issue|
        RequestDecisionIssue.create!(decision_issue: decision_issue, request_issue: request_issue)
      end
      create_remand_reasons(decision_issue, issue_attrs[:remand_reasons] || [])
    end
  end

  def fail_if_not_all_request_issues_have_decision!
    unless appeal.every_request_issue_has_decision?
      fail Caseflow::Error::AttorneyJudgeCheckoutError, message: "Not every request issue has a decision issue"
    end
  end

  def fail_if_appeal_has_no_decision_issues!
    # In order for this to work, have to reload an appeal from memory
    if appeal.reload.decision_issues.blank?
      fail Caseflow::Error::AttorneyJudgeCheckoutError, message: "Appeal is missing decision issues"
    end
  end

  def fail_if_invalid_issues_attrs!
    return if is_a?(AttorneyCaseReview) && omo_request?

    fail_if_count_mismatch!
    fail_if_no_dispositions!
  end

  def fail_if_no_dispositions!
    unless (issues || []).all? { |issue| issue[:disposition].present? }
      msg = "Issues in the request are missing dispositions"
      fail Caseflow::Error::AttorneyJudgeCheckoutError, message: msg
    end
  end

  def fail_if_count_mismatch!
    if (issues || []).count != appeal.undecided_issues.count
      title = "The issues are out of sync"
      msg = "The issues on this case have changed. Please refresh the page and submit your decision again."
      fail Caseflow::Error::AttorneyJudgeCheckoutError, message: msg, title: title
    end
  end

  def fail_if_no_remand_reasons!(issue, remand_reasons_attrs)
    if issue.disposition == "remanded" && remand_reasons_attrs.blank?
      msg = "Remand reasons are missing for a remanded issue"
      fail Caseflow::Error::AttorneyJudgeCheckoutError, message: msg
    end
  end

  def create_remand_reasons(decision_issue, remand_reasons_attrs)
    fail_if_no_remand_reasons!(decision_issue, remand_reasons_attrs)
    remand_reasons_attrs.each do |attrs|
      decision_issue.remand_reasons.find_or_initialize_by(code: attrs[:code]).tap do |record|
        record.post_aoj = attrs[:post_aoj]
        record.save!
      end
    end
  end
end
