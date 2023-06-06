# frozen_string_literal: true

class Metric < CaseflowRecord
  belongs_to :user

  METRIC_TYPES = { error: 'error', log: 'log', performance: 'performance' }
  LOG_SYSTEMS = { datadog: 'datadog', rails_console: 'rails_console', javascript_console: 'javascript_console' }
  PRODUCT_TYPES = {
    queue: 'queue',
    hearings: 'hearings',
    intake: 'intake',
    vha: 'vha',
    efolder: 'efolder',
    reader: 'reader',
    caseflow: 'caseflow', # Default product
    # Added below because MetricService has usages of this as a service
    vacols: 'vacols',
    bgs: 'bgs',
    gov_delivery: 'gov_delivery',
    mpi: 'mpi',
    pexip: 'pexip',
    va_dot_gov: 'va_dot_gov',
    va_notify: 'va_notify',
    vbms: 'vbms',
  }
  APP_NAMES = { caseflow: 'caseflow', efolder: 'efolder' }
  METRIC_GROUPS = { service: 'service' }

  validates :metric_type, inclusion: { in: METRIC_TYPES.values}
  validates :metric_product, inclusion: { in: PRODUCT_TYPES.values }
  validates :metric_group, inclusion: { in: METRIC_GROUPS.values }
  validates :app_name, inclusion: { in: APP_NAMES.values }
  validate :sent_to_in_log_systems

  def self.create_metric(caller, params, user)
    create( default_object(caller, params, user) )
  end

  def self.create_metric_from_rest(caller, params, user)
    params[:metric_attributes] = JSON.parse(params[:metric_attributes]) if params[:metric_attributes]
    params[:additional_info] = JSON.parse(params[:additional_info]) if params[:additional_info]
    params[:sent_to_info] = JSON.parse(params[:sent_to_info]) if params[:sent_to_info]
    params[:relevant_tables_info] = JSON.parse(params[:relevant_tables_info]) if params[:relevant_tables_info]

    create( default_object(caller, params, user) )
  end

  def sent_to_in_log_systems
    invalid_systems = sent_to - LOG_SYSTEMS.values
    msg = "contains invalid log systems. The following are valid log systems #{LOG_SYSTEMS.values}"
    errors.add(:sent_to, msg) if invalid_systems.size > 0
  end

  private

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
  def self.default_object(caller, params, user)
    {
      uuid: params[:uuid],
      user: user,
      metric_name: params[:name] || METRIC_TYPES[:log],
      metric_class: caller&.name || self.name,
      metric_group: params[:group] || METRIC_GROUPS[:service],
      metric_message: params[:message] || METRIC_TYPES[:log],
      metric_type: params[:type] || METRIC_TYPES[:log],
      metric_product: PRODUCT_TYPES[params[:product]] || PRODUCT_TYPES[:caseflow],
      app_name: params[:app_name] || APP_NAMES[:caseflow],
      metric_attributes: params[:metric_attributes],
      additional_info: params[:additional_info],
      sent_to: Array(params[:sent_to]).flatten,
      sent_to_info: params[:sent_to_info],
      relevant_tables_info: params[:relevant_tables_info],
      start: params[:start],
      end: params[:end],
      duration: calculate_duration(params[:start], params[:end], params[:duration]),
    }
  end

  def self.calculate_duration(start, end_time, duration)
    return duration if duration || !start || !end_time

    end_time - start
  end

end
