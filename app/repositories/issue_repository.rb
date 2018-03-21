class IssueRepository
  # :nocov:
  def self.create_vacols_issue!(issue_attrs:)
    MetricsService.record("VACOLS: create_vacols_issue! for #{issue_attrs[:vacols_id]}",
                          service: :vacols,
                          name: "IssueRepository.create_vacols_issue!") do
      issue_attrs = IssueMapper.rename_and_validate_vacols_attrs(
        action: :create,
        issue_attrs: issue_attrs
      )

      VACOLS::CaseIssue.create_issue!(issue_attrs)
    end
  end

  def self.update_vacols_issue!(vacols_id:, vacols_sequence_id:, issue_attrs:)
    MetricsService.record("VACOLS: update_vacols_issue! for vacols ID #{vacols_id} and sequence: #{vacols_sequence_id}",
                          service: :vacols,
                          name: "IssueRepository.update_vacols_issue!") do
      record = validate_issue_presence!(vacols_id, vacols_sequence_id)

      perform_actions_if_disposition_changes(record, issue_attrs)

      issue_attrs = IssueMapper.rename_and_validate_vacols_attrs(
        action: :update,
        issue_attrs: issue_attrs
      )

      VACOLS::CaseIssue.update_issue!(vacols_id, vacols_sequence_id, issue_attrs)
    end
  end

  def self.delete_vacols_issue!(vacols_id:, vacols_sequence_id:)
    MetricsService.record("VACOLS: delete_vacols_issue! for vacols ID #{vacols_id} and sequence: #{vacols_sequence_id}",
                          service: :vacols,
                          name: "IssueRepository.delete_vacols_issue!") do
      validate_issue_presence!(vacols_id, vacols_sequence_id)

      VACOLS::CaseIssue.delete_issue!(vacols_id, vacols_sequence_id)
    end
  end

  def self.validate_issue_presence!(vacols_id, vacols_sequence_id)
    record = VACOLS::CaseIssue.find_by(isskey: vacols_id, issseq: vacols_sequence_id)

    unless record
      msg = "Cannot find issue with vacols ID: #{vacols_id} and sequence ID: #{vacols_sequence_id} in VACOLS"
      fail Caseflow::Error::IssueRepositoryError, msg
    end
    record
  end

  def self.find_issue_reference(program:, issue:, level_1:, level_2:, level_3:)
    VACOLS::IssueReference.where(prog_code: program, iss_code: issue)
      .where("? is null or LEV1_CODE = '##' or LEV1_CODE = ?", level_1, level_1)
      .where("? is null or LEV2_CODE = '##' or LEV2_CODE = ?", level_2, level_2)
      .where("? is null or LEV3_CODE = '##' or LEV3_CODE = ?", level_3, level_3)
  end
  # :nocov:

  def self.perform_actions_if_disposition_changes(record, issue_attrs)
    case issue_attrs[:disposition]
    when "Remanded"
      # do stuff
    when "Vacated"
      create_vacols_issue!(issue_attrs: record.attributes_for_readjudication.merge(
        vacols_user_id: issue_attrs[:vacols_user_id])) if record.issdc != "5" && issue_attrs[:readjudication]
    end
  end
end
