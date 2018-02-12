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

  def self.reassign_case_to_judge(vacols_id:, attorney_css_id:, judge_css_id:, info:)
    decision_record = VACOLS::CaseDecision.find_by_vacols_id_and_css_id(vacols_id, attorney_css_id)
    return unless decision_record
    update_case_decision(decision_record, info)
    judge_stafkey = VACOLS::Staff.find_by(sdomainid: judge_css_id)
    decision_record.case.update_vacols_location!(judge_stafkey)
  end

  # decision_record is VACOLS::CaseDecision object
  # info = {
  #  work_product: "OMO - IME",
  #  overtime: true,
  #  document_id: "123456789.1234",
  #  note: "Require action"
  # }
  def self.update_case_decision(decision_record, info)
    decision_info = QueueMapper.case_decision_fields_to_vacols_codes(info)
    decision_record.update_case_decision!(decision_info)
  end

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
  #
  # :nocov:
  def self.aod_query(vacols_ids)
    VACOLS::Case.aod(vacols_ids)
  end
  # :nocov:
end
