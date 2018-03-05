class IssueRepository
  class IssueCreationError < StandardError; end
  # issue_hash = {
  #   vacols_id: "1234567",
  #   program: { description: "test", code: "01" },
  #   issue: { description: "test", code: "01" },
  #   level_1: { description: "test", code: "01" },
  #   level_2: { description: "test", code: "4567" },
  #   level_3: { description: "test", code: "6789" },
  #   note: "something"
  # }
  # :nocov:
  def self.create_vacols_issue(css_id, issue_hash)
    issue_hash = IssueMapper.transform_issue_hash(issue_hash)

    validate_issue_codes(issue_hash)

    staff = VACOLS::Staff.find_by(sdomainid: css_id)
    fail IssueCreationError, "Cannot find user with #{css_id} in VACOLS" unless staff

    record = VACOLS::CaseIssue.create_issue!(issue_hash.merge(added_by: staff.slogid))
    fail IssueCreationError, "Issue could not be created in VACOLS: #{issue_hash[:vacols_id]}" unless record

    Issue.load_from_vacols(record.attributes)
  end

  def self.find_issue_reference(program, issue, level_1)
    VACOLS::IssueReference.where(
      prog_code: program,
      iss_code: issue,
      lev1_code: level_1
    )
  end
  # :nocov:

  def self.validate_issue_codes(issue_hash)
    # Ensure combination of PROGAM, ISSUE and LEVEL_1 codes is valid by querying the VACOLS.ISSREF table
    if find_issue_reference(issue_hash[:program], issue_hash[:issue], issue_hash[:level_1]).empty?
      fail IssueCreationError, "Combination of Vacols Issue codes is invalid: #{issue_hash}"
    end

    # Level 2 can be:
    # a) nil
    # b) any number from: ["01", "02", "03", "04", "05", "06", "07"]
    # c) 4-digit number
    if issue_hash[:level_2] && issue_hash[:level_2] !~ /\A[0-9]{4}|0[1-7]{1}\Z/i
      fail IssueCreationError, "Level 2 is invalid: #{issue_hash[:level_2]}"
    end

    # Level 3 can be:
    # a) nil
    # b) 4-digit number
    if issue_hash[:level_3] && issue_hash[:level_3] !~ /\A[0-9]{4}\Z/i
      fail IssueCreationError, "Level 3 is invalid: #{issue_hash[:level_3]}"
    end
  end
end
