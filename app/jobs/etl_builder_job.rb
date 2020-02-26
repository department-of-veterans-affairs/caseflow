# frozen_string_literal: true

# Run the ETL::Builder regularly.

class ETLBuilderJob < CaseflowJob
  queue_with_priority :low_priority
  application_attr :etl

  SLACK_CHANNEL = "#appeals-delta"
  DATADOG_NAME = "etl_builder_job"

  def perform
    RequestStore.store[:current_user] = User.system_user

    build_etl
  end

  private

  def build_etl
    etl_build = ETL::Builder.new.incremental

    datadog_report_runtime(metric_group_name: DATADOG_NAME)

    msg = "ETL failed to sync any records"

    slack_service.send_notification(msg, self.class.to_s, SLACK_CHANNEL) if etl_build.built == 0
  end
end
