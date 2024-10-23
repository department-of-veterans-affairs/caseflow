# frozen_string_literal: true

class SearchQueryService::LegacyAppealRow
  def initialize(search_row, vacols_row)
    @search_row = search_row
    @vacols_row = vacols_row
  end

  def search_response
    SearchQueryService::SearchResponse.new(
      legacy_appeal,
      :legacy_appeal,
      SearchQueryService::ApiResponse.new(
        id: search_row["id"],
        type: "legacy_appeal",
        attributes: attributes
      )
    )
  end

  private

  attr_reader :search_row, :vacols_row

  # rubocop:disable Metrics/MethodLength
  def attributes
    SearchQueryService::LegacyAttributes.new(
      aod: aod,
      appellant_full_name: appellant_full_name,
      assigned_attorney: assigned_attorney,
      assigned_judge: assigned_judge,
      assigned_to_location: vacols_row["bfcurloc"],
      caseflow_veteran_id: search_row["veteran_id"],
      decision_date: decision_date,
      docket_name: "legacy",
      docket_number: docket_number,
      external_id: vacols_row["vacols_id"],
      hearings: hearings,
      issues: issues,
      mst: mst,
      overtime: search_row["overtime"],
      pact: pact,
      paper_case: paper_case,
      readable_hearing_request_type: readable_hearing_request_type,
      readable_original_hearing_request_type: readable_original_hearing_request_type,
      status: status,
      type: stream_type,
      veteran_appellant_deceased: veteran_appellant_deceased,
      veteran_file_number: search_row["veteran_file_number"],
      veteran_full_name: veteran_full_name
    )
  end
  # rubocop:enable Metrics/MethodLength

  def docket_number
    vacols_row["tinum"].presence || "Missing Docket Number"
  end

  def hearings
    vacols_json_array("hearings").map do |attrs|
      HearingAttributes.new(attrs).call
    end
  end

  class HearingAttributes
    def initialize(attributes)
      @attributes = attributes
    end

    def call
      {
        disposition: VACOLS::CaseHearing::HEARING_DISPOSITIONS[attributes["disposition"].try(:to_sym)],
        request_type: attributes["type"],
        appeal_type: VACOLS::Case::TYPES[attributes["bfac"]],
        external_id: attributes["external_id"],
        held_by: held_by,
        is_virtual: false,
        notes: attributes["notes"],
        type: type,
        created_at: nil,
        scheduled_in_timezone: nil,
        date: hearing_date
      }
    end

    private

    attr_reader :attributes

    def hearing_date
      if attributes["date"].present?
        HearingMapper.datetime_based_on_type(
          datetime: attributes["date"],
          regional_office: regional_office(attributes["venue"]),
          type: attributes["type"]
        )
      end
    end

    def type
      Hearing::HEARING_TYPES[attributes["hearing_type"]&.to_sym]
    end

    def held_by
      fname = attributes["held_by_first_name"]
      lname = attributes["held_by_last_name"]

      if fname.present? && lname.present?
        "#{fname} #{lname}"
      end
    end

    def regional_office(ro_key)
      RegionalOffice.find!(ro_key)
    rescue RegionalOffice::NotFoundError
      nil
    end
  end

  def issues
    vacols_json_array("issues").map do |attrs|
      WorkQueue::LegacyIssueSerializer.new(
        Issue.load_from_vacols(attrs)
      ).serializable_hash[:data][:attributes]
    end
  end

  def assigned_attorney
    json_array("assigned_attorney").first
  end

  def assigned_judge
    json_array("assigned_judge").first
  end

  def json_array(key)
    JSON.parse(search_row[key].presence || "[]")
  end

  def vacols_json_array(key)
    JSON.parse(vacols_row[key].presence || "[]")
  end

  def veteran_appellant_deceased
    search_row["date_of_death"].present? &&
      search_row["person_first_name"].present?
  end

  def stream_type
    VACOLS::Case::TYPES[vacols_row["bfac"]]
  end

  def status
    VACOLS::Case::STATUS[vacols_row["bfmpro"]]
  end

  def paper_case
    folder = Struct.new(:tivbms, :tisubj2).new(
      vacols_row["tivbms"],
      vacols_row["tisubj2"]
    )
    AppealRepository.folder_type_from(folder)
  end

  def mst
    vacols_row["issues_mst_count"].to_i > 0
  end

  def pact
    vacols_row["issues_pact_count"].to_i > 0
  end

  def appellant_full_name
    FullName.new(
      vacols_row["sspare2"],
      vacols_row["sspare3"],
      vacols_row["sspare1"]
    ).to_s.upcase
  end

  def veteran_full_name
    FullName.new(vacols_row["snamef"], vacols_row["snamemi"], vacols_row["snamel"]).to_s
  end

  def aod
    vacols_row["aod"].to_i == 1
  end

  def decision_date
    AppealRepository.normalize_vacols_date(vacols_row["bfddec"])
  end

  def readable_original_hearing_request_type
    legacy_appeal.readable_original_hearing_request_type
  end

  def readable_hearing_request_type
    legacy_appeal.readable_current_hearing_request_type
  end

  def legacy_appeal
    @legacy_appeal ||= begin
      appeal_attrs, = JSON.parse search_row["appeal"]
      SearchQueryService::QueriedLegacyAppeal.new(attributes: appeal_attrs)
    end
  end
end
