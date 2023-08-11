# frozen_string_literal: true

namespace :rating_caches do
  desc "Delete serialized ratings cache keys"
  task delete: [:environment] do
    keys = Rails.cache.instance_variable_get(:@data).keys
    rating_cache_keys = keys.map { |key| key if key.include?("-ratings-02082019") }.uniq.compact
    puts "Cached Serialized Rating Keys Count: #{rating_cache_keys.count}"
    count = 0
    rating_cache_keys.each do |cache_key|
      Rails.cache.delete(cache_key)
      count += 1
    end
    puts "Deleted Cached Serialized Rating Keys Count: #{count}"
  end
end
