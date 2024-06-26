# frozen_string_literal: true

require 'opentelemetry/sdk'
require 'opentelemetry/instrumentation/all'

# rubocop:disable Layout/LineLength

DT_API_URL = ENV["DT_API_URL"]
DT_API_TOKEN = ENV["DT_API_TOKEN"]

Rails.logger.info("DT_API_TOKEN is set to #{DT_API_TOKEN}")

if !Rails.env.development? && !Rails.env.test? && !Rails.env.demo?
  OpenTelemetry::SDK.configure do |c|
    c.service_name = 'ruby-quickstart'
    c.service_version = '1.0.1'
    c.use_all #application will be using all instrumentation provided by OpenTelemetry
    %w[dt_metadata_e617c525669e072eebe3d0f08212e8f2.properties /var/lib/dynatrace/enrichment/dt_metadata.properties].each { |name|
      begin
        c.resource = OpenTelemetry::SDK::Resources::Resource.create(Hash[*File.read(name.start_with?("/var") ? name : File.read(name)).split(/[=\n]+/)])
      rescue
      end
    }
    c.add_span_processor(
      OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
        OpenTelemetry::Exporter::OTLP::Exporter.new(
          endpoint: DT_API_URL + "/v1/traces",
          headers: {
            "Authorization": "Api-Token " + DT_API_TOKEN
          }
        )
      )
    )
  end
end
  # rubocop:enable Layout/LineLength
