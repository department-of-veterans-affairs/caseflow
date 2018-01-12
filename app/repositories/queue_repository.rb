class QueueRepository
  # :nocov:
  def self.tasks_query(css_id)
    VACOLS::CaseAssignment.active_cases_for_user(css_id)
  end
  # :nocov:

  # :nocov:
  def self.appeal_info_query(vacols_ids)
    VACOLS::Case.includes(:folder, :correspondent, :representative)
      .find(vacols_ids)
      .joins(VACOLS::Case::JOIN_AOD)
  end
  # :nocov:

  def self.tasks_for_user(css_id)
    tasks = MetricsService.record("VACOLS: fetch user assignments",
                                  service: :vacols,
                                  name: "appeals_by_vacols_id") do
      tasks_query(css_id)
    end
  end

  def self.appeals_from_tasks(tasks)
    # Run a second query to find all the appeal information.
    case_records = MetricsService.record("VACOLS: fetch appeals associated with tasks",
                                         service: :vacols,
                                         name: "appeals_by_vacols_id") do
      vacols_ids = tasks.map(&:vacols_id)
      appeal_info_query(vacols_ids)
    end

    hearings = Hearing.repository.hearings_for_appeals(vacols_ids)

    case_records.map do |case_record|
      appeal = build_appeal(case_record)
      appeal.aod = case_record["aod"] == 1
      appeal.issues = (issues[appeal.vacols_id] || []).map { |issue| Issue.load_from_vacols(issue.attributes) }
      appeal.hearings = hearings[appeal.vacols_id] || []
      appeal.remand_return_date = (case_record["rem_return"] || false) unless appeal.active?
      appeal.save
      appeal
    end
  end
end
