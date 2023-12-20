# frozen_string_literal: true

namespace :fakes do
  desc "Clear local Fakes stores"
  task clear: :environment do
    cm = CacheManager.new
    CacheManager::BUCKETS.keys.each { |bucket| cm.clear(bucket) }
    Fakes::EndProductStore.new.clear!
    Fakes::RatingStore.new.clear!
    Fakes::VeteranStore.new.clear!
  end

  desc "Build local Fakes stores"
  task build: :environment do
    Fakes::BGSServiceRecordMaker.new.call
  end
end
