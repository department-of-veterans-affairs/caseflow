class IssueRepository
  class IssueError < StandardError; end

  # :nocov:
  def self.create_vacols_issue!(css_id:, issue_attrs:)
    validate_access!(css_id, issue_attrs[:vacols_id])

    issue_attrs = IssueMapper.rename_and_validate_vacols_attrs(
      slogid: slogid_based_on_css_id(css_id),
      action: :create,
      issue_attrs: issue_attrs
    )

    VACOLS::CaseIssue.create_issue!(issue_attrs)
  end

  def self.update_vacols_issue!(css_id:, vacols_id:, vacols_sequence_id:, issue_attrs:)
    validate_access!(css_id, vacols_id)
    validate_issue_presence!(vacols_id, vacols_sequence_id)

    issue_attrs = IssueMapper.rename_and_validate_vacols_attrs(
      slogid: slogid_based_on_css_id(css_id),
      action: :update,
      issue_attrs: issue_attrs
    )

    VACOLS::CaseIssue.update_issue!(vacols_id, vacols_sequence_id, issue_attrs)
  end

  def self.delete_vacols_issue!(css_id:, vacols_id:, vacols_sequence_id:)
    validate_access!(css_id, vacols_id)
    validate_issue_presence!(vacols_id, vacols_sequence_id)

    VACOLS::CaseIssue.delete_issue!(vacols_id, vacols_sequence_id)
  end

  def self.validate_issue_presence!(vacols_id, vacols_sequence_id)
    record = VACOLS::CaseIssue.find_by(isskey: vacols_id, issseq: vacols_sequence_id)

    unless record
      msg = "Cannot find issue with vacols ID: #{vacols_id} and sequence ID: #{vacols_sequence_id} in VACOLS"
      fail IssueError, msg
    end
  end

  def self.validate_access!(css_id, vacols_id)
    unless QueueRepository.can_access_task?(css_id, vacols_id)
      fail IssueError, "Current user #{css_id} cannot access task with vacols ID: #{vacols_id}"
    end
  end

  def self.slogid_based_on_css_id(css_id)
    staff = VACOLS::Staff.find_by(sdomainid: css_id)
    fail IssueError, "Cannot find user with #{css_id} in VACOLS" unless staff
    staff.slogid
  end

  def self.find_issue_reference(program:, issue:, level_1:, level_2:, level_3:)
    VACOLS::IssueReference.where(prog_code: program, iss_code: issue)
      .where("? is null or LEV1_CODE = '##' or LEV1_CODE = ?", level_1, level_1)
      .where("? is null or LEV2_CODE = '##' or LEV2_CODE = ?", level_2, level_2)
      .where("? is null or LEV3_CODE = '##' or LEV3_CODE = ?", level_3, level_3)
  end
  # :nocov:
end
