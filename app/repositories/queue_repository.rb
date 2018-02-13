class QueueRepository
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
  def self.find_case(vacols_id, css_id)
    VACOLS::CaseDecision.find_by_vacols_id_and_css_id(vacols_id, css_id)
  end
  # :nocov:

  # :nocov:
  # decision_hash = {
  #  judge_css_id: "GRATR_316"
  #  work_product: "OMO - IME",
  #  overtime: true,
  #  document_id: "123456789.1234",
  #  note: "Require action"
  # }
  def self.reassign_case_to_judge(decision_record:, decision_hash:)
    return unless decision_record

    VacolsHelper.validate_presence(decision_hash, [:work_product, :document_id, :judge_css_id])

    ActiveRecord::Base.transaction do
      # update DECASS table
      update_case_decision(decision_record,
                           decision_hash.merge(reassigned_at: VacolsHelper.local_time_with_utc_timezone))

      # update location with the judge's stafkey
      update_location(decision_record, decision_hash[:judge_css_id])
    end
  end
  # :nocov:

  # :nocov:
  def self.update_location(decision_record, css_id)
    stafkey = VACOLS::Staff.find_by(sdomainid: css_id)
    decision_record.case.update_vacols_location!(stafkey)
  end
  # :nocov:

  # :nocov:
  def self.update_case_decision(decision_record, decision_hash)
    decision_info = QueueMapper.case_decision_fields_to_vacols_codes(decision_hash)
    decision_record.update_case_decision!(decision_info)
  end
  # :nocov:

  # :nocov:
  def self.tasks_query(css_id)
    VACOLS::CaseAssignment.tasks_for_user(css_id)
  end
  # :nocov:

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
