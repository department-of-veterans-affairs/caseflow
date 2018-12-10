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

  def opt_in_legacy_issue
    transaction do
      close_legacy_issue_in_vacols
      close_legacy_appeal_in_vacols if legacy_appeal_needs_closing?
    end
  end

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
    # if any of the issues with a disposition of "O" were remands
    # open the post-remand appeal, and convert the issue dispositions to 3
    legacy_appeal.issues.reject(&:closed?).empty?
  end

  def rollback_legacy_issue_opt_in
    case request_issue.vacols_issue[:disposition_code]
    when nil
      reopen_undecided_issue
    when '3'
      reopen_remanded_issue
    when *WHITELIST_DISPOSITION_CODES
      rollback_issue_disposition
    end
  end

  def reopen_undecided_issue
    transaction do
      rollback_issue_disposition

      if legacy_appeal.reopen_appeal_on_rollback?
        transaction do
          LegacyAppeal.reopen(
            appeals: [legacy_appeal],
            user: RequestStore.store[:current_user],
            disposition: Constants::VACOLS_DISPOSITIONS_BY_ID[VACOLS_DISPOSITION_CODE],
            reopen_issues: false
            )
        end
      end
    end
  end

  def rollback_issue_disposition
    Issue.rollback_disposition_in_vacols!(
      vacols_id: request_issue.vacols_id,
      vacols_sequence_id: request_issue.vacols_sequence_id,
      disposition_code_to_rollback: VACOLS_DISPOSITION_CODE,
      original_disposition_code: request_issue.vacols_issue[:disposition_code],
      original_disposition_date: request_issue.vacols_issue[:disposition_date]
    )
  end

  def reopen_remanded_issue
    # check if
    # put the disposition back to 3
    # reopen using the remand version of reopening
    # check if the post-remand appeal has any issues left

  end

  def legacy_appeal
    @legacy_appeal ||= LegacyAppeal.find_or_create_by_vacols_id(request_issue.vacols_id)
  end

  def legacy_issue
    
  end
end
