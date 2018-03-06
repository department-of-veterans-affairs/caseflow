class IssueRepository
  class IssueError < StandardError; end
  # :nocov:
  # issue_hash = {
  #   vacols_id: "1234567",
  #   program: { description: "test", code: "01" },
  #   issue: { description: "test", code: "01" },
  #   level_1: { description: "test", code: "01" },
  #   level_2: { description: "test", code: "07" },
  #   level_3: { description: "test", code: "6789" },
  #   note: "something"
  # }
  def self.create_vacols_issue(css_id:, issue_hash:)
    issue_hash = IssueMapper.transform_and_validate(issue_hash)
    staff = find_staff_record(css_id)

    record = VACOLS::CaseIssue.create_issue!(issue_hash.merge(added_by: staff.slogid))
    fail IssueError, "Issue could not be created in VACOLS: #{issue_hash[:vacols_id]}" unless record

    Issue.load_from_vacols(record.attributes)
  end

  # issue_hash = {
  #   program: { description: "test", code: "01" },
  #   issue: { description: "test", code: "01" },
  #   level_1: { description: "test", code: "01" },
  #   level_2: { description: "test", code: "07" },
  #   level_3: { description: "test", code: "6789" },
  #   note: "something"
  # }
  def self.update_vacols_issue(css_id:, vacols_id:, vacols_sequence_id:, issue_hash:)
    record = VACOLS::CaseIssue.find_by(isskey: vacols_id, issseq: vacols_sequence_id)

    unless record
      fail IssueError, "Cannot find issue with vacols ID: #{vacols_id} and sequence ID: #{vacols_sequence_id} in VACOLS"
    end

    issue_hash = IssueMapper.transform_and_validate(issue_hash)
    staff = find_staff_record(css_id)

    record.update_issue!(issue_hash.merge(updated_by: staff.slogid))
    Issue.load_from_vacols(record.attributes)
  end

  def self.find_staff_record(css_id)
    staff = VACOLS::Staff.find_by(sdomainid: css_id)
    fail IssueError, "Cannot find user with #{css_id} in VACOLS" unless staff
    staff
  end

  def self.find_issue_reference(program:, issue:, level_1:, level_2:, level_3:)
    VACOLS::IssueReference.where(prog_code: program, iss_code: issue)
      .where("? is null or LEV1_CODE = '##' or LEV1_CODE = ?", level_1, level_1)
      .where("? is null or LEV2_CODE = '##' or LEV2_CODE = ?", level_2, level_2)
      .where("? is null or LEV3_CODE = '##' or LEV3_CODE = ?", level_3, level_3)
  end
  # :nocov:
end
