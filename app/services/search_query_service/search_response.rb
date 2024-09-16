# frozen_string_literal: true

SearchQueryService::SearchResponse = Struct.new(:appeal, :type, :api_response) do
  def filter_restricted_info!(statuses)
    if statuses.include?(api_response.attributes.status)
      api_response.attributes.assigned_to_location = nil
    end
  end
end
