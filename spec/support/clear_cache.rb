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
  rescue Errno::ENOENT, Errno::ENOTEMPTY => error
    # flakey at CircleCI. Don't fail tests because of this.
    Rails.logger.error(error)
  end
end

def delete_matched(namespace:)
  redis = Redis.new(url: Rails.application.secrets.redis_url_cache)
  redis.scan_each(match: "#{namespace}:*") { |key| redis.del(key) }
end
