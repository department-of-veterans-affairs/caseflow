# frozen_string_literal: true

# Abstract service class for ETL synchronization.
# Subclasses should define a origin_class and a target_class
# and the target_class is expected to inherit from ETL::Record.
# The `call` method default behavior is to find all origin_class
# instances that have been updated "since" a Time,
# then sync and save the corresponding target_class instance.

class ETL::Syncer
  def initialize(since: nil)
    @since = since
  end

  def call
    synced = 0
    instances_needing_update.find_in_batches.with_index do |originals, batch|
      Rails.logger.debug("Starting batch #{batch} for #{target_class}")
      target_class.transaction do
        originals.reject { |original| filter?(original) }.each do |original|
          synced += 1 if target_class.sync_with_original(original).save!
        end
      end
    end
    synced
  end

  def origin_class
    fail "Must override abstract method origin_class"
  end

  def target_class
    fail "Must override abstract method target_class"
  end

  def filter?(_original)
    false
  end

  private

  attr_reader :since

  def incremental?
    !!since
  end

  def instances_needing_update
    return origin_class.where("updated_at >= ?", since) if incremental?

    origin_class
  end
end
