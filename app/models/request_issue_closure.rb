# frozen_string_literal: true

class RequestIssueClosure
  def initialize(request_issue)
    @request_issue = request_issue
  end

  delegate :closed_at, :end_product_establishment, :contention_reference_id,
           :legacy_issue_optin, :contention_disposition, :cancelled!, :close!, to: :request_issue

  def with_no_decision!
    return unless end_product_establishment&.status_cleared?
    return if contention_disposition

    close!(status: :no_decision) do
      cancelled!
      legacy_issue_optin&.flag_for_rollback!
    end
  end

  private

  attr_reader :request_issue
end
