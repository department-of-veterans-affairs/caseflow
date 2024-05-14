# frozen_string_literal: true

DT_API_URL = ENV["DT_API_URL"]
DT_API_TOKEN = ENV["DT_API_TOKEN"]
def init_opentelemetry # rubocop:disable Metrics/MethodLength
  OpenTelemetry::SDK.configure do |c|
    c.service_name = "caseflow"
    c.service_version = "1.0.1"
    # automatic instrumentation
    c.use_all
    for name in ["dt_metadata_e617c525669e072eebe3d0f08212e8f2.properties", "/var/lib/dynatrace/enrichment/dt_metadata.properties", "/var/lib/dynatrace/enrichment/dt_host_metadata.properties"] do
      begin
        c.resource = OpenTelemetry::SDK::Resources::Resource.create(Hash[*File.read(name.start_with?("/var") ? name : File.read(name)).split(/[=\n]+/)])
      rescue
      end
    end
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
