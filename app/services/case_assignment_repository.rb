class CaseAssignmentRepository
  # :nocov:
  def self.load_from_vacols(css_id, fetch_issues=false)
    MetricsService.record("VACOLS: active_cases_for_user #{css_id}",
                          service: :vacols,
                          name: "active_cases_for_user") do
      active_cases_issues = []
                            
      active_cases_for_user = VACOLS::CaseAssignment.active_cases_for_user(css_id)
      active_cases_vacols_ids = active_cases_for_user.map(&:vacols_id)
      active_cases_aod_results = VACOLS::Case.aod(active_cases_vacols_ids)
      active_cases_issues = VACOLS::CaseIssue.descriptions(active_cases_vacols_ids) if fetch_issues
      
      active_cases_for_user.map do |assignment|
        appeal = Appeal.find_or_initialize_by(vacols_id: assignment.vacols_id)
        appeal.attributes = assignment.attributes
        appeal.aod = (active_cases_aod_results[assignment.vacols_id] == 1)
        appeal.issues = Issue.load_from_vacols(active_cases_issues[assignment.vacols_id]) if fetch_issues
        appeal.save
        appeal
      end
    end
  end
  # :nocov:
end
