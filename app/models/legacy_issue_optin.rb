class LegacyIssueOptin < ApplicationRecord
  include Asyncable

  belongs_to :request_issue

  enum action: {
    opt_in: "opt_in",
    rollback: "rollback"
  }

  VACOLS_DISPOSITION_CODE = "O".freeze # oh not zero

  def perform!
    attempted!
    record_previous_disposition
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

  def record_previous_disposition
    # previous_appeal also saved for future-proofing
    update!(
      previous_appeal: legacy_appeal.serialize_for_opt_in,
      previous_disposition_code: legacy_issue.disposition_id,
      previous_disposition_date: legacy_issue.disposition_date
    )
  end

  def opt_in_legacy_issue
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
        if legacy_appeal.remand? # Can I ensure that legacy_appeal gets reloaded after reopen?
          revert_open_remand_issues
        end
      end
      rollback_issue_disposition
    end
  end

  def close_legacy_issue_in_vacols
    Issue.close_in_vacols!(
      vacols_id: vacols_id,
      vacols_sequence_id: vacols_sequence_id,
      disposition_code: VACOLS_DISPOSITION_CODE
    )
  end

  def rollback_issue_disposition
    Issue.rollback_disposition_in_vacols!(
      vacols_id: vacols_id,
      vacols_sequence_id: vacols_sequence_id,
      disposition_code_to_rollback: VACOLS_DISPOSITION_CODE,
      original_disposition_code: original_disposition_code,
      original_disposition_date: original_disposition_date
    )
  end

  def original_disposition_code
    LegacyIssueOptin.find_by(request_issue_id: request_issue_id, action: :opt_in).previous_disposition_code
  end

  def original_disposition_date
    LegacyIssueOptin.find_by(request_issue_id: request_issue_id, action: :opt_in).previous_disposition_date
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
    legacy_appeal.active? && legacy_appeal.issues.reject(&:closed?).empty?
  end

  def legacy_appeal_needs_reopened?
    legacy_appeal.case_record.bfmpro == "HIS" && legacy_appeal.case_record.bfcurloc == "99"
  end

  def remanded_issues
    # if the appeal is ready to be closed, all issues that used to
    # have a disposition of "3" should be closed with "O" now

    # if the appeal has been closed, and is being reopened, the same
    # issues would have a disposition of "3" again

    LegacyIssueOptin.where(
      vacols_id: vacols_id,
      previous_disposition_code: "3"
    ).pluck(:vacols_sequence_id, :previous_disposition_date).uniq
  end

  def revert_closed_remand_issues
    # put all remand issues with "O" back to "3"
    remanded_issues.each do |remand_issue|
      Issue.rollback_disposition_in_vacols!(
        vacols_id: vacols_id,
        vacols_sequence_id: remand_issue[0],
        disposition_code_to_rollback: VACOLS_DISPOSITION_CODE,
        original_disposition_code: "3",
        original_disposition_date: remand_issue[1]
      )
    end
  end

  def revert_open_remand_issues
    # if this is happening, all remanded issues should have a disposition
    # of "3" on a "HIS" appeal. This is rolling back and putting them back at "O"
    remanded_issues.each do |remand_issue|
      Issue.close_in_vacols!(
        vacols_id: vacols_id,
        vacols_sequence_id: remand_issue[0],
        disposition_code: VACOLS_DISPOSITION_CODE
      )
    end
  end

  def legacy_appeal
    @legacy_appeal ||= LegacyAppeal.find_or_create_by_vacols_id(vacols_id)
  end

  def legacy_issue
    request_issue.vacols_issue
  end
end
