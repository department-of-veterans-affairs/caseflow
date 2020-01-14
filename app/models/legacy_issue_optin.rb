# frozen_string_literal: true

class LegacyIssueOptin < ApplicationRecord
  belongs_to :request_issue
  belongs_to :legacy_issue

  VACOLS_DISPOSITION_CODE = "O" # oh not zero
  REMAND_DISPOSITION_CODES = %w[3 L].freeze

  delegate :vacols_id, :vacols_id=, :vacols_sequence_id, :vacols_sequence_id=, to: :request_issue

  class << self
    def related_remand_issues(vacols_id)
      joins(:request_issue)
        .where("request_issues.vacols_id = ?", vacols_id)
        .where(original_disposition_code: REMAND_DISPOSITION_CODES)
    end

    def revert_opted_in_remand_issues(vacols_id)
      # put all remand issues with "O" back to "3" before closing the appeal
      related_remand_issues(vacols_id).each do |remand_issue|
        Issue.rollback_opt_in!(remand_issue)
      end
    end

    def close_legacy_appeal_in_vacols(legacy_appeal)
      LegacyAppeal.close(
        appeals: [legacy_appeal],
        user: RequestStore.store[:current_user],
        closed_on: Time.zone.today,
        disposition: Constants::VACOLS_DISPOSITIONS_BY_ID[VACOLS_DISPOSITION_CODE]
      )
    end
  end

  def opt_in!
    Issue.close_in_vacols!(
      vacols_id: vacols_id,
      vacols_sequence_id: vacols_sequence_id,
      disposition_code: VACOLS_DISPOSITION_CODE
    )
    update!(optin_processed_at: Time.zone.now)
  end

  def flag_for_rollback!
    update!(rollback_created_at: Time.zone.now)
  end

  def rollback!
    reopen_legacy_appeal if legacy_appeal_needs_to_be_reopened?
    revert_open_remand_issues if legacy_appeal.remand?
    rollback_issue_disposition
  end

  def rollback_issue_disposition
    Issue.rollback_opt_in!(self)
    update!(rollback_processed_at: Time.zone.now)
  end

  def opt_in_pending?
    !optin_processed_at
  end

  def rollback_pending?
    rollback_created_at && !rollback_processed_at
  end

  def legacy_appeal
    LegacyAppeal.find_or_create_by_vacols_id(vacols_id)
  end

  private

  def revert_open_remand_issues
    # Before a remand is closed, it's "O" dispositions are changed to a "3", so when it's re-opened
    # the "3"s should be reverted back to "O"s
    self.class.related_remand_issues(vacols_id).each do |remand_issue|
      Issue.close_in_vacols!(
        vacols_id: vacols_id,
        vacols_sequence_id: remand_issue.vacols_sequence_id,
        disposition_code: VACOLS_DISPOSITION_CODE
      )
    end
  end

  def legacy_appeal_needs_to_be_reopened?
    return false unless (REMAND_DISPOSITION_CODES.include? original_disposition_code) || original_disposition_code.nil?

    !legacy_appeal.active?
  end

  def reopen_legacy_appeal
    LegacyAppeal.reopen(
      appeals: [legacy_appeal],
      user: RequestStore.store[:current_user],
      disposition: Constants::VACOLS_DISPOSITIONS_BY_ID[VACOLS_DISPOSITION_CODE],
      reopen_issues: false
    )
  end
end
