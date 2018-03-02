class AppealRepository
  class AppealNotValidToClose < StandardError; end

  # :nocov:

  def self.transaction
    VACOLS::Case.transaction do
      yield
    end
  end

  # Returns a boolean saying whether the load succeeded
  def self.load_vacols_data(appeal)
    case_record = MetricsService.record("VACOLS: load_vacols_data #{appeal.vacols_id}",
                                        service: :vacols,
                                        name: "load_vacols_data") do
      VACOLS::Case.includes(:folder, :correspondent).find(appeal.vacols_id)
    end

    set_vacols_values(appeal: appeal, case_record: case_record)

    true
  rescue ActiveRecord::RecordNotFound
    return false
  end

  def self.appeals_by_vbms_id(vbms_id)
    cases = MetricsService.record("VACOLS: appeals_by_vbms_id",
                                  service: :vacols,
                                  name: "appeals_by_vbms_id") do
      VACOLS::Case.where(bfcorlid: vbms_id).includes(:folder, :correspondent)
    end

    cases.map { |case_record| build_appeal(case_record) }
  end

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  def self.appeals_by_vbms_id_with_preloaded_status_api_attrs(vbms_id)
    MetricsService.record("VACOLS: appeals_by_vbms_id_with_preloaded_status_api_attrs",
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
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize

  def self.appeals_ready_for_hearing(vbms_id)
    cases = MetricsService.record("VACOLS: appeals_ready_for_hearing",
                                  service: :vacols,
                                  name: "appeals_ready_for_hearing") do
      # An appeal is ready for hearing if form 9 has been submitted, and
      # there is no decision date OR the appeal is in remand status
      VACOLS::Case.where(bfcorlid: vbms_id)
        .where.not(bfd19: nil)
        .where("bfddec is NULL or bfmpro = 'REM'")
        .includes(:folder, :correspondent)
    end

    cases.map { |case_record| build_appeal(case_record, true) }
  end

  def self.load_vacols_data_by_vbms_id(appeal:, decision_type:)
    case_scope = case decision_type
                 when "Full Grant"
                   VACOLS::Case.amc_full_grants(outcoded_after: 5.days.ago)
                 when "Partial Grant or Remand"
                   VACOLS::Case.remands_ready_for_claims_establishment
                 else
                   VACOLS::Case.includes(:folder, :correspondent)
                 end

    case_records = MetricsService.record("VACOLS: load_vacols_data_by_vbms_id #{appeal.vbms_id}",
                                         service: :vacols,
                                         name: "load_vacols_data_by_vbms_id") do
      case_scope.where(bfcorlid: appeal.vbms_id)
    end

    return false if case_records.empty?
    fail Caseflow::Error::MultipleAppealsByVBMSID if case_records.length > 1

    appeal.vacols_id = case_records.first.bfkey
    set_vacols_values(appeal: appeal, case_record: case_records.first)

    appeal
  end
  # :nocov:

  # TODO: consider persisting these records
  def self.build_appeal(case_record, persist = false)
    appeal = Appeal.find_or_initialize_by(vacols_id: case_record.bfkey)
    appeal.save! if persist
    set_vacols_values(appeal: appeal, case_record: case_record)
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def self.set_vacols_values(appeal:, case_record:)
    correspondent_record = case_record.correspondent
    folder_record = case_record.folder
    outcoder_record = folder_record.outcoder

    appeal.assign_from_vacols(
      vbms_id: case_record.bfcorlid,
      type: VACOLS::Case::TYPES[case_record.bfac],
      file_type: folder_type_from(folder_record),
      representative: VACOLS::Case::REPRESENTATIVES[case_record.bfso][:full_name],
      veteran_first_name: correspondent_record.snamef,
      veteran_middle_initial: correspondent_record.snamemi,
      veteran_last_name: correspondent_record.snamel,
      veteran_date_of_birth: correspondent_record.sdob,
      veteran_gender: correspondent_record.sgender,
      outcoder_first_name: outcoder_record.try(:snamef),
      outcoder_last_name: outcoder_record.try(:snamel),
      outcoder_middle_initial: outcoder_record.try(:snamemi),
      appellant_first_name: correspondent_record.sspare1,
      appellant_middle_initial: correspondent_record.sspare2,
      appellant_last_name: correspondent_record.sspare3,
      appellant_relationship: correspondent_record.sspare1 ? correspondent_record.susrtyp : "",
      appellant_ssn: correspondent_record.ssn,
      appellant_address_line_1: correspondent_record.saddrst1,
      appellant_address_line_2: correspondent_record.saddrst2,
      appellant_city: correspondent_record.saddrcty,
      appellant_state: correspondent_record.saddrstt,
      appellant_country: correspondent_record.saddrcnty,
      appellant_zip: correspondent_record.saddrzip,
      insurance_loan_number: case_record.bfpdnum,
      notification_date: normalize_vacols_date(case_record.bfdrodec),
      nod_date: normalize_vacols_date(case_record.bfdnod),
      soc_date: normalize_vacols_date(case_record.bfdsoc),
      form9_date: normalize_vacols_date(case_record.bfd19),
      ssoc_dates: ssoc_dates_from(case_record),
      hearing_request_type: VACOLS::Case::HEARING_REQUEST_TYPES[case_record.bfhr],
      video_hearing_requested: case_record.bfdocind == "V",
      hearing_requested: (case_record.bfhr == "1" || case_record.bfhr == "2"),
      hearing_held: !case_record.bfha.nil?,
      regional_office_key: case_record.bfregoff,
      certification_date: case_record.bf41stat,
      case_review_date: folder_record.tidktime,
      case_record: case_record,
      disposition: VACOLS::Case::DISPOSITIONS[case_record.bfdc],
      location_code: case_record.bfcurloc,
      decision_date: normalize_vacols_date(case_record.bfddec),
      prior_decision_date: normalize_vacols_date(case_record.bfdpdcn),
      status: VACOLS::Case::STATUS[case_record.bfmpro],
      last_location_change_date: normalize_vacols_date(case_record.bfdloout),
      outcoding_date: normalize_vacols_date(folder_record.tioctime),
      private_attorney_or_agent: case_record.bfso == "T",
      docket_number: folder_record.tinum
    )

    appeal
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  # :nocov:
  def self.issues(vacols_id)
    (VACOLS::CaseIssue.descriptions([vacols_id])[vacols_id] || []).map do |issue_hash|
      Issue.load_from_vacols(issue_hash)
    end
  end

  def self.remands_ready_for_claims_establishment
    remands = MetricsService.record("VACOLS: remands_ready_for_claims_establishment",
                                    service: :vacols,
                                    name: "remands_ready_for_claims_establishment") do
      VACOLS::Case.remands_ready_for_claims_establishment
    end

    remands.map { |case_record| build_appeal(case_record) }
  end

  def self.amc_full_grants(outcoded_after:)
    full_grants = MetricsService.record("VACOLS:  amc_full_grants #{outcoded_after}",
                                        service: :vacols,
                                        name: "amc_full_grants") do
      VACOLS::Case.amc_full_grants(outcoded_after: outcoded_after)
    end

    full_grants.map { |case_record| build_appeal(case_record) }
  end
  # :nocov:

  def self.ssoc_dates_from(case_record)
    [
      case_record.bfssoc1,
      case_record.bfssoc2,
      case_record.bfssoc3,
      case_record.bfssoc4,
      case_record.bfssoc5
    ].map { |datetime| normalize_vacols_date(datetime) }.reject(&:nil?)
  end

  def self.folder_type_from(folder_record)
    if %w[Y 1 0].include?(folder_record.tivbms)
      "VBMS"
    elsif folder_record.tisubj == "Y"
      "VVA"
    else
      "Paper"
    end
  end

  # dates in VACOLS are incorrectly recorded as UTC.
  def self.normalize_vacols_date(datetime)
    return nil unless datetime
    utc_datetime = datetime.in_time_zone("UTC")

    Time.zone.local(
      utc_datetime.year,
      utc_datetime.month,
      utc_datetime.day
    )
  end

  def self.dateshift_to_utc(value)
    Time.utc(value.year, value.month, value.day, 0, 0, 0)
  end
  # :nocov:

  def self.update_vacols_after_dispatch!(appeal:, vacols_note:)
    VACOLS::Case.transaction do
      update_location_after_dispatch!(appeal: appeal)

      if vacols_note
        VACOLS::Note.create!(case_id: appeal.case_record.bfkey,
                             text: vacols_note,
                             user_id: RequestStore.store[:current_user].regional_office.upcase,
                             assigned_to: appeal.case_record.bfregoff,
                             code: :other,
                             days_to_complete: 30,
                             days_til_due: 30)
      end
    end
  end

  def self.update_location_after_dispatch!(appeal:)
    location = location_after_dispatch(appeal: appeal)

    appeal.case_record.update_vacols_location!(location)
  end

  # Determine VACOLS location desired after dispatching a decision
  def self.location_after_dispatch(appeal:)
    return unless appeal.active?

    return "54" if appeal.vamc?
    return "53" if appeal.national_cemetery_administration?
    return "50" if appeal.special_issues?

    # By default, we route the appeal to ARC
    "98"
  end

  # Close an undecided appeal (prematurely, such as for a withdrawal or a VAIMA opt in)
  # WARNING: some parts of this action are not automatically reversable, and must
  # be reversed by hand
  # rubocop:disable Metrics/MethodLength
  def self.close_undecided_appeal!(appeal:, user:, closed_on:, disposition_code:)
    case_record = appeal.case_record
    folder_record = case_record.folder

    # App logic should prevent this, but because this is a destructive operation
    # add an additional failsafe
    fail AppealNotValidToClose if case_record.bfdc

    VACOLS::Case.transaction do
      case_record.update_attributes!(
        bfmpro: "HIS",
        bfddec: dateshift_to_utc(closed_on),
        bfdc: disposition_code,
        bfboard: "00",
        bfmemid: "000",
        bfattid: "000"
      )

      case_record.update_vacols_location!("99")

      folder_record.update_attributes!(
        ticukey: "HISTORY",
        tikeywrd: "HISTORY",
        tidcls: dateshift_to_utc(closed_on),
        timdtime: VacolsHelper.local_time_with_utc_timezone,
        timduser: user.regional_office
      )

      # Close any issues associated to the appeal
      case_record.case_issues.where(issdc: nil).update_all(
        issdc: disposition_code,
        issdcls: VacolsHelper.local_time_with_utc_timezone
      )

      close_associated_diary_notes(case_record, user)
      close_associated_hearings(case_record)
    end
  end
  # rubocop:enable Metrics/MethodLength

  # Close a remand (prematurely, such as for a withdrawal or a VAIMA opt in)
  # Remands need to be closed without overwriting the disposition data. A new
  # Appeal record is opened and subsequently closed to record the disposition
  # of the remand.
  #
  # WARNING: some parts of this action are not automatically reversable, and must
  # be reversed by hand
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def self.close_remand!(appeal:, user:, closed_on:, disposition_code:)
    case_record = appeal.case_record
    folder_record = case_record.folder

    # App logic should prevent this, but because this is a destructive operation
    # add an additional failsafe
    fail AppealNotValidToClose unless case_record.bfmpro == "REM"

    VACOLS::Case.transaction do
      case_record.update_attributes!(bfmpro: "HIS")

      case_record.update_vacols_location!("99")

      folder_record.update_attributes!(
        ticukey: "HISTORY",
        tikeywrd: "HISTORY",
        timdtime: VacolsHelper.local_time_with_utc_timezone,
        timduser: user.regional_office
      )

      close_associated_diary_notes(case_record, user)
      close_associated_hearings(case_record)

      # The follow up appeal will have the same ID as the remand, with a "P" tacked on
      # (It's a VACOLS thing)
      follow_up_appeal_key = "#{case_record.bfkey}P"

      follow_up_case = VACOLS::Case.create!(
        case_record.remand_clone_attributes.merge(
          bfkey: follow_up_appeal_key,
          bfmpro: "HIS",
          bfddec: dateshift_to_utc(closed_on),
          bfdc: disposition_code,
          bfboard: "88",
          bfattid: "888",
          bfac: "3",
          bfdcfld1: nil,
          bfdcfld2: nil,
          bfdcfld3: nil
        )
      )

      follow_up_case.update_vacols_location!("99")

      VACOLS::Folder.create!(
        folder_record.remand_clone_attributes.merge(
          ticknum: follow_up_appeal_key,
          ticukey: "HISTORY",
          tikeywrd: "HISTORY",
          tidcls: dateshift_to_utc(closed_on),
          timdtime: VacolsHelper.local_time_with_utc_timezone,
          timduser: user.regional_office
        )
      )

      # Create follow up issues that will be listed as closed with the
      # proper disposition
      case_record.case_issues.where(issdc: "3").each_with_index do |case_issue, i|
        VACOLS::CaseIssue.create!(
          case_issue.remand_clone_attributes.merge(
            isskey: follow_up_appeal_key,
            issseq: i + 1,
            issdc: disposition_code,
            issdcls: VacolsHelper.local_time_with_utc_timezone,
            issadtime: VacolsHelper.local_time_with_utc_timezone,
            issaduser: user.regional_office
          )
        )
      end
    end
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  def self.certify(appeal:, certification:)
    certification_date = AppealRepository.dateshift_to_utc Time.zone.now

    appeal.case_record.bfdcertool = certification_date
    appeal.case_record.bf41stat = certification_date

    preference_attrs = VACOLS::Case::HEARING_PREFERENCE_TYPES_V2[certification.hearing_preference.to_sym]
    appeal.case_record.bfhr = preference_attrs[:vacols_value]
    # "Ready for hearing" checkbox
    appeal.case_record.bftbind = preference_attrs[:ready_for_hearing] ? "X" : nil
    # "Video hearing" checkbox
    appeal.case_record.bfdocind = preference_attrs[:video_hearing] ? "V" : nil

    MetricsService.record("VACOLS: certify #{appeal.vacols_id}",
                          service: :vacols,
                          name: "certify") do
      appeal.case_record.save!
    end
  end

  def self.aod(vacols_id)
    VACOLS::Case.aod([vacols_id])[vacols_id]
  end

  def self.remand_return_date(vacols_id)
    VACOLS::Case.remand_return_date([vacols_id])[vacols_id]
  end

  def self.load_user_case_assignments_from_vacols(css_id)
    MetricsService.record("VACOLS: active_cases_for_user #{css_id}",
                          service: :vacols,
                          name: "active_cases_for_user") do
      active_cases_for_user = VACOLS::CaseAssignment.active_cases_for_user(css_id)
      active_cases_for_user = QueueRepository.filter_duplicate_tasks(active_cases_for_user)
      active_cases_vacols_ids = active_cases_for_user.map(&:vacols_id)
      active_cases_aod_results = VACOLS::Case.aod(active_cases_vacols_ids)
      active_cases_issues = VACOLS::CaseIssue.descriptions(active_cases_vacols_ids)
      active_cases_for_user.map do |assignment|
        assignment_issues_hash_array = active_cases_issues[assignment.vacols_id] || []

        # if that appeal is not found, it intializes a new appeal with the
        # assignments vacols_id
        appeal = Appeal.find_or_initialize_by(vacols_id: assignment.vacols_id)
        attribute_copy = assignment.attributes
        attribute_copy["type"] = VACOLS::Case::TYPES[attribute_copy.delete("bfac")]
        appeal.attributes = attribute_copy
        appeal.aod = active_cases_aod_results[assignment.vacols_id]

        # fetching Issue objects using the issue hash
        appeal.issues = assignment_issues_hash_array.map { |issue_hash| Issue.load_from_vacols(issue_hash) }
        appeal.save
        appeal
      end
    end
  end

  def self.case_assignment_exists?(vacols_id)
    VACOLS::CaseAssignment.exists_for_appeals([vacols_id])[vacols_id]
  end

  def self.regular_non_aod_docket_count
    MetricsService.record("VACOLS: regular_non_aod_docket_count",
                          name: "regular_non_aod_docket_count",
                          service: :vacols) do
      VACOLS::CaseDocket.regular_non_aod_docket_count
    end
  end

  def self.latest_docket_month
    result = MetricsService.record("VACOLS: latest_docket_month",
                                   name: "latest_docket_month",
                                   service: :vacols) do
      VACOLS::CaseDocket.docket_date_of_nth_appeal_in_case_storage(3500)
    end

    result.beginning_of_month
  end

  def self.docket_counts_by_month
    MetricsService.record("VACOLS: docket_counts_by_month",
                          name: "docket_counts_by_month",
                          service: :vacols) do
      VACOLS::CaseDocket.docket_counts_by_month
    end
  end

  class << self
    private

    # NOTE: this should be called within a transaction where you are closing an appeal
    def close_associated_hearings(case_record)
      # Only scheduled hearings need to be closed
      case_record.case_hearings.where(clsdate: nil, hearing_disp: nil).update_all(
        clsdate: VacolsHelper.local_time_with_utc_timezone,
        hearing_disp: "C"
      )
    end

    # NOTE: this should be called within a transaction where you are closing an appeal
    def close_associated_diary_notes(case_record, user)
      case_record.notes.where(tskdcls: nil).update_all(
        tskdcls: VacolsHelper.local_time_with_utc_timezone,
        tskmdtm: VacolsHelper.local_time_with_utc_timezone,
        tskmdusr: user.regional_office,
        tskstat: "C"
      )
    end
  end
  # :nocov:
end
