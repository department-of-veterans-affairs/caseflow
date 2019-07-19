BATCH_SIZE = 10

class UpdateCachedAppealsAttributesJob < ApplicationJob
  queue_as :low_priority

  def perform
    cache_ama_appeals
    cache_legacy_appeals
  end

  def cache_ama_appeals
    appeals_to_cache = Task.open.where(appeal_type: Appeal.name).map(&:appeal).map do |appeal|
      {
        appeal_id: appeal.id,
        docket_type: appeal.docket_type,
        docket_number: appeal.docket_number,
        appeal_type: Appeal.name
      }
    end

    CachedAppeal.import appeals_to_cache, on_duplicate_key_update: {conflict_target: [:appeal_id, :appeal_type]}
  end

  def cache_legacy_appeals
    legacy_appeals = LegacyAppeal.find(Task.open.where(appeal_type: LegacyAppeal.name).pluck(:appeal_id).uniq)

    cache_legacy_appeal_postgres_data(legacy_appeals)
    cache_legacy_appeal_vacols_data(legacy_appeals)
  end

  def cache_legacy_appeal_postgres_data(legacy_appeals)
    values_to_cache = legacy_appeals.map do |appeal|
      {
        appeal_id: appeal.id,
        appeal_type: LegacyAppeal.name,
        vacols_id: appeal.vacols_id,
        docket_type: appeal.docket_name # "legacy"
      }
    end

    CachedAppeal.import values_to_cache, on_duplicate_key_update: { conflict_target: [:appeal_id, :appeal_type] }
  end

  def cache_legacy_appeal_vacols_data(legacy_appeals)
    legacy_appeals.pluck(:vacols_id).in_groups_of(BATCH_SIZE).each do |vacols_ids|
      values_to_cache = VACOLS::Folder.where(ticknum: vacols_ids).pluck(:ticknum, :tinum).map do |vacols_folder|
        { vacols_id: vacols_folder[0], docket_number: vacols_folder[1] }
      end

      CachedAppeal.import values_to_cache, on_duplicate_key_update: { conflict_target: [:vacols_id], columns: [:docket_number] }
    end
  end
end
