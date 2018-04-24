module AssociatedBgsRecord
  extend ActiveSupport::Concern

  class LazyLoadingDisabledError < StandardError; end

  module ClassMethods
    # bgs_attr_accessor will lazy load the underlying data from BGS upon first call
    #
    # For example, veteran = Veteran.new(file_number: file_number) will *not* make any calls to load 
    # the data from BGS, but soon as we call veteran.ssn, it will trigger the BGS request and fill in
    # all instance variables for the veteran. Further requests will pull the values from memory and not
    # do subsequent BGS lookups
    def bgs_attr_accessor(*fields)
      options = fields.last.is_a?(Hash) ? fields.pop : {}

      @bgs_fields = fields

      fields.each do |field|

        define_method field do
          # foreign keys are not loaded from BGS, however there are some situations where
          # the foreign key in the response overrides the foriegn key sent in the request.
          # TODO: understand more about this scenario
          load_bgs_record! unless options[:foreign_key]

          instance_variable_get("@#{field}".to_sym)
        end

        define_method "#{field}=" do |value|
          instance_variable_set("@#{field}".to_sym, value)
        end
      end
    end

    def bgs_fields
      @bgs_fields ||= []
    end
  end

  def bgs_record
    @bgs_record ||= (fetch_bgs_record || :not_found)
  end

  def load_bgs_record!
    set_attrs_from_bgs_record if found?
    self
  end

  # TODO: Some of this logic may be Veteran specific, since it's the only model
  #   that uses AssociatedBgsRecord. When we add this to PowerOfAttorney, or
  #   another BGS backed model, make these more abstract
  def found?
    @accessible == false || (bgs_record != :not_found && bgs_record[:file_number])
  end

  def accessible?
    @accessible = fetch_accessible if @accessible.nil?
    @accessible
  end

  private

  def set_attrs_from_bgs_record
    self.class.bgs_fields.each do |bgs_attribute|
      instance_variable_set(
        "@#{bgs_attribute}".to_sym,
        bgs_record[bgs_attribute]
      )
    end
  end
end
