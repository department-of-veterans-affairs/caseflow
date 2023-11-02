# frozen_string_literal: true

require "opentelemetry/sdk"

class OpenTelemetryService
  @otel = OpenTelemetry::SDK.new
