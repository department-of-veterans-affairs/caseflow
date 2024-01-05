# frozen_string_literal: true

class ExternalApi::VBMSRequest
  def initialize(client:, request:, id:)
    @client = client
    @request = request
    @id = id
  end

  def call
    MetricsService.record("sent VBMS request #{request.class} for #{id}",
                          service: :vbms,
                          name: metrics_class_name) do
      client.send_request(request)
    end
  end

  private

  attr_reader :request, :client, :id

  def metrics_class_name
    request.class.name.split("::").last
  end
end
