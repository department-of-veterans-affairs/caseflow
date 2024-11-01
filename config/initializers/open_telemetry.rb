# frozen_string_literal: true
require 'rubygems'
require 'bundler/setup'

require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'

require "opentelemetry-instrumentation-action_pack"
require "opentelemetry-instrumentation-action_view"
require "opentelemetry-instrumentation-active_job"
require "opentelemetry-instrumentation-active_record"
require "opentelemetry-instrumentation-active_support"
require "opentelemetry-instrumentation-aws_sdk"
require "opentelemetry-instrumentation-concurrent_ruby"
require "opentelemetry-instrumentation-faraday"
require "opentelemetry-instrumentation-http_client"
require "opentelemetry-instrumentation-net_http"
require "opentelemetry-instrumentation-pg"
require "opentelemetry-instrumentation-rack"
require "opentelemetry-instrumentation-rails"
require "opentelemetry-instrumentation-rake"
require "opentelemetry-instrumentation-redis"

# rubocop:disable Layout/LineLength

DT_API_URL = ENV["DT_API_URL"]
DT_API_TOKEN = ENV["DT_API_TOKEN"]

Rails.logger.info("DT_API_TOKEN is set to #{DT_API_TOKEN}")

if !Rails.env.development? && !Rails.env.test? && !Rails.env.demo?
  OpenTelemetry::SDK.configure do |c|
    c.service_name = 'caseflow'
    c.service_version = '1.0.1'

    c.use 'OpenTelemetry::Instrumentation::ActiveRecord'
    c.use 'OpenTelemetry::Instrumentation::Rack', { untraced_endpoints: ['/health-check', '/sample', '/logs'] }
    c.use 'OpenTelemetry::Instrumentation::Rails'

    # c.use 'OpenTelemetry::Instrumentation::PG'
    # c.use 'OpenTelemetry::Instrumentation::ActionView'
    # c.use 'OpenTelemetry::Instrumentation::Redis'

    c.use 'OpenTelemetry::Instrumentation::ActionPack'
    c.use 'OpenTelemetry::Instrumentation::ActiveSupport'
    c.use 'OpenTelemetry::Instrumentation::ActiveJob'
    c.use 'OpenTelemetry::Instrumentation::AwsSdk', { suppress_internal_instrumentation: true }
    c.use 'OpenTelemetry::Instrumentation::ConcurrentRuby'
    c.use 'OpenTelemetry::Instrumentation::Faraday'
    c.use 'OpenTelemetry::Instrumentation::HttpClient'
    c.use 'OpenTelemetry::Instrumentation::Net::HTTP'

    Rails.logger.info("Loaded instruments")

    %w[dt_metadata_e617c525669e072eebe3d0f08212e8f2.properties /var/lib/dynatrace/enrichment/dt_host_metadata.properties].each { |name|
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
