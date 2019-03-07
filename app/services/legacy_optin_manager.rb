# frozen_string_literal: true

# LegacyOptInManager processes opt-ins and rollbacks in a batch per DecisionReview
# because whether a legacy_appeal needs closed depends on the state of all issues after processing
class LegacyOptinManager
  attr_reader :decision_review

  def initialize(decision_review:)
    @decision_review = decision_review
  end

  def process!
    VACOLS::Case.transaction do
      ApplicationRecord.transaction do
        pending_rollbacks.each(&:rollback!)

        pending_opt_ins.each(&:opt_in!)

        affected_legacy_appeals.each do |legacy_appeal|
          if legacy_appeal.issues.reject(&:closed?).empty?
            LegacyIssueOptin.revert_opted_in_remand_issues(legacy_appeal.vacols_id) if legacy_appeal.remand?
            LegacyIssueOptin.close_legacy_appeal_in_vacols(legacy_appeal) if legacy_appeal.active?
          end
        end
      end
    end
  end

  private

  def affected_legacy_appeals
    legacy_issue_opt_ins.map(&:legacy_appeal).uniq
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
end
