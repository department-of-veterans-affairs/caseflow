class CaseAssignmentRepository
  # :nocov:
  def self.load_from_vacols(css_id)
    MetricsService.record("VACOLS: active_cases_for_user #{css_id}",
                          service: :vacols,
                          name: "active_cases_for_user") do
      VACOLS::CaseAssignment.active_cases_for_user(css_id).map do |assignment|
        appeal = Appeal.find_or_initialize_by(vacols_id: assignment.vacols_id)
        appeal.attributes = assignment.attributes
        appeal.save
        appeal
      end
    end
  end
  # :nocov:
end
