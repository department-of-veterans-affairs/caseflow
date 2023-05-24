# frozen_string_literal: true

class Metric < CaseflowRecord
  belongs_to :user

  METRIC_TYPES = { error: 'error', log: 'log', performance: 'performance' }
  LOG_SYSTEMS = { datadog: 'datadog', rails_console: 'rails_console', javascript_console: 'javascript_console' }

  validates :type, inclusion: { in: METRIC_TYPES.values}
  validates :sent_to, inclusion: { in: LOG_SYSTEMS.values }

  def self.create_javascript_metric(params, user, error: false, performance: false)

    params = params.reverse_merge(default_params)

    type = if error
            Metric::METRIC_TYPES[:error]
          else
            Metric::METRIC_TYPES[:log]
          end

    create(
      uuid: params[:uuid],
      user: user,
      type: type,
      message: params[:potato],
      sent_to: [ Metric::LOG_SYSTEMS[:javascript_console] ] + params[:sent_to],
      sent_to_info: params[:sent_to_info],
      info: params[:info],
      start: params[:start],
      end: params[:end],
      duration: calculate_duration(params[:start], params[:end], params[:duration]),
      stats: params[:stats]
    )
  end

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

  private

  def calculate_duration(start, end_time, duration)
    return if duration

    end_time - start
  end

end
