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
    update!(original_appeal: legacy_appeal.serialize)

    case action
    when :opt_in
      close_legacy_issue_in_vacols
      close_legacy_appeal_in_vacols if legacy_appeal_needs_closing?
    when :rollback
      reopen_legacy_issue_in_vacols
    end

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
    # maybe need to add a check for if the issue has been moved to a post remand appeal
    # in which case it would still appear active on the original appeal
    legacy_appeal.issues.reject(&:closed?).empty?
  end

  def reopen_legacy_issue_in_vacols
    case request_issue.vacols_disposition_code
    when nil
      reopen_undecided_legacy_issue_in_vacols
    when '3'
      reopen_remanded_legacy_issue_in_vacols
    when *WHITELIST_DISPOSITION_CODES
      reopen_whitelist_legacy_issue_in_vacols
    end
  end

  def reopen_undecided_legacy_issue_in_vacols
    # check that it has a disposition of "O" as a safeguard?
    transaction do
      Issue.update_in_vacols!(
        vacols_id: request_issue.vacols_id,
        vacols_sequence_id: request_issue.vacols_sequence_id,
        issue_attrs: {
          disposition: nil,
          disposition_date: nil,
        }
      )

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

  def reopen_whitelist_legacy_issue_in_vacols
    Issue.update_in_vacols!(
      vacols_id: request_issue.vacols_id,
      vacols_sequence_id: request_issue.vacols_sequence_id,
      issue_attrs: {
        disposition: request_issue.vacols_disposition_code,
        disposition_date: nil,
      }
    )
  end

  def reopen_remanded_legacy_issue_in_vacols
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
