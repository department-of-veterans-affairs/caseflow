# frozen_string_literal: true

# Run the ETL::Builder regularly.

class ETLBuilderJob < CaseflowJob
  queue_with_priority :low_priority
  application_attr :etl

  def perform
    RequestStore.store[:current_user] = User.system_user

    sweep_etl
    build_etl
  # Raising an exception triggers a retry through shoryuken.
  # Don't retry via normal shoryuken since this job runs multiple times daily; just log the error.
  rescue StandardError => error
    log_error(error)
    klass = self.class.to_s
    slack_msg = "Error running #{klass}."
    slack_msg += " See Sentry event #{Raven.last_event_id}" if Raven.last_event_id.present?
    slack_service.send_notification(slack_msg, klass)
    # Also send a message to #appeals-data-workgroup
    slack_service.send_notification(slack_msg, klass, "#appeals-data-workgroup")
  end

  private

  def sweep_etl
    start = Time.zone.now
    swept = ETL::Sweeper.new.call
    datadog_report_time_segment(segment: "etl_sweeper", start_time: start)

    return unless swept > 20 # big enough to warrant reality check

    msg = "[INFO] ETL swept up #{swept} deleted records -- see logs for details"
    slack_service.send_notification(msg, "ETL::Sweeper")
  end

  def build_etl
    start = Time.zone.now
    etl_build = ETL::Builder.new.incremental
    datadog_report_time_segment(segment: "etl_builder", start_time: start)

    return unless etl_build.built == 0

    msg = "[WARN] ETL failed to sync any records"
    slack_service.send_notification(msg, self.class.to_s)
  end
end
