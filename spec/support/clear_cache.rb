# frozen_string_literal: true

REDIS_NAMESPACES = [
  "idt_test",
  "end_product_records_test",
  "test_all",
  "test_#{ENV['TEST_SUBCATEGORY']}"
].freeze

FeatureToggle.cache_namespace = "test_#{ENV['TEST_SUBCATEGORY'] || 'all'}"

RSpec.configure do |config|
  config.before(:all) do
    Rails.cache.clear
    REDIS_NAMESPACES.each { |namespace| delete_matched(namespace: namespace) }
  end

  config.after(:each) do
    Rails.cache.clear
    REDIS_NAMESPACES.each { |namespace| delete_matched(namespace: namespace) }
  end
end

def delete_matched(namespace:)
  redis = Redis.current
  redis.scan_each(match: "#{namespace}:*") { |key| redis.del(key) }
end
