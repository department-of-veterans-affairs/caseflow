# frozen_string_literal: true

class Fakes::RepresentativeStore < Fakes::PersistentStore
  class << self
    def redis_ns
      "representatives_#{Rails.env}"
    end
  end

  def all_participant_ids
    prefix = "#{self.class.redis_ns}:"
    all_keys.map { |key| key.sub(/^#{prefix}/, "") }
  end

  def store_representative_record(representative_participant_id, record)
    deflate_and_store(representative_participant_id, record)
  end

  def poas_list
  end
end
