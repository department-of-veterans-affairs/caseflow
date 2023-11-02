# config/initializers/opentelemetry.rb

# pending cutover
require 'datadog/opentelemetry'
# required imports
require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'
require 'opentelemetry/instrumentation/all'

# Exporter and Processor configuration
otel_exporter = OpenTelemetry::Exporter::OTLP::Exporter.new
processor = OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(otel_exporter)

OpenTelemetry::SDK.configure do |c|
  # Exporter and Processor configuration
  c.add_span_processor(processor) # Created above this SDK.configure block

  # Resource configuration
  c.resource = OpenTelemetry::SDK::Resources::Resource.create({
    OpenTelemetry::SemanticConventions::Resource::SERVICE_NAMESPACE => 'Caseflow',
    OpenTelemetry::SemanticConventions::Resource::SERVICE_NAME => 'rails',
    OpenTelemetry::SemanticConventions::Resource::SERVICE_INSTANCE_ID => Socket.gethostname,
    OpenTelemetry::SemanticConventions::Resource::SERVICE_VERSION => "0.0.0"
  })

  # Instruments
  c.use 'OpenTelemetry::Instrumentation::Rack'
  c.use 'OpenTelemetry::Instrumentation::ActionPack'
  c.use 'OpenTelemetry::Instrumentation::ActionView'
  c.use 'OpenTelemetry::Instrumentation::ActiveJob'
  c.use 'OpenTelemetry::Instrumentation::ActiveRecord'
  c.use 'OpenTelemetry::Instrumentation::ConcurrentRuby'
  c.use 'OpenTelemetry::Instrumentation::Faraday'
  c.use 'OpenTelemetry::Instrumentation::HttpClient'
  c.use 'OpenTelemetry::Instrumentation::Net::HTTP'
  c.use 'OpenTelemetry::Instrumentation::PG', {
    db_statement: :obfuscate,
  }
  c.use 'OpenTelemetry::Instrumentation::Rails'
  c.use 'OpenTelemetry::Instrumentation::Redis'
  # c.use 'OpenTelemetry::Instrumentation::RestClient'
  # c.use 'OpenTelemetry::Instrumentation::RubyKafka'
  # c.use 'OpenTelemetry::Instrumentation::Sidekiq'
end
