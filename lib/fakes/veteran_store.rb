# frozen_string_literal: true

class Fakes::VeteranStore < Fakes::PersistentStore
  class << self
    def redis_ns
      "veterans_#{Rails.env}"
    end
  end

  def all_veteran_file_numbers
    prefix = "#{self.class.redis_ns}:"
    all_keys.map { |key| key.sub(/^#{prefix}/, "") }
  end

  def store_veteran_record(file_number, record)
    deflate_and_store(file_number, record)
  end
end
