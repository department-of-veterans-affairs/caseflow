# frozen_string_literal: true

class VeteranAttributeCacher
  def initialize(limit: 100)
    @limit = limit
  end

  def call
    Veteran.where(ssn: nil).or(Veteran.where(first_name: nil)).find_each(batch_size: limit) do |v|
      v.update_cached_attributes! if v.stale_attributes?
    end
  end

  private

  attr_reader :limit
end
