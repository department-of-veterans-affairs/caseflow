class IssueRepository
  class IssueCreationError < StandardError; end
  # issue_hash = {
  #   vacols_id: "1234567",
  #   program: { description: "test", code: "01" },
  #   issue: { description: "test", code: "01" },
  #   level_1: { description: "test", code: "01" },
  #   level_2: { description: "test", code: "07" },
  #   level_3: { description: "test", code: "6789" },
  #   note: "something"
  # }
  # :nocov:
  def self.create_vacols_issue(css_id, issue_hash)
    issue_hash = IssueMapper.transform_issue_hash(issue_hash)

    if find_issue_reference(program: issue_hash[:program],
                            issue: issue_hash[:issue],
                            level_1: issue_hash[:level_1],
                            level_2: issue_hash[:level_2],
                            level_3: issue_hash[:level_3]).size != 1
      fail IssueCreationError, "Combination of Vacols Issue codes is invalid: #{issue_hash}"
    end

    staff = VACOLS::Staff.find_by(sdomainid: css_id)
    fail IssueCreationError, "Cannot find user with #{css_id} in VACOLS" unless staff

    record = VACOLS::CaseIssue.create_issue!(issue_hash.merge(added_by: staff.slogid))
    fail IssueCreationError, "Issue could not be created in VACOLS: #{issue_hash[:vacols_id]}" unless record

    Issue.load_from_vacols(record.attributes)
  end

  def self.find_issue_reference(program:, issue:, level_1:, level_2:, level_3:)
    VACOLS::IssueReference.where(prog_code: program, iss_code: issue)
      .where("? is null or LEV1_CODE = '##' or LEV1_CODE = ?", level_1, level_1)
      .where("? is null or LEV2_CODE = '##' or LEV2_CODE = ?", level_2, level_2)
      .where("? is null or LEV3_CODE = '##' or LEV3_CODE = ?", level_3, level_3)
  end
  # :nocov:
end
