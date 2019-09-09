# frozen_string_literal: true

class RequestIssueClosure
  def initialize(request_issue)
    @request_issue = request_issue
  end

  delegate :closed_at, :end_product_establishment, :contention_reference_id,
           :legacy_issue_optin, :contention_disposition, :canceled!, :close!, to: :request_issue

  def with_no_decision!
    return unless end_product_establishment&.status_cleared?
    return if contention_disposition

    close!(status: :no_decision) do
      canceled!
      legacy_issue_optin&.flag_for_rollback!
    end
  end

  def remove_issue_with_corrected_decision!
    close!(status: :removed) do
      canceled!
      RequestIssueContention.new(request_issue).remove!
      request_issue.end_product_establishment&.cancel_unused_end_product!
    end
  end

  private

  attr_reader :request_issue
end
