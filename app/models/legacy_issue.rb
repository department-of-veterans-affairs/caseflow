# frozen_string_literal: true

##
# Veterans may submit request issues on an AMA form that are already active issues on Legacy Appeals.  The user intaking the form tries to find matching legacy issues when adding a request issue, and if they find a match they connect the two.  One request issue can be connected to multiple legacy issues. If a match is found and the veteran did not select to opt their legacy issues into AMA, or the issue is not eligible to be opted into AMA, then the request issue is ineligible.  If it is eligible, an opt-in is created, which closes the issue in VACOLS so that it can continue to be processed only in AMA.

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
