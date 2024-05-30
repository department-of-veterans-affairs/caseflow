# frozen_string_literal: true

class ExternalApi::VADotGovService::FacilitiesIdsResponse < ExternalApi::VADotGovService::Response
  def initialize(api_response, ids)
    @ids = ids
    super(api_response)
  end

  def data
    return [] if body[:data].blank?

    body[:data]
  end

  def all_ids_present?
    @ids.all? { |id| data.include?(id) }
  end

  def missing_facility_ids
    return [] if all_ids_present?

    @ids.reject { |id| data.include?(id) }
  end
end
