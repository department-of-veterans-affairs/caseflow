# frozen_string_literal: true

class CachedAppealService
  class << self
    def cache_ama_appeals(appeals)
      start_time = Time.now.utc
      request_issues_to_cache = request_issue_counts_for_appeal_ids(appeals.pluck(:id))
      veteran_names_to_cache = veteran_names_for_file_numbers(appeals.pluck(:veteran_file_number))

      appeal_aod_status = aod_status_for_appeals(appeals)
      representative_names = representative_names_for_appeals(appeals)

      appeals_to_cache = appeals.map do |appeal|
        start_time = Time.now.utc
        regional_office = RegionalOffice::CITIES[appeal.closest_regional_office]
        {
          appeal_id: appeal.id,
          appeal_type: Appeal.name,
          case_type: appeal.type,
          closest_regional_office_city: regional_office ? regional_office[:city] : COPY::UNKNOWN_REGIONAL_OFFICE,
          closest_regional_office_key: regional_office ? appeal.closest_regional_office : COPY::UNKNOWN_REGIONAL_OFFICE,
          issue_count: request_issues_to_cache[appeal.id] || 0,
          docket_type: appeal.docket_type,
          docket_number: appeal.docket_number,
          hearing_request_type: appeal.current_hearing_request_type(readable: true),
          is_aod: appeal_aod_status.include?(appeal.id),
          power_of_attorney_name: representative_names[appeal.id],
          suggested_hearing_location: appeal.suggested_hearing_location&.formatted_location,
          veteran_name: veteran_names_to_cache[appeal.veteran_file_number]
        }
      end

      CachedAppeal.import(
        appeals_to_cache,
        on_duplicate_key_update: {
          conflict_target: [:appeal_id, :appeal_type],
          condition: conflict_clause(start_time),
          columns: AMA_CACHED_COLUMNS
        }
      )

      appeals_to_cache
    end

    def cache_legacy_appeal_postgres_data(legacy_appeals)
      start_time = Time.now.utc
      values_to_cache = legacy_appeals.map do |appeal|
        regional_office = RegionalOffice::CITIES[appeal.closest_regional_office]
        # bypass PowerOfAttorney model completely and always prefer BGS cache
        bgs_poa = fetch_bgs_power_of_attorney_by_file_number(appeal.veteran_file_number)
        {
          vacols_id: appeal.vacols_id,
          appeal_id: appeal.id,
          appeal_type: LegacyAppeal.name,
          closest_regional_office_city: regional_office ? regional_office[:city] : COPY::UNKNOWN_REGIONAL_OFFICE,
          closest_regional_office_key: regional_office ? appeal.closest_regional_office : COPY::UNKNOWN_REGIONAL_OFFICE,
          docket_type: appeal.docket_name, # "legacy"
          power_of_attorney_name: (bgs_poa&.representative_name || appeal.representative_name),
          suggested_hearing_location: appeal.suggested_hearing_location&.formatted_location
        }
      end

      CachedAppeal.import(
        values_to_cache,
        on_duplicate_key_update: {
          conflict_target: [:appeal_id, :appeal_type],
          condition: conflict_clause(start_time),
          columns: POSTGRES_LEGACY_CACHED_COLUMNS
        }
      )

      values_to_cache
    end

    def cache_legacy_appeal_vacols_data(vacols_ids)
      start_time = Time.now.utc
      vacols_folders = VACOLS::Folder
        .where(ticknum: vacols_ids)
        .pluck(:ticknum, :tinum, :ticorkey)
        .map do |folder|
        {
          vacols_id: folder[0],
          docket_number: folder[1],
          correspondent_id: folder[2]
        }
      end

      vacols_cases = case_fields_for_vacols_ids(vacols_ids)

      issue_counts_to_cache = issues_counts_for_vacols_folders(vacols_ids)
      aod_status_to_cache = VACOLS::Case.aod(vacols_ids)

      correspondent_ids = vacols_folders.map { |folder| folder[:correspondent_id] }
      veteran_names_to_cache = veteran_names_for_correspondent_ids(correspondent_ids)

      values_to_cache = vacols_folders.map do |folder|
        vacols_case = vacols_cases[folder[:vacols_id]]

        {
          vacols_id: folder[:vacols_id],
          case_type: vacols_case[:status],
          docket_number: folder[:docket_number],
          former_travel: vacols_case[:former_travel], # true or false
          hearing_request_type: vacols_case[:hearing_request_type],
          issue_count: issue_counts_to_cache[folder[:vacols_id]] || 0,
          is_aod: aod_status_to_cache[folder[:vacols_id]],
          veteran_name: veteran_names_to_cache[folder[:correspondent_id]]
        }
      end

      CachedAppeal.import(
        values_to_cache,
        on_duplicate_key_update: {
          conflict_target: [:vacols_id],
          condition: conflict_clause(start_time),
          columns: VACOLS_CACHED_COLUMNS
        }
      )

      values_to_cache
    end

    private

    AMA_CACHED_COLUMNS = [
      :case_type,
      :closest_regional_office_city,
      :closest_regional_office_key,
      :docket_type,
      :docket_number,
      :hearing_request_type,
      :is_aod,
      :issue_count,
      :power_of_attorney_name,
      :suggested_hearing_location,
      :veteran_name
    ].freeze
    POSTGRES_LEGACY_CACHED_COLUMNS = [
      :closest_regional_office_city,
      :closest_regional_office_key,
      :vacols_id,
      :docket_type,
      :power_of_attorney_name,
      :suggested_hearing_location
    ].freeze
    VACOLS_CACHED_COLUMNS = [
      :docket_number,
      :former_travel,
      :hearing_request_type,
      :issue_count,
      :veteran_name,
      :case_type,
      :is_aod
    ].freeze

    # TODO Comment
    def conflict_clause(start_time)
      "#{CachedAppeal.table_name}.updated_at < #{ActiveRecord::Base.connection.quote(start_time)}"
    end

    def fetch_bgs_power_of_attorney_by_file_number(file_number)
      return if file_number.blank?

      BgsPowerOfAttorney.find_or_create_by_file_number(file_number)
    rescue ActiveRecord::RecordInvalid # not found at BGS
      BgsPowerOfAttorney.new(file_number: file_number)
    end

    def request_issue_counts_for_appeal_ids(appeal_ids)
      RequestIssue.where(decision_review_id: appeal_ids, decision_review_type: Appeal.name)
        .group(:decision_review_id).count
    end

    def veteran_names_for_file_numbers(veteran_file_numbers)
      Veteran.where(file_number: veteran_file_numbers).map do |veteran|
        # Matches how last names are split and sorted on the front end (see: TaskTable.detailsColumn.getSortValue)
        [veteran.file_number, "#{veteran.last_name&.split(' ')&.last}, #{veteran.first_name}"]
      end.to_h
    end

    def aod_status_for_appeals(appeals)
      Appeal.where(id: appeals).joins(
        "left join claimants on appeals.id = claimants.decision_review_id and claimants.decision_review_type = 'Appeal' "\
        "left join people on people.participant_id = claimants.participant_id "\
        "left join advance_on_docket_motions on advance_on_docket_motions.person_id = people.id "
      ).where(
        "(advance_on_docket_motions.granted = true and advance_on_docket_motions.created_at > appeals.receipt_date) "\
        "or people.date_of_birth < (current_date - interval '75 years')"
      ).pluck(:id)
    end

    # Builds a hash of appeal_id => rep name
    def representative_names_for_appeals(appeals)
      Claimant.where(decision_review_id: appeals, decision_review_type: Appeal.name).joins(
        "LEFT JOIN bgs_power_of_attorneys ON bgs_power_of_attorneys.claimant_participant_id = claimants.participant_id"
      ).pluck("claimants.decision_review_id, bgs_power_of_attorneys.representative_name").to_h
    end

    def case_fields_for_vacols_ids(vacols_ids)
      # array of arrays will become hash with bfkey as key.
      # [
      #   [ 123, { location: 57, status: "Original", hearing_request_type: "Video", former_travel: true} ],
      #   [ 456, { location: 2, status: "Court Remand", hearing_request_type: "Video", former_travel: true } ],
      #   ...
      # ]
      # becomes
      # {
      #   123: { location: 57, status: "Original", hearing_request_type: "Video", former_travel: true },
      #   456: { location: 2, status: "Court Remand", hearing_request_type: "Video", former_travel: true },
      #   ...
      # }
      VACOLS::Case.where(bfkey: vacols_ids).map do |vacols_case|
        legacy_appeal = AppealRepository.build_appeal(vacols_case) # build non-persisting legacy appeal object

        [
          vacols_case.bfkey,
          {
            location: vacols_case.bfcurloc,
            status: VACOLS::Case::TYPES[vacols_case.bfac],
            hearing_request_type: legacy_appeal.current_hearing_request_type(readable: true),
            former_travel: former_travel?(legacy_appeal)
          }
        ]
      end.to_h
    end

    def issues_counts_for_vacols_folders(vacols_ids)
      VACOLS::CaseIssue.where(isskey: vacols_ids).group(:isskey).count
    end

    def veteran_names_for_correspondent_ids(correspondent_ids)
      # folders is an array of [ticknum, tinum, ticorkey] for each folder
      VACOLS::Correspondent.where(stafkey: correspondent_ids).map do |corr|
        [corr.stafkey, "#{corr.snamel.split(' ').last}, #{corr.snamef}"]
      end.to_h
    end

    # checks to see if the hearing request type was former_travel
    def former_travel?(legacy_appeal)
      # the current request type is travel
      if legacy_appeal.current_hearing_request_type == :travel_board
        return false
      end

      # otherwise check if og request type was travel
      legacy_appeal.original_hearing_request_type == :travel_board
    end
  end
end
