# frozen_string_literal: true

class RequestIssueCorrectionCleaner
  def initialize(correction_request_issue)
    @correction_request_issue = correction_request_issue
  end

  delegate :contested_decision_issue, :correction?, to: :correction_request_issue

  # Close the incorrectly added request issue from that DTA supplemental claim,
  # remove contention in VBMS and cancel EP
  def remove_dta_request_issue!
    return unless correction?
    return unless request_issue_to_remove

    RequestIssueClosure.new(request_issue_to_remove).remove_issue_with_corrected_decision!
  end

  private

  attr_reader :correction_request_issue

  def request_issue_to_remove
    @request_issue_to_remove ||= begin
      request_issue = contested_decision_issue&.contesting_remand_request_issue

      request_issue unless request_issue == correction_request_issue
    end
  end
end
