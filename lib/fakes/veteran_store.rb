# frozen_string_literal: true

class Fakes::VeteranStore < Fakes::PersistentStore
  class << self
    def redis_ns
      "veterans_#{Rails.env}"
    end
  end

  def all_veteran_ids
    prefix = "#{self.class.redis_ns}:"
    all_keys.map { |veteran_id| veteran_id.sub(/^#{prefix}/, "") }
  end

  def store_veteran_record(file_number, record)
    deflate_and_store(file_number, record)
  end
end
