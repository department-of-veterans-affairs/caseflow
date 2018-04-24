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
      fields.each do |field|
        bgs_fields[field] = true

        define_method field do
          load_bgs_record!
          instance_variable_get("@#{field}".to_sym)
        end

        define_method "#{field}=" do |value|
          instance_variable_set("@#{field}".to_sym, value)
        end
      end
    end

    def bgs_fields
      @bgs_fields ||= {}
    end
  end

  def bgs_record
    @bgs_record ||= (fetch_bgs_record || :not_found)
  end

  def found?
    @accessible == false || (bgs_record != :not_found && bgs_record[:file_number])
  end

  def accessible?
    @accessible = fetch_accessible if @accessible.nil?
    @accessible
  end

  def load_bgs_record!
    set_attrs_from_bgs_record if found?
    self
  end

  private

  def set_attrs_from_bgs_record
    self.bgs_fields.each do |bgs_attribute|
      instance_variable_set(
        "@#{bgs_attribute}".to_sym,
        bgs_record[bgs_attribute]
      )
    end
  end
end
