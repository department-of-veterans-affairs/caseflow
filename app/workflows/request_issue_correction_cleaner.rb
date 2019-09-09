# frozen_string_literal: true

class RequestIssueCorrectionCleaner
  def initialize(correction_request_issue)
    @correction_request_issue = correction_request_issue
  end

  # Close the incorrectly added request issue from that DTA supplemental claim,
  # remove contention in VBMS and cancel EP
  def remove_dta_request_issue!
    return unless correction_request_issue.correction?
    return unless request_issue_to_remove

    request_issue_to_remove.remove!
    RequestIssueContention.new(request_issue_to_remove).remove!
    request_issue_to_remove.end_product_establishment&.cancel_unused_end_product!
  end

  private

  attr_reader :correction_request_issue

  def request_issue_to_remove
    @request_issue_to_remove ||= correction_request_issue.contested_decision_issue.contesting_remand_request_issue
  end
end
