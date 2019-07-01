# frozen_string_literal: true

class UntrackedLegacyAppealsReportJob < CaseflowJob
  queue_as :low_priority
  application_attr :queue

  def perform
    send_report(legacy_appeal_ids_without_active_tasks)
  end

  def legacy_appeal_ids_without_active_tasks
    vacols_ids = VACOLS::Case.where(bfcurloc: LegacyAppeal::LOCATION_CODES[:caseflow]).pluck(:bfkey)
    legacy_appeals_charged_to_caseflow_ids = LegacyAppeal.where(vacols_id: vacols_ids).pluck(:id)
    legacy_appeal_with_active_tasks_ids = Task.where.not(
      type: [RootTask.name, TrackVeteranTask.name]
    ).where(appeal_type: LegacyAppeal.name, appeal_id: legacy_appeals_charged_to_caseflow_ids).pluck(:appeal_id).uniq

    legacy_appeals_charged_to_caseflow_ids.sort - legacy_appeal_with_active_tasks_ids.sort
  end

  def send_report(appeal_ids)
    return if appeal_ids.empty?

    msg = "Found #{appeal_ids.count} legacy appeals charged to CASEFLOW in VACOLS with no active Caseflow tasks.\n"
    msg += "LegacyAppeal.where(id: #{appeal_ids.sort})"

    Rails.logger.info(msg)
    slack_service.send_notification(msg)
  end
end
