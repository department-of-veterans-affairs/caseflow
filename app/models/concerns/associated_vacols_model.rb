module AssociatedVacolsModel
  extend ActiveSupport::Concern

  class LazyLoadingDisabledError < StandardError; end

  module ClassMethods
    # vacols_attr_accessors will lazy load the underlying data from the VACOLS DB upon first call
    #
    # For example, appeal = Appeal.find(id) will *not* make any calls to load the data from VACOLS,
    # but soon as we call appeal.veteran_first_name, it will trigger the VACOLS DB lookup and fill in
    # all instance variables for the appeal. Further requests will pull the values from memory and not
    # do subsequent VACOLS DB lookups
    def vacols_attr_accessor(*fields)
      fields.each do |field|
        define_method field do
          check_and_load_vacols_data! unless is_field_set(field)
          instance_variable_get("@#{field}".to_sym)
        end

        define_method "#{field}=" do |value|
          @vacols_load_status = :disabled
          mark_field_is_set(field)
          instance_variable_set("@#{field}".to_sym, value)
        end
      end
    end
  end

  def is_field_set(field)
    @set_fields && @set_fields[field.to_sym]
  end

  def mark_field_is_set(field)
    @set_fields = {} if !@set_fields
    @set_fields[field.to_sym] = true
  end

  # Setter method for assigning a hash of values
  # to their corresponding instance variables
  def assign_from_vacols(values)
    values.each do |key, value|
      setter = method("#{key}=")
      setter.call(value)
    end
  end

  def check_and_load_vacols_data!
    # raise LazyLoadingDisabledError if @vacols_load_status == :disabled
    perform_vacols_request unless @vacols_load_status

    vacols_success?
  end

  def vacols_record_exists?
    check_and_load_vacols_data!
  end

  private

  def perform_vacols_request
    # Use :loading status to prevent infinite loop
    @vacols_load_status = :loading

    # Fetch and cache values from VACOLS
    # self.class.repository.load_vacols_data(self) should return truthy or false
    # which is used to store the outcome of the load
    @vacols_load_status = self.class.repository.load_vacols_data(self) ? :success : :failed
  end

  def vacols_success?
    @vacols_load_status == :success || @vacols_load_status == :disabled
  end
end
