# config/initializers/datadog-tracer.rb
dd_trace_enabled = !Rails.env.development?

Rails.configuration.datadog_trace = {
  enabled: dd_trace_enabled,
  auto_instrument: true,
  auto_instrument_redis: true,
  default_service: 'Caseflow'
}
