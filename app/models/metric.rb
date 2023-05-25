# frozen_string_literal: true

class Metric < CaseflowRecord
  belongs_to :user

  METRIC_TYPES = { error: 'error', log: 'log', performance: 'performance' }
  LOG_SYSTEMS = { datadog: 'datadog', rails_console: 'rails_console', javascript_console: 'javascript_console' }

  validates :metric_type, inclusion: { in: METRIC_TYPES.values}
  validate :sent_to_in_log_systems

  def self.create_javascript_metric(params, user, is_error: false, performance: false)

    params = params.reverse_merge(default_params)

    metric_type = if is_error
            METRIC_TYPES[:error]
          else
            METRIC_TYPES[:log]
          end

    create(
      uuid: params[:uuid],
      user: user,
      metric_type: metric_type,
      message: params[:message],
      sent_to: [ LOG_SYSTEMS[:javascript_console] ] + params[:sent_to],
      sent_to_info: params[:sent_to_info],
      info: params[:info],
      start: params[:start],
      end: params[:end],
      duration: calculate_duration(params[:start], params[:end], params[:duration]),
      stats: params[:stats]
    )
  end

  def sent_to_in_log_systems
    invalid_systems = (sent_to - LOG_SYSTEMS.values)
    msg = "contains invalid log systems. The following are valid log systems #{LOG_SYSTEMS.values}"
    errors.add(:sent_to, msg) if invalid_systems.size > 0
  end

  private

  def self.default_params
    {
      sent_to: [],
      sent_to_info: {},
      info: {},
      start: 0,
      end: 0,
      stats: {}
    }
  end

  def self.calculate_duration(start, end_time, duration)
    return if duration

    end_time - start
  end

end
