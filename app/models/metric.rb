# frozen_string_literal: true

class Metric < CaseflowRecord
  belongs_to :user
  delegate :css_id, to: :user

  validates :metric_type, inclusion: { in: MetricAttributes::METRIC_TYPES.values }
  validates :metric_product, inclusion: { in: MetricAttributes::METRIC_GROUPS.values }
  validates :metric_group, inclusion: { in: MetricAttributes::METRIC_GROUPS.values }
  validates :app_name, inclusion: { in: MetricAttributes::METRIC_TYPES.values }
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
    invalid_systems = sent_to - MetricAttributes::LOG_SYSTEMS.values
    msg = "contains invalid log systems. The following are valid log systems #{MetricAttributes::LOG_SYSTEMS.values}"
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

  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  # :reek:ControlParameter
  def self.default_object(klass, params, user)
    {
      uuid: params[:uuid],
      user: user || RequestStore.store[:current_user] || User.system_user,
      metric_name: params[:name] || MetricAttributes::METRIC_TYPES[:log],
      metric_class: klass&.try(:name) || klass&.class&.name || name,
      metric_group: params[:group] || MetricAttributes::METRIC_GROUPS[:service],
      metric_message: params[:message] || MetricAttributes::METRIC_TYPES[:log],
      metric_type: params[:type] || MetricAttributes::METRIC_TYPES[:log],
      metric_product: MetricAttributes::METRIC_GROUPS[params[:product].to_sym] || MetricAttributes::METRIC_GROUPS[:caseflow],
      app_name: params[:app_name] || MetricAttributes::METRIC_TYPES[:caseflow],
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
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  def self.calculate_duration(start, end_time, duration)
    return duration if duration || !start || !end_time

    end_time - start
  end
end
