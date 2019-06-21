# frozen_string_literal: true

module AssociatedVacolsModel
  extend ActiveSupport::Concern

  class LazyLoadingDisabledError < StandardError; end

  module ClassMethods
    # vacols_attr_accessors will lazy load the underlying data from the VACOLS DB upon first call
    #
    # For example, appeal = LegacyAppeal.find(id) will *not* make any calls to load the data from VACOLS,
    # but soon as we call appeal.veteran_first_name, it will trigger the VACOLS DB lookup and fill in
    # all instance variables for the appeal. Further requests will pull the values from memory and not
    # do subsequent VACOLS DB lookups
    def vacols_attr_accessor(*fields)
      vacols_attr_getter(*fields)
      vacols_attr_setter(*fields)
    end

    def vacols_attr_getter(*fields)
      fields.each do |field|
        vacols_getters[field] = true

        define_vacols_getter(field)
      end
    end

    def vacols_attr_setter(*fields)
      fields.each do |field|
        vacols_setters[field] = true

        define_vacols_setter(field)
      end
    end

    def define_vacols_getter(field)
      define_method field do
        check_and_load_vacols_data! unless field_set?(field)
        instance_variable_get("@#{field}".to_sym)
      end
    end

    def define_vacols_setter(field)
      define_method "#{field}=" do |value|
        @vacols_load_status = :disabled
        mark_field_as_set(field)
        instance_variable_set("@#{field}".to_sym, value)
      end
    end

    def vacols_setters
      @vacols_setters ||= {}
    end

    def vacols_getters
      @vacols_getters ||= {}
    end

    def vacols_field?(field)
      vacols_setter?(field) && vacols_getter?(field)
    end

    def vacols_setter?(field)
      vacols_setters[field].present?
    end

    def vacols_getter?(field)
      vacols_getters[field].present?
    end
  end

  def field_set?(field)
    set_fields[field]
  end

  def mark_field_as_set(field)
    set_fields[field] = true
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
    # When we're ready to turn the error on, replace the if below with the
    # commented out error.
    # raise LazyLoadingDisabledError if @vacols_load_status == :disabled
    if @vacols_load_status == :disabled
      # For now we will send it to Sentry so we can fix cases
      # where LazyLoadingDisabledError happens in production
      Raven.capture_exception(LazyLoadingDisabledError.new)
      @vacols_load_status = nil
    end

    perform_vacols_request unless @vacols_load_status

    vacols_success?
  end

  def vacols_record_exists?
    check_and_load_vacols_data!
  end

  private

  def set_fields
    @set_fields ||= {}
  end

  def perform_vacols_request
    # Use :loading status to prevent infinite loop
    @vacols_load_status = :loading

    # Fetch and cache values from VACOLS
    # self.class.repository.load_vacols_data(self) should return truthy or false
    # which is used to store the outcome of the load
    @vacols_load_status = self.class.repository.load_vacols_data(self) ? :success : :failed
  end

  # There are four possible vacols_load_statuses:
  # 1) success: This means the data has successfully been loaded from VACOLS
  # 2) failed: This means the data was not successfully loaded from VACOLS, but a load was tried.
  # 3) loading: This means we are currently running the call to load VACOLS data
  # 4) disabled: This means code has called the setter method for at least one field.
  #      The user is expected to set all needed values themselves rather than relying
  #      on lazy loading. Otherwise we make unnecessary calls to VACOLS. First, to get
  #      the values we're setting, and another on lazy loading. In the future
  #      this status means we will raise an error when you try to lazy load VACOLS data.
  #      For now it prints an error. A disabled status is still defined as success in the method below.
  def vacols_success?
    @vacols_load_status == :success || @vacols_load_status == :disabled
  end
end
