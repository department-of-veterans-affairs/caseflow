# frozen_string_literal: true

class LegacyIssue < ApplicationRecord
  belongs_to :request_issue
  has_one :legacy_issue_optin

  validates :request_issue, :vacols_id, :vacols_sequence_id, presence: true
  delegate :decision_review, to: :request_issue

  def create_optin!
    return unless request_issue.eligible?
    return unless eligible_for_opt_in?

    legacy_issue_optin.create!(
      original_disposition_code: vacols_issue.disposition_id,
      original_disposition_date: vacols_issue.disposition_date,
      legacy_issue: self
    )
  end

  def eligible_for_opt_in?
    vacols_issue.eligible_for_opt_in? && legacy_appeal_eligible_for_opt_in?
  end

  def vacols_issue
    @vacols_issue ||= AppealRepository.issues(vacols_id).find do |issue|
      issue.vacols_sequence_id == vacols_sequence_id
    end
  end

  def legacy_appeal_eligible_for_opt_in?
    vacols_issue.legacy_appeal.eligible_for_soc_opt_in?(decision_review.receipt_date)
  end
end
