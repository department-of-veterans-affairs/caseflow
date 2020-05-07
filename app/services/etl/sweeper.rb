# frozen_string_literal: true

# Normally called via cron to clean up ETL records that refer to
# deleted original records.

class ETL::Sweeper
  include ETLClasses

  def call(etl_build)
    syncer_klasses.each do |klass|
      sweep_targets(klass.new(etl_build: etl_build))
    end
    etl_build
  end

  private

  # find all the PKs in target_klass that no longer
  # exist in origin_klass, and delete any targets that are stale.
  def sweep_targets(syncer)
    origin_klass = syncer.origin_class
    target_klass = syncer.target_class

    target_klass.find_in_batches.with_index do |targets, batch|
      Rails.logger.debug("Starting #{target_klass.name} sweep batch #{batch}")

      origin_pks = targets.pluck(target_klass.origin_primary_key)
      origin_pks_count = origin_pks.count
      Rails.logger.debug("Found #{origin_pks_count} #{target_klass.name} PKs")

      origin_rows = origin_klass.unscoped.where(id: origin_pks).pluck(:id)
      origin_rows_count = origin_rows.count 
      Rails.logger.debug("Found #{origin_rows_count} #{origin_klass.name} rows")

      next if origin_rows_count == origin_pks_count # no deletions, next batch

      origin_rows_deleted = origin_pks - origin_rows
      Rails.logger.debug("Target rows to sweep: #{origin_rows_deleted}")

      target_klass.where(target_klass.origin_primary_key => origin_rows_deleted).delete_all
    end
  end
end
