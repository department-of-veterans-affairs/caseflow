class CaseAssignmentRepository
  # :nocov:
  def self.load_from_vacols(css_id)
    MetricsService.record("VACOLS: active_cases_for_user #{css_id}",
                          service: :vacols,
                          name: "active_cases_for_user") do
      active_cases_for_user = VACOLS::CaseAssignment.active_cases_for_user(css_id)
      active_cases_vacols_ids = active_cases_for_user.map(&:vacols_id)
      active_cases_aod_results = VACOLS::Case.aod(active_cases_vacols_ids)
      active_cases_issues = Appeal.issues(active_cases_vacols_ids)

      active_cases_for_user.each_with_index.map do |assignment, index|
        appeal = Appeal.find_or_initialize_by(vacols_id: assignment.vacols_id)
        appeal.attributes = assignment.attributes
        appeal.aod = (active_cases_aod_results[index] == 1)
        appeal.save
        appeal
      end
    end
  end
  # :nocov:
end
