class CaseAssignmentRepository
  # :nocov:
  def self.load_from_vacols(css_id)
    MetricsService.record("VACOLS: active_cases_for_user #{css_id}",
                          service: :vacols,
                          name: "active_cases_for_user") do
      active_cases_for_user = VACOLS::CaseAssignment.active_cases_for_user(css_id)
      active_cases_vacols_ids = active_cases_for_user.map(&:vacols_id)
      active_cases_aod_results = VACOLS::Case.aod(active_cases_vacols_ids)
      active_cases_issues = VACOLS::CaseIssue.descriptions(active_cases_vacols_ids)

      active_cases_for_user.map do |assignment|
        case_issues_hash_array = active_cases_issues[assignment.vacols_id]

        appeal = Appeal.find_or_initialize_by(vacols_id: assignment.vacols_id)
        appeal.attributes = assignment.attributes
        appeal.aod = active_cases_aod_results[assignment.vacols_id]

        # fetching Issue objects using the issue hash
        appeal.issues = case_issues_hash_array.map { |issue_hash| Issue.load_from_vacols(issue_hash) }
        appeal.save
        appeal
      end
    end
  end
  # :nocov:
end
