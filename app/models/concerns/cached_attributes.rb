# Allows models to cache immutable attribtues in order to
# save time consuming calls to dependencies like VACOLS and VBMS.
#
# See cached_attributes_spec.rb for example usage.
#
module CachedAttributes
  extend ActiveSupport::Concern

  def clear_cached_attr!(attr_name)
    Rails.cache.delete(cache_id(attr_name))
  end

  private

  def get_cached_value(attr_name)
    Rails.cache.read(cache_id(attr_name))
  end

  def set_cached_value(attr_name, value)
    Rails.cache.write(cache_id(attr_name), value) && value
  end

  def cache_id(attr_name)
    "#{self.class.name}-#{id}-cached-#{attr_name}"
  end

  module ClassMethods
    def cache_attribute(attr_name, &get_value)
      define_method attr_name do
        cached_value = get_cached_value(attr_name)

        if cached_value
          Rails.logger.info("Retrieving cached value for #{self.class.name}##{attr_name}")
          return cached_value
        end

        value = get_value.call
        set_cached_value(attr_name, value)
      end
    end
  end
end
