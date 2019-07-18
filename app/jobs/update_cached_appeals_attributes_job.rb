BATCH_SIZE = 10

class UpdateCachedAppealsAttributesJob < ApplicationJob
  queue_as :low_priority

  def perform(*args)
    # get uniq appeal ids from tasks - appeal_id
    appeals_to_cache_ids = Task.open.where(appeal_type: LegacyAppeal.name).pluck(:appeal_id).uniq

    #  start batching
    appeals_to_cache = appeals_to_cache_ids.in_groups_of(BATCH_SIZE, false)

    #  cycle through each batch
    appeals_to_cache.each do |appeals_ids|
      # use appeals ids to get Appeals data - docket_type
      docket_types = Appeal.where(id: appeals_ids).pluck(:docket_type)

      # use appeal IDs to get docket number from VACOLS
      vacols_ids = LegacyAppeal.where(id: appeals_ids).pluck(:vacols_id)

      docket_numbers = VACOLS::Folder.where(ticknum: vacols_ids).pluck(:tinum)

      # THIS ZIP ASSUMES EVERYTHING IS IN THE CORRECT ORDER. Is that a safe assumption?
      # [appeal_id, docket_type, docket_number]
      appeals_cache_rows = appeals_ids.zip(docket_types, docket_numbers)

      attributes_to_cache = []

      appeals_cache_rows.count do |i|
        attributes_to_cache << {appeal_id: i[0], docket_type: i[1], docket_number: i[2], appeal_type: LegacyAppeal.name}
      end

      # CachedAppealAttribute.import attributes_to_cache

      CachedAppealAttribute.upsert_all(attributes_to_cache)

    end
  end
end
