# frozen_string_literal: true

class UntrackedLegacyAppealsChecker < DataIntegrityChecker
  def call
    appeal_ids = legacy_appeal_ids_without_active_tasks
    build_report(appeal_ids)
  end

  private

  def legacy_appeal_ids_without_active_tasks
    vacols_ids = VACOLS::Case.where(bfcurloc: LegacyAppeal::LOCATION_CODES[:caseflow]).pluck(:bfkey)
    legacy_appeals_charged_to_caseflow_ids = LegacyAppeal.where(vacols_id: vacols_ids).pluck(:id)
    legacy_appeal_with_active_tasks_ids = Task.where.not(
      type: [RootTask.name, TrackVeteranTask.name]
    ).where(appeal_type: LegacyAppeal.name, appeal_id: legacy_appeals_charged_to_caseflow_ids).pluck(:appeal_id).uniq

    legacy_appeals_charged_to_caseflow_ids.sort - legacy_appeal_with_active_tasks_ids.sort
  end

  def build_report(appeal_ids)
    return if appeal_ids.empty?

    add_to_report "Found #{appeal_ids.count} legacy appeals charged to CASEFLOW in VACOLS with no active Caseflow tasks."
    all_to_report "These appeals will not progress unless location is manually corrected in VACOLS "
    add_to_report "or an applicable Caseflow task is manually created. Research and fix these appeals accordingly."
    add_to_report "LegacyAppeal.where(id: #{appeal_ids.sort})"
  end
end
