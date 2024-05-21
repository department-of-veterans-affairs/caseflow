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

  def attributes
    SearchQueryService::LegacyAttributes.new(
      aod: aod,
      appellant_full_name: appellant_full_name,
      assigned_to_location: vacols_row["bfcurloc"],
      caseflow_veteran_id: search_row["veteran_id"],
      decision_date: decision_date,
      docket_name: "legacy",
      docket_number: vacols_row["tinum"],
      external_id: vacols_row["vacols_id"],
      hearings: hearings,
      issues: [{}] * vacols_row["issues_count"],
      mst: mst,
      pact: pact,
      paper_case: paper_case,
      status: status,
      type: stream_type,
      veteran_appellant_deceased: veteran_appellant_deceased,
      veteran_file_number: search_row["veteran_file_number"],
      veteran_full_name: veteran_full_name
    )
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
        date: HearingMapper.datetime_based_on_type(
          datetime: attributes["date"],
          regional_office: regional_office(attributes["venue"]),
          type: attributes["type"]
        )
      }
    end

    private

    attr_reader :attributes

    def regional_office(ro_key)
      RegionalOffice.find!(ro_key)
    rescue NotFoundError
      nil
    end
  end

  def vacols_json_array(key)
    JSON.parse(vacols_row[key] || "[]")
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
    vacols_row["issues_mst_count"] > 0
  end

  def pact
    vacols_row["issues_pact_count"] > 0
  end

  def appellant_full_name
    FullName.new(vacols_row["sspare2"], "", vacols_row["sspare1"]).to_s
  end

  def veteran_full_name
    FullName.new(vacols_row["snamef"], "", vacols_row["snamel"]).to_s
  end

  def aod
    vacols_row["aod"] == 1
  end

  def decision_date
    AppealRepository.normalize_vacols_date(vacols_row["bfddec"])
  end

  def legacy_appeal
    @legacy_appeal ||= begin
      appeal_attrs, = JSON.parse search_row["appeal"]
      SearchQueryService::QueriedLegacyAppeal.new(attributes: appeal_attrs)
    end
  end
end
