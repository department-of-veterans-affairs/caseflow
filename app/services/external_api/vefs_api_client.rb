# frozen_string_literal: true

class ExternalApi::VefsApiClient
  def fetch_cmp_document_content_by_uuid(cmp_document_uuid)
    doc_content = nil

    response = do_api_request(
      endpoint: v1_api_files_endpoint(cmp_document_uuid),
      method: :get
    )

    if response.success?
      # Parse content from JSON response
      doc_content = response.body
    end

    doc_content
  end

  private

  def do_api_request(endpoint:, method:, params: nil, headers: nil)
    response = nil

    begin
      case method
      when :get
        response = api_connection.get(endpoint, params, headers)
      else
        fail "Unsupported HTTP method: #{method}"
      end
    rescue Faraday::Error => error
      # Error reporting here
    end

    response
  end

  def api_connection
    # Set Faraday to use a bearer token for auth, send/receive JSON, and
    # raise an error on 4xx and 5xx responses
    @api_connection ||= Faraday.new(url: base_url) do |builder|
      builder.request :authorization, "Bearer", -> { bearer_token }
      builder.request :json
      builder.response :json
      builder.response :raise_error
    end
  end

  def base_url
    "http://localhost:8080"
  end

  def bearer_token
    SecureRandom.uuid
  end

  def v1_api_files_endpoint(cmp_document_uuid)
    "/api/v1/rest/files/#{cmp_document_uuid}/content"
  end
end
