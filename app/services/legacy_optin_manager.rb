class LegacyOptinManager
  attr_reader :decision_review

  VACOLS_DISPOSITION_CODE = "O".freeze # oh not zero

  def initialize(decision_review:)
    @decision_review = decision_review
  end

  def process!
    VACOLS::Case.transaction do
      pending_rollbacks.each do |legacy_issue_rollback|
        legacy_issue_rollback.rollback!
      end

      pending_opt_ins.each do |legacy_issue_opt_in|
        legacy_issue_opt_in.opt_in!
      end

      affected_legacy_appeals.each do |legacy_appeal|
        if legacy_appeal.issues.reject(&:closed?).empty?
          revert_opted_in_remand_issues(legacy_appeal.vacols_id) if legacy_appeal.remand?
          close_legacy_appeal_in_vacols(legacy_appeal) if legacy_appeal.active?
        end
      end
    end
  end

  private

  def affected_legacy_appeals
    legacy_appeals = []
    legacy_issue_opt_ins.each do |issue|
      legacy_appeals << legacy_appeal(issue.vacols_id)
    end
    legacy_appeals.uniq
  end

  def issues_to_be_processed
    pending_opt_ins + pending_rollbacks
  end

  def pending_opt_ins
    legacy_issue_opt_ins.select(&:opt_in_pending?)
  end

  def pending_rollbacks
    legacy_issue_opt_ins.select(&:rollback_pending?)
  end

  def legacy_issue_opt_ins
    request_issues_with_legacy_opt_ins.map(&:legacy_issue_optin)
  end

  def request_issues_with_legacy_opt_ins
    decision_review.request_issues.select(&:legacy_issue_optin)
  end

  def close_legacy_appeal_in_vacols(legacy_appeal)
    LegacyAppeal.close(
      appeals: [legacy_appeal],
      user: RequestStore.store[:current_user],
      closed_on: Time.zone.today,
      disposition: Constants::VACOLS_DISPOSITIONS_BY_ID[VACOLS_DISPOSITION_CODE]
    )
  end

  def reopen_legacy_appeal(legacy_appeal)
    LegacyAppeal.reopen(
      appeals: [legacy_appeal],
      user: RequestStore.store[:current_user],
      disposition: Constants::VACOLS_DISPOSITIONS_BY_ID[VACOLS_DISPOSITION_CODE],
      reopen_issues: false
    )
  end

  def legacy_appeal_needs_reopened?
    legacy_appeal.case_record.bfmpro == "HIS" && legacy_appeal.case_record.bfcurloc == "99"
  end

  def remand_issues(vacols_id)
    # if the appeal is ready to be closed, all issues that used to
    # have a disposition of "3" should be closed with "O" now
     # if the appeal has been closed, and is being reopened, the same
    # issues would have a disposition of "3" again

    # remand issues do not all have to be connected to the current decision review
     LegacyIssueOptin.where(
      vacols_id: vacols_id,
      original_disposition_code: "3"
    )
  end

  def revert_opted_in_remand_issues(vacols_id)
    # put all remand issues with "O" back to "3" before closing the appeal
    remand_issues(vacols_id).each do |remand_issue|
      Issue.rollback_opt_in!(remand_issue)
    end
  end

  def revert_open_remand_issues(vacols_id)
    # if this is happening, all remanded issues should have a disposition
    # of "3" on a "HIS" appeal. This is rolling back and putting them back at "O"
    remand_issues(vacols_id).each do |remand_issue|
      Issue.close_in_vacols!(
        vacols_id: vacols_id,
        vacols_sequence_id: remand_issue[0],
        disposition_code: VACOLS_DISPOSITION_CODE
      )
    end
  end

  def legacy_appeal(vacols_id)
    @legacy_appeals ||= {}
    @legacy_appeals[vacols_id] ||= LegacyAppeal.find_or_create_by_vacols_id(vacols_id)
  end
end
