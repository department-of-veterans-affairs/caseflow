# frozen_string_literal: true

class ETL::Syncer
  def initialize(since: Time.zone.yesterday)
    @since = since
  end

  def call
    target_class.transaction do
      instances_needing_update.find_each do |original|
        target_class.sync_with_original(original).save!
      end
    end
  end

  def origin_class
    fail "Must override abstract method origin_class"
  end

  def target_class
    fail "Must override abstract method target_class"
  end

  private

  attr_reader :since

  def instances_needing_update
    origin_class.where("updated_at >= ?", since)
  end
end
