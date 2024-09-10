# frozen_string_literal: true

class Metric < CaseflowRecord
  belongs_to :user
  delegate :css_id, to: :user

  METRIC_TYPES = { error: "error", log: "log", performance: "performance", info: "info" }.freeze
  LOG_SYSTEMS = {
    dynatrace: "dynatrace",
    rails_console: "rails_console",
    javascript_console: "javascript_console"
  }.freeze
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

  validates :metric_type, inclusion: { in: METRIC_TYPES.values }
  validates :metric_product, inclusion: { in: PRODUCT_TYPES.values }
  validates :metric_group, inclusion: { in: METRIC_GROUPS.values }
  validates :app_name, inclusion: { in: APP_NAMES.values }
  validate :sent_to_in_log_systems

  def self.create_metric(klass, params, user)
    create(default_object(klass, params, user))
  end

  def self.create_metric_from_rest(klass, params, user)
    params[:metric_attributes] = JSON.parse(params[:metric_attributes]) if params[:metric_attributes]
    params[:additional_info] = JSON.parse(params[:additional_info]) if params[:additional_info]
    params[:sent_to_info] = JSON.parse(params[:sent_to_info]) if params[:sent_to_info]
    params[:relevant_tables_info] = JSON.parse(params[:relevant_tables_info]) if params[:relevant_tables_info]

    create(default_object(klass, params, user))
  end

  def sent_to_in_log_systems
    invalid_systems = sent_to - LOG_SYSTEMS.values
    msg = "contains invalid log systems. The following are valid log systems #{LOG_SYSTEMS.values}"
    errors.add(:sent_to, msg) if !invalid_systems.empty?
  end

  # Returns an object with defaults set if below symbols are not found in params default object.
  # Looks for these symbols in params parameter
  # - uuid
  # - name
  # - group
  # - message
  # - type
  # - product
  # - app_name
  # - metric_attributes
  # - additional_info
  # - sent_to
  # - sent_to_info
  # - relevant_tables_info
  # - start
  # - end
  # - duration

  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength
  # :reek:ControlParameter
  def self.default_object(klass, params, user)
    product_types = PRODUCT_TYPES
    {
      uuid: params[:uuid],
      event_id: params[:event_id],
      user: user || RequestStore.store[:current_user] || User.system_user,
      metric_name: params[:name] || METRIC_TYPES[:log],
      metric_class: klass&.try(:name) || klass&.class&.name || name,
      metric_group: params[:group] || METRIC_GROUPS[:service],
      metric_message: params[:message] || METRIC_TYPES[:log],
      metric_type: params[:type] || METRIC_TYPES[:log],
      metric_product: product_types[params[:product].to_sym] || product_types[:caseflow],
      app_name: params[:app_name] || APP_NAMES[:caseflow],
      metric_attributes: params[:metric_attributes],
      additional_info: params[:additional_info],
      sent_to: Array(params[:sent_to]).flatten,
      sent_to_info: params[:sent_to_info],
      relevant_tables_info: params[:relevant_tables_info],
      start: params[:start],
      end: params[:end],
      duration: calculate_duration(params[:start], params[:end], params[:duration])
    }
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength

  def self.calculate_duration(start, end_time, duration)
    return duration if duration || !start || !end_time

    end_time - start
  end
end
