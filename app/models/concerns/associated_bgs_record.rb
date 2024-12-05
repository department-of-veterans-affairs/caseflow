# frozen_string_literal: true

module AssociatedBgsRecord
  extend ActiveSupport::Concern

  include BGSServiceConcern

  module ClassMethods
    # bgs_attr_accessor will lazy load the underlying data from BGS upon first call
    #
    # For example, veteran = Veteran.new(file_number: file_number) will *not* make any calls to load
    # the data from BGS, but soon as we call veteran.ssn, it will trigger the BGS request and fill in
    # all instance variables for the veteran. Further requests will pull the values from memory and not
    # do subsequent BGS lookups
    def bgs_attr_accessor(*attributes)
      attributes, options = extract_attributes_and_options(attributes)

      attributes.each do |attribute|
        define_method attribute do
          # Foreign keys are not loaded from BGS, however there are some situations where
          # the foreign key in the response overrides the foriegn key sent in the request.
          # TODO: understand more about this scenario
          load_bgs_record! unless options[:foreign_key]

          instance_variable_get("@#{attribute}".to_sym)
        end

        define_method "#{attribute}=" do |value|
          instance_variable_set("@#{attribute}".to_sym, value)
        end
      end

      bgs_attributes.concat(attributes)
    end

    def bgs_attributes
      @bgs_attributes ||= []
    end

    def cached_bgs_attributes
      self::CACHED_BGS_ATTRIBUTES # consumers must define
    end

    private

    def extract_attributes_and_options(attributes)
      attributes.last.is_a?(Hash) ? [attributes[0...-1], attributes.last] : [attributes, {}]
    end
  end

  def found?
    !accessible? || bgs_record != :not_found
  end

  def accessible?
    return @accessible unless @accessible.nil?

    @accessible = defined?(super) ? super : true
  end

  def bgs_record
    @bgs_record ||= (try_and_retry_bgs_record || :not_found)
  end

  private

  def try_and_retry_bgs_record
    fetch_bgs_record
  rescue BGS::ShareError => error
    if error.ignorable?
      fetch_bgs_record
    else
      raise error # re-raise if we can't try again
    end
  end

  def load_bgs_record!
    return if !accessible? || !found? || @bgs_record_loaded

    self.class.bgs_attributes.each do |bgs_attribute|
      instance_variable_set(
        "@#{bgs_attribute}".to_sym,
        bgs_record[bgs_attribute]
      )
    end

    @bgs_record_loaded = true
  end

  def stale_attributes
    self.class.cached_bgs_attributes.select { |attr| self[attr].nil? || self[attr].to_s != bgs_record[attr].to_s }
  end

  def cached_or_fetched_from_bgs(attr_name:, bgs_attr: nil)
    bgs_attr ||= attr_name
    self[attr_name] ||= begin
      return if not_found?

      bgs_record.dig(bgs_attr)
    end
  end

  def not_found?
    bgs_record == :not_found
  end
end
