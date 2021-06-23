# frozen_string_literal: true

class CachedAppealService
  # rubocop:disable Metrics/MethodLength
  def cache_ama_appeals(appeals)
    import_cached_appeals([:appeal_id, :appeal_type], AMA_CACHED_COLUMNS) do
      request_issues_to_cache = request_issue_counts_for_appeal_ids(appeals.pluck(:id))
      veteran_names_to_cache = veteran_names_for_file_numbers(appeals.pluck(:veteran_file_number))

      appeal_aod_status = aod_status_for_appeals(appeals)
      appeals.map do |appeal|
        {
          appeal_id: appeal.id,
          appeal_type: Appeal.name,
          case_type: appeal.type,
          issue_count: request_issues_to_cache[appeal.id] || 0,
          docket_type: appeal.docket_type,
          docket_number: appeal.docket_number,
          hearing_request_type: appeal.readable_current_hearing_request_type,
          is_aod: appeal_aod_status.include?(appeal.id),
          suggested_hearing_location: appeal.suggested_hearing_location&.formatted_location,
          veteran_name: veteran_names_to_cache[appeal.veteran_file_number]
        }.merge(
          regional_office_fields_to_cache(appeal)
        )
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

  def cache_legacy_appeal_postgres_data(legacy_appeals)
    import_cached_appeals([:appeal_id, :appeal_type], POSTGRES_LEGACY_CACHED_COLUMNS) do
      legacy_appeals.map do |appeal|
        {
          vacols_id: appeal.vacols_id,
          appeal_id: appeal.id,
          appeal_type: LegacyAppeal.name,
          docket_type: appeal.docket_name, # "legacy"
          suggested_hearing_location: appeal.suggested_hearing_location&.formatted_location
        }.merge(
          regional_office_fields_to_cache(appeal)
        )
      end
    end
  end

  # rubocop:disable Metrics/MethodLength
  def cache_legacy_appeal_vacols_data(vacols_ids)
    import_cached_appeals([:vacols_id], VACOLS_CACHED_COLUMNS) do
      vacols_folders = folder_fields_for_vacols_ids(vacols_ids)
      vacols_cases = case_fields_for_vacols_ids(vacols_ids)

      issue_counts_to_cache = issues_counts_for_vacols_folders(vacols_ids)
      aod_status_to_cache = VACOLS::Case.aod(vacols_ids)

      correspondent_ids = vacols_folders.map { |folder| folder[:correspondent_id] }
      veteran_names_to_cache = veteran_names_for_correspondent_ids(correspondent_ids)

      vacols_folders.map do |folder|
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
    end
  end
  # rubocop:enable Metrics/MethodLength

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
    :suggested_hearing_location,
    :veteran_name
  ].freeze
  POSTGRES_LEGACY_CACHED_COLUMNS = [
    :closest_regional_office_city,
    :closest_regional_office_key,
    :vacols_id,
    :docket_type,
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

  # This clause prevents the import query from inserting older data if it was already cached
  # by a different job.
  def conflict_clause(start_time)
    "#{CachedAppeal.table_name}.updated_at < #{ActiveRecord::Base.connection.quote(start_time)}"
  end

  # Wrapper method for import calls.
  def import_cached_appeals(conflict_columns, columns)
    start_time = Time.now.utc

    values_to_cache = yield

    CachedAppeal.import(
      values_to_cache,
      on_duplicate_key_update: {
        conflict_target: conflict_columns,
        condition: conflict_clause(start_time),
        columns: columns
      }
    )

    values_to_cache
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

  def regional_office_fields_to_cache(appeal)
    regional_office = RegionalOffice::CITIES[appeal.closest_regional_office]

    {
      closest_regional_office_city: regional_office&.fetch(:city, COPY::UNKNOWN_REGIONAL_OFFICE),
      closest_regional_office_key: (
        regional_office ? appeal.closest_regional_office : COPY::UNKNOWN_REGIONAL_OFFICE
      )
    }
  end

  def aod_status_for_appeals(appeals)
    Appeal.where(id: appeals).joins(
      "left join claimants on appeals.id = claimants.decision_review_id and "\
      "claimants.decision_review_type = 'Appeal' "\
      "left join people on people.participant_id = claimants.participant_id "\
      "left join advance_on_docket_motions on advance_on_docket_motions.person_id = people.id "
    ).where(
      "(advance_on_docket_motions.granted = true and advance_on_docket_motions.created_at > appeals.receipt_date) "\
      "or people.date_of_birth < (current_date - interval '75 years')"
    ).pluck(:id)
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
      original_request = original_hearing_request_type_for_vacols_case(vacols_case)
      changed_request = hearing_request_types_for_all_vacols_ids[vacols_case.bfkey]&.[](:changed)
      # Replicates HearingRequestTypeConcern#current_hearing_request_type
      current_request = HearingDay::REQUEST_TYPES.key(changed_request)&.to_sym || original_request

      [
        vacols_case.bfkey,
        {
          location: vacols_case.bfcurloc,
          status: VACOLS::Case::TYPES[vacols_case.bfac],
          hearing_request_type: LegacyAppeal::READABLE_HEARING_REQUEST_TYPES[current_request],
          former_travel: original_request == :travel_board && current_request != :travel_board
        }
      ]
    end.to_h
  end

  def folder_fields_for_vacols_ids(vacols_ids)
    VACOLS::Folder
      .where(ticknum: vacols_ids)
      .pluck(:ticknum, :tinum, :ticorkey)
      .map do |folder|
        {
          vacols_id: folder[0],
          docket_number: folder[1],
          correspondent_id: folder[2]
        }
      end
  end

  # Gets the symbolic representation of the original type of hearing requested for a vacols case record
  def original_hearing_request_type_for_vacols_case(vacols_case)
    # return the value saved in caseflow's database if it exists
    request_type = hearing_request_types_for_all_vacols_ids[vacols_case.bfkey]&.[](:original)
    return request_type.to_sym if request_type.present?

    # get the value from cached VACOLS data
    # redundant with logic in HearingRequestTypeConcern and AppealRepository
    request_type = VACOLS::Case::HEARING_REQUEST_TYPES[vacols_case.bfhr]

    (request_type == :travel_board && vacols_case.bfdocind == "V") ? :video : request_type
  end

  # Maps vacols ids to their leagcy appeal's changed hearing request type
  def hearing_request_types_for_all_vacols_ids
    @hearing_request_types_for_all_vacols_ids ||= LegacyAppeal
      .where
      .not(changed_hearing_request_type: nil)
      .pluck(:vacols_id, :changed_hearing_request_type, :original_hearing_request_type)
      .map { |group| [group[0], { changed: group[1], original: group[2] }] }
      .to_h
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
end
