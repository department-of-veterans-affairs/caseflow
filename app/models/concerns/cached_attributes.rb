# frozen_string_literal: true

# Allows models to cache immutable attributes in order to
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

  def set_cached_value(attr_name, value, write_options = {})
    Rails.cache.write(cache_id(attr_name), value, write_options) && value
  end

  def cache_id(attr_name)
    "#{self.class.name}-#{attribute_cache_key(attr_name)}-cached-#{attr_name}"
  end

  def attribute_cache_key(attr_name)
    send(self.class.attribute_cache_key(attr_name))
  end

  module ClassMethods
    # Use of class variables is intentional so that we can access them from subclasses
    # rubocop:disable Style/ClassVars

    def attribute_cache_key(attr_name)
      @@attribute_cache_keys[attr_name]
    end

    def cache_attribute(attr_name, write_options = {}, &get_value)
      @@attribute_cache_keys ||= {}
      @@attribute_cache_keys[attr_name] = write_options.delete(:cache_key) || :id

      define_method "#{attr_name}=" do |value|
        set_cached_value(attr_name, value)
      end

      define_method attr_name do
        cached_value = get_cached_value(attr_name)

        # making sure false values are retrived from cache as well
        if !cached_value.nil?
          Rails.logger.info("Retrieving cached value for #{self.class.name}##{attr_name}")
          return cached_value
        end
        value = instance_eval(&get_value)
        set_cached_value(attr_name, value, write_options)
      end
    end
    # rubocop:enable Style/ClassVars
  end
end
