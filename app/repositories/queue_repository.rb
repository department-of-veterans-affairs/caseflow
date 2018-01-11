class QueueRepository
  def self.tasks_for_attorney(css_id)
    cases = VACOLS::CaseAssignment.active_cases_for_user(css_id)
    vacols_ids = active_cases_for_user.map(&:vacols_id)

    aod_statuses = VACOLS::Case.aod(vacols_ids)
    issues = VACOLS::CaseIssue.descriptions(vacols_ids)


    MetricsService.record("VACOLS: cases_assigned_to_user",
                          service: :vacols,
                          name: "appeals_by_vbms_id_with_preloaded_status_api_attrs") do
      cases = VACOLS::Case.where(bfcorlid: vbms_id)
        .includes(:folder, :correspondent, folder: :outcoder)
        .references(:folder, :correspondent, folder: :outcoder)
        .joins(VACOLS::Case::JOIN_AOD, VACOLS::Case::JOIN_REMAND_RETURN)
      vacols_ids = cases.map(&:bfkey)
      # Load issues, but note that we do so without including descriptions
      issues = VACOLS::CaseIssue.where(isskey: vacols_ids).group_by(&:isskey)
      hearings = Hearing.repository.hearings_for_appeals(vacols_ids)
      cavc_decisions = CAVCDecision.repository.cavc_decisions_by_appeals(vacols_ids)

      cases.map do |case_record|
        poa = PowerOfAttorney.new
        PowerOfAttorneyRepository.set_vacols_values(poa, case_record)

        appeal = build_appeal(case_record)
        appeal.aod = case_record["aod"] == 1
        appeal.issues = (issues[appeal.vacols_id] || []).map { |issue| Issue.load_from_vacols(issue.attributes) }
        appeal.hearings = hearings[appeal.vacols_id] || []
        appeal.cavc_decisions = cavc_decisions[appeal.vacols_id] || []
        appeal.remand_return_date = (case_record["rem_return"] || false) unless appeal.active?
        appeal.save
        appeal
      end
    end
  end
  end
end
