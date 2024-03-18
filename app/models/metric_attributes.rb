module MetricAttributes
  METRIC_TYPES = { error: "error", log: "log", performance: "performance", info: "info" }.freeze
  LOG_SYSTEMS = { dynatrace: "dynatrace", datadog: "datadog", rails_console: "rails_console", javascript_console: "javascript_console" }.freeze
  PRODUCT_TYPES = {
    queue: "queue",
    hearings: "hearings",
    intake: "intake",
    vha: "vha",
    efolder: "efolder",
    reader: "reader",
    caseflow: "caseflow", # Default product
    # Added below because MetricsService has usages of this as a service
    vacols: "vacols",
    bgs: "bgs",
    gov_delivery: "gov_delivery",
    mpi: "mpi",
    pexip: "pexip",
    va_dot_gov: "va_dot_gov",
    va_notify: "va_notify",
    vbms: "vbms"
  }.freeze
  APP_NAMES = { caseflow: "caseflow", efolder: "efolder" }.freeze
  METRIC_GROUPS = { service: "service" }.freeze
end
