class CaseAssignmentRepository
  # :nocov:
  def self.load_from_vacols(css_id)
    MetricsService.record("VACOLS: active_cases_for_user #{css_id}",
                          service: :vacols,
                          name: "active_cases_for_user") do
      VACOLS::CaseAssignment.active_cases_for_user(css_id).map do |assignment|
        Appeal.initialize_appeal_without_lazy_load(vacols_id: assignment.vacols_id,
                                                   date_assigned: assignment.date_assigned,
                                                   date_received: assignment.date_received,
                                                   signed_date: assignment.signed_date,
                                                   veteran_first_name: assignment.veteran_first_name,
                                                   veteran_middle_initial: assignment.veteran_middle_initial,
                                                   veteran_last_name: assignment.veteran_last_name,
                                                   vbms_id: assignment.vbms_id)
      end
    end
  end
  # :nocov:
end
