# frozen_string_literal: true

require "rails_helper"

describe CacheManager do
  before do
    redis_store = ActiveSupport::Cache.lookup_store(:redis_store,
                                                    url: Rails.application.secrets.redis_url_cache,
                                                    namespace: "cache")
    allow(Rails).to receive(:cache).and_return(redis_store)
  end

  let(:stats_cache_key) { "IntakeStats-last-calculated-timestamp" }
  let(:ro_schedule_period) { build_stubbed(:ro_schedule_period) }
  let(:ro_cache_key) { "RoSchedulePeriod-#{ro_schedule_period.id}-cached-submitting_to_vacols" }

  describe "#all_cache_keys" do
    it "returns all keys in the cache" do
      IntakeStats.throttled_calculate_all!
      ro_schedule_period.start_confirming_schedule

      expect(subject.all_cache_keys).to include(stats_cache_key, ro_cache_key)
    end
  end

  describe "#clear" do
    it "removes cached Caseflow attributes" do
      expect(Rails.cache.exist?(stats_cache_key)).to be_falsey
      IntakeStats.throttled_calculate_all!
      expect(Rails.cache.exist?(stats_cache_key)).to be_truthy

      expect(Rails.cache.exist?(ro_cache_key)).to be_falsey
      ro_schedule_period.start_confirming_schedule
      expect(Rails.cache.exist?(ro_cache_key)).to be_truthy

      subject.clear(:caseflow)

      expect(Rails.cache.exist?(stats_cache_key)).to be_falsey
      expect(Rails.cache.exist?(ro_cache_key)).to be_falsey
    end
  end
end
