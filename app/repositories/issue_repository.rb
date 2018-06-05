class IssueRepository
  # :nocov:
  def self.create_vacols_issue!(issue_attrs:)
    MetricsService.record("VACOLS: create_vacols_issue for #{issue_attrs[:vacols_id]}",
                          service: :vacols,
                          name: "create_vacols_issue") do
      issue_attrs = IssueMapper.rename_and_validate_vacols_attrs(
        action: :create,
        issue_attrs: issue_attrs
      )

      VACOLS::CaseIssue.create_issue!(issue_attrs)
    end
  end

  def self.update_vacols_issue!(vacols_id:, vacols_sequence_id:, issue_attrs:)
    MetricsService.record("VACOLS: update_vacols_issue for vacols ID #{vacols_id} and sequence: #{vacols_sequence_id}",
                          service: :vacols,
                          name: "update_vacols_issue") do
      record = validate_issue_presence!(vacols_id, vacols_sequence_id)

      perform_actions_if_disposition_changes(
        record,
        issue_attrs.merge(vacols_id: vacols_id, vacols_sequence_id: vacols_sequence_id)
      )

      issue_attrs = IssueMapper.rename_and_validate_vacols_attrs(
        action: :update,
        issue_attrs: issue_attrs
      )
      VACOLS::CaseIssue.update_issue!(vacols_id, vacols_sequence_id, issue_attrs)
    end
  end

  def self.delete_vacols_issue!(vacols_id:, vacols_sequence_id:)
    MetricsService.record("VACOLS: delete_vacols_issue for vacols ID #{vacols_id} and sequence: #{vacols_sequence_id}",
                          service: :vacols,
                          name: "delete_vacols_issue") do
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

  def self.create_remand_reasons!(vacols_id, vacols_sequence_id, remand_reasons)
    VACOLS::RemandReason.create_remand_reasons!(vacols_id, vacols_sequence_id, remand_reasons)
  end

  def self.update_remand_reasons!(vacols_id, vacols_sequence_id, remand_reasons)
    VACOLS::RemandReason.update_remand_reasons!(vacols_id, vacols_sequence_id, remand_reasons)
  end

  def self.delete_remand_reasons!(vacols_id, vacols_sequence_id)
    VACOLS::RemandReason.delete_remand_reasons!(vacols_id, vacols_sequence_id)
  end

  def self.load_remands_from_vacols(vacols_id, vacols_sequence_id)
    VACOLS::RemandReason.load_remand_reasons(vacols_id, vacols_sequence_id).map do |reason|
      {
        code: reason.rmdval,
        after_certification: reason.rmddev.eql?("R2")
      }
    end
  end
  # :nocov:

  def self.perform_actions_if_disposition_changes(record, issue_attrs)
    case Constants::VACOLS_DISPOSITIONS_BY_ID[issue_attrs[:disposition]]
    when "Vacated"
      if record.issdc != "5" && issue_attrs[:readjudication]
        create_vacols_issue!(issue_attrs: record.attributes_for_readjudication.merge(
          vacols_user_id: issue_attrs[:vacols_user_id]
        ))
      end
    when nil
      # We only want to track non-disposition edits
      BusinessMetrics.record(service: :queue, name: "non_disposition_issue_edit")
    end

    update_remand_reasons(record, issue_attrs)
  end

  def self.update_remand_reasons(record, issue_attrs)
    args = [issue_attrs[:vacols_id], issue_attrs[:vacols_sequence_id]]

    unless issue_attrs[:disposition].eql? "Remanded"
      delete_remand_reasons!(*args)
      return
    end

    remand_reasons = RemandReasonMapper.convert_to_vacols_format(
      issue_attrs[:vacols_user_id],
      issue_attrs[:remand_reasons]
    )
    args.push(remand_reasons)

    if record.issdc.eql? "3"
      update_remand_reasons!(*args)
    else
      create_remand_reasons!(*args)
    end
  end
end
