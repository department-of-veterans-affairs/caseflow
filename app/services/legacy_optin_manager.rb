class LegacyOptinManager
  attr_reader :decision_review

  VACOLS_DISPOSITION_CODE = "O".freeze # oh not zero

  def initialize(decision_review:)
    @decision_review = decision_review
  end

  # we operate on LegacyIssueOptin rows, within a single VACOLS transaction
  def close!
    VACOLS::Case.transaction do
      affected_legacy_appeals.each do |legacy_appeal|
        # track which issues we close during this transaction
        open_legacy_issues = legacy_appeal.issues.reject(&:closed?)

        # loop through each issue on the appeal, gut check on whether it can be closed,
        # and then close it.
        request_issues_with_legacy_issues do |request_issue|
          vacols_id = request_issue.vacols_id # TODO get from legacy_issue_optin
          vacols_sequence_id = request_issue.vacols_sequence_id

          # filter out any not on this appeal
          next unless vacols_id == legacy_appeal.vacols_id

          # gut checks
          unless open_legacy_issues.map(&:vacols_sequence_id).include?(vacols_sequence_id)
            fail "VACOLS issue #{vacols_id} sequence #{vacols_sequence_id} is already closed"
          end

          # TODO how to handle multiples?
          if request_issue.legacy_issue_optins.count > 1
            fail "Can't yet handle multiple legacy_issue_optins for #{request_issue}"
          end

          # close it
          close_legacy_issue_in_vacols(request_issue.legacy_issue_optins.first)

          # pop it from our queue
          open_legacy_issues.reject! { |issue| issue.vacols_sequence_id == vacols_sequence_id }
        end

        # if open_legacy_issues is now empty, close the appeal
        if open_legacy_issues.empty?
          close_legacy_appeal_in_vacols(legacy_appeal)
        end
      end
    end
  end

  private

  def affected_legacy_appeals
    legacy_appeals = []
    request_issues_with_legacy_issues.each do |request_issue|
      legacy_appeals << legacy_appeal(request_issue.vacols_id) # TODO get from legacy_issue_optin
    end
    legacy_appeals.uniq
  end

  def request_issues_with_legacy_issues
    decision_review.request_issues.select { |reqi| reqi.legacy_issue_optins.any? }
  end

  def close_legacy_issue_in_vacols(legacy_issue_optin)
    Issue.close_in_vacols!(
      vacols_id: legacy_issue_optin.request_issue.vacols_id, # TODO move column to legacy_issue_optin
      vacols_sequence_id: legacy_issue_optin.request_issue.vacols_sequence_id, # TODO move column to legacy_issue_optin
      disposition_code: VACOLS_DISPOSITION_CODE
    )
  end

  def close_legacy_appeal_in_vacols(legacy_appeal)
    LegacyAppeal.close(
      appeals: [legacy_appeal],
      user: RequestStore.store[:current_user],
      closed_on: Time.zone.today,
      disposition: Constants::VACOLS_DISPOSITIONS_BY_ID[VACOLS_DISPOSITION_CODE]
    )
  end

  def legacy_appeal(vacols_id)
    @legacy_appeals ||= {}
    @legacy_appeals[vacols_id] ||= LegacyAppeal.find_or_create_by_vacols_id(vacols_id)
  end
end
