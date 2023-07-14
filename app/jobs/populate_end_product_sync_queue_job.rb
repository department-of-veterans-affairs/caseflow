# frozen_string_literal: true

# This job will find deltas between the end product establishment table and the VBMS ext claim table
# where VBMS ext claim level status code is CLR or CAN. If EP is already in the queue it will be skipped.
# Job will populate queue ENV["END_PRODUCT_QUEUE_BATCH_LIMIT"] records at a time.
# This job will run every minute.
class PopulateEndProductSyncQueueJob < CaseflowJob
  queue_with_priority :low_priority

  def perform
    RequestStore.store[:current_user] = User.system_user

    begin
      ActiveRecord::Base.transaction do
        batch = find_priority_end_product_establishments_to_sync
        batch.empty? ? return : insert_into_priority_sync_queue(batch)

        Rails.logger.info("PopulateEndProductSyncQueueJob EPEs processed: #{batch} - Time: #{Time.zone.now}")
      end
    rescue StandardError => error
      capture_exception(error: error)
    end
  end

  private

  def find_priority_end_product_establishments_to_sync
    get_batch = <<-SQL
    select id
      from end_product_establishments
      inner join vbms_ext_claim
      on end_product_establishments.reference_id = vbms_ext_claim."CLAIM_ID"::varchar
      where (end_product_establishments.synced_status <> vbms_ext_claim."LEVEL_STATUS_CODE" or end_product_establishments.synced_status is null)
        and vbms_ext_claim."LEVEL_STATUS_CODE" in ('CLR','CAN')
        and end_product_establishments.id not in (select end_product_establishment_id from priority_end_product_sync_queue)
      limit #{ENV['END_PRODUCT_QUEUE_BATCH_LIMIT']};
    SQL

    ActiveRecord::Base.connection.exec_query(ActiveRecord::Base.sanitize_sql(get_batch)).rows.flatten
  end

  def insert_into_priority_sync_queue(batch)
    batch.each do |ep_id|
      PriorityEndProductSyncQueue.create!(
        end_product_establishment_id: ep_id
      )
    end
  end
end
