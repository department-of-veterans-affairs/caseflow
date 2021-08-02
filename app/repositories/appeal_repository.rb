# frozen_string_literal: true

class AppealRepository
  class AppealNotValidToClose < StandardError; end
  class AppealNotValidToReopen < StandardError
    def initialize(appeal_id)
      super("Appeal id #{appeal_id} is not valid to reopen")
    end
  end

  # :nocov:

  class << self
    def transaction
      VACOLS::Case.transaction do
        yield
      end
    end

    def eager_load_legacy_appeals_for_tasks(tasks)
      # Make a single request to VACOLS to grab all of the rows we want here?
      legacy_appeal_ids = tasks.select { |t| t.appeal.is_a?(LegacyAppeal) }.map(&:appeal).pluck(:vacols_id)

      # Do not make a VACOLS request if there are no legacy appeals in the set of tasks
      return tasks if legacy_appeal_ids.empty?

      # Load the VACOLS case records associated with legacy tasks into memory in a single batch. Ignore appeals that no
      # longer appear in VACOLS.
      cases = (vacols_records_for_appeals(legacy_appeal_ids) || []).group_by(&:id)

      aod = legacy_appeal_ids.in_groups_of(1000, false).reduce({}) do |acc, group|
        acc.merge(VACOLS::Case.aod(group))
      end

      # Associate the cases we pulled from VACOLS to the appeals of the tasks.
      tasks.each do |t|
        next unless t.appeal.is_a?(LegacyAppeal)

        case_record = cases[t.appeal.vacols_id.to_s]&.first
        set_vacols_values(appeal: t.appeal, case_record: case_record) if case_record
        t.appeal.aod = aod[t.appeal.vacols_id.to_s]
      end
    end

    def find_case_record(id, ignore_misses: false)
      # Oracle cannot load more than 1000 records at a time
      if id.is_a?(Array)
        id.in_groups_of(1000, false).map do |group|
          if ignore_misses
            VACOLS::Case.eager_load(:correspondent, :case_issues, folder: [:outcoder]).where(bfkey: group)
          else
            VACOLS::Case.eager_load(:correspondent, :case_issues, folder: [:outcoder]).find(group)
          end
        end.flatten
      else
        # using .includes() creates 4 SQL queries at ~ 90ms each (measured in production).
        # using .eager_load() creates 2 SQL queries at ~ 90ms each
        VACOLS::Case.eager_load(:correspondent, :case_issues, folder: [:outcoder]).find(id)
      end
    end

    def vacols_records_for_appeals(ids)
      MetricsService.record("VACOLS: eager_load_legacy_appeals_batch",
                            service: :vacols,
                            name: "eager_load_legacy_appeals_batch") do
        find_case_record(ids, ignore_misses: true)
      end
    end

    # Returns a boolean saying whether the load succeeded
    def load_vacols_data(appeal)
      case_record = MetricsService.record("VACOLS: load_vacols_data #{appeal.vacols_id}",
                                          service: :vacols,
                                          name: "load_vacols_appeal_data") do
        find_case_record(appeal.vacols_id)
      end

      set_vacols_values(appeal: appeal, case_record: case_record)

      true
    rescue ActiveRecord::RecordNotFound
      false
    end

    def appeals_by_vbms_id(vbms_id)
      cases = MetricsService.record("VACOLS: appeals_by_vbms_id",
                                    service: :vacols,
                                    name: "appeals_by_vbms_id") do
        VACOLS::Case.where(bfcorlid: vbms_id).includes(:folder, :correspondent, :case_issues)
      end

      cases.map { |case_record| build_appeal(case_record, true) }
    end

    def appeals_by_vbms_id_with_preloaded_status_api_attrs(vbms_id)
      MetricsService.record("VACOLS: appeals_by_vbms_id_with_preloaded_status_api_attrs",
                            service: :vacols,
                            name: "appeals_by_vbms_id_with_preloaded_status_api_attrs") do
        cases = VACOLS::Case.where(bfcorlid: vbms_id)
          .includes(:folder, :correspondent, folder: :outcoder)
          .references(:folder, :correspondent, folder: :outcoder)

        vacols_ids = cases.map(&:bfkey)
        # Load issues, but note that we do so without including descriptions
        issues = VACOLS::CaseIssue.where(isskey: vacols_ids).group_by(&:isskey)
        hearings = HearingRepository.hearings_for_appeals(vacols_ids)
        cavc_decisions = CAVCDecision.repository.cavc_decisions_by_appeals(vacols_ids)

        aod_and_rem_return = VACOLS::Case.where(bfkey: vacols_ids)
          .joins(VACOLS::Case::JOIN_AOD, VACOLS::Case::JOIN_REMAND_RETURN)
          .select("bfkey", "aod", "rem_return")
          .index_by do |row|
            (row["bfkey"]).to_s
          end

        cases.map do |case_record|
          appeal = build_appeal(case_record)
          appeal.aod = aod_and_rem_return[appeal.vacols_id].aod == 1
          appeal.issues = (issues[appeal.vacols_id] || []).map { |issue| Issue.load_from_vacols(issue.attributes) }
          appeal.hearings = hearings[appeal.vacols_id] || []
          appeal.cavc_decisions = cavc_decisions[appeal.vacols_id] || []
          appeal.remand_return_date = (aod_and_rem_return[appeal.vacols_id].rem_return || false) unless appeal.active?
          appeal.save
          appeal
        end
      end
    end

    def appeals_ready_for_hearing(vbms_id)
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

    def load_vacols_data_by_vbms_id(appeal:, decision_type:)
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
    def build_appeal(case_record, persist = false)
      appeal = LegacyAppeal.find_or_initialize_by(vacols_id: case_record.bfkey)
      appeal.save! if persist
      set_vacols_values(appeal: appeal, case_record: case_record)
    end

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def set_vacols_values(appeal:, case_record:)
      correspondent_record = case_record.correspondent
      folder_record = case_record.folder
      # Only fetch outcoder (VACOLS::Staff) if the foreign key (:tiocuser) isn't nil
      outcoder_record = folder_record.outcoder if folder_record.tiocuser?

      appeal.assign_from_vacols(
        vbms_id: case_record.bfcorlid,
        type: VACOLS::Case::TYPES[case_record.bfac],
        file_type: folder_type_from(folder_record),
        veteran_first_name: correspondent_record.snamef,
        veteran_middle_initial: correspondent_record.snamemi,
        veteran_last_name: correspondent_record.snamel,
        veteran_name_suffix: correspondent_record.ssalut,
        outcoder_first_name: outcoder_record.try(:snamef),
        outcoder_last_name: outcoder_record.try(:snamel),
        outcoder_middle_initial: outcoder_record.try(:snamemi),
        appellant_first_name: correspondent_record.sspare2,
        appellant_middle_initial: correspondent_record.sspare3,
        appellant_last_name: correspondent_record.sspare1,
        appellant_name_suffix: correspondent_record.sspare4,
        appellant_relationship: correspondent_record.sspare1 ? correspondent_record.susrtyp : "",
        appellant_ssn: correspondent_record.ssn,
        insurance_loan_number: case_record.bfpdnum,
        notification_date: normalize_vacols_date(case_record.bfdrodec),
        nod_date: normalize_vacols_date(case_record.bfdnod),
        soc_date: normalize_vacols_date(case_record.bfdsoc),
        form9_date: normalize_vacols_date(case_record.bfd19),
        notice_of_death_date: normalize_vacols_date(correspondent_record.sfnod),
        ssoc_dates: ssoc_dates_from(case_record),
        hearing_request_type: VACOLS::Case::HEARING_REQUEST_TYPES[case_record.bfhr],
        video_hearing_requested: case_record.bfdocind == "V",
        hearing_requested: (case_record.bfhr == "1" || case_record.bfhr == "2"),
        hearing_held: %w[1 2 6 7].include?(case_record.bfha),
        regional_office_key: case_record.bfregoff,
        certification_date: case_record.bf41stat,
        case_review_date: folder_record.tidktime,
        citation_number: folder_record.tiread2,
        case_record: case_record,
        disposition: Constants::VACOLS_DISPOSITIONS_BY_ID[case_record.bfdc],
        location_code: case_record.bfcurloc,
        decision_date: normalize_vacols_date(case_record.bfddec),
        prior_decision_date: normalize_vacols_date(case_record.bfdpdcn),
        status: VACOLS::Case::STATUS[case_record.bfmpro],
        last_location_change_date: normalize_vacols_date(case_record.bfdloout),
        outcoding_date: normalize_vacols_date(folder_record.tioctime),
        docket_number: folder_record.tinum || "Missing Docket Number",
        docket_date: case_record.bfd19,
        number_of_issues: case_record.case_issues.length
      )

      appeal
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    # :nocov:
    def issues(vacols_id)
      (VACOLS::CaseIssue.descriptions([vacols_id])[vacols_id] || []).map do |issue_hash|
        Issue.load_from_vacols(issue_hash)
      end
    end

    def remands_ready_for_claims_establishment
      remands = MetricsService.record("VACOLS: remands_ready_for_claims_establishment",
                                      service: :vacols,
                                      name: "remands_ready_for_claims_establishment") do
        VACOLS::Case.remands_ready_for_claims_establishment
      end

      remands.map { |case_record| build_appeal(case_record) }
    end

    def amc_full_grants(outcoded_after:)
      full_grants = MetricsService.record("VACOLS:  amc_full_grants #{outcoded_after}",
                                          service: :vacols,
                                          name: "amc_full_grants") do
        VACOLS::Case.amc_full_grants(outcoded_after: outcoded_after)
      end

      full_grants.map { |case_record| build_appeal(case_record) }
    end
    # :nocov:

    def ssoc_dates_from(case_record)
      [
        case_record.bfssoc1,
        case_record.bfssoc2,
        case_record.bfssoc3,
        case_record.bfssoc4,
        case_record.bfssoc5
      ].map { |datetime| normalize_vacols_date(datetime) }.reject(&:nil?)
    end

    def folder_type_from(folder_record)
      if %w[Y 1 0].include?(folder_record.tivbms)
        "VBMS"
      elsif folder_record.tisubj2 == "Y"
        "VVA"
      else
        "Paper"
      end
    end

    # dates in VACOLS are incorrectly recorded as UTC.
    def normalize_vacols_date(datetime)
      return nil unless datetime

      utc_datetime = datetime.in_time_zone("UTC")

      Time.zone.local(
        utc_datetime.year,
        utc_datetime.month,
        utc_datetime.day
      )
    end

    def dateshift_to_utc(value)
      Time.utc(value.year, value.month, value.day, 0, 0, 0)
    end
    # :nocov:

    def update_vacols_after_dispatch!(appeal:, vacols_note:)
      VACOLS::Case.transaction do
        update_location_after_dispatch!(appeal: appeal)

        if vacols_note
          VACOLS::Note.create!(case_id: appeal.case_record.bfkey,
                               text: vacols_note,
                               user_id: RequestStore.store[:current_user].regional_office,
                               assigned_to: appeal.case_record.bfregoff,
                               code: :other,
                               days_to_complete: 30,
                               days_til_due: 30)
        end
      end
    end

    def withdraw_hearing!(appeal)
      appeal.case_record.update!(bfhr: "5", bfha: "5")
    end

    def update_vacols_hearing_request_type!(appeal, type)
      case type
      when VACOLS::CaseHearing::HEARING_TYPE_LOOKUP[:central]
        # if we're switching to Central
        # change bfhr: "1" and bfdocind: nil
        appeal.case_record.update!(bfhr: "1", bfdocind: nil)
      when VACOLS::CaseHearing::HEARING_TYPE_LOOKUP[:video]
        # if we're switching to Video
        # change bfhr: "2" and bfdocind: "V"
        appeal.case_record.update!(bfhr: "2", bfdocind: "V")
      end
    end

    def update_location_after_dispatch!(appeal:)
      location = location_after_dispatch(appeal: appeal)

      appeal.case_record.update_vacols_location!(location)
    end

    def update_location_for_death_dismissal!(appeal:)
      location = LegacyAppeal::LOCATION_CODES[:sr_council_dvc]
      appeal.case_record.update_vacols_location!(location)
    end

    # Updates the case location for a legacy appeal.
    #
    # @param appeal [LegacyAppeal] the appeal to modify
    # @param location [String] the appeal's new location (see LegacyAppeal::LOCATION_CODES)
    def update_location!(appeal, location)
      appeal.case_record.update_vacols_location!(location)
    end

    # Determine VACOLS location desired after dispatching a decision
    def location_after_dispatch(appeal:)
      return unless appeal.active?

      return "54" if appeal.vamc?
      return "53" if appeal.national_cemetery_administration?
      return "50" if appeal.special_issues?

      # By default, we route the appeal to ARC
      "98"
    end

    # Finds appeals in the set of vacols_ids passed that have been reopened after
    # being closed for RAMP
    def find_ramp_reopened_appeals(vacols_ids)
      VACOLS::Case
        .where(bfkey: vacols_ids)
        .where([
                 "bfdc IS NULL OR (bfdc != 'P' AND (bfmpro != 'HIS' OR bfdc NOT IN (?)))",
                 VACOLS::Case::BVA_DISPOSITION_CODES
               ])
        .map { |case_record| build_appeal(case_record) }
    end

    def close_appeal_with_disposition!(case_record:, folder:, user:, closed_on:, disposition_code:)
      VACOLS::Case.transaction do
        case_record.update!(
          bfmpro: "HIS",
          bfddec: dateshift_to_utc(closed_on),
          bfdc: disposition_code,
          bfboard: "00",
          bfmemid: "000",
          bfattid: "000"
        )

        case_record.update_vacols_location!(LegacyAppeal::LOCATION_CODES[:closed])

        folder.update!(
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

    # Close an undecided appeal (prematurely, such as for a withdrawal or a VAIMA opt in)
    # WARNING: some parts of this action are not automatically reversable, and must
    # be reversed by hand
    def close_undecided_appeal!(appeal:, user:, closed_on:, disposition_code:)
      case_record = appeal.case_record
      folder_record = case_record.folder

      # App logic should prevent this, but because this is a destructive operation
      # add an additional failsafe
      if case_record.bfdc
        Raven.extra_context(undecided_appeal_id: appeal.id)
        fail AppealNotValidToClose
      end

      close_appeal_with_disposition!(
        case_record: case_record,
        folder: folder_record,
        user: user,
        closed_on: closed_on,
        disposition_code: disposition_code
      )
    end

    # Close a remand (prematurely, such as for a withdrawal or a VAIMA opt in)
    # Remands need to be closed without overwriting the disposition data. A new
    # Appeal record is opened and subsequently closed to record the disposition
    # of the remand.
    #
    # WARNING: some parts of this action are not automatically reversable, and must
    # be reversed by hand
    def close_remand!(appeal:, user:, closed_on:, disposition_code:)
      case_record = appeal.case_record
      folder_record = case_record.folder

      # App logic should prevent this, but because this is a destructive operation
      # add an additional failsafe
      fail AppealNotValidToClose unless case_record.bfmpro == "REM"

      VACOLS::Case.transaction do
        case_record.update!(bfmpro: "HIS")

        case_record.update_vacols_location!(LegacyAppeal::LOCATION_CODES[:closed])

        folder_record.update!(
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

        # Remands can be reopened, which means there will already be a post-remand case.
        # Check for that, and if the post-remand case exists, skip the post-remand creation
        return if VACOLS::Case.find_by(bfkey: follow_up_appeal_key)

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

        follow_up_case.update_vacols_location!(LegacyAppeal::LOCATION_CODES[:closed])

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
        case_record.case_issues.where(issdc: %w[3 L]).each_with_index do |case_issue, i|
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

    # This method opts appeals into AMA even if they were already closed
    def opt_in_decided_appeal!(appeal:, user:, closed_on:)
      case_record = appeal.case_record
      folder_record = case_record.folder

      # This is currently only allowed for appeals with Advance Failure to Respond (G code) dispositions
      # By following the same pattern as closing undecided appeals
      # The original disposition and case/folder decision dates are stored on LegacyIssueOptin

      unless case_record.bfdc == "G"
        Raven.extra_context(vacols_id: appeal.id)
        fail AppealNotValidToClose
      end

      close_appeal_with_disposition!(
        case_record: case_record,
        folder: folder_record,
        user: user,
        closed_on: closed_on,
        disposition_code: "O"
      )
    end

    def reopen_undecided_appeal!(appeal:, user:, safeguards:, reopen_issues: true)
      case_record = appeal.case_record
      folder_record = case_record.folder
      not_valid_to_reopen_err = AppealNotValidToReopen.new(appeal.id)

      fail not_valid_to_reopen_err unless case_record.bfmpro == "HIS"
      fail not_valid_to_reopen_err unless case_record.bfcurloc == LegacyAppeal::LOCATION_CODES[:closed]

      close_date = case_record.bfddec
      close_disposition = case_record.bfdc

      if safeguards
        fail not_valid_to_reopen_err unless %w[9 E F G P O].include? close_disposition
      end

      previous_active_location = case_record.previous_active_location

      fail not_valid_to_reopen_err unless previous_active_location
      fail not_valid_to_reopen_err if %w[50 51 52 53 54 96 97 98 99].include? previous_active_location

      adv_status = previous_active_location == "77"
      bfmpro = adv_status ? "ADV" : "ACT"
      tikeywrd = adv_status ? "ADVANCE" : "ACTIVE"

      VACOLS::Case.transaction do
        case_record.update!(
          bfmpro: bfmpro,
          bfddec: nil,
          bfdc: nil,
          bfboard: "D1",
          bfmemid: nil,
          bfattid: nil
        )

        case_record.update_vacols_location!(previous_active_location)

        folder_record.update!(
          ticukey: "ACTIVE",
          tikeywrd: tikeywrd,
          tidcls: nil,
          timdtime: VacolsHelper.local_time_with_utc_timezone,
          timduser: user.regional_office
        )

        if reopen_issues
          # Reopen any issues that have the same close information as the appeal
          case_record.case_issues
            .where(issdc: close_disposition, issdcls: close_date)
            .update_all(
              issdc: nil,
              issdcls: nil
            )
        end
      end
    end

    def reopen_remand!(appeal:, user:, disposition_code:)
      case_record = appeal.case_record
      folder_record = case_record.folder
      not_valid_to_reopen_err = AppealNotValidToReopen.new(appeal.id)

      fail not_valid_to_reopen_err unless %w[P W O].include? disposition_code
      fail not_valid_to_reopen_err unless case_record.bfmpro == "HIS"
      fail not_valid_to_reopen_err unless case_record.bfcurloc == LegacyAppeal::LOCATION_CODES[:closed]

      previous_active_location = case_record.previous_active_location

      fail not_valid_to_reopen_err unless %w[50 53 54 62 70 96 97 98].include? previous_active_location
      fail not_valid_to_reopen_err if disposition_code == "P" && %w[53 43].include?(previous_active_location)

      follow_up_appeal_key = "#{case_record.bfkey}P"

      fail not_valid_to_reopen_err unless VACOLS::Case.where(bfkey: follow_up_appeal_key).count == 1

      VACOLS::Case.transaction do
        case_record.update!(bfmpro: "REM")

        case_record.update_vacols_location!(previous_active_location)

        folder_record.update!(
          ticukey: "REMAND",
          tikeywrd: "REMAND",
          timdtime: VacolsHelper.local_time_with_utc_timezone,
          timduser: user.regional_office
        )

        VACOLS::Case.where(bfkey: follow_up_appeal_key).delete_all
        VACOLS::Folder.where(ticknum: follow_up_appeal_key).delete_all
        VACOLS::CaseIssue.where(isskey: follow_up_appeal_key).delete_all
      end
    end

    # If an appeal was previously decided, we are just restoring data, we do not have to reset the appeal to active
    # original_data example: { disposition_code: "G", decision_date: "2019-11-30", folder_decision_date: "2019-11-30" }
    def rollback_opt_in_on_decided_appeal!(appeal:, user:, original_data:)
      opt_in_disposition = Constants::VACOLS_DISPOSITIONS_BY_ID[LegacyIssueOptin::VACOLS_DISPOSITION_CODE]
      return unless appeal.disposition == opt_in_disposition

      case_record = appeal.case_record
      folder_record = case_record.folder

      VACOLS::Case.transaction do
        case_record.update!(
          bfddec: original_data[:decision_date],
          bfdc: original_data[:disposition_code]
        )

        folder_record.update!(
          tidcls: original_data[:folder_decision_date],
          timdtime: VacolsHelper.local_time_with_utc_timezone,
          timduser: user.regional_office
        )
      end
    end

    def certify(appeal:, certification:)
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

    def aod(vacols_id)
      VACOLS::Case.aod([vacols_id])[vacols_id]
    end

    def remand_return_date(vacols_id)
      VACOLS::Case.remand_return_date([vacols_id])[vacols_id]
    end

    def load_user_case_assignments_from_vacols(css_id)
      MetricsService.record("VACOLS: active_cases_for_user #{css_id}",
                            service: :vacols,
                            name: "active_cases_for_user") do
        active_cases_for_user = VACOLS::CaseAssignment.active_cases_for_user(css_id)
        active_cases_for_user = QueueRepository.filter_duplicate_tasks(active_cases_for_user, css_id)
        active_cases_vacols_ids = active_cases_for_user.map(&:vacols_id)
        active_cases_aod_results = VACOLS::Case.aod(active_cases_vacols_ids)
        active_cases_issues = VACOLS::CaseIssue.descriptions(active_cases_vacols_ids)
        active_cases_for_user.map do |assignment|
          assignment_issues_hash_array = active_cases_issues[assignment.vacols_id] || []

          # if that appeal is not found, it intializes a new appeal with the
          # assignments vacols_id
          appeal = LegacyAppeal.find_or_initialize_by(vacols_id: assignment.vacols_id)
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

    def case_assignment_exists?(vacols_id)
      VACOLS::CaseAssignment.exists_for_appeals([vacols_id])[vacols_id]
    end

    def docket_counts_by_priority_and_readiness
      MetricsService.record("VACOLS: docket_counts_by_priority_and_readiness",
                            name: "docket_counts_by_priority_and_readiness",
                            service: :vacols) do
        VACOLS::CaseDocket.counts_by_priority_and_readiness
      end
    end

    def genpop_priority_count
      MetricsService.record("VACOLS: genpop_priority_count",
                            name: "genpop_priority_count",
                            service: :vacols) do
        VACOLS::CaseDocket.genpop_priority_count
      end
    end

    def priority_ready_appeal_vacols_ids
      MetricsService.record("VACOLS: priority_ready_appeal_vacols_ids",
                            name: "priority_ready_appeal_vacols_ids",
                            service: :vacols) do
        VACOLS::CaseDocket.priority_ready_appeal_vacols_ids
      end
    end

    def nod_count
      MetricsService.record("VACOLS: nod_count",
                            name: "nod_count",
                            service: :vacols) do
        VACOLS::CaseDocket.nod_count
      end
    end

    def regular_non_aod_docket_count
      MetricsService.record("VACOLS: regular_non_aod_docket_count",
                            name: "regular_non_aod_docket_count",
                            service: :vacols) do
        VACOLS::CaseDocket.regular_non_aod_docket_count
      end
    end

    def latest_docket_month
      result = MetricsService.record("VACOLS: latest_docket_month",
                                     name: "latest_docket_month",
                                     service: :vacols) do
        VACOLS::CaseDocket.docket_date_of_nth_appeal_in_case_storage(7000)
      end

      result.beginning_of_month
    end

    def docket_counts_by_month
      MetricsService.record("VACOLS: docket_counts_by_month",
                            name: "docket_counts_by_month",
                            service: :vacols) do
        VACOLS::CaseDocket.docket_counts_by_month
      end
    end

    def age_of_n_oldest_genpop_priority_appeals(num)
      MetricsService.record("VACOLS: age_of_n_oldest_genpop_priority_appeals",
                            name: "age_of_n_oldest_genpop_priority_appeals",
                            service: :vacols) do
        VACOLS::CaseDocket.age_of_n_oldest_genpop_priority_appeals(num)
      end
    end

    def age_of_oldest_priority_appeal
      MetricsService.record("VACOLS: age_of_oldest_priority_appeal",
                            name: "age_of_oldest_priority_appeal",
                            service: :vacols) do
        VACOLS::CaseDocket.age_of_oldest_priority_appeal
      end
    end

    def nonpriority_decisions_per_year
      MetricsService.record("VACOLS: nonpriority_decisions_per_year",
                            name: "nonpriority_decisions_per_year",
                            service: :vacols) do
        VACOLS::CaseDocket.nonpriority_decisions_per_year
      end
    end

    def distribute_priority_appeals(judge, genpop, limit)
      MetricsService.record("VACOLS: distribute_priority_appeals",
                            name: "distribute_priority_appeals",
                            service: :vacols) do
        VACOLS::CaseDocket.distribute_priority_appeals(judge, genpop, limit)
      end
    end

    def distribute_nonpriority_appeals(judge, genpop, range, limit, bust_backlog)
      MetricsService.record("VACOLS: distribute_nonpriority_appeals",
                            name: "distribute_nonpriority_appeals",
                            service: :vacols) do
        VACOLS::CaseDocket.distribute_nonpriority_appeals(judge, genpop, range, limit, bust_backlog)
      end
    end

    private

    # NOTE: this should be called within a transaction where you are closing an appeal
    def close_associated_hearings(case_record)
      # Only scheduled hearings need to be closed
      case_record.case_hearings.where(clsdate: nil, hearing_disp: nil).update_all(
        clsdate: VacolsHelper.local_time_with_utc_timezone,
        hearing_disp: VACOLS::CaseHearing::HEARING_DISPOSITION_CODES[:cancelled]
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
