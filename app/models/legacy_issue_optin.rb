class LegacyIssueOptin < ApplicationRecord
  include Asyncable

  belongs_to :request_issue

  VACOLS_DISPOSITION_CODE = "O".freeze # oh not zero

  def perform!
    attempted!
    close_legacy_issue_in_vacols
    close_legacy_appeal_in_vacols if legacy_appeal_needs_closing?
    clear_error!
    processed!
  end

  private

  def close_legacy_issue_in_vacols
    Issue.close_in_vacols!(
      vacols_id: request_issue.vacols_id,
      vacols_sequence_id: request_issue.vacols_sequence_id,
      disposition_code: VACOLS_DISPOSITION_CODE
    )
  end

  def close_legacy_appeal_in_vacols
    LegacyAppeal.close(
      appeals: [legacy_appeal],
      user: RequestStore.store[:current_user],
      closed_on: Time.zone.today,
      disposition: Constants::VACOLS_DISPOSITIONS_BY_ID[VACOLS_DISPOSITION_CODE]
    )
  end

  def legacy_appeal_needs_closing?
    # if all the issues are closed, the appeal should be closed.
    legacy_appeal.issues.reject(&:closed?).empty?
  end

  def legacy_appeal
    @legacy_appeal ||= LegacyAppeal.find_or_create_by_vacols_id(request_issue.vacols_id)
  end
end
