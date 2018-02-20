class ReassignCaseToJudgeError < StandardError; end

class QueueRepository
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
  # :nocov:

  # :nocov:
  # decass_hash = {
  #  vacols_id: "123456",
  #  attorney_css_id: "CASEFLOW_317",
  #  judge_css_id: "GRATR_316"
  #  work_product: "OMO - IME",
  #  overtime: true,
  #  document_id: "123456789.1234",
  #  note: "Require action"
  # }
  # TODO: use decass uniq ID instead of vacols_id and attorney_css_id
  def self.reassign_case_to_judge(decass_hash)
    decass_record = find_decass_record(decass_hash[:vacols_id], decass_hash[:attorney_css_id])
    fail ReassignCaseToJudgeError unless decass_record

    ActiveRecord::Base.transaction do
      # update DECASS table
      update_decass_record(decass_record,
                           decass_hash.merge(reassigned_at: VacolsHelper.local_time_with_utc_timezone))

      # update location with the judge's stafkey
      update_location(decass_record.case, decass_hash[:judge_css_id])
    end
  end
  # :nocov:

  # :nocov:
  def self.find_decass_record(vacols_id, css_id)
    VACOLS::Decass.find_by_vacols_id_and_css_id(vacols_id, css_id)
  end
  # :nocov:

  # :nocov:
  def self.update_location(case_record, css_id)
    stafkey = VACOLS::Staff.find_by(sdomainid: css_id)
    case_record.update_vacols_location!(stafkey)
  end
  # :nocov:

  # :nocov:
  def self.update_decass_record(decass_record, decass_hash)
    info = QueueMapper.case_decision_fields_to_vacols_codes(decass_hash)
    # Validate presence of the required fields after the mapper to ensure correctness
    VacolsHelper.validate_presence(decision_hash, [:work_product, :document_id, :reassigned_at])
    decass_record.update_decass_record!(info)
  end
  # :nocov:

  # :nocov:
  def self.tasks_query(css_id)
    records = VACOLS::CaseAssignment.tasks_for_user(css_id)
    filter_duplicate_tasks(records)
  end
  # :nocov:

  def self.filter_duplicate_tasks(records)
    # Keep the latest assignment if there are duplicate records
    records.group_by(&:vacols_id).each_with_object([]) { |(_k, v), result| result << v.sort_by(&:date_assigned).last }
  end

  # :nocov:
  def self.appeal_info_query(vacols_ids)
    VACOLS::Case.includes(:folder, :correspondent, :representative)
      .find(vacols_ids)
  end
  # :nocov:

  # :nocov:
  def self.aod_query(vacols_ids)
    VACOLS::Case.aod(vacols_ids)
  end
  # :nocov:
end
