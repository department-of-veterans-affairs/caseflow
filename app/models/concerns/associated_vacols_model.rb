module AssociatedVacolsModel
  extend ActiveSupport::Concern

  class LazyLoadingTurnedOffError < StandardError; end

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
          fail LazyLoadingTurnedOffError if !lazy_loading_enabled? && !@provided_values.include?(field)
          check_and_load_vacols_data!
          instance_variable_get("@#{field}".to_sym)
        end

        define_method "#{field}=" do |value|
          check_and_load_vacols_data!
          instance_variable_set("@#{field}".to_sym, value)
        end
      end
    end
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
    perform_vacols_request unless @vacols_load_status

    vacols_success?
  end

  def vacols_record_exists?
    check_and_load_vacols_data!
  end

  def turn_off_lazy_loading(initial_values: nil)
    @vacols_load_status = :disabled
    @provided_values = initial_values.keys
    initial_values.each do |key, value|
      send("#{key}=", value)
    end
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

  def lazy_loading_enabled?
    @vacols_load_status != :disabled
  end
end
