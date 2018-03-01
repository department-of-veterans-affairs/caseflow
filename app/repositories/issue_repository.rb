class IssueRepository
  class IssueCreationError < StandardError; end
  # issue_hash = {
  #   vacols_id: "1234567",
  #   program: "01",
  #   issue: "03",
  #   level_1: "06",
  #   level_2: "##",
  #   level_3: nil,
  #   note: "something"
  # }
  # :nocov:
  def self.create_vacols_issue(css_id, issue_hash)
    # Ensure combination of ISSUE codes is valid by querying the VACOLS.ISSREF table
    issue_reference = VACOLS::IssueReference.find_by(
      prog_code: issue_hash[:program],
      iss_code: issue_hash[:issue],
      lev1_code: issue_hash[:level_1],
      lev2_code: issue_hash[:level_2],
      lev3_code: issue_hash[:level_3]
    )
    fail IssueCreationError, "Combination of Vacols Issue codes is invalid" unless issue_reference

    staff = VACOLS::Staff.find_by(sdomainid: css_id)
    fail IssueCreationError, "Cannot find user with #{css_id} in VACOLS" unless staff

    record = VACOLS::CaseIssue.create_issue!(issue_hash.merge(added_by: staff.slogid))
    fail IssueCreationError, "Issue could not be created in VACOLS: #{issue_hash[:vacols_id]}" unless record

    Issue.load_from_vacols(record.attributes)
  end
  # :nocov:
end
