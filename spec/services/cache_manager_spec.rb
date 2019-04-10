# frozen_string_literal: true

describe CacheManager do
  describe "#clear" do
    it "removes cached Caseflow attributes" do
      cache_key = "IntakeStats-last-calculated-timestamp"
      expect(Rails.cache.exist?(cache_key)).to be_falsey
      IntakeStats.throttled_calculate_all!
      expect(Rails.cache.exist?(cache_key)).to be_truthy

      subject.clear(:caseflow)

      expect(Rails.cache.exist?(cache_key)).to be_falsey
    end
  end
end
