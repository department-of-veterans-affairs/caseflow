class IssueRepository
  class IssueError < StandardError; end

  # :nocov:
  def self.create_vacols_issue!(css_id:, issue_attrs:)
    validate_access(css_id, issue_attrs[:vacols_id])

    issue_attrs = IssueMapper.rename_and_validate_vacols_attrs(issue_attrs)
    staff = find_staff_record(css_id)

    record = VACOLS::CaseIssue.create_issue!(issue_attrs.merge(issaduser: staff.slogid))

    Issue.load_from_vacols(record.attributes)
  end

  def self.update_vacols_issue!(css_id:, vacols_id:, vacols_sequence_id:, issue_attrs:)
    validate_access(css_id, vacols_id)

    record = VACOLS::CaseIssue.find_by(isskey: vacols_id, issseq: vacols_sequence_id)

     unless record
      msg = "Cannot find issue with vacols ID: #{vacols_id} and sequence ID: #{vacols_sequence_id} in VACOLS"
      fail IssueError, msg
    end

    issue_attrs = IssueMapper.rename_and_validate_vacols_attrs(issue_attrs)
    staff = find_staff_record(css_id)

    record.update_issue!(issue_attrs.merge(issmduser: staff.slogid))

    Issue.load_from_vacols(record.attributes)
  end

  def self.delete_vacols_issue!(css_id:, vacols_id:, vacols_sequence_id:)
    validate_access(css_id, vacols_id)

    record = VACOLS::CaseIssue.find_by(isskey: vacols_id, issseq: vacols_sequence_id)

    unless record
      msg = "Cannot find issue with vacols ID: #{vacols_id} and sequence ID: #{vacols_sequence_id} in VACOLS"
      fail IssueError, msg
    end

    record.delete_issue!
  end

  def self.validate_access(css_id, vacols_id)
    unless QueueRepository.can_access_task?(css_id, vacols_id)
      fail IssueError, "Current user cannot access task with vacols ID: #{vacols_id}"
    end
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
