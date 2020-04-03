# frozen_string_literal: true

class VirtualHearings::ConferenceJob < ApplicationJob
  include VirtualHearings::PexipClient

  private

  def datadog_metric_info
    {
      app_name: Constants.DATADOG_METRICS.HEARINGS.APP_NAME,
      metric_group: Constants.DATADOG_METRICS.HEARINGS.VIRTUAL_HEARINGS_GROUP_NAME
    }
  end
end
