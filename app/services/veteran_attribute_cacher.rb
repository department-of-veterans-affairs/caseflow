# frozen_string_literal: true

class VeteranAttributeCacher
  def initialize(limit: 100)
    @limit = limit
  end

  def call
    potentially_stale_records.find_each(batch_size: limit) do |veteran|
      veteran.update_cached_attributes! if veteran.stale_attributes?
    end
  end

  private

  attr_reader :limit

  def potentially_stale_records
    Veteran.where(ssn: nil).or(Veteran.where(first_name: nil))
  end
end
