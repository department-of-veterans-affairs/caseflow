# frozen_string_literal: true

class RequestIssueClosure < SimpleDelegator
  alias request_issue __getobj__

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
end
