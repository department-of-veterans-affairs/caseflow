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
    case request_issue.vacols_issue[:disposition_code]
    when nil
      transaction do
        close_legacy_issue_in_vacols
        close_legacy_appeal_in_vacols if legacy_appeal_needs_closing?
      end
    when '3'
      close_remanded_issue
    when *WHITELIST_DISPOSITION_CODES
      close_legacy_issue_in_vacols
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
    # depending on how we do remanded issues
    # might need to add a check for if the issue has been moved to a post remand appeal
    # in which case it would still appear active on the original appeal
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
        LegacyAppeal.reopen(
          appeals: [legacy_appeal],
          user: RequestStore.store[:current_user],
          disposition: Constants::VACOLS_DISPOSITIONS_BY_ID[VACOLS_DISPOSITION_CODE],
          reopen_issues: false
          )
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

  def close_remanded_issue
  end

  def reopen_remanded_issue
    # delete the follow-up issue, isskey is follow_up_appeal key
      # and issseq is the vacols sequence id
    # if the original appeal is in HIS status,
      # update the original appeal's attributes back to Remand stuff
    # delete the follow-up appeal if no issues
  end

  def legacy_appeal
    @legacy_appeal ||= LegacyAppeal.find_or_create_by_vacols_id(request_issue.vacols_id)
  end
end
