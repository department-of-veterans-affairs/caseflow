# frozen_string_literal: true

class Fakes::PowerOfAttorneyStore < Fakes::PersistentStore
  class << self
    def redis_ns
      "powers_of_attorney_#{Rails.env}"
    end
  end

  def all_participant_ids
    prefix = "#{self.class.redis_ns}:"
    all_keys.map { |key| key.sub(/^#{prefix}/, "") }
  end

  def store_power_of_attorney_record(participant_id, record)
    deflate_and_store(participant_id, record)
  end

  def poas_list
  end
end