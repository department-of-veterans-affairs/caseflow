BATCH_SIZE = 10

class UpdateCachedAppealsAttributesJob < ApplicationJob
  queue_as :low_priority


  def perform
    cache_ama_appeals
    cache_legacy_appeals
  end

  def cache_ama_appeals
    ama_appeals = Task.open.where(appeal_type: Appeal.name).pluck(:appeal_id).uniq.in_groups_of(BATCH_SIZE)

    ama_appeals.each do |appeal_ids|
      appeals_attrs = Appeal.where(id: appeal_ids).map { |a|
        [a.id, a.docket_type, a.docket_number]
      }

      appeals_to_cache = []

      appeals_attrs.each do |a|
        appeals_to_cache << {appeal_id: a[0], docket_type: a[1], docket_number:a[2], appeal_type: Appeal.name}
      end

      CachedAppeal.import appeals_to_cache, on_duplicate_key_update: {conflict_target: [:appeal_id, :appeal_type]}
    end
  end

  def cache_legacy_appeals
    legacy_appeals_batches = Task.open.where(appeal_type: LegacyAppeal.name).pluck(:appeal_id).uniq.in_groups_of(BATCH_SIZE)

    legacy_appeals_batches.each do |legacy_appeal_ids|
      vacols_ids = cache_legacy_ama_data_and_return_vacols_ids(legacy_appeal_ids)

      cache_legacy_vacols_data(vacols_ids)

    end
  end

  def cache_legacy_ama_data_and_return_vacols_ids(legacy_appeal_ids)
    appeals_attrs =  LegacyAppeal.where(id: legacy_appeal_ids).map { |a|
      [a.id, a.vacols_id]
    }

    legacy_appeals_to_cache = []

    appeals_attrs.each do |a|
      legacy_appeals_to_cache << { appeal_id: a[0], vacols_id: a[1], docket_type: LegacyAppeal.name, appeal_type: LegacyAppeal.name }
    end

    CachedAppeal.import legacy_appeals_to_cache, on_duplicate_key_update: { conflict_target: [:appeal_id, :appeal_type] }

    # Return VACOLS IDs for further use.
    appeals_attrs.map { |attrs|
      attrs[1]
    }
  end

  def cache_legacy_vacols_data(vacols_ids)
    # returns array of [vacols_id, docket_number] arrays
    legacy_appeal_attrs = VACOLS::Folder.where(ticknum: vacols_ids).pluck(:ticknum, :tinum)

    puts "HERE"
    puts legacy_appeal_attrs

    # now do another write to cache w/ vacols_id as the key
    legacy_appeals_to_cache = []

    legacy_appeal_attrs.each do |a|
      legacy_appeals_to_cache << { vacols_id: a[0], docket_number: a[1] }
    end

    # byebug

    #  VACOLS IDs are unique
    CachedAppeal.import legacy_appeals_to_cache, on_duplicate_key_update: {conflict_target: [:vacols_id], columns: [:docket_number]}

  end










end
