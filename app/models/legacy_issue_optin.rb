class LegacyIssueOptin < ApplicationRecord
  include Asyncable

  belongs_to :request_issue

  enum action: {
    opt_in: "opt_in",
    rollback: "rollback"
  }

  VACOLS_DISPOSITION_CODE = "O".freeze # oh not zero
  WHITELIST_DISPOSITION_CODES = ['G', 'X'].freeze

  def perform!
    attempted!
    update!(original_appeal: legacy_appeal.serialize) # pseudocode

    case action
    when :opt_in
      opt_in_legacy_issue
    when :rollback
      rollback_legacy_issue_opt_in
    end

    clear_error!
    processed!
  end

  private

  def record_original_disposition
    update!(
      original_disposition_code: legacy_issue.disposition_id,
      original_disposition_date: legacy_issue.disposition_date
    )
  end

  def opt_in_legacy_issue
    record_original_disposition
    transaction do
      close_legacy_issue_in_vacols

      if legacy_appeal_needs_closing?
        if legacy_appeal.remand?
          revert_closed_remand_issues
        end
        close_legacy_appeal_in_vacols
      end
    end
  end

  def rollback_legacy_issue_opt_in
    transaction do
      if legacy_appeal_needs_reopened?
        reopen_legacy_appeal
        if legacy_appeal.remand? # Can I ensure that this gets reloaded?
          revert_open_remand_issues
        end
      end
      rollback_issue_disposition
    end
  end

  def close_legacy_issue_in_vacols
    Issue.close_in_vacols!(
      vacols_id: request_issue.vacols_id,
      vacols_sequence_id: request_issue.vacols_sequence_id,
      disposition_code: VACOLS_DISPOSITION_CODE
    )
  end

  def rollback_issue_disposition
    Issue.rollback_disposition_in_vacols!(
      vacols_id: request_issue.vacols_id,
      vacols_sequence_id: request_issue.vacols_sequence_id,
      disposition_code_to_rollback: VACOLS_DISPOSITION_CODE,
      original_disposition_code: original_disposition_code,
      original_disposition_date: original_disposition_date
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

  def reopen_legacy_appeal
    LegacyAppeal.reopen(
      appeals: [legacy_appeal],
      user: RequestStore.store[:current_user],
      disposition: Constants::VACOLS_DISPOSITIONS_BY_ID[VACOLS_DISPOSITION_CODE],
      reopen_issues: false
      )
  end

  def legacy_appeal_needs_closing?
    # if all the issues are closed, the appeal should be closed.
    # if any of the issues with a disposition of "O" were remands
    # open the post-remand appeal, and convert the issue dispositions to 3
    legacy_appeal.active? && legacy_appeal.issues.reject(&:closed?).empty?
  end

  def legacy_appeal_needs_reopened?
    legacy_appeal.case_record.bfmpro == "HIS" && legacy_appeal.case_record.bfcurloc == "99"
  end

  def revert_closed_remand_issues
    # put all remand issues with "O" back to "3"
  end

  def revert_open_remand_issues
    # put all remand issues with "3" back to "O"
  end

  def legacy_appeal
    @legacy_appeal ||= LegacyAppeal.find_or_create_by_vacols_id(request_issue.vacols_id)
  end

  def legacy_issue
    request_issue.vacols_issue
  end
end
