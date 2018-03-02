class QueueRepository
  class ReassignCaseToJudgeError < StandardError; end
  # :nocov:
  def self.tasks_for_user(css_id)
    MetricsService.record("VACOLS: fetch user tasks",
                          service: :vacols,
                          name: "tasks_for_user") do
      tasks_query(css_id)
    end
  end

  def self.appeals_from_tasks(tasks)
    vacols_ids = tasks.map(&:vacols_id)

    appeals = MetricsService.record("VACOLS: fetch appeals and associated info for tasks",
                                    service: :vacols,
                                    name: "appeals_from_tasks") do
      case_records = QueueRepository.appeal_info_query(vacols_ids)
      aod_by_appeal = aod_query(vacols_ids)
      hearings_by_appeal = Hearing.repository.hearings_for_appeals(vacols_ids)
      issues_by_appeal = VACOLS::CaseIssue.descriptions(vacols_ids)

      case_records.map do |case_record|
        appeal = AppealRepository.build_appeal(case_record)

        appeal.aod = aod_by_appeal[appeal.vacols_id]
        appeal.issues = (issues_by_appeal[appeal.vacols_id] || []).map { |issue| Issue.load_from_vacols(issue) }
        appeal.hearings = hearings_by_appeal[appeal.vacols_id] || []

        appeal
      end
    end

    appeals.map(&:save)
    appeals
  end

  # decass_hash = {
  #  task_id: "123456-2016-10-19",
  #  judge_css_id: "GRATR_316"
  #  work_product: "OMO - IME",
  #  overtime: true,
  #  document_id: "123456789.1234",
  #  note: "Require action"
  # }
  def self.reassign_case_to_judge(decass_hash)
    decass_record = find_decass_record(decass_hash[:task_id])
    ActiveRecord::Base.transaction do
      # update DECASS table
      update_decass_record(decass_record,
                           decass_hash.merge(reassigned_at: VacolsHelper.local_time_with_utc_timezone))

      # update location with the judge's stafkey
      update_location(decass_record.case, decass_hash[:judge_css_id])
      true
    end
  end

  def self.decass_by_vacols_id_and_date_assigned(vacols_id, date_assigned)
    VACOLS::Decass.find_by(defolder: vacols_id, deassign: date_assigned)
  end

  def self.update_location(case_record, css_id)
    fail ReassignCaseToJudgeError unless css_id
    staff = VACOLS::Staff.find_by(sdomainid: css_id)
    fail ReassignCaseToJudgeError unless staff
    case_record.update_vacols_location!(staff.stafkey)
  end

  def self.update_decass_record(decass_record, decass_hash)
    info = QueueMapper.case_decision_fields_to_vacols_codes(decass_hash)
    # Validate presence of the required fields after the mapper to ensure correctness
    VacolsHelper.validate_presence(info, [:work_product, :document_id, :reassigned_at])
    decass_record.update_decass_record!(info)
  end

  def self.tasks_query(css_id)
    records = VACOLS::CaseAssignment.tasks_for_user(css_id)
    filter_duplicate_tasks(records)
  end

  def self.appeal_info_query(vacols_ids)
    VACOLS::Case.includes(:folder, :correspondent, :representative)
      .find(vacols_ids)
  end

  def self.aod_query(vacols_ids)
    VACOLS::Case.aod(vacols_ids)
  end
  # :nocov:

  def self.find_decass_record(task_id)
    # Task ID is a concatantion of the vacols ID and the date assigned
    result = task_id.split("-", 2)
    fail ReassignCaseToJudgeError, "Task ID is invalid format: #{task_id}" if result.size != 2
    record = decass_by_vacols_id_and_date_assigned(result.first, result.second.to_date)
    # TODO: check permission that the user can update the record
    fail ReassignCaseToJudgeError, "Decass record does not exist for vacols_id: #{result.first}" unless record
    record
  end

  def self.filter_duplicate_tasks(records)
    # Keep the latest assignment if there are duplicate records
    records.group_by(&:vacols_id).each_with_object([]) { |(_k, v), result| result << v.sort_by(&:date_assigned).last }
  end
end
